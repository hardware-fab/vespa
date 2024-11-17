// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "dfadd_vivado.h"

#define DRV_NAME	"dfadd_vivado"

/* <<--regs-->> */
#define DFADD_DFADD_OUT_REG 0x48
#define DFADD_DFADD_IN_REG 0x44
#define DFADD_DFADD_N_REG 0x40

struct dfadd_vivado_device {
	struct esp_device esp;
};

static struct esp_driver dfadd_driver;

static struct of_device_id dfadd_device_ids[] = {
	{
		.name = "SLD_DFADD_VIVADO",
	},
	{
		.name = "eb_303",
	},
	{
		.compatible = "sld,dfadd_vivado",
	},
	{ },
};

static int dfadd_devs;

static inline struct dfadd_vivado_device *to_dfadd(struct esp_device *esp)
{
	return container_of(esp, struct dfadd_vivado_device, esp);
}

static void dfadd_prep_xfer(struct esp_device *esp, void *arg)
{
	struct dfadd_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->dfadd_out, esp->iomem + DFADD_DFADD_OUT_REG);
	iowrite32be(a->dfadd_in, esp->iomem + DFADD_DFADD_IN_REG);
	iowrite32be(a->dfadd_n, esp->iomem + DFADD_DFADD_N_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool dfadd_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct dfadd_vivado_device *dfadd = to_dfadd(esp); */
	/* struct dfadd_vivado_access *a = arg; */

	return true;
}

static int dfadd_probe(struct platform_device *pdev)
{
	struct dfadd_vivado_device *dfadd;
	struct esp_device *esp;
	int rc;

	dfadd = kzalloc(sizeof(*dfadd), GFP_KERNEL);
	if (dfadd == NULL)
		return -ENOMEM;
	esp = &dfadd->esp;
	esp->module = THIS_MODULE;
	esp->number = dfadd_devs;
	esp->driver = &dfadd_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	dfadd_devs++;
	return 0;
 err:
	kfree(dfadd);
	return rc;
}

static int __exit dfadd_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct dfadd_vivado_device *dfadd = to_dfadd(esp);

	esp_device_unregister(esp);
	kfree(dfadd);
	return 0;
}

static struct esp_driver dfadd_driver = {
	.plat = {
		.probe		= dfadd_probe,
		.remove		= dfadd_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = dfadd_device_ids,
		},
	},
	.xfer_input_ok	= dfadd_xfer_input_ok,
	.prep_xfer	= dfadd_prep_xfer,
	.ioctl_cm	= DFADD_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct dfadd_vivado_access),
};

static int __init dfadd_init(void)
{
	return esp_driver_register(&dfadd_driver);
}

static void __exit dfadd_exit(void)
{
	esp_driver_unregister(&dfadd_driver);
}

module_init(dfadd_init)
module_exit(dfadd_exit)

MODULE_DEVICE_TABLE(of, dfadd_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("dfadd_vivado driver");
