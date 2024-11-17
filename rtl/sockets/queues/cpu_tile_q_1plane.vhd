------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    cpu_tile_q_1plane.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
-- This file was originally part of the ESP project source code, available at:
-- https://github.com/sld-columbia/esp
------------------------------------------------------------------------------


-- Copyright (c) 2011-2023 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

library ieee;
use ieee.std_logic_1164.all;

use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;

use work.gencomp.all;
use work.genacc.all;

use work.nocpackage.all;
use work.tile.all;

entity cpu_tile_q_1plane is
  generic (
    tech        : integer := virtex7);
  port (
    rst                        : in  std_ulogic;
    clk                        : in  std_ulogic;
    -- tile->NoC1
    coherence_req_wrreq        : in  std_ulogic;
    coherence_req_data_in      : in  noc_flit_type;
    coherence_req_full         : out std_ulogic;
    -- NoC2->tile
    coherence_fwd_rdreq        : in  std_ulogic;
    coherence_fwd_data_out     : out noc_flit_type;
    coherence_fwd_empty        : out std_ulogic;
    -- Noc3->tile
    coherence_rsp_rcv_rdreq    : in  std_ulogic;
    coherence_rsp_rcv_data_out : out noc_flit_type;
    coherence_rsp_rcv_empty    : out std_ulogic;
    -- tile->Noc3
    coherence_rsp_snd_wrreq    : in  std_ulogic;
    coherence_rsp_snd_data_in  : in  noc_flit_type;
    coherence_rsp_snd_full     : out std_ulogic;
    -- tile->Noc2
    coherence_fwd_snd_wrreq    : in  std_ulogic;
    coherence_fwd_snd_data_in  : in  noc_flit_type;
    coherence_fwd_snd_full     : out std_ulogic;
    -- noc1->tile
    remote_ahbs_snd_wrreq      : in  std_ulogic;
    remote_ahbs_snd_data_in    : in  misc_noc_flit_type;
    remote_ahbs_snd_full       : out std_ulogic;
    -- NoC4->tile
    dma_rcv_rdreq              : in  std_ulogic;
    dma_rcv_data_out           : out noc_flit_type;
    dma_rcv_empty              : out std_ulogic;
    -- tile->NoC6
    dma_snd_wrreq              : in  std_ulogic;
    dma_snd_data_in            : in  noc_flit_type;
    dma_snd_full               : out std_ulogic;
    -- tile->noc1
    remote_ahbs_rcv_rdreq      : in  std_ulogic;
    remote_ahbs_rcv_data_out   : out misc_noc_flit_type;
    remote_ahbs_rcv_empty      : out std_ulogic;
    -- noc1->tile
    apb_rcv_rdreq              : in  std_ulogic;
    apb_rcv_data_out           : out misc_noc_flit_type;
    apb_rcv_empty              : out std_ulogic;
    -- tile->noc1
    apb_snd_wrreq              : in  std_ulogic;
    apb_snd_data_in            : in  misc_noc_flit_type;
    apb_snd_full               : out std_ulogic;
    -- noc1->tile
    remote_apb_rcv_rdreq       : in  std_ulogic;
    remote_apb_rcv_data_out    : out misc_noc_flit_type;
    remote_apb_rcv_empty       : out std_ulogic;
    -- tile->noc1
    remote_apb_snd_wrreq       : in  std_ulogic;
    remote_apb_snd_data_in     : in  misc_noc_flit_type;
    remote_apb_snd_full        : out std_ulogic;
    -- noc1->tile
    remote_irq_rdreq           : in  std_ulogic;
    remote_irq_data_out        : out misc_noc_flit_type;
    remote_irq_empty           : out std_ulogic;
    -- tile->noc1
    remote_irq_ack_wrreq       : in  std_ulogic;
    remote_irq_ack_data_in     : in  misc_noc_flit_type;
    remote_irq_ack_full        : out std_ulogic;

    -- Cachable data plane 1 -> request messages
    noc1_out_data : in  noc_flit_type;
    noc1_out_void : in  std_ulogic;
    noc1_out_stop : out std_ulogic;
    noc1_in_data  : out noc_flit_type;
    noc1_in_void  : out std_ulogic;
    noc1_in_stop  : in  std_ulogic);

end cpu_tile_q_1plane;

