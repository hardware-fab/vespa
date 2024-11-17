------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    acc_tile_q.vhd
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

use work.esp_global.all;

entity acc_tile_q is
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
    -- NoC5->tile
    apb_rcv_rdreq              : in  std_ulogic;
    apb_rcv_data_out           : out misc_noc_flit_type;
    apb_rcv_empty              : out std_ulogic;
    -- tile->NoC5
    apb_snd_wrreq              : in  std_ulogic;
    apb_snd_data_in            : in  misc_noc_flit_type;
    apb_snd_full               : out std_ulogic;
    -- tile->NoC5
    interrupt_wrreq            : in  std_ulogic;
    interrupt_data_in          : in  misc_noc_flit_type;
    interrupt_full             : out std_ulogic;
    -- NoC5->tile
    interrupt_ack_rdreq        : in  std_ulogic;
    interrupt_ack_data_out     : out misc_noc_flit_type;
    interrupt_ack_empty        : out std_ulogic;
    -- collapsed NoC
    noc_out_data              : in  noc_flit_vector;
    noc_out_void              : in  std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_out_stop              : out std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_in_data               : out noc_flit_vector;
    noc_in_void               : out std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_in_stop               : in  std_ulogic_vector(num_noc_planes-1 downto 0));

end acc_tile_q;

architecture rtl of acc_tile_q is

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
  -- NoC5->tile
  signal apb_rcv_wrreq                : std_ulogic;
  signal apb_rcv_data_in              : misc_noc_flit_type;
  signal apb_rcv_full                 : std_ulogic;
  -- tile->NoC5
  signal apb_snd_rdreq                : std_ulogic;
  signal apb_snd_data_out             : misc_noc_flit_type;
  signal apb_snd_empty                : std_ulogic;
  -- tile->Noc5
  signal interrupt_rdreq                    : std_ulogic;
  signal interrupt_data_out                 : misc_noc_flit_type;
  signal interrupt_empty                    : std_ulogic;
  -- NoC5->tile
  signal interrupt_ack_wrreq                : std_ulogic;
  signal interrupt_ack_data_in              : misc_noc_flit_type;
  signal interrupt_ack_full                 : std_ulogic;

  type noc2_packet_fsm is (none, packet_inv);
  signal noc2_fifos_current, noc2_fifos_next : noc2_packet_fsm;
  type noc3_packet_fsm is (none, packet_line);
  signal noc3_fifos_current, noc3_fifos_next : noc3_packet_fsm;
  type to_noc3_packet_fsm is (none, packet_coherence_rsp_snd);
  signal to_noc3_fifos_current, to_noc3_fifos_next : to_noc3_packet_fsm;
  type noc5_packet_fsm is (none, packet_apb_rcv);
  signal noc5_fifos_current, noc5_fifos_next : noc5_packet_fsm;
  type to_noc5_packet_fsm is (none, packet_apb_snd);
  signal to_noc5_fifos_current, to_noc5_fifos_next : to_noc5_packet_fsm;

  signal noc3_msg_type : noc_msg_type;
  signal noc3_preamble : noc_preamble_type;
  signal noc5_msg_type : noc_msg_type;
  signal noc5_preamble : noc_preamble_type;

  signal noc1_dummy_out_data  : noc_flit_type;
  signal noc1_dummy_out_void  : std_ulogic;
    
  -- Cachable data plane 1 -> request messages
  signal noc1_out_data :   noc_flit_type;
  signal noc1_out_void :   std_ulogic;
  signal noc1_out_stop :  std_ulogic;
  signal noc1_in_data  :  noc_flit_type;
  signal noc1_in_void  :  std_ulogic;
  signal noc1_in_stop  :   std_ulogic;
  -- Cachable data plane 2 -> forwarded messages
  signal noc2_out_data :   noc_flit_type;
  signal noc2_out_void :   std_ulogic;
  signal noc2_out_stop :  std_ulogic;
  signal noc2_in_data  :  noc_flit_type;
  signal noc2_in_void  :  std_ulogic;
  signal noc2_in_stop  :   std_ulogic;
  -- Cachable data plane 3 -> response messages
  signal noc3_out_data :   noc_flit_type;
  signal noc3_out_void :   std_ulogic;
  signal noc3_out_stop :  std_ulogic;
  signal noc3_in_data  :  noc_flit_type;
  signal noc3_in_void  :  std_ulogic;
  signal noc3_in_stop  :   std_ulogic;
  -- Non cachable data data plane 4 -> DMA transfers response
  signal noc4_out_data :   noc_flit_type;
  signal noc4_out_void :   std_ulogic;
  signal noc4_out_stop :  std_ulogic;
  signal noc4_in_data  :  noc_flit_type;
  signal noc4_in_void  :  std_ulogic;
  signal noc4_in_stop  :   std_ulogic;
  -- Configuration plane 5 -> RD/WR registers
  signal noc5_out_data :   noc_flit_type;
  signal noc5_out_void :   std_ulogic;
  signal noc5_out_stop :  std_ulogic;
  signal noc5_in_data  :  noc_flit_type;
  signal noc5_in_void  :  std_ulogic;
  signal noc5_in_stop  :   std_ulogic;
  -- Non cachable data data plane 6 -> DMA transfers requests
  signal noc6_out_data :   noc_flit_type;
  signal noc6_out_void :   std_ulogic;
  signal noc6_out_stop :  std_ulogic;
  signal noc6_in_data  :  noc_flit_type;
  signal noc6_in_void  :  std_ulogic;
  signal noc6_in_stop  :   std_ulogic;

