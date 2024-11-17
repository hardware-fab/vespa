# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

#-----------------------------------------------------------
#              Bitstream Configuration                     -
#-----------------------------------------------------------

set_property BITSTREAM.CONFIG.UNUSEDPIN Pullnone [current_design]
set_property BITSTREAM.GENERAL.COMPRESS True [current_design]

#-----------------------------------------------------------
#              Clock Pins                                  -
#-----------------------------------------------------------

#GM change: remove the constraints for the unused clocks
## {CLK_P_1}
#set_property IOSTANDARD LVDS [get_ports c0_main_clk_p]
#set_property PACKAGE_PIN AD41 [get_ports c0_main_clk_p]

## {CLK_N_1}
#set_property IOSTANDARD LVDS [get_ports c0_main_clk_n]
#set_property PACKAGE_PIN AE41 [get_ports c0_main_clk_n]

## {CLK_P_4}
#set_property IOSTANDARD LVDS [get_ports c0_main_clk_p]

## {CLK_N_4}
#set_property IOSTANDARD LVDS [get_ports c0_main_clk_n]
#set_property PACKAGE_PIN AF39 [get_ports c0_main_clk_p]
#set_property PACKAGE_PIN AG40 [get_ports c0_main_clk_n]


## {CLK_P_3}
#set_property IOSTANDARD LVDS [get_ports c1_main_clk_p]

## {CLK_N_3}
#set_property IOSTANDARD LVDS [get_ports c1_main_clk_n]
#set_property PACKAGE_PIN AC41 [get_ports c1_main_clk_p]
#set_property PACKAGE_PIN AB41 [get_ports c1_main_clk_n]

## {CLK_P_2}
#set_property IOSTANDARD LVDS [get_ports clk_ref_p]

## {CLK_N_2}
#set_property IOSTANDARD LVDS [get_ports clk_ref_n]
#set_property PACKAGE_PIN AA38 [get_ports clk_ref_p]
#set_property PACKAGE_PIN AA39 [get_ports clk_ref_n]


#-----------------------------------------------------------
#              UART                                        -
#-----------------------------------------------------------

## {eb_ba2_1_USB2UART_PVIO_A3_NCTS}
#set_property PACKAGE_PIN N33 [get_ports uart_rtsn]

## {eb_ba2_1_USB2UART_PVIO_A2_NRTS}
#set_property PACKAGE_PIN L29 [get_ports uart_ctsn]

## {eb_ba2_1_USB2UART_PVIO_A1_RXD}
#set_property PACKAGE_PIN L30 [get_ports uart_txd]

## {eb_ba2_1_USB2UART_PVIO_A0_TXD}
#set_property PACKAGE_PIN L32 [get_ports uart_rxd]

#set_property IOSTANDARD LVCMOS18 [get_ports {uart_*}]

#GM change: siccome non utilizzo i pin USB2UART (che immagino corrispondano alla board interface R5 che non ho), uso i pin sull'FPGA

set_property IOSTANDARD LVCMOS18 [get_ports uart_rxd]
set_property PACKAGE_PIN AC36 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS18 [get_ports uart_rts]
set_property PACKAGE_PIN AC37 [get_ports uart_rts]
set_property IOSTANDARD LVCMOS18 [get_ports uart_cts]
set_property PACKAGE_PIN AD38 [get_ports uart_cts]
set_property IOSTANDARD LVCMOS18 [get_ports uart_txd]
set_property PACKAGE_PIN AC38 [get_ports uart_txd]

#-----------------------------------------------------------
#              LEDs                                        -
#-----------------------------------------------------------

# {LED_RED}
set_property PACKAGE_PIN AD31 [get_ports LED_RED]

# {LED_GREEN}
set_property PACKAGE_PIN AD30 [get_ports LED_GREEN]

# {LED_BLUE}
set_property PACKAGE_PIN AC29 [get_ports LED_BLUE]

# {LED_YELLOW}
set_property PACKAGE_PIN AD29 [get_ports LED_YELLOW]

