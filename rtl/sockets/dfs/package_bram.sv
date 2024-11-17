//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    package_bram.sv
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
//----------------------------------------------------------------------------

package bram_pkg;
parameter      BRAM36_READ_WIDTH                          = 36;
parameter      BRAM36_ADDR_WIDTH                          = 10;

parameter      BRAM36_LOOKUP_INT_BITS_START               = 35;
parameter      BRAM36_LOOKUP_INT_BITS_END                 = 26;
parameter      BRAM36_LOOKUP_SHIFT_BITS_START             = 25;                  
parameter      BRAM36_LOOKUP_SHIFT_BITS_END               = 23;                  
parameter      BRAM36_M_BITS_START                        = 22;                          
parameter      BRAM36_M_BITS_END                          = 17;             
parameter      BRAM36_D_BITS_START                        = 16;                          
parameter      BRAM36_D_BITS_END                          = 11;      
parameter      BRAM36_O_INT_BITS_START                    = 10;                         
parameter      BRAM36_O_INT_BITS_END                      =  5;              
parameter      BRAM36_O_FRAC_BITS_START                   =  4;                     
parameter      BRAM36_O_FRAC_BITS_END                     =  2;             
parameter      BRAM36_O_FRAC_EN_START                     =  1;                     
parameter      BRAM36_O_FRAC_EN_END                       =  1;     

parameter      BRAM18_READ_WIDTH                          = 18;
parameter      BRAM18_ADDR_WIDTH                          = 10;

parameter      BRAM18_FREQ_OBTAINED_BITS_START            = 17;
parameter      BRAM18_FREQ_OBTAINED_BITS_END              = 5;
endpackage : bram_pkg