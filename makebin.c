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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

#include "template.h"

#define VALID_OPTS	"t:i:k:o:m:r:p:c:h"
#define BUFF_SIZE	0x100

void print_help() {
	printf("Makes all-in-one Linux loader\n"
		"Options:\n"
		"	-h	help\n"
		"	-t	template file\n"
		"	-i	initrd\n"
		"	-k	kernel\n"
		"	-m	machine number\n"
		"	-r	ramdisk size\n"
		"	-p	physical memory size\n"
		"	-c	cmdline\n"
		"	-o	output file\n");
}

size_t append_file(FILE *in, FILE *out) {
	size_t bytes = 0, read;
	char buffer[BUFF_SIZE];

	if (!in) goto out;

	while ( (read = fread(buffer, 1, sizeof(buffer), in)) ) {
		bytes += fwrite(buffer, 1, read, out);
	}

out:
	return bytes;
}

int main(int argc, char *argv[]) {
	struct bin_template header;
	size_t initrd_size;
	uint32_t mach_number = 0,
		rdisk_size = (16*1024),
		phys_size = 0x2000000;
	char cmdline[CMDLINE_MAX] = {0};
	FILE 	*tfile = NULL,
		*initrd = NULL,
		*kernel = NULL,
		*out = NULL;
	int c;

	while ((c = getopt (argc, argv, VALID_OPTS)) != -1) {
		switch (c) {
		case 't':
			tfile = fopen(optarg, "rb");
			if (!tfile) perror(NULL);
			break;
		case 'i':
			initrd = fopen(optarg, "rb");
			if (!initrd) perror(NULL);
			break;
		case 'k':
			kernel = fopen(optarg, "rb");
			if (!kernel) perror(NULL);
			break;
		case 'm':
			mach_number = atoi(optarg);
			break;
		case 'r':
			rdisk_size = atoi(optarg);
			break;
		case 'p':
			phys_size = atoi(optarg);
			break;
		case 'o':
			out = fopen(optarg, "w+b");
			if (!out) perror(NULL);
			break;
		case 'c':
			strncpy(cmdline, optarg, sizeof(cmdline)-1);
			break;
		default:
			print_help();
			exit(0);
			break;
		}
	}

	if (!tfile || !kernel || !out) {
		fprintf(stderr, "Not enough arguments!\n");
		print_help();
		exit(-1);
	}

	if (!mach_number)
		fprintf(stderr, "Warning: Machine number set to %d\n",
				mach_number);

	append_file(tfile, out);
	append_file(kernel, out);
	initrd_size = append_file(initrd, out);

	fseek(out, 0, SEEK_SET);
	fread(&header, 1, sizeof(header), out);

	if (header.magic != TEMPLATE_MAGIC) {
		fprintf(stderr, "Invalid magic in template file!\n");
		exit(-1);
	}

	if (header.version != TEMPLATE_VERSION)
		fprintf(stderr, "Warning: Version mismatch.\n");

	header.mach_id = mach_number;
	header.ramdisk_size = rdisk_size;
	header.initrd_size = initrd_size;
	header.phys_size = phys_size;
	strncpy((char*)header.cmdline, cmdline, sizeof(header.cmdline));

	printf(	"Your binary has the following parameters:\n"
		"	Machine ID: %d\n"
		"	Ramdisk size: %dKB\n"
		"	Initrd size: %luB\n"
		"	Physical memory size: %08x\n"
		"	Command line: %s\n",
		mach_number, rdisk_size, initrd_size, phys_size, cmdline);

	fseek(out, 0, SEEK_SET);
	fwrite(&header, 1, sizeof(header), out);

	fclose(out);
	fclose(tfile);
	fclose(kernel);
	fclose(initrd);

	return 0;
}
