// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include "../inc/espacc_config.h"
#include "../inc/espacc.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include "../../src_import/global.h"
#include "../../src_import/types.h"

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

int main(int argc, char **argv) {

    printf("****start*****\n");

    /* <<--params-->> */
	 const unsigned gsm_mlen = 8;
	 const unsigned gsm_nlen = 160;
	 const unsigned gsm_n = 100;

    uint32_t in_words_adj;
    uint32_t out_words_adj;
    uint32_t in_size;
    uint32_t out_size;
    uint32_t dma_in_size;
    uint32_t dma_out_size;
    uint32_t dma_size;


    in_words_adj = round_up(gsm_nlen, VALUES_PER_WORD);
    out_words_adj = round_up(gsm_nlen+gsm_mlen, VALUES_PER_WORD);
    in_size = in_words_adj * (gsm_n);
    out_size = out_words_adj * (gsm_n);

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
    for(unsigned i = 0; i < gsm_n; i++)
        for(unsigned j = 0; j < gsm_nlen; j++)
        {
            inbuff[i * in_words_adj + j] = (word_t) inData[j];
            printf("iter:%d    -    %d: in=%04x\n", i, j, (word) inbuff[i * in_words_adj + j] );
        }
    for(unsigned i = 0; i < dma_in_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    mem[i].word[k] = inbuff[i * VALUES_PER_WORD + k];

    // Set golden output
    for (unsigned i = 0; i < gsm_n; i++)
        gsm_main_sw((word *)&inbuff[i*in_words_adj], (word *)&outbuff_gold[i*out_words_adj]);


    // Call the TOP function
    top(mem, mem,
        /* <<--args-->> */
	 	 gsm_mlen,
	 	 gsm_nlen,
	 	 gsm_n,
        load, store);

    // Validate
    uint32_t out_offset = dma_in_size;
    for(unsigned i = 0; i < dma_out_size; i++)
	for(unsigned k = 0; k < VALUES_PER_WORD; k++)
	    outbuff[i * VALUES_PER_WORD + k] = mem[out_offset + i].word[k];

    int errors = 0;
    for(unsigned i = 0; i < gsm_n; i++)
        for(unsigned j = 0; j < gsm_nlen+gsm_mlen; j++)
	    {
            if (outbuff[i * out_words_adj + j] != outbuff_gold[i * out_words_adj + j])
		        errors++;
            printf("iter:%d    -    %d: dut=%04x gold=%04x \n", i, j, (word) outbuff[i * out_words_adj + j], (word) outbuff_gold[i * out_words_adj + j]);
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
