//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    esp.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//----------------------------------------------------------------------------

package my_uart_pkg;

    // UART_CLK_DIV_DEF           = clk / (16 * baud_rate)
    // SIM_UART_NUM_CLK_TICKS_BIT = clk / baud_rate


// BaudRate 1000000 bit/s @ 50MHz

    //parameter UART_CLK_DIV_DEF 				=	8'd3; 
	//parameter SIM_HALF_CLK_PERIOD_DEF       =	10; 
	//parameter SIM_UART_NUM_CLK_TICKS_BIT    =	50;

// BaudRate 115200 bit/s @ 50MHz

    //parameter UART_CLK_DIV_DEF 				=	8'd27; 
	//parameter SIM_HALF_CLK_PERIOD_DEF       =	10; 
	//parameter SIM_UART_NUM_CLK_TICKS_BIT    =	434;
	
// BaudRate 38400 bit/s @ 100MHz
   parameter UART_CLK_DIV_DEF              =   8'd163;
   parameter SIM_HALF_CLK_PERIOD_DEF       =   5;
   parameter SIM_UART_NUM_CLK_TICKS_BIT    =   2604;


// BaudRate 38400 bit/s @ 50MHz
//    parameter UART_CLK_DIV_DEF              =   8'd81;
//    parameter SIM_HALF_CLK_PERIOD_DEF       =   10;
//    parameter SIM_UART_NUM_CLK_TICKS_BIT    =   1302;



    parameter UART_NUM_CLK_TICKS_BIT 		= SIM_UART_NUM_CLK_TICKS_BIT;
    parameter UART_NUM_DWORD_BITS			= 8;
	parameter UART_NUM_STOP_BITS			= 1;
endpackage
 
