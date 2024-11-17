// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "dfmul_vivado.h"

#define DRV_NAME	"dfmul_vivado"

/* <<--regs-->> */
#define DFMUL_DFMUL_OUT_REG 0x48
#define DFMUL_DFMUL_N_REG 0x44
#define DFMUL_DFMUL_IN_REG 0x40

struct dfmul_vivado_device {
	struct esp_device esp;
};

static struct esp_driver dfmul_driver;

static struct of_device_id dfmul_device_ids[] = {
	{
		.name = "SLD_DFMUL_VIVADO",
	},
	{
		.name = "eb_305",
	},
	{
		.compatible = "sld,dfmul_vivado",
	},
	{ },
};

static int dfmul_devs;

static inline struct dfmul_vivado_device *to_dfmul(struct esp_device *esp)
{
	return container_of(esp, struct dfmul_vivado_device, esp);
}

static void dfmul_prep_xfer(struct esp_device *esp, void *arg)
{
	struct dfmul_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->dfmul_out, esp->iomem + DFMUL_DFMUL_OUT_REG);
	iowrite32be(a->dfmul_n, esp->iomem + DFMUL_DFMUL_N_REG);
	iowrite32be(a->dfmul_in, esp->iomem + DFMUL_DFMUL_IN_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool dfmul_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct dfmul_vivado_device *dfmul = to_dfmul(esp); */
	/* struct dfmul_vivado_access *a = arg; */

	return true;
}

static int dfmul_probe(struct platform_device *pdev)
{
	struct dfmul_vivado_device *dfmul;
	struct esp_device *esp;
	int rc;

	dfmul = kzalloc(sizeof(*dfmul), GFP_KERNEL);
	if (dfmul == NULL)
		return -ENOMEM;
	esp = &dfmul->esp;
	esp->module = THIS_MODULE;
	esp->number = dfmul_devs;
	esp->driver = &dfmul_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	dfmul_devs++;
	return 0;
 err:
	kfree(dfmul);
	return rc;
}

static int __exit dfmul_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct dfmul_vivado_device *dfmul = to_dfmul(esp);

	esp_device_unregister(esp);
	kfree(dfmul);
	return 0;
}

static struct esp_driver dfmul_driver = {
	.plat = {
		.probe		= dfmul_probe,
		.remove		= dfmul_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = dfmul_device_ids,
		},
	},
	.xfer_input_ok	= dfmul_xfer_input_ok,
	.prep_xfer	= dfmul_prep_xfer,
	.ioctl_cm	= DFMUL_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct dfmul_vivado_access),
};

static int __init dfmul_init(void)
{
	return esp_driver_register(&dfmul_driver);
}

static void __exit dfmul_exit(void)
{
	esp_driver_unregister(&dfmul_driver);
}

module_init(dfmul_init)
module_exit(dfmul_exit)

MODULE_DEVICE_TABLE(of, dfmul_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("dfmul_vivado driver");
