------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    misc_tile_q_1plane.vhd
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

entity misc_tile_q_1plane is
  generic (
    tech : integer := virtex7);
  port (
    rst                             : in  std_ulogic;
    clk                             : in  std_ulogic;
    -- Requests from remote masters
    -- noc1->tile
    ahbs_rcv_rdreq                  : in  std_ulogic;
    ahbs_rcv_data_out               : out misc_noc_flit_type;
    ahbs_rcv_empty                  : out std_ulogic;
    -- tile->noc1
    ahbs_snd_wrreq                  : in  std_ulogic;
    ahbs_snd_data_in                : in  misc_noc_flit_type;
    ahbs_snd_full                   : out std_ulogic;
    -- Requests to remote slaves
    -- noc1->tile
    remote_ahbs_rcv_rdreq           : in  std_ulogic;
    remote_ahbs_rcv_data_out        : out misc_noc_flit_type;
    remote_ahbs_rcv_empty           : out std_ulogic;
    -- tile->noc1
    remote_ahbs_snd_wrreq           : in  std_ulogic;
    remote_ahbs_snd_data_in         : in  misc_noc_flit_type;
    remote_ahbs_snd_full            : out std_ulogic;
    -- non-coherent DMA requests from masters
    -- NoC6->tile
    dma_rcv_rdreq                   : in  std_ulogic;
    dma_rcv_data_out                : out noc_flit_type;
    dma_rcv_empty                   : out std_ulogic;
    -- tile->NoC4
    dma_snd_wrreq                   : in  std_ulogic;
    dma_snd_data_in                 : in  noc_flit_type;
    dma_snd_full                    : out std_ulogic;
    dma_snd_atleast_4slots          : out std_ulogic;
    dma_snd_exactly_3slots          : out std_ulogic;
    -- coherent DMA requests from Ethernet
    -- This enables Ethernet to be a peripheral to connect to the system
    -- not in debug mode. The EDCL interface works withough this.
    -- The coherent interface is required in SMP instances of ESP
    -- with caches, because Ethernet relies on DMA buffers in memory
    -- that must be coherent.
    -- NoC6->tile
    coherent_dma_rcv_rdreq          : in  std_ulogic;
    coherent_dma_rcv_data_out       : out noc_flit_type;
    coherent_dma_rcv_empty          : out std_ulogic;
    -- tile->NoC4
    coherent_dma_snd_wrreq          : in  std_ulogic;
    coherent_dma_snd_data_in        : in  noc_flit_type;
    coherent_dma_snd_full           : out std_ulogic;
    -- Requests from master
    -- noc1->tile
    apb_rcv_rdreq                   : in  std_ulogic;
    apb_rcv_data_out                : out misc_noc_flit_type;
    apb_rcv_empty                   : out std_ulogic;
    -- tile->noc1
    apb_snd_wrreq                   : in  std_ulogic;
    apb_snd_data_in                 : in  misc_noc_flit_type;
    apb_snd_full                    : out std_ulogic;
    -- Requests to remote slaves
    -- noc1->tile
    remote_apb_rcv_rdreq            : in  std_ulogic;
    remote_apb_rcv_data_out         : out misc_noc_flit_type;
    remote_apb_rcv_empty            : out std_ulogic;
    -- tile->noc1
    remote_apb_snd_wrreq            : in  std_ulogic;
    remote_apb_snd_data_in          : in  misc_noc_flit_type;
    remote_apb_snd_full             : out std_ulogic;
    -- local_queue -> tile
    local_apb_rcv_rdreq             : in std_ulogic;
    local_apb_rcv_data_out          : out misc_noc_flit_type;
    local_apb_rcv_empty             : out std_ulogic;
    -- tile->local queue
    local_remote_apb_snd_wrreq      : in  std_ulogic;
    local_remote_apb_snd_data_in    : in  misc_noc_flit_type;
    local_remote_apb_snd_full       : out std_ulogic;
    -- Interrupt level update
    -- noc1->tile
    irq_ack_rdreq                   : in  std_ulogic;
    irq_ack_data_out                : out misc_noc_flit_type;
    irq_ack_empty                   : out std_ulogic;
    -- tile->noc1
    irq_wrreq                       : in  std_ulogic;
    irq_data_in                     : in  misc_noc_flit_type;
    irq_full                        : out std_ulogic;
    -- Interrupts from remote devices
    -- noc1->tile
    interrupt_rdreq                 : in  std_ulogic;
    interrupt_data_out              : out misc_noc_flit_type;
    interrupt_empty                 : out std_ulogic;
    -- Interrupt acknowledge to accelerators with level-sensitive interrupts
    -- tile->noc1
    interrupt_ack_wrreq             : in  std_ulogic;
    interrupt_ack_data_in           : in misc_noc_flit_type;
    interrupt_ack_full              : out std_ulogic;
    -- Cachable data plane 1 -> request messages
    noc1_out_data                   : in  noc_flit_type;
    noc1_out_void                   : in  std_ulogic;
    noc1_out_stop                   : out std_ulogic;
    noc1_in_data                    : out noc_flit_type;
    noc1_in_void                    : out std_ulogic;
    noc1_in_stop                    : in  std_ulogic);

