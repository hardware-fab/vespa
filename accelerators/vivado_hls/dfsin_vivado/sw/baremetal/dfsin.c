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

#define N 36
const float64 test_in[N] = {
  0x0000000000000000ULL,	/*      0  */
  0x3fc65717fced55c1ULL,	/*   PI/18 */
  0x3fd65717fced55c1ULL,	/*   PI/9  */
  0x3fe0c151fdb20051ULL,	/*   PI/6  */
  0x3fe65717fced55c1ULL,	/*  2PI/9  */
  0x3febecddfc28ab31ULL,	/*  5PI/18 */
  0x3ff0c151fdb20051ULL,	/*   PI/3  */
  0x3ff38c34fd4fab09ULL,	/*  7PI/18 */
  0x3ff65717fced55c1ULL,	/*  4PI/9  */
  0x3ff921fafc8b0079ULL,	/*   PI/2  */
  0x3ffbecddfc28ab31ULL,	/*  5PI/9  */
  0x3ffeb7c0fbc655e9ULL,	/* 11PI/18 */
  0x4000c151fdb20051ULL,	/*  2PI/3  */
  0x400226c37d80d5adULL,	/* 13PI/18 */
  0x40038c34fd4fab09ULL,	/*  7PI/9  */
  0x4004f1a67d1e8065ULL,	/*  5PI/6  */
  0x40065717fced55c1ULL,	/*  8PI/9  */
  0x4007bc897cbc2b1dULL,	/* 17PI/18 */
  0x400921fafc8b0079ULL,	/*   PI    */
  0x400a876c7c59d5d5ULL,	/* 19PI/18 */
  0x400becddfc28ab31ULL,	/* 10PI/9  */
  0x400d524f7bf7808dULL,	/*  7PI/6  */
  0x400eb7c0fbc655e9ULL,	/* 11PI/9  */
  0x40100e993dca95a3ULL,	/* 23PI/18 */
  0x4010c151fdb20051ULL,	/*  8PI/6  */
  0x4011740abd996affULL,	/* 25PI/18 */
  0x401226c37d80d5adULL,	/* 13PI/9  */
  0x4012d97c3d68405bULL,	/*  3PI/2  */
  0x40138c34fd4fab09ULL,	/* 14PI/9  */
  0x40143eedbd3715b7ULL,	/* 29PI/18 */
  0x4014f1a67d1e8065ULL,	/* 15PI/9  */
  0x4015a45f3d05eb13ULL,	/* 31PI/18 */
  0x40165717fced55c1ULL,	/* 16PI/9  */
  0x401709d0bcd4c06fULL,	/* 33PI/18 */
  0x4017bc897cbc2b1dULL,	/* 17PI/9  */
  0x40186f423ca395cbULL
};				/* 35PI/18 */

const float64 test_out[N] = {
  0x0000000000000000ULL,	/*  0.000000 */
  0x3fc63a1a335aadcdULL,	/*  0.173648 */
  0x3fd5e3a82b09bf3eULL,	/*  0.342020 */
  0x3fdfffff91f9aa91ULL,	/*  0.500000 */
  0x3fe491b716c242e3ULL,	/*  0.642787 */
  0x3fe8836f672614a6ULL,	/*  0.766044 */
  0x3febb67ac40b2bedULL,	/*  0.866025 */
  0x3fee11f6127e28adULL,	/*  0.939693 */
  0x3fef838b6adffac0ULL,	/*  0.984808 */
  0x3fefffffe1cbd7aaULL,	/*  1.000000 */
  0x3fef838bb0147989ULL,	/*  0.984808 */
  0x3fee11f692d962b4ULL,	/*  0.939693 */
  0x3febb67b77c0142dULL,	/*  0.866026 */
  0x3fe883709d4ea869ULL,	/*  0.766045 */
  0x3fe491b81d72d8e8ULL,	/*  0.642788 */
  0x3fe00000ea5f43c8ULL,	/*  0.500000 */
  0x3fd5e3aa4e0590c5ULL,	/*  0.342021 */
  0x3fc63a1d2189552cULL,	/*  0.173648 */
  0x3ea6aedffc454b91ULL,	/*  0.000001 */
  0xbfc63a1444ddb37cULL,	/* -0.173647 */
  0xbfd5e3a4e68f8f3eULL,	/* -0.342019 */
  0xbfdffffd494cf96bULL,	/* -0.499999 */
  0xbfe491b61cb9a3d3ULL,	/* -0.642787 */
  0xbfe8836eb2dcf815ULL,	/* -0.766044 */
  0xbfebb67a740aae32ULL,	/* -0.866025 */
  0xbfee11f5912d2157ULL,	/* -0.939692 */
  0xbfef838b1ac64afcULL,	/* -0.984808 */
  0xbfefffffc2e5dc8fULL,	/* -1.000000 */
  0xbfef838b5ea2e7eaULL,	/* -0.984808 */
  0xbfee11f7112dae27ULL,	/* -0.939693 */
  0xbfebb67c2c31cb4aULL,	/* -0.866026 */
  0xbfe883716e6fd781ULL,	/* -0.766045 */
  0xbfe491b9cd1b5d56ULL,	/* -0.642789 */
  0xbfe000021d0ca30dULL,	/* -0.500001 */
  0xbfd5e3ad0a69caf7ULL,	/* -0.342021 */
  0xbfc63a23c48863ddULL
};				/* -0.173649 */

typedef int64_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_DFSIN 0x306
#define DEV_NAME "sld,dfsin_vivado"

/* <<--params-->> */
const int32_t dfsin_in = 1;
const int32_t dfsin_out = 1;
const int32_t dfsin_n = 100;

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
#define DFSIN_DFSIN_IN_REG 0x48
#define DFSIN_DFSIN_OUT_REG 0x44
#define DFSIN_DFSIN_N_REG 0x40


static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < dfsin_n; i++)
	{
		printf("\nBatch %d:\n", i);
		for (j = 0; j < dfsin_out; j++)
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
	//print_time_us(total_time_sw/dfsin_n);
    //
	//printf("\n\nTotal Hardware Execution Time: ");
	//print_time_us(total_time_hw);
    //
	//printf("\nSingle Hardware Execution Time: ");
	//print_time_us(total_time_hw/dfsin_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	for (i = 0; i < dfsin_n; i++)
		for (j = 0; j < dfsin_in; j++)
			in[i * in_words_adj + j] = (token_t) test_in[i%N];

	//Time measurement for software execution
	start_time = custom_gettime_nano();

	for (i = 0; i < dfsin_n; i++)
		float64_sin_sw((float64 *)&in[i*in_words_adj], (float64 *)&gold[i*out_words_adj]);

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
		in_words_adj = dfsin_in;
		out_words_adj = dfsin_out;
	} else {
		in_words_adj = round_up(dfsin_in, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(dfsin_out, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (dfsin_n);
	out_len = out_words_adj * (dfsin_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;


	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_DFSIN, DEV_NAME);
	if (ndev == 0) {
		printf("dfsin not found\n");
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
		iowrite32(dev, DFSIN_DFSIN_IN_REG, dfsin_in);
		iowrite32(dev, DFSIN_DFSIN_OUT_REG, dfsin_out);
		iowrite32(dev, DFSIN_DFSIN_N_REG, dfsin_n);

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
			print_time_us(total_time_hw[cnt]/(dfsin_n));
			printf("\n");
		}
		aligned_free(ptable);
		aligned_free(mem);
		aligned_free(gold);
	}

	return 0;
}
