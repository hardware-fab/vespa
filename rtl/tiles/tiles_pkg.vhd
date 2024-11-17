------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    tiles_pkg.vhd
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

package tiles_pkg is

  component esp is
    generic (
      SIMULATION : boolean := false);
    port (
      rst                : in  std_logic;
      base_rst           : in    std_logic;  --  a reset for clocking resources
      refclk             : in  std_logic;
      icclk              : in    std_logic; --  a variable clock for the interconnect resources
      icrst              : in    std_logic; --  reset synchronized with the icclk
      pllbypass          : in  std_logic_vector(CFG_TILES_NUM - 1 downto 0);
      pll_locked_global  : out std_logic;  --  bringing internal lock to the top module
      uart_rxd           : in  std_logic;
      uart_txd           : out std_logic;
      uart_ctsn          : in  std_logic;
      uart_rtsn          : out std_logic;
      cpuerr             : out   std_logic;
      ddr_ahbsi          : out ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
      ddr_ahbso          : in  ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);
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
      mon_noc            : out monitor_noc_matrix(1 to 6, 0 to CFG_TILES_NUM-1);
      mon_acc            : out monitor_acc_vector(0 to relu(accelerators_num-1));
      mon_mem            : out monitor_mem_vector(0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1);
      mon_l2             : out monitor_cache_vector(0 to relu(CFG_NL2 - 1));
      mon_llc            : out monitor_cache_vector(0 to relu(CFG_NLLC - 1));
      mon_dvfs           : out monitor_dvfs_vector(0 to CFG_TILES_NUM-1);
      freq_data_out     : out std_logic_vector(GM_FREQ_DW-1 downto 0);  --  input freq data
      freq_empty_out    : out std_logic --  freq data empty
      );
  end component esp;

  component tile_cpu is
    generic (
      SIMULATION         : boolean              := false;
      this_has_dvfs      : integer range 0 to 1 := 0;
      this_has_pll       : integer range 0 to 1 := 0;
      this_has_dco       : integer range 0 to 1 := 0;
      this_extra_clk_buf : integer range 0 to 1 := 0;
      this_clock_domain  : integer := 0; --  clock domain of this tile
      pll_clk_freq       : integer range 0 to 10 := 0 --  clock frequency that must be returned from the pll (1=max, 10=min)
    );
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_ulogic;
      base_rst           : in    std_logic;  --  a reset for clocking resources
      refclk             : in  std_ulogic;
      icclk             : in    std_logic; --  a variable clock for the interconnect resources
      icrst              : in std_logic; --  reset for interconnect resources inside the tile
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  --  bringing internal lock to the top module
      pll_lck_glb        : in std_logic;  --  bringing global lock to the local reset generator
      dco_clk            : out std_ulogic;
      dco_rstn           : out std_ulogic;
      cpuerr             : out std_ulogic;
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NOC
      local_x            : out local_yx;
      local_y            : out local_yx;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_cache          : out monitor_cache_type;
      mon_dvfs_in        : in  monitor_dvfs_type;
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  --  input freq data
      freq_empty_in      : in std_logic --  freq data empty
      );
  end component tile_cpu;

  component tile_acc is
    generic (
      SIMULATION  :  boolean := false;  --  need this bool for pll library mismatch
      this_hls_conf      : hlscfg_t             := 0;
      this_device        : devid_t              := 0;
      this_irq_type      : integer              := 0;
      this_has_l2        : integer range 0 to 1 := 0;
      this_has_dvfs      : integer range 0 to 1 := 0;
      this_has_pll       : integer range 0 to 1 := 0;
      this_has_dco       : integer range 0 to 1 := 0;
      this_extra_clk_buf : integer range 0 to 1 := 0;
      this_clock_domain  : integer := 0; --  clock domain of this tile
      pll_clk_freq       : integer range 0 to 10 := 0; --  clock frequency that must be returned from the pll (1=max, 10=min)
      this_tile_id       : integer range 0 to CFG_TILES_NUM := 0 
    );
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_ulogic;
      base_rst           : in    std_logic;  --  a reset for clocking resources
      refclk             : in  std_ulogic;
      icclk             : in    std_logic; --  a variable clock for the interconnect resources
      icrst              : in std_logic; --  reset for interconnect resources inside the tile
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      pll_locked         : out std_logic;  --  bringing internal lock to the top module
      pll_lck_glb        : in std_logic;  --  bringing global lock to the local reset generator
      dco_clk            : out std_ulogic;
      dco_rstn           : out std_ulogic;
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NOC
      local_x            : out local_yx;
      local_y            : out local_yx;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_dvfs_in        : in  monitor_dvfs_type;
      --Monitor signals
      mon_acc            : out monitor_acc_type;
      mon_cache          : out monitor_cache_type;
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_in       : in std_logic_vector(GM_FREQ_DW-1 downto 0);  --  input freq data
      freq_empty_in      : in std_logic --  freq data empty
      );
  end component tile_acc;

  component tile_io is
    generic (
      SIMULATION   : boolean              := false;
      this_has_dco : integer range 0 to 2 := 0
    );
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_ulogic;
      clk                : in  std_ulogic;
      refclk_noc         : in  std_ulogic;
      pllclk_noc         : out std_ulogic;
      refclk             : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      dco_clk            : out std_ulogic;
      dco_rstn           : out std_ulogic;
      local_x            : out local_yx;
      local_y            : out local_yx;
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
      -- I/O link
      iolink_data_oen   : out std_logic;
      iolink_data_in    : in  std_logic_vector(CFG_IOLINK_BITS - 1 downto 0);
      iolink_data_out   : out std_logic_vector(CFG_IOLINK_BITS - 1 downto 0);
      iolink_valid_in   : in  std_ulogic;
      iolink_valid_out  : out std_ulogic;
      iolink_clk_in     : in  std_ulogic;
      iolink_clk_out    : out std_ulogic;
      iolink_credit_in  : in  std_ulogic;
      iolink_credit_out : out std_ulogic;
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NOC
      sys_clk_out        : out std_ulogic;
      sys_clk_lock       : out std_ulogic;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_dvfs           : out monitor_dvfs_type;
      freq_data_out       : out freq_reg_t;    --  number describing freq
      freq_empty_out      : out std_logic_vector(domains_num - 1 downto 0)  --  validity signal for freqs
    );
  end component tile_io;

  component tile_mem is
    generic (
      SIMULATION   : boolean := false;
      this_has_dco : integer range 0 to 1 := 0;
      this_has_ddr : integer range 0 to 1 := 1;
      dco_rst_cfg  : std_logic_vector(30 downto 0) := (others => '0'));
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_ulogic;
      refclk             : in  std_ulogic;
      clk                : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      dco_clk            : out std_ulogic;
      -- DDR controller ports (this_has_ddr -> 1)
      dco_clk_div2       : out std_ulogic;
      dco_clk_div2_90    : out std_ulogic;
      dco_rstn           : out std_ulogic;
      phy_rstn           : out std_ulogic;
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
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NOC
      local_x            : out local_yx;
      local_y            : out local_yx;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_mem            : out monitor_mem_type;
      mon_cache          : out monitor_cache_type;
      mon_dvfs           : out monitor_dvfs_type);
  end component tile_mem;

  component tile_empty is
    generic (
      SIMULATION   : boolean              := false;
      this_has_dco : integer range 0 to 1 := 0);
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_logic;
      clk                : in  std_logic;
      refclk             : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      dco_clk            : out std_ulogic;
      dco_rstn           : out std_ulogic;
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NoC
      local_x            : out local_yx;
      local_y            : out local_yx;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_dvfs_out       : out monitor_dvfs_type);
  end component tile_empty;

  component tile_slm is
    generic (
      SIMULATION   : boolean := false;
      this_has_dco : integer range 0 to 1 := 0;
      this_has_ddr : integer range 0 to 1 := 0;
      dco_rst_cfg  : std_logic_vector(30 downto 0) := (others => '0'));
    port (
      raw_rstn           : in  std_ulogic;
      tile_rst           : in  std_ulogic;
      clk                : in  std_ulogic;
      refclk             : in  std_ulogic;
      pllbypass          : in  std_ulogic;
      pllclk             : out std_ulogic;
      dco_clk            : out std_ulogic;
      -- DDR controller ports (this_has_ddr -> 1)
      dco_clk_div2       : out std_ulogic;
      dco_clk_div2_90    : out std_ulogic;
      dco_rstn           : out std_ulogic;
      phy_rstn           : out std_ulogic;
      ddr_ahbsi          : out ahb_slv_in_type;
      ddr_ahbso          : in  ahb_slv_out_type;
      ddr_cfg0           : out std_logic_vector(31 downto 0);
      ddr_cfg1           : out std_logic_vector(31 downto 0);
      ddr_cfg2           : out std_logic_vector(31 downto 0);
      slmddr_id          : out integer range 0 to SLMDDR_ID_RANGE_MSB;
      -- Pads configuration
      pad_cfg            : out std_logic_vector(ESP_CSR_PAD_CFG_MSB - ESP_CSR_PAD_CFG_LSB downto 0);
      -- NoC
      local_x            : out local_yx;
      local_y            : out local_yx;
      noc_mon_noc_vec   : in monitor_noc_vector(num_noc_planes-1 downto 0);
      test_output_port   : in noc_flit_vector;
      test_data_void_out : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_in       : in std_ulogic_vector(num_noc_planes-1 downto 0);
      test_input_port    : out noc_flit_vector;
      test_data_void_in  : out std_ulogic_vector(num_noc_planes-1 downto 0);
      test_stop_out      : out std_ulogic_vector(num_noc_planes-1 downto 0);
      mon_mem            : out monitor_mem_type;
      mon_dvfs           : out monitor_dvfs_type);
  end component tile_slm;

end tiles_pkg;
