//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    clockManager.py
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

module clockManager #(
    parameter PLL_FREQ = 1,
    parameter RANDOM_FREQ = 0  // Choose between random frequency and user-selected frequency
)
(
	input  logic rst_in,
	input  logic clk_in,
	(* dont_touch = "true" *) output logic mmcm_clk_o,
	output logic mmcm_locked_o,          
    input logic [8-1 : 0] freq_data_in,
    input logic freq_empty_in
	);

    //dfs produces a clock with variable frequency for the soc/specific cpu
    parameter DATA_WIDTH = 13 ;

    logic  [DATA_WIDTH-1 : 0]     data_i, data_freqChanger2dfs, data_constFreq2dfs;
    logic                         en_i, en_freqChanger2dfs, en_constFreq2dfs;
    logic  [DATA_WIDTH-1 : 0]     data_o;
    logic                         ack_o;
    logic                         locked_int;

    logic                         rst_active_high;
    
    assign rst_active_high        = ~rst_in;  
    assign mmcm_locked_o          = locked_int;     
    
    //Main DFS module
    dfs_top #(  
        .CLOCK_INPUT_PERIOD        (20.000),
        .USE_FRACT_OI              (1),
        .USE_D                     (1),
        .USE_DATA_O                (1),
        .USE_REG_FOR_DATA_I        (1),
        .ON_RESET_RESTORE_DEFAULT_F(0)
    ) dfs_inst (
        .clk_in                    (clk_in),
        .reset                     (rst_active_high),
        .en_i                      (en_i),
        .data_i                    (data_i), 
        .ack_o                     (ack_o),
        .data_o                    (data_o),
        .locked_o                  (locked_int),
        .clk_o                     (mmcm_clk_o)
    );

    constFreq #(
        .DATA_WIDTH             (DATA_WIDTH),
        .N_FREQ                 (20),
        //.FREQS                  ({50*8, 45*8, 40*8, 35*8, 30*8, 25*8})
        //.FREQS                  ({100*8, 95*8, 90*8, 85*8, 80*8, 75*8, 70*8, 65*8, 60*8, 55*8, 50*8, 45*8, 40*8, 35*8, 30*8, 25*8, 20*8, 15*8, 10*8, 5*8})
        .FREQS                  ({5*8, 10*8, 15*8, 20*8, 25*8, 30*8, 35*8, 40*8, 45*8, 50*8, 55*8, 60*8, 65*8, 70*8, 75*8, 80*8, 85*8, 90*8, 95*8, 100*8})
        //.FREQS                    ({1*8, 2*8, 3*8, 4*8, 5*8, 6*8, 7*8, 8*8, 9*8, 10*8, 11*8, 12*8, 13*8, 14*8, 15*8, 16*8, 17*8, 18*8, 19*8, 20*8, 21*8, 22*8, 23*8, 24*8, 25*8, 26*8, 27*8, 28*8, 29*8, 30*8, 31*8, 32*8, 33*8, 34*8, 35*8, 36*8, 37*8, 38*8, 39*8, 40*8, 41*8, 42*8, 43*8, 44*8, 45*8, 46*8, 47*8, 48*8, 49*8, 50*8, 51*8, 52*8, 53*8, 54*8, 55*8, 56*8, 57*8, 58*8, 59*8, 60*8, 61*8, 62*8, 63*8, 64*8, 65*8, 66*8, 67*8, 68*8, 69*8, 70*8, 71*8, 72*8, 73*8, 74*8, 75*8, 76*8, 77*8, 78*8, 79*8, 80*8, 81*8, 82*8, 83*8, 84*8, 85*8, 86*8, 87*8, 88*8, 89*8, 90*8, 91*8, 92*8, 93*8, 94*8, 95*8, 96*8, 97*8, 98*8, 99*8, 100*8})
    ) constFreq_inst (
        .clk              	    (clk_in                    ),
		.rst              	    (rst_active_high           ),
        .enable_i               (1'b1), //~RANDOM_FREQ              ),
		.constFreq2dfs_en       (en_constFreq2dfs          ),
		.constFreq2dfs_data     (data_constFreq2dfs        ),
		.dfs2constFreq_ack      (ack_o                     ),
		.freqData_in            (freq_data_in              ),
		.freqEmpty_in           (freq_empty_in             )
    );


//A module that requests random frequencies to the DFS
    //freq_changer #(
    //    .N_FREQ              (6),
    //    .FREQS               ({50*8, 45*8, 40*8, 35*8, 30*8, 25*8}),
    //    .NUM_COUNTS_DELAY    (3_000)
    //) frequency_changer_inst (
    //    .clk              	 (clk_in),
	//	.rst              	 (rst_active_high | ~RANDOM_FREQ),
    //    .enable_i            (RANDOM_FREQ),
	//	.freqChanger2dfs_en  (en_freqChanger2dfs),
	//	.freqChanger2dfs_data(data_freqChanger2dfs),
	//	.dfs2freqChanger_ack (ack_o)
    //);
	
    //Choose among the user-selected and the random frequency requests for the DFS
    //assign en_i   = RANDOM_FREQ ? en_freqChanger2dfs   : en_constFreq2dfs;
    //assign data_i = RANDOM_FREQ ? data_freqChanger2dfs : data_constFreq2dfs;
    
    assign en_i   = en_constFreq2dfs;
    assign data_i = data_constFreq2dfs;
endmodule
