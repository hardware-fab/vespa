// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "dfmul_vivado.h"

typedef int64_t token_t;

/* <<--params-def-->> */
#define DFMUL_OUT 1
#define DFMUL_N 100
#define DFMUL_IN 2

/* <<--params-->> */
const int32_t dfmul_out = DFMUL_OUT;
const int32_t dfmul_n = DFMUL_N;
const int32_t dfmul_in = DFMUL_IN;

#define NACC 1

struct dfmul_vivado_access dfmul_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.dfmul_out = DFMUL_OUT,
		.dfmul_n = DFMUL_N,
		.dfmul_in = DFMUL_IN,
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
		.devname = "dfmul_vivado.0",
		.ioctl_req = DFMUL_VIVADO_IOC_ACCESS,
		.esp_desc = &(dfmul_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
