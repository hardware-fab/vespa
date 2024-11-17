------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    esp.vhd
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
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;  
use work.esp_global.all;
use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;
use work.gencomp.all;
use work.leon3.all;
use work.net.all;
-- pragma translate_off
use work.sim.all;
library unisim;
use unisim.all;
-- pragma translate_on
use work.monitor_pkg.all;
use work.sldacc.all;
use work.tile.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.coretypes.all;
use work.grlib_config.all;
use work.socmap.all;
use work.tiles_pkg.all;
use work.tiles_fpga_pkg.all;

use work.misc.all; -- I need this library for the rstgen
use work.esp_csr_pkg.all; -- I need this library for freq data info
entity esp is
  generic (
    SIMULATION : boolean := false);
  port (
    rst               : in    std_logic;
    base_rst          : in    std_logic;  -- a reset for clocking resources
    refclk            : in    std_logic;
    icclk             : in    std_logic; -- a variable clock for the interconnect resources
    icrst             : in    std_logic; -- reset synchronized with the icclk
    pllbypass         : in    std_logic_vector(CFG_TILES_NUM - 1 downto 0);
    pll_locked_global : out   std_logic;  -- bringing internal lock to the top module
    uart_rxd          : in    std_logic;  -- UART1_RX (u1i.rxd)
    uart_txd          : out   std_logic;  -- UART1_TX (u1o.txd)
    uart_ctsn         : in    std_logic;  -- UART1_RTSN (u1i.ctsn)
    uart_rtsn         : out   std_logic;  -- UART1_RTSN (u1o.rtsn)
    cpuerr            : out   std_logic;
    ddr_ahbsi         : out ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
    ddr_ahbso         : in  ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);
    eth0_apbi         : out apb_slv_in_type;
    eth0_apbo         : in  apb_slv_out_type;
    sgmii0_apbi       : out apb_slv_in_type;
    sgmii0_apbo       : in  apb_slv_out_type;
    eth0_ahbmi        : out ahb_mst_in_type;
    eth0_ahbmo        : in  ahb_mst_out_type;
    edcl_ahbmo        : in  ahb_mst_out_type;
    dvi_apbi          : out apb_slv_in_type;
    dvi_apbo          : in  apb_slv_out_type;
    dvi_ahbmi         : out ahb_mst_in_type;
    dvi_ahbmo         : in  ahb_mst_out_type;
    mon_noc           : out monitor_noc_matrix(1 to 6, 0 to CFG_TILES_NUM-1);
    mon_acc           : out monitor_acc_vector(0 to relu(accelerators_num-1));
    mon_mem           : out monitor_mem_vector(0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1);
    mon_l2            : out monitor_cache_vector(0 to relu(CFG_NL2 - 1));
    mon_llc           : out monitor_cache_vector(0 to relu(CFG_NLLC - 1));
    mon_dvfs          : out monitor_dvfs_vector(0 to CFG_TILES_NUM-1);
    freq_data_out     : out std_logic_vector(GM_FREQ_DW-1 downto 0);  -- input freq data
    freq_empty_out    : out std_logic -- freq data empty
    );
end;


architecture rtl of esp is


--constant nocs_num : integer := 6;

--GM note: questo è l'output clock di ogni tile dotato di PLL
--Sembra che questo clock possa assumere i valori di 61.5, 80, 88.8 e 100MHz (in realtà sono dimezzati).
signal clk_tile : std_logic_vector(CFG_TILES_NUM-1 downto 0);
type noc_ctrl_matrix is array (1 to num_noc_planes) of std_logic_vector(CFG_TILES_NUM-1 downto 0);
type handshake_vec is array (CFG_TILES_NUM-1 downto 0) of std_logic_vector(3 downto 0);

signal rst_int       : std_logic;
--GM note: questo è l'input clock di ogni tile
signal refclk_int    : std_logic_vector(CFG_TILES_NUM -1 downto 0);
signal pllbypass_int : std_logic_vector(CFG_TILES_NUM - 1 downto 0);
signal cpuerr_vec    : std_logic_vector(0 to CFG_NCPU_TILE-1);

type monitor_noc_cast_vector is array (0 to CFG_TILES_NUM-1) of monitor_noc_vector(1 to num_noc_planes);
signal mon_noc_vec : monitor_noc_cast_vector;
signal mon_dvfs_out : monitor_dvfs_vector(0 to CFG_TILES_NUM-1);
signal mon_dvfs_domain  : monitor_dvfs_vector(0 to CFG_TILES_NUM-1);

signal mon_l2_int : monitor_cache_vector(0 to CFG_TILES_NUM-1);
signal mon_llc_int : monitor_cache_vector(0 to CFG_TILES_NUM-1);

-- NOC Signals ( collapsed everything into matrices)
signal noc_data_n_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_s_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_w_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_e_in       : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_void_in    : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_stop_in         : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_n_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_s_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_w_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_e_out      : noc_flit_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_data_void_out   : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);
signal noc_stop_out        : partial_handshake_matrix(CFG_TILES_NUM-1 downto 0);