architecture rtl of cpu_tile_q_1plane is

  signal fifo_rst : std_ulogic;

  -- tile->NoC1
  signal coherence_req_rdreq        : std_ulogic;
  signal coherence_req_data_out     : noc_flit_type;
  signal coherence_req_empty        : std_ulogic;
  -- NoC2->tile
  signal coherence_fwd_wrreq        : std_ulogic;
  signal coherence_fwd_data_in      : noc_flit_type;
  signal coherence_fwd_full         : std_ulogic;
  -- NoC3->tile
  signal coherence_rsp_rcv_wrreq    : std_ulogic;
  signal coherence_rsp_rcv_data_in  : noc_flit_type;
  signal coherence_rsp_rcv_full     : std_ulogic;
  -- tile->NoC3
  signal coherence_rsp_snd_rdreq    : std_ulogic;
  signal coherence_rsp_snd_data_out : noc_flit_type;
  signal coherence_rsp_snd_empty    : std_ulogic;
  -- tile->NoC2
  signal coherence_fwd_snd_rdreq    : std_ulogic;
  signal coherence_fwd_snd_data_out : noc_flit_type;
  signal coherence_fwd_snd_empty    : std_ulogic;
  -- NoC4->tile
  signal dma_rcv_wrreq              : std_ulogic;
  signal dma_rcv_data_in            : noc_flit_type;
  signal dma_rcv_full               : std_ulogic;
  -- tile->NoC6
  signal dma_snd_rdreq              : std_ulogic;
  signal dma_snd_data_out           : noc_flit_type;
  signal dma_snd_empty              : std_ulogic;
  -- tile->noc1
  signal remote_ahbs_snd_rdreq      : std_ulogic;
  signal remote_ahbs_snd_data_out   : misc_noc_flit_type;
  signal remote_ahbs_snd_empty      : std_ulogic;
  -- noc1->tile
  signal remote_ahbs_rcv_wrreq      : std_ulogic;
  signal remote_ahbs_rcv_data_in    : misc_noc_flit_type;
  signal remote_ahbs_rcv_full       : std_ulogic;
  -- noc1->tile
  signal apb_rcv_wrreq              : std_ulogic;
  signal apb_rcv_data_in            : misc_noc_flit_type;
  signal apb_rcv_full               : std_ulogic;
  -- tile->noc1
  signal apb_snd_rdreq              : std_ulogic;
  signal apb_snd_data_out           : misc_noc_flit_type;
  signal apb_snd_empty              : std_ulogic;
  -- noc1->tile
  signal remote_apb_rcv_wrreq       : std_ulogic;
  signal remote_apb_rcv_data_in     : misc_noc_flit_type;
  signal remote_apb_rcv_full        : std_ulogic;
  -- tile->noc1
  signal remote_apb_snd_rdreq       : std_ulogic;
  signal remote_apb_snd_data_out    : misc_noc_flit_type;
  signal remote_apb_snd_empty       : std_ulogic;
  -- noc1->tile
  signal remote_irq_wrreq           : std_ulogic;
  signal remote_irq_data_in         : misc_noc_flit_type;
  signal remote_irq_full            : std_ulogic;
  -- tile->noc1
  signal remote_irq_ack_rdreq       : std_ulogic;
  signal remote_irq_ack_data_out    : misc_noc_flit_type;
  signal remote_irq_ack_empty       : std_ulogic;

  -- Local Master -> Local apb slave (request)
  signal local_remote_apb_snd_wrreq    : std_ulogic;
  signal local_remote_apb_snd_data_in  : misc_noc_flit_type;
  signal local_remote_apb_snd_full     : std_ulogic;
  signal local_remote_apb_rcv_rdreq    : std_ulogic;
  signal local_remote_apb_rcv_data_out : misc_noc_flit_type;
  signal local_remote_apb_rcv_empty    : std_ulogic;
  -- Local apb slave --> Local Master (response)
  signal local_apb_snd_wrreq           : std_ulogic;
  signal local_apb_snd_data_in         : misc_noc_flit_type;
  signal local_apb_snd_full            : std_ulogic;
  signal local_apb_rcv_rdreq           : std_ulogic;
  signal local_apb_rcv_data_out        : misc_noc_flit_type;
  signal local_apb_rcv_empty           : std_ulogic;

  type noc1_packet_fsm is (none, packet_remote_apb_rcv, packet_ahbm_rcv, packet_irq,
                           packet_apb_rcv, packet_local_remote_apb_rcv, packet_local_apb_rcv,
                           packet_remote_ahbs_rcv, packet_coherence_rsp_rcv, packet_dma_rcv, packet_coherence_fwd);
  signal noc1_fifos_current, noc1_fifos_next : noc1_packet_fsm;
  type to_noc1_packet_fsm is (none, packet_remote_apb_snd, packet_ahbm_snd, packet_irq_ack,
                              packet_apb_snd, packet_local_remote_apb_snd, packet_local_apb_snd,
                              packet_remote_ahbs_snd, packet_coherence_req, packet_coherence_rsp_snd, packet_dma_snd, packet_coherence_fwd_snd);
  signal to_noc1_fifos_current, to_noc1_fifos_next : to_noc1_packet_fsm;


  signal noc3_msg_type : noc_msg_type;
  signal noc3_preamble : noc_preamble_type;
  signal noc1_msg_type : noc_msg_type;
  signal noc1_preamble : noc_preamble_type;
  signal local_remote_apb_rcv_preamble : noc_preamble_type;
  signal local_apb_rcv_preamble : noc_preamble_type;

