// ================================================================
// NVDLA Open Source Project
// 
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with 
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_MCIF_READ_IG_bpt.v
#include "NV_NVDLA_MCIF_define.h"

`include "simulate_x_tick.vh"
`include "NV_NVDLA_define.vh"
module NV_NVDLA_MCIF_READ_IG_bpt (
   nvdla_core_clk           //|< i
  ,nvdla_core_rstn          //|< i
  ,dma2bpt_cdt_lat_fifo_pop //|< i
  ,dma2bpt_req_pd           //|< i
  ,dma2bpt_req_valid        //|< i
  ,dma2bpt_req_ready        //|> o
  ,bpt2arb_req_pd           //|> o
  ,bpt2arb_req_valid        //|> o
  ,bpt2arb_req_ready        //|< i
  ,tieoff_axid              //|< i
  ,tieoff_lat_fifo_depth    //|< i
  );


input  nvdla_core_clk;
input  nvdla_core_rstn;

input         dma2bpt_req_valid;  
output        dma2bpt_req_ready;  
input  [NVDLA_DMA_RD_REQ-1:0] dma2bpt_req_pd;
input         dma2bpt_cdt_lat_fifo_pop;

output        bpt2arb_req_valid;  
input         bpt2arb_req_ready;  
output [NVDLA_DMA_RD_IG_PW-1:0] bpt2arb_req_pd;
input  [3:0] tieoff_axid;
input  [8:0] tieoff_lat_fifo_depth;

reg   [NVDLA_DMA_RD_SIZE-1:0] count_req;
reg   [NVDLA_DMA_RD_SIZE-1:0] req_num;
wire         lat_fifo_stall_enable;
reg          lat_adv;
reg    [10:0] lat_cnt_ext;
reg    [10:0] lat_cnt_mod;
reg    [10:0] lat_cnt_new;
reg    [10:0] lat_cnt_nxt;
reg    [8:0] lat_cnt_cur;
reg    [8:0] lat_count_cnt;
reg    [0:0] lat_count_dec;
wire   [2:0] lat_count_inc;
wire   [8:0] lat_fifo_free_slot;
wire         mon_lat_fifo_free_slot_c;

reg   [NVDLA_MEM_ADDRESS_WIDTH-1:0] out_addr;
wire   [2:0] out_size;
reg    [2:0] out_size_tmp;
wire   [1:0] beat_size;
wire         bpt2arb_accept;
wire  [NVDLA_MEM_ADDRESS_WIDTH-1:0] bpt2arb_addr;
wire   [3:0] bpt2arb_axid;
wire         bpt2arb_ftran;
wire         bpt2arb_ltran;
wire         bpt2arb_odd;
wire   [2:0] bpt2arb_size;
wire         bpt2arb_swizzle;
wire   [NVDLA_MCIF_BURST_SIZE_LOG2-1:0] stt_offset;
wire   [NVDLA_MCIF_BURST_SIZE_LOG2-1:0] end_offset;
wire   [NVDLA_MCIF_BURST_SIZE_LOG2-1:0] size_offset;
wire   [NVDLA_MCIF_BURST_SIZE_LOG2-1:0] ftran_size_tmp;
wire   [NVDLA_MCIF_BURST_SIZE_LOG2-1:0] ltran_size_tmp;
wire         mon_end_offset_c;
wire  [2:0]  ftran_size;
wire  [2:0]  ltran_size;
wire  [NVDLA_DMA_RD_SIZE-1:0] mtran_num;
wire  [NVDLA_MEM_ADDRESS_WIDTH-1:0] in_addr;
wire  [NVDLA_DMA_RD_REQ-1:0] in_pd;
wire  [NVDLA_DMA_RD_REQ-1:0] in_pd_p;
wire         in_rdy;
wire         in_rdy_p;
wire  [NVDLA_DMA_RD_SIZE-1:0] in_size;
wire         in_vld;
wire         in_vld_p;
wire  [NVDLA_DMA_RD_REQ-1:0] in_vld_pd;
wire         is_ftran;
wire         is_ltran;
wire         is_mtran;
wire         is_single_tran;
wire         mon_out_beats_c;
wire         out_inc;
wire         out_odd;
wire         out_swizzle;
wire         req_enable;
wire         req_rdy;
wire         req_vld;

    
NV_NVDLA_MCIF_READ_IG_BPT_pipe_p1 pipe_p1 (
   .nvdla_core_clk    (nvdla_core_clk)       //|< i
  ,.nvdla_core_rstn   (nvdla_core_rstn)      //|< i
  ,.dma2bpt_req_pd    (dma2bpt_req_pd)       //|< i
  ,.dma2bpt_req_valid (dma2bpt_req_valid)    //|< i
  ,.dma2bpt_req_ready (dma2bpt_req_ready)    //|> o
  ,.in_pd_p           (in_pd_p)              //|> w
  ,.in_vld_p          (in_vld_p)             //|> w
  ,.in_rdy_p          (in_rdy_p)             //|< w
  );


