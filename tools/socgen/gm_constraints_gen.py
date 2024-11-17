#!/usr/bin/env python3

#----------------------------------------------------------------------------
#  This file is a part of the VESPA SoC Prototyping Framework
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the Apache 2.0 License.
#
# File:    esp.vhd
# Authors: Gabriele Montanaro
#          Andrea Galimberti
#          Davide Zoni
# Company: Politecnico di Milano
# Mail:    name.surname@polimi.it
#----------------------------------------------------------------------------

from collections import defaultdict
import math
from thirdparty import *

def print_constraints(esp_config, soc):

  fp = open('gm_dfs_constraints.xdc', 'w')
  
  #Print a header for a more readable file
  fp.write("#This is a custom constraints file automatically generated, that separates the mutually exclusive clocks produced by the dfs\n\n")
  
  #Find the tiles with pll
  pll_tile = [0 for x in range(esp_config.ntiles)]
  for i in range(0, esp_config.ntiles):
    if esp_config.tiles[i].has_pll == 1:
      pll_tile[esp_config.tiles[i].clk_region] = i
  
  #Find the path of the mux inside the dfs
  for i in range (0, esp_config.ndomain):
    dfs_path = ""
    
    #This is the tile containing the pll of the clock domain i
    t = esp_config.tiles[pll_tile[i]]
    
    #Delimitate each clock region with comments
    fp.write("\n\n\n\n###################################### DFS CLOCKS FOR DOMAIN " + str(i) + " ######################################\n\n\n")
  
    #When i=0, the dfs is in the top module
    if i == 0 :
      dfs_path = "interconnect_clock_dvfs.dvfs_manager_1/dfs_inst/"
    #When the tile is a CPU, the path is simpler
    elif t.cpu_id != -1 :
      dfs_path = "esp_1/tiles_gen[" + str(pll_tile[i]) + "].cpu_tile.tile_cpu_i/tile_cpu_1/dvfs_gen.dvfs_manager_1/dfs_inst/"
    #When the tile is an accelerator, the path is longer and depends also on the accelerator name
    else :
      dfs_path = "esp_1/tiles_gen[" + str(pll_tile[i]) + "].accelerator_tile.tile_acc_i/tile_acc_1/" + t.acc.lowercase_name + "_gen.noc_" + t.acc.lowercase_name + "_i/esp_acc_dma_1/with_dvfs.dvfs_manager_1/dfs_inst/"
    
    
    
    #Not really sure about this master clock honestly... what should it be?
    clk_mst = dfs_path + "mmcm_1/mmcm_adv_inst/CLKOUT0"
    clk_src_0 = dfs_path + "clock_mux/I0"
    clk_src_1 = dfs_path + "clock_mux/I1"
    clk_out = dfs_path + "clock_mux/O"
    
    mul_factor = 1;
    if(i==0):
      mul_factor = 2;

    fp.write("create_generated_clock -name dfs_clk_mst_" + str(i) + " [get_pins " + clk_mst + "]\n")
    fp.write("create_generated_clock -name dfs_clk_" + str(i) + "_0 -divide_by 1 -multiply_by " + str(mul_factor) + " -source [get_pins " + clk_src_0 + "] [get_pins " + clk_out + "]\n")
    fp.write("create_generated_clock -name dfs_clk_" + str(i) + "_1 -divide_by 1 -multiply_by " + str(mul_factor) + " -add -master dfs_clk_mst_" + str(i) + " -source [get_pins " + clk_src_1 + "] [get_pins " + clk_out + "]\n")
    fp.write("set_clock_groups -physically_exclusive -group dfs_clk_" + str(i) + "_0 -group dfs_clk_" + str(i) + "_1\n")
  
  #After all the clocks have been generated, I need to set them as -asynchronous with respect to each other and also to the original clock
  fp.write("\n\n\n\n###################################### SET CLOCKS ASYNC TO EACH OTHER ######################################\n\n\n")
  
  #The interconnect clock need to be asynchronous also w.r.t. external port clocks
  #fp.write("set_clock_groups -asynchronous -group [get_clocks erx_clk] -group [get_clocks dfs_clk_0_0]\n\n")
  #fp.write("set_clock_groups -asynchronous -group [get_clocks erx_clk] -group [get_clocks dfs_clk_0_1]\n\n")
  #fp.write("set_clock_groups -asynchronous -group [get_clocks etx_clk] -group [get_clocks dfs_clk_0_0]\n\n")
  #fp.write("set_clock_groups -asynchronous -group [get_clocks etx_clk] -group [get_clocks dfs_clk_0_1]\n\n")
  #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_0_0] -group [get_clocks *clk_mmi64]\n\n")
  #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_0_1] -group [get_clocks *clk_mmi64]\n\n\n")
  fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_0_0] -group [get_clocks clk_nobuf]\n")
  fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_0_1] -group [get_clocks clk_nobuf]\n")
  for i in range (0, esp_config.ndomain):

    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks clk_pll_i]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks clk_pll_i_1]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks clk_ref_p]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks profpga_clk0_p]\n\n\n")

    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks clk_pll_i]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks clk_pll_i_1]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks clk_ref_p]\n\n")
    #fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks profpga_clk0_p]\n\n\n")
    for j in range (0, i):
      if j != i :
        fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks dfs_clk_" + str(j) + "_0]\n")
        fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_0] -group [get_clocks dfs_clk_" + str(j) + "_1]\n")
        fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks dfs_clk_" + str(j) + "_0]\n")
        fp.write("set_clock_groups -asynchronous -group [get_clocks dfs_clk_" + str(i) + "_1] -group [get_clocks dfs_clk_" + str(j) + "_1]\n\n")
  fp.close()
  
