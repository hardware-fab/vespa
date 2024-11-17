------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    sync_noc_set.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.monitor_pkg.all;
use work.nocpackage.all;

use work.esp_global.all;

entity sync_noc_set is
  generic (
    PORTS     : std_logic_vector(4 downto 0);
--    local_x   : std_logic_vector(2 downto 0);
--    local_y   : std_logic_vector(2 downto 0);
    HAS_SYNC  : integer range 0 to 1 := 0);
  port (
    clk           : in  std_logic;
    clk_tile      : in  std_logic;
    rst           : in  std_logic;
    rst_tile      : in  std_logic;
--    CONST_PORTS   : in  std_logic_vector(4 downto 0);
    CONST_local_x : in  std_logic_vector(2 downto 0);
    CONST_local_y : in  std_logic_vector(2 downto 0);
    noc_data_n_in     : in  noc_flit_vector;
    noc_data_s_in     : in  noc_flit_vector;
    noc_data_w_in     : in  noc_flit_vector;
    noc_data_e_in     : in  noc_flit_vector;
    noc_input_port    : in  noc_flit_vector;
    noc_data_void_in  : in  handshake_vector;
    noc_stop_in       : in  handshake_vector;
    noc_data_n_out    : out noc_flit_vector;
    noc_data_s_out    : out noc_flit_vector;
    noc_data_w_out    : out noc_flit_vector;
    noc_data_e_out    : out noc_flit_vector;
    noc_output_port   : out noc_flit_vector;
    noc_data_void_out : out handshake_vector;
    noc_stop_out      : out handshake_vector;

    -- Monitor output. Can be left unconnected
    noc_mon_noc_vec   : out monitor_noc_vector(num_noc_planes-1 downto 0)

    );

end sync_noc_set;

architecture mesh of sync_noc_set is

  component sync_noc_xy
    generic (
      PORTS     : std_logic_vector(4 downto 0);
--      local_x   : std_logic_vector(2 downto 0);
--      local_y   : std_logic_vector(2 downto 0);
      has_sync  : integer range 0 to 1); --further, pass these param to module through CFG_HAS_SYNC parameter pkg file
    port (
      clk           : in  std_logic;
      clk_tile      : in  std_logic;
      rst           : in  std_logic;
      rst_tile      : in  std_logic;
--      CONST_PORTS   : in  std_logic_vector(4 downto 0);
      CONST_local_x : in  std_logic_vector(2 downto 0);
      CONST_local_y : in  std_logic_vector(2 downto 0);
      data_n_in     : in  noc_flit_type;
      data_s_in     : in  noc_flit_type;
      data_w_in     : in  noc_flit_type;
      data_e_in     : in  noc_flit_type;
      input_port    : in  noc_flit_type;
      data_void_in  : in  std_logic_vector(4 downto 0);
      stop_in       : in  std_logic_vector(4 downto 0);
      data_n_out    : out noc_flit_type;
      data_s_out    : out noc_flit_type;
      data_w_out    : out noc_flit_type;
      data_e_out    : out noc_flit_type;
      output_port   : out noc_flit_type;
      data_void_out : out std_logic_vector(4 downto 0);
      stop_out      : out std_logic_vector(4 downto 0);
      -- Monitor output. Can be left unconnected
      mon_noc       : out monitor_noc_type
      );
  end component;

begin

  sync_noc_set_loop: for plane in 0 to num_noc_planes-1 generate
    sync_noc_set: sync_noc_xy
      generic map (
        PORTS    =>  PORTS,
  --      local_x  =>  local_x,
  --      local_y  =>  local_y,
        has_sync =>  HAS_SYNC) --further, pass these param to module through CFG_HAS_SYNC parameter pkg file
      port map (
        clk           => clk,
        clk_tile      => clk_tile,
        rst           => rst,
        rst_tile      => rst_tile,
  --      CONST_PORTS   => CONST_PORTS,
        CONST_local_x => CONST_local_x,
        CONST_local_y => CONST_local_y,
        data_n_in     => noc_data_n_in(plane),
        data_s_in     => noc_data_s_in(plane),
        data_w_in     => noc_data_w_in(plane),
        data_e_in     => noc_data_e_in(plane),
        input_port    => noc_input_port(plane),
        data_void_in  => noc_data_void_in(plane),
        stop_in       => noc_stop_in(plane),
        data_n_out    => noc_data_n_out(plane),
        data_s_out    => noc_data_s_out(plane),
        data_w_out    => noc_data_w_out(plane),
        data_e_out    => noc_data_e_out(plane),
        output_port   => noc_output_port(plane),
        data_void_out => noc_data_void_out(plane),
        stop_out      => noc_stop_out(plane),
        mon_noc       => noc_mon_noc_vec(plane)
        );
  end generate sync_noc_set_loop;

end;