NV_NVDLA_MCIF_READ_IG_BPT_pipe_p2 pipe_p2 (
   .nvdla_core_clk    (nvdla_core_clk)       //|< i
  ,.nvdla_core_rstn   (nvdla_core_rstn)      //|< i
  ,.in_pd_p           (in_pd_p)              //|< w
  ,.in_vld_p          (in_vld_p)             //|< w
  ,.in_rdy_p          (in_rdy_p)             //|> w
  ,.in_pd             (in_pd)                //|> w
  ,.in_vld            (in_vld)               //|> w
  ,.in_rdy            (in_rdy)               //|< w
  );


assign in_rdy = req_rdy & is_ltran;
assign in_vld_pd = {NVDLA_DMA_RD_REQ{in_vld}} & in_pd;

assign in_addr[NVDLA_MEM_ADDRESS_WIDTH-1:0] =  in_vld_pd[NVDLA_MEM_ADDRESS_WIDTH-1:0];
assign in_size[NVDLA_DMA_RD_SIZE-1:0]       =  in_vld_pd[NVDLA_DMA_RD_REQ-1:NVDLA_MEM_ADDRESS_WIDTH];

`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
  // VCS coverage off
  wire cond_zzz_assert_always_1x = (in_addr[NVDLA_MEMORY_ATOMIC_LOG2-1:0] == 0);
  nv_assert_always #(0,0,"lower LSB should always be 0")      zzz_assert_always_1x (.clk(nvdla_core_clk), .reset_(`ASSERT_RESET), .test_expr(cond_zzz_assert_always_1x)); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON


#if (NVDLA_MCIF_BURST_SIZE > 1)
assign stt_offset[NVDLA_MCIF_BURST_SIZE_LOG2-1:0]  = in_addr[NVDLA_MEMORY_ATOMIC_LOG2+NVDLA_MCIF_BURST_SIZE_LOG2-1:NVDLA_MEMORY_ATOMIC_LOG2];
assign size_offset[NVDLA_MCIF_BURST_SIZE_LOG2-1:0] = in_size[NVDLA_MCIF_BURST_SIZE_LOG2-1:0];
assign {mon_end_offset_c, end_offset[NVDLA_MCIF_BURST_SIZE_LOG2-1:0]} = stt_offset + size_offset;

assign is_single_tran = (stt_offset + in_size) < NVDLA_MCIF_BURST_SIZE;

assign ftran_size_tmp[NVDLA_MCIF_BURST_SIZE_LOG2-1:0] = is_single_tran ? size_offset : NVDLA_MCIF_BURST_SIZE -1 - stt_offset;
assign ltran_size_tmp[NVDLA_MCIF_BURST_SIZE_LOG2-1:0] = is_single_tran ? 0 : end_offset; 

