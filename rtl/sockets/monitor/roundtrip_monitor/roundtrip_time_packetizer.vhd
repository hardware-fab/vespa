------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    roundtrip_time_packetizer.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
------------------------------------------------------------------------------

--This module send the average of the roundtrip time to the csr register through the NoC.
--Basically it convert a simple data in a NoC packet with the correct information
--
--SUFFIXES:
--i: input
--o: output
--n: input of a register (assigned in combinatorial processes, read in sequential processes)
--r: output of a register (read in combinatorial processes, assigned in sequential processes)
--w: wire (used only in combinatorial processes)
--t: type
--cs: current state (read in combinatorial processes, assigned in sequential processes)
--ns: next state (assigned in combinatorial processes, read in sequential processes)
--S: state
--f: functions

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nocpackage.all;
use work.esp_global.all;
use work.esp_csr_pkg.all;

entity roundtrip_time_packetizer is
  generic (
    DATA_WIDTH    : integer := 16;
    THIS_TILE_ID  : integer := 0
  );
  port (
    clk_i           : in  std_ulogic;
    rst_i           : in  std_ulogic;
    average_data_i            : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    average_valid_i           : in  std_logic;
    average_ready_o           : out std_logic;
    local_apb_snd_data_o      : out misc_noc_flit_type;
    local_apb_snd_wrreq_o     : out std_logic;
    local_apb_snd_full_i      : in  std_logic;
  );
end;

architecture rtl of roundtrip_time_packetizer is

  constant MISC_NOC_FLIT_DATA_SIZE : integer := 32;

  function get_x_from_id_f (tile_id : integer)
  return local_yx is
  variable ret_v : integer;
  begin
    ret_v := tile_id mod CFG_XLEN;
    return std_logic_vector(to_unsigned(ret_v, 3));
  end get_x_from_id_f;

  function get_y_from_id_f (tile_id : integer)
  return local_yx is
  variable ret_v : integer;
  begin
    ret_v := tile_id/CFG_YLEN;
    return std_logic_vector(to_unsigned(ret_v, 3));
  end get_y_from_id_f;

  type state_t is (IDLE_S, SEND_HEADER_S, SEND_ADDR_S, SEND_DATA_S);
  signal fsm_cs, fsm_ns : state_t;

  signal   averageData_n, averageData_r : std_logic_vector(MISC_NOC_FLIT_DATA_SIZE-1 downto 0);

  constant LOCAL_X                 : local_yx := get_x_from_id_f(THIS_TILE_ID);
  constant LOCAL_Y                 : local_yx := get_y_from_id_f(THIS_TILE_ID);

begin

  fsm_comb : process (all)
  begin
    fsm_ns <= fsm_cs;
    averageData_n <= averageData_r;

    average_ready_o <= '0';
    local_apb_snd_data_o <= (others => '0');
    local_apb_snd_wrreq_o <= '0';

    --IDLE: waiting for a valid data from the averager module
    if fsm_cs = IDLE_S then
      average_ready_o <= '1';
      if average_valid_i = '1' then
        fsm_ns <= SEND_HEADER_S;
        averageData_n <= (DATA_WIDTH downto 0 => average_data_i, others => '0');
      end if;

    --SEND_HEADER: sending the packet header
    elsif fsm_cs = SEND_HEADER_S then
      local_apb_snd_wrreq_o <= '1';
      local_apb_snd_data_o <= create_header(MISC_NOC_FLIT_SIZE, LOCAL_Y, LOCAL_X, LOCAL_Y, LOCAL_X, REQ_REG_WR, X"00");
      if local_apb_snd_full_i = '0' then
        fsm_ns <= SEND_ADDR_S;
      end if;

    --SEND_ADDR: sending the address
    elsif fsm_cs = SEND_ADDR_S then
      local_apb_snd_wrreq_o <= '1';
      local_apb_snd_data_o <= PREAMBLE_BODY & std_logic_vector(to_unsigned(TODO_CSR_ADDR, MISC_NOC_FLIT_DATA_SIZE));
      if local_apb_snd_full_i = '0' then
        fsm_ns <= SEND_DATA_S;
      end if;

    --SEND_DATA: sending the average through the packet
    elsif fsm_cs = SEND_DATA_S then
      local_apb_snd_wrreq_o <= '1';
      local_apb_snd_data_o <= PREAMBLE_TAIL & averageData_r;
      if local_apb_snd_full_i = '0' then
        fsm_ns <= IDLE_S;
      end if;

    else
      fsm_ns <= IDLE_S;
    end if;
  end process fsm_comb;

  fsm_seq : process (clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '0' then
        fsm_cs <= IDLE_S;
        averageData_r <= (others => '0');
      else
        fsm_cs <= fsm_ns;
        averageData_r <= averageData_n;
      end if;
    end if;
  end process;

end;