end misc_tile_q_1plane;

architecture rtl of misc_tile_q_1plane is

  signal fifo_rst : std_ulogic;

  -- noc1->tile
  signal ahbs_rcv_wrreq            : std_ulogic;
  signal ahbs_rcv_data_in          : misc_noc_flit_type;
  signal ahbs_rcv_full             : std_ulogic;
  -- tile->noc1
  signal ahbs_snd_rdreq            : std_ulogic;
  signal ahbs_snd_data_out         : misc_noc_flit_type;
  signal ahbs_snd_empty            : std_ulogic;
  -- noc1->tile
  signal remote_ahbs_rcv_wrreq     : std_ulogic;
  signal remote_ahbs_rcv_data_in   : misc_noc_flit_type;
  signal remote_ahbs_rcv_full      : std_ulogic;
  -- tile->noc1
  signal remote_ahbs_snd_rdreq     : std_ulogic;
  signal remote_ahbs_snd_data_out  : misc_noc_flit_type;
  signal remote_ahbs_snd_empty     : std_ulogic;
  -- NoC6->tile
  signal dma_rcv_wrreq             : std_ulogic;
  signal dma_rcv_data_in           : noc_flit_type;
  signal dma_rcv_full              : std_ulogic;
  -- tile->NoC4
  signal dma_snd_rdreq             : std_ulogic;
  signal dma_snd_data_out          : noc_flit_type;
  signal dma_snd_empty             : std_ulogic;
  -- NoC6->tile
  signal coherent_dma_rcv_wrreq    : std_ulogic;
  signal coherent_dma_rcv_data_in  : noc_flit_type;
  signal coherent_dma_rcv_full     : std_ulogic;
  -- tile->NoC4
  signal coherent_dma_snd_rdreq    : std_ulogic;
  signal coherent_dma_snd_data_out : noc_flit_type;
  signal coherent_dma_snd_empty    : std_ulogic;
  -- noc1->tile
  signal apb_rcv_wrreq             : std_ulogic;
  signal apb_rcv_data_in           : misc_noc_flit_type;
  signal apb_rcv_full              : std_ulogic;
  -- tile->noc1
  signal apb_snd_rdreq             : std_ulogic;
  signal apb_snd_data_out          : misc_noc_flit_type;
  signal apb_snd_empty             : std_ulogic;
  -- noc1->tile
  signal remote_apb_rcv_wrreq      : std_ulogic;
  signal remote_apb_rcv_data_in    : misc_noc_flit_type;
  signal remote_apb_rcv_full       : std_ulogic;
  -- tile->noc1
  signal remote_apb_snd_rdreq      : std_ulogic;
  signal remote_apb_snd_data_out   : misc_noc_flit_type;
  signal remote_apb_snd_empty      : std_ulogic;
  -- noc1->tile
  signal irq_ack_wrreq             : std_ulogic;
  signal irq_ack_data_in           : misc_noc_flit_type;
  signal irq_ack_full              : std_ulogic;
  -- tile->noc1
  signal irq_rdreq                 : std_ulogic;
  signal irq_data_out              : misc_noc_flit_type;
  signal irq_empty                 : std_ulogic;
  -- noc1->tile
  signal interrupt_wrreq           : std_ulogic;
  signal interrupt_data_in         : misc_noc_flit_type;
  signal interrupt_full            : std_ulogic;
  -- tile->noc1
  signal interrupt_ack_rdreq       : std_ulogic;
  signal interrupt_ack_data_out    : misc_noc_flit_type;
  signal interrupt_ack_empty       : std_ulogic;

  -- Partially decoupling local-remote transactions to prevent deadlock
  -- Local Master -> Local apb slave (request)
  signal local_remote_apb_rcv_rdreq    : std_ulogic;
  signal local_remote_apb_rcv_data_out : misc_noc_flit_type;
  signal local_remote_apb_rcv_empty    : std_ulogic;
  -- Local apb slave --> Local Master (response)
  signal local_apb_snd_wrreq           : std_ulogic;
  signal local_apb_snd_data_in         : misc_noc_flit_type;
  signal local_apb_snd_full            : std_ulogic;


  --type to_noc4_packet_fsm is (none,
  --                            packet_dma_snd,
  --                            packet_coherent_dma_snd);
  --signal to_noc4_fifos_current, to_noc4_fifos_next : to_noc4_packet_fsm;

  type noc1_packet_fsm is (none,
                           packet_local_remote_apb_rcv,
                           packet_apb_rcv,
                           packet_remote_apb_rcv,
                           packet_irq_ack,
                           packet_interrupt,
                           packet_ahbs_rcv,
                           packet_remote_ahbs_rcv,
                           packet_dma_rcv,
                           packet_coherent_dma_rcv);

  signal noc1_fifos_current, noc1_fifos_next : noc1_packet_fsm;

  type to_noc1_packet_fsm is (none,
                              packet_local_apb_snd,
                              packet_apb_snd,
                              packet_remote_apb_snd,
                              packet_ahbs_snd,
                              packet_remote_ahbs_snd,
                              packet_irq,
                              packet_dma_snd,
                              packet_coherent_dma_snd);
  signal to_noc1_fifos_current, to_noc1_fifos_next : to_noc1_packet_fsm;

  signal noc1_msg_type : noc_msg_type;
  signal noc1_preamble : noc_preamble_type;
  signal local_remote_apb_rcv_preamble : noc_preamble_type;

  --type noc6_packet_fsm is (none,
  --                         packet_dma_rcv,
  --                         packet_coherent_dma_rcv);
  --signal noc6_fifos_current, noc6_fifos_next : noc6_packet_fsm;
  --
  --signal noc6_msg_type : noc_msg_type;
  --signal noc6_preamble : noc_preamble_type;

  -- attribute mark_debug : string;

  -- attribute mark_debug of interrupt_wrreq : signal is "true";
  -- attribute mark_debug of interrupt_data_in : signal is "true";
  -- attribute mark_debug of interrupt_full : signal is "true";
  -- attribute mark_debug of interrupt_ack_rdreq : signal is "true";
  -- attribute mark_debug of interrupt_ack_data_out : signal is "true";
  -- attribute mark_debug of interrupt_ack_empty : signal is "true";
  -- attribute mark_debug of noc1_msg_type : signal is "true";
  -- attribute mark_debug of noc1_preamble : signal is "true";
  -- attribute mark_debug of noc1_fifos_current : signal is "true";
  -- attribute mark_debug of noc1_fifos_next : signal is "true";
  -- attribute mark_debug of to_noc1_fifos_current : signal is "true";
  -- attribute mark_debug of to_noc1_fifos_next : signal is "true";

