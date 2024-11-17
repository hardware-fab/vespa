------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    acc_tile_q_1plane.vhd
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

entity acc_tile_q_1plane is
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
    -- NoC4->tile
    dma_rcv_rdreq              : in  std_ulogic;
    dma_rcv_data_out           : out noc_flit_type;
    dma_rcv_empty              : out std_ulogic;
    -- tile->NoC4
    coherent_dma_snd_wrreq     : in  std_ulogic;
    coherent_dma_snd_data_in   : in  noc_flit_type;
    coherent_dma_snd_full      : out std_ulogic;
    -- tile->NoC6
    dma_snd_wrreq              : in  std_ulogic;
    dma_snd_data_in            : in  noc_flit_type;
    dma_snd_full               : out std_ulogic;
    -- NoC6->tile
    coherent_dma_rcv_rdreq     : in  std_ulogic;
    coherent_dma_rcv_data_out  : out noc_flit_type;
    coherent_dma_rcv_empty     : out std_ulogic;
    -- noc1->tile
    apb_rcv_rdreq              : in  std_ulogic;
    apb_rcv_data_out           : out misc_noc_flit_type;
    apb_rcv_empty              : out std_ulogic;
    -- tile->noc1
    apb_snd_wrreq              : in  std_ulogic;
    apb_snd_data_in            : in  misc_noc_flit_type;
    apb_snd_full               : out std_ulogic;
    -- tile->noc1
    interrupt_wrreq            : in  std_ulogic;
    interrupt_data_in          : in  misc_noc_flit_type;
    interrupt_full             : out std_ulogic;
    -- noc1->tile
    interrupt_ack_rdreq        : in  std_ulogic;
    interrupt_ack_data_out     : out misc_noc_flit_type;
    interrupt_ack_empty        : out std_ulogic;

    -- Cachable data plane 1 -> request messages
    noc1_out_data : in  noc_flit_type;
    noc1_out_void : in  std_ulogic;
    noc1_out_stop : out std_ulogic;
    noc1_in_data  : out noc_flit_type;
    noc1_in_void  : out std_ulogic;
    noc1_in_stop  : in  std_ulogic);

end acc_tile_q_1plane;

