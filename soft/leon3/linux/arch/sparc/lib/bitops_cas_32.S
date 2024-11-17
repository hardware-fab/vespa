/* bitops_cas_32.S: Sparc32 atomic bit operations for LEON with CAS.
 *
 * Copyright (C) 2000, 2007 David S. Miller (davem@davemloft.net)
 *
 * Adaption for LEON with CAS from bitops.S, by Andreas Larsson
 * (andreas@gaisler.com).
 */

#include <linux/linkage.h>
#include <asm/asi.h>
#include <asm/export.h>

	.text

ENTRY(test_and_set_bit)	/* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	or	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 clr	%o0
	andcc	%g7, %o2, %g2
	bne,a	2f
	 mov	1, %o0
2:	retl
	 nop
ENDPROC(test_and_set_bit)
EXPORT_SYMBOL(test_and_set_bit)

ENTRY(test_and_clear_bit) /* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	andn	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 clr	%o0
	andcc	%g7, %o2, %g2
	bne,a	2f
	 mov	1, %o0
2:	retl
	 nop
ENDPROC(test_and_clear_bit)
EXPORT_SYMBOL(test_and_clear_bit)

ENTRY(test_and_change_bit) /* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	xor	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 clr	%o0
	andcc	%g7, %o2, %g2
	bne,a	2f
	 mov	1, %o0
2:	retl
	 nop
ENDPROC(test_and_change_bit)
EXPORT_SYMBOL(test_and_change_bit)

ENTRY(set_bit) /* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	or	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 nop
	retl
	 nop
ENDPROC(set_bit)
EXPORT_SYMBOL(set_bit)

ENTRY(clear_bit) /* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	andn	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 nop
	retl
	 nop
ENDPROC(clear_bit)
EXPORT_SYMBOL(clear_bit)

ENTRY(change_bit) /* %o0=nr, %o1=addr */
	srl	%o0, 5, %g1
	mov	1, %o2
	sll	%g1, 2, %g3
	and	%o0, 31, %g2
	sll	%o2, %g2, %o2
	add	%o1, %g3, %o1
1:	ld	[%o1], %g7
	xor	%g7, %o2, %g1
	casa	[%o1] 0xb, %g7, %g1
	cmp	%g7, %g1
	bne	1b
	 nop
	retl
	 nop
ENDPROC(change_bit)
EXPORT_SYMBOL(change_bit)
