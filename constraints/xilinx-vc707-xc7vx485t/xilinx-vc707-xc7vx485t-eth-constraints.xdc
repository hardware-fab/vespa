# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0
#-----------------------------------------------------------
# PCS/PMA constraints not generated by Vivado in sgmii.xdc -
#-----------------------------------------------------------

create_clock -period 8.000 -name gtrefclk [get_pins -hier *ibufds_gtrefclk/O]

set clkm_elab [get_clocks -of_objects [get_nets clkm]]
set refclk_elab [get_clocks -of_objects [get_nets chip_refclk]]
set clk125m_elab [get_clocks -of_objects [get_nets -hierarchical userclk2]]

# Ethernet is asynchronous w.r.t. MIG ui_clk
set_clock_groups -asynchronous -group [get_clocks ${clk125m_elab}] -group [get_clocks ${refclk_elab}]
set_clock_groups -asynchronous -group [get_clocks ${clk125m_elab}] -group [get_clocks ${clkm_elab}]

# Ethenret clocks require their own internal timing constraints
set_max_delay -from [get_clocks gtrefclk] -to [get_clocks {*TXOUTCLK* *RXOUTCLK*}] 8.000
set_max_delay -from [get_clocks -include_generated_clocks *TXOUTCLK*] -to [get_clocks {gtrefclk *RXOUTCLK*}] 8.000
set_max_delay -from [get_clocks *RXOUTCLK*] -to [get_clocks gtrefclk] 8.000
set_max_delay -from [get_clocks *RXOUTCLK*] -to [get_clocks -include_generated_clocks *TXOUTCLK*] 8.000

set_false_path -to [get_pins -hier -filter {name =~ *gpcs_pma_inst/MGT_RESET.RESET_INT_*/PRE }]


