// ================================================================
// NVDLA Open Source Project
// 
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with 
// this distribution for more information.
// ================================================================

// File Name: nv_ram_rws_512x64.v
`include "NV_NVDLA_define.vh"

`timescale 1ns / 10ps
module nv_ram_rws_512x64 (
        clk,
        ra,
        re,
        dout,
        wa,
        we,
        di,
        pwrbus_ram_pd
        );
parameter FORCE_CONTENTION_ASSERTION_RESET_ACTIVE=1'b0;

// port list
input           clk;
input  [8:0]    ra;
input           re;
output [63:0]   dout;
input  [8:0]    wa;
input           we;
input  [63:0]   di;
input  [31:0]   pwrbus_ram_pd;



// This wrapper consists of :  1 Ram cells: RAMPDP_512X64_GL_M4_D2 ;  

//Wires for Misc Ports 
wire  DFT_clamp;

//Wires for Mbist Ports 
wire [8:0] mbist_Wa_w0;
wire [1:0] mbist_Di_w0;
wire  mbist_we_w0;
wire [8:0] mbist_Ra_r0;

// verilint 528 off - Variable set but not used
wire [63:0] mbist_Do_r0_int_net;
// verilint 528 on - Variable set but not used
wire  mbist_ce_r0;
wire  mbist_en_sync;

//Wires for RamAccess Ports 
wire  SI;

// verilint 528 off - Variable set but not used
wire  SO_int_net;
// verilint 528 on - Variable set but not used
wire  shiftDR;
wire  updateDR;
wire  debug_mode;

//Wires for Misc Ports 
wire  mbist_ramaccess_rst_;
wire  ary_atpg_ctl;
wire  write_inh;
wire  scan_ramtms;
wire  iddq_mode;
wire  jtag_readonly_mode;
wire  ary_read_inh;
wire  scan_en;
wire [7:0] svop;

