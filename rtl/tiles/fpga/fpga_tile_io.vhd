------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    fpga_tile_io.vhd
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
--  I/O tile.
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
use work.uart.all;
use work.misc.all;
use work.net.all;
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
use work.coretypes.all;
use work.grlib_config.all;
use work.socmap.all;
use work.ariane_esp_pkg.all;
use work.tiles_pkg.all;

entity fpga_tile_io is
  generic (
    SIMULATION   : boolean   := false;
    ROUTER_PORTS : ports_vec := "11111";
    HAS_SYNC     : integer range 0 to 1 := 1
    );
  port (
    raw_rstn           : in    std_ulogic;
    rst                : in    std_ulogic;  -- Global reset (active high)
    clk                : in    std_ulogic;
    refclk_noc         : in    std_ulogic;
    pllclk_noc         : out   std_ulogic;
    refclk             : in    std_ulogic;
    pllbypass          : in    std_ulogic;
    pllclk             : out   std_ulogic; 
    pll_locked         : out std_logic;  -- bringing internal lock to the top module
    dco_clk            : out   std_ulogic;
    -- Ethernet
    mdcscaler          : out   integer range 0 to 2047;
    eth0_apbi          : out   apb_slv_in_type;
    eth0_apbo          : in    apb_slv_out_type;
    sgmii0_apbi        : out   apb_slv_in_type;
    sgmii0_apbo        : in    apb_slv_out_type;
    eth0_ahbmi         : out   ahb_mst_in_type;
    eth0_ahbmo         : in    ahb_mst_out_type;
    edcl_ahbmo         : in    ahb_mst_out_type;
    dvi_apbi           : out   apb_slv_in_type;
    dvi_apbo           : in    apb_slv_out_type;
    dvi_ahbmi          : out   ahb_mst_in_type;
    dvi_ahbmo          : in    ahb_mst_out_type;
    -- UART
    uart_rxd           : in    std_ulogic;
    uart_txd           : out   std_ulogic;
    uart_ctsn          : in    std_ulogic;
    uart_rtsn          : out   std_ulogic;
    -- Test interface
    tdi                : in    std_logic;
    tdo                : out   std_logic;
    tms                : in    std_logic;
    tclk               : in    std_logic;
    -- NOC
    sys_clk_int        : in    std_ulogic;
    sys_rstn           : in    std_ulogic;
    sys_clk_out        : out   std_ulogic;
    sys_clk_lock       : out   std_ulogic;
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
    mon_dvfs           : out   monitor_dvfs_type;
    freq_data_out       : out freq_reg_t;    -- number describing freq
    freq_empty_out      : out std_logic_vector(domains_num - 1 downto 0)  -- validity signal for freqs
    );

end;

