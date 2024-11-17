//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    constFreq.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

`timescale 1ns / 1ps

module constFreq #(
        parameter DATA_WIDTH = 13,
        parameter N_FREQ = 6,
        parameter int FREQS[N_FREQ] = {60*8, 55*8, 50*8, 45*8, 40*8, 35*8},
        parameter PLL_FREQ = 1
    )(
        input  logic                                clk,
        input  logic                                rst,
        input  logic                                enable_i,
        output logic                         		constFreq2dfs_en,
        output logic  [DATA_WIDTH-1 : 0]            constFreq2dfs_data,	
        input  logic                        		dfs2constFreq_ack,
        input  logic  [8-1 : 0]                     freqData_in,
        input  logic                                freqEmpty_in
    );

    ////////////////////////////////////////////////////////////////////////////
    //							LOGIC ELEMENTS          					  //						
    ////////////////////////////////////////////////////////////////////////////
    typedef enum logic [2:0] {
        S_IDLE,
        S_WAIT_ACK,
        S_WAIT_NEW_FREQ
    } state;
    state                                state_current, state_next;

    logic                                constFreq2dfs_en_next;
    logic [8-1 : 0]                      freqData_reg, freqData_next;
    logic  [DATA_WIDTH-1 : 0]            constFreq2dfs_data_next;
    ////////////////////////////////////////////////////////////////////////////
    //							SEQUENTIAL ROUTINE      					  //						
    ////////////////////////////////////////////////////////////////////////////

    always_ff @( posedge clk ) begin 
        if(rst) begin     
            constFreq2dfs_data    <= FREQS[PLL_FREQ][0+:DATA_WIDTH];
            constFreq2dfs_en      <= '0;
            state_current         <= S_IDLE;
            freqData_reg          <= '0;
        end
        else begin
            //Frequency has a fixed value. Note that higher frequency values should occupy the lower positions in the FREQ array.
            constFreq2dfs_data <= constFreq2dfs_data_next;
            constFreq2dfs_en   <= constFreq2dfs_en_next;
            state_current      <= state_next;
            freqData_reg       <= freqData_next;
        end 
    end

    ////////////////////////////////////////////////////////////////////////////
    //							COMBINATIONAL ELEMENTS						  //						
    ////////////////////////////////////////////////////////////////////////////

    always_comb begin 
        state_next   			   = state_current;
        
        constFreq2dfs_data_next    = constFreq2dfs_data;
        constFreq2dfs_en_next      = '0;
        freqData_next              = freqData_reg;

        case (state_current)
        //If the module is enabled, raise the enable for the dfs and wait for the acknowledge, otherwise sleep
        S_IDLE: begin
            if(enable_i) begin
                constFreq2dfs_en_next       = 1'b1;
                state_next 				    = S_WAIT_ACK;
            end
            else
            begin
                state_next                  = S_WAIT_NEW_FREQ;
            end
        end
        //Wait for the aknowledge (it isn't really needed in such a simple module)
        S_WAIT_ACK: begin
            if(dfs2constFreq_ack) begin
                state_next                  = S_WAIT_NEW_FREQ;
            end  
        end
        //Wait for a new freq
        S_WAIT_NEW_FREQ:
        begin
            if (enable_i && !freqEmpty_in)
            begin
                freqData_next = freqData_in;
                if(freqData_in != freqData_reg)
                begin
                    constFreq2dfs_en_next       = 1'b1;
                    constFreq2dfs_data_next     = FREQS[freqData_in][0+:DATA_WIDTH];
                    state_next                  = S_WAIT_ACK;
                end
            end
        end
        endcase 
    end
    
    
endmodule

