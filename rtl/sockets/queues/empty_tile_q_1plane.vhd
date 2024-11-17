------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    empty_tile_q_1plane.vhd
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

entity empty_tile_q_1plane is
  generic (
    tech : integer := virtex7);
  port (
    rst                             : in  std_ulogic;
    clk                             : in  std_ulogic;
    -- noc1->tile
    apb_rcv_rdreq           : in  std_ulogic;
    apb_rcv_data_out        : out misc_noc_flit_type;
    apb_rcv_empty           : out std_ulogic;
    -- tile->noc1
    apb_snd_wrreq           : in  std_ulogic;
    apb_snd_data_in         : in  misc_noc_flit_type;
    apb_snd_full            : out std_ulogic;

    -- Cachable data plane 1 -> request messages
    noc1_out_data : in  noc_flit_type;
    noc1_out_void : in  std_ulogic;
    noc1_out_stop : out std_ulogic;
    noc1_in_data  : out noc_flit_type;
    noc1_in_void  : out std_ulogic;
    noc1_in_stop  : in  std_ulogic);

end empty_tile_q_1plane;

architecture rtl of empty_tile_q_1plane is

  signal fifo_rst : std_ulogic;

  -- noc1->tile
  signal apb_rcv_wrreq     : std_ulogic;
  signal apb_rcv_data_in   : misc_noc_flit_type;
  signal apb_rcv_full      : std_ulogic;
  -- tile->noc1
  signal apb_snd_rdreq     : std_ulogic;
  signal apb_snd_data_out  : misc_noc_flit_type;
  signal apb_snd_empty     : std_ulogic;


begin  -- rtl

  fifo_rst <= rst;                      --FIFO rst active low


  -- From noc1: APB requests
  noc1_out_stop           <= apb_rcv_full and (not noc1_out_void);
  apb_rcv_data_in <= large_to_narrow_flit(noc1_out_data);
  apb_rcv_wrreq   <= (not noc1_out_void) and (not apb_rcv_full);
  fifo_8 : fifo0
    generic map (
      depth => 5,                       --Header, data up to 4 words
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

  -- To noc1: APB response
  noc1_in_data          <= narrow_to_large_flit(apb_snd_data_out);
  noc1_in_void          <= apb_snd_empty or noc1_in_stop;
  apb_snd_rdreq <= (not apb_snd_empty) and (not noc1_in_stop);
  fifo_11 : fifo0
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

end rtl;