assign ftran_size[2:0] = {{(3-NVDLA_MCIF_BURST_SIZE_LOG2){1'b0}},ftran_size_tmp};
assign ltran_size[2:0] = {{(3-NVDLA_MCIF_BURST_SIZE_LOG2){1'b0}},ltran_size_tmp};
assign mtran_num = in_size - ftran_size - ltran_size - 1;
#else
assign ftran_size[2:0] = 3'b0; 
assign ltran_size[2:0] = 3'b0;
assign mtran_num = in_size - 1;
#endif


//================
// check the empty entry of lat.fifo
//================
#if (NVDLA_MCIF_BURST_SIZE > 1)
reg    [2:0] slot_needed;
always @(
  out_size
  //or is_single_tran
  or is_ltran
  //or out_swizzle
  or is_ftran
  ) begin
    //if (is_single_tran) begin
    //    slot_needed = (out_size>>(NVDLA_DMA_MASK_BIT-1)) + 1;                      //fixme
    //end else if (is_ltran) begin
    //    slot_needed = ((out_size+out_swizzle)>>(NVDLA_DMA_MASK_BIT-1)) + 1;        //fixme
    //end else if (is_ftran) begin
    //    slot_needed = (out_size+1)>>(NVDLA_DMA_MASK_BIT-1);
    if (is_ftran | is_ltran) begin
        slot_needed = out_size+1;
    end else begin
        slot_needed = NVDLA_PRIMARY_MEMIF_MAX_BURST_LENGTH;
    end
end

#else 
wire   [2:0]  slot_needed = 3'b1;
#endif



assign lat_fifo_stall_enable = (tieoff_lat_fifo_depth!=0);
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    lat_count_dec <= 1'b0;
  end else begin
    lat_count_dec <= dma2bpt_cdt_lat_fifo_pop;
  end
end
assign lat_count_inc = (bpt2arb_accept && lat_fifo_stall_enable ) ? slot_needed : 0;


always @(
  lat_count_inc
  or lat_count_dec
  ) begin
  lat_adv = lat_count_inc[2:0] != {{2{1'b0}}, lat_count_dec[0:0]};
end
    
// lat cnt logic
always @(
  lat_cnt_cur
  or lat_count_inc
  or lat_count_dec
  or lat_adv
  ) begin
  // VCS sop_coverage_off start
  lat_cnt_ext[10:0] = {1'b0, 1'b0, lat_cnt_cur};
  lat_cnt_mod[10:0] = lat_cnt_cur + lat_count_inc[2:0] - lat_count_dec[0:0]; // spyglass disable W164b
  lat_cnt_new[10:0] = (lat_adv)? lat_cnt_mod[10:0] : lat_cnt_ext[10:0];
  lat_cnt_nxt[10:0] = lat_cnt_new[10:0];
  // VCS sop_coverage_off end
//| &End;
end

// lat flops
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    lat_cnt_cur[8:0] <= 0;
  end else begin
  lat_cnt_cur[8:0] <= lat_cnt_nxt[8:0];
  end
end

// lat output logic
always @(
  lat_cnt_cur
  ) begin
  lat_count_cnt[8:0] = lat_cnt_cur[8:0];
end
    
// lat asserts
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
  // VCS coverage off 
  nv_assert_never #(0,0,"never: counter underflow below <und_cnt>")      zzz_assert_never_2x (nvdla_core_clk, `ASSERT_RESET, (lat_cnt_nxt < 0)); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON

  
assign {mon_lat_fifo_free_slot_c,lat_fifo_free_slot[8:0]} = tieoff_lat_fifo_depth - lat_count_cnt;
assign req_enable = (!lat_fifo_stall_enable) || ({{6{1'b0}}, slot_needed} <= lat_fifo_free_slot);

`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
  // VCS coverage off 
  nv_assert_never #(0,0,"should not over flow")      zzz_assert_never_3x (nvdla_core_clk, `ASSERT_RESET, mon_lat_fifo_free_slot_c); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON

//================
// bsp out: swizzle
//================
#if (NVDLA_DMA_MASK_BIT==2)
assign out_swizzle = (stt_offset[0]==1'b1);
assign out_odd     = (in_size[0]==1'b0);
#else
assign out_swizzle = 1'b0;
assign out_odd     = 1'b0;
#endif

//================
// bsp out: size
//================
#if (NVDLA_MCIF_BURST_SIZE > 1)
always @(
  is_ftran
  or ftran_size
  or is_mtran
  or is_ltran
  or ltran_size
  ) begin
    out_size_tmp = {3{`tick_x_or_0}};
    if (is_ftran) begin
        out_size_tmp = ftran_size;
    end else if (is_mtran) begin
        out_size_tmp = NVDLA_MCIF_BURST_SIZE-1;
    end else if (is_ltran) begin
        out_size_tmp = ltran_size;
    end
end
assign out_size = out_size_tmp;
#else 
assign out_size = 3'h0;
#endif


#if (NVDLA_MEMIF_WIDTH > NVDLA_MEMORY_ATOMIC_WIDTH)
//================
// bsp out: USER: SIZE
//================
assign out_inc = is_ftran & is_ltran & out_swizzle && !out_odd;
assign {mon_out_beats_c,beat_size[1:0]} = out_size[2:1] + out_inc;
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
  // VCS coverage off 
  nv_assert_never #(0,0,"should never overflow")      zzz_assert_never_4x (nvdla_core_clk, `ASSERT_RESET, mon_out_beats_c); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
#endif

//================
// bpt2arb: addr
//================
always @(posedge nvdla_core_clk) begin
    if (bpt2arb_accept) begin
        if (is_ftran) begin
        #if (NVDLA_MCIF_BURST_SIZE > 1)
            out_addr <= in_addr + ((ftran_size+1) <<NVDLA_MEMORY_ATOMIC_LOG2);
        #else 
            out_addr <= in_addr + (1 <<NVDLA_MEMORY_ATOMIC_LOG2);
        #endif
        end else begin
            out_addr <= out_addr + (NVDLA_MCIF_BURST_SIZE<<NVDLA_MEMORY_ATOMIC_LOG2);
        end
    end
end

//================
// tran count
//================
#if (NVDLA_MCIF_BURST_SIZE > 1)
always @(
  is_single_tran
  or mtran_num
  ) begin
    if (is_single_tran) begin
        req_num = 0;
    end else begin
        req_num = 1 + mtran_num[14:NVDLA_MCIF_BURST_SIZE_LOG2];
    end
end
#else
always @(*) begin
  req_num = in_size;
end
#endif


always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    count_req <= {15{1'b0}};
  end else begin
    if (bpt2arb_accept) begin
        if (is_ltran) begin
            count_req <= 0;
        end else begin
            count_req <= count_req + 1;
        end
    end
  end
end

assign is_ftran = (count_req==0);
assign is_mtran = (count_req>0 && count_req<req_num);
assign is_ltran = (count_req==req_num);

assign bpt2arb_addr = (is_ftran) ? in_addr : out_addr;
assign bpt2arb_size = out_size;
assign bpt2arb_swizzle = out_swizzle;
assign bpt2arb_odd   = out_odd;
assign bpt2arb_ltran = is_ltran;
assign bpt2arb_ftran = is_ftran;
assign bpt2arb_axid  = tieoff_axid[3:0];

assign req_rdy = req_enable & bpt2arb_req_ready;
assign req_vld = req_enable & in_vld; 

assign bpt2arb_req_valid = req_vld;
assign bpt2arb_accept = bpt2arb_req_valid & req_rdy;

assign      bpt2arb_req_pd[3:0] =  bpt2arb_axid[3:0];
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+3:4] =    bpt2arb_addr[NVDLA_MEM_ADDRESS_WIDTH-1:0];
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+6:NVDLA_MEM_ADDRESS_WIDTH+4] =    bpt2arb_size[2:0];
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+7]  =    bpt2arb_swizzle ;
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+8]  =    bpt2arb_odd ;
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+9]  =    bpt2arb_ltran ;
assign      bpt2arb_req_pd[NVDLA_MEM_ADDRESS_WIDTH+10] =    bpt2arb_ftran ;


#if (NVDLA_MCIF_BURST_SIZE > 1)
//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    reg funcpoint_cover_off;
    initial begin
        if ( $test$plusargs( "cover_off" ) ) begin
            funcpoint_cover_off = 1'b1;
        end else begin
            funcpoint_cover_off = 1'b0;
        end
    end

    property mcif_bpt__is_first_trans__0_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        ((req_vld) && nvdla_core_rstn) |-> (is_ftran);
    endproperty
    // Cover 0 : "is_ftran"
    FUNCPOINT_mcif_bpt__is_first_trans__0_COV : cover property (mcif_bpt__is_first_trans__0_cov);

  `endif
`endif
//VCS coverage on

//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property mcif_bpt__is_middle_trans__1_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        ((req_vld) && nvdla_core_rstn) |-> (is_mtran);
    endproperty
    // Cover 1 : "is_mtran"
    FUNCPOINT_mcif_bpt__is_middle_trans__1_COV : cover property (mcif_bpt__is_middle_trans__1_cov);

  `endif
`endif
//VCS coverage on

//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property mcif_bpt__is_last_trans__2_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        ((req_vld) && nvdla_core_rstn) |-> (is_ltran);
    endproperty
    // Cover 2 : "is_ltran"
    FUNCPOINT_mcif_bpt__is_last_trans__2_COV : cover property (mcif_bpt__is_last_trans__2_cov);

  `endif
`endif
//VCS coverage on

#if (NVDLA_MEMIF_WIDTH > NVDLA_MEMORY_ATOMIC_WIDTH)
//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property mcif_bpt__is_swizzle_and_odd__3_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        ((req_vld) && nvdla_core_rstn) |-> (out_swizzle & out_odd);
    endproperty
    // Cover 3 : "out_swizzle & out_odd"
    FUNCPOINT_mcif_bpt__is_swizzle_and_odd__3_COV : cover property (mcif_bpt__is_swizzle_and_odd__3_cov);

  `endif
`endif
//VCS coverage on
#endif

//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property mcif_bpt__is_odd_not_swizzle__4_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        ((req_vld) && nvdla_core_rstn) |-> (out_odd & !out_swizzle);
    endproperty
    // Cover 4 : "out_odd & !out_swizzle"
    FUNCPOINT_mcif_bpt__is_odd_not_swizzle__4_COV : cover property (mcif_bpt__is_odd_not_swizzle__4_cov);

  `endif
`endif
//VCS coverage on

//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property mcif_bpt__count_inc_and_dec__5_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        lat_count_inc & lat_count_dec;
    endproperty
    // Cover 5 : "lat_count_inc & lat_count_dec"
    FUNCPOINT_mcif_bpt__count_inc_and_dec__5_COV : cover property (mcif_bpt__count_inc_and_dec__5_cov);

  `endif
`endif
//VCS coverage on
#endif

endmodule // NV_NVDLA_MCIF_READ_IG_bpt



// **************************************************************************************************************
// Generated by ::pipe -m -bc -is in_pd_p (in_vld_p,in_rdy_p) <= dma2bpt_req_pd[NVDLA_DMA_RD_REQ-1:0] (dma2bpt_req_valid,dma2bpt_req_ready)
// **************************************************************************************************************
`include "NV_NVDLA_define.vh"
module NV_NVDLA_MCIF_READ_IG_BPT_pipe_p1 (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,dma2bpt_req_pd
  ,dma2bpt_req_valid
  ,dma2bpt_req_ready
  ,in_pd_p
  ,in_vld_p
  ,in_rdy_p
  );
input         nvdla_core_clk;
input         nvdla_core_rstn;
input  [NVDLA_DMA_RD_REQ-1:0] dma2bpt_req_pd;
input         dma2bpt_req_valid;
output        dma2bpt_req_ready;
output [NVDLA_DMA_RD_REQ-1:0] in_pd_p;
output        in_vld_p;
input         in_rdy_p;

//: my $mem = NVDLA_DMA_RD_REQ;
//: &eperl::pipe(" -wid $mem -is -do in_pd_p -vo in_vld_p -ri in_rdy_p  -di dma2bpt_req_pd -vi dma2bpt_req_valid -ro dma2bpt_req_ready ");


endmodule



// **************************************************************************************************************
// Generated by ::pipe -m -bc -is in_pd (in_vld,in_rdy) <= in_pd_p[NVDLA_DMA_RD_REQ-1:0] (in_vld_p,in_rdy_p)
// **************************************************************************************************************
`include "NV_NVDLA_define.vh"
module NV_NVDLA_MCIF_READ_IG_BPT_pipe_p2 (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,in_pd_p
  ,in_vld_p
  ,in_rdy_p
  ,in_pd
  ,in_vld
  ,in_rdy
  );
input         nvdla_core_clk;
input         nvdla_core_rstn;
input  [NVDLA_DMA_RD_REQ-1:0] in_pd_p;
input         in_vld_p;
output        in_rdy_p;
output [NVDLA_DMA_RD_REQ-1:0] in_pd;
output        in_vld;
input         in_rdy;


//: my $mem = NVDLA_DMA_RD_REQ;
//: &eperl::pipe(" -wid $mem -is -do in_pd -vo in_vld -ri in_rdy -di in_pd_p -vi in_vld_p -ro in_rdy_p ");


endmodule // NV_NVDLA_MCIF_READ_IG_BPT_pipe_p2