set_property IOSTANDARD LVCMOS18 [get_ports LED_*]

#GM change: aggiungo il button della DDR4 ai constraints
set_property  PACKAGE_PIN E35 [get_ports {button_ddr4}]
set_property IOSTANDARD LVCMOS18 [get_ports {button_ddr4}]

#-----------------------------------------------------------
#              Diagnostic LEDs                             -
#-----------------------------------------------------------

# {eb_ta1_1_LED01}
set_property IOSTANDARD LVCMOS15 [get_ports c0_calib_complete]
set_property PACKAGE_PIN K36 [get_ports c0_calib_complete]

# {eb_ta1_1_LED02}
set_property IOSTANDARD LVCMOS15 [get_ports c0_diagnostic_led]
set_property PACKAGE_PIN L35 [get_ports c0_diagnostic_led]

# {eb_ta2_1_LED01}
set_property IOSTANDARD LVCMOS15 [get_ports c1_calib_complete]
set_property PACKAGE_PIN AM26 [get_ports c1_calib_complete]

# {eb_ta2_1_LED02}
set_property IOSTANDARD LVCMOS15 [get_ports c1_diagnostic_led]
set_property PACKAGE_PIN AL28 [get_ports c1_diagnostic_led]


#-----------------------------------------------------------
#              Reset                                       -
#-----------------------------------------------------------

# {eb_ta1_1_SW1}
set_property IOSTANDARD LVCMOS15 [get_ports reset]
set_property PACKAGE_PIN J44 [get_ports reset]


#-----------------------------------------------------------
#              Timing constraints                          -
#-----------------------------------------------------------

#create_clock -period 5.000 [get_ports c0_main_clk_p]   #GM change

#create_clock -period 5.000 [get_ports c1_main_clk_p]   #GM change

#create_clock -period 5.000 [get_ports clk_ref_p]       #GM change

# Note: the following CLOCK_DEDICATED_ROUTE constraint will cause a warning in place similar
# to the following:
#   WARNING:Place:1402 - A clock IOB / PLL clock component pair have been found that are not
#   placed at an optimal clock IOB / PLL site pair.
# This warning can be ignored.  See the Users Guide for more information.

#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets c0_main_clk_p]     #GM change: Vivado throws an error during implementation
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets c1_main_clk_p]     #GM change
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_pins -hierarchical *pll*CLKIN1]   #GM change: no idea about what is this, but Vivado throws an error during implementation

# Recover elaborated clock name

# Both memory controllers impose their user clock. Make them asynchronous
#set_clock_groups -asynchronous -group [get_clocks [get_clocks -of_objects [get_nets clkm]]] -group [get_clocks [get_clocks -of_objects [get_nets clkm_2]]]     #GM change
#set_clock_groups -asynchronous -group [get_clocks [get_clocks -of_objects [get_nets clkm]]] -group [get_clocks [get_clocks -of_objects [get_nets chip_refclk]]] #GM change
#set_clock_groups -asynchronous -group [get_clocks [get_clocks -of_objects [get_nets clkm_2]]] -group [get_clocks [get_clocks -of_objects [get_nets chip_refclk]]] #GM change

#set_clock_groups -asynchronous -group [get_clocks clk_ref_p] -group [get_clocks [get_clocks -of_objects [get_nets clkm]]]  #GM change
#set_clock_groups -asynchronous -group [get_clocks clk_ref_p] -group [get_clocks [get_clocks -of_objects [get_nets clkm_2]]]  #GM change
#set_clock_groups -asynchronous -group [get_clocks clk_ref_p] -group [get_clocks [get_clocks -of_objects [get_nets chip_refclk]]]  #GM change

#-----------------------------------------------------------
#              False Paths                                 -
#-----------------------------------------------------------
set_false_path -from [get_ports reset]
set_false_path -to [get_ports LED_YELLOW]
set_false_path -to [get_ports LED_BLUE]
set_false_path -to [get_ports LED_GREEN]
set_false_path -to [get_ports LED_RED]