-- my signals
signal pll_locked : std_logic_vector(CFG_TILES_NUM-1 downto 0);
signal pll_lck_glb_int : std_logic;
signal rst_local, rst_local_rstgen : std_logic_vector(CFG_TILES_NUM-1 downto 0);
--signal rst_ic, rst_ic_rstgen : std_logic;
signal freq_data : freq_reg_t;
signal freq_empty : std_logic_vector(domains_num-1 downto 0);
--signal mon_transit : monitor_transit_matrix(0 to nocs_num-1, 0 to CFG_TILES_NUM-1);
--constant REGISTER_WIDTH : integer := 32;
--signal count_transit_inj, count_transit_inj_sync := transit_count_type;
--signal count_transit_ej, count_transit_ej_sync := transit_count_type;

-- need the synchronizer to connect nocs with different freqs
component synchronizer is
  generic (
    DATA_WIDTH : integer
    );
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0));
end component;

-- a stupid function 'cause VHDL doesn't accept conditional constant declaration...
function check_resync(tile_domain:integer; noc_domain:integer)
return integer is
begin
  if tile_domain = noc_domain then
      return 0;
  else
      return 1;
  end if;
end function;
begin

  -- here it generates some reset signals that are synchronized with the various clock domains
  sync_rst_gen: for i in 0 to CFG_TILES_NUM-1 generate
    --Generate a reset for each PLL 
    reset_gen: if tile_has_pll(i) = 1 generate
      local_rst: rstgen
        generic map(acthigh => 0, syncin => 0)
        port map (rst, clk_tile(i), pll_lck_glb_int, rst_local_rstgen(i), open);
    end generate reset_gen;

    --Generate a reset for the IO tile, which goes at 50MHz
    reset_io: if i = io_tile_id generate
      local_rst: rstgen
        generic map(acthigh => 0, syncin => 0)
        port map (rst, clk_tile(i), pll_lck_glb_int, rst_local_rstgen(i), open);
    end generate reset_io;

    --If the tile hasn't got a Pll, copy the rst of the domain master
    reset_copy: if tile_has_pll(i) = 0 and tile_domain(i) /= 0 generate
      rst_local_rstgen(i) <= rst_local_rstgen(tile_domain_master(i));
    end generate reset_copy;

    --Clock domain 0 refers to the interconnect clock, so the tile uses its reset
    reset_domain0: if tile_domain(i) = 0  and CFG_HAS_DVFS /= 0 and i /= io_tile_id generate
      rst_local_rstgen(i) <= icrst;
    end generate reset_domain0;

    reset_no_dfs: if CFG_HAS_DVFS = 0 generate
      rst_local_rstgen(i) <= rst;
    end generate reset_no_dfs;

  end generate sync_rst_gen;


  -- simple process to initialize the value of icrst and rst_local
  process (pll_lck_glb_int, rst_local_rstgen)
  begin
    if pll_lck_glb_int = '1' then
      rst_local <= rst_local_rstgen;
    else
      rst_local <= (others => '0');
    end if;
  end process;

  rst_int <= rst;
  pllbypass_int <= pllbypass;

  cpuerr <= cpuerr_vec(0);

  -- bring domain 0 freq info to the top
  freq_data_out     <= freq_data(0);  -- input freq data
  freq_empty_out    <= freq_empty(0); -- freq data empty

  -----------------------------------------------------------------------------
  -- DVFS domain probes steering
  -----------------------------------------------------------------------------
  domain_in_gen: for i in 0 to CFG_TILES_NUM-1 generate
    mon_dvfs_domain(i).clk <= '0';
    mon_dvfs_domain(i).transient <= mon_dvfs_out(tile_domain_master(i)).transient;
    mon_dvfs_domain(i).vf <= mon_dvfs_out(tile_domain_master(i)).vf;

    no_domain_master: if tile_domain(i) /= 0 and tile_has_pll(i) = 0 generate
      mon_dvfs_domain(i).acc_idle <= mon_dvfs_domain(tile_domain_master(i)).acc_idle;
      mon_dvfs_domain(i).traffic <= mon_dvfs_domain(tile_domain_master(i)).traffic;
      mon_dvfs_domain(i).burst <= mon_dvfs_domain(tile_domain_master(i)).burst;
      --GM note: l'input clock di un tile senza PLL di un dominio di clock diverso da quello base è dato dall'output
      --clock del tile dotato di PLL appartenente al relativo dominio di clock
      refclk_int(i) <= clk_tile(tile_domain_master(i));
    end generate no_domain_master;

    --GM note: se un tile ha il PLL o appartiene al dominio di clock principale, il clock di input è il clock principale
    domain_master_gen: if tile_domain(i) = 0 or tile_has_pll(i) /= 0 generate
      refclk_int(i) <= refclk;
    end generate domain_master_gen;

  end generate domain_in_gen;

  domain_probes_gen: for k in 1 to domains_num-1 generate
    -- DVFS masters need info from slave DVFS tiles
    process (mon_dvfs_out)
      variable mon_dvfs_or : monitor_dvfs_type;
    begin  -- process
      mon_dvfs_or.acc_idle := '1';
      mon_dvfs_or.traffic := '0';
      mon_dvfs_or.burst := '0';
      for i in 0 to CFG_TILES_NUM-1 loop
        if tile_domain(i) = k then
          mon_dvfs_or.acc_idle := mon_dvfs_or.acc_idle and mon_dvfs_out(i).acc_idle;
          mon_dvfs_or.traffic := mon_dvfs_or.traffic or mon_dvfs_out(i).traffic;
          mon_dvfs_or.burst := mon_dvfs_or.burst or mon_dvfs_out(i).burst;
        end if;
      end loop;  -- i
      mon_dvfs_domain(domain_master_tile(k)).acc_idle <= mon_dvfs_or.acc_idle;
      mon_dvfs_domain(domain_master_tile(k)).traffic <= mon_dvfs_or.traffic;
      mon_dvfs_domain(domain_master_tile(k)).burst <= mon_dvfs_or.burst;
    end process;
  end generate domain_probes_gen;

  mon_dvfs <= mon_dvfs_out;

  -----------------------------------------------------------------------------
  -- NOC CONNECTIONS
  -----------------------------------------------------------------------------






  meshgen_y: for y in 0 to CFG_YLEN-1 generate
    meshgen_x: for x in 0 to CFG_XLEN-1 generate
      meshgen_noc: for plane in 0 to num_noc_planes-1 generate
        y_0: if (y=0) generate
          -- North port is unconnected
          noc_data_n_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(0) <= '0';
        end generate y_0;

        y_non_0: if (y /= 0) generate
          -- North port is connected

          --Same clock domain: no need for a resync
          no_resync_y_non_0: if (noc_domain(y*CFG_XLEN + x) = noc_domain((y-1)*CFG_XLEN + x)) generate
            noc_data_n_in(y*CFG_XLEN + x)(plane)       <= noc_data_s_out((y-1)*CFG_XLEN + x)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= noc_data_void_out((y-1)*CFG_XLEN + x)(plane)(1);
            noc_stop_in(y*CFG_XLEN + x)(plane)(0)      <= noc_stop_out((y-1)*CFG_XLEN + x)(plane)(1);
          end generate no_resync_y_non_0;

          --Different clock domains: need a resync
          resync_y_non_0: if (noc_domain(y*CFG_XLEN + x) /= noc_domain((y-1)*CFG_XLEN + x)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> south output port of tile (x, y-1)
            clk_wr <= clk_tile(noc_domain_master((y-1)*CFG_XLEN + x));
            rst_wr <= rst_local(noc_domain_master((y-1)*CFG_XLEN + x));
            flit_wr <= noc_data_s_out((y-1)*CFG_XLEN + x)(plane);
            wren <= not noc_data_void_out((y-1)*CFG_XLEN + x)(plane)(1);
            noc_stop_in((y-1)*CFG_XLEN + x)(plane)(1) <= full;
            --Read port -> north input port of tile (x, y)
            clk_rd <= clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_n_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(0);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(0) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_y_non_0;
        end generate y_non_0;

        y_YLEN: if (y=CFG_YLEN-1) generate
          -- South port is unconnected
          noc_data_s_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(1) <= '0';
        end generate y_YLEN;

        y_non_YLEN: if (y /= CFG_YLEN-1) generate
          -- south port is connected

          --Same clock domain: no need for a resync
          no_resync_y_non_YLEN: if (noc_domain(y*CFG_XLEN + x) = noc_domain((y+1)*CFG_XLEN + x)) generate
            noc_data_s_in(y*CFG_XLEN + x)(plane)       <= noc_data_n_out((y+1)*CFG_XLEN + x)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= noc_data_void_out((y+1)*CFG_XLEN + x)(plane)(0);
            noc_stop_in(y*CFG_XLEN + x)(plane)(1)      <= noc_stop_out((y+1)*CFG_XLEN + x)(plane)(0);
          end generate no_resync_y_non_YLEN;

          --Different clock domains: need a resync
          resync_y_non_YLEN: if (noc_domain(y*CFG_XLEN + x) /= noc_domain((y+1)*CFG_XLEN + x)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> north output port of tile (x, y+1)
            clk_wr <= clk_tile(noc_domain_master((y+1)*CFG_XLEN + x));
            rst_wr <= rst_local(noc_domain_master((y+1)*CFG_XLEN + x));
            flit_wr <= noc_data_n_out((y+1)*CFG_XLEN + x)(plane);
            wren <= not noc_data_void_out((y+1)*CFG_XLEN + x)(plane)(0);
            noc_stop_in((y+1)*CFG_XLEN + x)(plane)(0) <= full;
            --Read port -> south input port of tile (x, y)
            clk_rd <= clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_s_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(1);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(1) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_y_non_YLEN;
        end generate y_non_YLEN;

        x_0: if (x=0) generate
          -- West port is unconnected
          noc_data_w_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(2) <= '0';
        end generate x_0;

        x_non_0: if (x /= 0) generate
          -- West port is connected

          --Same clock domain: no need for a resync
          no_resync_x_non_0: if (noc_domain(y*CFG_XLEN + x) = noc_domain(y*CFG_XLEN + x - 1)) generate
            noc_data_w_in(y*CFG_XLEN + x)(plane)      <= noc_data_e_out(y*CFG_XLEN + x - 1)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= noc_data_void_out(y*CFG_XLEN + x - 1)(plane)(3);
            noc_stop_in(y*CFG_XLEN + x)(plane)(2)      <= noc_stop_out(y*CFG_XLEN + x - 1)(plane)(3);
          end generate no_resync_x_non_0;

          --Different clock domains: need a resync
          resync_x_non_0: if (noc_domain(y*CFG_XLEN + x) /= noc_domain(y*CFG_XLEN + x - 1)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> east output port of tile (x-1, y)
            clk_wr <= clk_tile(noc_domain_master(y*CFG_XLEN + x - 1));
            rst_wr <= rst_local(noc_domain_master(y*CFG_XLEN + x - 1));
            flit_wr <= noc_data_e_out(y*CFG_XLEN + x - 1)(plane);
            wren <= not noc_data_void_out(y*CFG_XLEN + x - 1)(plane)(3);
            noc_stop_in(y*CFG_XLEN + x - 1)(plane)(3) <= full;
            --Read port -> west input port of tile (x, y)
            clk_rd <= clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_w_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(2);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(2) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_x_non_0;

        end generate x_non_0;

        x_XLEN: if (x=CFG_XLEN-1) generate
          -- East port is unconnected
          noc_data_e_in(y*CFG_XLEN + x)(plane) <= (others => '0');
          noc_data_void_in(y*CFG_XLEN + x)(plane)(3) <= '1';
          noc_stop_in(y*CFG_XLEN + x)(plane)(3) <= '0';
        end generate x_XLEN;

        x_non_XLEN: if (x /= CFG_XLEN-1) generate
          -- East port is connected

          --Same clock domain: no need for a resync
          no_resync_x_non_XLEN: if (noc_domain(y*CFG_XLEN + x) = noc_domain(y*CFG_XLEN + x + 1)) generate
            noc_data_e_in(y*CFG_XLEN + x)(plane)         <= noc_data_w_out(y*CFG_XLEN + x + 1)(plane);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(3)   <= noc_data_void_out(y*CFG_XLEN + x + 1)(plane)(2);
            noc_stop_in(y*CFG_XLEN + x)(plane)(3)        <= noc_stop_out(y*CFG_XLEN + x + 1)(plane)(2);
          end generate no_resync_x_non_XLEN;

          --Different clock domains: need a resync
          resync_x_non_XLEN: if (noc_domain(y*CFG_XLEN + x) /= noc_domain(y*CFG_XLEN + x + 1)) generate

          signal flit_wr, flit_rd : noc_flit_type;
          signal wren, rden, full, empty : std_logic;
          signal clk_wr, clk_rd, rst_wr, rst_rd : std_logic;

          begin
            --Write port -> west output port of tile (x+1, y)
            clk_wr <= clk_tile(noc_domain_master(y*CFG_XLEN + x + 1));
            rst_wr <= rst_local(noc_domain_master(y*CFG_XLEN + x + 1));
            flit_wr <= noc_data_w_out(y*CFG_XLEN + x + 1)(plane);
            wren <= not noc_data_void_out(y*CFG_XLEN + x + 1)(plane)(2);
            noc_stop_in(y*CFG_XLEN + x + 1)(plane)(2) <= full;
            --Read port -> east input port of tile (x, y)
            clk_rd <= clk_tile(noc_domain_master(y*CFG_XLEN + x));
            rst_rd <= rst_local(noc_domain_master(y*CFG_XLEN + x));
            noc_data_e_in(y*CFG_XLEN + x)(plane) <= flit_rd;
            rden <= not noc_stop_out(y*CFG_XLEN + x)(plane)(3);
            noc_data_void_in(y*CFG_XLEN + x)(plane)(3) <= empty;

            inferred_async_fifo_inst: inferred_async_fifo
                generic map (
                  g_data_width => NOC_FLIT_SIZE,
                  g_size       => 8)
                port map (
                  rst_wr_n_i => rst_wr,
                  clk_wr_i   => clk_wr,
                  we_i       => wren,
                  d_i        => flit_wr,
                  wr_full_o  => full,
                  rst_rd_n_i => rst_rd,
                  clk_rd_i   => clk_rd,
                  rd_i       => rden,
                  q_o        => flit_rd,
                  rd_empty_o => empty);
          end generate resync_x_non_XLEN;
        end generate x_non_XLEN;
      end generate meshgen_noc;
    end generate meshgen_x;
  end generate meshgen_y;


  -----------------------------------------------------------------------------
  -- TILES
  -----------------------------------------------------------------------------
  tiles_gen: for i in 0 to CFG_TILES_NUM - 1  generate
  --constant TILE2NOC_RESYNC : integer := 1 when noc_domain(i) /= tile_domain(i) else 0;
  --begin
    empty_tile: if tile_type(i) = 0 generate
    tile_empty_i: fpga_tile_empty
      generic map (
        SIMULATION   => SIMULATION,
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => CFG_HAS_SYNC) -- empty tile works at 50MHz reference, thus it must always be synchronized
      port map (
        raw_rstn           => '0',
        rst                => rst_local(i), --rst,    -- for the empty module I use the interconnect reset
        clk                => clk_tile(i),
        refclk             => refclk_int(i),
        icclk              => clk_tile(noc_domain_master(i)),--icclk, -- a variable clock for the interconnect resources
        icrst              => rst_local(noc_domain_master(i)), --icrst, -- reset for interconnect resources
        pllbypass          => '0',
        pllclk             => open,
	    pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
        sys_clk_int        => icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
        dco_clk            => open,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
	noc_data_n_in     => noc_data_n_in(i),
	noc_data_s_in     => noc_data_s_in(i),
	noc_data_w_in     => noc_data_w_in(i),
	noc_data_e_in     => noc_data_e_in(i),
	noc_data_void_in  => noc_data_void_in(i),
	noc_stop_in       => noc_stop_in(i),
	noc_data_n_out    => noc_data_n_out(i),
	noc_data_s_out    => noc_data_s_out(i),
	noc_data_w_out    => noc_data_w_out(i),
	noc_data_e_out    => noc_data_e_out(i),
	noc_data_void_out => noc_data_void_out(i),
	noc_stop_out       => noc_stop_out(i),
	noc_mon_noc_vec   => mon_noc_vec(i),
	mon_dvfs_out       => mon_dvfs_out(i));
      clk_tile(i)  <= refclk_int(i);
    end generate empty_tile;


    cpu_tile: if tile_type(i) = 1 generate
-- pragma translate_off
      assert tile_cpu_id(i) /= -1 report "Undefined CPU ID for CPU tile" severity error;
-- pragma translate_on
      tile_cpu_i: fpga_tile_cpu

      generic map (
        SIMULATION         => SIMULATION,
        this_has_dvfs      => tile_has_dvfs(i),
        this_has_pll       => tile_has_pll(i),
        this_extra_clk_buf => extra_clk_buf(i),
        ROUTER_PORTS       => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC           => check_resync(tile_domain(i), noc_domain(i)),--CFG_HAS_SYNC) -- has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        this_clock_domain  => tile_domain(i), -- clock domain of this tile
        pll_clk_freq       => domain_freq(tile_domain(i)) -- clock frequency that must be returned from the pll (1=max, 10=min)
    )
      port map (
        raw_rstn           => '0',
        rst                => rst_local(i), --rst_int,    -- local reset
        base_rst           => base_rst,  -- a reset for clocking resources
        refclk             => refclk_int(i),
        icclk              => clk_tile(noc_domain_master(i)),--icclk, -- a variable clock for the interconnect resources
        icrst              => rst_local(noc_domain_master(i)), --icrst, -- reset for interconnect resources inside the tile
        pllbypass          => pllbypass_int(i),
        pllclk             => clk_tile(i),
        pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
        pll_lck_glb        => pll_lck_glb_int,  -- bringing global lock to the local reset generator 
        dco_clk            => open,
        cpuerr             => cpuerr_vec(tile_cpu_id(i)),
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        sys_clk_int        => clk_tile(noc_domain_master(i)),--icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        mon_cache          => mon_l2_int(i),
        mon_dvfs_in        => mon_dvfs_domain(i),
        mon_dvfs           => mon_dvfs_out(i),
        freq_data_in   => freq_data(tile_domain(i)),  -- input freq data
        freq_empty_in  => freq_empty(tile_domain(i))  -- freq data empty
        );
    end generate cpu_tile;


    accelerator_tile: if tile_type(i) = 2 generate
-- pragma translate_off
      assert tile_device(i) /= 0 report "Undefined device ID for accelerator tile" severity error;
-- pragma translate_on
      tile_acc_i: fpga_tile_acc
      generic map (
        SIMULATION  => SIMULATION,  -- need this bool for pll library mismatch
        this_hls_conf      => tile_design_point(i),
        this_device        => tile_device(i),
        this_irq_type      => tile_irq_type(i),
        this_has_l2        => tile_has_l2(i),
        this_has_dvfs      => tile_has_dvfs(i),
        this_has_pll       => tile_has_pll(i),
        this_extra_clk_buf => extra_clk_buf(i),
        ROUTER_PORTS       => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC           => check_resync(tile_domain(i), noc_domain(i)),--CFG_HAS_SYNC -- has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        this_clock_domain  => tile_domain(i), -- clock domain of this tile
        pll_clk_freq       => domain_freq(tile_domain(i)), -- clock frequency that must be returned from the pll (1=max, 10=min)
        this_tile_id       => i -- why this info is not already passed as parameter???
    )
      port map (
        raw_rstn           => '0',
        rst                => rst_local(i), --rst_int,     -- local reset
        base_rst           => base_rst,  -- a reset for clocking resources
        refclk             => refclk_int(i),
        icclk              => clk_tile(noc_domain_master(i)),--icclk, -- a variable clock for the interconnect resources
        icrst              => rst_local(noc_domain_master(i)),--icrst, -- reset for interconnect resources inside the tile
        pllbypass          => pllbypass_int(i),
        pllclk             => clk_tile(i),
        pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
        pll_lck_glb        => pll_lck_glb_int,  -- bringing global lock to the local reset generator
        dco_clk            => open,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        sys_clk_int        => clk_tile(noc_domain_master(i)),--icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        mon_dvfs_in        => mon_dvfs_domain(i),
        --Monitor signals
        mon_acc            => mon_acc(tile_acc_id(i)),
        mon_cache          => mon_l2_int(i),
        mon_dvfs           => mon_dvfs_out(i),
        freq_data_in   => freq_data(tile_domain(i)),  -- input freq data
        freq_empty_in  => freq_empty(tile_domain(i))  -- freq data empty
        );
    end generate accelerator_tile;


    io_tile: if tile_type(i) = 3 generate
      tile_io_i : fpga_tile_io
      generic map (
        SIMULATION   => SIMULATION,
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => CFG_HAS_SYNC -- IO tile has its own frequency, thus it must always be synchronized
        )
      port map (
        raw_rstn           => base_rst, --'0',  -- I need the base reset for the freq sync
	      rst                => rst_local(i), --rst_int,     -- local reset
	      clk                => refclk_int(i), --icclk,--refclk_int(i),  -- use the interconnect clock (now use the fixed 50MHz clock!)
        refclk_noc         => '0',
        pllclk_noc         => open,
        refclk             => refclk_int(i), --'0',  -- I need the ref clock for frequency data synchronization
        pllbypass          => '0',
        pllclk             => open,
        pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
        dco_clk            => open,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- Ethernet MDC Scaler configuration
        mdcscaler          => open,
        -- I/O bus interfaces
        eth0_apbi          => eth0_apbi,
        eth0_apbo          => eth0_apbo,
        sgmii0_apbi        => sgmii0_apbi,
        sgmii0_apbo        => sgmii0_apbo,
        eth0_ahbmi         => eth0_ahbmi,
        eth0_ahbmo         => eth0_ahbmo,
        edcl_ahbmo         => edcl_ahbmo,
        dvi_apbi           => dvi_apbi,
        dvi_apbo           => dvi_apbo,
        dvi_ahbmi          => dvi_ahbmi,
        dvi_ahbmo          => dvi_ahbmo,
        uart_rxd           => uart_rxd,
        uart_txd           => uart_txd,
        uart_ctsn          => uart_ctsn,
        uart_rtsn          => uart_rtsn,
        -- NOC
        sys_clk_int        => clk_tile(noc_domain_master(i)),--icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
        sys_rstn           => rst_local(noc_domain_master(i)),--icrst, --rst_int,     -- the new NoC clock is the ic clock
        sys_clk_out        => open,
        sys_clk_lock       => open,
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        mon_dvfs           => mon_dvfs_out(i),
        --injection_count     => count_transit_inj_sync,  -- monitor transit statistics
        --ejection_count     => count_transit_ej_sync,  -- monitor transit statistics
        freq_data_out      => freq_data,    -- number describing freq
        freq_empty_out     => freq_empty  -- validity signal for freqs
	);
      clk_tile(i) <= refclk_int(i);
    end generate io_tile;

    mem_tile: if tile_type(i) = 4 generate
      tile_mem_i: fpga_tile_mem
      generic map (
        ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
        HAS_SYNC     => check_resync(tile_domain(i), noc_domain(i)))--CFG_HAS_SYNC) -- has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
      port map (
        raw_rstn           => '0',
	      rst                => rst_local(i), --rst_int,    -- local reset
        refclk             => '0',
	      clk                => icclk, --sys_clk_int(tile_mem_id(i)), --GM_change: use the interconnect clock
        pllbypass          => '0',
        pllclk             => open,
        pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
        dco_clk            => open,
        -- DDR controller ports (this_has_ddr -> 1)
        dco_clk_div2       => open,
        dco_clk_div2_90    => open,
	ddr_ahbsi          => ddr_ahbsi(tile_mem_id(i)),
	ddr_ahbso          => ddr_ahbso(tile_mem_id(i)),
        ddr_cfg0           => open,
        ddr_cfg1           => open,
        ddr_cfg2           => open,
        mem_id             => open,
        -- FPGA proxy memory link (this_has_ddr -> 0)
        fpga_data_in       => (others => '0'),
        fpga_data_out      => open,
        fpga_oen           => open,
        fpga_valid_in      => '0',
        fpga_valid_out     => open,
        fpga_clk_in        => '0',
        fpga_clk_out       => open,
        fpga_credit_in     => '0',
        fpga_credit_out    => open,
        -- Test interface
        tdi                => '0',
        tdo                => open,
        tms                => '0',
        tclk               => '0',
        -- NOC
        sys_clk_int        => clk_tile(noc_domain_master(i)),--icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
        rst_noc           => rst_local(noc_domain_master(i)),    -- reset for the NoC
        noc_data_n_in     => noc_data_n_in(i),
        noc_data_s_in     => noc_data_s_in(i),
        noc_data_w_in     => noc_data_w_in(i),
        noc_data_e_in     => noc_data_e_in(i),
        noc_data_void_in  => noc_data_void_in(i),
        noc_stop_in       => noc_stop_in(i),
        noc_data_n_out    => noc_data_n_out(i),
        noc_data_s_out    => noc_data_s_out(i),
        noc_data_w_out    => noc_data_w_out(i),
        noc_data_e_out    => noc_data_e_out(i),
        noc_data_void_out => noc_data_void_out(i),
        noc_stop_out       => noc_stop_out(i),
        noc_mon_noc_vec   => mon_noc_vec(i),
        mon_mem            => mon_mem(tile_mem_id(i)),
        mon_cache          => mon_llc_int(i),
        mon_dvfs           => mon_dvfs_out(i));
        clk_tile(i) <= icclk; --sys_clk_int(tile_mem_id(i));    set icclk as the master clock of domain 0
    end generate mem_tile;

    slm_tile: if tile_type(i) = 5 generate
      tile_slm_i: fpga_tile_slm
        generic map (
          SIMULATION   => SIMULATION,
          ROUTER_PORTS => set_router_ports(CFG_FABTECH, CFG_XLEN, CFG_YLEN, tile_x(i), tile_y(i)),
          HAS_SYNC     => 1)--check_resync(tile_domain(i), noc_domain(i)))--CFG_HAS_SYNC) -- has_sync now depends on whether the noc and the PE on the same tile have the same clock domain
        port map (
          raw_rstn           => '0',
          rst                => rst_local(i), --rst_int,     -- local reset
          clk                => refclk_int(i),
          refclk             => '0',
          pllbypass          => '0',
          pllclk             => open,
          pll_locked         => pll_locked(i),  -- bringing internal lock to the top module
          dco_clk            => open,
          -- DDR controller ports (disaled in generic ESP top)
          dco_clk_div2       => open,
          dco_clk_div2_90    => open,
          ddr_ahbsi          => open,
          ddr_ahbso          => ahbs_none,
          ddr_cfg0           => open,
          ddr_cfg1           => open,
          ddr_cfg2           => open,
          slmddr_id          => open,
          -- Test interface
          tdi                => '0',
          tdo                => open,
          tms                => '0',
          tclk               => '0',
          -- NOC
          sys_clk_int        => icclk, --sys_clk_int(0),  -- the new NoC clock is the ic clock
          noc_data_n_in     => noc_data_n_in(i),
          noc_data_s_in     => noc_data_s_in(i),
          noc_data_w_in     => noc_data_w_in(i),
          noc_data_e_in     => noc_data_e_in(i),
          noc_data_void_in  => noc_data_void_in(i),
          noc_stop_in       => noc_stop_in(i)(3 downto 0),
          noc_data_n_out    => noc_data_n_out(i),
          noc_data_s_out    => noc_data_s_out(i),
          noc_data_w_out    => noc_data_w_out(i),
          noc_data_e_out    => noc_data_e_out(i),
          noc_data_void_out => noc_data_void_out(i),
          noc_stop_out       => noc_stop_out(i),
          noc_mon_noc_vec   => mon_noc_vec(i),
          mon_mem            => mon_mem(CFG_NMEM_TILE + tile_slm_id(i)),
          mon_dvfs           => mon_dvfs_out(i));
      clk_tile(i) <= refclk_int(i);
    end generate slm_tile;

  end generate tiles_gen;

  no_mem_tile_gen: if CFG_NMEM_TILE = 0 generate
    ddr_ahbsi(0) <= ahbs_in_none;
  end generate no_mem_tile_gen;

  monitor_noc_gen: for i in 1 to num_noc_planes generate
    monitor_noc_tiles_gen: for j in 0 to CFG_TILES_NUM-1 generate
      mon_noc(i,j) <= mon_noc_vec(j)(i);
    end generate monitor_noc_tiles_gen;
  end generate monitor_noc_gen;

  monitor_l2_gen: for i in 0 to CFG_NL2 - 1 generate
    mon_l2(i) <= mon_l2_int(cache_tile_id(i));
  end generate monitor_l2_gen;

  monitor_llc_gen: for i in 0 to CFG_NLLC - 1 generate
    mon_llc(i) <= mon_llc_int(llc_tile_id(i));
  end generate monitor_llc_gen;


  -- Handle cases with no accelerators, no l2, no llc
  mon_acc_noacc_gen: if accelerators_num = 0 generate
    mon_acc(0) <= monitor_acc_none;
  end generate mon_acc_noacc_gen;

  mon_l2_nol2_gen: if CFG_NL2 = 0 generate
    mon_l2(0) <= monitor_cache_none;
  end generate mon_l2_nol2_gen;

  mon_llc_nollc_gen: if CFG_NLLC = 0 generate
    mon_llc(0) <= monitor_cache_none;
  end generate mon_llc_nollc_gen;

  -- convert noc matrix into transit matrix