begin  -- rtl

  fifo_rst <= rst;                  --FIFO rst active low

  -- To noc1: coherence requests from CPU to directory (GET/PUT)
  noc1_out_stop <= '0';
  noc1_dummy_out_data <= noc1_out_data;
  noc1_dummy_out_void <= noc1_out_void;
  noc1_in_data          <= coherence_req_data_out;
  noc1_in_void          <= coherence_req_empty or noc1_in_stop;
  coherence_req_rdreq   <= (not coherence_req_empty) and (not noc1_in_stop);
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
  noc2_out_stop <= coherence_fwd_full and (not noc2_out_void);
  coherence_fwd_data_in <= noc2_out_data;
  coherence_fwd_wrreq <= (not noc2_out_void) and (not coherence_fwd_full);

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
  noc3_out_stop <= coherence_rsp_rcv_full and (not noc3_out_void);
  coherence_rsp_rcv_data_in <= noc3_out_data;
  coherence_rsp_rcv_wrreq <= (not noc3_out_void) and (not coherence_rsp_rcv_full);

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
  noc3_in_data          <= coherence_rsp_snd_data_out;
  noc3_in_void          <= coherence_rsp_snd_empty or noc3_in_stop;
  coherence_rsp_snd_rdreq   <= (not coherence_rsp_snd_empty) and (not noc3_in_stop);
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
  noc2_in_data          <= coherence_fwd_snd_data_out;
  noc2_in_void          <= coherence_fwd_snd_empty or noc2_in_stop;
  coherence_fwd_snd_rdreq   <= (not coherence_fwd_snd_empty) and (not noc2_in_stop);
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
  noc4_out_stop   <= dma_rcv_full and (not noc4_out_void);
  dma_rcv_data_in <= noc4_out_data;
  dma_rcv_wrreq   <= (not noc4_out_void) and (not dma_rcv_full);
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
  noc6_out_stop   <= coherent_dma_rcv_full and (not noc6_out_void);
  coherent_dma_rcv_data_in <= noc6_out_data;
  coherent_dma_rcv_wrreq   <= (not noc6_out_void) and (not coherent_dma_rcv_full);
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
  noc6_in_data <= dma_snd_data_out;
  noc6_in_void <= dma_snd_empty or noc6_in_stop;
  dma_snd_rdreq <= (not dma_snd_empty) and (not noc6_in_stop);
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
  noc4_in_data <= coherent_dma_snd_data_out;
  noc4_in_void <= coherent_dma_snd_empty or noc4_in_stop;
  coherent_dma_snd_rdreq <= (not coherent_dma_snd_empty) and (not noc4_in_stop);
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

  -- From noc5: APB requests from cores
  noc5_msg_type <= get_msg_type(NOC_FLIT_SIZE, noc5_out_data);
  noc5_preamble <= get_preamble(NOC_FLIT_SIZE, noc5_out_data);
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      noc5_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge 
      noc5_fifos_current <= noc5_fifos_next;
    end if;
  end process;
  noc5_fifos_get_packet : process (noc5_out_data, noc5_out_void, noc5_msg_type,
                                   noc5_preamble, noc5_fifos_current,
                                   apb_rcv_full,
                                   interrupt_ack_full)
  begin  -- process noc5_get_packet
    apb_rcv_wrreq       <= '0';
    interrupt_ack_wrreq <= '0';

    noc5_fifos_next <= noc5_fifos_current;
    noc5_out_stop   <= '0';

    case noc5_fifos_current is
      when none =>
        if noc5_out_void = '0' then
          if ((noc5_msg_type = REQ_REG_RD or noc5_msg_type = REQ_REG_WR)
              and noc5_preamble = PREAMBLE_HEADER) then
            if apb_rcv_full = '0' then
              apb_rcv_wrreq   <= '1';
              noc5_fifos_next <= packet_apb_rcv;
            else
              noc5_out_stop <= '1';
            end if;
          elsif (noc5_msg_type = INTERRUPT and noc5_preamble = PREAMBLE_1FLIT) then
            interrupt_ack_wrreq <= not interrupt_ack_full;
            noc5_out_stop <= interrupt_ack_full;
          end if;
        end if;

      when packet_apb_rcv =>
        apb_rcv_wrreq <= not noc5_out_void and (not apb_rcv_full);
        noc5_out_stop <= apb_rcv_full and (not noc5_out_void);
        if (noc5_preamble = PREAMBLE_TAIL and noc5_out_void = '0' and
            apb_rcv_full = '0') then
          noc5_fifos_next <= none;
        end if;

      when others =>
        noc5_fifos_next <= none;

    end case;
  end process noc5_fifos_get_packet;

  apb_rcv_data_in <= large_to_narrow_flit(noc5_out_data);
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

  interrupt_ack_data_in <= large_to_narrow_flit(noc5_out_data);
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

  -- To noc5: APB response from accelerators
  -- To noc5: interrupts from accelerators
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      to_noc5_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge
      to_noc5_fifos_current <= to_noc5_fifos_next;
    end if;
  end process;
  noc5_fifos_put_packet: process (noc5_in_stop, to_noc5_fifos_current,
                                  apb_snd_data_out, apb_snd_empty,
                                  interrupt_data_out, interrupt_empty)
    variable to_noc5_preamble : noc_preamble_type;
  begin  -- process noc5_get_packet
    noc5_in_data <= (others => '0');
    noc5_in_void <= '1';
    apb_snd_rdreq <= '0';
    interrupt_rdreq <= '0';
    to_noc5_fifos_next <= to_noc5_fifos_current;
    to_noc5_preamble := "00";

    case to_noc5_fifos_current is
      when none => if apb_snd_empty = '0' then
                     if noc5_in_stop = '0' then
                       noc5_in_data <= narrow_to_large_flit(apb_snd_data_out);
                       noc5_in_void <= apb_snd_empty;
                       apb_snd_rdreq <= '1';
                       to_noc5_fifos_next <= packet_apb_snd;
                     end if;
                   elsif interrupt_empty = '0' then
                     if noc5_in_stop = '0' then
                       noc5_in_data <= narrow_to_large_flit(interrupt_data_out);
                       noc5_in_void <= interrupt_empty;
                       interrupt_rdreq <= '1';
                     end if;
                   end if;

      when packet_apb_snd => to_noc5_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
                             if (noc5_in_stop = '0' and apb_snd_empty = '0') then
                               noc5_in_data <= narrow_to_large_flit(apb_snd_data_out);
                               noc5_in_void <= apb_snd_empty;
                               apb_snd_rdreq <= not noc5_in_stop;
                               if to_noc5_preamble = PREAMBLE_TAIL then
                                 to_noc5_fifos_next <= none;
                               end if;
                             end if;

      when others => to_noc5_fifos_next <= none;
    end case;
  end process noc5_fifos_put_packet;

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

  -- Cachable data plane 1 -> request messages
  noc1_out_data <= noc_out_data(0);
  noc1_out_void <= noc_out_void(0);
  noc_out_stop(0) <= noc1_out_stop;
  noc_in_data(0)  <= noc1_in_data ;
  noc_in_void(0)  <= noc1_in_void ;
  noc1_in_stop  <= noc_in_stop(0);
  -- Cachable data plane 2 -> forwarded messages
  noc2_out_data <= noc_out_data(1);
  noc2_out_void <= noc_out_void(1);
  noc_out_stop(1) <= noc2_out_stop;
  noc_in_data(1)  <= noc2_in_data ;
  noc_in_void(1)  <= noc2_in_void ;
  noc2_in_stop  <= noc_in_stop(1);
  -- Cachable data plane 3 -> response messages
  noc3_out_data <= noc_out_data(2);
  noc3_out_void <= noc_out_void(2);
  noc_out_stop(2) <= noc3_out_stop;
  noc_in_data(2)  <= noc3_in_data ;
  noc_in_void(2)  <= noc3_in_void ;
  noc3_in_stop  <= noc_in_stop(2);
  -- Non cachable data data plane 4 -> DMA transfers response
  noc4_out_data <= noc_out_data(3);
  noc4_out_void <= noc_out_void(3);
  noc_out_stop(3) <= noc4_out_stop;
  noc_in_data(3)  <= noc4_in_data ;
  noc_in_void(3)  <= noc4_in_void ;
  noc4_in_stop  <= noc_in_stop(3);
  -- Configuration plane 5 -> RD/WR registers
  noc5_out_data <= noc_out_data(4);
  noc5_out_void <= noc_out_void(4);
  noc_out_stop(4) <= noc5_out_stop;
  noc_in_data(4)  <= noc5_in_data ;
  noc_in_void(4)  <= noc5_in_void ;
  noc5_in_stop  <= noc_in_stop(4);
  -- Non cachable data data plane 6 -> DMA transfers requests
  noc6_out_data <= noc_out_data(5);
  noc6_out_void <= noc_out_void(5);
  noc_out_stop(5) <= noc6_out_stop;
  noc_in_data(5)  <= noc6_in_data ;
  noc_in_void(5)  <= noc6_in_void ;
  noc6_in_stop  <= noc_in_stop(5);
end rtl;
