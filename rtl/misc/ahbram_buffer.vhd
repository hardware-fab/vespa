------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    copy_results.py
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
------------------------------------------------------------------------------

--This module is a buffer for the AHB bus connecting the BRAM memory and the NoC interface.

--SUFFIXES:
--i: input
--o: output
--w: wire (assigned in combinatorial processes, read in sequential processes)
--r: register (read in combinatorial processes, assigned in sequential processes)
--t: type
--n: active low
--cs: current state (read in combinatorial processes, assigned in sequential processes)
--ns: next state (assigned in combinatorial processes, read in sequential processes)
--S: state

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.config_types.all;
use work.config.all;
use work.amba.all;
use work.stdlib.all;
use work.devices.all;
use work.gencomp.all;
use work.esp_global.all;

entity ahbram_buffer is
  port (
    rst_i           : in  std_ulogic;
    clk_i           : in  std_ulogic;
    noc_ahbsi_i     : in  ahb_slv_in_type;
    noc_ahbso_o     : out ahb_slv_out_type;
    mem_ahbsi_o     : out ahb_slv_in_type;
    mem_ahbso_i     : in  ahb_slv_out_type
  );
end;

architecture rtl of ahbram_buffer is

signal noc_ahbso_ready_w, noc_ahbso_ready_r               : std_logic;
signal noc_ahbso_rdata_w, noc_ahbso_rdata_r               : std_logic_vector(AHBDW-1 downto 0);
signal noc_ahbso_rdata_old_w, noc_ahbso_rdata_old_r       : std_logic_vector(AHBDW-1 downto 0);

signal mem_ahbsi_addr_w                                   : std_logic_vector(GLOB_PHYS_ADDR_BITS-1 downto 0);
signal mem_ahbsi_trans_w                                  : std_logic_vector(1 downto 0);

signal mem_ahbsi_w                                        : ahb_slv_in_type;
signal noc_ahbso_w                                        : ahb_slv_out_type;

type state_t is (IDLE_S, FIRST_TRANS_S, SEQ_S, BUSY_S);
signal fsm_cs, fsm_ns : state_t;

constant UNSIGNED_ONE : unsigned (GLOB_PHYS_ADDR_BITS-1 downto 0) := (0 => '1', others => '0');

