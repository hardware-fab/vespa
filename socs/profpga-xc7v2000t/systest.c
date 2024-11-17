// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

#include <stdio.h>
#include <uart.h>
#include <float.h>

#define BASE_ADDRESS 0x60000300
#define TIMER_LO 0xB4
#define TIMER_HI 0xB8

#define CLOCK_PERIOD 20

double custom_gettime_milli()
{
	volatile unsigned long timer_reg_lo, timer_reg_hi;
	volatile uint32_t * timer_lo_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_LO);
	volatile uint32_t * timer_hi_ptr = (volatile uint32_t *)(BASE_ADDRESS + TIMER_HI);
	timer_reg_lo = *timer_lo_ptr;
	timer_reg_hi = *timer_hi_ptr;
	return (double) ((*timer_lo_ptr | (long unsigned)(*timer_hi_ptr)<<32)*CLOCK_PERIOD)/1000000;
}
int main(int argc, char **argv)
{
	//printf("Hello from ESP!\n");
	//GM change: piccolo codice che stampa sulla uart a ripetizione
	//init_uart();
	//while(1)
	printf("\n\nStart of the communication:\n\n");
	printf("It seems that I need a longer line here, otherwise it cuts part of the important part of communication. This is a strange behaviour, indeed.\n\n");

	//*test = 1;
	//volatile uint32_t temp, temp2;
	long unsigned time_millisec, start_time;
	int i=0;
	start_time = 0;
	while(1)
	{
		//write_reg_u32_local((uintptr_t) test, 0x12345678);
		//*test = 0x12345678;
		//temp = read_reg_u32_local((uintptr_t) test);
		//temp = *test;
		//time_millisec = (long unsigned) ((*timer_lo_ptr | (long unsigned)(*timer_hi_ptr)<<32)*CLOCK_PERIOD)/1000000;
		//printf("%d: lo=%u - hi=%u - time=%u\n", i, *timer_lo_ptr, *timer_hi_ptr, time_millisec) ;
		if(custom_gettime_milli()-start_time>5000)
		{
			printf("Trascorsi 5 secondi...\n");
			start_time = custom_gettime_milli();
		}
		//time_millisec=custom_gettime_milli();
		//printf("%d\n", time_millisec);
		//test++;
		//i++;
	}

	return 0;
}

