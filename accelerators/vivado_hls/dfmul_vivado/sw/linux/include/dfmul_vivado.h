// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef _DFMUL_VIVADO_H_
#define _DFMUL_VIVADO_H_

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

struct dfmul_vivado_access {
	struct esp_access esp;
	/* <<--regs-->> */
	unsigned dfmul_out;
	unsigned dfmul_n;
	unsigned dfmul_in;
	unsigned src_offset;
	unsigned dst_offset;
};

#define DFMUL_VIVADO_IOC_ACCESS	_IOW ('S', 0, struct dfmul_vivado_access)

#endif /* _DFMUL_VIVADO_H_ */