begin  -- rtl

  fifo_rst <= rst;                  --FIFO rst active low

  -- To noc1: coherence requests from CPU to directory (GET/PUT)
  --noc1_out_stop         <= '0';
  --noc1_in_data          <= coherence_req_data_out;
  --noc1_in_void          <= coherence_req_empty or noc1_in_stop;
  --coherence_req_rdreq   <= (not coherence_req_empty) and (not noc1_in_stop);
  fifo_1: fifo0
    generic map (
      depth => 6,                       --Header, address, [cache line]
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherence_req_rdreq,
      wrreq    => coherence_req_wrreq,
      data_in  => coherence_req_data_in,
      empty    => coherence_req_empty,
      full     => coherence_req_full,
      data_out => coherence_req_data_out);


  -- From noc2: coherence forwarded messages to CPU (INV, GETS/M)
  --noc2_out_stop <= coherence_fwd_full and (not noc2_out_void);
  --coherence_fwd_data_in <= noc2_out_data;
  --coherence_fwd_wrreq <= (not noc2_out_void) and (not coherence_fwd_full);

  fifo_2: fifo0
    generic map (
      depth => 4,                       --Header, address (x2)
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherence_fwd_rdreq,
      wrreq    => coherence_fwd_wrreq,
      data_in  => coherence_fwd_data_in,
      empty    => coherence_fwd_empty,
      full     => coherence_fwd_full,
      data_out => coherence_fwd_data_out);



  -- From noc3: coherence response messages to CPU (DATA, INVACK, PUTACK)
  --noc3_out_stop <= coherence_rsp_rcv_full and (not noc3_out_void);
  --coherence_rsp_rcv_data_in <= noc3_out_data;
  --coherence_rsp_rcv_wrreq <= (not noc3_out_void) and (not coherence_rsp_rcv_full);

  fifo_3: fifo0
    generic map (
      depth => 5,                       --Header (use RESERVED field to
                                        --determine  ACK number), cache line
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherence_rsp_rcv_rdreq,
      wrreq    => coherence_rsp_rcv_wrreq,
      data_in  => coherence_rsp_rcv_data_in,
      empty    => coherence_rsp_rcv_empty,
      full     => coherence_rsp_rcv_full,
      data_out => coherence_rsp_rcv_data_out);


  -- To noc3: coherence response messages from CPU (DATA, EDATA, INVACK)
  --noc3_in_data          <= coherence_rsp_snd_data_out;
  --noc3_in_void          <= coherence_rsp_snd_empty or noc3_in_stop;
  --coherence_rsp_snd_rdreq   <= (not coherence_rsp_snd_empty) and (not noc3_in_stop);
  fifo_4: fifo0
    generic map (
      depth => 5,                       --Header
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherence_rsp_snd_rdreq,
      wrreq    => coherence_rsp_snd_wrreq,
      data_in  => coherence_rsp_snd_data_in,
      empty    => coherence_rsp_snd_empty,
      full     => coherence_rsp_snd_full,
      data_out => coherence_rsp_snd_data_out);

  -- To noc2: dcs l2_fwd_out
  --noc2_in_data          <= coherence_fwd_snd_data_out;
  --noc2_in_void          <= coherence_fwd_snd_empty or noc2_in_stop;
  --coherence_fwd_snd_rdreq   <= (not coherence_fwd_snd_empty) and (not noc2_in_stop);
  fifo_5: fifo0
    generic map (
      depth => 5,                       --Header
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherence_fwd_snd_rdreq,
      wrreq    => coherence_fwd_snd_wrreq,
      data_in  => coherence_fwd_snd_data_in,
      empty    => coherence_fwd_snd_empty,
      full     => coherence_fwd_snd_full,
      data_out => coherence_fwd_snd_data_out);


  -- From noc1: remote APB response to core (APB rcv)
  -- From noc1: remove AHB master request to DSU (AHBM rcv)
  -- From noc1: IRQ
  -- From local_remote_apb_rcv (APB rcv from devices in this tile)
  noc1_msg_type <= get_msg_type(NOC_FLIT_SIZE, noc1_out_data);
  noc1_preamble <= get_preamble(NOC_FLIT_SIZE, noc1_out_data);
  local_remote_apb_rcv_preamble <= get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & local_remote_apb_rcv_data_out);
  local_apb_rcv_preamble <= get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & local_apb_rcv_data_out);

  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      noc1_fifos_current <= none;
    elsif clk'event and clk = '1' then
      noc1_fifos_current <= noc1_fifos_next;   -- rising clock edge
    end if;
  end process;
  noc1_fifos_get_packet: process (noc1_out_data, noc1_out_void, noc1_msg_type,
                                  noc1_preamble, remote_apb_rcv_full,
                                  remote_irq_full,
                                  noc1_fifos_current,
                                  apb_rcv_full, local_remote_apb_rcv_empty,
                                  local_apb_rcv_empty, local_remote_apb_rcv_data_out,
                                  local_apb_rcv_data_out, local_remote_apb_rcv_preamble,
                                  local_apb_rcv_preamble,
                                  remote_ahbs_rcv_full,
                                  coherence_rsp_rcv_full,
                                  dma_rcv_full,
                                  coherence_fwd_full)
  begin  -- process noc1_get_packet
    remote_apb_rcv_wrreq <= '0';
    remote_apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    remote_irq_wrreq <= '0';

    apb_rcv_wrreq <= '0';
    apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    remote_ahbs_rcv_wrreq <= '0';
    remote_ahbs_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    coherence_rsp_rcv_wrreq <= '0';
    coherence_rsp_rcv_data_in <= noc1_out_data;

    dma_rcv_wrreq <= '0';
    dma_rcv_data_in <= noc1_out_data;

    coherence_fwd_wrreq <= '0';
    coherence_fwd_data_in <= noc1_out_data;

    noc1_fifos_next <= noc1_fifos_current;
    noc1_out_stop <= '0';

    local_remote_apb_rcv_rdreq <= '0';
    local_apb_rcv_rdreq <= '0';



    case noc1_fifos_current is
      when none =>
                   --LOCAL REMOTE APB RCV (originally on NoC 5)
                   if local_remote_apb_rcv_empty = '0' then
                     noc1_out_stop <= not noc1_out_void;
                     if apb_rcv_full = '0' then
                       local_remote_apb_rcv_rdreq <= '1';
                       apb_rcv_wrreq <= '1';
                       apb_rcv_data_in <= local_remote_apb_rcv_data_out;
                       noc1_fifos_next <= packet_local_remote_apb_rcv;
                     end if;
                   --LOCAL APB RCV (originally on NoC 5)
                   elsif local_apb_rcv_empty = '0' then
                     noc1_out_stop <= not noc1_out_void;
                     if remote_apb_rcv_full = '0' then
                       local_apb_rcv_rdreq <= '1';
                       remote_apb_rcv_wrreq <= '1';
                       remote_apb_rcv_data_in <= local_apb_rcv_data_out;
                       noc1_fifos_next <= packet_local_apb_rcv;
                     end if;
                   elsif noc1_out_void = '0' then
                     --REMOTE APB RCV (originally on NoC 5)
                     if (noc1_msg_type = RSP_REG_RD
                         and noc1_preamble = PREAMBLE_HEADER) then
                       if remote_apb_rcv_full = '0' then
                         remote_apb_rcv_wrreq <= '1';
                         noc1_fifos_next <= packet_remote_apb_rcv;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --REMOTE IRQ (originally on NoC 5)
                     elsif (noc1_msg_type = IRQ_MSG and (noc1_preamble = PREAMBLE_HEADER or noc1_preamble = PREAMBLE_1FLIT)) then
                       if remote_irq_full = '0' then
                         remote_irq_wrreq <= '1';
                         if noc1_preamble = PREAMBLE_HEADER then
                           -- Leon3 needs more than single-flit packet
                           noc1_fifos_next <= packet_irq;
                         end if;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --APB RCV (originally on NoC 5)
                     elsif ((noc1_msg_type = REQ_REG_RD or noc1_msg_type = REQ_REG_WR) and noc1_preamble = PREAMBLE_HEADER) then
                       if apb_rcv_full = '0' then
                         apb_rcv_wrreq <= '1';
                         noc1_fifos_next <= packet_apb_rcv;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --REMOTE AHBS RCV (originally on NoC 5)
                     elsif ((noc1_msg_type = RSP_AHB_RD) and noc1_preamble = PREAMBLE_HEADER) then
                       if remote_ahbs_rcv_full = '0' then
                         remote_ahbs_rcv_wrreq <= '1';
                         noc1_fifos_next <= packet_remote_ahbs_rcv;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --COHERENCE RSP RCV (originally on NoC 3)
                     elsif ((noc1_msg_type = RSP_DATA or noc1_msg_type = RSP_EDATA or noc1_msg_type = RSP_INV_ACK) and noc1_preamble = PREAMBLE_HEADER) then
                       if coherence_rsp_rcv_full = '0' then
                         coherence_rsp_rcv_wrreq <= '1';
                         noc1_fifos_next <= packet_coherence_rsp_rcv;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --DMA RCV (originally on NoC 4)
                     elsif ((noc1_msg_type = DMA_FROM_DEV or noc1_msg_type = DMA_TO_DEV) and noc1_preamble = PREAMBLE_HEADER) then
                       if dma_rcv_full = '0' then
                         dma_rcv_wrreq <= '1';
                         noc1_fifos_next <= packet_dma_rcv;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     --COHERENCE FWD (originally on NoC 2)
                     elsif ((noc1_msg_type = FWD_GETS or noc1_msg_type = FWD_GETM or noc1_msg_type = FWD_INV or noc1_msg_type = FWD_PUT_ACK or noc1_msg_type = FWD_GETM_NOCOH or noc1_msg_type = FWD_INV_NOCOH) and noc1_preamble = PREAMBLE_HEADER) then
                       if coherence_fwd_full = '0' then
                         coherence_fwd_wrreq <= '1';
                         noc1_fifos_next <= packet_coherence_fwd;
                       else
                         noc1_out_stop <= '1';
                       end if;
                     end if;
                   end if;
      --REMOTE APB RCV (originally on NoC 5)
      when packet_remote_apb_rcv => remote_apb_rcv_wrreq <= (not noc1_out_void) and (not remote_apb_rcv_full);
                             noc1_out_stop <= remote_apb_rcv_full and (not noc1_out_void);
                             if noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                             remote_apb_rcv_full = '0' then
                               noc1_fifos_next <= none;
                             end if;
      --LOCAL REMOTE APB RCV (originally on NoC 5)
      when packet_local_remote_apb_rcv => noc1_out_stop <= not noc1_out_void;
                                          apb_rcv_wrreq <= not local_remote_apb_rcv_empty and (not apb_rcv_full);
                                          apb_rcv_data_in <= local_remote_apb_rcv_data_out;
                                          if (local_remote_apb_rcv_empty = '0' and apb_rcv_full = '0') then
                                            local_remote_apb_rcv_rdreq <= '1';
                                            if local_remote_apb_rcv_preamble = PREAMBLE_TAIL then
                                                noc1_fifos_next <= none;
                                            end if;
                                          end if;
      --REMOTE IRQ (originally on NoC 5)
      when packet_irq => remote_irq_wrreq <= not noc1_out_void and (not remote_irq_full);
                             noc1_out_stop <= remote_irq_full and (not noc1_out_void);
                             if noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                             remote_irq_full = '0' then
                               noc1_fifos_next <= none;
                             end if;
      --APB RCV (originally on NoC 5)
      when packet_apb_rcv => apb_rcv_wrreq <= not noc1_out_void and (not apb_rcv_full);
                             noc1_out_stop <= apb_rcv_full and (not noc1_out_void);
                             if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                                 apb_rcv_full = '0') then
                               noc1_fifos_next <= none;
                             end if;
      --LOCAL APB RCV (originally on NoC 5)
      when packet_local_apb_rcv => noc1_out_stop <= not noc1_out_void;
                              remote_apb_rcv_wrreq <= not local_apb_rcv_empty and (not remote_apb_rcv_full);
                              local_apb_rcv_rdreq <= (not remote_apb_rcv_full);
                              remote_apb_rcv_data_in <= local_apb_rcv_data_out;
                              if (local_apb_rcv_preamble = PREAMBLE_TAIL and local_apb_rcv_empty = '0' and
                                  remote_apb_rcv_full = '0') then
                                noc1_fifos_next <= none;
                              end if;
      --REMOTE AHBS RCV (originally on NoC 5)
      when packet_remote_ahbs_rcv => remote_ahbs_rcv_wrreq <= not noc1_out_void and (not remote_ahbs_rcv_full);
                              noc1_out_stop <= remote_ahbs_rcv_full and (not noc1_out_void);
                              if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                                  remote_ahbs_rcv_full = '0') then
                                noc1_fifos_next <= none;
                              end if;
      --COHERENCE RSP RCV (originally on NoC 3)
      when packet_coherence_rsp_rcv => coherence_rsp_rcv_wrreq <= not noc1_out_void and (not coherence_rsp_rcv_full);
                              noc1_out_stop <= coherence_rsp_rcv_full and (not noc1_out_void);
                              if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                                  coherence_rsp_rcv_full = '0') then
                                noc1_fifos_next <= none;
                              end if;
      --DMA RCV (originally on NoC 4)
      when packet_dma_rcv => dma_rcv_wrreq <= not noc1_out_void and (not dma_rcv_full);
                              noc1_out_stop <= dma_rcv_full and (not noc1_out_void);
                              if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                                  dma_rcv_full = '0') then
                                noc1_fifos_next <= none;
                              end if;
      --COHERENCE FWD (originally on NoC 2)
      when packet_coherence_fwd => coherence_fwd_wrreq <= not noc1_out_void and (not coherence_fwd_full);
                              noc1_out_stop <= coherence_fwd_full and (not noc1_out_void);
                              if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
                                  coherence_fwd_full = '0') then
                                noc1_fifos_next <= none;
                              end if;
      when others => noc1_fifos_next <= none;
    end case;
  end process noc1_fifos_get_packet;

  fifo_7: fifo0
    generic map (
    depth => 2,                       --Header, data
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_apb_rcv_rdreq,
      wrreq    => remote_apb_rcv_wrreq,
      data_in  => remote_apb_rcv_data_in,
      empty    => remote_apb_rcv_empty,
      full     => remote_apb_rcv_full,
      data_out => remote_apb_rcv_data_out);

  remote_irq_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_9: fifo0
    generic map (
      depth => 2,                       --Header, irq level
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_irq_rdreq,
      wrreq    => remote_irq_wrreq,
      data_in  => remote_irq_data_in,
      empty    => remote_irq_empty,
      full     => remote_irq_full,
      data_out => remote_irq_data_out);

  fifo_16: fifo0
    generic map (
      depth => 3,                       --Header, address, data
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => apb_rcv_rdreq,
      wrreq    => apb_rcv_wrreq,
      data_in  => apb_rcv_data_in,
      empty    => apb_rcv_empty,
      full     => apb_rcv_full,
      data_out => apb_rcv_data_out);

  fifo_20: fifo0
    generic map (
      depth => 3,                       --Header, address, data
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_ahbs_rcv_rdreq,
      wrreq    => remote_ahbs_rcv_wrreq,
      data_in  => remote_ahbs_rcv_data_in,
      empty    => remote_ahbs_rcv_empty,
      full     => remote_ahbs_rcv_full,
      data_out => remote_ahbs_rcv_data_out);

  -- To noc1: remote APB request from core (APB snd)
  -- To noc1: remote AHB master response from DSU (AHBM snd) - CPU0 tile only
  -- To noc1: remote irq acknowledge response from CPU (IRQ)
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      to_noc1_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge
      to_noc1_fifos_current <= to_noc1_fifos_next;
    end if;
  end process;

  to_noc1_select_packet: process (noc1_in_stop, to_noc1_fifos_current,
                                  remote_apb_snd_data_out, remote_apb_snd_empty,
                                  remote_irq_ack_data_out, remote_irq_ack_empty,
                                  apb_snd_data_out, apb_snd_empty,
                                  local_remote_apb_snd_full, local_apb_snd_full,
                                  remote_ahbs_snd_data_out, remote_ahbs_snd_empty,
                                  coherence_req_data_out, coherence_req_empty,
                                  coherence_rsp_snd_data_out, coherence_rsp_snd_empty,
                                  dma_snd_data_out, dma_snd_rdreq,
                                  coherence_fwd_snd_data_out, coherence_fwd_snd_empty)
    variable to_noc1_preamble : noc_preamble_type;
    variable remote_apb_snd_to_local : std_ulogic;
    variable apb_snd_to_local : std_ulogic;
  begin  -- process to_noc1_select_packet
    remote_apb_snd_to_local := remote_apb_snd_data_out(HEADER_ROUTE_L);
    apb_snd_to_local        := apb_snd_data_out(HEADER_ROUTE_L);
    local_remote_apb_snd_wrreq <= '0';
    local_apb_snd_wrreq <= '0';

    noc1_in_data <= (others => '0');
    noc1_in_void <= '1';

    remote_apb_snd_rdreq <= '0';
    remote_irq_ack_rdreq <= '0';
    apb_snd_rdreq <= '0';
    remote_ahbs_snd_rdreq <= '0';
    coherence_req_rdreq <= '0';
    coherence_rsp_snd_rdreq <= '0';
    dma_snd_rdreq <= '0';
    coherence_fwd_snd_rdreq <= '0';

    to_noc1_fifos_next <= to_noc1_fifos_current;
    to_noc1_preamble := "00";

    case to_noc1_fifos_current is
      when none  =>
                    --REMOTE IRQ (originally on NoC 5)
                    if remote_irq_ack_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_Data <= narrow_to_large_flit(remote_irq_ack_data_out);
                        noc1_in_void <= remote_irq_ack_empty;
                        remote_irq_ack_rdreq <= '1';
                        to_noc1_fifos_next <= packet_irq_ack;
                      end if;
                    --REMOTE APB SND (originally on NoC 5)
                    elsif (remote_apb_snd_empty = '0' and remote_apb_snd_to_local = '0') then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= narrow_to_large_flit(remote_apb_snd_data_out);
                        noc1_in_void <= remote_apb_snd_empty;
                        remote_apb_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_remote_apb_snd;
                      end if;
                    --LOCAL REMOTE APB SND (originally on NoC 5)
                    elsif (remote_apb_snd_empty = '0' and remote_apb_snd_to_local = '1') then
                      if local_remote_apb_snd_full = '0' then
                        local_remote_apb_snd_wrreq <= '1';
                        remote_apb_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_local_remote_apb_snd;
                      end if;
                    --APB SND (originally on NoC 5)
                    elsif (apb_snd_empty = '0' and apb_snd_to_local = '0') then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= narrow_to_large_flit(apb_snd_data_out);
                        noc1_in_void <= apb_snd_empty;
                        apb_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_apb_snd;
                      end if;
                    --LOCAL APB SND (originally on NoC 5)
                    elsif (apb_snd_empty = '0' and apb_snd_to_local = '1') then
                      if local_apb_snd_full = '0' then
                        local_apb_snd_wrreq <= '1';
                        apb_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_local_apb_snd;
                      end if;
                    --REMOTE AHBS SND (originally on NoC 5)
                    elsif remote_ahbs_snd_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= narrow_to_large_flit(remote_ahbs_snd_data_out);
                        noc1_in_void <= remote_ahbs_snd_empty;
                        remote_ahbs_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_remote_ahbs_snd;
                      end if;
                    --COHERENCE REQ (originally on NoC 1)
                    elsif coherence_req_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= coherence_req_data_out;
                        noc1_in_void <= coherence_req_empty;
                        coherence_req_rdreq <= '1';
                        to_noc1_fifos_next <= packet_coherence_req;
                      end if;
                    --COHERENCE RSP SND (originally on NoC 3)
                    elsif coherence_rsp_snd_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= coherence_rsp_snd_data_out;
                        noc1_in_void <= coherence_rsp_snd_empty;
                        coherence_rsp_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_coherence_rsp_snd;
                      end if;
                    --DMA SND (originally on NoC 6)
                    elsif dma_snd_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= dma_snd_data_out;
                        noc1_in_void <= dma_snd_empty;
                        dma_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_dma_snd;
                      end if;
                    --COHERENCE FWD SND (originally on NoC 2)
                    elsif coherence_fwd_snd_empty = '0' then
                      if noc1_in_stop = '0' then
                        noc1_in_data <= coherence_fwd_snd_data_out;
                        noc1_in_void <= coherence_fwd_snd_empty;
                        coherence_fwd_snd_rdreq <= '1';
                        to_noc1_fifos_next <= packet_coherence_fwd_snd;
                      end if;
                    end if;
      --REMOTE APB SND (originally on NoC 5)
      when packet_remote_apb_snd => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_apb_snd_data_out);
                             if (noc1_in_stop = '0' and remote_apb_snd_empty = '0') then
                               noc1_in_data <= narrow_to_large_flit(remote_apb_snd_data_out);
                               noc1_in_void <= remote_apb_snd_empty;
                               remote_apb_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --LOCAL REMOTE APB SND (originally on NoC 5)
      when packet_local_remote_apb_snd => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_apb_snd_data_out);
                             if (local_remote_apb_snd_full = '0' and remote_apb_snd_empty = '0') then
                               local_remote_apb_snd_wrreq <= '1';
                               remote_apb_snd_rdreq <= '1';
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --REMOTE IRQ (originally on NoC 5)
      when packet_irq_ack  => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_irq_ack_data_out);
                              if (noc1_in_stop = '0' and remote_irq_ack_empty = '0') then
                                noc1_in_data <= narrow_to_large_flit(remote_irq_ack_data_out);
                                noc1_in_void <= remote_irq_ack_empty;
                                remote_irq_ack_rdreq <= not noc1_in_stop;
                                if to_noc1_preamble = PREAMBLE_TAIL then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      --APB SND (originally on NoC 5)
      when packet_apb_snd  => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
                             if (noc1_in_stop = '0' and apb_snd_empty = '0') then
                               noc1_in_data <= narrow_to_large_flit(apb_snd_data_out);
                               noc1_in_void <= apb_snd_empty;
                               apb_snd_rdreq <= not noc1_in_stop;
                               if (to_noc1_preamble = PREAMBLE_TAIL) then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --LOCAL APB SND (originally on NoC 5)
      when packet_local_apb_snd => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
                             if (local_apb_snd_full = '0' and apb_snd_empty = '0') then
                               local_apb_snd_wrreq <= '1';
                               apb_snd_rdreq <= '1';
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --REMOTE AHBS SND (originally on NoC 5)
      when packet_remote_ahbs_snd  => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_ahbs_snd_data_out);
                              if (noc1_in_stop = '0' and remote_ahbs_snd_empty = '0') then
                                noc1_in_data <= narrow_to_large_flit(remote_ahbs_snd_data_out);
                                noc1_in_void <= remote_ahbs_snd_empty;
                                remote_ahbs_snd_rdreq <= not noc1_in_stop;
                                if (to_noc1_preamble = PREAMBLE_TAIL) then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      --COHERENCE REQ (originally on NoC 1)
      when packet_coherence_req => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_req_data_out);
                              if (noc1_in_stop = '0' and coherence_req_empty = '0') then
                                noc1_in_data <= coherence_req_data_out;
                                noc1_in_void <= coherence_req_empty or noc1_in_stop;
                                coherence_req_rdreq <= (not coherence_req_empty) and (not noc1_in_stop);
                                if to_noc1_preamble = PREAMBLE_TAIL then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      --COHERENCE RSP SND (originally on NoC 3)
      when packet_coherence_rsp_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_rsp_snd_data_out);
                              if (noc1_in_stop = '0' and coherence_rsp_snd_empty = '0') then
                                noc1_in_data <= coherence_rsp_snd_data_out;
                                noc1_in_void <= coherence_rsp_snd_empty or noc1_in_stop;
                                coherence_rsp_snd_rdreq <= (not coherence_rsp_snd_empty) and (not noc1_in_stop);
                                if to_noc1_preamble = PREAMBLE_TAIL then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      --DMA SND (originally on NoC 6)
      when packet_dma_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, dma_snd_data_out);
                              if (noc1_in_stop = '0' and dma_snd_empty = '0') then
                                noc1_in_data <= dma_snd_data_out;
                                noc1_in_void <= dma_snd_empty or noc1_in_stop;
                                dma_snd_rdreq <= (not dma_snd_empty) and (not noc1_in_stop);
                                if to_noc1_preamble = PREAMBLE_TAIL then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      --COHERENCE FWD SND (originally on NoC 2)
      when packet_coherence_fwd_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_fwd_snd_data_out);
                              if (noc1_in_stop = '0' and coherence_fwd_snd_empty = '0') then
                                noc1_in_data <= coherence_fwd_snd_data_out;
                                noc1_in_void <= coherence_fwd_snd_empty or noc1_in_stop;
                                coherence_fwd_snd_rdreq <= (not coherence_fwd_snd_empty) and (not noc1_in_stop);
                                if to_noc1_preamble = PREAMBLE_TAIL then
                                  to_noc1_fifos_next <= none;
                                end if;
                              end if;
      when others => to_noc1_fifos_next <= none;
    end case;
  end process to_noc1_select_packet;

  fifo_10: fifo0
    generic map (
      depth => 3,                       --Header, address, data (1 word)
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_apb_snd_rdreq,
      wrreq    => remote_apb_snd_wrreq,
      data_in  => remote_apb_snd_data_in,
      empty    => remote_apb_snd_empty,
      full     => remote_apb_snd_full,
      data_out => remote_apb_snd_data_out);

  fifo_12: fifo0
    generic map (
      depth => 2,                       --Header, irq info
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_irq_ack_rdreq,
      wrreq    => remote_irq_ack_wrreq,
      data_in  => remote_irq_ack_data_in,
      empty    => remote_irq_ack_empty,
      full     => remote_irq_ack_full,
      data_out => remote_irq_ack_data_out);

  fifo_17: fifo0
    generic map (
      depth => 6,                       --Header, address, data (up to 4 words)
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => apb_snd_rdreq,
      wrreq    => apb_snd_wrreq,
      data_in  => apb_snd_data_in,
      empty    => apb_snd_empty,
      full     => apb_snd_full,
      data_out => apb_snd_data_out);

  local_remote_apb_snd_data_in <= remote_apb_snd_data_out;
  fifo_18: fifo0
    generic map (
      depth => 6,                       --Header, address, data (1 word) (2x)
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => local_remote_apb_rcv_rdreq,
      wrreq    => local_remote_apb_snd_wrreq,
      data_in  => local_remote_apb_snd_data_in,
      empty    => local_remote_apb_rcv_empty,
      full     => local_remote_apb_snd_full,
      data_out => local_remote_apb_rcv_data_out);

  local_apb_snd_data_in <= apb_snd_data_out;
  fifo_19: fifo0
    generic map (
      depth => 6,                       --Header, data (1 word) (2x)
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => local_apb_rcv_rdreq,
      wrreq    => local_apb_snd_wrreq,
      data_in  => local_apb_snd_data_in,
      empty    => local_apb_rcv_empty,
      full     => local_apb_snd_full,
      data_out => local_apb_rcv_data_out);

  fifo_21: fifo0
    generic map (
      depth => 32, --3,                       --Header, address, data
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => remote_ahbs_snd_rdreq,
      wrreq    => remote_ahbs_snd_wrreq,
      data_in  => remote_ahbs_snd_data_in,
      empty    => remote_ahbs_snd_empty,
      full     => remote_ahbs_snd_full,
      data_out => remote_ahbs_snd_data_out);

  -- noc4 does not interact with CPU tiles
  -- From noc4: DMA response to accelerators
  --noc4_in_data <= (others => '0');
  --noc4_in_void <= '1';
  --noc4_dummy_in_stop <= noc4_in_stop;
  --noc4_out_stop   <= dma_rcv_full and (not noc4_out_void);
  --dma_rcv_data_in <= noc4_out_data;
  --dma_rcv_wrreq   <= (not noc4_out_void) and (not dma_rcv_full);
  fifo_14: fifo0
    generic map (
      depth => 6,                      -- same as coherence req for the CPU
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => dma_rcv_rdreq,
      wrreq    => dma_rcv_wrreq,
      data_in  => dma_rcv_data_in,
      empty    => dma_rcv_empty,
      full     => dma_rcv_full,
      data_out => dma_rcv_data_out);

  -- noc6 does not interact with CPU tiles
  --noc6_dummy_out_data <= noc6_out_data;
  --noc6_dummy_out_void <= noc6_out_void;
  --noc6_out_stop <= '0';
  --noc6_in_data <= dma_snd_data_out;
  --noc6_in_void <= dma_snd_empty or noc6_in_stop;
  --dma_snd_rdreq <= (not dma_snd_empty) and (not noc6_in_stop);
  fifo_13: fifo0
    generic map (
      depth => 5,                       -- same as coherence rsp for the CPU
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => dma_snd_rdreq,
      wrreq    => dma_snd_wrreq,
      data_in  => dma_snd_data_in,
      empty    => dma_snd_empty,
      full     => dma_snd_full,
      data_out => dma_snd_data_out);

end rtl;
