/*
 * Experimental Kinect depth image unpacking code.
 * (C)2011 Mike Bourgeous
 */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#include "unpack.h"

int main(int argc, char *argv[])
{
	uint8_t buf11[11];
	uint8_t buf8out[8];
	uint16_t buf16out[8];
	enum { TO_16, TO_8, PIX_TO_16 } mode = TO_16;

	if(argc >= 2) {
		if(!strcmp(argv[1], "-8")) {
			mode = TO_8;
		} else if(!strcmp(argv[1], "-i")) {
			mode = PIX_TO_16;
		}
	}
	
	if(mode == PIX_TO_16) {
		uint8_t in[640 * 480 * 11 / 8];
		uint16_t val;
		int idx;

		if(fread(in, 1, sizeof(in), stdin) != sizeof(in)) {
			fprintf(stderr, "Must provide %zu bytes on stdin.\n", sizeof(in));
			return -1;
		}

		for(idx = 0; idx < 640 * 480; idx++) {
			val = 65535 - (pxval_11(in, idx) << 5);
			fwrite(&val, 2, 1, stdout);
		}

		return 0;
	}

	while(!feof(stdin)) {
		memset(buf11, 0, 11);
		if(fread(buf11, 1, 11, stdin) <= 0) {
			break;
		}

		switch(mode) {
			case TO_16:
				unpack11_to_16(buf11, buf16out);
				fwrite(buf16out, 16, 1, stdout);
				break;

			case TO_8:
				unpack11_to_8(buf11, buf8out);
				fwrite(buf8out, 8, 1, stdout);
				break;

			default:
				break;
		}
	}

	return 0;
}

