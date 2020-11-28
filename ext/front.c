/*
 * Experimental Kinect depth image unpacking code.
 * (C)2011 Mike Bourgeous
 */
#include <stdio.h>
#include <stdint.h>

#include "unpack.h"

int main()
{
	uint16_t in[640 * 480];
	uint8_t out[XPIX * YPIX];

	if(fread(in, 2, 640 * 480, stdin) != 640 * 480) {
		fprintf(stderr, "Must provide %d bytes of unpacked depth data to stdin.\n", 640 * 480 * 2);
	}

	ku_init_lut();
	plot_front(in, out);

	fwrite(out, 1, sizeof(out), stdout);
	
	return 0;
}

