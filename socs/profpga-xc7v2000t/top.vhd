------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    top.vhd
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

------------------------------------------------------------------------------
--  ESP - profpga - TA1 - xc7v2000t
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
       
        
use work.grlib_config.all;
use work.amba.all;
use work.stdlib.all;
use work.devices.all;
use work.gencomp.all;
use work.leon3.all;
use work.uart.all;
use work.misc.all;
use work.net.all;
use work.svga_pkg.all;
library unisim;
-- pragma translate_off
use work.sim.all;
-- pragma translate_on
use unisim.VCOMPONENTS.all;
use work.monitor_pkg.all;
use work.sldacc.all;
use work.tile.all;
use work.nocpackage.all;
use work.cachepackage.all;
use work.coretypes.all;
use work.config.all;
use work.esp_global.all;
use work.socmap.all;
use work.tiles_pkg.all;

use work.esp_csr_pkg.all; -- I need this library for freq data info

entity top is
  generic (
    SIMULATION          : boolean := false
  );
  port (
    -- MMI64 interface:
    profpga_clk0_p        : in  std_ulogic;  -- 100 MHz clock
    profpga_clk0_n        : in  std_ulogic;  -- 100 MHz clock
    profpga_sync0_p       : in  std_ulogic;
    profpga_sync0_n       : in  std_ulogic;
    dmbi_h2f              : in  std_logic_vector(19 downto 0);
    dmbi_f2h              : out std_logic_vector(19 downto 0);
    --
    reset           : in    std_ulogic;
    --c0_main_clk_p   : in    std_ulogic;  -- 200 MHz clock
    --c0_main_clk_n   : in    std_ulogic;  -- 200 MHz clock
    --c1_main_clk_p   : in    std_ulogic;  -- 200 MHz clock
    --c1_main_clk_n   : in    std_ulogic;  -- 200 MHz clock
    --clk_ref_p       : in    std_ulogic;  -- 200 MHz clock
    --clk_ref_n       : in    std_ulogic;  -- 200 MHz clock
    c0_calib_complete  : out   std_logic;
    c1_calib_complete  : out   std_logic;
    uart_rxd           : in    std_ulogic;
    uart_txd           : out   std_ulogic;
    uart_cts          : in    std_ulogic; -- nel top.vhd originale, i segnali cts e rts erano negati (ctsn e rtsn)
    uart_rts          : out   std_ulogic; --           perché i constraints erano differenti
    -- Ethernet signals
    reset_o2  : out   std_ulogic;
    --etx_clk   : in    std_ulogic;
    --erx_clk   : in    std_ulogic;
    erxd      : in    std_logic_vector(3 downto 0);
    erx_dv    : in    std_ulogic;
    erx_er    : in    std_ulogic;
    erx_col   : in    std_ulogic;
    erx_crs   : in    std_ulogic;
    etxd      : out   std_logic_vector(3 downto 0);
    etx_en    : out   std_ulogic;
    etx_er    : out   std_ulogic;
    emdc      : out   std_ulogic;
    emdio     : inout std_logic;
    -- DVI
    tft_nhpd        : in  std_ulogic;   -- Hot plug
    tft_clk_p       : out std_ulogic;
    tft_clk_n       : out std_ulogic;
    tft_data        : out std_logic_vector(23 downto 0);
    tft_hsync       : out std_ulogic;
    tft_vsync       : out std_ulogic;
    tft_de          : out std_ulogic;
    tft_dken        : out std_ulogic;
    tft_ctl1_a1_dk1 : out std_ulogic;
    tft_ctl2_a2_dk2 : out std_ulogic;
    tft_a3_dk3      : out std_ulogic;
    tft_isel        : out std_ulogic;
    tft_bsel        : out std_logic;
    tft_dsel        : out std_logic;
    tft_edge        : out std_ulogic;
    tft_npd         : out std_ulogic;

    LED_RED         : out   std_ulogic;
    LED_GREEN       : out   std_ulogic;
    LED_BLUE        : out   std_ulogic;
    LED_YELLOW      : out   std_ulogic;
    c0_diagnostic_led  : out   std_ulogic;
    c1_diagnostic_led  : out   std_ulogic
   );
end;


architecture rtl of top is

