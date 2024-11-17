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
#include "../types.h"

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8

#define CLOCK_PERIOD 20

static double start_time, end_time, total_time_sw;
static double total_time_hw;

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

const word inData[N] =
  { 81, 10854, 1893, -10291, 7614, 29718, 20475, -29215, -18949, -29806,
  -32017, 1596, 15744, -3088, -17413, -22123, 6798, -13276, 3819, -16273,
    -1573, -12523, -27103,
  -193, -25588, 4698, -30436, 15264, -1393, 11418, 11370, 4986, 7869, -1903,
    9123, -31726,
  -25237, -14155, 17982, 32427, -12439, -15931, -21622, 7896, 1689, 28113,
    3615, 22131, -5572,
  -20110, 12387, 9177, -24544, 12480, 21546, -17842, -13645, 20277, 9987,
    17652, -11464, -17326,
  -10552, -27100, 207, 27612, 2517, 7167, -29734, -22441, 30039, -2368, 12813,
    300, -25555, 9087,
  29022, -6559, -20311, -14347, -7555, -21709, -3676, -30082, -3190, -30979,
    8580, 27126, 3414,
  -4603, -22303, -17143, 13788, -1096, -14617, 22071, -13552, 32646, 16689,
    -8473, -12733, 10503,
  20745, 6696, -26842, -31015, 3792, -19864, -20431, -30307, 32421, -13237,
    9006, 18249, 2403,
  -7996, -14827, -5860, 7122, 29817, -31894, 17955, 28836, -31297, 31821,
    -27502, 12276, -5587,
  -22105, 9192, -22549, 15675, -12265, 7212, -23749, -12856, -5857, 7521,
    17349, 13773, -3091,
  -17812, -9655, 26667, 7902, 2487, 3177, 29412, -20224, -2776, 24084, -7963,
    -10438, -11938,
  -14833, -6658, 32058, 4020, 10461, 15159
};

const word outData[N] =
  { 80, 10848, 1888, -10288, 7616, 29712, 20480, -29216, -18944, -29808,
  -32016, 1600, 15744, -3088, -17408, -22128, 6800, -13280, 3824, -16272,
    -1568, -12528, -27104,
  -192, -25584, 4704, -30432, 15264, -1392, 11424, 11376, 4992, 7872, -1904,
    9120, -31728, -25232,
  -14160, 17984, 32432, -12432, -15936, -21616, 7904, 1696, 28112, 3616,
    22128, -5568, -20112,
  12384, 9184, -24544, 12480, 21552, -17840, -13648, 20272, 9984, 17648,
    -11456, -17328, -10544,
  -27104, 208, 27616, 2512, 7168, -29728, -22448, 30032, -2368, 12816, 304,
    -25552, 9088, 29024,
  -6560, -20304, -14352, -7552, -21712, -3680, -30080, -3184, -30976, 8576,
    27120, 3408, -4608,
  -22304, -17136, 13792, -1088, -14624, 22064, -13552, 32640, 16688, -8480,
    -12736, 10496, 20752,
  6704, -26848, -31008, 3792, -19856, -20432, -30304, 32416, -13232, 9008,
    18256, 2400, -8000,
  -14832, -5856, 7120, 29824, -31888, 17952, 28832, -31296, 31824, -27504,
    12272, -5584, -22112,
  9200, -22544, 15680, -12272, 7216, -23744, -12848, -5856, 7520, 17344,
    13776, -3088, -17808,
  -9648, 26672, 7904, 2480, 3184, 29408, -20224, -2768, 24080, -7968, -10432,
    -11936, -14832,
  -6656, 32064, 4016, 10464, 15152
};

const word outLARc[M] = { 32, 33, 22, 13, 7, 5, 3, 2 };

typedef int16_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_GSM 0x307
#define DEV_NAME "sld,gsm_vivado"

/* <<--params-->> */
const int32_t gsm_mlen = 8;
const int32_t gsm_nlen = 160;
const int32_t gsm_n = 100;

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
#define GSM_GSM_MLEN_REG 0x48
#define GSM_GSM_NLEN_REG 0x44
#define GSM_GSM_N_REG 0x40


static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < gsm_n; i++)
	{
		if(i==0)
		{
			printf("\nBatch %d:\n", i);
			for (j = 0; j < gsm_mlen + gsm_nlen; j++)
			{
				printf("%d    -    gold = %d     out = %d\n", j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
				if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
					errors++;
			}
		}
		else
			for (j = 0; j < gsm_mlen + gsm_nlen; j++)
				if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
					errors++;
	}

	printf("\n\nTotal Software Execution Time: ");
	print_time_us(total_time_sw);

	printf("\nSingle Software Execution Time: ");
	print_time_us(total_time_sw/gsm_n);

	printf("\n\nTotal Hardware Execution Time: ");
	print_time_us(total_time_hw);

	printf("\nSingle Hardware Execution Time: ");
	print_time_us(total_time_hw/gsm_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	for (i = 0; i < gsm_n; i++)
		for (j = 0; j < gsm_nlen; j++)
			in[i * in_words_adj + j] = (token_t) inData[j];

	//Time measurement for software execution
	start_time = custom_gettime_nano();

	for (i = 0; i < gsm_n; i++)
		gsm_main_sw((word *)&in[i*in_words_adj], (word *)&gold[i*out_words_adj]);

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
		in_words_adj = gsm_nlen;
		out_words_adj = gsm_nlen+gsm_mlen;
	} else {
		in_words_adj = round_up(gsm_nlen, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(gsm_nlen+gsm_mlen, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (gsm_n);
	out_len = out_words_adj * (gsm_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;

    //	//------------------------------------------------------------------------------------------------------
	volatile uint32_t * domain0_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
	volatile uint32_t * domain1_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
	//volatile uint32_t * domain2_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//volatile uint32_t * domain3_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//volatile uint32_t * domain4_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	*domain0_freq_reg = 18;
	*domain1_freq_reg = 8;
	//*domain2_freq_reg = 5;
	//*domain3_freq_reg = 9;
	//*domain4_freq_reg = 7;

	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_GSM, DEV_NAME);
	if (ndev == 0) {
		printf("gsm not found\n");
		return 0;
	}

	for (n = 0; n < ndev; n++) {

		printf("**************** %s.%d ****************\n", DEV_NAME, n);

		dev = &espdevs[n];

		printf("NCHUNK MAX = %d\n", ioread32(dev, PT_NCHUNK_MAX_REG));
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
		iowrite32(dev, GSM_GSM_MLEN_REG, gsm_mlen);
		iowrite32(dev, GSM_GSM_NLEN_REG, gsm_nlen);
		iowrite32(dev, GSM_GSM_N_REG, gsm_n);

			// Flush (customize coherence model here)
			esp_flush(coherence);

			volatile uint32_t * noc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
			volatile uint32_t * acc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
			volatile uint32_t * cpu_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);

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
			total_time_hw = end_time-start_time;

			printf("  Done\n");
			printf("  validating...\n");

			/* Validation */
			errors = validate_buf(&mem[out_offset], gold);
			if (errors)
				printf("  ... FAIL\n");
			else
				printf("  ... PASS\n");
		}

		aligned_free(ptable);
		aligned_free(mem);
		aligned_free(gold);
	}

	return 0;
}