architecture rtl of acc_tile_q_1plane is

  signal fifo_rst : std_ulogic;

  -- tile->NoC1
  signal coherence_req_rdreq                 : std_ulogic;
  signal coherence_req_data_out              : noc_flit_type;
  signal coherence_req_empty                 : std_ulogic;
  -- NoC2->tile
  signal coherence_fwd_wrreq             : std_ulogic;
  signal coherence_fwd_data_in           : noc_flit_type;
  signal coherence_fwd_full              : std_ulogic;
  -- NoC3->tile
  signal coherence_rsp_rcv_wrreq            : std_ulogic;
  signal coherence_rsp_rcv_data_in          : noc_flit_type;
  signal coherence_rsp_rcv_full             : std_ulogic;
  -- tile->NoC3
  signal coherence_rsp_snd_rdreq     : std_ulogic;
  signal coherence_rsp_snd_data_out  : noc_flit_type;
  signal coherence_rsp_snd_empty     : std_ulogic;
  -- tile->NoC2
  signal coherence_fwd_snd_rdreq    : std_ulogic;
  signal coherence_fwd_snd_data_out : noc_flit_type;
  signal coherence_fwd_snd_empty    : std_ulogic;
  -- NoC4->tile
  signal dma_rcv_wrreq                       : std_ulogic;
  signal dma_rcv_data_in                     : noc_flit_type;
  signal dma_rcv_full                        : std_ulogic;
  -- tile->NoC4
  signal coherent_dma_snd_rdreq              : std_ulogic;
  signal coherent_dma_snd_data_out           : noc_flit_type;
  signal coherent_dma_snd_empty              : std_ulogic;
  -- tile->NoC6
  signal dma_snd_rdreq                       : std_ulogic;
  signal dma_snd_data_out                    : noc_flit_type;
  signal dma_snd_empty                       : std_ulogic;
  -- NoC6->tile
  signal coherent_dma_rcv_wrreq              : std_ulogic;
  signal coherent_dma_rcv_data_in            : noc_flit_type;
  signal coherent_dma_rcv_full               : std_ulogic;
  -- noc1->tile
  signal apb_rcv_wrreq                : std_ulogic;
  signal apb_rcv_data_in              : misc_noc_flit_type;
  signal apb_rcv_full                 : std_ulogic;
  -- tile->noc1
  signal apb_snd_rdreq                : std_ulogic;
  signal apb_snd_data_out             : misc_noc_flit_type;
  signal apb_snd_empty                : std_ulogic;
  -- tile->noc1
  signal interrupt_rdreq                    : std_ulogic;
  signal interrupt_data_out                 : misc_noc_flit_type;
  signal interrupt_empty                    : std_ulogic;
  -- noc1->tile
  signal interrupt_ack_wrreq                : std_ulogic;
  signal interrupt_ack_data_in              : misc_noc_flit_type;
  signal interrupt_ack_full                 : std_ulogic;

  type noc1_packet_fsm is (none, packet_apb_rcv, packet_coherence_rsp_rcv, packet_dma_rcv, packet_coherent_dma_rcv, packet_coherence_fwd);
  signal noc1_fifos_current, noc1_fifos_next : noc1_packet_fsm;
  type to_noc1_packet_fsm is (none, packet_apb_snd, packet_coherence_req, packet_coherence_rsp_snd, packet_coherent_dma_snd, packet_dma_snd, packet_coherence_fwd_snd);
  signal to_noc1_fifos_current, to_noc1_fifos_next : to_noc1_packet_fsm;

  signal noc1_msg_type : noc_msg_type;
  signal noc1_preamble : noc_preamble_type;

  -- attribute mark_debug : string;

  -- attribute mark_debug of interrupt_ack_wrreq : signal is "true";
  -- attribute mark_debug of interrupt_ack_data_in : signal is "true";
  -- attribute mark_debug of interrupt_ack_full : signal is "true";
  -- attribute mark_debug of interrupt_rdreq : signal is "true";
  -- attribute mark_debug of interrupt_data_out : signal is "true";
  -- attribute mark_debug of interrupt_empty : signal is "true";
  -- attribute mark_debug of noc1_msg_type : signal is "true";
  -- attribute mark_debug of noc1_preamble : signal is "true";
  -- attribute mark_debug of noc1_fifos_current : signal is "true";
  -- attribute mark_debug of noc1_fifos_next : signal is "true";
  -- attribute mark_debug of to_noc1_fifos_current : signal is "true";
  -- attribute mark_debug of to_noc1_fifos_next : signal is "true";

