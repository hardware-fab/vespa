#
# SPDX-License-Identifier: GPL-2.0
#
# Copyright (C) 2019 FORTH-ICS/CARV
#		Panagiotis Peristerakis <perister@ics.forth.gr>
#

platform-objs-y += platform.o
platform-genflags-y += -DBASE_FREQ_MHZ=$(BASE_FREQ)
