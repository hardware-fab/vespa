// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include "../inc/espacc_config.h"
#include "../inc/espacc.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "../../src_import/global.h"

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


int main(int argc, char **argv) {

    printf("****start*****\n");

    /* <<--params-->> */
	 const unsigned dfsin_in = 1;
	 const unsigned dfsin_out = 1;
	 const unsigned dfsin_n = 100;

    uint32_t in_words_adj;
    uint32_t out_words_adj;
    uint32_t in_size;
    uint32_t out_size;
    uint32_t dma_in_size;
    uint32_t dma_out_size;
    uint32_t dma_size;


    in_words_adj = round_up(dfsin_in, VALUES_PER_WORD);
    out_words_adj = round_up(dfsin_out, VALUES_PER_WORD);
    in_size = in_words_adj * (dfsin_n);
    out_size = out_words_adj * (dfsin_n);

    dma_in_size = in_size / VALUES_PER_WORD;
    dma_out_size = out_size / VALUES_PER_WORD;
    dma_size = dma_in_size + dma_out_size;

    dma_word_t *mem=(dma_word_t*) malloc(dma_size * sizeof(dma_word_t));
    word_t *inbuff=(word_t*) malloc(in_size * sizeof(word_t));
    word_t *outbuff=(word_t*) malloc(out_size * sizeof(word_t));
    word_t *outbuff_gold= (word_t*) malloc(out_size * sizeof(word_t));
    dma_info_t load;
    dma_info_t store;

    // Prepare input data
    for(unsigned i = 0; i < dfsin_n; i++)
        for(unsigned j = 0; j < dfsin_in; j++)
        {
            inbuff[i * in_words_adj + j] = (word_t) test_in[i%N];
            printf("iter:%d    -    %d: in=%016llx\n", i, j, (float64) inbuff[i * in_words_adj + j] );
        }

    for(unsigned i = 0; i < dma_in_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    mem[i].word[k] = inbuff[i * VALUES_PER_WORD + k];

    // Set golden output
    for (unsigned i = 0; i < dfsin_n; i++)
        float64_sin_sw((float64 *)&inbuff[i*in_words_adj], (float64 *)&outbuff_gold[i*out_words_adj]);


    // Call the TOP function
    top(mem, mem,
        /* <<--args-->> */
	 	 dfsin_in,
	 	 dfsin_out,
	 	 dfsin_n,
        load, store);

    // Validate
    uint32_t out_offset = dma_in_size;
    for(unsigned i = 0; i < dma_out_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    outbuff[i * VALUES_PER_WORD + k] = mem[out_offset + i].word[k];

    int errors = 0;
    for(unsigned i = 0; i < dfsin_n; i++)
        for(unsigned j = 0; j < dfsin_out; j++)
	    {
            if (outbuff[i * out_words_adj + j] != outbuff_gold[i * out_words_adj + j])
		        errors++;
            printf("iter:%d    -    %d: dut=%016llx gold=%016llx \n", i, j, (float64) outbuff[i * out_words_adj + j], (float64) outbuff_gold[i * out_words_adj + j]);
        }
    if (errors)
	std::cout << "Test FAILED with " << errors << " errors." << std::endl;
    else
	std::cout << "Test PASSED." << std::endl;

    // Free memory

    free(mem);
    free(inbuff);
    free(outbuff);
    free(outbuff_gold);

    return 0;
}