begin  -- rtl

  fifo_rst <= rst;                  --FIFO rst active low

  -- To noc1: coherence requests from CPU to directory (GET/PUT)
  --noc1_in_data          <= coherence_req_data_out;
  --noc1_in_void          <= coherence_req_empty or noc1_in_stop;
  --coherence_req_rdreq   <= (not coherence_req_empty) and (not noc1_in_stop);
  fifo_1: fifo0
    generic map (
      depth =>  6,                       --Header, address, [cache line]
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
      depth =>  4,                       --Header, address (x2)
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
      depth =>  5,                       --Header (use RESERVED field to
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
      depth =>  5,                       --Header
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
      depth =>  5,                       --Header
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



  -- From noc4: DMA response to accelerators
  --noc4_out_stop   <= dma_rcv_full and (not noc4_out_void);
  --dma_rcv_data_in <= noc4_out_data;
  --dma_rcv_wrreq   <= (not noc4_out_void) and (not dma_rcv_full);
  fifo_14: fifo0
    generic map (
      depth =>  18,                      --Header, [data]
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

  -- From noc6: Coherent DMA response to accelerators
  --noc6_out_stop   <= coherent_dma_rcv_full and (not noc6_out_void);
  --coherent_dma_rcv_data_in <= noc6_out_data;
  --coherent_dma_rcv_wrreq   <= (not noc6_out_void) and (not coherent_dma_rcv_full);
  fifo_14c: fifo0
    generic map (
      depth =>  18,                      --Header, [data]
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherent_dma_rcv_rdreq,
      wrreq    => coherent_dma_rcv_wrreq,
      data_in  => coherent_dma_rcv_data_in,
      empty    => coherent_dma_rcv_empty,
      full     => coherent_dma_rcv_full,
      data_out => coherent_dma_rcv_data_out);

  -- To noc6: DMA requests from accelerators
  --noc6_in_data <= dma_snd_data_out;
  --noc6_in_void <= dma_snd_empty or noc6_in_stop;
  --dma_snd_rdreq <= (not dma_snd_empty) and (not noc6_in_stop);
  fifo_13: fifo0
    generic map (
      depth =>  18,                      --Header, address, length or data
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

  -- To noc4: Coherent DMA requests from accelerators
  --noc4_in_data <= coherent_dma_snd_data_out;
  --noc4_in_void <= coherent_dma_snd_empty or noc4_in_stop;
  --coherent_dma_snd_rdreq <= (not coherent_dma_snd_empty) and (not noc4_in_stop);
  fifo_13c: fifo0
    generic map (
      depth =>  18,                      --Header, address, length or data
      width => NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => coherent_dma_snd_rdreq,
      wrreq    => coherent_dma_snd_wrreq,
      data_in  => coherent_dma_snd_data_in,
      empty    => coherent_dma_snd_empty,
      full     => coherent_dma_snd_full,
      data_out => coherent_dma_snd_data_out);

  -- From noc1: APB requests from cores
  noc1_msg_type <= get_msg_type(NOC_FLIT_SIZE, noc1_out_data);
  noc1_preamble <= get_preamble(NOC_FLIT_SIZE, noc1_out_data);
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      noc1_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge
      noc1_fifos_current <= noc1_fifos_next;
    end if;
  end process;
  noc1_fifos_get_packet : process (noc1_out_data, noc1_out_void, noc1_msg_type,
                                   noc1_preamble, noc1_fifos_current,
                                   apb_rcv_full,
                                   interrupt_ack_full,
                                   coherence_rsp_rcv_full,
                                   dma_rcv_full,
                                   coherent_dma_rcv_full,
                                   coherence_fwd_full)
  begin  -- process noc1_get_packet
    apb_rcv_wrreq       <= '0';
    interrupt_ack_wrreq <= '0';
    coherence_rsp_rcv_wrreq <= '0';
    dma_rcv_wrreq <= '0';
    coherent_dma_rcv_wrreq <= '0';
    coherence_fwd_wrreq <= '0';

    dma_rcv_data_in <= noc1_out_data;
    coherent_dma_rcv_data_in <= noc1_out_data;
    coherence_fwd_data_in <= noc1_out_data;

    noc1_fifos_next <= noc1_fifos_current;
    noc1_out_stop   <= '0';

    case noc1_fifos_current is
      when none =>
        if noc1_out_void = '0' then
          --APB RCV (original: NoC 5)
          if ((noc1_msg_type = REQ_REG_RD or noc1_msg_type = REQ_REG_WR)
              and noc1_preamble = PREAMBLE_HEADER) then
            if apb_rcv_full = '0' then
              apb_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_apb_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --INTERRUPT ACK (original: NoC 5)
          elsif (noc1_msg_type = INTERRUPT and noc1_preamble = PREAMBLE_1FLIT) then
            interrupt_ack_wrreq <= not interrupt_ack_full;
            noc1_out_stop <= interrupt_ack_full;
          --COHERENCE RSP RCV (original: NoC 3)
          elsif ((noc1_msg_type = RSP_DATA or noc1_msg_type = RSP_EDATA or noc1_msg_type = RSP_INV_ACK)
                and noc1_preamble = PREAMBLE_HEADER) then
            if coherence_rsp_rcv_full = '0' then
              coherence_rsp_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_coherence_rsp_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --DMA RCV (original: NoC 4)
          elsif ((noc1_msg_type = DMA_FROM_DEV or noc1_msg_type = DMA_TO_DEV) and noc1_preamble = PREAMBLE_HEADER) then
            if dma_rcv_full = '0' then
              dma_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_dma_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --COHERENT DMA RCV (original: NoC 6)
          elsif ((noc1_msg_type = REQ_DMA_READ or noc1_msg_type = REQ_DMA_WRITE or noc1_msg_type = REQ_P2P or noc1_msg_type = RSP_P2P or noc1_msg_type = CPU_DMA) and noc1_preamble = PREAMBLE_HEADER) then
            if coherent_dma_rcv_full = '0' then
              coherent_dma_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_coherent_dma_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --COHERENCE FWD (original: NoC 2)
          elsif ((noc1_msg_type = FWD_GETS or noc1_msg_type = FWD_GETM or noc1_msg_type = FWD_INV or noc1_msg_type = FWD_PUT_ACK or noc1_msg_type = FWD_GETM_NOCOH or noc1_msg_type = FWD_INV_NOCOH) and noc1_preamble = PREAMBLE_HEADER) then
            if coherence_fwd_full = '0' then
              coherence_fwd_wrreq   <= '1';
              noc1_fifos_next <= packet_coherence_fwd;
            else
              noc1_out_stop <= '1';
            end if;
          end if;
        end if;
      --APB RCV (original: NoC 5)
      when packet_apb_rcv =>
        apb_rcv_wrreq <= not noc1_out_void and (not apb_rcv_full);
        noc1_out_stop <= apb_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            apb_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --COHERENCE RSP RCV (original: NoC 3)
      when packet_coherence_rsp_rcv =>
        coherence_rsp_rcv_wrreq <= not noc1_out_void and (not coherence_rsp_rcv_full);
        noc1_out_stop <= coherence_rsp_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            coherence_rsp_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
       --DMA RCV (original: NoC 4)
      when packet_dma_rcv =>
        dma_rcv_wrreq <= not noc1_out_void and (not dma_rcv_full);
        noc1_out_stop <= dma_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            dma_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --COHERENT DMA RCV (original: NoC 6)
      when packet_coherent_dma_rcv =>
        coherent_dma_rcv_wrreq <= not noc1_out_void and (not coherent_dma_rcv_full);
        noc1_out_stop <= coherent_dma_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            coherent_dma_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --COHERENCE FWD (original: NoC 2)
      when packet_coherence_fwd =>
        coherence_fwd_wrreq <= not noc1_out_void and (not coherence_fwd_full);
        noc1_out_stop <= coherence_fwd_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            coherence_fwd_full = '0') then
          noc1_fifos_next <= none;
        end if;
      when others =>
        noc1_fifos_next <= none;

    end case;
  end process noc1_fifos_get_packet;

  apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_10 : fifo0
    generic map (
      depth =>  3,                       --Header, address, data
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

  interrupt_ack_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_16 : fifo0
    generic map (
      depth =>  2,                       --Header x # accelerators
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => interrupt_ack_rdreq,
      wrreq    => interrupt_ack_wrreq,
      data_in  => interrupt_ack_data_in,
      empty    => interrupt_ack_empty,
      full     => interrupt_ack_full,
      data_out => interrupt_ack_data_out);

  -- To noc1: APB response from accelerators
  -- To noc1: interrupts from accelerators
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      to_noc1_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge
      to_noc1_fifos_current <= to_noc1_fifos_next;
    end if;
  end process;
  noc1_fifos_put_packet: process (noc1_in_stop, to_noc1_fifos_current,
                                  apb_snd_data_out, apb_snd_empty,
                                  interrupt_data_out, interrupt_empty,
                                  coherence_req_data_out, coherence_req_empty,
                                  coherence_rsp_snd_data_out, coherence_rsp_snd_empty,
                                  coherent_dma_snd_data_out, coherent_dma_snd_empty,
                                  dma_snd_data_out, dma_snd_empty,
                                  coherence_fwd_snd_data_out, coherence_fwd_snd_empty)
    variable to_noc1_preamble : noc_preamble_type;
  begin  -- process noc1_get_packet
    noc1_in_data <= (others => '0');
    noc1_in_void <= '1';

    apb_snd_rdreq <= '0';
    interrupt_rdreq <= '0';
    coherence_req_rdreq <= '0';
    coherence_rsp_snd_rdreq <= '0';
    coherent_dma_snd_rdreq <= '0';
    dma_snd_rdreq <= '0';
    coherence_fwd_snd_rdreq <= '0';

    to_noc1_fifos_next <= to_noc1_fifos_current;
    to_noc1_preamble := "00";

    case to_noc1_fifos_current is
      when none =>
                  --APB SND (originally on NoC 5)
                  if apb_snd_empty = '0' then
                     if noc1_in_stop = '0' then
                       noc1_in_data <= narrow_to_large_flit(apb_snd_data_out);
                       noc1_in_void <= apb_snd_empty;
                       apb_snd_rdreq <= '1';
                       to_noc1_fifos_next <= packet_apb_snd;
                     end if;
                   --INTERRUPT DATA (originally on NoC 5)
                   elsif interrupt_empty = '0' then
                     if noc1_in_stop = '0' then
                       noc1_in_data <= narrow_to_large_flit(interrupt_data_out);
                       noc1_in_void <= interrupt_empty;
                       interrupt_rdreq <= '1';
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
                   --COHERENT DMA SND (originally on NoC 4)
                   elsif coherent_dma_snd_empty = '0' then
                     if noc1_in_stop = '0' then
                       noc1_in_data <= coherent_dma_snd_data_out;
                       noc1_in_void <= coherent_dma_snd_empty;
                       coherent_dma_snd_rdreq <= '1';
                       to_noc1_fifos_next <= packet_coherent_dma_snd;
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
      --APB SND (originally on NoC 5)
      when packet_apb_snd => to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
                             if (noc1_in_stop = '0' and apb_snd_empty = '0') then
                               noc1_in_data <= narrow_to_large_flit(apb_snd_data_out);
                               noc1_in_void <= apb_snd_empty;
                               apb_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --COHERENCE REQ (originally on NoC 1)
      when packet_coherence_req => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_req_data_out);
                             if (noc1_in_stop = '0' and coherence_req_empty = '0') then
                               noc1_in_data <= coherence_req_data_out;
                               noc1_in_void <= coherence_req_empty;
                               coherence_req_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --COHERENCE RSP SND (originally on NoC 3)
      when packet_coherence_rsp_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_rsp_snd_data_out);
                             if (noc1_in_stop = '0' and coherence_rsp_snd_empty = '0') then
                               noc1_in_data <= coherence_rsp_snd_data_out;
                               noc1_in_void <= coherence_rsp_snd_empty;
                               coherence_rsp_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --COHERENCE DMA SND (originally on NoC 4)
      when packet_coherent_dma_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherent_dma_snd_data_out);
                             if (noc1_in_stop = '0' and coherent_dma_snd_empty = '0') then
                               noc1_in_data <= coherent_dma_snd_data_out;
                               noc1_in_void <= coherent_dma_snd_empty;
                               coherent_dma_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --DMA SND (originally on NoC 6)
      when packet_dma_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, dma_snd_data_out);
                             if (noc1_in_stop = '0' and dma_snd_empty = '0') then
                               noc1_in_data <= dma_snd_data_out;
                               noc1_in_void <= dma_snd_empty;
                               dma_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      --COHERENCE FWD SND (originally on NoC 2)
      when packet_coherence_fwd_snd => to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherence_fwd_snd_data_out);
                             if (noc1_in_stop = '0' and coherence_fwd_snd_empty = '0') then
                               noc1_in_data <= coherence_fwd_snd_data_out;
                               noc1_in_void <= coherence_fwd_snd_empty;
                               coherence_fwd_snd_rdreq <= not noc1_in_stop;
                               if to_noc1_preamble = PREAMBLE_TAIL then
                                 to_noc1_fifos_next <= none;
                               end if;
                             end if;
      when others => to_noc1_fifos_next <= none;
    end case;
  end process noc1_fifos_put_packet;

  fifo_7: fifo0
    generic map (
      depth =>  3,                       --Header, data (1 word)
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

  fifo_15: fifo0
    generic map (
      depth =>  2,                       --Header only x possible sharers
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => interrupt_rdreq,
      wrreq    => interrupt_wrreq,
      data_in  => interrupt_data_in,
      empty    => interrupt_empty,
      full     => interrupt_full,
      data_out => interrupt_data_out);




end rtl;
