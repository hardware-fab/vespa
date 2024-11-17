------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    empty_tile_q.vhd
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

use work.amba.all;
use work.stdlib.all;
use work.sld_devices.all;
use work.devices.all;

use work.gencomp.all;
use work.genacc.all;

use work.nocpackage.all;
use work.tile.all;

use work.esp_global.all;

entity empty_tile_q is
  generic (
    tech : integer := virtex7);
  port (
    rst                             : in  std_ulogic;
    clk                             : in  std_ulogic;
    -- NoC5->tile
    apb_rcv_rdreq           : in  std_ulogic;
    apb_rcv_data_out        : out misc_noc_flit_type;
    apb_rcv_empty           : out std_ulogic;
    -- tile->NoC5
    apb_snd_wrreq           : in  std_ulogic;
    apb_snd_data_in         : in  misc_noc_flit_type;
    apb_snd_full            : out std_ulogic;

    -- collapsed NoC
    noc_out_data              : in  noc_flit_vector;
    noc_out_void              : in  std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_out_stop              : out std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_in_data               : out noc_flit_vector;
    noc_in_void               : out std_ulogic_vector(num_noc_planes-1 downto 0);
    noc_in_stop               : in  std_ulogic_vector(num_noc_planes-1 downto 0));

end empty_tile_q;

architecture rtl of empty_tile_q is

  signal fifo_rst : std_ulogic;

  -- NoC5->tile
  signal apb_rcv_wrreq     : std_ulogic;
  signal apb_rcv_data_in   : misc_noc_flit_type;
  signal apb_rcv_full      : std_ulogic;
  -- tile->NoC5
  signal apb_snd_rdreq     : std_ulogic;
  signal apb_snd_data_out  : misc_noc_flit_type;
  signal apb_snd_empty     : std_ulogic;


  -- Cachable data plane 1 -> request messages
  signal noc1_out_data :   noc_flit_type;
  signal noc1_out_void :   std_ulogic;
  signal noc1_out_stop :  std_ulogic;
  signal noc1_in_data  :  noc_flit_type;
  signal noc1_in_void  :  std_ulogic;
  signal noc1_in_stop  :   std_ulogic;
  -- Cachable data plane 2 -> forwarded messages
  signal noc2_out_data :   noc_flit_type;
  signal noc2_out_void :   std_ulogic;
  signal noc2_out_stop :  std_ulogic;
  signal noc2_in_data  :  noc_flit_type;
  signal noc2_in_void  :  std_ulogic;
  signal noc2_in_stop  :   std_ulogic;
  -- Cachable data plane 3 -> response messages
  signal noc3_out_data :   noc_flit_type;
  signal noc3_out_void :   std_ulogic;
  signal noc3_out_stop :  std_ulogic;
  signal noc3_in_data  :  noc_flit_type;
  signal noc3_in_void  :  std_ulogic;
  signal noc3_in_stop  :   std_ulogic;
  -- Non cachable data data plane 4 -> DMA transfers response
  signal noc4_out_data :   noc_flit_type;
  signal noc4_out_void :   std_ulogic;
  signal noc4_out_stop :  std_ulogic;
  signal noc4_in_data  :  noc_flit_type;
  signal noc4_in_void  :  std_ulogic;
  signal noc4_in_stop  :   std_ulogic;
  -- Configuration plane 5 -> RD/WR registers
  signal noc5_out_data :   noc_flit_type;
  signal noc5_out_void :   std_ulogic;
  signal noc5_out_stop :  std_ulogic;
  signal noc5_in_data  :  noc_flit_type;
  signal noc5_in_void  :  std_ulogic;
  signal noc5_in_stop  :   std_ulogic;
  -- Non cachable data data plane 6 -> DMA transfers requests
  signal noc6_out_data :   noc_flit_type;
  signal noc6_out_void :   std_ulogic;
  signal noc6_out_stop :  std_ulogic;
  signal noc6_in_data  :  noc_flit_type;
  signal noc6_in_void  :  std_ulogic;
  signal noc6_in_stop  :   std_ulogic;

