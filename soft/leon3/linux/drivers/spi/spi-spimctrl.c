/*
 * Driver for Aeroflex Gaisler SPIMCTRL
 *
 * SPIMCTRL maps SPI flash devices in a read-only memory area and also provides
 * a register interface that allows any SPI command to be sent. This driver only
 * makes use of the register interface.
 *
 * Copyright (c) 2011 Jan Andersson <jan@gaisler.com>
 *
 * This driver is based on:
 *
 * Altera SPI driver
 * Copyright (C) 2008 Thomas Chou <thomas@wytron.com.tw>
 * which in turn was based on spi_s3c24xx.c, which is:
 * Copyright (c) 2006 Ben Dooks
 * Copyright (c) 2006 Simtec Electronics
 *	Ben Dooks <ben@simtec.co.uk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/module.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/errno.h>
#include <linux/platform_device.h>
#include <linux/spi/spi.h>
#include <linux/spi/spi_bitbang.h>
#include <linux/io.h>
#include <linux/of_irq.h>

#define DRV_NAME "grlib-spimctrl"

/* Core has one chip-select only */
#define GR_SPIM_NUMCS	1

/* Register offsets */
#define GR_SPIM_CTRL	0x04
#define GR_SPIM_STAT	0x08
#define GR_SPIM_RX	0x0C
#define GR_SPIM_TX	0x10

/* Register fields */
#define GR_SPIM_CTRL_CSN	(1 << 3)
#define GR_SPIM_CTRL_IEN	(1 << 1)
#define GR_SPIM_CTRL_USRC	(1 << 0)

#define GR_SPIM_STAT_BUSY	(1 << 1)
#define GR_SPIM_STAT_DONE	(1 << 0)


struct gr_spimctrl {
	/* bitbang has to be first */
	struct spi_bitbang bitbang;
	struct completion done;

	void __iomem *base;
	int irq;
	int len;
	int count;
	u32 ctrl;

	/* data buffers */
	const unsigned char *tx;
	unsigned char *rx;
};

static inline void gr_spim_write(u32 val, void __iomem *addr)
{
	iowrite32be(val, addr);
}

static inline u32 gr_spim_read(void __iomem *addr)
{
	return ioread32be(addr);
}


static inline struct gr_spimctrl *gr_spimctrl_spi_to_hw(struct spi_device *sdev)
{
	return spi_master_get_devdata(sdev->master);
}

static void gr_spimctrl_chipsel(struct spi_device *spi, int value)
{
	struct gr_spimctrl *hw = gr_spimctrl_spi_to_hw(spi);
	u32 ctrl = hw->ctrl;

	if (spi->mode & SPI_CS_HIGH) {
		switch (value) {
		case BITBANG_CS_INACTIVE:
			hw->ctrl &= ~GR_SPIM_CTRL_CSN;
			break;

		case BITBANG_CS_ACTIVE:
			hw->ctrl |= GR_SPIM_CTRL_CSN;
			break;
		}
	} else {
		switch (value) {
		case BITBANG_CS_INACTIVE:
			hw->ctrl |= GR_SPIM_CTRL_CSN;
			break;

		case BITBANG_CS_ACTIVE:
			hw->ctrl &= ~GR_SPIM_CTRL_CSN;
			break;
		}
	}
	if (ctrl != hw->ctrl)
		gr_spim_write(hw->ctrl, hw->base + GR_SPIM_CTRL);
}

static int gr_spimctrl_setupxfer(struct spi_device *spi, struct spi_transfer *t)
{
	/* the controller does not support mode changes so we just ignore them.
	 * we can assume that the controller is attached to a memory device and
	 * that the controller can communicate with this device.
	 */

	if (t && t->bits_per_word % 8)
		return -EINVAL;

	if (spi->bits_per_word % 8)
		return -EINVAL;

	if (spi->chip_select > GR_SPIM_NUMCS)
		return -EINVAL;

	return 0;
}

