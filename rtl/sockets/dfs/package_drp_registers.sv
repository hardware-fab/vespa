//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    package_drp_registers.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

package drp_register_pkg;

parameter      REG_DATA_WIDTH                          = 16;
parameter      REG_ADDRESS_WIDTH                       = 7;
                
parameter      CLOCK_OUT0_REG1                         = 7'h08;
parameter      CLOCK_OUT0_REG2                         = 7'h09;
parameter      CLOCK_OUT1_REG1                         = 7'h0a;
parameter      CLOCK_OUT1_REG2                         = 7'h0b;
parameter      CLOCK_FBOUT_REG1                        = 7'h14;
parameter      CLOCK_FBOUT_REG2                        = 7'h15;
parameter      DIV_REG1                                = 7'h16;

parameter      OUT0_REG1_PHASE_BITS_START              = 15;
parameter      OUT0_REG1_PHASE_BITS_END                = 13;
parameter      OUT0_REG1_RESERVED_BITS_START           = 12;
parameter      OUT0_REG1_RESERVED_BITS_END             = 12;
parameter      OUT0_REG1_HIGH_BITS_START               = 11;
parameter      OUT0_REG1_HIGH_BITS_END                 =  6;
parameter      OUT0_REG1_LOW_BITS_START                =  5;
parameter      OUT0_REG1_LOW_BITS_END                  =  0;

parameter      OUT0_REG2_RESERVED_BITS_START           = 15;
parameter      OUT0_REG2_RESERVED_BITS_END             = 15;
parameter      OUT0_REG2_FRAC_BITS_START               = 14;
parameter      OUT0_REG2_FRAC_BITS_END                 = 12;
parameter      OUT0_REG2_FRAC_EN_BITS_START            = 11;
parameter      OUT0_REG2_FRAC_EN_BITS_END              = 11;
parameter      OUT0_REG2_FRAC_WF_R_BITS_START          = 10;
parameter      OUT0_REG2_FRAC_WF_R_BITS_END            = 10;
parameter      OUT0_REG2_MX_BITS_START                 =  9;
parameter      OUT0_REG2_MX_BITS_END                   =  8;
parameter      OUT0_REG2_EDGE_BITS_START               =  7;  
parameter      OUT0_REG2_EDGE_BITS_END                 =  7;                 
parameter      OUT0_REG2_NO_COUNT_BITS_START           =  6; 
parameter      OUT0_REG2_NO_COUNT_BITS_END             =  6; 
parameter      OUT0_REG2_DELAY_TIME_BITS_START         =  5;
parameter      OUT0_REG2_DELAY_TIME_BITS_END           =  0;

parameter      CLOCK_FBOUT_REG1_PHASE_BITS_START       = 15;
parameter      CLOCK_FBOUT_REG1_PHASE_BITS_END         = 13;
parameter      CLOCK_FBOUT_REG1_RESERVED_BITS_START    = 12;
parameter      CLOCK_FBOUT_REG1_RESERVED_BITS_END      = 12;
parameter      CLOCK_FBOUT_REG1_HIGH_BITS_START        = 11;
parameter      CLOCK_FBOUT_REG1_HIGH_BITS_END          =  6;
parameter      CLOCK_FBOUT_REG1_LOW_BITS_START         =  5;
parameter      CLOCK_FBOUT_REG1_LOW_BITS_END           =  0;

parameter      CLOCK_FBOUT_REG2_RESERVED_BITS_START    = 15;
parameter      CLOCK_FBOUT_REG2_RESERVED_BITS_END      = 15;
parameter      CLOCK_FBOUT_REG2_FRAC_BITS_START        = 14;
parameter      CLOCK_FBOUT_REG2_FRAC_BITS_END          = 12;
parameter      CLOCK_FBOUT_REG2_FRAC_EN_BITS_START     = 11;
parameter      CLOCK_FBOUT_REG2_FRAC_EN_BITS_END       = 11;
parameter      CLOCK_FBOUT_REG2_FRAC_WF_R_BITS_START   = 10;
parameter      CLOCK_FBOUT_REG2_FRAC_WF_R_BITS_END     = 10;
parameter      CLOCK_FBOUT_REG2_MX_BITS_START          =  9;
parameter      CLOCK_FBOUT_REG2_MX_BITS_END            =  8;
parameter      CLOCK_FBOUT_REG2_EDGE_BITS_START        =  7;  
parameter      CLOCK_FBOUT_REG2_EDGE_BITS_END          =  7;                 
parameter      CLOCK_FBOUT_REG2_NO_COUNT_BITS_START    =  6; 
parameter      CLOCK_FBOUT_REG2_NO_COUNT_BITS_END      =  6; 
parameter      CLOCK_FBOUT_REG2_DELAY_TIME_BITS_START  =  5;
parameter      CLOCK_FBOUT_REG2_DELAY_TIME_BITS_END    =  0;

parameter      DIV_REG1_RESERVED_BITS_START            = 15; 
parameter      DIV_REG1_RESERVED_BITS_END              = 14;
parameter      DIV_REG1_EDGE_BITS_START                = 13; 
parameter      DIV_REG1_EDGE_BITS_END                  = 13;         
parameter      DIV_REG1_NO_COUNT_BITS_START            = 12;
parameter      DIV_REG1_NO_COUNT_BITS_END              = 12;
parameter      DIV_REG1_HIGH_BITS_START                = 11;
parameter      DIV_REG1_HIGH_BITS_END                  =  6;    
parameter      DIV_REG1_LOW_BITS_START                 =  5;
parameter      DIV_REG1_LOW_BITS_END                   =  0;

endpackage : drp_register_pkg