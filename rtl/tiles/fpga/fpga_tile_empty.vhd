------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    fpga_tile_empty.vhd
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

-----------------------------------------------------------------------------
--  EMPTY tile
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.leon3.all;
use work.ariane_esp_pkg.all;
use work.misc.all;
-- pragma translate_off
use work.sim.all;
library unisim;
use unisim.all;
-- pragma translate_on
use work.monitor_pkg.all;
use work.esp_csr_pkg.all;
use work.jtag_pkg.all;
use work.sldacc.all;
use work.nocpackage.all;
use work.tile.all;
use work.cachepackage.all;
use work.coretypes.all;
use work.grlib_config.all;
use work.socmap.all;
use work.tiles_pkg.all;

entity fpga_tile_empty is
  generic (
    SIMULATION   : boolean              := false;
    HAS_SYNC     : integer range 0 to 1 := 1;
    ROUTER_PORTS : ports_vec            := "11111");
  port (
    raw_rstn           : in  std_ulogic;
    rst                : in  std_logic;
    clk                : in  std_logic;
    refclk             : in  std_ulogic;
    icclk             : in    std_logic; -- a variable clock for the interconnect resources
    icrst             : in    std_logic; -- a reset for the interconnect resources
    pllbypass          : in  std_ulogic;
    pllclk             : out std_ulogic;
    pll_locked         : out std_logic;  -- bringing internal lock to the top module
    dco_clk            : out std_ulogic;
    -- Test interface
    tdi                : in  std_logic;
    tdo                : out std_logic;
    tms                : in  std_logic;
    tclk               : in  std_logic;
    -- NOC
    sys_clk_int        : in  std_logic;
    noc_data_n_in     : in  noc_flit_vector;
    noc_data_s_in     : in  noc_flit_vector;
    noc_data_w_in     : in  noc_flit_vector;
    noc_data_e_in     : in  noc_flit_vector;
    noc_data_void_in  : in  partial_handshake_vector;
    noc_stop_in       : in  partial_handshake_vector;
    noc_data_n_out    : out noc_flit_vector;
    noc_data_s_out    : out noc_flit_vector;
    noc_data_w_out    : out noc_flit_vector;
    noc_data_e_out    : out noc_flit_vector;
    noc_data_void_out : out partial_handshake_vector;
    noc_stop_out      : out partial_handshake_vector;
    noc_mon_noc_vec   : out monitor_noc_vector(num_noc_planes-1 downto 0);
    mon_dvfs_out       : out monitor_dvfs_type);
end;

architecture rtl of fpga_tile_empty is

  -- Tile parameters
  signal this_local_y : local_yx;
  signal this_local_x : local_yx;

  -- DCO reset -> keeping the logic compliant with the asic flow
  signal dco_rstn : std_ulogic;

  -- Tile interface signals
  signal test_output_port_s   : noc_flit_vector;
  signal test_data_void_out_s : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_stop_in_s       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_input_port_s    : noc_flit_vector;
  signal test_data_void_in_s  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal test_stop_out_s      : std_ulogic_vector(num_noc_planes-1 downto 0);

  signal noc_mon_noc_vec_int  : monitor_noc_vector(num_noc_planes-1 downto 0);

  -- Noc signals
  signal noc_stop_in_s         : handshake_vector;
  signal noc_stop_out_s        : handshake_vector;
  signal noc_empty_stop_in       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_empty_stop_out      : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_data_void_in_s    : handshake_vector;
  signal noc_data_void_out_s   : handshake_vector;
  signal noc_empty_data_void_in  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_empty_data_void_out : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_input_port        : noc_flit_vector;
  signal noc_output_port       : noc_flit_vector;

  attribute keep              : string;
  attribute keep of noc_empty_stop_in       : signal is "true";
  attribute keep of noc_empty_stop_out      : signal is "true";
  attribute keep of noc_empty_data_void_in  : signal is "true";
  attribute keep of noc_empty_data_void_out : signal is "true";
  attribute keep of noc_input_port        : signal is "true";
  attribute keep of noc_output_port       : signal is "true";
  attribute keep of noc_data_n_in     : signal is "true";
  attribute keep of noc_data_s_in     : signal is "true";
  attribute keep of noc_data_w_in     : signal is "true";
  attribute keep of noc_data_e_in     : signal is "true";
  attribute keep of noc_data_void_in  : signal is "true";
  attribute keep of noc_stop_in       : signal is "true";
  attribute keep of noc_data_n_out    : signal is "true";
  attribute keep of noc_data_s_out    : signal is "true";
  attribute keep of noc_data_w_out    : signal is "true";
  attribute keep of noc_data_e_out    : signal is "true";
  attribute keep of noc_data_void_out : signal is "true";
  attribute keep of noc_stop_out      : signal is "true";