begin

  --Internal assignments

  --This two signals are useful since only a couple of AHB signals are actually modified in the fsm
  mem_ahbsi_w.hsel        <=   noc_ahbsi_i.hsel;
  mem_ahbsi_w.haddr       <=   mem_ahbsi_addr_w;
  mem_ahbsi_w.hwrite      <=   noc_ahbsi_i.hwrite;
  mem_ahbsi_w.htrans      <=   mem_ahbsi_trans_w;
  mem_ahbsi_w.hsize       <=   noc_ahbsi_i.hsize;
  mem_ahbsi_w.hburst      <=   noc_ahbsi_i.hburst;
  mem_ahbsi_w.hwdata      <=   noc_ahbsi_i.hwdata;
  mem_ahbsi_w.hprot       <=   noc_ahbsi_i.hprot;
  mem_ahbsi_w.hready      <=   noc_ahbsi_i.hready;
  mem_ahbsi_w.hmaster     <=   noc_ahbsi_i.hmaster;
  mem_ahbsi_w.hmastlock   <=   noc_ahbsi_i.hmastlock;
  mem_ahbsi_w.hmbsel      <=   noc_ahbsi_i.hmbsel;
  mem_ahbsi_w.hirq        <=   noc_ahbsi_i.hirq;
  mem_ahbsi_w.testen      <=   noc_ahbsi_i.testen;
  mem_ahbsi_w.testrst     <=   noc_ahbsi_i.testrst;
  mem_ahbsi_w.scanen      <=   noc_ahbsi_i.scanen;
  mem_ahbsi_w.testoen     <=   noc_ahbsi_i.testoen;
  mem_ahbsi_w.testin      <=   noc_ahbsi_i.testin;

  noc_ahbso_w.hready      <=   noc_ahbso_ready_r;
  noc_ahbso_w.hresp       <=   mem_ahbso_i.hresp;
  noc_ahbso_w.hrdata      <=   noc_ahbso_rdata_r;
  noc_ahbso_w.hsplit      <=   mem_ahbso_i.hsplit;
  noc_ahbso_w.hirq        <=   mem_ahbso_i.hirq;
  noc_ahbso_w.hconfig     <=   mem_ahbso_i.hconfig;
  noc_ahbso_w.hindex      <=   mem_ahbso_i.hindex;


  --Output assignments

  --No buffer on the slave input. During writing transactions, the state machine is basically useless.
  mem_ahbsi_o <= noc_ahbsi_i when noc_ahbsi_i.hwrite = '1' else
                 mem_ahbsi_w;

  noc_ahbso_o <= noc_ahbso_w;


  fsm_comb : process (all)
  begin
    fsm_ns <= fsm_cs;

    noc_ahbso_ready_w <= '1';
    noc_ahbso_rdata_w <= mem_ahbso_i.hrdata;
    mem_ahbsi_addr_w <= noc_ahbsi_i.haddr;
    mem_ahbsi_trans_w <= noc_ahbsi_i.htrans;

    noc_ahbso_rdata_old_w <= noc_ahbso_rdata_old_r;

    --IDLE state
    if fsm_cs = IDLE_S then
      --Start of a communication
      if noc_ahbsi_i.htrans = HTRANS_NONSEQ and noc_ahbsi_i.hwrite = '0' then
        fsm_ns <= FIRST_TRANS_S;
        --If the transaction is NONSEQ, the memory is not able to output the correct data in the next clock cycle
        --(due to the one clock cycle latency introduced by this module), so it lowers the ready signal
        noc_ahbso_ready_w   <= '0';
      end if;

    --FIRST TRANS: first data exchange in the burst
    elsif fsm_cs = FIRST_TRANS_S then
      if noc_ahbsi_i.htrans = HTRANS_IDLE then
        fsm_ns <= IDLE_S;
      elsif noc_ahbsi_i.htrans = HTRANS_SEQ then
        fsm_ns <= SEQ_S;
      elsif noc_ahbsi_i.htrans = HTRANS_BUSY then
        --Sending a SEQ to the memory allows to take advantage of this extra clock cycle the same way a low read does
        fsm_ns <= SEQ_S;
        mem_ahbsi_trans_w <= HTRANS_SEQ;
      end if;

    --SEQ: the transaction is executing a burst
    elsif fsm_cs = SEQ_S then
      mem_ahbsi_addr_w <= std_logic_vector(unsigned(noc_ahbsi_i.haddr) + shift_left(UNSIGNED_ONE, to_integer(unsigned(noc_ahbsi_i.hsize))));
      if noc_ahbsi_i.htrans = HTRANS_IDLE then
        fsm_ns <= IDLE_S;
      elsif noc_ahbsi_i.htrans = HTRANS_BUSY then
        fsm_ns <= BUSY_S;
        --When the transaction is busy, it saves the output of the mem in order to send it when the transaction restart
        noc_ahbso_rdata_old_w <= mem_ahbso_i.hrdata;
      end if;

    --BUSY: the NoC is issuing a busy transaction
    elsif fsm_cs = BUSY_S then
      mem_ahbsi_addr_w <= std_logic_vector(unsigned(noc_ahbsi_i.haddr) + shift_left(UNSIGNED_ONE, to_integer(unsigned(noc_ahbsi_i.hsize))));
      if noc_ahbsi_i.htrans = HTRANS_IDLE then
        fsm_ns <= IDLE_S;
      elsif noc_ahbsi_i.htrans = HTRANS_SEQ then
        fsm_ns <= SEQ_S;
        --When the communication restarts, it sends the preserved output
        noc_ahbso_rdata_w <= noc_ahbso_rdata_old_r;
      end if;
    end if;
  end process fsm_comb;

  fsm_seq : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        fsm_cs <= IDLE_S;
        noc_ahbso_ready_r      <=  '0';
        noc_ahbso_rdata_r      <=  (others => '0');
        noc_ahbso_rdata_old_r  <=  (others => '0');
      else
        fsm_cs <= fsm_ns;
        noc_ahbso_ready_r      <=  noc_ahbso_ready_w;
        noc_ahbso_rdata_r      <=  noc_ahbso_rdata_w;
        noc_ahbso_rdata_old_r  <=  noc_ahbso_rdata_old_w;
      end if;
    end if;
  end process;

end;

