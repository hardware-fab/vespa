------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    dma_ctrl_mux.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.parallel_acc_pkg.all;


entity dma_ctrl_mux is
    generic (
      N_CORES       : integer := 4
    );
    port (
      clk                           : in  std_logic;
      rst                           : in  std_logic;

      multi_dma_ctrl_data_acc       : in  multi_dma_ctrl_data_t(N_CORES-1 downto 0);
      multi_dma_ctrl_valid_acc      : in  std_logic_vector(N_CORES-1 downto 0);
      multi_dma_ctrl_ready_acc      : out std_logic_vector(N_CORES-1 downto 0);

      dma_ctrl_data_mem             : out std_logic_vector(DMA_CTRL_WIDTH-1 downto 0);
      dma_ctrl_valid_mem            : out std_logic;
      dma_ctrl_ready_mem            : in  std_logic;

      multi_dma_ctrl_data_reg       : out multi_dma_ctrl_data_t(N_CORES-1 downto 0);

      multi_ap_done                 : in std_logic_vector(N_CORES-1 downto 0)
    );
end entity dma_ctrl_mux;


architecture rtl of dma_ctrl_mux is

signal dma_ctrl_valid_mem_int, dma_ctrl_ready_mem_int         : std_logic;
signal dma_ctrl_data_mem_int                                  : std_logic_vector(DMA_CTRL_WIDTH-1 downto 0);
signal multi_dma_ctrl_data_reg_ff                             : multi_dma_ctrl_data_t(N_CORES-1 downto 0);
signal length_sum, index_sum                                  : integer := 0;
signal data_is_passing                                        : std_logic := '0';


begin

  --NO FIFO
  --dma_ctrl_valid_mem <= dma_ctrl_valid_mem_int;
  --dma_ctrl_ready_mem_int <= dma_ctrl_ready_mem;
  --dma_ctrl_data_mem <= dma_ctrl_data_mem_int;

  data_is_passing <= dma_ctrl_valid_mem_int and dma_ctrl_ready_mem_int;


  --Input data multiplexing
  --Basically, it sums the inputs length and index to obtain a single dma transaction.
  --It seems that index is the address, length is the number of words in the transaction and size is the size of the words.
  dma_ctrl_data_mem_int(DMA_CTRL_WIDTH-1 downto REG_SIZE) <= (others => '0');
  dma_ctrl_data_mem_int(REG_SIZE-1 downto REG_LENGTH)    <= multi_dma_ctrl_data_acc(0)(REG_SIZE-1 downto REG_LENGTH);
  dma_ctrl_data_mem_int(REG_LENGTH-1 downto REG_INDEX) <= std_logic_vector(to_unsigned(length_sum, REG_WIDTH));
  dma_ctrl_data_mem_int(REG_INDEX-1 downto 0) <= std_logic_vector(to_unsigned(index_sum, REG_WIDTH));

  ctrl_regs: process(multi_dma_ctrl_data_acc, data_is_passing, multi_ap_done)
    variable length_sum_var : integer := 0;
    variable index_sum_var : integer := 0;
  begin
    length_sum_var := 0;
    index_sum_var := 0;
    for i in 0 to N_CORES-1 loop
      if multi_ap_done(i) = '0' then
        length_sum_var  := length_sum_var + to_integer(unsigned(multi_dma_ctrl_data_acc(i)(REG_LENGTH-1 downto REG_INDEX)));
        index_sum_var  := index_sum_var + to_integer(unsigned(multi_dma_ctrl_data_acc(i)(REG_INDEX-1 downto REG_INDEX-REG_WIDTH)));
      --If the accelerator is done, the contribution to the transaction length is zero and the contribution to the index is equal to the old one plus the old length
      else
        length_sum_var  := length_sum_var;
        index_sum_var  := index_sum_var + to_integer(unsigned(multi_dma_ctrl_data_reg_ff(i)(REG_INDEX-1 downto REG_INDEX-REG_WIDTH)))
                          + to_integer(unsigned(multi_dma_ctrl_data_reg_ff(i)(REG_LENGTH-1 downto REG_INDEX)));
      end if;
    end loop;
    length_sum <= length_sum_var;
    index_sum <= index_sum_var;
  end process ctrl_regs;


  --Management of the cores: basically it waits for all the cores to output valid data in order to issue a single transaction.
  --TODO: I don't know if it is the best way to do this. Maybe it's better to do separate transactions. Or maybe the first core can "anticipate" the requests of the subsequent cores.

  --Control valid signals
  ctrl_axis_valid: process(multi_dma_ctrl_valid_acc, multi_ap_done)
    variable valid_var : std_logic := '1';
  begin
    --Initializing with not multi_ap_done(0) ensures that if all accelerators are done no valid is issued
    valid_var := not multi_ap_done(0) and multi_dma_ctrl_valid_acc(0);
    for i in 1 to N_CORES-1 loop
      if multi_ap_done(i) = '0' then
        valid_var := valid_var and multi_dma_ctrl_valid_acc(i);
      end if;
    end loop;
    dma_ctrl_valid_mem_int <= valid_var;
  end process;

  --Control ready signals
  multi_dma_ctrl_ready_acc <= (others => '1') when data_is_passing = '1' else (others => '0');

  --Simple process to output a register containing the transaction information. It is useful for the module that will manage the actual data transaction.
  reg_out: process(clk) is
  begin
    if rising_edge(clk) then
      if rst = '1' then
        multi_dma_ctrl_data_reg_ff <= (others => (others => '0'));
      else
        for i in 0 to N_CORES-1 loop
          if multi_dma_ctrl_valid_acc(i) = '1' then
            multi_dma_ctrl_data_reg_ff(i) <= multi_dma_ctrl_data_acc(i);
          else
            multi_dma_ctrl_data_reg_ff(i) <= multi_dma_ctrl_data_reg_ff(i);
          end if;
        end loop;
      end if;
    end if;
  end process reg_out;
  multi_dma_ctrl_data_reg <= multi_dma_ctrl_data_reg_ff;

  --FIFO to debuffer operations and (hopefully) improve timing
  fifo_1: axis_fifo
  generic map (
      DEPTH         => 4,
      LOG2_DEPTH    => 2,
      WIDTH         => DMA_CTRL_WIDTH
    )

    port map (
      clk                           => clk,
      rst                           => rst,

      data_wr                       => dma_ctrl_data_mem_int,
      valid_wr                      => dma_ctrl_valid_mem_int,
      ready_wr                      => dma_ctrl_ready_mem_int,

      data_rd                       => dma_ctrl_data_mem,
      valid_rd                      => dma_ctrl_valid_mem,
      ready_rd                      => dma_ctrl_ready_mem
    );

end rtl;