component ahb2mig_7series_profpga
  generic(
    hindex     : integer := 0;
    haddr      : integer := 0;
    hmask      : integer := 16#f00#
  );
  port(
    app_addr          : out   std_logic_vector(28 downto 0);
    app_cmd           : out   std_logic_vector(2 downto 0);
    app_en            : out   std_logic;      
    app_wdf_data      : out   std_logic_vector(511 downto 0);
    app_wdf_end       : out   std_logic;      
    app_wdf_mask      : out   std_logic_vector(63 downto 0);
    app_wdf_wren      : out   std_logic;      
    app_rd_data       : in    std_logic_vector(511 downto 0);
    app_rd_data_end   : in    std_logic;
    app_rd_data_valid : in    std_logic;
    app_rdy           : in    std_logic;
    app_wdf_rdy       : in    std_logic;
    ahbso             : out   ahb_slv_out_type;
    ahbsi             : in    ahb_slv_in_type;
    clk_amba          : in    std_logic;
    rst_n_syn         : in    std_logic
   );
end component ;

-- aggiungo il modulo che genera il reset
component profpga_clocksync is
  generic (
    CLK_CORE_COMPENSATION : string := "DELAYED" -- "DELAYED" , "DELAYED_XVUS" or "ZHOLD"
  );
  port (
    -- access to FPGA pins
    clk_p           : in  std_ulogic;
    clk_n           : in  std_ulogic;
    sync_p          : in  std_ulogic;
    sync_n          : in  std_ulogic;

    -- clock from pad
    clk_o           : out std_ulogic;

    -- clock feedback (either clk_o or 1:1 output from MMCM/PLL)
    clk_i           : in  std_ulogic;
    clk_locked_i    : in  std_ulogic;

    -- configuration access from profpga_infrastructure
    mmi64_clk       : in  std_ulogic;
    mmi64_reset     : in  std_ulogic;
    cfg_dn_i        : in  std_ulogic_vector(19 downto 0);
    cfg_up_o        : out std_ulogic_vector(19 downto 0);

    -- sync events
    user_reset_o    : out std_ulogic;
    user_strobe1_o  : out std_ulogic;
    user_strobe2_o  : out std_ulogic;
    user_event_id_o : out std_ulogic_vector(7 downto 0);
    user_event_en_o : out std_ulogic
  );
end component profpga_clocksync;
  
 -- I add the declaration of the DFS module
  component clockManager
    generic(
      PLL_FREQ                                 :    integer := 1;
      RANDOM_FREQ                              :    integer := 0
    );
    port (
      rst_in                                   :     in std_logic;
      clk_in                                   :     in std_logic;
      mmcm_clk_o                               :     out std_logic;
      mmcm_locked_o                            :     out std_logic;
      freq_data_in                             :     in std_logic_vector(8-1 downto 0);
      freq_empty_in                            :     in std_logic
      );
  end component;

  function set_ddr_index (
    constant n : integer range 0 to 3)
    return integer is
  begin
    if n > (MEM_ID_RANGE_MSB) then
      return MEM_ID_RANGE_MSB;
    else
      return n;
    end if;
  end set_ddr_index;

  constant this_ddr_index : attribute_vector(0 to 3) := (
    0 => set_ddr_index(0),
    1 => set_ddr_index(1),
    2 => set_ddr_index(2),
    3 => set_ddr_index(3)
    );

component ahbram is
  generic (
    hindex      : integer := 0;
    tech        : integer := DEFMEMTECH;
    large_banks : integer := 0;
    kbytes      : integer := 1;
    pipe        : integer := 0;
    maccsz      : integer := AHBDW;
    scantest    : integer := 0;
    endianness  : integer := 0);
  port (
    rst     : in  std_ulogic;
    clk     : in  std_ulogic;
    haddr   : in  integer range 0 to 4095;
    hmask   : in  integer range 0 to 4095;
    ahbsi   : in  ahb_slv_in_type;
    ahbso   : out ahb_slv_out_type
  );
end component;


-- Switches
signal sel0, sel1, sel2, sel3, sel4 : std_ulogic;

-- clock and reset
signal clkm : std_ulogic := '0';    --
signal clkm_sync_rst : std_ulogic;  --
signal rstn, rstraw : std_ulogic;
signal lock, rst : std_ulogic;
signal migrstn : std_logic;
signal cgi : clkgen_in_type;
signal cgo : clkgen_out_type;

