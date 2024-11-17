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

#include <monitors.h>

typedef int64_t token_t;

static unsigned DMA_WORD_PER_BEAT(unsigned _st)
{
        return (sizeof(void *) / _st);
}


#define SLD_DFADD 0x303
#define DEV_NAME "sld,dfadd_vivado"

/* <<--params-->> */
const int32_t dfadd_out = 1;
const int32_t dfadd_in = 2;
const int32_t dfadd_n = 100;

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
#define DFADD_DFADD_OUT_REG 0x48
#define DFADD_DFADD_IN_REG 0x44
#define DFADD_DFADD_N_REG 0x40

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

static void wait_micro(long unsigned waiting_time)
{
	long unsigned start, end;
	start = custom_gettime_nano();
	end = 0;
	while(end < start + waiting_time*1000)
		end = custom_gettime_nano();
	return;
}

static int validate_buf(token_t *out, token_t *gold)
{
	int i;
	int j;
	unsigned errors = 0;

	printf("\n----------Results:---------\n");
	for (i = 0; i < dfadd_n; i++)
	{
		//printf("\nBatch %d:\n", i);
		for (j = 0; j < dfadd_out; j++)
		{
			printf("%d    -    gold = %016llx     out = %016llx\n", j, gold[i * out_words_adj + j], out[i * out_words_adj + j]);
			if (gold[i * out_words_adj + j] != out[i * out_words_adj + j])
				errors++;
		}
	}

	printf("\n\nTotal Software Execution Time: ");
	print_time_us(total_time_sw);

	printf("\nSingle Software Execution Time: ");
	print_time_us(total_time_sw/dfadd_n);

	printf("\n\nTotal Hardware Execution Time: ");
	print_time_us(total_time_hw);

	printf("\nSingle Hardware Execution Time: ");
	print_time_us(total_time_hw/dfadd_n);

	printf("\n\n");

	return errors;
}


static void init_buf (token_t *in, token_t * gold)
{
	int i;
	int j;

	for (i = 0; i < dfadd_n; i++)
		for (j = 0; j < dfadd_in; j++)
			in[i * in_words_adj + j] = (token_t)  j*1.57 + i*78.41 + 13.499;

	//Time measurement for software execution
	start_time = custom_gettime_nano();

	for (i = 0; i < dfadd_n; i++)
        float64_add_sw((float64 *)&in[i*in_words_adj], (float64 *)&gold[i*out_words_adj]);

	end_time = custom_gettime_nano();
	total_time_sw = end_time-start_time;

}


