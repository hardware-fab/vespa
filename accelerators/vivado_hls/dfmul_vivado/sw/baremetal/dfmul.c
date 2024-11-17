/* Copyright (c) 2011-2023 Columbia University, System Level Design Group */
/* SPDX-License-Identifier: Apache-2.0 */

#include <stdio.h>
#ifndef __riscv
#include <stdlib.h>
#endif

#include <esp_accelerator.h>
#include <esp_probe.h>
#include <fixed_point.h>

#include "../global.h"

typedef int64_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_DFMUL 0x305
#define DEV_NAME "sld,dfmul_vivado"

/* <<--params-->> */
const int32_t dfmul_out = 1;
const int32_t dfmul_n = 100;
const int32_t dfmul_in = 2;

static unsigned in_words_adj;
static unsigned out_words_adj;
static unsigned in_len;
static unsigned out_len;
static unsigned in_size;
static unsigned out_size;
static unsigned out_offset;
static unsigned mem_size;

/* Size of the contiguous chunks for scatter/gather */
#define CHUNK_SHIFT 20
#define CHUNK_SIZE BIT(CHUNK_SHIFT)
#define NCHUNK(_sz) ((_sz % CHUNK_SIZE == 0) ?		\
			(_sz / CHUNK_SIZE) :		\
			(_sz / CHUNK_SIZE) + 1)

/* User defined registers */
/* <<--regs-->> */
#define DFMUL_DFMUL_OUT_REG 0x48
#define DFMUL_DFMUL_N_REG 0x44
#define DFMUL_DFMUL_IN_REG 0x40

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8

#define CLOCK_PERIOD 20

static double start_time, end_time, total_time_sw;
static double total_time_hw[6];

static long unsigned custom_gettime_nano()
{
	volatile unsigned long timer_reg_lo, timer_reg_hi;
	volatile uint32_t * timer_lo_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_LO);
	volatile uint32_t * timer_hi_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_HI);
	timer_reg_lo = *timer_lo_ptr;
	timer_reg_hi = *timer_hi_ptr;
	return (long unsigned) ((*timer_lo_ptr | (long unsigned)(*timer_hi_ptr)<<32)*CLOCK_PERIOD);
}

static void print_time(long unsigned value)
{
	uint32_t nano = value%1000;
	uint32_t micro = (value%1000000)/1000;
	uint32_t milli = (value%1000000000)/1000000;
	uint32_t sec = (value%1000000000000)/1000000000;
	printf("original value=%lu : %u s - %u ms - %u us - %u ns", value, sec, milli, micro, nano);
}

static void print_time_us(long unsigned value)
{
	uint32_t decimal = value%1000;
	uint32_t integer = (value)/1000;
	printf("%u,%03u", integer, decimal);
}

#define N 20
const float64 a_input[N] = {
  0x7FF0000000000000ULL,	/* inf */
  0x7FFF000000000000ULL,	/* nan */
  0x7FF0000000000000ULL,	/* inf */
  0x7FF0000000000000ULL,	/* inf */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x0000000000000000ULL,	/* 0.0 */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x0000000000000000ULL,	/* 0.0 */
  0x8000000000000000ULL,	/* -0.0 */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x4000000000000000ULL,	/* 2.0 */
  0x3FD0000000000000ULL,	/* 0.25 */
  0xC000000000000000ULL,	/* -2.0 */
  0xBFD0000000000000ULL,	/* -0.25 */
  0x4000000000000000ULL,	/* 2.0 */
  0xBFD0000000000000ULL,	/* -0.25 */
  0xC000000000000000ULL,	/* -2.0 */
  0x3FD0000000000000ULL,	/* 0.25 */
  0x0000000000000000ULL		/* 0.0 */
};

