// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "adpcm_vivado.h"

typedef int32_t token_t;

/* <<--params-def-->> */
#define ADPCM_N 10
#define ADPCM_SIZE 2000

/* <<--params-->> */
const int32_t adpcm_n = ADPCM_N;
const int32_t adpcm_size = ADPCM_SIZE;

#define NACC 1

struct adpcm_vivado_access adpcm_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.adpcm_n = ADPCM_N,
		.adpcm_size = ADPCM_SIZE,
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
		.devname = "adpcm_vivado.0",
		.ioctl_req = ADPCM_VIVADO_IOC_ACCESS,
		.esp_desc = &(adpcm_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
