# Linux4nLaunch

This program will create a compatible binary image for loading with nLaunch. It packs a kernel, initrd, bootargs and kernel parameters all into one. This means you can 'permanently' install Linux to calculators supported by nLaunch. This can reduce boot time to about 20-25 seconds instead of going through the Nspire OS.

Note that this is not well tested at the moment and there are some issues with the booted system.

## Usage

Run ```make``` in the directory to build the template files and program.

Use the ```makebin``` program with the produced ```template.bin```, your kernel, initrd and boot parameters. Run with the ```-h``` flag to see a list of options.

Put the produced binary through the ```buildos.sh``` script that comes with nLaunch with a empty zip folder to produce the OS update file.

From there, follow instructions as per nLaunch to install the binary.

## Download mode patch

When using Linux installed using this method, there won't be a Nspire software to manipulate files. To upgrade the kernel, you would need to reformat and reinstall everything from scratch.

The download mode patch for nLaunch will let you enter boot2's 'download mode' where you can manipulate files (like dragging upgrade files into the nlaunch folder).

Hold down tab as nLaunch is booting and it will eventually freeze during boot. You can now connect a USB cable to the calculator and manipulate files as per normal.

## Limitations

nLaunch insists on executing the OS at address 0x10000000 which is inside the 4MB zreladdr range for the kernel. That means that we have to do a lot of redundant work re-relocating the kernel out. This adds about 2-3 seconds to boot time.

