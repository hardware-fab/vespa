// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "dfadd_vivado.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define DFADD_OUT 1
#define DFADD_IN 2
#define DFADD_N 100

/* <<--params-->> */
const int32_t dfadd_out = DFADD_OUT;
const int32_t dfadd_in = DFADD_IN;
const int32_t dfadd_n = DFADD_N;

#define NACC 1

struct dfadd_vivado_access dfadd_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.dfadd_out = DFADD_OUT,
		.dfadd_in = DFADD_IN,
		.dfadd_n = DFADD_N,
		.src_offset = 0,
		.dst_offset = 0,
		.esp.coherence = ACC_COH_NONE,
		.esp.p2p_store = 0,
		.esp.p2p_nsrcs = 0,
		.esp.p2p_srcs = {"", "", "", ""},
	}
};

esp_thread_info_t cfg_000[] = {
	{
		.run = true,
		.devname = "dfadd_vivado.0",
		.ioctl_req = DFADD_VIVADO_IOC_ACCESS,
		.esp_desc = &(dfadd_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
