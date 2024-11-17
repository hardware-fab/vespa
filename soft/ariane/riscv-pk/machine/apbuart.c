// See LICENSE for license details.

#include <string.h>
#include "apbuart.h"
#include "fdt.h"

volatile uint32_t* apbuart = 0;

static int apbuart_is_transmit_empty()
{
	return apbuart[APBUART_STATUS] & APBUART_STATUS_TE;
}

static void apbuart_wait_tx()
{
	while (apbuart_is_transmit_empty() == 0) { }
}

void apbuart_putchar(uint8_t ch)
{
	apbuart_wait_tx();
	apbuart[APBUART_DATA] = (uint32_t) ch;
}

static int apbuart_is_receive_ready()
{
	return apbuart[APBUART_STATUS] & APBUART_STATUS_DR;
}

static void apbuart_wait_rx()
{
	while (apbuart_is_receive_ready() == 0) { }
}

int apbuart_getchar()
{
	apbuart_wait_rx();
	return apbuart[APBUART_DATA];
}

struct apbuart_scan
{
	int compat;
	uint64_t reg;
};

static void apbuart_open(const struct fdt_scan_node *node, void *extra)
{
	struct apbuart_scan *scan = (struct apbuart_scan *)extra;
	memset(scan, 0, sizeof(*scan));
}

static void apbuart_prop(const struct fdt_scan_prop *prop, void *extra)
{
	struct apbuart_scan *scan = (struct apbuart_scan *)extra;
	if (!strcmp(prop->name, "compatible") && !strcmp((const char*)prop->value, "gaisler,apbuart")) {
		scan->compat = 1;
	} else if (!strcmp(prop->name, "reg")) {
		fdt_get_address(prop->node->parent, prop->value, &scan->reg);
	}
}

static void apbuart_done(const struct fdt_scan_node *node, void *extra)
{
	struct apbuart_scan *scan = (struct apbuart_scan *)extra;
	if (!scan->compat || !scan->reg || apbuart) return;

	apbuart = (void*)(uintptr_t)scan->reg;

	/* apbuart[APBUART_CONTROL] = APBUART_CTRL_TE | APBUART_CTRL_RE; */
}

void query_apbuart(uintptr_t fdt)
{
	struct fdt_cb cb;
	struct apbuart_scan scan;

	memset(&cb, 0, sizeof(cb));
	cb.open = apbuart_open;
	cb.prop = apbuart_prop;
	cb.done = apbuart_done;
	cb.extra = &scan;

	fdt_scan(fdt, &cb);
}
