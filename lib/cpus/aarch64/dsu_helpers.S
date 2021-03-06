/*
 * Copyright (c) 2018, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <asm_macros.S>
#include <dsu_def.h>
#include <errata_report.h>

/*
 * DSU erratum 936184
 * Check the DSU variant, revision and configuration to determine if the
 * erratum applies. This erratum was fixed in r2p0.
 *
 * This function is called from both assembly and C environment. So it
 * follows AAPCS.
 *
 * Clobbers: x0-x3
 */
	.globl	check_errata_dsu_936184
	.globl	errata_dsu_936184_wa

func check_errata_dsu_936184
	mov	x2, #ERRATA_NOT_APPLIES
	mov	x3, #ERRATA_APPLIES

	/* Erratum applies only if ACP interface is present in DSU */
	mov	x0, x2
	mrs	x1, CLUSTERCFR_EL1
	ubfx	x1, x1, #CLUSTERCFR_ACP_SHIFT, #1
	cbz	x1, 1f

	/* If ACP is present, check if DSU is older than r2p0 */
	mrs	x1, CLUSTERIDR_EL1

	/* DSU variant and revision bitfields in CLUSTERIDR are adjacent */
	ubfx	x0, x1, #CLUSTERIDR_REV_SHIFT,\
			#(CLUSTERIDR_REV_BITS + CLUSTERIDR_VAR_BITS)
	mov	x1, #(0x2 << CLUSTERIDR_REV_BITS)
	cmp	x0, x1
	csel	x0, x2, x3, hs
1:
	ret
endfunc check_errata_dsu_936184

func errata_dsu_936184_wa
	mov	x20, x30
	bl	check_errata_dsu_936184
	cbz	x0, 1f

	/* If erratum applies, we set a mask to a DSU control register */
	mrs	x0, CLUSTERACTLR_EL1
	ldr	x1, =DSU_ERRATA_936184_MASK
	orr	x0, x0, x1
	msr	CLUSTERACTLR_EL1, x0
	isb
1:
	ret	x20
endfunc errata_dsu_936184_wa