--monitor_conversion_tiles: for tile in 0 to CFG_TILES_NUM-1 generate
--  monitor_conversion_planes: for plane in 0 to nocs_num-1 generate
--    mon_transit(plane, tile).clk <= mon_noc_vec(plane+1)(tile).clk;
--    mon_transit(plane, tile).tile_injection <= mon_noc_vec(plane+1)(tile).tile_injection;
--    mon_transit(plane, tile).tile_ejection <= mon_noc_vec(plane+1)(tile).tile_ejection;
--  end generate monitor_conversion_planes;
--end generate monitor_conversion_tiles;
--
  -- process to "and" all the singular pll_locked signals and generate a general lock
  process(pll_locked)
  variable pll_lock_temp : std_logic;
  begin
  pll_lock_temp := '1';
    for i in 0 to CFG_TILES_NUM-1 loop
      pll_lock_temp := pll_lock_temp and pll_locked(i);
    end loop;
    pll_lck_glb_int <= pll_lock_temp;
  end process;
  pll_locked_global <= pll_lck_glb_int;

  --transit_monitor_generation: if CFG_MON_NOC_INJECT_EN /= 0 generate
  --  -- a set of processes to count the injection/ejection events at the right frequency
  --  monitor_transit_counter_tiles: for tile in 0 to CFG_TILES_NUM-1 generate
  --    monitor_transit_counter_planes: for plane in 0 to nocs_num-1 generate
  --      process(clk_tile(tile_domain_master(tile)), rst_local(tile_domain_master(tile))
  --      begin
  --        if rst_local(tile_domain_master(tile)) == 0 then
  --          count_transit_inj(tile*nocs_num+plane) <= (others => '0');
  --          count_transit_ej(tile*nocs_num+plane) <= (others => '0');
  --        elsif clk_tile(tile_domain_master(tile))'event and clk_tile(tile_domain_master(tile)) = '1' then
  --          count_transit_inj(tile*nocs_num+plane) <= count_transit_inj(tile*nocs_num+plane) + mon_transit(plane, tile).tile_injection;
  --          count_transit_ej(tile*nocs_num+plane) <= count_transit_ej(tile*nocs_num+plane) + mon_transit(plane, tile).tile_ejection;
  --        end if;
  --      end process;
  --    end generate monitor_transit_counter_planes;
  --  end generate monitor_transit_counter_tiles;
  --  -- a huge set of synchronizers to convert injection/ejection counters to the frequency of the IO tile.
  --  --Not a good practice of course, but I do not have any better ideas.
  --  monitor_transit_synchronizers_tiles: for tile in 0 to CFG_TILES_NUM-1 generate
  --    monitor_transit_synchronizers_planes: for plane in 0 to nocs_num-1 generate
  --      synchronizer_inj: synchronizer
  --        generic map (
  --          DATA_WIDTH => REGISTER_WIDTH)
  --        port map (
  --          clk    => refclk,
  --          reset_n => rst,
  --          data_i => count_transit_inj(tile*nocs_num + plane),
  --          data_o => count_transit_inj_sync(tile*nocs_num + plane));
  --      synchronizer_ej: synchronizer
  --        generic map (
  --          DATA_WIDTH => REGISTER_WIDTH)
  --        port map (
  --          clk    => refclk,
  --          reset_n => rst,
  --          data_i => count_transit_ej(tile*nocs_num + plane),
  --          data_o => count_transit_ej_sync(tile*nocs_num + plane));
  --    end generate monitor_transit_synchronizers_planes;
  --  end generate monitor_transit_synchronizers_tiles;
  --end generate transit_monitor_generation;
  --
  --no_transit_monitor_generation: if CFG_MON_NOC_INJECT_EN = 0 generate
  --  count_transit_inj <= (others => (others => '0'));
  --  count_transit_inj_sync <= (others => (others => '0'));
  --  count_transit_ej <= (others => (others => '0'));
  --  count_transit_ej_sync <= (others => (others => '0'));
  --end generate no_transit_monitor_generation;
end;
