//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    freq_changer.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

`timescale 1ns / 1ps

module freq_changer #(
        parameter DATA_WIDTH = 13,
        parameter N_FREQ = 6,
        parameter int FREQS[N_FREQ] = {35*8, 40*8, 45*8, 50*8, 55*8, 60*8},
        parameter NUM_COUNTS_DELAY = 50
    )(
        input  logic                                clk,
        input  logic                                rst,
        input  logic                                enable_i,
        //DFS interface
        output logic                         		freqChanger2dfs_en,
        output logic  [DATA_WIDTH-1 : 0]            freqChanger2dfs_data,	
        input  logic                        		dfs2freqChanger_ack
    );

    
    typedef enum logic [1:0] {
        S_IDLE,
        S_WAIT_COMPLETION,
        S_GETRND,
        S_CYCLE
    } state;

    ////////////////////////////////////////////////////////////////////////////
    //							SEQUENTIAL ELEMENTS	     					  //						
    ////////////////////////////////////////////////////////////////////////////
    
    // - register for status to wait dfs reconfiguration
    state 				            state_cur, state_next;
    
    logic                           start_count, start_count_next;
    logic                           finish_count;
    
    logic  [DATA_WIDTH-1 : 0]       freqChanger2dfs_data_next;
    logic                           freqChanger2dfs_en_next;

    logic [$clog2(N_FREQ) -1 :0]    idx_freq_rnd;
    logic                           rnd_req;

    logic [$clog2(N_FREQ) -1 :0]    trng_counter, trng_counter_next;
    logic [$clog2(N_FREQ) -1 :0]    idx_freq_ff;

    always_ff @( posedge clk ) begin 
        if(rst) begin
            state_cur 	            <= S_IDLE;
            start_count             <= '0;          
            freqChanger2dfs_data    <= '0;
            freqChanger2dfs_en      <= '0;
        end
        else begin
            state_cur 	         <= state_next;
            start_count          <= start_count_next;
            freqChanger2dfs_data <= freqChanger2dfs_data_next;
            freqChanger2dfs_en   <= freqChanger2dfs_en_next;
        end 
    end

    ////////////////////////////////////////////////////////////////////////////
    //							COMBINATIONAL ELEMENTS						  //						
    ////////////////////////////////////////////////////////////////////////////

    always_comb begin 
        state_next   			   = state_cur;
        
        start_count_next           = start_count;
        
        freqChanger2dfs_data_next  = freqChanger2dfs_data;
        freqChanger2dfs_en_next    = '0;
        rnd_req                    = '0;

        case (state_cur)
        S_IDLE: begin
            if(enable_i) begin
                start_count_next            = '0;
                freqChanger2dfs_en_next     = 1'b1;
                freqChanger2dfs_data_next 	= FREQS[idx_freq_rnd][0+:DATA_WIDTH];
                state_next 				    = S_WAIT_COMPLETION;
            end
        end
        S_WAIT_COMPLETION: begin
            start_count_next    = 1'b1;  
            if(dfs2freqChanger_ack) begin
                state_next      = S_GETRND;
                rnd_req         = 1'b1;
            end  
        end
        S_GETRND: begin
            if(idx_freq_rnd<N_FREQ)
                state_next = S_CYCLE;
            else
                rnd_req    = 1'b1;
        end
        S_CYCLE: begin
            if (finish_count) begin
                freqChanger2dfs_en_next     = 1'b1;
                freqChanger2dfs_data_next 	= FREQS[idx_freq_rnd][0+:DATA_WIDTH];
                
                state_next 				    = S_WAIT_COMPLETION;
                start_count_next            = 1'b0;
            end  
        end
        endcase 
    end
    
    counterDFS #(
        .NUM_COUNTS (NUM_COUNTS_DELAY)
    ) counterWait (
        .clk        (clk         ),
        .en         (start_count ),
        .finish     (finish_count)
    );

    // simple process to select a frequency in a pseudo-random way
    
    //Standard sequential routine
    always_ff @( posedge clk ) begin
        if(rst) begin
            trng_counter <= '0;
            idx_freq_rnd <= '0;
        end
        else begin
            trng_counter <= trng_counter_next;
            idx_freq_rnd <= idx_freq_ff;
        end
    end

    //Combinatorial routine
    always_comb begin
        if(rst)
        begin
            idx_freq_ff = '0;
            trng_counter_next = '0;
        end
        else
        begin
            trng_counter_next = trng_counter + 1;
            //When the counter has finished, it increases the frequency selector of one
            if(rnd_req)
                idx_freq_ff = idx_freq_rnd + 1;
            else
                idx_freq_ff = idx_freq_rnd;
        end
    end

endmodule

//A separated module for the counter
module counterDFS #(parameter NUM_COUNTS=50)
(
    input logic         clk,
    input logic         en,
    output logic        finish
);
    logic [15:0]        count, count_next;
    logic               finish_next;
    
    
    always_ff @( posedge clk )
    begin
        if(~en)
        begin
            count 	<= '0;
            finish  <= 1'b0;
        end
        else
        begin
            count  <= count_next;
            finish <= finish_next;
        end
    end
    
    always_comb 
    begin
        count_next  = count + 1;
        finish_next = finish;
        
        if (count == NUM_COUNTS-1) begin
            finish_next= 1'b1;
            count_next = count;
        end
    end
endmodule
