------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    tile_empty.vhd
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

entity tile_empty is
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

end;

architecture rtl of tile_empty is

  -- Tile synchronous reset
  signal rst : std_ulogic;

  -- DCO
  signal dco_en       : std_ulogic;
  signal dco_clk_sel  : std_ulogic;
  signal dco_cc_sel   : std_logic_vector(5 downto 0);
  signal dco_fc_sel   : std_logic_vector(5 downto 0);
  signal dco_div_sel  : std_logic_vector(2 downto 0);
  signal dco_freq_sel : std_logic_vector(1 downto 0);
  signal dco_clk_lock : std_ulogic;
  signal dco_clk_int  : std_ulogic;

  -- Queues
  signal apb_rcv_rdreq    : std_ulogic;
  signal apb_rcv_data_out : misc_noc_flit_type;
  signal apb_rcv_empty    : std_ulogic;
  signal apb_snd_wrreq    : std_ulogic;
  signal apb_snd_data_in  : misc_noc_flit_type;
  signal apb_snd_full     : std_ulogic;

  -- Bus
  signal apbi           : apb_slv_in_type;
  signal apbo           : apb_slv_out_vector;

  -- Mon
  signal mon_dvfs_int         : monitor_dvfs_type;
  signal mon_noc              : monitor_noc_vector(1 to num_noc_planes);

  attribute keep              : string;

  -- Tile parameters
  signal tile_config : std_logic_vector(ESP_CSR_WIDTH - 1 downto 0);

  signal tile_id : integer range 0 to CFG_TILES_NUM - 1;

  signal this_csr_pindex        : integer range 0 to NAPBSLV - 1;
  signal this_csr_pconfig       : apb_config_type;

  signal this_local_y : local_yx;
  signal this_local_x : local_yx;

  constant this_local_apb_en : std_logic_vector(0 to NAPBSLV - 1) := (
    0 => '1',                           -- CSRs
    others => '0');

