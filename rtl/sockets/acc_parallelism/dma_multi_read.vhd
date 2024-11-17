------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    dma_multi_read.vhd
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


entity dma_multi_read is
  generic (
    N_CORES       : integer := 4
  );
  port (
    clk                           : in  std_logic;
    rst                           : in  std_logic;

    dma_chnl_data_mem             : in  std_logic_vector(DMA_CHNL_WIDTH-1 downto 0);
    dma_chnl_valid_mem            : in  std_logic;
    dma_chnl_ready_mem            : out std_logic;

    multi_dma_chnl_data_acc       : out multi_dma_chnl_data_t(N_CORES-1 downto 0);
    multi_dma_chnl_valid_acc      : out std_logic_vector(N_CORES-1 downto 0);
    multi_dma_chnl_ready_acc      : in std_logic_vector(N_CORES-1 downto 0);

    multi_dma_ctrl_data_reg       : in multi_dma_ctrl_data_t(N_CORES-1 downto 0);

    multi_ap_done                 : in std_logic_vector(N_CORES-1 downto 0)
  );
end entity dma_multi_read;


architecture rtl of dma_multi_read is

signal dma_chnl_data_mem_int    : std_logic_vector(DMA_CHNL_WIDTH-1 downto 0);
signal dma_chnl_valid_mem_int   : std_logic;
signal dma_chnl_ready_mem_int   : std_logic;

signal core_cnt, core_cnt_next  : integer := 0;
signal word_cnt, word_cnt_next  : integer := 0;

signal data_is_passing          : std_logic := '0';

signal num_word_transaction     : integer := 0;

begin

  --NO FIFO
  --dma_chnl_data_mem_int    <= dma_chnl_data_mem;
  --dma_chnl_valid_mem_int   <= dma_chnl_valid_mem;
  --dma_chnl_ready_mem       <= dma_chnl_ready_mem_int;

  --Control bool
  data_is_passing <= dma_chnl_valid_mem_int and multi_dma_chnl_ready_acc(core_cnt);

  --The amount of words in the transaction for each core is taken from the module that controls the dma_ctrl transaction (dma_ctrl_mux.vhd)
  num_word_transaction <= to_integer(unsigned(multi_dma_ctrl_data_reg(core_cnt)(REG_LENGTH-1 downto REG_LENGTH-REG_WIDTH)));

  --AXI-Stream assignments
  dma_chnl_ready_mem_int <= multi_dma_chnl_ready_acc(core_cnt);
  valid_and_data_assignment: process(dma_chnl_data_mem_int, dma_chnl_valid_mem_int, core_cnt)
  begin
    multi_dma_chnl_valid_acc <= (others => '0');
    multi_dma_chnl_data_acc <= (others => (others => '0'));
    multi_dma_chnl_valid_acc(core_cnt) <= dma_chnl_valid_mem_int;
    multi_dma_chnl_data_acc(core_cnt) <= dma_chnl_data_mem_int;
  end process valid_and_data_assignment;

  --A very easy run to completion arbitration, where in order each core receive its input data.
  always_comb_mux: process(core_cnt, word_cnt, data_is_passing, num_word_transaction, multi_ap_done)
  begin

    core_cnt_next <= core_cnt;
    word_cnt_next <= word_cnt;

    --If data is passing, it increments the word counter and eventually the core counter
    if data_is_passing = '1' then
      word_cnt_next <= word_cnt + 1;

      if word_cnt = num_word_transaction-1 then
        word_cnt_next <= 0;
        core_cnt_next <= core_cnt + 1;

        if core_cnt = N_CORES-1 then
          core_cnt_next <= 0;
        end if;

      end if;
    --If the core is done, skip to the next one (if the first one is done, then no action should be taken)
    elsif core_cnt /= 0 and multi_ap_done(core_cnt) = '1' then
      word_cnt_next <= 0;
      core_cnt_next <= core_cnt + 1;
      if core_cnt = N_CORES-1 then
        core_cnt_next <= 0;
      end if;
    end if;
  end process always_comb_mux;

  --Sequential process to update the counters
  always_ff_mux: process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        core_cnt <= 0;
        word_cnt <= 0;
      else
        core_cnt <= core_cnt_next;
        word_cnt <= word_cnt_next;
      end if;
    end if;
  end process always_ff_mux;

  --FIFO to debuffer operations and (hopefully) improve timing
  fifo_1: axis_fifo
  generic map (
      DEPTH         => 4,
      LOG2_DEPTH    => 2,
      WIDTH         => DMA_CHNL_WIDTH
    )

    port map (
      clk                           => clk,
      rst                           => rst,

      data_wr                       => dma_chnl_data_mem,
      valid_wr                      => dma_chnl_valid_mem,
      ready_wr                      => dma_chnl_ready_mem,

      data_rd                       => dma_chnl_data_mem_int,
      valid_rd                      => dma_chnl_valid_mem_int,
      ready_rd                      => dma_chnl_ready_mem_int
    );

end rtl;
