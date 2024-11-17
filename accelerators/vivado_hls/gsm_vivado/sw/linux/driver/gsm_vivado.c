// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include <linux/of_device.h>
#include <linux/mm.h>

#include <asm/io.h>

#include <esp_accelerator.h>
#include <esp.h>

#include "gsm_vivado.h"

#define DRV_NAME	"gsm_vivado"

/* <<--regs-->> */
#define GSM_GSM_MLEN_REG 0x48
#define GSM_GSM_NLEN_REG 0x44
#define GSM_GSM_N_REG 0x40

struct gsm_vivado_device {
	struct esp_device esp;
};

static struct esp_driver gsm_driver;

static struct of_device_id gsm_device_ids[] = {
	{
		.name = "SLD_GSM_VIVADO",
	},
	{
		.name = "eb_307",
	},
	{
		.compatible = "sld,gsm_vivado",
	},
	{ },
};

static int gsm_devs;

static inline struct gsm_vivado_device *to_gsm(struct esp_device *esp)
{
	return container_of(esp, struct gsm_vivado_device, esp);
}

static void gsm_prep_xfer(struct esp_device *esp, void *arg)
{
	struct gsm_vivado_access *a = arg;

	/* <<--regs-config-->> */
	iowrite32be(a->gsm_mlen, esp->iomem + GSM_GSM_MLEN_REG);
	iowrite32be(a->gsm_nlen, esp->iomem + GSM_GSM_NLEN_REG);
	iowrite32be(a->gsm_n, esp->iomem + GSM_GSM_N_REG);
	iowrite32be(a->src_offset, esp->iomem + SRC_OFFSET_REG);
	iowrite32be(a->dst_offset, esp->iomem + DST_OFFSET_REG);

}

static bool gsm_xfer_input_ok(struct esp_device *esp, void *arg)
{
	/* struct gsm_vivado_device *gsm = to_gsm(esp); */
	/* struct gsm_vivado_access *a = arg; */

	return true;
}

static int gsm_probe(struct platform_device *pdev)
{
	struct gsm_vivado_device *gsm;
	struct esp_device *esp;
	int rc;

	gsm = kzalloc(sizeof(*gsm), GFP_KERNEL);
	if (gsm == NULL)
		return -ENOMEM;
	esp = &gsm->esp;
	esp->module = THIS_MODULE;
	esp->number = gsm_devs;
	esp->driver = &gsm_driver;
	rc = esp_device_register(esp, pdev);
	if (rc)
		goto err;

	gsm_devs++;
	return 0;
 err:
	kfree(gsm);
	return rc;
}

static int __exit gsm_remove(struct platform_device *pdev)
{
	struct esp_device *esp = platform_get_drvdata(pdev);
	struct gsm_vivado_device *gsm = to_gsm(esp);

	esp_device_unregister(esp);
	kfree(gsm);
	return 0;
}

static struct esp_driver gsm_driver = {
	.plat = {
		.probe		= gsm_probe,
		.remove		= gsm_remove,
		.driver		= {
			.name = DRV_NAME,
			.owner = THIS_MODULE,
			.of_match_table = gsm_device_ids,
		},
	},
	.xfer_input_ok	= gsm_xfer_input_ok,
	.prep_xfer	= gsm_prep_xfer,
	.ioctl_cm	= GSM_VIVADO_IOC_ACCESS,
	.arg_size	= sizeof(struct gsm_vivado_access),
};

static int __init gsm_init(void)
{
	return esp_driver_register(&gsm_driver);
}

static void __exit gsm_exit(void)
{
	esp_driver_unregister(&gsm_driver);
}

module_init(gsm_init)
module_exit(gsm_exit)

MODULE_DEVICE_TABLE(of, gsm_device_ids);

MODULE_AUTHOR("Emilio G. Cota <cota@braap.org>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("gsm_vivado driver");