begin  -- rtl

  fifo_rst <= rst;                      --FIFO rst active low

  -- noc1: unused
  noc1_in_data  <= (others => '0');
  noc1_in_void  <= '1';
  noc1_out_stop <= '0';

  -- noc2: unused
  noc2_in_data  <= (others => '0');
  noc2_in_void  <= '1';
  noc2_out_stop <= '0';

  -- to noc3: unused
  noc3_in_data  <= (others => '0');
  noc3_in_void  <= '1';
  noc3_out_stop <= '0';

  -- to noc4: unused
  noc4_in_data  <= (others => '0');
  noc4_in_void  <= '1';
  noc4_out_stop <= '0';

  -- to noc6: unused
  noc6_in_data  <= (others => '0');
  noc6_in_void  <= '1';
  noc6_out_stop <= '0';

  -- From noc5: APB requests
  noc5_out_stop           <= apb_rcv_full and (not noc5_out_void);
  apb_rcv_data_in <= large_to_narrow_flit(noc5_out_data);
  apb_rcv_wrreq   <= (not noc5_out_void) and (not apb_rcv_full);
  fifo_8 : fifo0
    generic map (
      depth => 5,                       --Header, data up to 4 words
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => apb_rcv_rdreq,
      wrreq    => apb_rcv_wrreq,
      data_in  => apb_rcv_data_in,
      empty    => apb_rcv_empty,
      full     => apb_rcv_full,
      data_out => apb_rcv_data_out);

  -- To noc5: APB response
  noc5_in_data          <= narrow_to_large_flit(apb_snd_data_out);
  noc5_in_void          <= apb_snd_empty or noc5_in_stop;
  apb_snd_rdreq <= (not apb_snd_empty) and (not noc5_in_stop);
  fifo_11 : fifo0
    generic map (
      depth => 6,                       --Header, address, data (up to 4 words)
      width => MISC_NOC_FLIT_SIZE)
    port map (
      clk      => clk,
      rst      => fifo_rst,
      rdreq    => apb_snd_rdreq,
      wrreq    => apb_snd_wrreq,
      data_in  => apb_snd_data_in,
      empty    => apb_snd_empty,
      full     => apb_snd_full,
      data_out => apb_snd_data_out);

  -- Cachable data plane 1 -> request messages
  noc1_out_data <= noc_out_data(0);
  noc1_out_void <= noc_out_void(0);
  noc_out_stop(0) <= noc1_out_stop;
  noc_in_data(0)  <= noc1_in_data ;
  noc_in_void(0)  <= noc1_in_void ;
  noc1_in_stop  <= noc_in_stop(0);
  -- Cachable data plane 2 -> forwarded messages
  noc2_out_data <= noc_out_data(1);
  noc2_out_void <= noc_out_void(1);
  noc_out_stop(1) <= noc2_out_stop;
  noc_in_data(1)  <= noc2_in_data ;
  noc_in_void(1)  <= noc2_in_void ;
  noc2_in_stop  <= noc_in_stop(1);
  -- Cachable data plane 3 -> response messages
  noc3_out_data <= noc_out_data(2);
  noc3_out_void <= noc_out_void(2);
  noc_out_stop(2) <= noc3_out_stop;
  noc_in_data(2)  <= noc3_in_data ;
  noc_in_void(2)  <= noc3_in_void ;
  noc3_in_stop  <= noc_in_stop(2);
  -- Non cachable data data plane 4 -> DMA transfers response
  noc4_out_data <= noc_out_data(3);
  noc4_out_void <= noc_out_void(3);
  noc_out_stop(3) <= noc4_out_stop;
  noc_in_data(3)  <= noc4_in_data ;
  noc_in_void(3)  <= noc4_in_void ;
  noc4_in_stop  <= noc_in_stop(3);
  -- Configuration plane 5 -> RD/WR registers
  noc5_out_data <= noc_out_data(4);
  noc5_out_void <= noc_out_void(4);
  noc_out_stop(4) <= noc5_out_stop;
  noc_in_data(4)  <= noc5_in_data ;
  noc_in_void(4)  <= noc5_in_void ;
  noc5_in_stop  <= noc_in_stop(4);
  -- Non cachable data data plane 6 -> DMA transfers requests
  noc6_out_data <= noc_out_data(5);
  noc6_out_void <= noc_out_void(5);
  noc_out_stop(5) <= noc6_out_stop;
  noc_in_data(5)  <= noc6_in_data ;
  noc_in_void(5)  <= noc6_in_void ;
  noc6_in_stop  <= noc_in_stop(5);
end rtl;
