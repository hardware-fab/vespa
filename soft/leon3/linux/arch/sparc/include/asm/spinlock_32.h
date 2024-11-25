/* spinlock.h: 32-bit Sparc spinlock support.
 *
 * Copyright (C) 1997 David S. Miller (davem@caip.rutgers.edu)
 */

#ifndef __SPARC_SPINLOCK_H
#define __SPARC_SPINLOCK_H

#ifndef __ASSEMBLY__

#include <asm/psr.h>
#include <asm/barrier.h>
#include <asm/processor.h> /* for cpu_relax */

#define arch_spin_is_locked(lock) (*((volatile unsigned char *)(lock)) != 0)

static inline void arch_spin_unlock_wait(arch_spinlock_t *lock)
{
	smp_cond_load_acquire(&lock->lock, !VAL);
}

static inline void arch_spin_lock(arch_spinlock_t *lock)
{
	__asm__ __volatile__(
	"\n1:\n\t"
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	"ldstub	[%0], %%g2\n\t"
#else
	"ldstuba	[%0] 1, %%g2\n\t" /* ASI_LEON23_DCACHE_MISS */
#endif
	"orcc	%%g2, 0x0, %%g0\n\t"
	"bne,a	2f\n\t"
	" ldub	[%0], %%g2\n\t"
	".subsection	2\n"
	"2:\n\t"
	"orcc	%%g2, 0x0, %%g0\n\t"
	"bne,a	2b\n\t"
	" ldub	[%0], %%g2\n\t"
	"b,a	1b\n\t"
	".previous\n"
	: /* no outputs */
	: "r" (lock)
	: "g2", "memory", "cc");
}

static inline int arch_spin_trylock(arch_spinlock_t *lock)
{
	unsigned int result;
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__("ldstub [%1], %0"
#else
	__asm__ __volatile__("ldstuba [%1] 1, %0" /* ASI_LEON23_DCACHE_MISS */
#endif
			     : "=r" (result)
			     : "r" (lock)
			     : "memory");
	return (result == 0);
}

static inline void arch_spin_unlock(arch_spinlock_t *lock)
{
	__asm__ __volatile__("stb %%g0, [%0]" : : "r" (lock) : "memory");
}

/* Read-write spinlocks, allowing multiple readers
 * but only one writer.
 *
 * NOTE! it is quite common to have readers in interrupts
 * but no interrupt writers. For those circumstances we
 * can "mix" irq-safe locks - any writer needs to get a
 * irq-safe write-lock, but readers can get non-irqsafe
 * read-locks.
 *
 * XXX This might create some problems with my dual spinlock
 * XXX scheme, deadlocks etc. -DaveM
 *
 * Sort of like atomic_t's on Sparc, but even more clever.
 *
 *	------------------------------------
 *	| 24-bit counter           | wlock |  arch_rwlock_t
 *	------------------------------------
 *	 31                       8 7     0
 *
 * wlock signifies the one writer is in or somebody is updating
 * counter. For a writer, if he successfully acquires the wlock,
 * but counter is non-zero, he has to release the lock and wait,
 * till both counter and wlock are zero.
 *
 * Unfortunately this scheme limits us to ~16,000,000 cpus.
 */
static inline void __arch_read_lock(arch_rwlock_t *rw)
{
	register arch_rwlock_t *lp asm("g1");
	lp = rw;
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"call	___rw_read_enter\n\t"
	" ldstub	[%%g1 + 3], %%g2\n"
	: /* no outputs */
	: "r" (lp)
	: "g2", "g4", "memory", "cc");
#else
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"set	3, %%g3\n\t" /* ___rw_read_enter assumes g3 is three! */
	"call	___rw_read_enter\n\t"
	" ldstuba	[%%g1 + %%g3]1, %%g2\n"  /* ASI_LEON23_DCACHE_MISS */
	: /* no outputs */
	: "r" (lp)
	: "g2", "g3", "g4", "memory", "cc");
#endif
}

#define arch_read_lock(lock) \
do {	unsigned long flags; \
	local_irq_save(flags); \
	__arch_read_lock(lock); \
	local_irq_restore(flags); \
} while(0)

static inline void __arch_read_unlock(arch_rwlock_t *rw)
{
	register arch_rwlock_t *lp asm("g1");
	lp = rw;
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"call	___rw_read_exit\n\t"
	" ldstub	[%%g1 + 3], %%g2\n"
	: /* no outputs */
	: "r" (lp)
	: "g2", "g4", "memory", "cc");
