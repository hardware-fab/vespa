// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "dfsin_vivado.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define DFSIN_IN 1
#define DFSIN_OUT 1
#define DFSIN_N 100

/* <<--params-->> */
const int32_t dfsin_in = DFSIN_IN;
const int32_t dfsin_out = DFSIN_OUT;
const int32_t dfsin_n = DFSIN_N;

#define NACC 1

struct dfsin_vivado_access dfsin_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.dfsin_in = DFSIN_IN,
		.dfsin_out = DFSIN_OUT,
		.dfsin_n = DFSIN_N,
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
		.devname = "dfsin_vivado.0",
		.ioctl_req = DFSIN_VIVADO_IOC_ACCESS,
		.esp_desc = &(dfsin_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
