//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    copy_results.py
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------


`timescale 1ns/1ps

module my_testbench();

  import my_uart_pkg::*;

  parameter SIMULATION  = 1;
  parameter HALF_CLOCK_PROFPGA = 5;
  parameter HALF_CLOCK_DDR3 = 3.125;
  parameter HALF_CLOCK_REF = 2.5;
  parameter HALF_CLOCK_UART = 5;

  parameter ADDR_WIDTH = 32;
  parameter WORD_WIDTH = 32;
  parameter LEN_WIDTH = 6;
  //parameter PACKET_SIZE_MIN = (ADDR_WIDTH/8) + 1; //Packet size in bytes without data
  
   //Ethernet signals
  logic reset_o2 ;
  logic etx_clk  ;
  logic erx_clk  ;
  logic  [7 : 0] erxdt   ;
  logic erx_dv   ;
  logic erx_er   ;
  logic erx_col  ;
  logic erx_crs  ;
  logic [7 : 0] etxdt    ;
  logic etx_en   ;
  logic etx_er   ;
  logic emdc     ;
  wire emdio    ;


  logic tft_nhpd        ;
  logic tft_clk_p       ;
  logic tft_clk_n       ;
  logic [23 : 0] tft_data        ;
  logic tft_hsync       ;
  logic tft_vsync       ;
  logic tft_de          ;
  logic tft_dken        ;
  logic tft_ctl1_a1_dk1 ;
  logic tft_ctl2_a2_dk2 ;
  logic tft_a3_dk3      ;
  logic tft_isel        ;
  logic tft_bsel        ;
  logic tft_dsel        ;
  logic tft_edge        ;
  logic tft_npd         ;

  //clock and reset
  logic reset          = 1;
  logic c0_main_clk_p  = 0;
  logic c0_main_clk_n  = 1;
  logic c1_main_clk_p  = 0;
  logic c1_main_clk_n  = 1;
  logic clk_ref_p      = 0;
  logic clk_ref_n      = 1;


  //UART
  logic uart_rxd  ;
  logic uart_txd  ;
  logic uart_cts ;
  logic uart_rts;



  logic profpga_clk0_p   = 0;  // 100 MHz clock
  logic profpga_clk0_n   = 1;  // 100 MHz clock
  logic profpga_sync0_p ;
  logic profpga_sync0_n ;
  logic  [19 : 0] dmbi_h2f       ;
  logic [19 : 0] dmbi_f2h        ;


  //Other signals
  logic tb_uart_txd;
  logic tb_uart_rxd;
  logic clk;
  logic uart_clk, tb_uart_tick;

  //Top module instantiation
  top #( .SIMULATION (SIMULATION)
      ) top_inst (
      // MMI64
      .profpga_clk0_p    ( profpga_clk0_p),
      .profpga_clk0_n    ( profpga_clk0_n),
      .profpga_sync0_p   ( profpga_sync0_p),
      .profpga_sync0_n   ( profpga_sync0_n),
      .dmbi_h2f          ( dmbi_h2f),
      .dmbi_f2h          ( dmbi_f2h),
      .reset             ( reset),
      //.c0_main_clk_p     ( c0_main_clk_p),
      //.c0_main_clk_n     ( c0_main_clk_n),
      //.c1_main_clk_p     ( c1_main_clk_p),
      //.c1_main_clk_n     ( c1_main_clk_n),
      //.clk_ref_p         ( clk_ref_p),
      //.clk_ref_n         ( clk_ref_n),
      .c0_calib_complete ( open),
      .c1_calib_complete ( open),
      .uart_rxd          ( uart_rxd),
      .uart_txd          ( uart_txd),
      .uart_cts         ( uart_cts),
      .uart_rts         ( uart_rts),
      .reset_o2          ( reset_o2),
      //.etx_clk           ( etx_clk),
      //.erx_clk           ( erx_clk),
      .erxd              ( erxdt[3 : 0]),
      .erx_dv            ( erx_dv),
      .erx_er            ( erx_er),
      .erx_col           ( erx_col),
      .erx_crs           ( erx_crs),
      .etxd              ( etxdt[3 : 0]),
      .etx_en            ( etx_en),
      .etx_er            ( etx_er),
      .emdc              ( emdc),
      .emdio             ( emdio),
      .tft_nhpd          ( 1'b0),
      .tft_clk_p         ( tft_clk_p),
      .tft_clk_n         ( tft_clk_n),
      .tft_data          ( tft_data),
      .tft_hsync         ( tft_hsync),
      .tft_vsync         ( tft_vsync),
      .tft_de            ( tft_de),
      .tft_dken          ( tft_dken),
      .tft_ctl1_a1_dk1   ( tft_ctl1_a1_dk1),
      .tft_ctl2_a2_dk2   ( tft_ctl2_a2_dk2),
      .tft_a3_dk3        ( tft_a3_dk3),
      .tft_isel          ( tft_isel),
      .tft_bsel          ( tft_bsel),
      .tft_dsel          ( tft_dsel),
      .tft_edge          ( tft_edge),
      .tft_npd           ( tft_npd),
      
      .LED_RED           ( open),
      .LED_GREEN         ( open),
      .LED_BLUE          ( open),
      .LED_YELLOW        ( open),
      .c0_diagnostic_led ( open),
      .c1_diagnostic_led ( open)
      );


  //Top module signals
  


  
  assign tb_uart_rxd = uart_txd;
  assign uart_rxd = tb_uart_txd;
  assign clk = profpga_clk0_p;
  
  always #HALF_CLOCK_PROFPGA profpga_clk0_p =~ profpga_clk0_p;
  always #HALF_CLOCK_PROFPGA profpga_clk0_n =~ profpga_clk0_n;
  
  always #HALF_CLOCK_DDR3 c0_main_clk_p =~ c0_main_clk_p;
  always #HALF_CLOCK_DDR3 c0_main_clk_n =~ c0_main_clk_n;
  always #HALF_CLOCK_DDR3 c1_main_clk_p =~ c1_main_clk_p;
  always #HALF_CLOCK_DDR3 c1_main_clk_n =~ c1_main_clk_n;
  
  always #HALF_CLOCK_REF clk_ref_p =~ clk_ref_p;
  always #HALF_CLOCK_REF clk_ref_n =~ clk_ref_n;
  
  always #HALF_CLOCK_UART uart_clk =~ uart_clk;
  always #(HALF_CLOCK_UART*UART_NUM_CLK_TICKS_BIT) tb_uart_tick =~ tb_uart_tick;

  initial
  begin
    profpga_clk0_p <= 0;
    profpga_clk0_n <= 1;
    c0_main_clk_p <= 0;
    c0_main_clk_n <= 1;
    c1_main_clk_p <= 0;
    c1_main_clk_n <= 1;
    clk_ref_p <= 0;
    clk_ref_n <= 1;
    profpga_sync0_p <= 0;
    profpga_sync0_n <= 1;
    dmbi_h2f        = 'b0;
    reset = 1;
    tb_uart_txd = 1;
    uart_cts = 0;
    uart_clk = 0;
    tb_uart_tick = 0;
    repeat(100) @(posedge clk);
    reset         <= 0;
    
    //Send reset 4 times
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    //sendPacketUart( .write(1'b1), .data_len('b0), .addr(32'h60000400), .data_in(32'h00000001));
    //repeat(10000) @(posedge clk);
    repeat(1000000000) @(posedge clk);
    $finish;
  end
  
  
  ////////////////////////////////////////////////////////////////
	// TASK TO DULOCAL TRANSACTION SEND TOKEN RECEIVE RESPONSE 	////
	// THE UART USING THE PADS									////
	////////////////////////////////////////////////////////////////
	//task automatic TASK_duLocalTransaction;
	//	input duTokenType_t 	duLoc_m2s_tokenType;
	//	input [DU_CPUIDW-1:0]	duLoc_m2s_cpuid;
	//	input [DU_ADRW-1:0]		duLoc_m2s_adr;
	//	input [DU_DATW-1:0]		duLoc_m2s_dat;
  //
	//	output Response_t   duLoc_respArray;		
	//	integer duLoc_iterSend	= 0;
	//	integer duLoc_iterResp	= 0;
	//	
	//	@(posedge clk);
	//	fork
	//		//SEND TOKENS
	//		begin
	//			sendTokenUart(
	//				{duLoc_m2s_cpuid, duLoc_m2s_tokenType },
	//				{duLoc_m2s_adr }, //32bit adr
	//				{duLoc_m2s_dat }	//32bit dat
	//			);
	//		end
	//		
	//		// WAIT ACK OVER UART
	//		begin
	//			recvByteUart(recv_data);
	//			duLoc_respArray[HPOS_BIT_ACK_ERR_DU2H -:8 ] = recv_data;
	//			// data resp
	//			if(FUNC_isWriteToken ({ duLoc_m2s_cpuid, duLoc_m2s_tokenType  }) )
	//			begin
	//				duLoc_respArray[NUM_BYTE_DAT_DU2H*8-1:0] =32'b0;
	//			end
	//			else
	//			begin
	//				for(duLoc_iterResp=0; duLoc_iterResp<NUM_BYTE_DAT_DU2H; duLoc_iterResp=duLoc_iterResp+1)
	//				begin	// WAIT ACK+DATA OVER UART
	//					recvByteUart(recv_data);
	//					duLoc_respArray[HPOS_BIT_DAT_DU2H - (duLoc_iterResp*8) -:8] = recv_data;
	//				end
  //
	//			end
	//			$display("@%0t: %m DUT response ackErr: 0x%h data: 0x%h",
	//					$time,
	//					duLoc_respArray[HPOS_BIT_ACK_ERR_DU2H:LPOS_BIT_ACK_ERR_DU2H], 
	//					duLoc_respArray[HPOS_BIT_DAT_DU2H:LPOS_BIT_DAT_DU2H]	);
	//		end
	//	join
	//endtask

	////////////////////////////////////////////////
	// TASK TO SEND A duTOKEN TO 				////
	// THE UART USING THE PADS					////
	////////////////////////////////////////////////
	task sendPacketUart;
		input logic write; //Write or read
		input logic [LEN_WIDTH-1:0] data_len; //Length of data only (in bytes)
		input logic [ADDR_WIDTH-1:0] addr;  //Starting address
		input logic [WORD_WIDTH-1:0] data_in;  //Data (TODO let data have an arbitrary length up to data_len)
	
		automatic logic [3:0] iSendTokenUart='d0;
		automatic logic [UART_NUM_DWORD_BITS-1:0] tx_data;
		
		begin
			iSendTokenUart = 'd0;
			@(posedge uart_clk);
			$display("TASK sendTokenUart:\t%m write=%d, data_len=%d, adr=%h, data=%h",$time,write,data_len, addr, data_in);
		//SEND_CMD
			begin
				sendByteUart({1'b1, write, data_len});
				iSendTokenUart = iSendTokenUart+'d1;
				@(posedge uart_clk);
			end
			
		//SEND ADDR
			iSendTokenUart = 'd0;
			@(posedge uart_clk);
			repeat(ADDR_WIDTH/8) 
			begin		
				sendByteUart(addr[(ADDR_WIDTH/8-iSendTokenUart)*8-1 -:8]);
				iSendTokenUart = iSendTokenUart+'d1;
				@(posedge uart_clk);
			end
			
		//SEND DATA
      iSendTokenUart = 'd0;
      @(posedge uart_clk);
      repeat((WORD_WIDTH/8)*(data_len + 1))
      begin
        sendByteUart(data_in[(WORD_WIDTH/8-iSendTokenUart)*8-1 -: 8]);
        iSendTokenUart = iSendTokenUart+'d1;
        @(posedge uart_clk);
      end
		end

	endtask: sendPacketUart
	
	////////////////////////////////////////////////
	// TASK TO SEND BYTE TO 					////
	// THE UART USING THE PADS					////
	////////////////////////////////////////////////
	task automatic sendByteUart;
		input [UART_NUM_DWORD_BITS-1:0] txData; // 8 bit
		automatic integer iSendByteUart;
		begin
			assert(tb_uart_txd==1); //check tx == 1 if not sending
			@(posedge uart_clk);
	
			$display("@%0t: START %m(%b)",$time,txData);
			
		//start bit is 0 in uart communication protocol
			tb_uart_txd = '0;
			iSendByteUart	 = 'd0;
			repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
		// send the payload, namely 8 bits
			repeat(UART_NUM_DWORD_BITS)
			begin
				tb_uart_txd = txData[iSendByteUart];
				//$display("@%0t: BIT %m(%b)",$time,tbSysUartTx);
				iSendByteUart    = iSendByteUart+'d1;
				repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
			end
		// send stop bit/s, that is/are 1
			repeat(UART_NUM_STOP_BITS)
			begin
				tb_uart_txd = '1;
				repeat(UART_NUM_CLK_TICKS_BIT) @(posedge uart_clk);
			end
		// line is 1 when idle, thus keep it set to 1
		end
	endtask: sendByteUart
	
endmodule:my_testbench