#else
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"set	3, %%g3\n\t" /* ___rw_read_exit assumes g3 is three! */
	"call	___rw_read_exit\n\t"
	" ldstuba	[%%g1 + %%g3] 1, %%g2\n" /* ASI_LEON23_DCACHE_MISS */
	: /* no outputs */
	: "r" (lp)
	: "g2", "g3", "g4", "memory", "cc");
#endif
}

#define arch_read_unlock(lock) \
do {	unsigned long flags; \
	local_irq_save(flags); \
	__arch_read_unlock(lock); \
	local_irq_restore(flags); \
} while(0)

static inline void arch_write_lock(arch_rwlock_t *rw)
{
	register arch_rwlock_t *lp asm("g1");
	lp = rw;
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"call	___rw_write_enter\n\t"
	" ldstub	[%%g1 + 3], %%g2\n"
	: /* no outputs */
	: "r" (lp)
	: "g2", "g4", "memory", "cc");
#else
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"set	3, %%g3\n\t" /* ___rw_write_enter assumes g3 is three! */
	"call	___rw_write_enter\n\t"
	" ldstuba	[%%g1 + %%g3] 1, %%g2\n" /* ASI_LEON23_DCACHE_MISS */
	: /* no outputs */
	: "r" (lp)
	: "g2", "g3", "g4", "memory", "cc");
#endif
	*(volatile __u32 *)&lp->lock = ~0U;
}

static inline void arch_write_unlock(arch_rwlock_t *lock)
{
	__asm__ __volatile__(
"	st		%%g0, [%0]"
	: /* no outputs */
	: "r" (lock)
	: "memory");
}

static inline int arch_write_trylock(arch_rwlock_t *rw)
{
	unsigned int val;

#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__("ldstub [%1 + 3], %0"
			     : "=r" (val)
			     : "r" (&rw->lock)
			     : "memory");
#else
	__asm__ __volatile__("set	3, %%g3\n\t"
			     "ldstuba [%1 + %%g3] 1, %0" /* 1=ASI DCACHE_MISS */
			     : "=r" (val)
			     : "r" (&rw->lock)
			     : "g3", "memory");
#endif
	if (val == 0) {
		val = rw->lock & ~0xff;
		if (val)
			((volatile u8*)&rw->lock)[3] = 0;
		else
			*(volatile u32*)&rw->lock = ~0U;
	}

	return (val == 0);
}

static inline int __arch_read_trylock(arch_rwlock_t *rw)
{
	register arch_rwlock_t *lp asm("g1");
	register int res asm("o0");
	lp = rw;
#if !(defined(CONFIG_SPARC_LEON) && defined(CONFIG_SMP))
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"call	___rw_read_try\n\t"
	" ldstub	[%%g1 + 3], %%g2\n"
	: "=r" (res)
	: "r" (lp)
	: "g2", "g4", "memory", "cc");
#else
	__asm__ __volatile__(
	"mov	%%o7, %%g4\n\t"
	"set 3, %%g3\n\t" /* __rw_read_try assumes g3 is three! */
	"call	___rw_read_try\n\t"
	" ldstuba	[%%g1 + %%g3] 1, %%g2\n" /* 1=ASI DCACHE_MISS */
	: "=r" (res)
	: "r" (lp)
	: "g2", "g3", "g4", "memory", "cc");
#endif
	return res;
}

#define arch_read_trylock(lock) \
({	unsigned long flags; \
	int res; \
	local_irq_save(flags); \
	res = __arch_read_trylock(lock); \
	local_irq_restore(flags); \
	res; \
})

#define arch_spin_lock_flags(lock, flags) arch_spin_lock(lock)
#define arch_read_lock_flags(rw, flags)   arch_read_lock(rw)
#define arch_write_lock_flags(rw, flags)  arch_write_lock(rw)

#define arch_spin_relax(lock)	cpu_relax()
#define arch_read_relax(lock)	cpu_relax()
#define arch_write_relax(lock)	cpu_relax()

#define arch_read_can_lock(rw) (!((rw)->lock & 0xff))
#define arch_write_can_lock(rw) (!(rw)->lock)

#endif /* !(__ASSEMBLY__) */

#endif /* __SPARC_SPINLOCK_H */