begin

  pll_locked       <= '1'; -- no pll implemented in this kind of tile

  noc_mon_noc_vec <= noc_mon_noc_vec_int;

 -----------------------------------------------------------------------------
  -- JTAG for single tile testing / bypass when test_if_en = 0 ( bypass jtag)
  -----------------------------------------------------------------------------
  noc_empty_stop_in <= test_stop_in_s;
  test_output_port_s <= noc_output_port;
  test_data_void_out_s <= noc_empty_data_void_out;
  test_stop_out_s <= noc_empty_stop_out;
  noc_input_port <= test_input_port_s;
  noc_empty_data_void_in <= test_data_void_in_s;

  tdo <= '0';

  -----------------------------------------------------------------------------
  -- NOC Connections
  ----------------------------------------------------------------------------
  connections_generation: for plane in 0 to num_noc_planes-1 generate
    noc_stop_in_s(plane)         <= noc_empty_stop_in(plane)  & noc_stop_in(plane);
    noc_stop_out(plane)          <= noc_stop_out_s(plane)(3 downto 0);
    noc_empty_stop_out(plane)      <= noc_stop_out_s(plane)(4);
    noc_data_void_in_s(plane)    <= noc_empty_data_void_in(plane) & noc_data_void_in(plane);
    noc_data_void_out(plane)     <= noc_data_void_out_s(plane)(3 downto 0);
    noc_empty_data_void_out(plane) <= noc_data_void_out_s(plane)(4);
  end generate connections_generation;

  sync_noc_set_empty: sync_noc_set
  generic map (
     PORTS    => ROUTER_PORTS,
     HAS_SYNC => HAS_SYNC)
   port map (
     clk                => icclk,
     clk_tile           => clk,
     rst                => icrst,
     rst_tile           => rst,
     CONST_local_x      => this_local_x,
     CONST_local_y      => this_local_y,
     noc_data_n_in     => noc_data_n_in,
     noc_data_s_in     => noc_data_s_in,
     noc_data_w_in     => noc_data_w_in,
     noc_data_e_in     => noc_data_e_in,
     noc_input_port    => noc_input_port,
     noc_data_void_in  => noc_data_void_in_s,
     noc_stop_in       => noc_stop_in_s,
     noc_data_n_out    => noc_data_n_out,
     noc_data_s_out    => noc_data_s_out,
     noc_data_w_out    => noc_data_w_out,
     noc_data_e_out    => noc_data_e_out,
     noc_output_port   => noc_output_port,
     noc_data_void_out => noc_data_void_out_s,
     noc_stop_out      => noc_stop_out_s,
     noc_mon_noc_vec   => noc_mon_noc_vec_int
     );



  tile_empty_1: tile_empty
    generic map (
      SIMULATION   => SIMULATION,
      this_has_dco => 0)
    port map (
      raw_rstn           => raw_rstn,
      tile_rst           => rst,
      clk                => clk,
      refclk             => refclk,
      pllbypass          => pllbypass,
      pllclk             => pllclk,
      dco_clk            => dco_clk,
      dco_rstn           => dco_rstn,
      pad_cfg            => open,
      local_x            => this_local_x,
      local_y            => this_local_y,
      test_output_port   => test_output_port_s,
      test_data_void_out => test_data_void_out_s,
      test_stop_in       => test_stop_out_s,
      test_input_port    => test_input_port_s,
      test_data_void_in  => test_data_void_in_s,
      test_stop_out      => test_stop_in_s,
      noc_mon_noc_vec   => noc_mon_noc_vec_int,
      mon_dvfs_out        => mon_dvfs_out);

end;