static int gr_spimctrl_setup(struct spi_device *spi)
{
	return gr_spimctrl_setupxfer(spi, NULL);
}

static void gr_spimctrl_cleanup(struct spi_device *spi)
{
	struct gr_spimctrl *hw = gr_spimctrl_spi_to_hw(spi);

	hw->ctrl &= ~GR_SPIM_CTRL_USRC;
	gr_spim_write(hw->ctrl, hw->base + GR_SPIM_CTRL);
}

static int gr_spimctrl_txrx(struct spi_device *spi, struct spi_transfer *t)
{
	struct gr_spimctrl *hw = gr_spimctrl_spi_to_hw(spi);

	hw->tx = t->tx_buf;
	hw->rx = t->rx_buf;
	hw->count = 0;
	hw->len = t->len;

	if (hw->irq != NO_IRQ) {
		/* interrupt driven transfer, send the first byte */
		gr_spim_write(GR_SPIM_STAT_DONE, hw->base + GR_SPIM_STAT);
		gr_spim_write(hw->tx ? *hw->tx++ : 0, hw->base + GR_SPIM_TX);
		wait_for_completion(&hw->done);
	} else {
		/* polling */
		do {
			/* clear done bit, transmit, wait for receive .. */
			gr_spim_write(GR_SPIM_STAT_DONE,
				hw->base + GR_SPIM_STAT);

			gr_spim_write(hw->tx ? *hw->tx++ : 0,
				hw->base + GR_SPIM_TX);

			while (!(gr_spim_read(hw->base + GR_SPIM_STAT) &
					GR_SPIM_STAT_DONE))
				cpu_relax();

			if (hw->rx)
				hw->rx[hw->count] =
					gr_spim_read(hw->base + GR_SPIM_RX);

			hw->count++;
		} while (hw->count < hw->len);
	}

	return hw->count;
}

static irqreturn_t gr_spimctrl_irq(int irq, void *dev)
{
	struct gr_spimctrl *hw = dev;
	u32 rxd;

	if (!(gr_spim_read(hw->base + GR_SPIM_STAT) & GR_SPIM_STAT_DONE))
		return IRQ_NONE;

	if (hw->rx) {
		rxd = gr_spim_read(hw->base + GR_SPIM_RX);
		hw->rx[hw->count] = rxd;
	}

	hw->count++;

	gr_spim_write(GR_SPIM_STAT_DONE, hw->base + GR_SPIM_STAT);

	if (hw->count < hw->len)
		gr_spim_write(hw->tx ? *hw->tx++ : 0, hw->base + GR_SPIM_TX);
	else
		complete(&hw->done);

	return IRQ_HANDLED;
}