const float64 b_input[N] = {
  0xFFFFFFFFFFFFFFFFULL,	/* nan */
  0xFFF0000000000000ULL,	/* -inf */
  0x0000000000000000ULL,	/* nan */
  0x3FF0000000000000ULL,	/* -inf */
  0xFFFF000000000000ULL,	/* nan */
  0x7FF0000000000000ULL,	/* inf */
  0x7FF0000000000000ULL,	/* inf */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x3FF0000000000000ULL,	/* 1.0 */
  0x0000000000000000ULL,	/* 0.0 */
  0x8000000000000000ULL,	/* -0.0 */
  0x3FD0000000000000ULL,	/* 0.25 */
  0x4000000000000000ULL,	/* 2.0 */
  0xBFD0000000000000ULL,	/* -0.25 */
  0xC000000000000000ULL,	/* -2.0 */
  0xBFD0000000000000ULL,	/* -0.25 */
  0x4000000000000000ULL,	/* -2.0 */
  0x3FD0000000000000ULL,	/* 0.25 */
  0xC000000000000000ULL,	/* -2.0 */
  0x0000000000000000ULL		/* 0.0 */
};

const float64 z_output[N] = {
  0xFFFFFFFFFFFFFFFFULL,	/* nan */
  0x7FFF000000000000ULL,	/* nan */
  0x7FFFFFFFFFFFFFFFULL,	/* nan */
  0x7FF0000000000000ULL,	/* inf */
  0xFFFF000000000000ULL,	/* nan */
  0x7FFFFFFFFFFFFFFFULL,	/* nan */
  0x7FF0000000000000ULL,	/* inf */
  0x0000000000000000ULL,	/* 0.0 */
  0x8000000000000000ULL,	/* -0.0 */
  0x0000000000000000ULL,	/* 0.0 */
  0x8000000000000000ULL,	/* -0.0 */
  0x3FE0000000000000ULL,	/* 0.5 */
  0x3FE0000000000000ULL,	/* 0.5 */
  0x3FE0000000000000ULL,	/* 0.5 */
  0x3FE0000000000000ULL,	/* 0.5 */
  0xBFE0000000000000ULL,	/* -0.5 */
  0xBFE0000000000000ULL,	/* -0.5 */
  0xBFE0000000000000ULL,	/* -0.5 */
  0xBFE0000000000000ULL,	/* -0.5 */
  0x0000000000000000ULL		/* 0.0 */
};

static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < dfmul_n; i++)
	{
		printf("\nBatch %d:\n", i);
		for (j = 0; j < dfmul_out; j++)
		{
			printf("%d    -    gold = %016llx     out = %016llx\n", j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
			if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
				errors++;
		}
	}

	//printf("\n\nTotal Software Execution Time: ");
	//print_time_us(total_time_sw);
    //
	//printf("\nSingle Software Execution Time: ");
	//print_time_us(total_time_sw/dfmul_n);
    //
	//printf("\n\nTotal Hardware Execution Time: ");
	//print_time_us(total_time_hw);
    //
	//printf("\nSingle Hardware Execution Time: ");
	//print_time_us(total_time_hw/dfmul_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	for (i = 0; i < dfmul_n; i++)
		for (j = 0; j < dfmul_in; j++)
		{
			if(j==0)
				in[i * in_words_adj + j] = (token_t) a_input[i%N];
			else
				in[i * in_words_adj + j] = (token_t) b_input[i%N];

		}

	//Time measurement for software execution
	start_time = custom_gettime_nano();

	for (i = 0; i < dfmul_n; i++)
		float64_mul_sw((float64 *)&in[i*in_words_adj], (float64 *)&gold[i*out_words_adj]);

	end_time = custom_gettime_nano();
	total_time_sw = end_time-start_time;

}


