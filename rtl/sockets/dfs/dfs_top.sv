//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    dfs_top.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

`timescale 1ns / 1fs
/*
Description: Module in charge of controlling dynamic clock reconfiguration.

*/

//////////////////////////////////////////////////////////////////
//                      Local parameters                        //
//////////////////////////////////////////////////////////////////
import bram_pkg::*;
import drp_register_pkg::*;

parameter DATA_WIDTH                    = 13 ; 
parameter M                             = 48 ;
parameter D                             = 4  ;
parameter O                             = 12 ;
parameter FRACTIONAL_POINT_POSITION     = 3  ;
parameter MAX_FRACTIONAL_BIT_CONSIDERED = 3  ;

module dfs_top
    #(  
    parameter CLOCK_INPUT_PERIOD        = 10.000 ,
    parameter USE_FRACT_OI              = 1,
    parameter USE_D                     = 1,
    parameter USE_DATA_O                = 1,
    parameter USE_REG_FOR_DATA_I        = 1,
    parameter ON_RESET_RESTORE_DEFAULT_F= 0
    )
    (
    input  logic                         clk_in,
    input  logic                         reset,
    input  logic  [DATA_WIDTH-1 : 0]     data_i, 
    input  logic                         en_i,
    output logic  [DATA_WIDTH-1 : 0]     data_o,
    output logic                         ack_o,
    output logic                         locked_o,
    output logic                         clk_o
    );
    
    localparam BITS_FOR_STATES = 5;
    typedef enum logic [BITS_FOR_STATES-1:0] {  
        S_IDLE                                , 
        S_LOOKUP_SEND_ADDR                    ,
        S_LOOKUP_REDIRECT                     , 
        S_LOOKUP_READ_CONF                    ,
        S_RECONF_M_SUPPLY_ADDR                ,
        S_RECONF_M_WAIT_REG_READ              ,
        S_RECONF_M_OVERWRITE_REG              ,
        S_RECONF_M_WAIT_ACK_WRITE             , 
        S_RECONF_D_SUPPLY_ADDR                ,
        S_RECONF_D_WAIT_REG_READ              ,
        S_RECONF_D_OVERWRITE_REG              ,
        S_RECONF_D_WAIT_ACK_WRITE             , 
        S_RECONF_O_INT_SUPPLY_ADDR            ,
        S_RECONF_O_INT_WAIT_REG_READ          ,
        S_RECONF_O_INT_OVERWRITE_REG          ,
        S_RECONF_O_INT_WAIT_ACK_WRITE         , 
        S_RECONF_O_FRAC_SUPPLY_ADDR           ,
        S_RECONF_O_FRAC_WAIT_REG_READ         ,
        S_RECONF_O_FRAC_OVERWRITE_REG         ,
        S_RECONF_O_FRAC_WAIT_ACK_WRITE        , 
        S_RECONF_END
    } State;

    //FSM
    (* dont_touch = "true" *) State       curState   , nextState;

    //clock wizard controlling
    (* dont_touch = "true" *) wire                                clk;
    (* dont_touch = "true" *) wire                                clk_o_wire;    
    assign                    clk_o    = clk_o_wire;
    reg                                 reset_requested;
    reg [REG_ADDRESS_WIDTH -1  : 0]     daddr0  , daddr1, daddr_x   ;
    wire                                clk_out0, clk_out1;
    wire                                locked0 , locked1;
    reg                                 den0    , den1  , den_non_current;
    reg                                 dwe0    , dwe1  , dwe_non_current;
    reg [REG_DATA_WIDTH - 1 : 0]        din0    , din1  , din_x;
    reg [REG_DATA_WIDTH - 1 : 0]        dout0   , dout1 , dout_non_current;
    reg                                 drdy0   , drdy1 , drdy_non_current;
    reg                                 reset_non_current , reset_non_current_next;
    reg                                 reset0  ;
    reg                                 reset1  ;
    reg                                 sel     , sel_next;
    //configuration_storage
    (* dont_touch = "true" *) reg [OUT0_REG1_LOW_BITS_START-OUT0_REG1_LOW_BITS_END               : 0]  Conf_Oi_int    , Conf_Oi_int_next    ;
    (* dont_touch = "true" *) reg [OUT0_REG2_FRAC_BITS_START-OUT0_REG2_FRAC_BITS_END             : 0]  Conf_Oi_frac   , Conf_Oi_frac_next   ;
    (* dont_touch = "true" *) reg [OUT0_REG2_FRAC_EN_BITS_START-OUT0_REG2_FRAC_EN_BITS_END       : 0]  Conf_Oi_frac_en, Conf_Oi_frac_en_next;
    (* dont_touch = "true" *) reg [CLOCK_FBOUT_REG1_LOW_BITS_START-CLOCK_FBOUT_REG1_LOW_BITS_END : 0]  Conf_M         , Conf_M_next         ;
    (* dont_touch = "true" *) reg [DIV_REG1_LOW_BITS_START-DIV_REG1_LOW_BITS_END                 : 0]  Conf_D         , Conf_D_next         ;
    //to signal outside the current frequency.
    reg [BRAM18_FREQ_OBTAINED_BITS_START-BRAM18_FREQ_OBTAINED_BITS_END :0]   cur_freq, freq_next;
    // bram access
    
    (* dont_touch = "true" *) reg [BRAM36_ADDR_WIDTH-1:0]                 bram_addr;
                              reg                                         bram_addr_valid;
    (* dont_touch = "true" *) reg [BRAM36_READ_WIDTH-1:0]                 bram_data;
                              reg                                         bram_reset;

    reg                                         bram18_addr_valid;
    reg [BRAM18_READ_WIDTH-1:0]                 bram18_data;

    //to save data_i
    logic [DATA_WIDTH-1 : 0]                    data_i_reg, data_i_reg_next;

    logic locked_int;    

    //////////////////////////////////////////////////////////////////
    //                       Sequential Logic                       //
    //////////////////////////////////////////////////////////////////

    always_ff @(posedge clk) begin
        if( reset ) begin
            reset_requested         <= 1'b0;
            
            if(ON_RESET_RESTORE_DEFAULT_F) curState <= S_RECONF_M_SUPPLY_ADDR;
            else                           curState                <= S_IDLE;
            
            Conf_M                  <=  M >> 2  ; 
            Conf_Oi_int             <= 6'b000001;
            Conf_Oi_frac            <= 6'b000001;
            Conf_Oi_frac_en         <= 1'b0     ;
            Conf_D                  <=  D >> 2  ;

            bram_reset              <= 1'b1;

            data_i_reg              <= {DATA_WIDTH {1'b0} };

            reset_non_current       <= 1'b0;
            sel                     <= 1'b0; 
            //if( USE_DATA_O) cur_freq<= int((1000/CLOCK_INPUT_PERIOD*M/D)*8 ); 
            //else            
            cur_freq                <= {DATA_WIDTH{1'b0} }; 
        end 
        else 
        begin
            reset_requested         <= reset_requested;
            curState                <= nextState;

            Conf_M                  <= Conf_M_next;
            Conf_Oi_int             <= Conf_Oi_int_next;
            Conf_Oi_frac            <= Conf_Oi_frac_next;
            Conf_Oi_frac_en         <= Conf_Oi_frac_en_next;
            Conf_D                  <= Conf_D_next;

            bram_reset              <= 1'b0;

            data_i_reg              <= data_i_reg_next;

            reset_non_current       <= reset_non_current_next;
            sel                     <= sel_next;
            cur_freq                <= freq_next;
        end
    end
   
    //////////////////////////////////////////////////////////////////
    //                      Combinational logic                     //
    //////////////////////////////////////////////////////////////////

    always_comb begin : select_sigen_inal_non_current_MMCM
        din0   = din_x;
        din1   = din_x;
        daddr0 = daddr_x;
        daddr1 = daddr_x;

        if(sel)
        begin
            reset1              = 1'b0;
            den1                = 1'b0;
            dwe1                = 1'b0;

            reset0              = reset_non_current;
            den0                = den_non_current;
            dwe0                = dwe_non_current;

            dout_non_current    = dout0;
            drdy_non_current    = drdy0;
        end
        else
        begin
            reset0              = 1'b0;
            den0                = 1'b0;
            dwe0                = 1'b0;

            reset1              = reset_non_current;
            den1                = den_non_current;
            dwe1                = dwe_non_current;
            
            dout_non_current    = dout1;
            drdy_non_current    = drdy1;
        end
    end

    assign data_o               = cur_freq;

    always_comb begin
        nextState               = curState;
        reset_non_current_next  = reset_non_current;
        sel_next                = sel;
        data_i_reg_next         = data_i_reg;
        freq_next               = cur_freq;
        //memory access concerns only S_LOOKUP_states
        bram_addr               = { BRAM36_ADDR_WIDTH   {1'b0}};
        bram_addr_valid         = 1'b0;
        //
        if( USE_DATA_O )
        bram18_addr_valid       = 1'b0;
        
        din_x                   = { REG_DATA_WIDTH    {1'b0}};
        daddr_x                 = { REG_ADDRESS_WIDTH {1'b0}};
        den_non_current         = 1'b0;
        dwe_non_current         = 1'b0;

        Conf_M_next             = Conf_M;
        Conf_Oi_int_next        = Conf_Oi_int;
        Conf_Oi_frac_next       = Conf_Oi_frac;
        Conf_Oi_frac_en_next    = Conf_Oi_frac_en;
        Conf_D_next             = Conf_D;

        ack_o                   = 1'b0;

        case(curState)
        S_IDLE: 
        begin
            if(en_i) 
            begin
                if ( USE_REG_FOR_DATA_I )
                begin
                    data_i_reg_next = data_i;
                    nextState       = S_LOOKUP_SEND_ADDR;
                end
                else
                begin
                    // it assumes that data_i remains unchanged for the first 2 clock cycles
                    // instrument bram to retrieve lookup information at next cc
                    bram_addr       = data_i[FRACTIONAL_POINT_POSITION+:BRAM36_ADDR_WIDTH];
                    bram_addr_valid = 1'b1;  
                    nextState       = S_LOOKUP_REDIRECT;
                end
            end
        end
        S_LOOKUP_SEND_ADDR:
        begin
            // instrument bram to retrieve lookup information at next cc
            bram_addr       = data_i_reg[FRACTIONAL_POINT_POSITION+:BRAM36_ADDR_WIDTH];
            bram_addr_valid = 1'b1;  
            nextState       = S_LOOKUP_REDIRECT;
        end
        S_LOOKUP_REDIRECT: 
        begin // perform lookup using indirection
            //temporary signals for lookup indirection
            reg [BRAM36_ADDR_WIDTH-1:0] base  ;
            reg [5:0]                   offset;
            reg [2:0]                   shift ;

            base            = bram_data[BRAM36_LOOKUP_INT_BITS_START  : BRAM36_LOOKUP_INT_BITS_END  ];
            shift           = bram_data[BRAM36_LOOKUP_SHIFT_BITS_START: BRAM36_LOOKUP_SHIFT_BITS_END];

            
            if ( USE_REG_FOR_DATA_I )   offset          = { {MAX_FRACTIONAL_BIT_CONSIDERED{1'b0}},data_i_reg[FRACTIONAL_POINT_POSITION-1-:MAX_FRACTIONAL_BIT_CONSIDERED]} << shift; 
                                        offset          = { {MAX_FRACTIONAL_BIT_CONSIDERED{1'b0}},data_i    [FRACTIONAL_POINT_POSITION-1-:MAX_FRACTIONAL_BIT_CONSIDERED]} << shift; // if( USE_REG_FOR_DATA_I == 1'b0 ) assume data_i is left unchanged for the first 2 clock cycles.
            //take MAX_FRACTIONAL_BIT_CONSIDERED most signifacnts bits
            bram_addr         = base + offset[MAX_FRACTIONAL_BIT_CONSIDERED+:MAX_FRACTIONAL_BIT_CONSIDERED];
            bram_addr_valid   = 1'b1;
            if( USE_DATA_O)
                bram18_addr_valid = 1'b1;
            
            nextState       = S_LOOKUP_READ_CONF;
        end 
        S_LOOKUP_READ_CONF:
        begin 
            Conf_M_next                 = bram_data  [BRAM36_M_BITS_START             :BRAM36_M_BITS_END              ];
            Conf_Oi_int_next            = bram_data  [BRAM36_O_INT_BITS_START         :BRAM36_O_INT_BITS_END          ];            
            Conf_Oi_frac_next           = bram_data  [BRAM36_O_FRAC_BITS_START        :BRAM36_O_FRAC_BITS_END         ];
            Conf_Oi_frac_en_next        = bram_data  [BRAM36_O_FRAC_EN_START          :BRAM36_O_FRAC_EN_END           ];               
            Conf_D_next                 = bram_data  [BRAM36_D_BITS_START             :BRAM36_D_BITS_END              ];
            if (USE_DATA_O) freq_next   = bram18_data[BRAM18_FREQ_OBTAINED_BITS_START :BRAM18_FREQ_OBTAINED_BITS_END  ];
            else            freq_next   = { DATA_WIDTH{1'b0} }; 
            reset_non_current_next      = 1'b1;
            nextState                   = S_RECONF_M_SUPPLY_ADDR;
        end
        S_RECONF_M_SUPPLY_ADDR :
        begin 
            den_non_current = 1'b1;
            daddr_x         = CLOCK_FBOUT_REG1;
            nextState       = S_RECONF_M_WAIT_REG_READ; // pay attention S_RECONF_X_SUPPLY_ADDR has to preceed S_RECONF_X_WAIT_REG_READ
        end
        S_RECONF_D_SUPPLY_ADDR :
        begin 
            den_non_current = 1'b1;
            daddr_x         = DIV_REG1;
            nextState       = S_RECONF_D_WAIT_REG_READ; // pay attention S_RECONF_X_SUPPLY_ADDR has to preceed S_RECONF_X_WAIT_REG_READ
        end
        S_RECONF_O_INT_SUPPLY_ADDR :
        begin 
            den_non_current = 1'b1;
            daddr_x         = CLOCK_OUT0_REG1;
            nextState       = S_RECONF_O_INT_WAIT_REG_READ; // pay attention S_RECONF_X_SUPPLY_ADDR has to preceed S_RECONF_X_WAIT_REG_READ
        end
        S_RECONF_O_FRAC_SUPPLY_ADDR :
        begin 
            den_non_current = 1'b1;
            daddr_x         = CLOCK_OUT0_REG2;
            nextState       = S_RECONF_O_FRAC_WAIT_REG_READ; // pay attention S_RECONF_X_SUPPLY_ADDR has to preceed S_RECONF_X_WAIT_REG_READ
        end
        S_RECONF_M_WAIT_REG_READ, S_RECONF_D_WAIT_REG_READ, S_RECONF_O_INT_WAIT_REG_READ, S_RECONF_O_FRAC_WAIT_REG_READ: 
        begin //wait a ready (value register) from the non current clock wizard
            if (drdy_non_current) nextState = curState.next(); // pay attention S_RECONF_X_REG_READ has to preceed S_RECONF_X_OVERWRITE_CURRENT_REG_VALUE
        end
        S_RECONF_M_OVERWRITE_REG :
        begin 
            din_x           = {dout_non_current[CLOCK_FBOUT_REG1_PHASE_BITS_START:CLOCK_FBOUT_REG1_RESERVED_BITS_END], Conf_M, Conf_M};
            den_non_current = 1'b1;
            dwe_non_current = 1'b1;
            daddr_x         = CLOCK_FBOUT_REG1;
            nextState       = S_RECONF_M_WAIT_ACK_WRITE;
        end
        S_RECONF_D_OVERWRITE_REG: 
        begin 
            din_x           = { dout_non_current[DIV_REG1_RESERVED_BITS_START:DIV_REG1_NO_COUNT_BITS_END] , Conf_D, Conf_D};    
            den_non_current = 1'b1;
            dwe_non_current = 1'b1;
            daddr_x         = DIV_REG1;
            nextState       = S_RECONF_D_WAIT_ACK_WRITE;
        end
        S_RECONF_O_INT_OVERWRITE_REG: 
        begin 
            din_x           = {dout_non_current[OUT0_REG1_PHASE_BITS_START:OUT0_REG1_RESERVED_BITS_END],Conf_Oi_int, Conf_Oi_int};
            den_non_current = 1'b1;
            dwe_non_current = 1'b1;
            daddr_x         = CLOCK_OUT0_REG1;
            nextState       = S_RECONF_O_INT_WAIT_ACK_WRITE;
        end
        S_RECONF_O_FRAC_OVERWRITE_REG: 
        begin 
            din_x           = {dout_non_current[OUT0_REG2_RESERVED_BITS_START:OUT0_REG2_RESERVED_BITS_END], Conf_Oi_frac, Conf_Oi_frac_en, dout_non_current[OUT0_REG2_FRAC_WF_R_BITS_START:OUT0_REG2_DELAY_TIME_BITS_END]};
            den_non_current = 1'b1;
            dwe_non_current = 1'b1;
            daddr_x         = CLOCK_OUT0_REG2;
            nextState       = S_RECONF_O_FRAC_WAIT_ACK_WRITE;
        end
        S_RECONF_M_WAIT_ACK_WRITE: 
        begin // data ready signals register write complete.
            
            if(drdy_non_current) 
            begin
                if( USE_D)       nextState  = S_RECONF_D_SUPPLY_ADDR;
                else             nextState  = S_RECONF_O_INT_SUPPLY_ADDR;
            end
            
        end
        S_RECONF_D_WAIT_ACK_WRITE: 
        begin // data ready signals register write complete.
            
            if(drdy_non_current) 
            begin
                nextState                   = S_RECONF_O_INT_SUPPLY_ADDR;
            end
            
        end
        S_RECONF_O_INT_WAIT_ACK_WRITE: 
        begin // data ready signals register write complete.
            
            if(drdy_non_current) 
            begin
                if( USE_FRACT_OI)   
                    nextState               = S_RECONF_O_FRAC_SUPPLY_ADDR;
                else                
                begin
                    nextState               = S_RECONF_END;
                    reset_non_current_next  = 1'b0;
                end
            end
        end
        S_RECONF_O_FRAC_WAIT_ACK_WRITE: 
        begin // data ready signals register write complete.
            
            if(drdy_non_current) 
            begin
                nextState                   = S_RECONF_END;
                reset_non_current_next      = 1'b0;
            end
            
        end
        S_RECONF_END:
        begin // wait till secondary FSM complete register updating.
            if( locked_int)  
            begin
                
                sel_next        = ~ sel;
                nextState       = S_IDLE;

                ack_o           = 1'b1;
            end
        end
        endcase

    end

    /////////////////////////////////////
    //          locked_o               //
    /////////////////////////////////////
    //assign locked_o = locked0 & locked1;
    assign locked_o = locked0 | locked1; 
    assign locked_int = locked0 & locked1;
    //////////////////////////////////////////////////////////////////
    //                       Module instances                       //
    //////////////////////////////////////////////////////////////////
    //BUFG clkin1_ibufg(
    //    .O              (clk        ),
    //    .I              (clk_in     )
    //);

    assign clk = clk_in;

    bram36 #(
        .READ_WIDTH(BRAM36_READ_WIDTH),
        .ADDR_WIDTH(BRAM36_ADDR_WIDTH)
    ) bram_for_configuration_storage (
        .clk(    clk                ),
        .reset(  bram_reset         ),
        .addr_i( bram_addr          ),
        .valid_i(bram_addr_valid    ),
        .data_o( bram_data          )
    );

    generate
    if( USE_DATA_O )
    begin
        bram18 #(
        .READ_WIDTH(BRAM18_READ_WIDTH),
        .ADDR_WIDTH(BRAM18_ADDR_WIDTH)
        ) bram_for_frequency_output_storage (
            .clk(    clk                ),
            .reset(  bram_reset         ),
            .addr_i( bram_addr          ),
            .valid_i(bram18_addr_valid  ),
            .data_o( bram18_data        )
        );
    end 
    endgenerate

    clk_wiz_0_clk_wiz #(
        .M(M),
        .D(D),
        .O(O),
        .CLOCK_INPUT_PERIOD(CLOCK_INPUT_PERIOD)
    ) mmcm_0    (
        .clk_in1        (clk        ),
        .clk_out1       (clk_out0   ),         
        .dclk           (clk        ),
        .den            (den0       ),
        .dwe            (dwe0       ),
        .daddr          (daddr0     ),
        .din            (din0       ),
        .dout           (dout0      ),
        .drdy           (drdy0      ),            
        .reset          (reset0     ), 
        .locked         (locked0    )
    );

    clk_wiz_0_clk_wiz #(
        .M(M),
        .D(D),
        .O(O),
        .CLOCK_INPUT_PERIOD(CLOCK_INPUT_PERIOD)
    ) mmcm_1 (
        .clk_in1        (clk        ),
        .clk_out1       (clk_out1   ),
        .dclk           (clk        ),
        .den            (den1       ),
        .dwe            (dwe1       ),
        .daddr          (daddr1     ),
        .din            (din1       ),
        .dout           (dout1      ),
        .drdy           (drdy1      ),            
        .reset          (reset1     ), 
        .locked         (locked1    )
    );

    (* dont_touch = "true" *)  BUFGMUX_CTRL clock_mux (
        .I0             (clk_out0   ),
        .I1             (clk_out1   ),
        .O              (clk_o_wire ),
        .S              (sel        )
    );
    
    
endmodule