static int gr_spimctrl_probe(struct platform_device *pdev)
{
	struct gr_spimctrl *hw;
	struct spi_master *master;
	int err = -ENODEV;
	struct resource *r;
	u32 status;

	master = spi_alloc_master(&pdev->dev, sizeof(struct gr_spimctrl));
	if (!master)
		return err;

	/* setup the master state */
	master->bus_num = pdev->id;
	master->num_chipselect = GR_SPIM_NUMCS;
	master->mode_bits = SPI_CS_HIGH;
	master->setup = gr_spimctrl_setup;
	master->cleanup = gr_spimctrl_cleanup;

	hw = spi_master_get_devdata(master);
	platform_set_drvdata(pdev, hw);

	/* setup the state for the bitbang driver */
	hw->bitbang.master = spi_master_get(master);
	if (!hw->bitbang.master)
		goto exit;
	hw->bitbang.master->dev.of_node = of_node_get(pdev->dev.of_node);

	hw->bitbang.setup_transfer = gr_spimctrl_setupxfer;
	hw->bitbang.chipselect = gr_spimctrl_chipsel;
	hw->bitbang.txrx_bufs = gr_spimctrl_txrx;

	/* find and map our resources */
	r = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	hw->base = of_ioremap(r, 0, resource_size(r), "ag-spimctrl regs");
	if (!hw->base) {
		err = -EBUSY;
		goto exit;
	}

	/* check current hw state. if controller is busy, leave it alone */
	status = gr_spim_read(hw->base + GR_SPIM_STAT);
	if (status & GR_SPIM_STAT_BUSY) {
		err = -EBUSY;
		goto exit_iounmap;
	}

	/* save control register value to keep settings */
	hw->ctrl = gr_spim_read(hw->base + GR_SPIM_CTRL);

	/* irq is optional */
	hw->irq = irq_of_parse_and_map(pdev->dev.of_node, 0);
	if (hw->irq != NO_IRQ) {
		init_completion(&hw->done);
		err = request_irq(hw->irq, gr_spimctrl_irq, IRQF_SHARED,
				pdev->name, hw);
		if (err)
			goto exit_iounmap;
		/* enable interrupt, written to hw below */
		hw->ctrl |= GR_SPIM_CTRL_IEN;
	}

	/* enter user mode so SPI comm. can be done via reg. interface */
	if (!(hw->ctrl & GR_SPIM_CTRL_USRC)) {
		hw->ctrl |= GR_SPIM_CTRL_USRC;
		gr_spim_write(hw->ctrl, hw->base + GR_SPIM_CTRL);
	}

	/* register our spi controller */
	err = spi_bitbang_start(&hw->bitbang);
	if (err)
		goto exit_iounmap;

	dev_info(&pdev->dev, "base at 0x%p, irq %d, bus %d\n",
		hw->base, hw->irq, master->bus_num);

	return 0;

exit_iounmap:
	of_iounmap(r, hw->base, resource_size(r));
exit:
	spi_master_put(master);
	platform_set_drvdata(pdev, NULL);
	return err;
}

static int gr_spimctrl_remove(struct platform_device *pdev)
{
	struct gr_spimctrl *hw = platform_get_drvdata(pdev);
	struct spi_master *master = hw->bitbang.master;
	struct resource *r = platform_get_resource(pdev, IORESOURCE_MEM, 0);

	spi_bitbang_stop(&hw->bitbang);

	/* bring hw out of user mode */
	hw->ctrl &= ~GR_SPIM_CTRL_USRC;
	gr_spim_write(hw->ctrl, hw->base + GR_SPIM_CTRL);

	spi_master_put(master);

	if (hw->irq != NO_IRQ)
		free_irq(hw->irq, hw);
	of_iounmap(r, hw->base,	resource_size(r));

	platform_set_drvdata(pdev, NULL);

	return 0;
}

#ifdef CONFIG_OF
static const struct of_device_id gr_spimctrl_of_match[] = {
	{ .name = "GAISLER_SPIMCTRL",},
	{ .name = "01_045",},
	{},
};
MODULE_DEVICE_TABLE(of, gr_spimctrl_of_match);
#else /* CONFIG_OF */
#define gr_spimctrl_of_match NULL
#endif /* CONFIG_OF */

static struct platform_driver gr_spimctrl_driver = {
	.probe = gr_spimctrl_probe,
	.remove = gr_spimctrl_remove,
	.driver = {
		.name = DRV_NAME,
		.owner = THIS_MODULE,
		.pm = NULL,
		.of_match_table = gr_spimctrl_of_match,
	},
};

static int __init gr_spimctrl_init(void)
{
	return platform_driver_register(&gr_spimctrl_driver);
}
module_init(gr_spimctrl_init);

static void __exit gr_spimctrl_exit(void)
{
	platform_driver_unregister(&gr_spimctrl_driver);
}
module_exit(gr_spimctrl_exit);

MODULE_DESCRIPTION("Aeroflex Gaisler GRLIB SPIMCTRL driver");
MODULE_AUTHOR("Jan Andersson <jan@gaisler.com>");
MODULE_LICENSE("GPL");
