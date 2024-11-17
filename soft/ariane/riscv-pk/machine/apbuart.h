// See LICENSE for license details.

#ifndef _RISCV_APBUART_H
#define _RISCV_APBUART_H

#include <stdint.h>

extern volatile uint32_t *apbuart;

#define APBUART_DATA       0
#define APBUART_STATUS     1
#define APBUART_CONTROL    2
#define APBUART_SCALER     3
#define APBUART_FIFO_DBG   4

#define APBUART_CTRL_RE 0x1
#define APBUART_CTRL_TE 0x2
#define APBUART_CTRL_RI 0x4
#define APBUART_CTRL_TI 0x8
#define APBUART_CTRL_PS 0x10
#define APBUART_CTRL_PE 0x20
#define APBUART_CTRL_FL 0x40
#define APBUART_CTRL_LB 0x80
#define APBUART_CTRL_EC 0x100
#define APBUART_CTRL_TF 0x200
#define APBUART_CTRL_RF 0x400
#define APBUART_CTRL_DB 0x800
#define APBUART_CTRL_FE 0x80000000

#define APBUART_STATUS_DR 0x1
#define APBUART_STATUS_TS 0x2
#define APBUART_STATUS_TE 0x4
#define APBUART_STATUS_BR 0x8
#define APBUART_STATUS_OV 0x10
#define APBUART_STATUS_PE 0x20
#define APBUART_STATUS_FE 0x40
#define APBUART_STATUS_TH 0x80
#define APBUART_STATUS_RH 0x100
#define APBUART_STATUS_TF 0x200
#define APBUART_STATUS_RF 0x400


void apbuart_putchar(uint8_t ch);
int apbuart_getchar();
void query_apbuart(uintptr_t dtb);

#endif