architecture rtl of fpga_tile_io is

  attribute syn_keep                    : boolean;
  attribute syn_preserve                : boolean;

  signal this_local_x          : local_yx;
  signal this_local_y          : local_yx;

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
  signal noc_io_stop_in       : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_io_stop_out      : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_data_void_in_s    : handshake_vector;
  signal noc_data_void_out_s   : handshake_vector;
  signal noc_io_data_void_in  : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_io_data_void_out : std_ulogic_vector(num_noc_planes-1 downto 0);
  signal noc_input_port        : noc_flit_vector;
  signal noc_output_port       : noc_flit_vector;

  attribute keep              : string;
  attribute keep of noc_io_stop_in       : signal is "true";
  attribute keep of noc_io_stop_out      : signal is "true";
  attribute keep of noc_io_data_void_in  : signal is "true";
  attribute keep of noc_io_data_void_out : signal is "true";
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
  noc_io_stop_in <= test_stop_in_s;
  test_output_port_s <= noc_output_port;
  test_data_void_out_s <= noc_io_data_void_out;
  test_stop_out_s <= noc_io_stop_out;
  noc_input_port <= test_input_port_s;
  noc_io_data_void_in <= test_data_void_in_s;

  tdo <= '0';

  -----------------------------------------------------------------------------
  -- NOC Connections
  ----------------------------------------------------------------------------
  connections_generation: for plane in 0 to num_noc_planes-1 generate
    noc_stop_in_s(plane)         <= noc_io_stop_in(plane)  & noc_stop_in(plane);
    noc_stop_out(plane)          <= noc_stop_out_s(plane)(3 downto 0);
    noc_io_stop_out(plane)      <= noc_stop_out_s(plane)(4);
    noc_data_void_in_s(plane)    <= noc_io_data_void_in(plane) & noc_data_void_in(plane);
    noc_data_void_out(plane)     <= noc_data_void_out_s(plane)(3 downto 0);
    noc_io_data_void_out(plane) <= noc_data_void_out_s(plane)(4);
  end generate connections_generation;

  sync_noc_set_io: sync_noc_set
  generic map (
     PORTS    => ROUTER_PORTS,
     HAS_SYNC => HAS_SYNC )
   port map (
     clk                => sys_clk_int,
     clk_tile           => clk,
     rst                => sys_rstn,
     rst_tile           => dco_rstn,
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

  -----------------------------------------------------------------------------
  -- Tile
  -----------------------------------------------------------------------------
  tile_io_1 : tile_io
    generic map (
      SIMULATION   => SIMULATION,
      this_has_dco => 0
    )
    port map (
      raw_rstn           => raw_rstn,
      tile_rst           => rst,
      clk                => clk,    -- Local DCO clock
      refclk_noc         => refclk_noc,  -- Backup NoC clock when DCO is enabled
      pllclk_noc         => pllclk_noc,  -- NoC DCO clock out
      refclk             => refclk,    -- Local backup ext clock
      pllbypass          => pllbypass,  --ext_clk_sel,
      pllclk             => pllclk,    -- DCO clock monitor
      dco_clk            => dco_clk,    -- Local DCO clock out (fixed @ TILE_FREQ)
      dco_rstn           => dco_rstn,
      local_x            => this_local_x,
      local_y            => this_local_y,
      -- Ethernet MDC Scaler configuration
      mdcscaler          => mdcscaler,
      -- Ethernet
      eth0_apbi          => eth0_apbi,
      eth0_apbo          => eth0_apbo,
      sgmii0_apbi        => sgmii0_apbi,
      sgmii0_apbo        => sgmii0_apbo,
      eth0_ahbmi         => eth0_ahbmi,
      eth0_ahbmo         => eth0_ahbmo,
      edcl_ahbmo         => edcl_ahbmo,
      -- DVI
      dvi_apbi           => dvi_apbi,
      dvi_apbo           => dvi_apbo,
      dvi_ahbmi          => dvi_ahbmi,
      dvi_ahbmo          => dvi_ahbmo,
      -- UART
      uart_rxd           => uart_rxd,
      uart_txd           => uart_txd,
      uart_ctsn          => uart_ctsn,
      uart_rtsn          => uart_rtsn,
      -- I/O link
      iolink_data_oen    => open,
      iolink_data_in     => (others => '0'),
      iolink_data_out    => open,
      iolink_valid_in    => '0',
      iolink_valid_out   => open,
      iolink_clk_in      => '0',
      iolink_clk_out     => open,
      iolink_credit_in   => '0',
      iolink_credit_out  => open,
      -- Pad configuration
      pad_cfg            => open,
      -- NOC
      sys_clk_out        => sys_clk_out,  -- Global NoC clock out
      sys_clk_lock       => sys_clk_lock,
      noc_mon_noc_vec   => noc_mon_noc_vec_int,
      test_output_port   => test_output_port_s,
      test_data_void_out => test_data_void_out_s,
      test_stop_in       => test_stop_out_s,
      test_input_port    => test_input_port_s,
      test_data_void_in  => test_data_void_in_s,
      test_stop_out      => test_stop_in_s,
      mon_dvfs            => mon_dvfs,
      freq_data_out         => freq_data_out,    -- number describing freq
      freq_empty_out        => freq_empty_out  -- validity signal for freqs
      );

end;
