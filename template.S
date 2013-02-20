//
// nLaunch Linux Loader template
//

#define CMDLINE_MAX	128
#define PHYS_RAM_START	0x10000000
#define RELOC_LOCATION	(PHYS_RAM_START + 0x400000)

// struct {
//	uint32_t	reserved; /* Branch instruction */
//
// 	uint32_t	magic; /* 'KERN' */
// 	uint32_t	bin_version; /* version of this template */
//
// 	uint32_t	mach_id; /* Machine ID */
//
// 	uint32_t	ramdisk_size; /* Size of ramdisk in kernel (in KB) */
//	uint32_t	initrd_size; /* Size of initrd */
// 	uint32_t	phys_size; /* Size of physical memory */
//
// 	char		cmdline[CMDLINE_MAX];
// };

// Struct begin

b main

.ascii "KERN"	/* Magic number */
.long 0x0	/* Template version */

mach_id:	.long 0

ramdisk_size:	.long 0
initrd_size:	.long 0
phys_size:	.long 0

cmdline:	.fill CMDLINE_MAX, 1, 0

// Struct end

main:

	// Disable interrupts and ensure we are in SVC mode

	mrs r0, cpsr
	bic r0, r0, #0xFF
	orr r0, r0, #0xD3
	msr cpsr, r0

	mov sp, #0x11000000

	// Sanity check

	ldr r0, kernel_start + 0x24
	ldr r1, zimage_magic
	cmp r0, r1
	bne panic

	// Start filling ATAGs

	ldr r0, ramdisk_size
	str r0, atag_ramdisk_kbsize

	ldr r0, phys_size
	str r0, atag_mem_size

	mov r0, #PHYS_RAM_START
	str r0, atag_mem_start

	/* Are we allowed to have a initrd size of 0? */
//	ldr r0, initrd_size
//	str r0, atag_initrd_size

	/* If there is an initrd, it'll be at the end */
	ldr r0, kernel_start + 0x28 /* Start */
	ldr r1, kernel_start + 0x2C /* End */
	sub r5, r1, r0 /* Get kernel size */
//	add r0, r5, #RELOC_LOCATION /* initrd start address */
//	str r0, atag_initrd_start

//	ldr r0, initrd_size
//	add r5, r5, r0 /* Total image size */

	adr r0, atag_cmdline
	adr r1, cmdline
	mov r2, #CMDLINE_MAX
	bl memcpy

	// Relocate kernel

	mov r0, #RELOC_LOCATION
	adr r1, kernel_start
	mov r2, r5 /* Size incl initrd */
	bkpt #1
	bl memcpy

	// Boot the kernel

	mov r0, #0
	ldr r1, mach_id
	adr r2, atag_list

	mov pc, #RELOC_LOCATION

panic:
	b panic

memcpy: /* r0 = dst, r1 = src, r2 = size */
	/* Slow and stupid */
	ldrb r3, [r1]
	strb r3, [r0]
	add r0, r0, #1
	add r1, r1, #1
	subs r2, r2, #1
	bne memcpy
	bx lr

zimage_magic: 	.long 0x016F2818

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

// Start list
.long 2
.long ATAG_CORE

	// Physical memory
	.long 4
	.long ATAG_MEM
		atag_mem_size:		.long 0
		atag_mem_start:		.long 0

	// Ramdisk
	.long 5
	.long ATAG_RAMDISK
		.long 0 //Flags
		atag_ramdisk_kbsize:	.long 0
		.long 0 // Start

/*	// Initrd
	.long 4
	.long ATAG_INITRD2
		atag_initrd_start:	.long 0
		atag_initrd_size:	.long 0
*/
	// Command line
	.long 2 + ((CMDLINE_MAX + 3) / 4)
	.long ATAG_CMDLINE
		atag_cmdline:		.fill CMDLINE_MAX, 1, 0

// End list
.long 0
.long ATAG_NONE

//.align 2
kernel_start:
