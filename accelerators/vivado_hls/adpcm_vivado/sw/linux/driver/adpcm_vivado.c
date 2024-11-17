// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "adpcm_vivado.h"

#define DRV_NAME	"adpcm_vivado"

/* <<--regs-->> */
#define ADPCM_ADPCM_N_REG 0x44
#define ADPCM_ADPCM_SIZE_REG 0x40

struct adpcm_vivado_device {
	struct esp_device esp;
};

static struct esp_driver adpcm_driver;

static struct of_device_id adpcm_device_ids[] = {
	{
		.name = "SLD_ADPCM_VIVADO",
	},
	{
		.name = "eb_300",
	},
	{
		.compatible = "sld,adpcm_vivado",
	},
	{ },
};

static int adpcm_devs;

static inline struct adpcm_vivado_device *to_adpcm(struct esp_device *esp)
{
	return container_of(esp, struct adpcm_vivado_device, esp);
}

static void adpcm_prep_xfer(struct esp_device *esp, void *arg)
{
	struct adpcm_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->adpcm_n, esp->iomem + ADPCM_ADPCM_N_REG);
	iowrite32be(a->adpcm_size, esp->iomem + ADPCM_ADPCM_SIZE_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool adpcm_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct adpcm_vivado_device *adpcm = to_adpcm(esp); */
	/* struct adpcm_vivado_access *a = arg; */

	return true;
}

static int adpcm_probe(struct platform_device *pdev)
{
	struct adpcm_vivado_device *adpcm;
	struct esp_device *esp;
	int rc;

	adpcm = kzalloc(sizeof(*adpcm), GFP_KERNEL);
	if (adpcm == NULL)
		return -ENOMEM;
	esp = &adpcm->esp;
	esp->module = THIS_MODULE;
	esp->number = adpcm_devs;
	esp->driver = &adpcm_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	adpcm_devs++;
	return 0;
 err:
	kfree(adpcm);
	return rc;
}

static int __exit adpcm_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct adpcm_vivado_device *adpcm = to_adpcm(esp);

	esp_device_unregister(esp);
	kfree(adpcm);
	return 0;
}

static struct esp_driver adpcm_driver = {
	.plat = {
		.probe		= adpcm_probe,
		.remove		= adpcm_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = adpcm_device_ids,
		},
	},
	.xfer_input_ok	= adpcm_xfer_input_ok,
	.prep_xfer	= adpcm_prep_xfer,
	.ioctl_cm	= ADPCM_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct adpcm_vivado_access),
};

static int __init adpcm_init(void)
{
	return esp_driver_register(&adpcm_driver);
}

static void __exit adpcm_exit(void)
{
	esp_driver_unregister(&adpcm_driver);
}

module_init(adpcm_init)
module_exit(adpcm_exit)

MODULE_DEVICE_TABLE(of, adpcm_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("adpcm_vivado driver");