---mig0 signals
signal c0_app_addr          : std_logic_vector(28 downto 0);
signal c0_app_cmd           : std_logic_vector(2 downto 0);
signal c0_app_en            : std_ulogic;
signal c0_app_wdf_data      : std_logic_vector(511 downto 0);
signal c0_app_wdf_end       : std_ulogic;
signal c0_app_wdf_mask      : std_logic_vector(63 downto 0); 
signal c0_app_wdf_wren      : std_ulogic;
signal c0_app_rd_data       : std_logic_vector(511 downto 0);
signal c0_app_rd_data_end   : std_ulogic;
signal c0_app_rd_data_valid : std_ulogic;
signal c0_app_rdy           : std_ulogic;
signal c0_app_wdf_rdy       : std_ulogic;
signal c0_calib_done        : std_ulogic;
---mig0 signals
signal c1_app_addr          : std_logic_vector(28 downto 0);
signal c1_app_cmd           : std_logic_vector(2 downto 0);
signal c1_app_en            : std_ulogic;
signal c1_app_wdf_data      : std_logic_vector(511 downto 0);
signal c1_app_wdf_end       : std_ulogic;
signal c1_app_wdf_mask      : std_logic_vector(63 downto 0); 
signal c1_app_wdf_wren      : std_ulogic;
signal c1_app_rd_data       : std_logic_vector(511 downto 0);
signal c1_app_rd_data_end   : std_ulogic;
signal c1_app_rd_data_valid : std_ulogic;
signal c1_app_rdy           : std_ulogic;
signal c1_app_wdf_rdy       : std_ulogic;
signal c1_calib_done        : std_ulogic;

-- Ethernet signals
signal ethi : eth_in_type;
signal etho : eth_out_type;

-- Tiles
--pragma translate_off
--signal mctrl_ahbsi : ahb_slv_in_type;
--signal mctrl_ahbso : ahb_slv_out_type;
--signal mctrl_apbi  : apb_slv_in_type;
--signal mctrl_apbo  : apb_slv_out_type;
--pragma translate_on

-- UART
signal uart_rxd_int  : std_logic;       -- UART1_RX (u1i.rxd)
signal uart_txd_int  : std_logic;       -- UART1_TX (u1o.txd)
signal uart_ctsn_int : std_logic;       -- UART1_RTSN (u1i.ctsn)
signal uart_rtsn_int : std_logic;       -- UART1_RTSN (u1o.rtsn)

-- Memory controller DDR3
signal buf_ddr_ahbsi   : ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
signal buf_ddr_ahbso   : ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);

signal noc_ddr_ahbsi   : ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
signal noc_ddr_ahbso   : ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);

signal mem_ddr_ahbsi   : ahb_slv_in_vector_type(0 to MEM_ID_RANGE_MSB);
signal mem_ddr_ahbso   : ahb_slv_out_vector_type(0 to MEM_ID_RANGE_MSB);

-- Ethernet
--constant CPU_FREQ : integer := 50000;
signal eth0_apbi : apb_slv_in_type;
signal eth0_apbo : apb_slv_out_type;
signal sgmii0_apbi : apb_slv_in_type;
signal sgmii0_apbo : apb_slv_out_type;
signal eth0_ahbmi : ahb_mst_in_type;
signal eth0_ahbmo : ahb_mst_out_type;
signal edcl_ahbmo : ahb_mst_out_type;

-- DVI

component svga2tfp410
  generic (
    tech    : integer);
  port (
    clk         : in  std_ulogic;
    rstn        : in  std_ulogic;
    vgaclk_fb   : in  std_ulogic;
    vgao        : in  apbvga_out_type;
    vgaclk      : out std_ulogic;
    idck_p      : out std_ulogic;
    idck_n      : out std_ulogic;
    data        : out std_logic_vector(23 downto 0);
    hsync       : out std_ulogic;
    vsync       : out std_ulogic;
    de          : out std_ulogic;
    dken        : out std_ulogic;
    ctl1_a1_dk1 : out std_ulogic;
    ctl2_a2_dk2 : out std_ulogic;
    a3_dk3      : out std_ulogic;
    isel        : out std_ulogic;
    bsel        : out std_ulogic;
    dsel        : out std_ulogic;
    edge        : out std_ulogic;
    npd         : out std_ulogic);
end component;

signal dvi_apbi : apb_slv_in_type;
signal dvi_apbo : apb_slv_out_type;
signal dvi_ahbmi : ahb_mst_in_type;
signal dvi_ahbmo : ahb_mst_out_type;

signal dvi_nhpd        : std_ulogic;
signal dvi_data        : std_logic_vector(23 downto 0);
signal dvi_hsync       : std_ulogic;
signal dvi_vsync       : std_ulogic;
signal dvi_de          : std_ulogic;
signal dvi_dken        : std_ulogic;
signal dvi_ctl1_a1_dk1 : std_ulogic;
signal dvi_ctl2_a2_dk2 : std_ulogic;
signal dvi_a3_dk3      : std_ulogic;
signal dvi_isel        : std_ulogic;
signal dvi_bsel        : std_ulogic;
signal dvi_dsel        : std_ulogic;
signal dvi_edge        : std_ulogic;
signal dvi_npd         : std_ulogic;

