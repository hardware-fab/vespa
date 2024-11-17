/*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^/
<                                                                        >
< DISCLAIMER: Politecnico di Milano                                      >
<                                                                        >
< Modified version from original CHStone sources at:                     >
<   https://github.com/A-T-Kristensen/patmos_HLS                         >
<                                                                        >
< AUTHORS: Gabriele Montanaro and Davide Zoni                            >
<                                                                        >
< E-MAIL: gabriele.montanaro@polimi.it - davide.zoni@polimi.it           >
<                                                                        >
/^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
/*
+--------------------------------------------------------------------------+
| CHStone : a suite of benchmark programs for C-based High-Level Synthesis |
| ======================================================================== |
|                                                                          |
| * Collected and Modified : Y. Hara, H. Tomiyama, S. Honda,               |
|                            H. Takada and K. Ishii                        |
|                            Nagoya University, Japan                      |
|                                                                          |
| * Remark :                                                               |
|    1. This source code is modified to unify the formats of the benchmark |
|       programs in CHStone.                                               |
|    2. Test vectors are added for CHStone.                                |
|    3. If "main_result" is 0 at the end of the program, the program is    |
|       correctly executed.                                                |
|    4. Please follow the copyright of each benchmark program.             |
+--------------------------------------------------------------------------+
*/
/*************************************************************************/
/*                                                                       */
/*   SNU-RT Benchmark Suite for Worst Case Timing Analysis               */
/*   =====================================================               */
/*                              Collected and Modified by S.-S. Lim      */
/*                                           sslim@archi.snu.ac.kr       */
/*                                         Real-Time Research Group      */
/*                                        Seoul National University      */
/*                                                                       */
/*                                                                       */
/*        < Features > - restrictions for our experimental environment   */
/*                                                                       */
/*          1. Completely structured.                                    */
/*               - There are no unconditional jumps.                     */
/*               - There are no exit from loop bodies.                   */
/*                 (There are no 'break' or 'return' in loop bodies)     */
/*          2. No 'switch' statements.                                   */
/*          3. No 'do..while' statements.                                */
/*          4. Expressions are restricted.                               */
/*               - There are no multiple expressions joined by 'or',     */
/*                'and' operations.                                      */
/*          5. No library calls.                                         */
/*               - All the functions needed are implemented in the       */
/*                 source file.                                          */
/*                                                                       */
/*                                                                       */
/*************************************************************************/
/*                                                                       */
/*  FILE: adpcm.c                                                        */
/*  SOURCE : C Algorithms for Real-Time DSP by P. M. Embree              */
/*                                                                       */
/*  DESCRIPTION :                                                        */
/*                                                                       */
/*     CCITT G.722 ADPCM (Adaptive Differential Pulse Code Modulation)   */
/*     algorithm.                                                        */
/*     16khz sample rate data is stored in the array test_data[SIZE].    */
/*     Results are stored in the array compressed[SIZE] and result[SIZE].*/
/*     Execution time is determined by the constant SIZE (default value  */
/*     is 2000).                                                         */
/*                                                                       */
/*  REMARK :                                                             */
/*                                                                       */
/*  EXECUTION TIME :                                                     */
/*                                                                       */
/*                                                                       */
/*************************************************************************/
#include <stdio.h>
#include "adpcm_global.h"

const int test_data[SIZE] = {
  0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x44, 0x44, 0x44,
  0x44, 0x44, 0x43, 0x43, 0x43,
  0x43, 0x43, 0x43, 0x43, 0x42,
  0x42, 0x42, 0x42, 0x42, 0x42,
  0x41, 0x41, 0x41, 0x41, 0x41,
  0x40, 0x40, 0x40, 0x40, 0x40,
  0x40, 0x40, 0x40, 0x3f, 0x3f,
  0x3f, 0x3f, 0x3f, 0x3e, 0x3e,
  0x3e, 0x3e, 0x3e, 0x3e, 0x3d,
  0x3d, 0x3d, 0x3d, 0x3d, 0x3d,
  0x3c, 0x3c, 0x3c, 0x3c, 0x3c,
  0x3c, 0x3c, 0x3c, 0x3c, 0x3b,
  0x3b, 0x3b, 0x3b, 0x3b, 0x3b,
  0x3b, 0x3b, 0x3b, 0x3b, 0x3b,
  0x3b, 0x3b, 0x3b, 0x3b, 0x3b,
  0x3b, 0x3b, 0x3b, 0x3b, 0x3b,
  0x3b, 0x3b, 0x3c, 0x3c, 0x3c,
  0x3c, 0x3c, 0x3c, 0x3c, 0x3c
};

const int test_result[SIZE] = {
  0, (int) 0xffffffff, (int)0xffffffff, 0, 0,
  (int)0xffffffff, 0, 0, (int)0xffffffff, (int)0xffffffff,
  0, 0, 0x1, 0x1, 0,
  (int)0xfffffffe, (int)0xffffffff, (int)0xfffffffe, 0, (int)0xfffffffc,
  0x1, 0x1, 0x1, (int)0xfffffffb, 0x2,
  0x2, 0x3, 0xb, 0x14, 0x14,
  0x16, 0x18, 0x20, 0x21, 0x26,
  0x27, 0x2e, 0x2f, 0x33, 0x32,
  0x35, 0x33, 0x36, 0x34, 0x37,
  0x34, 0x37, 0x35, 0x38, 0x36,
  0x39, 0x38, 0x3b, 0x3a, 0x3f,
  0x3f, 0x40, 0x3a, 0x3d, 0x3e,
  0x41, 0x3c, 0x3e, 0x3f, 0x42,
  0x3e, 0x3b, 0x37, 0x3b, 0x3e,
  0x41, 0x3b, 0x3b, 0x3a, 0x3b,
  0x36, 0x39, 0x3b, 0x3f, 0x3c,
  0x3b, 0x37, 0x3b, 0x3d, 0x41,
  0x3d, 0x3e, 0x3c, 0x3e, 0x3b,
  0x3a, 0x37, 0x3b, 0x3e, 0x41,
  0x3c, 0x3b, 0x39, 0x3a, 0x36
};

int input_hw[SIZE];
int result_hw[SIZE];

int input_sw[SIZE];
int result_sw[SIZE];



int main ()
{
	int count, i;

	int main_result;

	for(i=0; i<SIZE; i++)
		input_hw[i] = i/3;
	for(i=0; i<SIZE; i++)
		input_sw[i] = i/3;


	main_result = 0;
	adpcm_main_hw (input_hw, result_hw);
	adpcm_main_sw (input_sw, result_sw);

	for (i = 0; i < IN_END; i++)
	{
		//printf("%d: HW=%d  SW=%d\n", i, result_hw[i], result_sw[i]);
		if (result_hw[i] != result_sw[i])
			main_result += 1;
	}
	printf ("Result = %d\n", main_result);
	return main_result;
    }
