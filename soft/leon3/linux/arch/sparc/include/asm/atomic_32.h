/* atomic.h: These still suck, but the I-cache hit rate is higher.
 *
 * Copyright (C) 1996 David S. Miller (davem@davemloft.net)
 * Copyright (C) 2000 Anton Blanchard (anton@linuxcare.com.au)
 * Copyright (C) 2007 Kyle McMartin (kyle@parisc-linux.org)
 *
 * Additions by Keith M Wesolowski (wesolows@foobazco.org) based
 * on asm-parisc/atomic.h Copyright (C) 2000 Philipp Rumpf <prumpf@tux.org>.
 */

#ifndef __ARCH_SPARC_ATOMIC__
#define __ARCH_SPARC_ATOMIC__

#include <linux/types.h>

#include <asm/cmpxchg.h>
#include <asm/barrier.h>
#include <asm-generic/atomic64.h>

#define ATOMIC_INIT(i)  { (i) }
#define atomic_read(v)          ACCESS_ONCE((v)->counter)

#ifdef CONFIG_SPARC_LEON_CAS

#define ATOMIC_OP(op)							\
void atomic_##op(int, atomic_t *);

#define ATOMIC_OP_RETURN(op)						\
int atomic_##op##_return(int, atomic_t *);

#define ATOMIC_FETCH_OP(op)						\
int atomic_fetch_##op(int, atomic_t *);

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

#define atomic_cmpxchg(v, o, n) (cmpxchg(&((v)->counter), (o), (n)))
#define atomic_xchg(v, new) (xchg(&((v)->counter), new))
#define atomic_set(v, i)	WRITE_ONCE(((v)->counter), (i))

static inline int __atomic_add_unless(atomic_t *v, int a, int u)
{
	int c, old;
	c = atomic_read(v);
	for (;;) {
		if (unlikely(c == (u)))
			break;
		old = atomic_cmpxchg((v), c, c + (a));
		if (likely(old == c))
			break;
		c = old;
	}
	return c;
}

#else /* CONFIG_SPARC_LEON_CAS */

int atomic_add_return(int, atomic_t *);
int atomic_fetch_add(int, atomic_t *);
int atomic_fetch_and(int, atomic_t *);
int atomic_fetch_or(int, atomic_t *);
int atomic_fetch_xor(int, atomic_t *);
int atomic_cmpxchg(atomic_t *, int, int);
int atomic_xchg(atomic_t *, int);
int __atomic_add_unless(atomic_t *, int, int);
void atomic_set(atomic_t *, int);

#endif /* CONFIG_SPARC_LEON_CAS */

#define atomic_add(i, v)	((void)atomic_add_return( (int)(i), (v)))
#define atomic_sub(i, v)	((void)atomic_add_return(-(int)(i), (v)))
#define atomic_inc(v)		((void)atomic_add_return(        1, (v)))
#define atomic_dec(v)		((void)atomic_add_return(       -1, (v)))

#define atomic_and(i, v)	((void)atomic_fetch_and((i), (v)))
#define atomic_or(i, v)		((void)atomic_fetch_or((i), (v)))
#define atomic_xor(i, v)	((void)atomic_fetch_xor((i), (v)))

#define atomic_sub_return(i, v)	(atomic_add_return(-(int)(i), (v)))
#define atomic_fetch_sub(i, v)  (atomic_fetch_add (-(int)(i), (v)))

#define atomic_inc_return(v)	(atomic_add_return(        1, (v)))
#define atomic_dec_return(v)	(atomic_add_return(       -1, (v)))

#define atomic_add_negative(a, v)	(atomic_add_return((a), (v)) < 0)

/*
 * atomic_inc_and_test - increment and test
 * @v: pointer of type atomic_t
 *
 * Atomically increments @v by 1
 * and returns true if the result is zero, or false for all
 * other cases.
 */
#define atomic_inc_and_test(v) (atomic_inc_return(v) == 0)

#define atomic_dec_and_test(v) (atomic_dec_return(v) == 0)
#define atomic_sub_and_test(i, v) (atomic_sub_return(i, v) == 0)

#endif /* !(__ARCH_SPARC_ATOMIC__) */