// Use Bbox and clamps to clamp and tie off the DFT signals in the wrapper 
NV_BLKBOX_SRC0 UI_enableDFTmode_async_ld_buf (.Y(DFT_clamp));
wire pre_mbist_Wa_w0_0;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_0 (.Y(pre_mbist_Wa_w0_0));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_0 (.Z(mbist_Wa_w0[0]), .A1(pre_mbist_Wa_w0_0), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_1;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_1 (.Y(pre_mbist_Wa_w0_1));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_1 (.Z(mbist_Wa_w0[1]), .A1(pre_mbist_Wa_w0_1), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_2;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_2 (.Y(pre_mbist_Wa_w0_2));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_2 (.Z(mbist_Wa_w0[2]), .A1(pre_mbist_Wa_w0_2), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_3;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_3 (.Y(pre_mbist_Wa_w0_3));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_3 (.Z(mbist_Wa_w0[3]), .A1(pre_mbist_Wa_w0_3), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_4;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_4 (.Y(pre_mbist_Wa_w0_4));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_4 (.Z(mbist_Wa_w0[4]), .A1(pre_mbist_Wa_w0_4), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_5;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_5 (.Y(pre_mbist_Wa_w0_5));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_5 (.Z(mbist_Wa_w0[5]), .A1(pre_mbist_Wa_w0_5), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_6;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_6 (.Y(pre_mbist_Wa_w0_6));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_6 (.Z(mbist_Wa_w0[6]), .A1(pre_mbist_Wa_w0_6), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_7;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_7 (.Y(pre_mbist_Wa_w0_7));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_7 (.Z(mbist_Wa_w0[7]), .A1(pre_mbist_Wa_w0_7), .A2(DFT_clamp) );
wire pre_mbist_Wa_w0_8;
NV_BLKBOX_SRC0_X testInst_mbist_Wa_w0_8 (.Y(pre_mbist_Wa_w0_8));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Wa_w0_8 (.Z(mbist_Wa_w0[8]), .A1(pre_mbist_Wa_w0_8), .A2(DFT_clamp) );
wire pre_mbist_Di_w0_0;
NV_BLKBOX_SRC0_X testInst_mbist_Di_w0_0 (.Y(pre_mbist_Di_w0_0));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Di_w0_0 (.Z(mbist_Di_w0[0]), .A1(pre_mbist_Di_w0_0), .A2(DFT_clamp) );
wire pre_mbist_Di_w0_1;
NV_BLKBOX_SRC0_X testInst_mbist_Di_w0_1 (.Y(pre_mbist_Di_w0_1));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Di_w0_1 (.Z(mbist_Di_w0[1]), .A1(pre_mbist_Di_w0_1), .A2(DFT_clamp) );
wire pre_mbist_we_w0;
NV_BLKBOX_SRC0_X testInst_mbist_we_w0 (.Y(pre_mbist_we_w0));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_we_w0 (.Z(mbist_we_w0), .A1(pre_mbist_we_w0), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_0;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_0 (.Y(pre_mbist_Ra_r0_0));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_0 (.Z(mbist_Ra_r0[0]), .A1(pre_mbist_Ra_r0_0), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_1;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_1 (.Y(pre_mbist_Ra_r0_1));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_1 (.Z(mbist_Ra_r0[1]), .A1(pre_mbist_Ra_r0_1), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_2;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_2 (.Y(pre_mbist_Ra_r0_2));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_2 (.Z(mbist_Ra_r0[2]), .A1(pre_mbist_Ra_r0_2), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_3;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_3 (.Y(pre_mbist_Ra_r0_3));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_3 (.Z(mbist_Ra_r0[3]), .A1(pre_mbist_Ra_r0_3), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_4;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_4 (.Y(pre_mbist_Ra_r0_4));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_4 (.Z(mbist_Ra_r0[4]), .A1(pre_mbist_Ra_r0_4), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_5;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_5 (.Y(pre_mbist_Ra_r0_5));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_5 (.Z(mbist_Ra_r0[5]), .A1(pre_mbist_Ra_r0_5), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_6;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_6 (.Y(pre_mbist_Ra_r0_6));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_6 (.Z(mbist_Ra_r0[6]), .A1(pre_mbist_Ra_r0_6), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_7;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_7 (.Y(pre_mbist_Ra_r0_7));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_7 (.Z(mbist_Ra_r0[7]), .A1(pre_mbist_Ra_r0_7), .A2(DFT_clamp) );
wire pre_mbist_Ra_r0_8;
NV_BLKBOX_SRC0_X testInst_mbist_Ra_r0_8 (.Y(pre_mbist_Ra_r0_8));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_Ra_r0_8 (.Z(mbist_Ra_r0[8]), .A1(pre_mbist_Ra_r0_8), .A2(DFT_clamp) );
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_0 (.A(mbist_Do_r0_int_net[0]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_1 (.A(mbist_Do_r0_int_net[1]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_2 (.A(mbist_Do_r0_int_net[2]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_3 (.A(mbist_Do_r0_int_net[3]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_4 (.A(mbist_Do_r0_int_net[4]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_5 (.A(mbist_Do_r0_int_net[5]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_6 (.A(mbist_Do_r0_int_net[6]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_7 (.A(mbist_Do_r0_int_net[7]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_8 (.A(mbist_Do_r0_int_net[8]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_9 (.A(mbist_Do_r0_int_net[9]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_10 (.A(mbist_Do_r0_int_net[10]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_11 (.A(mbist_Do_r0_int_net[11]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_12 (.A(mbist_Do_r0_int_net[12]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_13 (.A(mbist_Do_r0_int_net[13]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_14 (.A(mbist_Do_r0_int_net[14]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_15 (.A(mbist_Do_r0_int_net[15]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_16 (.A(mbist_Do_r0_int_net[16]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_17 (.A(mbist_Do_r0_int_net[17]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_18 (.A(mbist_Do_r0_int_net[18]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_19 (.A(mbist_Do_r0_int_net[19]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_20 (.A(mbist_Do_r0_int_net[20]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_21 (.A(mbist_Do_r0_int_net[21]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_22 (.A(mbist_Do_r0_int_net[22]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_23 (.A(mbist_Do_r0_int_net[23]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_24 (.A(mbist_Do_r0_int_net[24]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_25 (.A(mbist_Do_r0_int_net[25]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_26 (.A(mbist_Do_r0_int_net[26]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_27 (.A(mbist_Do_r0_int_net[27]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_28 (.A(mbist_Do_r0_int_net[28]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_29 (.A(mbist_Do_r0_int_net[29]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_30 (.A(mbist_Do_r0_int_net[30]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_31 (.A(mbist_Do_r0_int_net[31]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_32 (.A(mbist_Do_r0_int_net[32]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_33 (.A(mbist_Do_r0_int_net[33]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_34 (.A(mbist_Do_r0_int_net[34]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_35 (.A(mbist_Do_r0_int_net[35]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_36 (.A(mbist_Do_r0_int_net[36]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_37 (.A(mbist_Do_r0_int_net[37]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_38 (.A(mbist_Do_r0_int_net[38]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_39 (.A(mbist_Do_r0_int_net[39]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_40 (.A(mbist_Do_r0_int_net[40]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_41 (.A(mbist_Do_r0_int_net[41]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_42 (.A(mbist_Do_r0_int_net[42]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_43 (.A(mbist_Do_r0_int_net[43]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_44 (.A(mbist_Do_r0_int_net[44]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_45 (.A(mbist_Do_r0_int_net[45]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_46 (.A(mbist_Do_r0_int_net[46]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_47 (.A(mbist_Do_r0_int_net[47]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_48 (.A(mbist_Do_r0_int_net[48]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_49 (.A(mbist_Do_r0_int_net[49]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_50 (.A(mbist_Do_r0_int_net[50]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_51 (.A(mbist_Do_r0_int_net[51]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_52 (.A(mbist_Do_r0_int_net[52]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_53 (.A(mbist_Do_r0_int_net[53]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_54 (.A(mbist_Do_r0_int_net[54]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_55 (.A(mbist_Do_r0_int_net[55]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_56 (.A(mbist_Do_r0_int_net[56]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_57 (.A(mbist_Do_r0_int_net[57]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_58 (.A(mbist_Do_r0_int_net[58]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_59 (.A(mbist_Do_r0_int_net[59]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_60 (.A(mbist_Do_r0_int_net[60]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_61 (.A(mbist_Do_r0_int_net[61]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_62 (.A(mbist_Do_r0_int_net[62]));
`endif 
`ifndef FPGA 
NV_BLKBOX_SINK testInst_mbist_Do_r0_63 (.A(mbist_Do_r0_int_net[63]));
`endif 
wire pre_mbist_ce_r0;
NV_BLKBOX_SRC0_X testInst_mbist_ce_r0 (.Y(pre_mbist_ce_r0));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_ce_r0 (.Z(mbist_ce_r0), .A1(pre_mbist_ce_r0), .A2(DFT_clamp) );
wire pre_mbist_en_sync;
NV_BLKBOX_SRC0_X testInst_mbist_en_sync (.Y(pre_mbist_en_sync));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_en_sync (.Z(mbist_en_sync), .A1(pre_mbist_en_sync), .A2(DFT_clamp) );
wire pre_SI;
NV_BLKBOX_SRC0_X testInst_SI (.Y(pre_SI));
AN2D4PO4 UJ_DFTQUALIFIER_SI (.Z(SI), .A1(pre_SI), .A2(DFT_clamp) );
`ifndef FPGA 
NV_BLKBOX_SINK testInst_SO (.A(SO_int_net));
`endif 
wire pre_shiftDR;
NV_BLKBOX_SRC0_X testInst_shiftDR (.Y(pre_shiftDR));
AN2D4PO4 UJ_DFTQUALIFIER_shiftDR (.Z(shiftDR), .A1(pre_shiftDR), .A2(DFT_clamp) );
wire pre_updateDR;
NV_BLKBOX_SRC0_X testInst_updateDR (.Y(pre_updateDR));
AN2D4PO4 UJ_DFTQUALIFIER_updateDR (.Z(updateDR), .A1(pre_updateDR), .A2(DFT_clamp) );
wire pre_debug_mode;
NV_BLKBOX_SRC0_X testInst_debug_mode (.Y(pre_debug_mode));
AN2D4PO4 UJ_DFTQUALIFIER_debug_mode (.Z(debug_mode), .A1(pre_debug_mode), .A2(DFT_clamp) );
wire pre_mbist_ramaccess_rst_;
NV_BLKBOX_SRC0_X testInst_mbist_ramaccess_rst_ (.Y(pre_mbist_ramaccess_rst_));
AN2D4PO4 UJ_DFTQUALIFIER_mbist_ramaccess_rst_ (.Z(mbist_ramaccess_rst_), .A1(pre_mbist_ramaccess_rst_), .A2(DFT_clamp) );
wire pre_ary_atpg_ctl;
NV_BLKBOX_SRC0_X testInst_ary_atpg_ctl (.Y(pre_ary_atpg_ctl));
AN2D4PO4 UJ_DFTQUALIFIER_ary_atpg_ctl (.Z(ary_atpg_ctl), .A1(pre_ary_atpg_ctl), .A2(DFT_clamp) );
wire pre_write_inh;
NV_BLKBOX_SRC0_X testInst_write_inh (.Y(pre_write_inh));
AN2D4PO4 UJ_DFTQUALIFIER_write_inh (.Z(write_inh), .A1(pre_write_inh), .A2(DFT_clamp) );
wire pre_scan_ramtms;
NV_BLKBOX_SRC0_X testInst_scan_ramtms (.Y(pre_scan_ramtms));
AN2D4PO4 UJ_DFTQUALIFIER_scan_ramtms (.Z(scan_ramtms), .A1(pre_scan_ramtms), .A2(DFT_clamp) );
wire pre_iddq_mode;
NV_BLKBOX_SRC0_X testInst_iddq_mode (.Y(pre_iddq_mode));
AN2D4PO4 UJ_DFTQUALIFIER_iddq_mode (.Z(iddq_mode), .A1(pre_iddq_mode), .A2(DFT_clamp) );
wire pre_jtag_readonly_mode;
NV_BLKBOX_SRC0_X testInst_jtag_readonly_mode (.Y(pre_jtag_readonly_mode));
AN2D4PO4 UJ_DFTQUALIFIER_jtag_readonly_mode (.Z(jtag_readonly_mode), .A1(pre_jtag_readonly_mode), .A2(DFT_clamp) );
wire pre_ary_read_inh;
NV_BLKBOX_SRC0_X testInst_ary_read_inh (.Y(pre_ary_read_inh));
AN2D4PO4 UJ_DFTQUALIFIER_ary_read_inh (.Z(ary_read_inh), .A1(pre_ary_read_inh), .A2(DFT_clamp) );
wire pre_scan_en;
NV_BLKBOX_SRC0_X testInst_scan_en (.Y(pre_scan_en));
AN2D4PO4 UJ_DFTQUALIFIER_scan_en (.Z(scan_en), .A1(pre_scan_en), .A2(DFT_clamp) );
NV_BLKBOX_SRC0 testInst_svop_0 (.Y(svop[0]));
NV_BLKBOX_SRC0 testInst_svop_1 (.Y(svop[1]));
NV_BLKBOX_SRC0 testInst_svop_2 (.Y(svop[2]));
NV_BLKBOX_SRC0 testInst_svop_3 (.Y(svop[3]));
NV_BLKBOX_SRC0 testInst_svop_4 (.Y(svop[4]));
NV_BLKBOX_SRC0 testInst_svop_5 (.Y(svop[5]));
NV_BLKBOX_SRC0 testInst_svop_6 (.Y(svop[6]));
NV_BLKBOX_SRC0 testInst_svop_7 (.Y(svop[7]));

// Declare the wires for test signals

// Instantiating the internal logic module now
// verilint 402 off - inferred Reset must be a module port
nv_ram_rws_512x64_logic #(FORCE_CONTENTION_ASSERTION_RESET_ACTIVE) r_nv_ram_rws_512x64 (
                           .SI(SI), .SO_int_net(SO_int_net), 
                           .ary_atpg_ctl(ary_atpg_ctl), 
                           .ary_read_inh(ary_read_inh), .clk(clk), 
                           .debug_mode(debug_mode), .di(di), .dout(dout), 
                           .iddq_mode(iddq_mode), 
                           .jtag_readonly_mode(jtag_readonly_mode), 
                           .mbist_Di_w0(mbist_Di_w0), 
                           .mbist_Do_r0_int_net(mbist_Do_r0_int_net), 
                           .mbist_Ra_r0(mbist_Ra_r0), .mbist_Wa_w0(mbist_Wa_w0), 
                           .mbist_ce_r0(mbist_ce_r0), 
                           .mbist_en_sync(mbist_en_sync), 
                           .mbist_ramaccess_rst_(mbist_ramaccess_rst_), 
                           .mbist_we_w0(mbist_we_w0), 
                           .pwrbus_ram_pd(pwrbus_ram_pd), .ra(ra), .re(re), 
                           .scan_en(scan_en), .scan_ramtms(scan_ramtms), 
                           .shiftDR(shiftDR), .svop(svop), .updateDR(updateDR), 
                           .wa(wa), .we(we), .write_inh(write_inh) );
// verilint 402 on - inferred Reset must be a module port


// synopsys dc_tcl_script_begin
// synopsys dc_tcl_script_end



// synopsys dc_tcl_script_begin
// synopsys dc_tcl_script_end


`ifndef SYNTHESIS
task arrangement (output integer arrangment_string[63:0]);
  begin
    arrangment_string[0] = 0  ;     
    arrangment_string[1] = 1  ;     
    arrangment_string[2] = 2  ;     
    arrangment_string[3] = 3  ;     
    arrangment_string[4] = 4  ;     
    arrangment_string[5] = 5  ;     
    arrangment_string[6] = 6  ;     
    arrangment_string[7] = 7  ;     
    arrangment_string[8] = 8  ;     
    arrangment_string[9] = 9  ;     
    arrangment_string[10] = 10  ;     
    arrangment_string[11] = 11  ;     
    arrangment_string[12] = 12  ;     
    arrangment_string[13] = 13  ;     
    arrangment_string[14] = 14  ;     
    arrangment_string[15] = 15  ;     
    arrangment_string[16] = 16  ;     
    arrangment_string[17] = 17  ;     
    arrangment_string[18] = 18  ;     
    arrangment_string[19] = 19  ;     
    arrangment_string[20] = 20  ;     
    arrangment_string[21] = 21  ;     
    arrangment_string[22] = 22  ;     
    arrangment_string[23] = 23  ;     
    arrangment_string[24] = 24  ;     
    arrangment_string[25] = 25  ;     
    arrangment_string[26] = 26  ;     
    arrangment_string[27] = 27  ;     
    arrangment_string[28] = 28  ;     
    arrangment_string[29] = 29  ;     
    arrangment_string[30] = 30  ;     
    arrangment_string[31] = 31  ;     
    arrangment_string[32] = 32  ;     
    arrangment_string[33] = 33  ;     
    arrangment_string[34] = 34  ;     
    arrangment_string[35] = 35  ;     
    arrangment_string[36] = 36  ;     
    arrangment_string[37] = 37  ;     
    arrangment_string[38] = 38  ;     
    arrangment_string[39] = 39  ;     
    arrangment_string[40] = 40  ;     
    arrangment_string[41] = 41  ;     
    arrangment_string[42] = 42  ;     
    arrangment_string[43] = 43  ;     
    arrangment_string[44] = 44  ;     
    arrangment_string[45] = 45  ;     
    arrangment_string[46] = 46  ;     
    arrangment_string[47] = 47  ;     
    arrangment_string[48] = 48  ;     
    arrangment_string[49] = 49  ;     
    arrangment_string[50] = 50  ;     
    arrangment_string[51] = 51  ;     
    arrangment_string[52] = 52  ;     
    arrangment_string[53] = 53  ;     
    arrangment_string[54] = 54  ;     
    arrangment_string[55] = 55  ;     
    arrangment_string[56] = 56  ;     
    arrangment_string[57] = 57  ;     
    arrangment_string[58] = 58  ;     
    arrangment_string[59] = 59  ;     
    arrangment_string[60] = 60  ;     
    arrangment_string[61] = 61  ;     
    arrangment_string[62] = 62  ;     
    arrangment_string[63] = 63  ;     
  end
endtask
`endif

`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_VAL_TASKS

`ifndef MEM_REG_NAME 
 `define MEM_REG_NAME MX.mem
`endif

// Bit vector indicating which shadow addresses have been written
reg [511:0] shadow_written = 'b0;

// Shadow ram array used to store initialization values
reg [63:0] shadow_mem [511:0];


`ifdef NV_RAM_EXPAND_ARRAY
wire [63:0] shadow_mem_row0 = shadow_mem[0];
wire [63:0] shadow_mem_row1 = shadow_mem[1];
wire [63:0] shadow_mem_row2 = shadow_mem[2];
wire [63:0] shadow_mem_row3 = shadow_mem[3];
wire [63:0] shadow_mem_row4 = shadow_mem[4];
wire [63:0] shadow_mem_row5 = shadow_mem[5];
wire [63:0] shadow_mem_row6 = shadow_mem[6];
wire [63:0] shadow_mem_row7 = shadow_mem[7];
wire [63:0] shadow_mem_row8 = shadow_mem[8];
wire [63:0] shadow_mem_row9 = shadow_mem[9];
wire [63:0] shadow_mem_row10 = shadow_mem[10];
wire [63:0] shadow_mem_row11 = shadow_mem[11];
wire [63:0] shadow_mem_row12 = shadow_mem[12];
wire [63:0] shadow_mem_row13 = shadow_mem[13];
wire [63:0] shadow_mem_row14 = shadow_mem[14];
wire [63:0] shadow_mem_row15 = shadow_mem[15];
wire [63:0] shadow_mem_row16 = shadow_mem[16];
wire [63:0] shadow_mem_row17 = shadow_mem[17];
wire [63:0] shadow_mem_row18 = shadow_mem[18];
wire [63:0] shadow_mem_row19 = shadow_mem[19];
wire [63:0] shadow_mem_row20 = shadow_mem[20];
wire [63:0] shadow_mem_row21 = shadow_mem[21];
wire [63:0] shadow_mem_row22 = shadow_mem[22];
wire [63:0] shadow_mem_row23 = shadow_mem[23];
wire [63:0] shadow_mem_row24 = shadow_mem[24];
wire [63:0] shadow_mem_row25 = shadow_mem[25];
wire [63:0] shadow_mem_row26 = shadow_mem[26];
wire [63:0] shadow_mem_row27 = shadow_mem[27];
wire [63:0] shadow_mem_row28 = shadow_mem[28];
wire [63:0] shadow_mem_row29 = shadow_mem[29];
wire [63:0] shadow_mem_row30 = shadow_mem[30];
wire [63:0] shadow_mem_row31 = shadow_mem[31];
wire [63:0] shadow_mem_row32 = shadow_mem[32];
wire [63:0] shadow_mem_row33 = shadow_mem[33];
wire [63:0] shadow_mem_row34 = shadow_mem[34];
wire [63:0] shadow_mem_row35 = shadow_mem[35];
wire [63:0] shadow_mem_row36 = shadow_mem[36];
wire [63:0] shadow_mem_row37 = shadow_mem[37];
wire [63:0] shadow_mem_row38 = shadow_mem[38];
wire [63:0] shadow_mem_row39 = shadow_mem[39];
wire [63:0] shadow_mem_row40 = shadow_mem[40];
wire [63:0] shadow_mem_row41 = shadow_mem[41];
wire [63:0] shadow_mem_row42 = shadow_mem[42];
wire [63:0] shadow_mem_row43 = shadow_mem[43];
wire [63:0] shadow_mem_row44 = shadow_mem[44];
wire [63:0] shadow_mem_row45 = shadow_mem[45];
wire [63:0] shadow_mem_row46 = shadow_mem[46];
wire [63:0] shadow_mem_row47 = shadow_mem[47];
wire [63:0] shadow_mem_row48 = shadow_mem[48];
wire [63:0] shadow_mem_row49 = shadow_mem[49];
wire [63:0] shadow_mem_row50 = shadow_mem[50];
wire [63:0] shadow_mem_row51 = shadow_mem[51];
wire [63:0] shadow_mem_row52 = shadow_mem[52];
wire [63:0] shadow_mem_row53 = shadow_mem[53];
wire [63:0] shadow_mem_row54 = shadow_mem[54];
wire [63:0] shadow_mem_row55 = shadow_mem[55];
wire [63:0] shadow_mem_row56 = shadow_mem[56];
wire [63:0] shadow_mem_row57 = shadow_mem[57];
wire [63:0] shadow_mem_row58 = shadow_mem[58];
wire [63:0] shadow_mem_row59 = shadow_mem[59];
wire [63:0] shadow_mem_row60 = shadow_mem[60];
wire [63:0] shadow_mem_row61 = shadow_mem[61];
wire [63:0] shadow_mem_row62 = shadow_mem[62];
wire [63:0] shadow_mem_row63 = shadow_mem[63];
wire [63:0] shadow_mem_row64 = shadow_mem[64];
wire [63:0] shadow_mem_row65 = shadow_mem[65];
wire [63:0] shadow_mem_row66 = shadow_mem[66];
wire [63:0] shadow_mem_row67 = shadow_mem[67];
wire [63:0] shadow_mem_row68 = shadow_mem[68];
wire [63:0] shadow_mem_row69 = shadow_mem[69];
wire [63:0] shadow_mem_row70 = shadow_mem[70];
wire [63:0] shadow_mem_row71 = shadow_mem[71];
wire [63:0] shadow_mem_row72 = shadow_mem[72];
wire [63:0] shadow_mem_row73 = shadow_mem[73];
wire [63:0] shadow_mem_row74 = shadow_mem[74];
wire [63:0] shadow_mem_row75 = shadow_mem[75];
wire [63:0] shadow_mem_row76 = shadow_mem[76];
wire [63:0] shadow_mem_row77 = shadow_mem[77];
wire [63:0] shadow_mem_row78 = shadow_mem[78];
wire [63:0] shadow_mem_row79 = shadow_mem[79];
wire [63:0] shadow_mem_row80 = shadow_mem[80];
wire [63:0] shadow_mem_row81 = shadow_mem[81];
wire [63:0] shadow_mem_row82 = shadow_mem[82];
wire [63:0] shadow_mem_row83 = shadow_mem[83];
wire [63:0] shadow_mem_row84 = shadow_mem[84];
wire [63:0] shadow_mem_row85 = shadow_mem[85];
wire [63:0] shadow_mem_row86 = shadow_mem[86];
wire [63:0] shadow_mem_row87 = shadow_mem[87];
wire [63:0] shadow_mem_row88 = shadow_mem[88];
wire [63:0] shadow_mem_row89 = shadow_mem[89];
wire [63:0] shadow_mem_row90 = shadow_mem[90];
wire [63:0] shadow_mem_row91 = shadow_mem[91];
wire [63:0] shadow_mem_row92 = shadow_mem[92];
wire [63:0] shadow_mem_row93 = shadow_mem[93];
wire [63:0] shadow_mem_row94 = shadow_mem[94];
wire [63:0] shadow_mem_row95 = shadow_mem[95];
wire [63:0] shadow_mem_row96 = shadow_mem[96];
wire [63:0] shadow_mem_row97 = shadow_mem[97];
wire [63:0] shadow_mem_row98 = shadow_mem[98];
wire [63:0] shadow_mem_row99 = shadow_mem[99];
wire [63:0] shadow_mem_row100 = shadow_mem[100];
wire [63:0] shadow_mem_row101 = shadow_mem[101];
wire [63:0] shadow_mem_row102 = shadow_mem[102];
wire [63:0] shadow_mem_row103 = shadow_mem[103];
wire [63:0] shadow_mem_row104 = shadow_mem[104];
wire [63:0] shadow_mem_row105 = shadow_mem[105];
wire [63:0] shadow_mem_row106 = shadow_mem[106];
wire [63:0] shadow_mem_row107 = shadow_mem[107];
wire [63:0] shadow_mem_row108 = shadow_mem[108];
wire [63:0] shadow_mem_row109 = shadow_mem[109];
wire [63:0] shadow_mem_row110 = shadow_mem[110];
wire [63:0] shadow_mem_row111 = shadow_mem[111];
wire [63:0] shadow_mem_row112 = shadow_mem[112];
wire [63:0] shadow_mem_row113 = shadow_mem[113];
wire [63:0] shadow_mem_row114 = shadow_mem[114];
wire [63:0] shadow_mem_row115 = shadow_mem[115];
wire [63:0] shadow_mem_row116 = shadow_mem[116];
wire [63:0] shadow_mem_row117 = shadow_mem[117];
wire [63:0] shadow_mem_row118 = shadow_mem[118];
wire [63:0] shadow_mem_row119 = shadow_mem[119];
wire [63:0] shadow_mem_row120 = shadow_mem[120];
wire [63:0] shadow_mem_row121 = shadow_mem[121];
wire [63:0] shadow_mem_row122 = shadow_mem[122];
wire [63:0] shadow_mem_row123 = shadow_mem[123];
wire [63:0] shadow_mem_row124 = shadow_mem[124];
wire [63:0] shadow_mem_row125 = shadow_mem[125];
wire [63:0] shadow_mem_row126 = shadow_mem[126];
wire [63:0] shadow_mem_row127 = shadow_mem[127];
wire [63:0] shadow_mem_row128 = shadow_mem[128];
wire [63:0] shadow_mem_row129 = shadow_mem[129];
wire [63:0] shadow_mem_row130 = shadow_mem[130];
wire [63:0] shadow_mem_row131 = shadow_mem[131];
wire [63:0] shadow_mem_row132 = shadow_mem[132];
wire [63:0] shadow_mem_row133 = shadow_mem[133];
wire [63:0] shadow_mem_row134 = shadow_mem[134];
wire [63:0] shadow_mem_row135 = shadow_mem[135];
wire [63:0] shadow_mem_row136 = shadow_mem[136];
wire [63:0] shadow_mem_row137 = shadow_mem[137];
wire [63:0] shadow_mem_row138 = shadow_mem[138];
wire [63:0] shadow_mem_row139 = shadow_mem[139];
wire [63:0] shadow_mem_row140 = shadow_mem[140];
wire [63:0] shadow_mem_row141 = shadow_mem[141];
wire [63:0] shadow_mem_row142 = shadow_mem[142];
wire [63:0] shadow_mem_row143 = shadow_mem[143];
wire [63:0] shadow_mem_row144 = shadow_mem[144];
wire [63:0] shadow_mem_row145 = shadow_mem[145];
wire [63:0] shadow_mem_row146 = shadow_mem[146];
wire [63:0] shadow_mem_row147 = shadow_mem[147];
wire [63:0] shadow_mem_row148 = shadow_mem[148];
wire [63:0] shadow_mem_row149 = shadow_mem[149];
wire [63:0] shadow_mem_row150 = shadow_mem[150];
wire [63:0] shadow_mem_row151 = shadow_mem[151];
wire [63:0] shadow_mem_row152 = shadow_mem[152];
wire [63:0] shadow_mem_row153 = shadow_mem[153];
wire [63:0] shadow_mem_row154 = shadow_mem[154];
wire [63:0] shadow_mem_row155 = shadow_mem[155];
wire [63:0] shadow_mem_row156 = shadow_mem[156];
wire [63:0] shadow_mem_row157 = shadow_mem[157];
wire [63:0] shadow_mem_row158 = shadow_mem[158];
wire [63:0] shadow_mem_row159 = shadow_mem[159];
wire [63:0] shadow_mem_row160 = shadow_mem[160];
wire [63:0] shadow_mem_row161 = shadow_mem[161];
wire [63:0] shadow_mem_row162 = shadow_mem[162];
wire [63:0] shadow_mem_row163 = shadow_mem[163];
wire [63:0] shadow_mem_row164 = shadow_mem[164];
wire [63:0] shadow_mem_row165 = shadow_mem[165];
wire [63:0] shadow_mem_row166 = shadow_mem[166];
wire [63:0] shadow_mem_row167 = shadow_mem[167];
wire [63:0] shadow_mem_row168 = shadow_mem[168];
wire [63:0] shadow_mem_row169 = shadow_mem[169];
wire [63:0] shadow_mem_row170 = shadow_mem[170];
wire [63:0] shadow_mem_row171 = shadow_mem[171];
wire [63:0] shadow_mem_row172 = shadow_mem[172];
wire [63:0] shadow_mem_row173 = shadow_mem[173];
wire [63:0] shadow_mem_row174 = shadow_mem[174];
wire [63:0] shadow_mem_row175 = shadow_mem[175];
wire [63:0] shadow_mem_row176 = shadow_mem[176];
wire [63:0] shadow_mem_row177 = shadow_mem[177];
wire [63:0] shadow_mem_row178 = shadow_mem[178];
wire [63:0] shadow_mem_row179 = shadow_mem[179];
wire [63:0] shadow_mem_row180 = shadow_mem[180];
wire [63:0] shadow_mem_row181 = shadow_mem[181];
wire [63:0] shadow_mem_row182 = shadow_mem[182];
wire [63:0] shadow_mem_row183 = shadow_mem[183];
wire [63:0] shadow_mem_row184 = shadow_mem[184];
wire [63:0] shadow_mem_row185 = shadow_mem[185];
wire [63:0] shadow_mem_row186 = shadow_mem[186];
wire [63:0] shadow_mem_row187 = shadow_mem[187];
wire [63:0] shadow_mem_row188 = shadow_mem[188];
wire [63:0] shadow_mem_row189 = shadow_mem[189];
wire [63:0] shadow_mem_row190 = shadow_mem[190];
wire [63:0] shadow_mem_row191 = shadow_mem[191];
wire [63:0] shadow_mem_row192 = shadow_mem[192];
wire [63:0] shadow_mem_row193 = shadow_mem[193];
wire [63:0] shadow_mem_row194 = shadow_mem[194];
wire [63:0] shadow_mem_row195 = shadow_mem[195];
wire [63:0] shadow_mem_row196 = shadow_mem[196];
wire [63:0] shadow_mem_row197 = shadow_mem[197];
wire [63:0] shadow_mem_row198 = shadow_mem[198];
wire [63:0] shadow_mem_row199 = shadow_mem[199];
wire [63:0] shadow_mem_row200 = shadow_mem[200];
wire [63:0] shadow_mem_row201 = shadow_mem[201];
wire [63:0] shadow_mem_row202 = shadow_mem[202];
wire [63:0] shadow_mem_row203 = shadow_mem[203];
wire [63:0] shadow_mem_row204 = shadow_mem[204];
wire [63:0] shadow_mem_row205 = shadow_mem[205];
wire [63:0] shadow_mem_row206 = shadow_mem[206];
wire [63:0] shadow_mem_row207 = shadow_mem[207];
wire [63:0] shadow_mem_row208 = shadow_mem[208];
wire [63:0] shadow_mem_row209 = shadow_mem[209];
wire [63:0] shadow_mem_row210 = shadow_mem[210];
wire [63:0] shadow_mem_row211 = shadow_mem[211];
wire [63:0] shadow_mem_row212 = shadow_mem[212];
wire [63:0] shadow_mem_row213 = shadow_mem[213];
wire [63:0] shadow_mem_row214 = shadow_mem[214];
wire [63:0] shadow_mem_row215 = shadow_mem[215];
wire [63:0] shadow_mem_row216 = shadow_mem[216];
wire [63:0] shadow_mem_row217 = shadow_mem[217];
wire [63:0] shadow_mem_row218 = shadow_mem[218];
wire [63:0] shadow_mem_row219 = shadow_mem[219];
wire [63:0] shadow_mem_row220 = shadow_mem[220];
wire [63:0] shadow_mem_row221 = shadow_mem[221];
wire [63:0] shadow_mem_row222 = shadow_mem[222];
wire [63:0] shadow_mem_row223 = shadow_mem[223];
wire [63:0] shadow_mem_row224 = shadow_mem[224];
wire [63:0] shadow_mem_row225 = shadow_mem[225];
wire [63:0] shadow_mem_row226 = shadow_mem[226];
wire [63:0] shadow_mem_row227 = shadow_mem[227];
wire [63:0] shadow_mem_row228 = shadow_mem[228];
wire [63:0] shadow_mem_row229 = shadow_mem[229];
wire [63:0] shadow_mem_row230 = shadow_mem[230];
wire [63:0] shadow_mem_row231 = shadow_mem[231];
wire [63:0] shadow_mem_row232 = shadow_mem[232];
wire [63:0] shadow_mem_row233 = shadow_mem[233];
wire [63:0] shadow_mem_row234 = shadow_mem[234];
wire [63:0] shadow_mem_row235 = shadow_mem[235];
wire [63:0] shadow_mem_row236 = shadow_mem[236];
wire [63:0] shadow_mem_row237 = shadow_mem[237];
wire [63:0] shadow_mem_row238 = shadow_mem[238];
wire [63:0] shadow_mem_row239 = shadow_mem[239];
wire [63:0] shadow_mem_row240 = shadow_mem[240];
wire [63:0] shadow_mem_row241 = shadow_mem[241];
wire [63:0] shadow_mem_row242 = shadow_mem[242];
wire [63:0] shadow_mem_row243 = shadow_mem[243];
wire [63:0] shadow_mem_row244 = shadow_mem[244];
wire [63:0] shadow_mem_row245 = shadow_mem[245];
wire [63:0] shadow_mem_row246 = shadow_mem[246];
wire [63:0] shadow_mem_row247 = shadow_mem[247];
wire [63:0] shadow_mem_row248 = shadow_mem[248];
wire [63:0] shadow_mem_row249 = shadow_mem[249];
wire [63:0] shadow_mem_row250 = shadow_mem[250];
wire [63:0] shadow_mem_row251 = shadow_mem[251];
wire [63:0] shadow_mem_row252 = shadow_mem[252];
wire [63:0] shadow_mem_row253 = shadow_mem[253];
wire [63:0] shadow_mem_row254 = shadow_mem[254];
wire [63:0] shadow_mem_row255 = shadow_mem[255];
wire [63:0] shadow_mem_row256 = shadow_mem[256];
wire [63:0] shadow_mem_row257 = shadow_mem[257];
wire [63:0] shadow_mem_row258 = shadow_mem[258];
wire [63:0] shadow_mem_row259 = shadow_mem[259];
wire [63:0] shadow_mem_row260 = shadow_mem[260];
wire [63:0] shadow_mem_row261 = shadow_mem[261];
wire [63:0] shadow_mem_row262 = shadow_mem[262];
wire [63:0] shadow_mem_row263 = shadow_mem[263];
wire [63:0] shadow_mem_row264 = shadow_mem[264];
wire [63:0] shadow_mem_row265 = shadow_mem[265];
wire [63:0] shadow_mem_row266 = shadow_mem[266];
wire [63:0] shadow_mem_row267 = shadow_mem[267];
wire [63:0] shadow_mem_row268 = shadow_mem[268];
wire [63:0] shadow_mem_row269 = shadow_mem[269];
wire [63:0] shadow_mem_row270 = shadow_mem[270];
wire [63:0] shadow_mem_row271 = shadow_mem[271];
wire [63:0] shadow_mem_row272 = shadow_mem[272];
wire [63:0] shadow_mem_row273 = shadow_mem[273];
wire [63:0] shadow_mem_row274 = shadow_mem[274];
wire [63:0] shadow_mem_row275 = shadow_mem[275];
wire [63:0] shadow_mem_row276 = shadow_mem[276];
wire [63:0] shadow_mem_row277 = shadow_mem[277];
wire [63:0] shadow_mem_row278 = shadow_mem[278];
wire [63:0] shadow_mem_row279 = shadow_mem[279];
wire [63:0] shadow_mem_row280 = shadow_mem[280];
wire [63:0] shadow_mem_row281 = shadow_mem[281];
wire [63:0] shadow_mem_row282 = shadow_mem[282];
wire [63:0] shadow_mem_row283 = shadow_mem[283];
wire [63:0] shadow_mem_row284 = shadow_mem[284];
wire [63:0] shadow_mem_row285 = shadow_mem[285];
wire [63:0] shadow_mem_row286 = shadow_mem[286];
wire [63:0] shadow_mem_row287 = shadow_mem[287];
wire [63:0] shadow_mem_row288 = shadow_mem[288];
wire [63:0] shadow_mem_row289 = shadow_mem[289];
wire [63:0] shadow_mem_row290 = shadow_mem[290];
wire [63:0] shadow_mem_row291 = shadow_mem[291];
wire [63:0] shadow_mem_row292 = shadow_mem[292];
wire [63:0] shadow_mem_row293 = shadow_mem[293];
wire [63:0] shadow_mem_row294 = shadow_mem[294];
wire [63:0] shadow_mem_row295 = shadow_mem[295];
wire [63:0] shadow_mem_row296 = shadow_mem[296];
wire [63:0] shadow_mem_row297 = shadow_mem[297];
wire [63:0] shadow_mem_row298 = shadow_mem[298];
wire [63:0] shadow_mem_row299 = shadow_mem[299];
wire [63:0] shadow_mem_row300 = shadow_mem[300];
wire [63:0] shadow_mem_row301 = shadow_mem[301];
wire [63:0] shadow_mem_row302 = shadow_mem[302];
wire [63:0] shadow_mem_row303 = shadow_mem[303];
wire [63:0] shadow_mem_row304 = shadow_mem[304];
wire [63:0] shadow_mem_row305 = shadow_mem[305];
wire [63:0] shadow_mem_row306 = shadow_mem[306];
wire [63:0] shadow_mem_row307 = shadow_mem[307];
wire [63:0] shadow_mem_row308 = shadow_mem[308];
wire [63:0] shadow_mem_row309 = shadow_mem[309];
wire [63:0] shadow_mem_row310 = shadow_mem[310];
wire [63:0] shadow_mem_row311 = shadow_mem[311];
wire [63:0] shadow_mem_row312 = shadow_mem[312];
wire [63:0] shadow_mem_row313 = shadow_mem[313];
wire [63:0] shadow_mem_row314 = shadow_mem[314];
wire [63:0] shadow_mem_row315 = shadow_mem[315];
wire [63:0] shadow_mem_row316 = shadow_mem[316];
wire [63:0] shadow_mem_row317 = shadow_mem[317];
wire [63:0] shadow_mem_row318 = shadow_mem[318];
wire [63:0] shadow_mem_row319 = shadow_mem[319];
wire [63:0] shadow_mem_row320 = shadow_mem[320];
wire [63:0] shadow_mem_row321 = shadow_mem[321];
wire [63:0] shadow_mem_row322 = shadow_mem[322];
wire [63:0] shadow_mem_row323 = shadow_mem[323];
wire [63:0] shadow_mem_row324 = shadow_mem[324];
wire [63:0] shadow_mem_row325 = shadow_mem[325];
wire [63:0] shadow_mem_row326 = shadow_mem[326];
wire [63:0] shadow_mem_row327 = shadow_mem[327];
wire [63:0] shadow_mem_row328 = shadow_mem[328];
wire [63:0] shadow_mem_row329 = shadow_mem[329];
wire [63:0] shadow_mem_row330 = shadow_mem[330];
wire [63:0] shadow_mem_row331 = shadow_mem[331];
wire [63:0] shadow_mem_row332 = shadow_mem[332];
wire [63:0] shadow_mem_row333 = shadow_mem[333];
wire [63:0] shadow_mem_row334 = shadow_mem[334];
wire [63:0] shadow_mem_row335 = shadow_mem[335];
wire [63:0] shadow_mem_row336 = shadow_mem[336];
wire [63:0] shadow_mem_row337 = shadow_mem[337];
wire [63:0] shadow_mem_row338 = shadow_mem[338];
wire [63:0] shadow_mem_row339 = shadow_mem[339];
wire [63:0] shadow_mem_row340 = shadow_mem[340];
wire [63:0] shadow_mem_row341 = shadow_mem[341];
wire [63:0] shadow_mem_row342 = shadow_mem[342];
wire [63:0] shadow_mem_row343 = shadow_mem[343];
wire [63:0] shadow_mem_row344 = shadow_mem[344];
wire [63:0] shadow_mem_row345 = shadow_mem[345];
wire [63:0] shadow_mem_row346 = shadow_mem[346];
wire [63:0] shadow_mem_row347 = shadow_mem[347];
wire [63:0] shadow_mem_row348 = shadow_mem[348];
wire [63:0] shadow_mem_row349 = shadow_mem[349];
wire [63:0] shadow_mem_row350 = shadow_mem[350];
wire [63:0] shadow_mem_row351 = shadow_mem[351];
wire [63:0] shadow_mem_row352 = shadow_mem[352];
wire [63:0] shadow_mem_row353 = shadow_mem[353];
wire [63:0] shadow_mem_row354 = shadow_mem[354];
wire [63:0] shadow_mem_row355 = shadow_mem[355];
wire [63:0] shadow_mem_row356 = shadow_mem[356];
wire [63:0] shadow_mem_row357 = shadow_mem[357];
wire [63:0] shadow_mem_row358 = shadow_mem[358];
wire [63:0] shadow_mem_row359 = shadow_mem[359];
wire [63:0] shadow_mem_row360 = shadow_mem[360];
wire [63:0] shadow_mem_row361 = shadow_mem[361];
wire [63:0] shadow_mem_row362 = shadow_mem[362];
wire [63:0] shadow_mem_row363 = shadow_mem[363];
wire [63:0] shadow_mem_row364 = shadow_mem[364];
wire [63:0] shadow_mem_row365 = shadow_mem[365];
wire [63:0] shadow_mem_row366 = shadow_mem[366];
wire [63:0] shadow_mem_row367 = shadow_mem[367];
wire [63:0] shadow_mem_row368 = shadow_mem[368];
wire [63:0] shadow_mem_row369 = shadow_mem[369];
wire [63:0] shadow_mem_row370 = shadow_mem[370];
wire [63:0] shadow_mem_row371 = shadow_mem[371];
wire [63:0] shadow_mem_row372 = shadow_mem[372];
wire [63:0] shadow_mem_row373 = shadow_mem[373];
wire [63:0] shadow_mem_row374 = shadow_mem[374];
wire [63:0] shadow_mem_row375 = shadow_mem[375];
wire [63:0] shadow_mem_row376 = shadow_mem[376];
wire [63:0] shadow_mem_row377 = shadow_mem[377];
wire [63:0] shadow_mem_row378 = shadow_mem[378];
wire [63:0] shadow_mem_row379 = shadow_mem[379];
wire [63:0] shadow_mem_row380 = shadow_mem[380];
wire [63:0] shadow_mem_row381 = shadow_mem[381];
wire [63:0] shadow_mem_row382 = shadow_mem[382];
wire [63:0] shadow_mem_row383 = shadow_mem[383];
wire [63:0] shadow_mem_row384 = shadow_mem[384];
wire [63:0] shadow_mem_row385 = shadow_mem[385];
wire [63:0] shadow_mem_row386 = shadow_mem[386];
wire [63:0] shadow_mem_row387 = shadow_mem[387];
wire [63:0] shadow_mem_row388 = shadow_mem[388];
wire [63:0] shadow_mem_row389 = shadow_mem[389];
wire [63:0] shadow_mem_row390 = shadow_mem[390];
wire [63:0] shadow_mem_row391 = shadow_mem[391];
wire [63:0] shadow_mem_row392 = shadow_mem[392];
wire [63:0] shadow_mem_row393 = shadow_mem[393];
wire [63:0] shadow_mem_row394 = shadow_mem[394];
wire [63:0] shadow_mem_row395 = shadow_mem[395];
wire [63:0] shadow_mem_row396 = shadow_mem[396];
wire [63:0] shadow_mem_row397 = shadow_mem[397];
wire [63:0] shadow_mem_row398 = shadow_mem[398];
wire [63:0] shadow_mem_row399 = shadow_mem[399];
wire [63:0] shadow_mem_row400 = shadow_mem[400];
wire [63:0] shadow_mem_row401 = shadow_mem[401];
wire [63:0] shadow_mem_row402 = shadow_mem[402];
wire [63:0] shadow_mem_row403 = shadow_mem[403];
wire [63:0] shadow_mem_row404 = shadow_mem[404];
wire [63:0] shadow_mem_row405 = shadow_mem[405];
wire [63:0] shadow_mem_row406 = shadow_mem[406];
wire [63:0] shadow_mem_row407 = shadow_mem[407];
wire [63:0] shadow_mem_row408 = shadow_mem[408];
wire [63:0] shadow_mem_row409 = shadow_mem[409];
wire [63:0] shadow_mem_row410 = shadow_mem[410];
wire [63:0] shadow_mem_row411 = shadow_mem[411];
wire [63:0] shadow_mem_row412 = shadow_mem[412];
wire [63:0] shadow_mem_row413 = shadow_mem[413];
wire [63:0] shadow_mem_row414 = shadow_mem[414];
wire [63:0] shadow_mem_row415 = shadow_mem[415];
wire [63:0] shadow_mem_row416 = shadow_mem[416];
wire [63:0] shadow_mem_row417 = shadow_mem[417];
wire [63:0] shadow_mem_row418 = shadow_mem[418];
wire [63:0] shadow_mem_row419 = shadow_mem[419];
wire [63:0] shadow_mem_row420 = shadow_mem[420];
wire [63:0] shadow_mem_row421 = shadow_mem[421];
wire [63:0] shadow_mem_row422 = shadow_mem[422];
wire [63:0] shadow_mem_row423 = shadow_mem[423];
wire [63:0] shadow_mem_row424 = shadow_mem[424];
wire [63:0] shadow_mem_row425 = shadow_mem[425];
wire [63:0] shadow_mem_row426 = shadow_mem[426];
wire [63:0] shadow_mem_row427 = shadow_mem[427];
wire [63:0] shadow_mem_row428 = shadow_mem[428];
wire [63:0] shadow_mem_row429 = shadow_mem[429];
wire [63:0] shadow_mem_row430 = shadow_mem[430];
wire [63:0] shadow_mem_row431 = shadow_mem[431];
wire [63:0] shadow_mem_row432 = shadow_mem[432];
wire [63:0] shadow_mem_row433 = shadow_mem[433];
wire [63:0] shadow_mem_row434 = shadow_mem[434];
wire [63:0] shadow_mem_row435 = shadow_mem[435];
wire [63:0] shadow_mem_row436 = shadow_mem[436];
wire [63:0] shadow_mem_row437 = shadow_mem[437];
wire [63:0] shadow_mem_row438 = shadow_mem[438];
wire [63:0] shadow_mem_row439 = shadow_mem[439];
wire [63:0] shadow_mem_row440 = shadow_mem[440];
wire [63:0] shadow_mem_row441 = shadow_mem[441];
wire [63:0] shadow_mem_row442 = shadow_mem[442];
wire [63:0] shadow_mem_row443 = shadow_mem[443];
wire [63:0] shadow_mem_row444 = shadow_mem[444];
wire [63:0] shadow_mem_row445 = shadow_mem[445];
wire [63:0] shadow_mem_row446 = shadow_mem[446];
wire [63:0] shadow_mem_row447 = shadow_mem[447];
wire [63:0] shadow_mem_row448 = shadow_mem[448];
wire [63:0] shadow_mem_row449 = shadow_mem[449];
wire [63:0] shadow_mem_row450 = shadow_mem[450];
wire [63:0] shadow_mem_row451 = shadow_mem[451];
wire [63:0] shadow_mem_row452 = shadow_mem[452];
wire [63:0] shadow_mem_row453 = shadow_mem[453];
wire [63:0] shadow_mem_row454 = shadow_mem[454];
wire [63:0] shadow_mem_row455 = shadow_mem[455];
wire [63:0] shadow_mem_row456 = shadow_mem[456];
wire [63:0] shadow_mem_row457 = shadow_mem[457];
wire [63:0] shadow_mem_row458 = shadow_mem[458];
wire [63:0] shadow_mem_row459 = shadow_mem[459];
wire [63:0] shadow_mem_row460 = shadow_mem[460];
wire [63:0] shadow_mem_row461 = shadow_mem[461];
wire [63:0] shadow_mem_row462 = shadow_mem[462];
wire [63:0] shadow_mem_row463 = shadow_mem[463];
wire [63:0] shadow_mem_row464 = shadow_mem[464];
wire [63:0] shadow_mem_row465 = shadow_mem[465];
wire [63:0] shadow_mem_row466 = shadow_mem[466];
wire [63:0] shadow_mem_row467 = shadow_mem[467];
wire [63:0] shadow_mem_row468 = shadow_mem[468];
wire [63:0] shadow_mem_row469 = shadow_mem[469];
wire [63:0] shadow_mem_row470 = shadow_mem[470];
wire [63:0] shadow_mem_row471 = shadow_mem[471];
wire [63:0] shadow_mem_row472 = shadow_mem[472];
wire [63:0] shadow_mem_row473 = shadow_mem[473];
wire [63:0] shadow_mem_row474 = shadow_mem[474];
wire [63:0] shadow_mem_row475 = shadow_mem[475];
wire [63:0] shadow_mem_row476 = shadow_mem[476];
wire [63:0] shadow_mem_row477 = shadow_mem[477];
wire [63:0] shadow_mem_row478 = shadow_mem[478];
wire [63:0] shadow_mem_row479 = shadow_mem[479];
wire [63:0] shadow_mem_row480 = shadow_mem[480];
wire [63:0] shadow_mem_row481 = shadow_mem[481];
wire [63:0] shadow_mem_row482 = shadow_mem[482];
wire [63:0] shadow_mem_row483 = shadow_mem[483];
wire [63:0] shadow_mem_row484 = shadow_mem[484];
wire [63:0] shadow_mem_row485 = shadow_mem[485];
wire [63:0] shadow_mem_row486 = shadow_mem[486];
wire [63:0] shadow_mem_row487 = shadow_mem[487];
wire [63:0] shadow_mem_row488 = shadow_mem[488];
wire [63:0] shadow_mem_row489 = shadow_mem[489];
wire [63:0] shadow_mem_row490 = shadow_mem[490];
wire [63:0] shadow_mem_row491 = shadow_mem[491];
wire [63:0] shadow_mem_row492 = shadow_mem[492];
wire [63:0] shadow_mem_row493 = shadow_mem[493];
wire [63:0] shadow_mem_row494 = shadow_mem[494];
wire [63:0] shadow_mem_row495 = shadow_mem[495];
wire [63:0] shadow_mem_row496 = shadow_mem[496];
wire [63:0] shadow_mem_row497 = shadow_mem[497];
wire [63:0] shadow_mem_row498 = shadow_mem[498];
wire [63:0] shadow_mem_row499 = shadow_mem[499];
wire [63:0] shadow_mem_row500 = shadow_mem[500];
wire [63:0] shadow_mem_row501 = shadow_mem[501];
wire [63:0] shadow_mem_row502 = shadow_mem[502];
wire [63:0] shadow_mem_row503 = shadow_mem[503];
wire [63:0] shadow_mem_row504 = shadow_mem[504];
wire [63:0] shadow_mem_row505 = shadow_mem[505];
wire [63:0] shadow_mem_row506 = shadow_mem[506];
wire [63:0] shadow_mem_row507 = shadow_mem[507];
wire [63:0] shadow_mem_row508 = shadow_mem[508];
wire [63:0] shadow_mem_row509 = shadow_mem[509];
wire [63:0] shadow_mem_row510 = shadow_mem[510];
wire [63:0] shadow_mem_row511 = shadow_mem[511];
`endif

task init_mem_val;
  input [8:0] row;
  input [63:0] data;
  begin
    shadow_mem[row] = data;
    shadow_written[row] = 1'b1;
  end
endtask

task init_mem_commit;
integer row;
begin

// initializing RAMPDP_512X64_GL_M4_D2
for (row = 0; row < 512; row = row + 1)
 if (shadow_written[row]) r_nv_ram_rws_512x64.ram_Inst_512X64.mem_write(row - 0, shadow_mem[row][63:0]);

shadow_written = 'b0;
end
endtask
`endif
`endif
`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_VAL_TASKS
task do_write; //(wa, we, di);
   input  [8:0] wa;
   input   we;
   input  [63:0] di;
   reg    [63:0] d;
   begin
      d = probe_mem_val(wa);
      d = (we ? di : d);
      init_mem_val(wa,d);
   end
endtask

`endif
`endif


`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_VAL_TASKS

`ifndef MEM_REG_NAME 
 `define MEM_REG_NAME MX.mem
`endif

function [63:0] probe_mem_val;
input [8:0] row;
reg [63:0] data;
begin

// probing RAMPDP_512X64_GL_M4_D2
 if (row >=  0 &&  row < 512) data[63:0] = r_nv_ram_rws_512x64.ram_Inst_512X64.mem_read(row - 0);
    probe_mem_val = data;

end
endfunction
`endif
`endif

`ifndef SYNTHESIS
`ifndef NO_CLEAR_MEM_TASK
`ifndef NO_INIT_MEM_VAL_TASKS
reg disable_clear_mem = 0;
task clear_mem;
integer i;
begin
  if (!disable_clear_mem) 
  begin
    for (i = 0; i < 512; i = i + 1)
      begin
        init_mem_val(i, 'bx);
      end
    init_mem_commit();
  end
end
endtask
`endif
`endif
`endif

`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_ZERO_TASK
`ifndef NO_INIT_MEM_VAL_TASKS
task init_mem_zero;
integer i;
begin
 for (i = 0; i < 512; i = i + 1)
   begin
     init_mem_val(i, 'b0);
   end
 init_mem_commit();
end
endtask
`endif
`endif
`endif

`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_VAL_TASKS
`ifndef NO_INIT_MEM_FROM_FILE_TASK
task init_mem_from_file;
input string init_file;
integer i;
begin

 $readmemh(init_file,shadow_mem);
 for (i = 0; i < 512; i = i + 1)
   begin

     shadow_written[i] = 1'b1;

   end
 init_mem_commit();

end
endtask
`endif
`endif
`endif

`ifndef SYNTHESIS
`ifndef NO_INIT_MEM_RANDOM_TASK
`ifndef NO_INIT_MEM_VAL_TASKS
RANDFUNC rf0 ();
RANDFUNC rf1 ();

task init_mem_random;
reg [63:0] random_num;
integer i;
begin
 for (i = 0; i < 512; i = i + 1)
   begin
     random_num = {rf0.rollpli(0,32'hffffffff),rf1.rollpli(0,32'hffffffff)};
     init_mem_val(i, random_num);
   end
 init_mem_commit();
end
endtask
`endif
`endif
`endif

`ifndef SYNTHESIS
`ifndef NO_FLIP_TASKS
`ifndef NO_INIT_MEM_VAL_TASKS

RANDFUNC rflip ();

task random_flip;
integer random_num;
integer row;
integer bitnum;
begin
  random_num = rflip.rollpli(0, 32768);
  row = random_num / 64;
  bitnum = random_num % 64;
  target_flip(row, bitnum);
end
endtask

task target_flip;
input [8:0] row;
input [63:0] bitnum;
reg [63:0] data;
begin
  if(!$test$plusargs("no_display_target_flips"))
    $display("%m: flipping row %d bit %d at time %t", row, bitnum, $time);

  data = probe_mem_val(row);
  data[bitnum] = ~data[bitnum];
  init_mem_val(row, data);
  init_mem_commit();
end
endtask

`endif
`endif
`endif

// The main module is done
endmodule

//********************************************************************************