signal vgao  : apbvga_out_type;
signal clkvga, clkvga_p, clkvga_n : std_ulogic;

attribute syn_keep : boolean;
attribute syn_preserve : boolean;
attribute syn_keep of clkvga : signal is true;
attribute syn_preserve of clkvga : signal is true;
attribute keep : boolean;
attribute keep of clkvga : signal is true;

-- CPU flags
signal cpuerr : std_ulogic;

-- NOC
signal chip_rst : std_ulogic;
signal chip_refclk : std_ulogic := '0';
signal chip_pllbypass : std_logic_vector(CFG_TILES_NUM-1 downto 0);
signal chip_pllclk : std_ulogic;


attribute keep of clkm : signal is true;
--attribute keep of clkm_2 : signal is true;    --
attribute keep of chip_refclk : signal is true;

signal c0_diagnostic_count : std_logic_vector(26 downto 0);
signal c0_diagnostic_toggle : std_ulogic;
signal c1_diagnostic_count : std_logic_vector(26 downto 0);
signal c1_diagnostic_toggle : std_ulogic;

-- MMI64
signal user_rstn        : std_ulogic;
signal mon_ddr          : monitor_ddr_vector(0 to MEM_ID_RANGE_MSB);
signal mon_noc          : monitor_noc_matrix(1 to 6, 0 to CFG_TILES_NUM-1);
signal mon_noc_actual   : monitor_noc_matrix(0 to 1, 0 to CFG_TILES_NUM-1);
--signal mon_noc_actual   : monitor_noc_matrix(0 to 5, 0 to CFG_TILES_NUM-1); -- adapting mon_noc_actual to the shape of mon_noc
signal mon_mem          : monitor_mem_vector(0 to CFG_NMEM_TILE + CFG_NSLM_TILE + CFG_NSLMDDR_TILE - 1);
signal mon_l2           : monitor_cache_vector(0 to relu(CFG_NL2 - 1));
signal mon_llc          : monitor_cache_vector(0 to relu(CFG_NLLC - 1));
signal mon_acc          : monitor_acc_vector(0 to relu(accelerators_num-1));
signal mon_dvfs         : monitor_dvfs_vector(0 to CFG_TILES_NUM-1);

-- my signals
signal uart_cts_int : std_logic;
signal uart_rts_int : std_logic;
signal clk_custom : std_logic;
signal clk_cfg_dn, clk_cfg_up : std_ulogic_vector(19 downto 0);
signal rst_custom, monitor_rst_o : std_logic;

signal pll_locked_global, lock_global : std_logic;
signal base_rst : std_logic;
signal icclk, icclk_locked, icrst, icrstn, icrst_rstgen : std_logic;  --Interconnect clock (valid for NoC, as well as mem and IO tiles)

signal freq_data     : std_logic_vector(GM_FREQ_DW-1 downto 0);  -- input freq data
signal freq_empty    : std_logic; -- freq data empty

begin

  c0_diagnostic: process (clkm, rst_custom)--clkm_sync_rst)
  begin  -- process c0_diagnostic
    if  rst_custom = '1' then --clkm_sync_rst = '1' then                  -- asynchronous reset (active high)
      c0_diagnostic_count <= (others => '0');
    elsif clkm'event and clkm = '1' then  -- rising clock edge
      c0_diagnostic_count <= c0_diagnostic_count + 1;
    end if;
  end process c0_diagnostic;
  c0_diagnostic_toggle <= c0_diagnostic_count(26);
  c0_led_diag_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x15v) port map (c0_diagnostic_led, c0_diagnostic_toggle);

-------------------------------------------------------------------------------
-- Leds -----------------------------------------------------------------------
-------------------------------------------------------------------------------

  -- From memory controllers' PLLs
  lock_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v) port map (LED_GREEN, '1');--lock);  temp test

  -- From CPU 0 (on chip)
  cpuerr_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v) port map (LED_RED, rst_custom);--cpuerr);  temp test
  --pragma translate_off
  process(clkm, rstn)
  begin  -- process
    if rstn = '1' then
      assert cpuerr = '0' report "Program Completed!" severity failure;
    end if;
  end process;
  --pragma translate_on

  -- From DDR controller (on FPGA)
  calib0_complete_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x15v) port map (c0_calib_complete, c0_calib_done);
  calib1_complete_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x15v) port map (c1_calib_complete, c1_calib_done);

  led3_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v) port map (LED_BLUE, '0');

  led4_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v) port map (LED_YELLOW, '0');
    
