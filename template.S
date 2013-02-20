//
// nLaunch Linux Loader template
//
//     Copyright (C) 2013  Daniel Tang
//
//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#include "template.h"

#define PHYS_RAM_START	0x10000000

#define KERNEL_RELOC	(PHYS_RAM_START + 0x00400000)
#define INITRD_RELOC	(PHYS_RAM_START + 0x00800000)

/* Header begin */
b main
.long TEMPLATE_MAGIC	/* Magic number */
.long TEMPLATE_VERSION	/* Template version */
mach_id:	.long 0
ramdisk_size:	.long 0
initrd_size:	.long 0
phys_size:	.long 0
cmdline:	.fill CMDLINE_MAX, 1, 0
/* Header end */

/* Static data */
kernel_magic: 	.long 0x016F2818

//
// Register allocations:
//	r0-r10	temporaries
//	r11-r12	local temporaries
//

main:
	// Disable interrupts and ensure we are in SVC mode

	mrs r0, cpsr
	bic r0, r0, #0xFF
	orr r0, r0, #0xD3
	msr cpsr, r0

	// Sanity check

	ldr r0, kernel_start + 0x24
	ldr r1, kernel_magic
	cmp r0, r1
	bne panic

	// Relocate kernel and initrds

	ldr r0, kernel_start + 0x28 /* Start */
	ldr r1, kernel_start + 0x2C /* End */
	sub r2, r1, r0 /* Get kernel size */

	mov r0, #KERNEL_RELOC
	adr r1, kernel_start
	add r11, r1, r2

	bl memcpy /* Reloc kernel */

	mov r0, #INITRD_RELOC
	mov r1, r11
	ldr r2, initrd_size
	str r2, atag_initrd_size /* Fill it in while we're at it */

	bl memcpy /* Reloc initrd */

	// Start filling ATAGs

	ldr r0, ramdisk_size
	str r0, atag_ramdisk_kbsize

	ldr r0, phys_size
	str r0, atag_mem_size

	mov r0, #PHYS_RAM_START
	str r0, atag_mem_start

	mov r0, #INITRD_RELOC
	str r0, atag_initrd_start

	adr r0, atag_cmdline
	adr r1, cmdline
	mov r2, #CMDLINE_MAX
	bl memcpy

	// Boot the kernel

	mov r0, #0
	ldr r1, mach_id
	adr r2, atag_list

	mov pc, #KERNEL_RELOC

panic:
	b panic

memcpy: /* r0 = dst, r1 = src, r2 = size */
	cmp r2, #0
	bxeq lr
	_copy:
		ldmia r1!, {r3-r10}
		stmia r0!, {r3-r10}
		subs r2, r2, #32
	bgt _copy
	bx lr

/* Start ATAG list */

#define ATAG_NONE       0x00000000
#define ATAG_CORE       0x54410001
#define ATAG_MEM        0x54410002
#define ATAG_VIDEOTEXT  0x54410003
#define ATAG_RAMDISK    0x54410004
#define ATAG_INITRD2    0x54420005
#define ATAG_SERIAL     0x54410006
#define ATAG_REVISION   0x54410007
#define ATAG_VIDEOLFB   0x54410008
#define ATAG_CMDLINE    0x54410009

atag_list:

.long 2
.long ATAG_CORE

	/* Physical memory */
	.long 4
	.long ATAG_MEM
		atag_mem_size:		.long 0
		atag_mem_start:		.long 0

	/* Ramdisk */
	.long 5
	.long ATAG_RAMDISK
		.long 0 //Flags
		atag_ramdisk_kbsize:	.long 0
		.long 0 // Start

	/* Initrd */
	.long 4
	.long ATAG_INITRD2
		atag_initrd_start:	.long 0
		atag_initrd_size:	.long 0

	/* Command line */
	.long 2 + ((CMDLINE_MAX + 3) / 4)
	.long ATAG_CMDLINE
		atag_cmdline:		.fill CMDLINE_MAX, 1, 0

.long 0
.long ATAG_NONE

/* End ATAG list */

.align 2
kernel_start:
