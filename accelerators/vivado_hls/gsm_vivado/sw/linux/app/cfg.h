// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __ESP_CFG_000_H__
#define __ESP_CFG_000_H__

#include "libesp.h"
#include "gsm_vivado.h"

typedef int16_t token_t;

/* <<--params-def-->> */
#define GSM_MLEN 8
#define GSM_NLEN 160
#define GSM_N 100

/* <<--params-->> */
const int32_t gsm_mlen = GSM_MLEN;
const int32_t gsm_nlen = GSM_NLEN;
const int32_t gsm_n = GSM_N;

#define NACC 1

struct gsm_vivado_access gsm_cfg_000[] = {
	{
		/* <<--descriptor-->> */
		.gsm_mlen = GSM_MLEN,
		.gsm_nlen = GSM_NLEN,
		.gsm_n = GSM_N,
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
		.devname = "gsm_vivado.0",
		.ioctl_req = GSM_VIVADO_IOC_ACCESS,
		.esp_desc = &(gsm_cfg_000[0].esp),
	}
};

#endif /* __ESP_CFG_000_H__ */