begin

  local_x <= this_local_x;
  local_y <= this_local_y;

  -- DCO Reset synchronizer
  dco_clk <= dco_clk_int;

  rst_gen: if this_has_dco /= 0 generate
    tile_rstn : rstgen
      generic map (acthigh => 1, syncin => 0)
      port map (tile_rst, dco_clk_int, dco_clk_lock, rst, open);
  end generate rst_gen;

  no_rst_gen: if this_has_dco = 0 generate
    rst <= tile_rst;
  end generate no_rst_gen;

  dco_rstn <= rst;

  -- DCO
  dco_gen: if this_has_dco /= 0 generate

    dco_i: dco
      generic map (
        tech => CFG_FABTECH,
        enable_div2 => 0,
        dlog => 9)                      -- come out of reset after NoC, but
                                        -- before tile_io.
      port map (
        rstn     => raw_rstn,
        ext_clk  => refclk,
        en       => dco_en,
        clk_sel  => dco_clk_sel,
        cc_sel   => dco_cc_sel,
        fc_sel   => dco_fc_sel,
        div_sel  => dco_div_sel,
        freq_sel => dco_freq_sel,
        clk      => dco_clk_int,
        clk_div  => pllclk,
        lock     => dco_clk_lock);

    dco_freq_sel <= tile_config(ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 0  downto ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 0  - 1);
    dco_div_sel  <= tile_config(ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 2  downto ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 2  - 2);
    dco_fc_sel   <= tile_config(ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 5  downto ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 5  - 5);
    dco_cc_sel   <= tile_config(ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 11 downto ESP_CSR_DCO_CFG_MSB - DCO_CFG_LPDDR_CTRL_BITS - 11 - 5);
    dco_clk_sel  <= tile_config(ESP_CSR_DCO_CFG_LSB + 1);
    dco_en       <= raw_rstn and tile_config(ESP_CSR_DCO_CFG_LSB);

  end generate dco_gen;

  no_dco_gen: if this_has_dco = 0 generate
    pllclk       <= '0';
    dco_clk_int  <= refclk;
    dco_clk_lock <= '1';
  end generate no_dco_gen;

  -----------------------------------------------------------------------------
  -- Tile parameters
  -----------------------------------------------------------------------------
  tile_id                <= to_integer(unsigned(tile_config(ESP_CSR_TILE_ID_MSB downto ESP_CSR_TILE_ID_LSB)));
  pad_cfg                <= tile_config(ESP_CSR_PAD_CFG_MSB downto ESP_CSR_PAD_CFG_LSB);

  this_csr_pindex        <= tile_csr_pindex(tile_id);
  this_csr_pconfig       <= fixed_apbo_pconfig(this_csr_pindex);

  this_local_y           <= tile_y(tile_id);
  this_local_x           <= tile_x(tile_id);

  -----------------------------------------------------------------------------
  -- Buse
  -----------------------------------------------------------------------------
  -- Unused APB ports
  no_apb : for i in 0 to NAPBSLV - 1 generate
    local_apb : if this_local_apb_en(i) = '0' generate
      apbo(i)      <= apb_none;
      apbo(i).pirq <= (others => '0');
    end generate local_apb;
  end generate no_apb;

  -----------------------------------------------------------------------------
  -- Services
  -----------------------------------------------------------------------------

  -- APB
  noc2apb_1 : noc2apb
    generic map (
      tech         => CFG_FABTECH,
      local_apb_en => this_local_apb_en)
    port map (
      rst              => rst,
      clk              => clk,
      local_y          => this_local_y,
      local_x          => this_local_x,
      apbi             => apbi,
      apbo             => apbo,
      pready           => '1',
      dvfs_transient   => '0',
      apb_snd_wrreq    => apb_snd_wrreq,
      apb_snd_data_in  => apb_snd_data_in,
      apb_snd_full     => apb_snd_full,
      apb_rcv_rdreq    => apb_rcv_rdreq,
      apb_rcv_data_out => apb_rcv_data_out,
      apb_rcv_empty    => apb_rcv_empty);

  --Monitors
  mon_dvfs_int.vf        <= (others => '0');
  mon_dvfs_int.clk       <= clk;
  mon_dvfs_int.acc_idle  <= '0';
  mon_dvfs_int.traffic   <= '0';
  mon_dvfs_int.burst     <= '0';
  mon_dvfs_int.transient <= '0';
  mon_dvfs_out           <= mon_dvfs_int;

  mon_noc <= noc_mon_noc_vec;

  --Memory mapped registers
 empty_tile_csr : esp_tile_csr
    generic map(
      pindex => 0)
   port map(
     clk => clk,
     rstn => rst,
     pconfig => this_csr_pconfig,
     mon_ddr => monitor_ddr_none,
     mon_mem => monitor_mem_none,
     mon_noc => mon_noc,
     mon_l2 => monitor_cache_none,
     mon_llc => monitor_cache_none,
     mon_acc => monitor_acc_none,
     mon_dvfs => mon_dvfs_int,
     tile_config => tile_config,
     srst => open,
     apbi => apbi,
     apbo => apbo(0),
     freq_data   => open  -- number associated to the frequency
 );


  -----------------------------------------------------------------------------
  -- Tile queues
  -----------------------------------------------------------------------------
  -- let's try to collapse all noc planes into one!
  queue_single_plane: if num_noc_planes = 1 generate
    empty_tile_q_1 : empty_tile_q_1plane
      generic map (
        tech => CFG_FABTECH)
      port map (
        rst                        => rst,
        clk                        => clk,
        apb_snd_wrreq              => apb_snd_wrreq,
        apb_snd_data_in            => apb_snd_data_in,
        apb_snd_full               => apb_snd_full,
        apb_rcv_rdreq              => apb_rcv_rdreq,
        apb_rcv_data_out           => apb_rcv_data_out,
        apb_rcv_empty              => apb_rcv_empty,
        noc1_out_data              => test_output_port(0),
        noc1_out_void              => test_data_void_out(0),
        noc1_out_stop              => test_stop_out(0),
        noc1_in_data               => test_input_port(0),
        noc1_in_void               => test_data_void_in(0),
        noc1_in_stop               => test_stop_in(0));
  end generate queue_single_plane;

  queue_multi_plane: if num_noc_planes = 6 generate
    empty_tile_q_1 : empty_tile_q
      generic map (
        tech => CFG_FABTECH)
      port map (
        rst                        => rst,
        clk                        => clk,
        apb_snd_wrreq              => apb_snd_wrreq,
        apb_snd_data_in            => apb_snd_data_in,
        apb_snd_full               => apb_snd_full,
        apb_rcv_rdreq              => apb_rcv_rdreq,
        apb_rcv_data_out           => apb_rcv_data_out,
        apb_rcv_empty              => apb_rcv_empty,
        noc_out_data              => test_output_port,
        noc_out_void              => test_data_void_out,
        noc_out_stop              => test_stop_out,
        noc_in_data               => test_input_port,
        noc_in_void               => test_data_void_in,
        noc_in_stop               => test_stop_in);
  end generate queue_multi_plane;
end;