-------------------------------------------------------------------------------
-- Switches -------------------------------------------------------------------
-------------------------------------------------------------------------------

  sel0 <= '1';
  sel1 <= '0';
  sel2 <= '0';
  sel3 <= '0';
  sel4 <= '0';

----------------------------------------------------------------------
--- FPGA Reset and Clock generation  ---------------------------------
----------------------------------------------------------------------
  -- let's try to implement our dfs
  interconnect_clock_dvfs: if CFG_HAS_DVFS /= 0 generate
    dvfs_manager_1 : clockManager
    generic map(
      PLL_FREQ => domain_freq(0),
      RANDOM_FREQ => 0
    )
    port map(
        rst_in => base_rst,
        clk_in => chip_refclk,
        mmcm_clk_o => icclk,
        mmcm_locked_o => icclk_locked,
        freq_data_in => freq_data,
        freq_empty_in => freq_empty
    );
  end generate interconnect_clock_dvfs;

  interconnect_clock_no_dvfs: if CFG_HAS_DVFS = 0 generate
    icclk <= clkm;
    icclk_locked <= lock;
  end generate interconnect_clock_no_dvfs;

  cgi.pllctrl <= "00";
  cgi.pllrst <= rstraw;

  -- an important problem in the design of a sistem with multiple clock is that many subsystems need a synchronous reset.
  --This means that their reset must be stopped only after the locking of their clock signal, generated by the PLLs.
  --At the same time, the DFS that generates such clock signals need a reset to start its operations correctly.
  --For this reason, I decided to use two resets: the first one (the original esp reset signal for the tiles) will become the reset
  --for the local clocking resources, while my new reset (that starts after the locking of all clocks) will be the general system reset.
  reset_pad : inpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v) port map (reset, rst);

  --Reset for the clocking resources
  rst_clkres : rstgen         -- reset generator
  generic map (acthigh => 1, syncin => 0)
  port map (rst_custom, chip_refclk, lock, base_rst, open);
  lock <= c0_calib_done and c1_calib_done and cgo.clklock;

  --rst1 : rstgen         -- reset generator
  --generic map (acthigh => 1)
  --port map (rst_custom, clkm, lock, migrstn, open); -- scambio rst con il mio custom

  --General system reset
  rst_sys : rstgen         -- reset generator
  generic map (acthigh => 1, syncin => 0)   --GM note: il segnale rst è active high, ho controllato il modulo rstgen
  port map (rst_custom, clkm, lock_global, rstn, rstraw); -- scambio rst con il mio custom
  lock_global <= pll_locked_global and icclk_locked;
  
  -- generate interconnect reset
  interconnect_rst: rstgen
    generic map(acthigh => 1, syncin => 0)
    port map (rst_custom, icclk, lock_global, icrst_rstgen, open);

  -- simple process to initialize the value of rst_ic and rst_local
  process (lock_global, icrst_rstgen)
  begin
    if lock_global = '1' then
      icrst <= icrst_rstgen;
    else
      icrst <= '0';
    end if;
  end process;
  icrstn <= not icrst;

-----------------------------------------------------------------------------
-- UART pads
-----------------------------------------------------------------------------

  uart_ctsn_int <= not uart_cts_int;
  uart_rts_int <= not uart_rtsn_int;
  uart_rxd_pad   : inpad  generic map (level => cmos, voltage => x18v, tech => CFG_FABTECH) port map (uart_rxd, uart_rxd_int);
  uart_txd_pad   : outpad generic map (level => cmos, voltage => x18v, tech => CFG_FABTECH) port map (uart_txd, uart_txd_int);
  uart_ctsn_pad : inpad  generic map (level => cmos, voltage => x18v, tech => CFG_FABTECH) port map (uart_cts, uart_cts_int);
  uart_rtsn_pad : outpad generic map (level => cmos, voltage => x18v, tech => CFG_FABTECH) port map (uart_rts, uart_rts_int);

