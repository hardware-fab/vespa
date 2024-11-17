# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0
#TODO: Fix these constraints for all FPGA boards

#GM change: these clocks do not exists anymore
#set_clock_groups -physically_exclusive -group [get_clocks dvfs_clk0*] -group [get_clocks dvfs_clk1*] -group [get_clocks dvfs_clk2*] -group [get_clocks dvfs_clk3*]

#set_clock_groups -asynchronous -group [get_clocks *[get_clocks -of_objects [get_nets clkm]]*] -group [get_clocks dvfs_clk*]
#set_clock_groups -asynchronous -group [get_clocks *[get_clocks -of_objects [get_nets chip_refclk]]*] -group [get_clocks dvfs_clk*]

#set_clock_groups -asynchronous -group [get_clocks *mmi64*] -group [get_clocks dvfs_clk*]

# set_clock_groups -asynchronous -group [get_clocks *${clkm_elab}*] -group [get_clocks *iserdes_clk]
# set_clock_groups -asynchronous -group [get_clocks sync_pulse] -group [get_clocks mem_refclk]

#GM change: new clocks created with DFS (I think they should not be used anymore)
set_clock_groups -physically_exclusive -group clk_out1_clk_wiz_0 -group clk_out1_clk_wiz_0_1
set_clock_groups -physically_exclusive -group clk_out1_clk_wiz_0_2 -group clk_out1_clk_wiz_0_3
set_clock_groups -physically_exclusive -group clk_out1_clk_wiz_0_4 -group clk_out1_clk_wiz_0_5
set_clock_groups -physically_exclusive -group clk_out1_clk_wiz_0_6 -group clk_out1_clk_wiz_0_7
set_clock_groups -physically_exclusive -group clk_out1_clk_wiz_0_8 -group clk_out1_clk_wiz_0_9

#GM note: there are three attributes for clock groups: -asynchronous, -logically_exclusive and -physically_exclusive.
#   -asynchronous: there is one or more paths between the two clocks, but they should not be timed (e.g. a 2-clock fifo);
#   -logically_exclusive: the clocks never interact with each other, and each path between them is a false path;
#   -physically_exclusive: the clocks are defined on the same source pin, so no path exists between them (e.g. using MMCMs).