int main(int argc, char * argv[])
{
    printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");
	//printf("Starting main... \n");


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

	volatile uint32_t * noc_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
	volatile uint32_t * cpu_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
	volatile uint32_t * acc1_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//volatile uint32_t * acc2_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 3)*4 + 128);
	//volatile uint32_t * acc3_freq = (volatile uint32_t *)(BASE_ADDRESS + (16 + 4)*4 + 128);

	*noc_freq = 9;
	*cpu_freq = 9;
	*acc1_freq = 9;
	//*acc1_freq = 7;
	//*acc2_freq = 6;
	//*acc3_freq = 5;


	if (DMA_WORD_PER_BEAT(sizeof(token_t)) == 0) {
		in_words_adj = dfadd_in;
		out_words_adj = dfadd_out;
	} else {
		in_words_adj = round_up(dfadd_in, DMA_WORD_PER_BEAT(sizeof(token_t)));
		out_words_adj = round_up(dfadd_out, DMA_WORD_PER_BEAT(sizeof(token_t)));
	}
	in_len = in_words_adj * (dfadd_n);
	out_len = out_words_adj * (dfadd_n);
	in_size = in_len * sizeof(token_t);
	out_size = out_len * sizeof(token_t);
	out_offset  = in_len;
	mem_size = (out_offset * sizeof(token_t)) + out_size;

    //---------------------------------TEMP!!! GM change!!! ELIMINARE---------------------------------------
    //volatile uint32_t * cpu_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
	//for(int i = 0; i< 100; i++)
	//{
	//	wait_micro(10);
	//	*cpu_freq_reg = i;
	//}
	//	//------------------------------------------------------------------------------------------------------
	//volatile uint32_t * domain0_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 0)*4 + 128);
	//volatile uint32_t * domain1_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 1)*4 + 128);
	//volatile uint32_t * domain2_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//volatile uint32_t * domain3_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//volatile uint32_t * domain4_freq_reg = (volatile uint32_t *)(BASE_ADDRESS + (16 + 2)*4 + 128);
	//*domain0_freq_reg = 18;
	//*domain1_freq_reg = 8;
	//*domain2_freq_reg = 5;
	//*domain3_freq_reg = 9;
	//*domain4_freq_reg = 7;
	//-------------------------------------GM change - ESP MONITORS: EXAMPLE #3-----------------------------
    //esp_monitor_args_t mon_args;
	////read a specified subset of the monitors on the SoC
    //esp_monitor_vals_t vals_diff;
    //
	////dynamically allocate monitor arg structure
	//esp_monitor_vals_t vals_start_ptr;
	//esp_monitor_vals_t vals_end_ptr;
    //
	////set read_mode to MANY
	//mon_args.read_mode = ESP_MON_READ_MANY;
	//mon_args.read_mask = 0;
    //
    //
	//const int ACC_TILE_INDEX = 0;
	//mon_args.tile_index = ACC_TILE_INDEX;
	//mon_args.read_mask |= 1 << ESP_MON_READ_NOC_INJECTS;
    //mon_args.read_mask |= 1 << ESP_MON_READ_NOC_EJECTS;
    //
	////enable reading noc backpressure on a plane - requires the index of the noc plane
	//const int NOC_PLANE = 0;
	//mon_args.noc_index = NOC_PLANE;
	//mon_args.read_mask |= 1 << ESP_MON_READ_NOC_QUEUE_FULL_PLANE;
    //
	////cfg_fc[0].hw_buf = buf[0];
    //
	////values written into vals struct argument
	//esp_monitor(mon_args, &vals_start_ptr);
	////esp_run(cfg_fc, 1);
	//wait_micro(1000);
    //esp_monitor(mon_args, &vals_end_ptr);


	//write results to file
	//fp = fopen("multifft_esp_mon_many.txt", "w");
	//esp_monitor_print(mon_args, vals_diff, fp);
	//fclose(fp);
    //
	//when done with monitors, free all allocated structures, and unmap the address space
	//esp_monitor_free();
	//________________________________________TEMP_______________________________________




	// Search for the device
	printf("Scanning device tree... \n");

	ndev = probe(&espdevs, VENDOR_SLD, SLD_DFADD, DEV_NAME);
	if (ndev == 0) {
		printf("dfadd not found\n");
		return 0;
	}

	for (n = 0; n<ndev; n++)
	{
		dev = &espdevs[n];
		printf("\n\n\n-----------------DEVICE N.%d-------------------\n\n", n);
		printf("Vendor: %x\n", dev->vendor);
		printf("ID: %x\n", dev->id);
		printf("Number: %x\n", dev->number);
		printf("IRQ: %x\n", dev->irq);
		printf("Address: %llx\n", dev->addr);
		printf("Compat: %u\n", dev->compat);
		printf("Name: %s\n", dev->name);
	}

	for (n = 0; n < ndev; n++) {

		printf("**************** %s.%d ****************\n", DEV_NAME, n);

		dev = &espdevs[n];

		printf("NCHUNK MAX = %d\n", ioread32(dev, PT_NCHUNK_MAX_REG));
		// Check DMA capabilities
		if (ioread32(dev, PT_NCHUNK_MAX_REG) == 0) {
			printf("  -> scatter-gather DMA is disabled. Abort.\n");
			//return 0;
			continue;
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
		iowrite32(dev, DFADD_DFADD_OUT_REG, dfadd_out);
		iowrite32(dev, DFADD_DFADD_IN_REG, dfadd_in);
		iowrite32(dev, DFADD_DFADD_N_REG, dfadd_n);

			// Flush (customize coherence model here)
			esp_flush(coherence);


			// Start accelerators
			printf("  Start...\n");

			//Time measurement for software execution
			start_time = custom_gettime_nano();



			for(int j=0; j<3; j++)
			{
				iowrite32(dev, CMD_REG, CMD_MASK_START);
				// Wait for completion
				done = 0;
				while (!done) {
					done = ioread32(dev, STATUS_REG);
					done &= STATUS_MASK_DONE;
				}
				iowrite32(dev, CMD_REG, 0x0);
				printf("Roundtrip time %d = %d\n", j, esp_monitor_rtt_1tile(3));
			}
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

    printf("\n	** DONE **\n");

        //calculate difference of all values
	//vals_diff = esp_monitor_diff(vals_start_ptr, vals_end_ptr);
    //int sum = 0;
	//for(int q=0; q<6; q++)
	//	//sum += vals_diff.noc_ejects[3][q];
	//	sum += vals_diff.noc_ejects[0][q];
	//printf("The ejected packets are %d\n", sum);

	return 0;
}