begin  -- rtl

  fifo_rst <= rst;                      --FIFO rst active low

  -- From noc6: DMA requests from accelerators to frame buffer
  -- From noc6: coherent DMA responses from LLC to Ethernet
  --noc6_in_data       <= (others => '0');
  --noc6_in_void       <= '1';
  --noc6_dummy_in_stop <= noc6_in_stop;
  --
  --noc6_msg_type <= get_msg_type(NOC_FLIT_SIZE, noc6_out_data);
  --noc6_preamble <= get_preamble(NOC_FLIT_SIZE, noc6_out_data);
  --process (clk, rst)
  --begin  -- process
  --  if rst = '0' then                   -- asynchronous reset (active low)
  --    noc6_fifos_current <= none;
  --  elsif clk'event and clk = '1' then  -- rising clock edge
  --    noc6_fifos_current <= noc6_fifos_next;
  --  end if;
  --end process;
  --noc6_fifos_get_packet : process (noc6_out_data, noc6_out_void, noc6_msg_type,
  --                                 noc6_preamble, noc6_fifos_current,
  --                                 dma_rcv_full,
  --                                 coherent_dma_rcv_full)
  --begin  -- process noc1_get_packet
  --  dma_rcv_wrreq          <= '0';
  --  coherent_dma_rcv_wrreq <= '0';
  --
  --  noc6_fifos_next <= noc6_fifos_current;
  --  noc6_out_stop   <= '0';
  --
  --  case noc6_fifos_current is
  --    when none =>
  --      if noc6_out_void = '0' then
  --        if (noc6_msg_type = DMA_FROM_DEV and noc6_preamble = PREAMBLE_HEADER) then
  --          if dma_rcv_full = '0' then
  --            dma_rcv_wrreq   <= '1';
  --            noc6_fifos_next <= packet_dma_rcv;
  --          else
  --            noc6_out_stop <= '1';
  --          end if;
  --        elsif (noc6_msg_type = RSP_DATA_DMA and noc6_preamble = PREAMBLE_HEADER) then
  --          if coherent_dma_rcv_full = '0' then
  --            coherent_dma_rcv_wrreq <= '1';
  --            noc6_fifos_next        <= packet_coherent_dma_rcv;
  --          else
  --            noc6_out_stop <= '1';
  --          end if;
  --        end if;
  --      end if;
  --
  --    when packet_dma_rcv =>
  --      dma_rcv_wrreq <= not noc6_out_void and (not dma_rcv_full);
  --      noc6_out_stop <= dma_rcv_full and (not noc6_out_void);
  --      if (noc6_preamble = PREAMBLE_TAIL and noc6_out_void = '0' and
  --          dma_rcv_full = '0') then
  --        noc6_fifos_next <= none;
  --      end if;
  --
  --    when packet_coherent_dma_rcv =>
  --      coherent_dma_rcv_wrreq <= not noc6_out_void and (not coherent_dma_rcv_full);
  --      noc6_out_stop          <= coherent_dma_rcv_full and (not noc6_out_void);
  --      if (noc6_preamble = PREAMBLE_TAIL and noc6_out_void = '0' and
  --          coherent_dma_rcv_full = '0') then
  --        noc6_fifos_next <= none;
  --      end if;
  --
  --    when others =>
  --      noc6_fifos_next <= none;
  --  end case;
  --end process noc6_fifos_get_packet;

  --dma_rcv_data_in <= noc6_out_data;
  fifo_18 : fifo0
    generic map (
      depth => 18,                      --Header, address, [data]
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

  --coherent_dma_rcv_data_in <= noc6_out_data;
  fifo_25 : fifo0
    generic map (
      depth => 8,                       --Header, address, [data]
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

  -- To noc4: DMA response to accelerators
  -- To noc4: coherent DMA request to LLC from Ethernet (causes recalls)
  --noc4_out_stop       <= '0';
  --noc4_dummy_out_data <= noc4_out_data;
  --noc4_dummy_out_void <= noc4_out_void;
  --process (clk, rst)
  --begin  -- process
  --  if rst = '0' then                   -- asynchronous reset (active low)
  --    to_noc4_fifos_current <= none;
  --  elsif clk'event and clk = '1' then  -- rising clock edge
  --    to_noc4_fifos_current <= to_noc4_fifos_next;
  --  end if;
  --end process;
  --
  --to_noc4_select_packet : process (noc4_in_stop, to_noc4_fifos_current,
  --                                 dma_snd_data_out, dma_snd_empty,
  --                                 coherent_dma_snd_data_out, coherent_dma_snd_empty)
  --  variable to_noc4_preamble : noc_preamble_type;
  --begin  -- process to_noc4_select_packet
  --  noc4_in_data <= (others => '0');
  --  noc4_in_void <= '1';
  --
  --  dma_snd_rdreq          <= '0';
  --  coherent_dma_snd_rdreq <= '0';
  --
  --  to_noc4_fifos_next <= to_noc4_fifos_current;
  --  to_noc4_preamble   := "00";
  --
  --  case to_noc4_fifos_current is
  --    when none =>
  --      if dma_snd_empty = '0' then
  --        noc4_in_data <= dma_snd_data_out;
  --        noc4_in_void <= dma_snd_empty;
  --        if noc4_in_stop = '0' then
  --          dma_snd_rdreq      <= '1';
  --          to_noc4_fifos_next <= packet_dma_snd;
  --        end if;
  --      elsif coherent_dma_snd_empty = '0' then
  --        noc4_in_data <= coherent_dma_snd_data_out;
  --        noc4_in_void <= coherent_dma_snd_empty;
  --        if noc4_in_stop = '0' then
  --          coherent_dma_snd_rdreq <= '1';
  --          to_noc4_fifos_next     <= packet_coherent_dma_snd;
  --        end if;
  --      end if;
  --
  --    when packet_dma_snd =>
  --      to_noc4_preamble := get_preamble(NOC_FLIT_SIZE, dma_snd_data_out);
  --      if (noc4_in_stop = '0' and dma_snd_empty = '0') then
  --        noc4_in_data  <= dma_snd_data_out;
  --        noc4_in_void  <= dma_snd_empty;
  --        dma_snd_rdreq <= not noc4_in_stop;
  --        if to_noc4_preamble = PREAMBLE_TAIL then
  --          to_noc4_fifos_next <= none;
  --        end if;
  --      end if;
  --
  --    when packet_coherent_dma_snd =>
  --      to_noc4_preamble := get_preamble(NOC_FLIT_SIZE, coherent_dma_snd_data_out);
  --      if (noc4_in_stop = '0' and coherent_dma_snd_empty = '0') then
  --        noc4_in_data           <= coherent_dma_snd_data_out;
  --        noc4_in_void           <= coherent_dma_snd_empty;
  --        coherent_dma_snd_rdreq <= not noc4_in_stop;
  --        if to_noc4_preamble = PREAMBLE_TAIL then
  --          to_noc4_fifos_next <= none;
  --        end if;
  --      end if;
  --
  --    when others =>
  --      to_noc4_fifos_next <= none;
  --  end case;
  --end process to_noc4_select_packet;

  fifo_19 : fifo2
    generic map (
      depth => 18,                      --Header, address, [data]
      width => NOC_FLIT_SIZE)
    port map (
      clk            => clk,
      rst            => fifo_rst,
      rdreq          => dma_snd_rdreq,
      wrreq          => dma_snd_wrreq,
      data_in        => dma_snd_data_in,
      empty          => dma_snd_empty,
      full           => dma_snd_full,
      atleast_4slots => dma_snd_atleast_4slots,
      exactly_3slots => dma_snd_exactly_3slots,
      data_out       => dma_snd_data_out);

  fifo_22 : fifo0
    generic map (
      depth => 8,                       --Header, address, [data]
      width => NOC_FLIT_SIZE)
    port map (
      clk            => clk,
      rst            => fifo_rst,
      rdreq          => coherent_dma_snd_rdreq,
      wrreq          => coherent_dma_snd_wrreq,
      data_in        => coherent_dma_snd_data_in,
      empty          => coherent_dma_snd_empty,
      full           => coherent_dma_snd_full,
      data_out       => coherent_dma_snd_data_out);


  -- From noc1: APB request from remote core (APB rcv)
  -- From noc1: IRQ ack.
  -- From noc1: AHB requests from remote core (AHBS rcv)
  -- From noc1: AHB responses from remote core (remote AHBS rcv)
  -- From local_remote_apb_rcv (APB rcv from devices in this tile)
  noc1_msg_type <= get_msg_type(NOC_FLIT_SIZE, noc1_out_data);
  noc1_preamble <= get_preamble(NOC_FLIT_SIZE, noc1_out_data);
  local_remote_apb_rcv_preamble <= get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & local_remote_apb_rcv_data_out);

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
                                   local_remote_apb_rcv_empty,
                                   local_remote_apb_rcv_data_out,
                                   local_remote_apb_rcv_preamble,
                                   apb_rcv_full,
                                   remote_apb_rcv_full,
                                   irq_ack_full,
                                   interrupt_full,
                                   ahbs_rcv_full,
                                   remote_ahbs_rcv_full,
                                   dma_rcv_full,
                                   coherent_dma_rcv_full)
  begin  -- process noc1_get_packet
    remote_apb_rcv_wrreq  <= '0';
    remote_apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    remote_ahbs_rcv_wrreq <= '0';
    remote_ahbs_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    apb_rcv_wrreq         <= '0';
    apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);

    dma_rcv_wrreq          <= '0';
    dma_rcv_data_in <= noc1_out_data;

    coherent_dma_rcv_wrreq <= '0';
    coherent_dma_rcv_data_in <= noc1_out_data;

    irq_ack_wrreq         <= '0';
    interrupt_wrreq       <= '0';
    ahbs_rcv_wrreq        <= '0';

    noc1_fifos_next <= noc1_fifos_current;
    noc1_out_stop   <= '0';

    local_remote_apb_rcv_rdreq <= '0';

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
        elsif noc1_out_void = '0' then
          --APB RCV (originally on NoC 5)
          if ((noc1_msg_type = REQ_REG_RD or noc1_msg_type = REQ_REG_WR)
              and noc1_preamble = PREAMBLE_HEADER) then
            if apb_rcv_full = '0' then
              apb_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_apb_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --REMOTE APB RCV (originally on NoC 5)
          elsif (noc1_msg_type = RSP_REG_RD and noc1_preamble = PREAMBLE_HEADER) then
            if remote_apb_rcv_full = '0' then
              remote_apb_rcv_wrreq <= '1';
              noc1_fifos_next      <= packet_remote_apb_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --IRQ ACK (originally on NoC 5)
          elsif (noc1_msg_type = IRQ_MSG and noc1_preamble = PREAMBLE_HEADER) then
            if irq_ack_full = '0' then
              irq_ack_wrreq   <= '1';
              noc1_fifos_next <= packet_irq_ack;
            else
              noc1_out_stop <= '1';
            end if;
          --INTERRUPT (originally on NoC 5)
          elsif (noc1_msg_type = INTERRUPT and noc1_preamble = PREAMBLE_1FLIT) then
            interrupt_wrreq <= not interrupt_full;
            noc1_out_stop   <= interrupt_full;
          --AHBS RCV (originally on NoC 5)
          elsif ((noc1_msg_type = AHB_RD or noc1_msg_type = AHB_WR)
                 and noc1_preamble = PREAMBLE_HEADER) then
            if ahbs_rcv_full = '0' then
              ahbs_rcv_wrreq  <= '1';
              noc1_fifos_next <= packet_ahbs_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --REMOTE AHBS RCV (originally on NoC 5)
          elsif (noc1_msg_type = RSP_AHB_RD and noc1_preamble = PREAMBLE_HEADER) then
            if remote_ahbs_rcv_full = '0' then
              remote_ahbs_rcv_wrreq <= '1';
              noc1_fifos_next       <= packet_remote_ahbs_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --DMA RCV (originally on NoC 6)
          elsif (noc1_msg_type = DMA_FROM_DEV and noc1_preamble = PREAMBLE_HEADER) then
            if dma_rcv_full = '0' then
              dma_rcv_wrreq   <= '1';
              noc1_fifos_next <= packet_dma_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          --COHERENT DMA RCV (originally on NoC 6)
          elsif (noc1_msg_type = RSP_DATA_DMA and noc1_preamble = PREAMBLE_HEADER) then
            if coherent_dma_rcv_full = '0' then
              coherent_dma_rcv_wrreq <= '1';
              noc1_fifos_next        <= packet_coherent_dma_rcv;
            else
              noc1_out_stop <= '1';
            end if;
          end if;
        end if;
      --LOCAL REMOTE APB RCV (originally on NoC 5)
      when packet_local_remote_apb_rcv =>
        noc1_out_stop <= not noc1_out_void;
        apb_rcv_wrreq <= not local_remote_apb_rcv_empty and (not apb_rcv_full);
        apb_rcv_data_in <= local_remote_apb_rcv_data_out;
        if (local_remote_apb_rcv_empty = '0' and apb_rcv_full = '0') then
          local_remote_apb_rcv_rdreq <= '1';
          if local_remote_apb_rcv_preamble = PREAMBLE_TAIL then
            noc1_fifos_next <= none;
          end if;
        end if;
      --APB RCV (originally on NoC 5)
      when packet_apb_rcv =>
        apb_rcv_wrreq <= not noc1_out_void and (not apb_rcv_full);
        noc1_out_stop <= apb_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            apb_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --REMOTE APB RCV (originally on NoC 5)
      when packet_remote_apb_rcv =>
        remote_apb_rcv_wrreq <= not noc1_out_void and (not remote_apb_rcv_full);
        noc1_out_stop        <= remote_apb_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            remote_apb_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --IRQ ACK (originally on NoC 5)
      when packet_irq_ack =>
        irq_ack_wrreq <= not noc1_out_void and (not irq_ack_full);
        noc1_out_stop <= irq_ack_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            irq_ack_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --AHBS RCV (originally on NoC 5)
      when packet_ahbs_rcv =>
        ahbs_rcv_wrreq <= not noc1_out_void and (not ahbs_rcv_full);
        noc1_out_stop  <= ahbs_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            ahbs_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --REMOTE AHBS RCV (originally on NoC 5)
      when packet_remote_ahbs_rcv =>
        remote_ahbs_rcv_wrreq <= not noc1_out_void and (not remote_ahbs_rcv_full);
        noc1_out_stop         <= remote_ahbs_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            remote_ahbs_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --DMA RCV (originally on NoC 6)
      when packet_dma_rcv =>
        dma_rcv_wrreq <= not noc1_out_void and (not dma_rcv_full);
        noc1_out_stop <= dma_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            dma_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      --COHERENT DMA RCV (originally on NoC 6)
      when packet_coherent_dma_rcv =>
        coherent_dma_rcv_wrreq <= not noc1_out_void and (not coherent_dma_rcv_full);
        noc1_out_stop          <= coherent_dma_rcv_full and (not noc1_out_void);
        if (noc1_preamble = PREAMBLE_TAIL and noc1_out_void = '0' and
            coherent_dma_rcv_full = '0') then
          noc1_fifos_next <= none;
        end if;
      when others =>
        noc1_fifos_next <= none;
    end case;
  end process noc1_fifos_get_packet;

  fifo_7 : fifo0
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

  fifo_20 : fifo0
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

  irq_ack_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_12 : fifo0
    generic map (
      depth => 8,                       --Header, irq info x # cpus
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => irq_ack_rdreq,
      wrreq    => irq_ack_wrreq,
      data_in  => irq_ack_data_in,
      empty    => irq_ack_empty,
      full     => irq_ack_full,
      data_out => irq_ack_data_out);

  interrupt_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_15 : fifo0
    generic map (
      depth => 9,                       --Header x # accelerators
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

  ahbs_rcv_data_in <= large_to_narrow_flit(noc1_out_data);
  fifo_16 : fifo0
    generic map (
      depth => 6,                       --Header, address, [data]
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => ahbs_rcv_rdreq,
      wrreq    => ahbs_rcv_wrreq,
      data_in  => ahbs_rcv_data_in,
      empty    => ahbs_rcv_empty,
      full     => ahbs_rcv_full,
      data_out => ahbs_rcv_data_out);

  fifo_26 : fifo0
    generic map (
      depth => 6,                       --Header, address, [data]
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


  -- To noc1: APB response to remote core (APB snd)
  -- To noc1: IRQ
  -- To noc1: INTERRUPT ack to accelerators
  -- to noc1: AHB reponse messages to CPU (AHBS snd)
  -- to noc1: AHB request messages to remote slaves (remote AHBS snd)
  process (clk, rst)
  begin  -- process
    if rst = '0' then                   -- asynchronous reset (active low)
      to_noc1_fifos_current <= none;
    elsif clk'event and clk = '1' then  -- rising clock edge
      to_noc1_fifos_current <= to_noc1_fifos_next;
    end if;
  end process;

  to_noc1_select_packet : process (noc1_in_stop, to_noc1_fifos_current,
                                   local_apb_snd_full,
                                   apb_snd_data_out, apb_snd_empty,
                                   remote_apb_snd_data_out, remote_apb_snd_empty,
                                   irq_data_out, irq_empty,
                                   interrupt_ack_data_out, interrupt_ack_empty,
                                   ahbs_snd_data_out, ahbs_snd_empty,
                                   remote_ahbs_snd_data_out, remote_ahbs_snd_empty,
                                   dma_snd_data_out, dma_snd_empty,
                                   coherent_dma_snd_data_out, coherent_dma_snd_empty)
    variable to_noc1_preamble : noc_preamble_type;
    variable remote_apb_snd_to_local : std_ulogic;
    variable apb_snd_to_local : std_ulogic;
  begin  -- process to_noc1_select_packet
    apb_snd_to_local        := apb_snd_data_out(HEADER_ROUTE_L);
    local_apb_snd_wrreq <= '0';

    noc1_in_data          <= (others => '0');
    noc1_in_void          <= '1';
    apb_snd_rdreq         <= '0';
    remote_apb_snd_rdreq  <= '0';
    irq_rdreq             <= '0';
    interrupt_ack_rdreq   <= '0';
    ahbs_snd_rdreq        <= '0';
    remote_ahbs_snd_rdreq <= '0';
    dma_snd_rdreq          <= '0';
    coherent_dma_snd_rdreq <= '0';

    to_noc1_fifos_next    <= to_noc1_fifos_current;
    to_noc1_preamble      := "00";

    case to_noc1_fifos_current is
      when none =>
        --IRQ (originally on NoC 5)
        if irq_empty = '0' then
          noc1_in_data <= narrow_to_large_flit(irq_data_out);
          to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & irq_data_out);
          if noc1_in_stop = '0' then
            noc1_in_void       <= irq_empty;
            irq_rdreq          <= '1';
            if to_noc1_preamble = PREAMBLE_HEADER then
              -- Leon3 needs more than single flit
              to_noc1_fifos_next <= packet_irq;
            end if;
          end if;
        --INTERRUPT ACK (originally on NoC 5)
        elsif interrupt_ack_empty = '0' then
          if noc1_in_stop = '0' then
            noc1_in_data <= narrow_to_large_flit(interrupt_ack_data_out);
            noc1_in_void <= interrupt_ack_empty;
            interrupt_ack_rdreq <= '1';
          end if;
        --APB SND (originally on NoC 5)
        elsif (apb_snd_empty = '0' and apb_snd_to_local = '0') then
          noc1_in_data <= narrow_to_large_flit(apb_snd_data_out);
          if noc1_in_stop = '0' then
            noc1_in_void       <= apb_snd_empty;
            apb_snd_rdreq      <= '1';
            to_noc1_fifos_next <= packet_apb_snd;
          end if;
        --LOCAL APB SND (originally on NoC 5)
        elsif (apb_snd_empty = '0' and apb_snd_to_local = '1') then
          if local_apb_snd_full = '0' then
            local_apb_snd_wrreq <= '1';
            apb_snd_rdreq <= '1';
            to_noc1_fifos_next <= packet_local_apb_snd;
          end if;
        --REMOTE APB SND (originally on NoC 5)
        elsif remote_apb_snd_empty = '0' then
          noc1_in_data <= narrow_to_large_flit(remote_apb_snd_data_out);
          if noc1_in_stop = '0' then
            noc1_in_void         <= remote_apb_snd_empty;
            remote_apb_snd_rdreq <= '1';
            to_noc1_fifos_next   <= packet_remote_apb_snd;
          end if;
        --AHBS SND (originally on NoC 5)
        elsif ahbs_snd_empty = '0' then
          noc1_in_data <= narrow_to_large_flit(ahbs_snd_data_out);
          if noc1_in_stop = '0' then
            noc1_in_void       <= ahbs_snd_empty;
            ahbs_snd_rdreq     <= '1';
            to_noc1_fifos_next <= packet_ahbs_snd;
          end if;
        --REMOTE AHBS SND (originally on NoC 5)
        elsif remote_ahbs_snd_empty = '0' then
          noc1_in_data <= narrow_to_large_flit(remote_ahbs_snd_data_out);
          if noc1_in_stop = '0' then
            noc1_in_void          <= remote_ahbs_snd_empty;
            remote_ahbs_snd_rdreq <= '1';
            to_noc1_fifos_next    <= packet_remote_ahbs_snd;
          end if;
        --DMA SND (originally on NoC 4)
        elsif dma_snd_empty = '0' then
          noc1_in_data <= dma_snd_data_out;
          noc1_in_void <= dma_snd_empty;
          if noc1_in_stop = '0' then
            dma_snd_rdreq      <= '1';
            to_noc1_fifos_next <= packet_dma_snd;
          end if;
        --COHERENT DMA SND (originally on NoC 4)
        elsif coherent_dma_snd_empty = '0' then
          noc1_in_data <= coherent_dma_snd_data_out;
          noc1_in_void <= coherent_dma_snd_empty;
          if noc1_in_stop = '0' then
            coherent_dma_snd_rdreq <= '1';
            to_noc1_fifos_next     <= packet_coherent_dma_snd;
          end if;
        end if;
      --APB SND (originally on NoC 5)
      when packet_apb_snd =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
        if (noc1_in_stop = '0' and apb_snd_empty = '0') then
          noc1_in_data  <= narrow_to_large_flit(apb_snd_data_out);
          noc1_in_void  <= apb_snd_empty;
          apb_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --LOCAL APB SND (originally on NoC 5)
      when packet_local_apb_snd =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & apb_snd_data_out);
        if (local_apb_snd_full = '0' and apb_snd_empty = '0') then
          local_apb_snd_wrreq <= '1';
          apb_snd_rdreq <= '1';
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --REMOTE APB SND (originally on NoC 5)
      when packet_remote_apb_snd =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_apb_snd_data_out);
        if (noc1_in_stop = '0' and remote_apb_snd_empty = '0') then
          noc1_in_data <= narrow_to_large_flit(remote_apb_snd_data_out);
          noc1_in_void         <= remote_apb_snd_empty;
          remote_apb_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --AHBS SND (originally on NoC 5)
      when packet_ahbs_snd =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & ahbs_snd_data_out);
        if (noc1_in_stop = '0' and ahbs_snd_empty = '0') then
          noc1_in_data <= narrow_to_large_flit(ahbs_snd_data_out);
          noc1_in_void   <= ahbs_snd_empty;
          ahbs_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --REMOTE AHBS SND (originally on NoC 5)
      when packet_remote_ahbs_snd =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & remote_ahbs_snd_data_out);
        if (noc1_in_stop = '0' and remote_ahbs_snd_empty = '0') then
          noc1_in_data <= narrow_to_large_flit(remote_ahbs_snd_data_out);
          noc1_in_void          <= remote_ahbs_snd_empty;
          remote_ahbs_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --IRQ (originally on NoC 5)
      when packet_irq =>
        to_noc1_preamble := get_preamble(MISC_NOC_FLIT_SIZE, noc_flit_pad & irq_data_out);
        if (noc1_in_stop = '0' and irq_empty = '0') then
          noc1_in_data <= narrow_to_large_flit(irq_data_out);
          noc1_in_void <= irq_empty;
          irq_rdreq    <= not noc1_in_stop;
          if (to_noc1_preamble = PREAMBLE_TAIL) then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --DMA SND (originally on NoC 4)
      when packet_dma_snd =>
        to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, dma_snd_data_out);
        if (noc1_in_stop = '0' and dma_snd_empty = '0') then
          noc1_in_data  <= dma_snd_data_out;
          noc1_in_void  <= dma_snd_empty;
          dma_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      --COHERENT DMA SND (originally on NoC 4)
      when packet_coherent_dma_snd =>
        to_noc1_preamble := get_preamble(NOC_FLIT_SIZE, coherent_dma_snd_data_out);
        if (noc1_in_stop = '0' and coherent_dma_snd_empty = '0') then
          noc1_in_data           <= coherent_dma_snd_data_out;
          noc1_in_void           <= coherent_dma_snd_empty;
          coherent_dma_snd_rdreq <= not noc1_in_stop;
          if to_noc1_preamble = PREAMBLE_TAIL then
            to_noc1_fifos_next <= none;
          end if;
        end if;
      when others =>
        to_noc1_fifos_next <= none;
    end case;
  end process to_noc1_select_packet;

  fifo_23: fifo0
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
  fifo_24: fifo0
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

  fifo_10 : fifo0
    generic map (
      depth => 2,                       --Header, data (1 word)
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

  fifo_21 : fifo0
    generic map (
      depth => 3,                       --Header, address, data
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

  fifo_9 : fifo0
    generic map (
      depth => 2,                       --Header, irq level
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => irq_rdreq,
      wrreq    => irq_wrreq,
      data_in  => irq_data_in,
      empty    => irq_empty,
      full     => irq_full,
      data_out => irq_data_out);

  fifo_11 : fifo0
    generic map (
      depth => 2,                       --Header, interrupt_ack level
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

  fifo_17 : fifo0
    generic map (
      depth => 5,                       --Header, data
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => ahbs_snd_rdreq,
      wrreq    => ahbs_snd_wrreq,
      data_in  => ahbs_snd_data_in,
      empty    => ahbs_snd_empty,
      full     => ahbs_snd_full,
      data_out => ahbs_snd_data_out);

  fifo_27 : fifo0
    generic map (
      depth => 5,                       --Header, data
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


end rtl;
