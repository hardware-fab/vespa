------------------------------------------------------------------------------
--  This file is a part of the VESPA SoC Prototyping Framework
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the Apache 2.0 License.
--
-- File:    parallel_acc_pkg.vhd
-- Authors: Gabriele Montanaro
--          Andrea Galimberti
--          Davide Zoni
-- Company: Politecnico di Milano
-- Mail:    name.surname@polimi.it
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package parallel_acc_pkg is

  constant DMA_CTRL_WIDTH         : integer := 96;
  constant DMA_CHNL_WIDTH         : integer := 64;

  constant REG_WIDTH              : integer := 32;
  constant REG_INDEX              : integer := REG_WIDTH;
  constant REG_LENGTH             : integer := REG_INDEX + REG_WIDTH;
  constant REG_SIZE               : integer := REG_LENGTH + 3;


  type multi_dma_ctrl_data_t is array (integer range <>) of std_logic_vector(DMA_CTRL_WIDTH-1 downto 0);
  type multi_dma_chnl_data_t is array (integer range <>) of std_logic_vector(DMA_CHNL_WIDTH-1 downto 0);

  component axis_fifo is
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
  end component axis_fifo;

  component dma_ctrl_mux is
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
  end component dma_ctrl_mux;

  component dma_multi_read is
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
  end component dma_multi_read;

  component dma_multi_write is
    generic (
      N_CORES       : integer := 4
    );
    port (
      clk                           : in  std_logic;
      rst                           : in  std_logic;

      dma_chnl_data_mem             : out std_logic_vector(DMA_CHNL_WIDTH-1 downto 0);
      dma_chnl_valid_mem            : out std_logic;
      dma_chnl_ready_mem            : in  std_logic;

      multi_dma_chnl_data_acc       : in  multi_dma_chnl_data_t(N_CORES-1 downto 0);
      multi_dma_chnl_valid_acc      : in  std_logic_vector(N_CORES-1 downto 0);
      multi_dma_chnl_ready_acc      : out std_logic_vector(N_CORES-1 downto 0);

      multi_dma_ctrl_data_reg       : in  multi_dma_ctrl_data_t(N_CORES-1 downto 0);

      multi_ap_done                 : in std_logic_vector(N_CORES-1 downto 0)
    );
  end component dma_multi_write;

end parallel_acc_pkg;
