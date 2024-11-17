------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    axis_fifo.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity axis_fifo is
    generic (
      DEPTH         : integer := 8;
      LOG2_DEPTH    : integer := 3;
      WIDTH         : integer := 32
    );

    port (
      clk                           : in  std_ulogic;
      rst                           : in  std_ulogic;

      data_wr                       : in  std_logic_vector(WIDTH-1 downto 0);
      valid_wr                      : in  std_logic;
      ready_wr                      : out std_logic;

      data_rd                       : out std_logic_vector(WIDTH-1 downto 0);
      valid_rd                      : out std_logic;
      ready_rd                      : in  std_logic
    );
end entity axis_fifo;


architecture rtl of axis_fifo is

    signal is_writing, is_reading               : std_logic;
    signal wr_ptr, rd_ptr, count                : integer range 0 to DEPTH := 0;
    signal full, empty                          : std_logic;

    type mem_type is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal mem                                  : mem_type;

begin

    --Basic assignments
    full <= '1' when count = DEPTH else '0';
    empty <= '1' when count = 0 else '0';

    valid_rd <= not empty;
    ready_wr <= not full;

    is_writing <= (not full) and valid_wr;
    is_reading <= (not empty) and ready_rd;

    --Write pointer computation
    wr_ptr_comp: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wr_ptr <= 0;
            else
                if is_writing = '1' then
                    wr_ptr <= wr_ptr + 1;
                    if (wr_ptr = DEPTH-1) then
                        wr_ptr <= 0;
                    end if;
                    mem(wr_ptr) <= data_wr;
                else
                    wr_ptr <= wr_ptr;
                end if;
            end if;
        end if;
    end process wr_ptr_comp;

    --Read pointer computation
    rd_ptr_comp: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rd_ptr <= 0;
            else
                if is_reading = '1' then
                    rd_ptr <= rd_ptr + 1;
                    if (rd_ptr = DEPTH-1) then
                        rd_ptr <= 0;
                    end if;
                else
                    rd_ptr <= rd_ptr;
                end if;
            end if;
        end if;
    end process rd_ptr_comp;
    data_rd <= mem(rd_ptr);

    --Counter
    count_comp: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                count <= 0;
            else
                if is_reading = '1' and is_writing = '0' then
                    count <= count - 1;
                elsif is_writing = '1' and is_reading = '0' then
                    count <= count + 1;
                else
                    count <= count;
                end if;
            end if;
        end if;
    end process count_comp;

end rtl;
