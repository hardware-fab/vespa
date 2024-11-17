/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Copyright (C) 2019 FORTH-ICS/CARV
 *				Panagiotis Peristerakis <perister@ics.forth.gr>
 */

#include <sbi/riscv_encoding.h>
#include <sbi/sbi_const.h>
#include <sbi/sbi_platform.h>
#include <sbi_utils/irqchip/plic.h>
#include <sbi_utils/serial/gaisler-uart.h>
#include <sbi_utils/sys/clint.h>
#include <sbi/sbi_console.h>
#include <sbi/sbi_hart.h>
#include <libfdt.h>
#include <fdt.h>
#include <sbi_utils/irqchip/plic.h>
#include <sbi/riscv_io.h>

#define ESP_UART_ADDR			0x60000100
#define ESP_BASE_FREQ			(BASE_FREQ_MHZ * 1000000)
#define ESP_UART_BAUDRATE			38400
#define ESP_UART_REG_SHIFT			2
#define ESP_UART_REG_WIDTH			4
#define ESP_PLIC_ADDR			0x6c000000
#define ESP_PLIC_NUM_SOURCES			30
#define ESP_HART_COUNT			4
#define ESP_CLINT_ADDR 0x2000000
#define PLIC_ENABLE_BASE		0x2000
#define PLIC_ENABLE_STRIDE		0x80
#define PLIC_CONTEXT_BASE		0x200000
#define PLIC_CONTEXT_STRIDE		0x1000

#define SBI_ARIANE_FEATURES	\
	(SBI_PLATFORM_HAS_TIMER_VALUE | \
	 SBI_PLATFORM_HAS_SCOUNTEREN | \
	 SBI_PLATFORM_HAS_MCOUNTEREN | \
	 SBI_PLATFORM_HAS_MFAULTS_DELEGATION)


/*
 * Ariane platform early initialization.
 */
static int esp_early_init(bool cold_boot)
{
	/* For now nothing to do. */
	return 0;
}

/*
 * Ariane platform final initialization.
 */
static int esp_final_init(bool cold_boot)
{
	void *fdt;

	if (!cold_boot)
		return 0;
	fdt = sbi_scratch_thishart_arg1_ptr();
	plic_fdt_fixup(fdt, "riscv,plic0");
	return 0;
}

/*
 * Initialize the esp console.
 */
static int esp_console_init(void)
{
	return gaisler_uart_init(ESP_UART_ADDR,
						 ESP_BASE_FREQ,
						 ESP_UART_BAUDRATE);
}

static int plic_esp_warm_irqchip_init(u32 target_hart,
			   int m_cntx_id, int s_cntx_id)
{
	size_t i, ie_words = ESP_PLIC_NUM_SOURCES / 32 + 1;

	if (ESP_HART_COUNT <= target_hart)
		return -1;
	/* By default, enable all IRQs for M-mode of target HART */
	if (m_cntx_id > -1) {
		for (i = 0; i < ie_words; i++)
			plic_set_ie(m_cntx_id, i, 1);
	}
	/* Enable all IRQs for S-mode of target HART */
	if (s_cntx_id > -1) {
		for (i = 0; i < ie_words; i++)
			plic_set_ie(s_cntx_id, i, 1);
	}
	/* By default, enable M-mode threshold */
	if (m_cntx_id > -1)
		plic_set_thresh(m_cntx_id, 1);
	/* By default, disable S-mode threshold */
	if (s_cntx_id > -1)
		plic_set_thresh(s_cntx_id, 0);

	return 0;
}

/*
 * Initialize the esp interrupt controller for current HART.
 */
static int esp_irqchip_init(bool cold_boot)
{
	u32 hartid = sbi_current_hartid();
	int ret;

	if (cold_boot) {
		ret = plic_cold_irqchip_init(ESP_PLIC_ADDR,
					     ESP_PLIC_NUM_SOURCES,
					     ESP_HART_COUNT);
		if (ret)
			return ret;
	}
	return plic_esp_warm_irqchip_init(hartid,
					2 * hartid, 2 * hartid + 1);
}

/*
 * Initialize IPI for current HART.
 */
static int esp_ipi_init(bool cold_boot)
{
	int ret;

	if (cold_boot) {
		ret = clint_cold_ipi_init(ESP_CLINT_ADDR,
					  ESP_HART_COUNT);
		if (ret)
			return ret;
	}

	return clint_warm_ipi_init();
}

/*
 * Initialize esp timer for current HART.
 */
static int esp_timer_init(bool cold_boot)
{
	int ret;

	if (cold_boot) {
		ret = clint_cold_timer_init(ESP_CLINT_ADDR,
					    ESP_HART_COUNT, TRUE);
		if (ret)
			return ret;
	}

	return clint_warm_timer_init();
}

/*
 * Reboot the esp.
 */
static int esp_system_reboot(u32 type)
{
	/* For now nothing to do. */
	sbi_printf("System reboot\n");
	return 0;
}

/*
 * Shutdown or poweroff the esp.
 */
static int esp_system_shutdown(u32 type)
{
	/* For now nothing to do. */
	sbi_printf("System shutdown\n");
	return 0;
}

/*
 * Platform descriptor.
 */
const struct sbi_platform_operations platform_ops = {
	.early_init = esp_early_init,
	.final_init = esp_final_init,
	.console_init = esp_console_init,
	.console_putc = gaisler_uart_putc,
	.console_getc = gaisler_uart_getc,
	.irqchip_init = esp_irqchip_init,
	.ipi_init = esp_ipi_init,
	.ipi_send = clint_ipi_send,
	.ipi_clear = clint_ipi_clear,
	.timer_init = esp_timer_init,
	.timer_value = clint_timer_value,
	.timer_event_start = clint_timer_event_start,
	.timer_event_stop = clint_timer_event_stop,
	.system_reboot = esp_system_reboot,
	.system_shutdown = esp_system_shutdown
};

const struct sbi_platform platform = {
	.opensbi_version = OPENSBI_VERSION,
	.platform_version = SBI_PLATFORM_VERSION(0x0, 0x01),
	.name = "ESP+ARIANE RISC-V",
	.features = SBI_ARIANE_FEATURES,
	.hart_count = ESP_HART_COUNT,
	.hart_stack_size = 4096,
	.disabled_hart_mask = 0,
	.platform_ops_addr = (unsigned long)&platform_ops
};