----------------------------------------------------------------------
---  DDR3 memory controller ------------------------------------------
----------------------------------------------------------------------

  --GM note: chip_refclk is the 50MHz reference, compared with the clkm which goes at 100MHz
  clkgenmigref0 : clkgen
    generic map (CFG_FABTECH, 16, 32, 0, 0, 0, 0, 0, 100000)
    port map (clkm, clkm, chip_refclk, open, open, open, open, cgi, cgo, open, open, open);


  gen_mig : if (SIMULATION /= true) generate

    mig_loop: for nmem in 0 to CFG_NMEM_TILE-1 generate
      first_bank: if nmem = 0 generate
        mig_ahbram1 : ahbram
          generic map (
            hindex   => 0,
            tech     => 0,
            kbytes   => CFG_MEM_SIZE_MAIN,
            pipe     => 0,
            maccsz   => AHBDW,
            scantest => 0,
            endianness => 0
            )
          port map(
            rst     => icrst, --rstn,  -- need the icclk for the memory
            clk     => icclk, --clkm,  -- need the icclk for the memory
            haddr   => ddr_haddr(this_ddr_index(nmem)),
            hmask   => ddr_hmask(this_ddr_index(nmem)),
            ahbsi   => mem_ddr_ahbsi(nmem),
            ahbso   => mem_ddr_ahbso(nmem)
            );
      end generate first_bank;
      generic_bank: if nmem /= 0 generate
        mig_ahbram1 : ahbram
          generic map (
            hindex   => 0,
            tech     => 0,
            kbytes   => CFG_MEM_SIZE_ADD,
            pipe     => 0,
            maccsz   => AHBDW,
            scantest => 0,
            endianness => 0
            )
          port map(
            rst     => icrst, --rstn,  -- need the icclk for the memory
            clk     => icclk, --clkm,  -- need the icclk for the memory
            haddr   => ddr_haddr(this_ddr_index(nmem)),
            hmask   => ddr_hmask(this_ddr_index(nmem)),
            ahbsi   => mem_ddr_ahbsi(nmem),
            ahbso   => mem_ddr_ahbso(nmem)
            );
      end generate generic_bank;
    end generate mig_loop;

    c0_calib_done <= '1';

    c1_calib_done <= '1';

    -- genero il reset con il clock sync
    --If the monitor is present the input clock cannot drive both modules, so the reset is generated in the monitor infrastructure
    --rst_custom_gen : if CFG_MON_DDR_EN + CFG_MON_NOC_INJECT_EN + CFG_MON_NOC_QUEUES_EN + CFG_MON_ACC_EN + CFG_MON_DVFS_EN = 0 generate
      clocksync: profpga_clocksync
          port map(

          clk_p            => profpga_clk0_p,
          clk_n            => profpga_clk0_n,
          sync_p           => profpga_sync0_p,
          sync_n           => profpga_sync0_n,


          clk_o            => clkm,


          clk_i            => clkm,
          clk_locked_i     => '1',


          mmi64_clk        => '0',
          mmi64_reset      => '0',
          cfg_dn_i         => clk_cfg_dn,
          cfg_up_o         => clk_cfg_up,


          user_reset_o     => rst_custom,
          user_strobe1_o   => open,
          user_strobe2_o   => open,
          user_event_id_o  => open,
          user_event_en_o  => open
          );
     --   end generate;

    -- pragma translate_on
  --rst_monitor_gen : if CFG_MON_DDR_EN + CFG_MON_NOC_INJECT_EN + CFG_MON_NOC_QUEUES_EN + CFG_MON_ACC_EN + CFG_MON_DVFS_EN /= 0 generate
  --  rst_custom <= monitor_rst_o;
  --end generate;

  end generate gen_mig;

  ahbram_buffer_loop: for nmem in 0 to CFG_NMEM_TILE-1 generate
    -- BRAM buffer instantiation
    ahbram_buffer_1: ahbram_buffer
    port map(
      rst_i           =>  icrst,
      clk_i           =>  icclk,
      noc_ahbsi_i     =>  buf_ddr_ahbsi(nmem),
      noc_ahbso_o     =>  buf_ddr_ahbso(nmem),
      mem_ahbsi_o     =>  mem_ddr_ahbsi(nmem),
      mem_ahbso_i     =>  mem_ddr_ahbso(nmem)
    );
    -- latency increaser instantiation
    ahbram_latency_simulator: ahbram_latencyIncreaser
    generic map(
      LATENCY_CYCLES  =>  25
    )
    port map(
      rst_i           =>  icrst,
      clk_i           =>  icclk,
      noc_ahbsi_i     =>  noc_ddr_ahbsi(nmem),
      noc_ahbso_o     =>  noc_ddr_ahbso(nmem),
      mem_ahbsi_o     =>  buf_ddr_ahbsi(nmem),
      mem_ahbso_i     =>  buf_ddr_ahbso(nmem)
    );
  end generate ahbram_buffer_loop;

  gen_mig_model : if (SIMULATION = true) generate
    -- pragma translate_off
    rst_custom <= rst;     -- adding this for simulation. Don't know how it worked without this!

    mig_loop: for nmem in 0 to CFG_NMEM_TILE-1 generate
      first_bank: if nmem = 0 generate
        mig_ahbram:  ahbram_sim
          generic map (
            hindex   => 0,
            tech     => 0,
            kbytes   => CFG_MEM_SIZE_MAIN,
            pipe     => 0,
            maccsz   => AHBDW,
            fname    => "ram.srec"
            )
          port map(
            rst     => icrst, --rstn,  -- need the icclk for the memory
            clk     => icclk, --clkm,  -- need the icclk for the memory
            haddr   => ddr_haddr(this_ddr_index(nmem)),
            hmask   => ddr_hmask(this_ddr_index(nmem)),
            ahbsi   => mem_ddr_ahbsi(nmem),
            ahbso   => mem_ddr_ahbso(nmem)
            );
        end generate first_bank;
        generic_bank: if nmem /= 0 generate
          mig_ahbram:  ahbram_sim
          generic map (
            hindex   => 0,
            tech     => 0,
            kbytes   => CFG_MEM_SIZE_ADD,
            pipe     => 0,
            maccsz   => AHBDW,
            fname    => "ram.srec"
            )
          port map(
            rst     => icrst, --rstn,  -- need the icclk for the memory
            clk     => icclk, --clkm,  -- need the icclk for the memory
            haddr   => ddr_haddr(this_ddr_index(nmem)),
            hmask   => ddr_hmask(this_ddr_index(nmem)),
            ahbsi   => mem_ddr_ahbsi(nmem),
            ahbso   => mem_ddr_ahbso(nmem)
            );
        end generate generic_bank;
    end generate mig_loop;

    c0_calib_done <= '1';

    c1_calib_done <= '1';

    clkm <= not clkm after 5 ns;
    --clkm_2 <= not clkm_2 after 5 ns;

    -- pragma translate_on
  end generate gen_mig_model;

