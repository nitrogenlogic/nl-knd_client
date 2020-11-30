/*
 * Non-inline definitions and functions for Kinect data pack/unpack code.
 * (C)2011 Mike Bourgeous
 */
#include <string.h>
#include <math.h>

#include <nlutils/nlutils.h>

#define UNPACK_INLINE
#include "unpack.h"

// Depth look-up table (translates depth sample into world-space millimeters).
int ku_depth_lut[2048];

// Initializes the depth look-up table.
// Copied from the knd daemon code, based on:
// http://groups.google.com/group/openkinect/browse_thread/thread/31351846fd33c78/e98a94ac605b9f21#e98a94ac605b9f21
void ku_init_lut()
{
	int i;

	for(i = 0; i < 2047; i++) {
		ku_depth_lut[i] = (int)(0.1236f * tanf(i / 2842.5f + 1.1863f) * 1000.0f);
	}
	ku_depth_lut[2047] = 1048576;
}

// Finds the closest entry in the depth look-up table to the given world-space
// depth value in millimeters without going over.  Uses a binary search.
int ku_reverse_lut(int zw)
{
	int idx = PXZMAX / 2;
	int off = PXZMAX / 4;

	while(off > 0 && ku_depth_lut[idx] != zw) {
		if(ku_depth_lut[idx] > zw) {
			idx -= off;
		} else if(ku_depth_lut[idx] < zw) {
			idx += off;
		}

		off >>= 1;
	}

	// Binary search isn't perfect due to truncation, so find the optimum value
	while(ku_depth_lut[idx] > zw && idx > 0) {
		idx--;
	}
	while(ku_depth_lut[idx + 1] < zw && idx <= PXZMAX) {
		idx++;
	}

	return idx;
}

// Plots a linear depth version of the given perspective image on the 8-bit
// output surface, which must be 640x480 bytes.
void plot_linear(const uint16_t *in, uint8_t *out)
{
	int x, y, pix;

	for(pix = 0, y = 0; y < 640; y++) {
		for(x = 0; x < 480; x++, pix++) {
			out[pix] = 255 - CLAMP(0, 255, ((int32_t)ku_depth_lut[(65535 - in[pix]) >> 5] - 400) * 255 / ZMAX);
		}
	}
}

// Turns overhead view coordinates into a pixel index.
#define OVPX(xw, zw) (((zw) * ZPIX / ZMAX) * XPIX + ((xw) * XPIX / XMAX + XPIX / 2))

// Plots an overhead view on the given raw linear 8-bit grayscale image
// surface, which must be XPIX bytes wide by ZPIX bytes tall.
void plot_overhead(const uint16_t *in, uint8_t *out)
{
	int y, x, pix, val;
	int xw, zw, opx;
	int c;

	memset(out, 0, XPIX * ZPIX);

	// TODO: Draw borders

	for(pix = 0, y = 0; y < 480; y++) {
		for(x = 0; x < 640; x++, pix++) {
			val = (65535 - in[pix]) >> 5;
			zw = ku_depth_lut[val];
			if(val >= 2047 || zw >= ZMAX) {
				continue;
			}
			xw = ku_xworld(x, zw);

			opx = OVPX(xw, zw);
			if(opx < 0 || opx >= XPIX * ZPIX) {
				continue;
			}
			c = out[opx];
			c += 2;
			if(c > 255) {
				c = 255;
			}
			out[opx] = c;
		}
	}
}

// Turns side view coordinates into a pixel index.
#define SVPX(zw, yw) (((-yw) * YPIX / YMAX + YPIX / 2) * ZPIX + ((zw) * ZPIX / ZMAX))

// Plots a side view on the given raw linear 8-bit grayscale image surface,
// which must be ZPIX bytes wide by YPIX bytes tall.
void plot_side(const uint16_t *in, uint8_t *out)
{
	int y, x, pix, val;
	int yw, zw, opx;
	int c;

	memset(out, 0, ZPIX * YPIX);

	// TODO: Draw borders
	// TODO: Allow skipping for speed

	for(pix = 0, y = 0; y < 480; y++) {
		for(x = 0; x < 640; x++, pix++) {
			val = (65535 - in[pix]) >> 5;
			zw = ku_depth_lut[val];
			if(val >= 2047 || zw >= ZMAX) {
				continue;
			}
			yw = ku_yworld(y, zw);

			opx = SVPX(zw, yw);
			if(opx < 0 || opx >= ZPIX * YPIX) {
				continue;
			}
			c = out[opx];
			c += 2;
			if(c > 255) {
				c = 255;
			}
			out[opx] = c;
		}
	}
}

// Turns front view coordinates into a pixel index.
#define FVPX(xw, yw) (((-yw) * YPIX / YMAX + YPIX / 2) * XPIX + ((-xw) * XPIX / XMAX + XPIX / 2))

// Plots a front view on the given raw linear 8-bit grayscale image surface,
// which must be XPIX bytes wide by YPIX bytes tall.
void plot_front(const uint16_t *in, uint8_t *out)
{
	int y, x, pix, val;
	int xw, yw, zw, opx;
	int c;

	memset(out, 0, XPIX * YPIX);

	// TODO: Draw borders
	// TODO: Allow skipping for speed

	for(pix = 0, y = 0; y < 480; y++) {
		for(x = 0; x < 640; x++, pix++) {
			val = (65535 - in[pix]) >> 5;
			zw = ku_depth_lut[val];
			if(val >= 2047 || zw >= ZMAX) {
				continue;
			}
			xw = ku_xworld(x, zw);
			yw = ku_yworld(y, zw);

			opx = FVPX(xw, yw);
			if(opx < 0 || opx >= XPIX * YPIX) {
				continue;
			}
			c = out[opx];
			c += 1 + (zw - 512) / 256; // TODO: Scale intensity by surface area
			if(c > 255) {
				c = 255;
			}
			out[opx] = c;
		}
	}
}

