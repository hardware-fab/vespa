// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "dfsin_vivado.h"

#define DRV_NAME	"dfsin_vivado"

/* <<--regs-->> */
#define DFSIN_DFSIN_IN_REG 0x48
#define DFSIN_DFSIN_OUT_REG 0x44
#define DFSIN_DFSIN_N_REG 0x40

struct dfsin_vivado_device {
	struct esp_device esp;
};

static struct esp_driver dfsin_driver;

static struct of_device_id dfsin_device_ids[] = {
	{
		.name = "SLD_DFSIN_VIVADO",
	},
	{
		.name = "eb_306",
	},
	{
		.compatible = "sld,dfsin_vivado",
	},
	{ },
};

static int dfsin_devs;

static inline struct dfsin_vivado_device *to_dfsin(struct esp_device *esp)
{
	return container_of(esp, struct dfsin_vivado_device, esp);
}

static void dfsin_prep_xfer(struct esp_device *esp, void *arg)
{
	struct dfsin_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->dfsin_in, esp->iomem + DFSIN_DFSIN_IN_REG);
	iowrite32be(a->dfsin_out, esp->iomem + DFSIN_DFSIN_OUT_REG);
	iowrite32be(a->dfsin_n, esp->iomem + DFSIN_DFSIN_N_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool dfsin_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct dfsin_vivado_device *dfsin = to_dfsin(esp); */
	/* struct dfsin_vivado_access *a = arg; */

	return true;
}

static int dfsin_probe(struct platform_device *pdev)
{
	struct dfsin_vivado_device *dfsin;
	struct esp_device *esp;
	int rc;

	dfsin = kzalloc(sizeof(*dfsin), GFP_KERNEL);
	if (dfsin == NULL)
		return -ENOMEM;
	esp = &dfsin->esp;
	esp->module = THIS_MODULE;
	esp->number = dfsin_devs;
	esp->driver = &dfsin_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	dfsin_devs++;
	return 0;
 err:
	kfree(dfsin);
	return rc;
}

static int __exit dfsin_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct dfsin_vivado_device *dfsin = to_dfsin(esp);

	esp_device_unregister(esp);
	kfree(dfsin);
	return 0;
}

static struct esp_driver dfsin_driver = {
	.plat = {
		.probe		= dfsin_probe,
		.remove		= dfsin_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = dfsin_device_ids,
		},
	},
	.xfer_input_ok	= dfsin_xfer_input_ok,
	.prep_xfer	= dfsin_prep_xfer,
	.ioctl_cm	= DFSIN_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct dfsin_vivado_access),
};

static int __init dfsin_init(void)
{
	return esp_driver_register(&dfsin_driver);
}

static void __exit dfsin_exit(void)
{
	esp_driver_unregister(&dfsin_driver);
}

module_init(dfsin_init)
module_exit(dfsin_exit)

MODULE_DEVICE_TABLE(of, dfsin_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("dfsin_vivado driver");
