/* atomic_cas_32.S
 *
 * Copyright (C) 1999, 2007 2012 David S. Miller (davem@davemloft.net)
 *
 * Adaption for LEON with CAS from atomic_64.S, by Andreas Larsson
 * (andreas@gaisler.com).
 */

#include <linux/linkage.h>
#include <asm/asi.h>
#include <asm/export.h>

	.text

#define ATOMIC_OP(op)							\
ENTRY(atomic_##op) /* %o0 = increment, %o1 = atomic_ptr */		\
1:	ld	[%o1], %g1;						\
	op	%g1, %o0, %g7;						\
	casa	[%o1] 0xb, %g1, %g7;					\
	cmp	%g1, %g7;						\
	bne	1b;							\
	 nop;								\
	retl;								\
	 nop;								\
ENDPROC(atomic_##op);							\
EXPORT_SYMBOL(atomic_##op);

#define ATOMIC_OP_RETURN(op)						\
ENTRY(atomic_##op##_return) /* %o0 = increment, %o1 = atomic_ptr */	\
1:	ld	[%o1], %g1;						\
	op	%g1, %o0, %g7;						\
	casa	[%o1] 0xb, %g1, %g7;					\
	cmp	%g1, %g7;						\
	bne	1b;							\
	 nop;								\
	retl;								\
	 op	%g1, %o0, %o0;						\
ENDPROC(atomic_##op##_return);					\
EXPORT_SYMBOL(atomic_##op##_return);

#define ATOMIC_FETCH_OP(op)						\
ENTRY(atomic_fetch_##op) /* %o0 = increment, %o1 = atomic_ptr */	\
1:	ld	[%o1], %g1;						\
	op	%g1, %o0, %g7;						\
	casa	[%o1] 0xb, %g1, %g7;					\
	cmp	%g1, %g7;						\
	bne	1b;							\
	 nop;								\
	retl;								\
	 mov	%g1, %o0;						\
ENDPROC(atomic_fetch_##op);						\
EXPORT_SYMBOL(atomic_fetch_##op);

#define ATOMIC_OPS(op) ATOMIC_OP(op) ATOMIC_OP_RETURN(op) ATOMIC_FETCH_OP(op)

ATOMIC_OPS(add)
ATOMIC_OPS(sub)

#undef ATOMIC_OPS
#define ATOMIC_OPS(op) ATOMIC_OP(op) ATOMIC_FETCH_OP(op)

ATOMIC_OPS(and)
ATOMIC_OPS(or)
ATOMIC_OPS(xor)

#undef ATOMIC_OPS
#undef ATOMIC_FETCH_OP
#undef ATOMIC_OP_RETURN
#undef ATOMIC_OP
