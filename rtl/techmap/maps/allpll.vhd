------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    allpll.vhd
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

package allpll is

  component pll_virtex7
    generic (
      SIMULATION  :  boolean := false; 
      clk_mul    : integer;
      clk0_div   : integer;
      clk1_div   : integer;
      clk2_div   : integer;
      clk3_div   : integer;
      clk4_div   : integer;
      clk5_div   : integer;
      clk0_phase : real;
      clk1_phase : real;
      clk2_phase : real;
      clk3_phase : real;
      clk4_phase : real;
      clk5_phase : real;
      freq       : integer);
    port (
      clk    : in  std_ulogic;
      rst    : in  std_ulogic;
      dvfs_clk0   : out std_ulogic;
      dvfs_clk1   : out std_ulogic;
      dvfs_clk2   : out std_ulogic;
      dvfs_clk3   : out std_ulogic;
      dvfs_clk4   : out std_ulogic;
      dvfs_clk5   : out std_ulogic;
      locked : out std_ulogic);
  end component;

  -- Added a simulation only instance for Xcelium simulator
  component pll_virtex7_sim
    generic (
      SIMULATION  :  boolean := false; 
      clk_mul    : integer;
      clk0_div   : integer;
      clk1_div   : integer;
      clk2_div   : integer;
      clk3_div   : integer;
      clk4_div   : integer;
      clk5_div   : integer;
      clk0_phase : real;
      clk1_phase : real;
      clk2_phase : real;
      clk3_phase : real;
      clk4_phase : real;
      clk5_phase : real;
      freq       : integer);
    port (
      clk    : in  std_ulogic;
      rst    : in  std_ulogic;
      dvfs_clk0   : out std_ulogic;
      dvfs_clk1   : out std_ulogic;
      dvfs_clk2   : out std_ulogic;
      dvfs_clk3   : out std_ulogic;
      dvfs_clk4   : out std_ulogic;
      dvfs_clk5   : out std_ulogic;
      locked : out std_ulogic);
  end component;

  component pll_virtexu is
    generic (
      clk_mul    : integer;
      clk0_div   : integer;
      clk1_div   : integer;
      clk2_div   : integer;
      clk3_div   : integer;
      clk4_div   : integer;
      clk5_div   : integer;
      clk0_phase : real;
      clk1_phase : real;
      clk2_phase : real;
      clk3_phase : real;
      clk4_phase : real;
      clk5_phase : real;
      freq       : integer);
    port (
      clk       : in  std_ulogic;
      rst       : in  std_ulogic;
      dvfs_clk0 : out std_ulogic;
      dvfs_clk1 : out std_ulogic;
      dvfs_clk2 : out std_ulogic;
      dvfs_clk3 : out std_ulogic;
      dvfs_clk4 : out std_ulogic;
      dvfs_clk5 : out std_ulogic;
      locked    : out std_ulogic);
  end component pll_virtexu;

  component pll_virtexup is
    generic (
      clk_mul    : integer;
      clk0_div   : integer;
      clk1_div   : integer;
      clk2_div   : integer;
      clk3_div   : integer;
      clk4_div   : integer;
      clk5_div   : integer;
      clk0_phase : real;
      clk1_phase : real;
      clk2_phase : real;
      clk3_phase : real;
      clk4_phase : real;
      clk5_phase : real;
      freq       : integer);
    port (
      clk       : in  std_ulogic;
      rst       : in  std_ulogic;
      dvfs_clk0 : out std_ulogic;
      dvfs_clk1 : out std_ulogic;
      dvfs_clk2 : out std_ulogic;
      dvfs_clk3 : out std_ulogic;
      dvfs_clk4 : out std_ulogic;
      dvfs_clk5 : out std_ulogic;
      locked    : out std_ulogic);
  end component pll_virtexup;

end allpll;
