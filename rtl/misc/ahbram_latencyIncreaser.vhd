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
------------------------------------------------------------------------------

--This module artificially increases the latency on an AHB channel, to simulate the behaviour of a DDR memory

--SUFFIXES:
--i: input
--o: output
--w: wire
--n: register input (assigned in combinatorial processes, read in sequential processes)
--r: register output (read in combinatorial processes, assigned in sequential processes)
--t: type
--cs: current state (read in combinatorial processes, assigned in sequential processes)
--ns: next state (assigned in combinatorial processes, read in sequential processes)
--S: state

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.amba.all;

entity ahbram_latencyIncreaser is
  generic (
    LATENCY_CYCLES  : integer := 20
  );
  port (
    rst_i           : in  std_ulogic;
    clk_i           : in  std_ulogic;
    noc_ahbsi_i     : in  ahb_slv_in_type;
    noc_ahbso_o     : out ahb_slv_out_type;
    mem_ahbsi_o     : out ahb_slv_in_type;
    mem_ahbso_i     : in  ahb_slv_out_type
  );
end;

architecture rtl of ahbram_latencyIncreaser is

signal first_trans_ahbsi_n, first_trans_ahbsi_r : ahb_slv_in_type;

signal latency_counter_n, latency_counter_r : integer range 0 to LATENCY_CYCLES;

type state_t is (IDLE_S, WAIT_S, RELEASE_S);
signal fsm_cs, fsm_ns : state_t;

begin

  --Memory output is connected directly to the NoC, except for the ready
  noc_ahbso_o.hresp       <=   mem_ahbso_i.hresp;
  noc_ahbso_o.hrdata      <=   mem_ahbso_i.hrdata;
  noc_ahbso_o.hsplit      <=   mem_ahbso_i.hsplit;
  noc_ahbso_o.hirq        <=   mem_ahbso_i.hirq;
  noc_ahbso_o.hconfig     <=   mem_ahbso_i.hconfig;
  noc_ahbso_o.hindex      <=   mem_ahbso_i.hindex;

  fsm_comb : process (all)
  begin
    fsm_ns <= fsm_cs;

    first_trans_ahbsi_n <= first_trans_ahbsi_r;
    latency_counter_n <= latency_counter_r;

    mem_ahbsi_o <= ahbs_in_none;
    noc_ahbso_o.hready <= mem_ahbso_i.hready;

    --IDLE state
    if fsm_cs = IDLE_S then
      --Start of a communication
      if noc_ahbsi_i.htrans = HTRANS_NONSEQ then
        fsm_ns <= WAIT_S;
        --Save the first packet and start waiting
        first_trans_ahbsi_n <= noc_ahbsi_i;
        latency_counter_n <= 0;
      end if;

    --WAIT: the module wait LATENCY_CYCLES clock cycles before issuing the first ahb packet to the memory
    elsif fsm_cs = WAIT_S then
      noc_ahbso_o.hready <= '0';
      latency_counter_n <= latency_counter_r + 1;
      if latency_counter_r = LATENCY_CYCLES - 1 then
        fsm_ns <= RELEASE_S;
        mem_ahbsi_o <= first_trans_ahbsi_r;
      end if;

    --RELEASE: this module becomes totally transparent and the communication can go on
    elsif fsm_cs = RELEASE_S then
      mem_ahbsi_o <= noc_ahbsi_i;
      --At the end of the communication, returns to IDLE
      if noc_ahbsi_i.htrans = HTRANS_IDLE then
        fsm_ns <= IDLE_S;
      end if;

    --DEFAULT
    else
      fsm_ns <= IDLE_S;
    end if;

  end process fsm_comb;

  fsm_seq : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        fsm_cs <= IDLE_S;
        first_trans_ahbsi_r    <= ahbs_in_none;
        latency_counter_r      <= 0;
      else
        fsm_cs <= fsm_ns;
        first_trans_ahbsi_r    <= first_trans_ahbsi_n;
        latency_counter_r      <= latency_counter_n;
      end if;
    end if;
  end process;

end;

