------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    tiles_fpga_pkg.vhd
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
use ieee.numeric_std.all;

use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.monitor_pkg.all;
use work.esp_csr_pkg.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.socmap.all;

package tiles_fpga_pkg is

  component fpga_tile_cpu is
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_cache          : out monitor_cache_type;
      mon_dvfs_in        : in  monitor_dvfs_type;
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  -- input freq data
      freq_empty_in      : in std_logic -- freq data empty
      );
  end component fpga_tile_cpu;

  component fpga_tile_acc is
    generic (
      SIMULATION  :  boolean := false;  -- need this bool for pll library mismatch
      this_hls_conf      : hlscfg_t             := 0;
      this_device        : devid_t              := 0;
      this_irq_type      : integer              := 0;
      this_has_l2        : integer range 0 to 1 := 0;
      this_has_dvfs      : integer range 0 to 1 := 0;
      this_has_pll       : integer range 0 to 1 := 0;
      this_extra_clk_buf : integer range 0 to 1 := 0;
      ROUTER_PORTS       : ports_vec            := "11111";
      HAS_SYNC           : integer range 0 to 1 := 1;
      this_clock_domain  : integer := 0; -- clock domain of this tile
      pll_clk_freq       : integer range 0 to 10 := 0; -- clock frequency that must be returned from the pll (1=max, 10=min)
      this_tile_id       : integer range 0 to CFG_TILES_NUM := 0 --
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_dvfs_in        : in  monitor_dvfs_type;
      --Monitor signals
      mon_acc            : out monitor_acc_type;
      mon_cache          : out monitor_cache_type;
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  -- input freq data
      freq_empty_in      : in std_logic -- freq data empty
      );
  end component fpga_tile_acc;

  component fpga_tile_io is
    generic (
      SIMULATION   : boolean              := false;
      ROUTER_PORTS : ports_vec            := "11111";
      HAS_SYNC     : integer range 0 to 1 := 1
    );
    port (
      raw_rstn           : in  std_ulogic;
      rst                : in  std_ulogic;
      clk                : in  std_ulogic;
      refclk_noc         : in  std_ulogic;
      pllclk_noc         : out std_ulogic;
      refclk             : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  -- bringing internal lock to the top module
      dco_clk            : out std_ulogic;
      -- Test interface
      tdi                : in  std_logic;
      tdo                : out std_logic;
      tms                : in  std_logic;
      tclk               : in  std_logic;
      -- Ethernet MDC Scaler configuration
      mdcscaler          : out integer range 0 to 2047;
      -- I/O bus interfaces
      eth0_apbi          : out apb_slv_in_type;
      eth0_apbo          : in  apb_slv_out_type;
      sgmii0_apbi        : out apb_slv_in_type;
      sgmii0_apbo        : in  apb_slv_out_type;
      eth0_ahbmi         : out ahb_mst_in_type;
      eth0_ahbmo         : in  ahb_mst_out_type;
      edcl_ahbmo         : in  ahb_mst_out_type;
      dvi_apbi           : out apb_slv_in_type;
      dvi_apbo           : in  apb_slv_out_type;
      dvi_ahbmi          : out ahb_mst_in_type;
      dvi_ahbmo          : in  ahb_mst_out_type;
      uart_rxd           : in  std_ulogic;
      uart_txd           : out std_ulogic;
      uart_ctsn          : in  std_ulogic;
      uart_rtsn          : out std_ulogic;
      -- NOC
      sys_clk_int        : in  std_ulogic;
      sys_rstn           : in  std_ulogic;
      sys_clk_out        : out std_ulogic;
      sys_clk_lock       : out std_ulogic;
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_out       : out freq_reg_t;    -- number describing freq
      freq_empty_out      : out std_logic_vector(domains_num - 1 downto 0)  -- validity signal for freqs
      );
  end component fpga_tile_io;

  component fpga_tile_mem is
    generic (
      SIMULATION   : boolean  := false;
      ROUTER_PORTS : ports_vec := "11111";
      HAS_SYNC     : integer range 0 to 1 := 1);
    port (
      raw_rstn           : in  std_ulogic;
      rst                : in  std_ulogic;
      refclk             : in  std_ulogic;
      clk                : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  -- bringing internal lock to the top module
      dco_clk            : out std_ulogic;
      -- DDR controller ports (this_has_ddr -> 1)
      dco_clk_div2       : out std_ulogic;
      dco_clk_div2_90    : out std_ulogic;
      ddr_ahbsi          : out ahb_slv_in_type;
      ddr_ahbso          : in  ahb_slv_out_type;
      ddr_cfg0           : out std_logic_vector(31 downto 0);
      ddr_cfg1           : out std_logic_vector(31 downto 0);
      ddr_cfg2           : out std_logic_vector(31 downto 0);
      mem_id             : out integer range 0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1;
      -- FPGA proxy memory link (this_has_ddr -> 0)
      fpga_data_in       : in  std_logic_vector(ARCH_BITS - 1 downto 0);
      fpga_data_out      : out std_logic_vector(ARCH_BITS - 1 downto 0);
      fpga_oen           : out std_ulogic;
      fpga_valid_in      : in  std_ulogic;
      fpga_valid_out     : out std_ulogic;
      fpga_clk_in        : in  std_ulogic;
      fpga_clk_out       : out std_ulogic;
      fpga_credit_in     : in  std_ulogic;
      fpga_credit_out    : out std_ulogic;
      -- Test interface
      tdi                : in  std_logic;
      tdo                : out std_logic;
      tms                : in  std_logic;
      tclk               : in  std_logic;
      -- NOC
      sys_clk_int        : in  std_logic;
      rst_noc           : in std_logic;  -- reset for the NoC
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_mem            : out monitor_mem_type;
      mon_cache          : out monitor_cache_type;
      mon_dvfs           : out monitor_dvfs_type);
  end component fpga_tile_mem;

  component fpga_tile_empty is
    generic (
      SIMULATION   : boolean              := false;
      ROUTER_PORTS : ports_vec            := "11111";
      HAS_SYNC     : integer range 0 to 1 := 1);
    port (
      raw_rstn           : in  std_ulogic;
      rst                : in  std_logic;
      clk                : in  std_logic;
      refclk             : in  std_ulogic;
      icclk             : in    std_logic; -- a variable clock for the interconnect resources
      icrst              : in std_logic; -- reset for interconnect resources inside the tile
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  -- bringing internal lock to the top module
      dco_clk            : out std_ulogic;
      -- Test interface
      tdi                : in  std_logic;
      tdo                : out std_logic;
      tms                : in  std_logic;
      tclk               : in  std_logic;
      -- NoC
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_dvfs_out       : out monitor_dvfs_type);
  end component fpga_tile_empty;

  component fpga_tile_slm is
    generic (
      SIMULATION   : boolean := false;
      ROUTER_PORTS : ports_vec            := "11111";
      HAS_SYNC     : integer range 0 to 1 := 1);
    port (
      raw_rstn           : in  std_ulogic;
      rst                : in  std_ulogic;
      clk                : in  std_ulogic;
      refclk             : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  -- bringing internal lock to the top module
      dco_clk            : out std_ulogic;
      -- DDR controller ports (this_has_ddr -> 1)
      dco_clk_div2       : out std_ulogic;
      dco_clk_div2_90    : out std_ulogic;
      ddr_ahbsi          : out ahb_slv_in_type;
      ddr_ahbso          : in  ahb_slv_out_type;
      ddr_cfg0           : out std_logic_vector(31 downto 0);
      ddr_cfg1           : out std_logic_vector(31 downto 0);
      ddr_cfg2           : out std_logic_vector(31 downto 0);
      slmddr_id          : out integer range 0 to SLMDDR_ID_RANGE_MSB;
      -- Test interface
      tdi                : in  std_logic;
      tdo                : out std_logic;
      tms                : in  std_logic;
      tclk               : in  std_logic;
      -- NoC
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
      noc_mon_noc_vec   : out monitor_noc_vector;
      mon_mem            : out monitor_mem_type;
      mon_dvfs           : out monitor_dvfs_type);
  end component fpga_tile_slm;

end tiles_fpga_pkg;