int main(int argc, char * argv[])
{
	int i;
	int n;
	int ndev;
	struct esp_device *espdevs;
	struct esp_device *dev;
	unsigned done;
	unsigned **ptable;
	token_t *mem;
	token_t *gold;
	unsigned errors = 0;
	unsigned coherence;

	if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
		in_words_adj = dfmul_in;
		out_words_adj = dfmul_out;
	} else {
		in_words_adj = round_up(dfmul_in, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(dfmul_out, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (dfmul_n);
	out_len = out_words_adj * (dfmul_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;


	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_DFMUL, DEV_NAME);
	if (ndev == 0) {
		printf("dfmul not found\n");
		return 0;
	}

	for (n = 0; n < ndev; n++) {

		printf("**************** %s.%d ****************\n", DEV_NAME, n);

		dev = &espdevs[n];

		// Check DMA capabilities
		if (ioread32(dev, PT_NCHUNK_MAX_REG) == 0) {
			printf("  -> scatter-gather DMA is disabled. Abort.\n");
			return 0;
		}

		if (ioread32(dev, PT_NCHUNK_MAX_REG) < NCHUNK(mem_size)) {
			printf("  -> Not enough TLB entries available. Abort.\n");
			return 0;
		}

		// Allocate memory
		gold = aligned_malloc(out_size);
		mem = aligned_malloc(mem_size);
		printf("  memory buffer base-address = %p\n", mem);

		// Alocate and populate page table
		ptable = aligned_malloc(NCHUNK(mem_size) * sizeof(unsigned *));
		for (i = 0; i < NCHUNK(mem_size); i++)
			ptable[i] = (unsigned *) &mem[i * (CHUNK_SIZE / sizeof(token_t))];

		printf("  ptable = %p\n", ptable);
		printf("  nchunk = %lu\n", NCHUNK(mem_size));

#ifndef __riscv
		for (coherence = ACC_COH_NONE; coherence <= ACC_COH_RECALL; coherence++) {
#else
		{
			/* TODO: Restore full test once ESP caches are integrated */
			coherence = ACC_COH_NONE;
#endif
			printf("  --------------------\n");
			printf("  Generate input...\n");
			init_buf(mem, gold);

			// Pass common configuration parameters

			iowrite32(dev, SELECT_REG, ioread32(dev, DEVID_REG));
			iowrite32(dev, COHERENCE_REG, coherence);

#ifndef __sparc
			iowrite32(dev, PT_ADDRESS_REG, (unsigned long long) ptable);
#else
			iowrite32(dev, PT_ADDRESS_REG, (unsigned) ptable);
#endif
			iowrite32(dev, PT_NCHUNK_REG, NCHUNK(mem_size));
			iowrite32(dev, PT_SHIFT_REG, CHUNK_SHIFT);

			// Use the following if input and output data are not allocated at the default offsets
			iowrite32(dev, SRC_OFFSET_REG, 0x0);
			iowrite32(dev, DST_OFFSET_REG, 0x0);

			// Pass accelerator-specific configuration parameters
			/* <<--regs-config-->> */
		iowrite32(dev, DFMUL_DFMUL_OUT_REG, dfmul_out);
		iowrite32(dev, DFMUL_DFMUL_N_REG, dfmul_n);
		iowrite32(dev, DFMUL_DFMUL_IN_REG, dfmul_in);

			// Flush (customize coherence model here)
			esp_flush(coherence);

			//Three measurements for each bench
			for(int m = 0; m<3; m++)
			{
				volatile uint32_t * noc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
				volatile uint32_t * acc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
				volatile uint32_t * cpu_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);

				if (m==0)
				{
					*noc_freq = 19;
					*acc_freq = 1;
					*cpu_freq = 9;
				}
				else if (m==1)
				{
					*noc_freq = 19;
					*acc_freq = 9;
					*cpu_freq = 9;
				}
				else if (m==2)
				{
					*noc_freq = 1;
					*acc_freq = 9;
					*cpu_freq = 9;
				}
				// Start accelerators
				printf("  Start...\n");

				//Time measurement for software execution
				start_time = custom_gettime_nano();

				iowrite32(dev, CMD_REG, CMD_MASK_START);

				// Wait for completion
				done = 0;
				while (!done) {
					done = ioread32(dev, STATUS_REG);
					done &= STATUS_MASK_DONE;
				}
				iowrite32(dev, CMD_REG, 0x0);

				end_time = custom_gettime_nano();
				total_time_hw[n*3+m] = end_time-start_time;
			}
			printf("  Done\n");
			printf("  validating...\n");

			/* Validation */
			errors = validate_buf(&mem[out_offset], gold);
			if (errors)
				printf("  ... FAIL\n");
			else
				printf("  ... PASS\n");
		}
		for(int cnt = 0; cnt < 6; cnt++)
		{
			print_time_us(total_time_hw[cnt]/(dfmul_n));
			printf("\n");
		}
		aligned_free(ptable);
		aligned_free(mem);
		aligned_free(gold);
	}

	return 0;
}
