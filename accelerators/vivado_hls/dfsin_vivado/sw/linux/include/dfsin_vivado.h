// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _DFSIN_VIVADO_H_
#define _DFSIN_VIVADO_H_

#ifdef __KERNEL__
#include <linux/ioctl.h>
#include <linux/types.h>
#else
#include <sys/ioctl.h>
#include <stdint.h>
#ifndef __user
#define __user
#endif
#endif /* __KERNEL__ */

#include <esp.h>
#include <esp_accelerator.h>

struct dfsin_vivado_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned dfsin_in;
	unsigned dfsin_out;
	unsigned dfsin_n;
	unsigned src_offset;
	unsigned dst_offset;
};

#define DFSIN_VIVADO_IOC_ACCESS	_IOW ('S', 0, struct dfsin_vivado_access)

#endif /* _DFSIN_VIVADO_H_ */
