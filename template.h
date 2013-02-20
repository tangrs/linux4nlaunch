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

#ifndef _TEMPLATE_H
#define _TEMPLATE_H

#define CMDLINE_MAX		128
#define TEMPLATE_VERSION	0x0
#define TEMPLATE_MAGIC		0x4e52454b

#ifndef __ASSEMBLER__

#include <stdint.h>

struct bin_template {
	uint32_t	reserved; /* Branch instruction */

	uint32_t	magic; /* 'KERN' */
	uint32_t	version; /* version of this template */

	uint32_t	mach_id; /* Machine ID */

	uint32_t	ramdisk_size; /* Size of ramdisk in kernel (in KB) */
	uint32_t	initrd_size; /* Size of initrd */
	uint32_t	phys_size; /* Size of physical memory */

	uint8_t		cmdline[CMDLINE_MAX];
};

#endif

#endif
