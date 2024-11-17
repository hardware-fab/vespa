------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    fpga_tile_cpu.vhd
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
--  CPU tile
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

entity fpga_tile_cpu is
  generic (
    SIMULATION         : boolean              := false;
    this_has_dvfs      : integer range 0 to 1 := 0;
    this_has_pll       : integer range 0 to 1 := 0;
    this_extra_clk_buf : integer range 0 to 1 := 0;
    ROUTER_PORTS       : ports_vec            := "11111";
    HAS_SYNC           : integer range 0 to 1 := 1;
    this_clock_domain  : integer := 0; -- clock domain of this tile
    pll_clk_freq       : integer range 0 to 10 := 0 -- clock frequency that must be returned from the pll (1=max, 10=min)
    );
  port (
    raw_rstn           : in  std_ulogic;
    rst                : in  std_ulogic;
    base_rst           : in    std_logic;  -- a reset for clocking resources
    refclk             : in  std_ulogic;
    icclk             : in    std_logic; -- a variable clock for the interconnect resources
    icrst              : in std_logic; -- reset for interconnect resources inside the tile
    pllbypass          : in  std_ulogic;
    pllclk             : out std_ulogic;
    pll_locked         : out std_logic;  -- bringing internal lock to the top module
    pll_lck_glb        : in std_logic;  -- bringing global lock to the local reset generator
    dco_clk            : out std_ulogic;
    cpuerr             : out std_ulogic;
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
    mon_cache          : out monitor_cache_type;
    mon_dvfs_in        : in  monitor_dvfs_type;
    mon_dvfs           : out monitor_dvfs_type;
    freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  -- input freq data
    freq_empty_in      : in std_logic -- freq data empty
    );
end;


architecture rtl of fpga_tile_cpu is

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
  signal noc_cpu_stop_in       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_cpu_stop_out      : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_data_void_in_s    : handshake_vector;
  signal noc_data_void_out_s   : handshake_vector;
  signal noc_cpu_data_void_in  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_cpu_data_void_out : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_input_port        : noc_flit_vector;
  signal noc_output_port       : noc_flit_vector;

  attribute keep              : string;
  attribute keep of noc_cpu_stop_in       : signal is "true";
  attribute keep of noc_cpu_stop_out      : signal is "true";
  attribute keep of noc_cpu_data_void_in  : signal is "true";
  attribute keep of noc_cpu_data_void_out : signal is "true";
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

  -- my signals
  signal clk_feedthru : std_logic;
  signal pllclk_int : std_logic;
  
begin
  
  -- the clock that must be used internally
  clock_no_pll: if this_has_pll /= 0 generate
    clk_feedthru <= pllclk_int;
  end generate;

  clock_with_pll: if this_has_pll = 0 generate
    clk_feedthru <= refclk;
  end generate;
  
  pllclk <= pllclk_int;
  ----------------------------------------------------
  
  noc_mon_noc_vec <= noc_mon_noc_vec_int;

  -----------------------------------------------------------------------------
  -- JTAG for single tile testing / bypass when test_if_en = 0 ( bypass jtag)
  -----------------------------------------------------------------------------
  noc_cpu_stop_in <= test_stop_in_s;
  test_output_port_s <= noc_output_port;
  test_data_void_out_s <= noc_cpu_data_void_out;
  test_stop_out_s <= noc_cpu_stop_out;
  noc_input_port <= test_input_port_s;
  noc_cpu_data_void_in <= test_data_void_in_s;

  tdo <= '0';

  -----------------------------------------------------------------------------
  -- NOC Connections
  ----------------------------------------------------------------------------
  connections_generation: for plane in 0 to num_noc_planes-1 generate
    noc_stop_in_s(plane)         <= noc_cpu_stop_in(plane)  & noc_stop_in(plane);
    noc_stop_out(plane)          <= noc_stop_out_s(plane)(3 downto 0);
    noc_cpu_stop_out(plane)      <= noc_stop_out_s(plane)(4);
    noc_data_void_in_s(plane)    <= noc_cpu_data_void_in(plane) & noc_data_void_in(plane);
    noc_data_void_out(plane)     <= noc_data_void_out_s(plane)(3 downto 0);
    noc_cpu_data_void_out(plane) <= noc_data_void_out_s(plane)(4);
  end generate connections_generation;

  --GM note: this is the synchronizing interface: as such, it uses the tile clock as well as the interconnect clock
  sync_noc_set_cpu: sync_noc_set
  generic map (
     PORTS    => ROUTER_PORTS,
     HAS_SYNC => HAS_SYNC )
   port map (
     clk                => icclk,--sys_clk_int,         -- NoC clock
     clk_tile           => clk_feedthru, --refclk,      -- tile clock
     rst                => icrst,--rst,        -- use ic reset
     rst_tile           => rst, --dco_rstn,    -- use tile reset
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


  tile_cpu_1: tile_cpu
    generic map (
      SIMULATION          => SIMULATION,
      this_has_dvfs       => this_has_dvfs,  -- no DVFS controller
      this_has_pll        => this_has_pll,
      this_has_dco        => 0,
      this_extra_clk_buf  => this_extra_clk_buf,
      this_clock_domain  => this_clock_domain, -- clock domain of this tile
      pll_clk_freq       => pll_clk_freq -- clock frequency that must be returned from the pll (1=max, 10=min)
    )
    port map (
      raw_rstn            => raw_rstn,
      tile_rst            => rst,
      base_rst            => base_rst, -- a reset for clocking resources
      refclk              => refclk,
      icclk               => icclk, -- a variable clock for the interconnect resources
      icrst               => icrst, -- reset for interconnect resources inside the tile
      pllbypass           => pllbypass,
      pllclk              => pllclk_int,  -- I need the pll clock internally
      pll_locked          => pll_locked,  -- bringing internal lock to the top module
      pll_lck_glb         => pll_lck_glb,  -- bringing global lock to the local reset generator
      dco_clk             => dco_clk,
      dco_rstn            => dco_rstn,
      cpuerr              => cpuerr,
      -- Pad configuration
      pad_cfg             => open,
      -- NOC
      local_x             => this_local_x,
      local_y             => this_local_y, 
      noc_mon_noc_vec   => noc_mon_noc_vec_int,
      test_output_port   => test_output_port_s,
      test_data_void_out => test_data_void_out_s,
      test_stop_in       => test_stop_out_s,
      test_input_port    => test_input_port_s,
      test_data_void_in  => test_data_void_in_s,
      test_stop_out      => test_stop_in_s,
      mon_cache           => mon_cache,
      mon_dvfs_in         => mon_dvfs_in,
      mon_dvfs            => mon_dvfs,
      freq_data_in          => freq_data_in,  -- input freq data
      freq_empty_in         => freq_empty_in -- freq data empty
      );

end;