-----------------------------------------------------------------------
---  ETHERNET ---------------------------------------------------------
-----------------------------------------------------------------------

  reset_o2 <= icrst; --rstn;  -- need the icclk
  eth0 : if SIMULATION = false and CFG_GRETH = 1 generate -- Gaisler ethernet MAC
  -- removed altogether the ethernet signals.
    eth0_apbo <= apb_none;
    eth0_ahbmo <= ahbm_none;
    edcl_ahbmo <= ahbm_none;
    etho.mdio_o <= '0';
    etho.mdio_oe <= '0';
    etho.txd <= (others => '0');
    etho.tx_en <= '0';
    etho.tx_er <= '0';
    etho.mdc <= '0';
  end generate;

  ethi.edclsepahb <= '1';

  emdio_pad : iopad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (emdio, etho.mdio_o, etho.mdio_oe, ethi.mdio_i);
  etxd_pad : outpadv generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v, width => 4)
    port map (etxd, etho.txd(3 downto 0));
  etxen_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (etx_en, etho.tx_en);
  etxer_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (etx_er, etho.tx_er);
  emdc_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (emdc, etho.mdc);

  no_eth0: if SIMULATION = true or CFG_GRETH = 0 generate
    eth0_apbo <= apb_none;
    eth0_ahbmo <= ahbm_none;
    edcl_ahbmo <= ahbm_none;
    etho.mdio_o <= '0';
    etho.mdio_oe <= '0';
    etho.txd <= (others => '0');
    etho.tx_en <= '0';
    etho.tx_er <= '0';
    etho.mdc <= '0';
  end generate no_eth0;

  sgmii0_apbo <= apb_none;

  -----------------------------------------------------------------------------
  -- DVI
  -----------------------------------------------------------------------------

  svga : if CFG_SVGA_ENABLE /= 0 generate
    svga0 : svgactrl generic map(
      memtech => CFG_FABTECH,
      pindex => 13,
      paddr => 6,
      hindex => 0,
      clk0 => 25000,
      clk1 => 25000,
      clk2 => 25000,
      clk3 => 25000,
      burstlen => 6,
      ahbaccsz => CFG_AHBDW)
      port map(
        rst => icrst, --rstn, -- use ic clock
        clk => icclk, --chip_refclk, -- use ic clock
        vgaclk => clkvga,
        apbi => dvi_apbi,
        apbo => dvi_apbo,
        vgao => vgao,
        ahbi => dvi_ahbmi,
        ahbo => dvi_ahbmo,
        clk_sel => open);

    dvi0 : svga2tfp410
      generic map (
        tech    => CFG_FABTECH)
      port map (
        clk         => icclk, --chip_refclk, -- use ic clock
        rstn        => icrst, --rstraw, -- use ic clock
        vgao        => vgao,
        vgaclk_fb   => clkvga,
        vgaclk      => clkvga,
        idck_p      => clkvga_p,
        idck_n      => clkvga_n,
        data        => dvi_data,
        hsync       => dvi_hsync,
        vsync       => dvi_vsync,
        de          => dvi_de,
        dken        => dvi_dken,
        ctl1_a1_dk1 => dvi_ctl1_a1_dk1,
        ctl2_a2_dk2 => dvi_ctl2_a2_dk2,
        a3_dk3      => dvi_a3_dk3,
        isel        => dvi_isel,
        bsel        => dvi_bsel,
        dsel        => dvi_dsel,
        edge        => dvi_edge,
        npd         => dvi_npd);

  end generate;

  novga : if CFG_SVGA_ENABLE = 0 generate
    dvi_apbo   <= apb_none;
    dvi_ahbmo  <= ahbm_none;
    dvi_data   <= (others => '0');
    clkvga_p   <= '0';
    clkvga_n   <= '0';
    dvi_hsync  <= '0';
    dvi_vsync  <= '0';
    dvi_de     <= '0';
    dvi_dken   <= '0';
    dvi_ctl1_a1_dk1 <= '0';
    dvi_ctl2_a2_dk2 <= '0';
    dvi_a3_dk3 <= '0';
    dvi_isel   <= '0';
    dvi_bsel   <= '0';
    dvi_dsel   <= '0';
    dvi_edge  <= '0';
    dvi_npd    <= '0';
  end generate;

  tft_nhpd_pad : inpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_nhpd, dvi_nhpd);

  tft_clkp_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_clk_p, clkvga_p);
  tft_clkn_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_clk_n, clkvga_n);

  tft_data_pad : outpadv generic map (width => 24, tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_data, dvi_data);
  tft_hsync_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_hsync, dvi_hsync);
  tft_vsync_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_vsync, dvi_vsync);
  tft_de_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_de, dvi_de);

  tft_dken_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_dken, dvi_dken);
  tft_ctl1_a1_dk1_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_ctl1_a1_dk1, dvi_ctl1_a1_dk1);
  tft_ctl2_a2_dk2_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_ctl2_a2_dk2, dvi_ctl2_a2_dk2);
  tft_a3_dk3_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_a3_dk3, dvi_a3_dk3);

  tft_isel_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_isel, dvi_isel);
  tft_bsel_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_bsel, dvi_bsel);
  tft_dsel_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_dsel, dvi_dsel);
  tft_edge_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_edge, dvi_edge);
  tft_npd_pad : outpad generic map (tech => CFG_FABTECH, level => cmos, voltage => x18v)
    port map (tft_npd, dvi_npd);

  -----------------------------------------------------------------------------
  -- CHIP
  -----------------------------------------------------------------------------
  chip_rst <= rstn;
  chip_pllbypass <= (others => '0');

  esp_1: esp
    generic map (
      SIMULATION => SIMULATION)
    port map (
      rst           => chip_rst,
      base_rst      => base_rst, -- a reset for clocking resources
      refclk        => chip_refclk,
      icclk         => icclk, -- a variable clock for the interconnect resources
      icrst         => icrst, -- reset synchronized with the icclk
      pllbypass     => chip_pllbypass,
      pll_locked_global => pll_locked_global,  -- bringing internal lock to the top module
      uart_rxd      => uart_rxd_int,
      uart_txd      => uart_txd_int,
      uart_ctsn     => uart_ctsn_int,
      uart_rtsn     => uart_rtsn_int,
      cpuerr        => cpuerr,
      ddr_ahbsi     => noc_ddr_ahbsi,
      ddr_ahbso     => noc_ddr_ahbso,
      eth0_apbi     => eth0_apbi,
      eth0_apbo     => eth0_apbo,
      edcl_ahbmo    => edcl_ahbmo,
      sgmii0_apbi   => sgmii0_apbi,
      sgmii0_apbo   => sgmii0_apbo,
      eth0_ahbmi    => eth0_ahbmi,
      eth0_ahbmo    => eth0_ahbmo,
      dvi_apbi      => dvi_apbi,
      dvi_apbo      => dvi_apbo,
      dvi_ahbmi     => dvi_ahbmi,
      dvi_ahbmo     => dvi_ahbmo,
      -- Monitor signals
      mon_noc       => mon_noc,
      mon_acc       => mon_acc,
      mon_mem       => mon_mem,
      mon_l2        => mon_l2,
      mon_llc       => mon_llc,
      mon_dvfs      => mon_dvfs,
      freq_data_out     => freq_data,  -- input freq data
      freq_empty_out    => freq_empty -- freq data empty
      );


  -- last piece of original ESP monitor
  dmbi_f2h <= (others => '0');

end;


