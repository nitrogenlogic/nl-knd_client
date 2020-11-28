/*
 * Definitions for Kinect data pack/unpack code.
 * (C)2011 Mike Bourgeous
 */
#ifndef UNPACK_H_
#define UNPACK_H_

#include <stdint.h>

#ifndef UNPACK_INLINE
#define UNPACK_INLINE inline
#endif /* UNPACK_INLINE */

// assuming xmax~=3.797 and ymax~=2.848 when z ~= 7
// calculated as x=5*tan(28)/tan(35) and y=x*3/4
#define XPIX 500
#define YPIX 500
#define ZPIX 500
#define XMAX 7594 // Actually 2*xmax
#define YMAX 5696 // Actually 2*ymax
#define ZMAX 7000
#define PXZMAX 1092


// Depth look-up table (translates depth sample into world-space millimeters).
extern int ku_depth_lut[2048];

// Unpacks and inverts 8 11-bit pixels (11 bytes) from in and stores them as
// MSB-aligned 16-bit values in out (16 bytes)
UNPACK_INLINE void unpack11_to_16(const uint8_t *in, uint16_t *out)
{
	out[0] = 65535 - (((in[0] << 3) | (in[1] >> 5)) << 5);
	out[1] = 65535 - ((((in[1] & 0x1f) << 6) | (in[2] >> 2)) << 5);
	out[2] = 65535 - ((((in[2] & 0x03) << 9) | (in[3] << 1) | (in[4] >> 7)) << 5);
	out[3] = 65535 - ((((in[4] & 0x7f) << 4) | (in[5] >> 4)) << 5);
	out[4] = 65535 - ((((in[5] & 0x0f) << 7) | (in[6] >> 1)) << 5);
	out[5] = 65535 - ((((in[6] & 0x01) << 10) | (in[7] << 2) | (in[8] >> 6)) << 5);
	out[6] = 65535 - ((((in[8] & 0x3f) << 5) | (in[9] >> 3)) << 5);
	out[7] = 65535 - ((((in[9] & 0x07) << 8) | in[10]) << 5);
}

// Packs 8 LSB-aligned 11-in-16-bit pixels (16 bytes) into 11 output bytes
UNPACK_INLINE void pack16_to_11(const uint16_t *in, uint8_t *out)
{
	out[0] = in[0] >> 3;
	out[1] = ((in[0] & 0x07) << 5) | (in[1] >> 6);
	out[2] = ((in[1] & 0x3f) << 2) | (in[2] >> 9);
	out[3] = (in[2] & 0x1fe) >> 1;
	out[4] = ((in[2] & 0x01) << 7) | (in[3] >> 4);
	out[5] = ((in[3] & 0x0f) << 4) | (in[4] >> 7);
	out[6] = ((in[4] & 0x7f) << 1) | (in[5] >> 10);
	out[7] = (in[5] & 0x3fc) >> 2;
	out[8] = ((in[5] & 0x03) << 6) | (in[6] >> 5);
	out[9] = ((in[6] & 0x1f) << 3) | (in[7] >> 8);
	out[10] = in[7] & 0xff;
}

// Unpacks 8 11-bit pixels (11 bytes) into 8 output bytes
UNPACK_INLINE void unpack11_to_8(const uint8_t *in, uint8_t *out)
{
	uint16_t buf16[8];
	int i;

	unpack11_to_16(in, buf16);
	for(i = 0; i < 8; i++) {
		out[i] = buf16[i] >> 3;
	}
}

// Unpacks a single pixel into a right-aligned 16-bit value
UNPACK_INLINE int pxval_11(uint8_t *buf, int pixel)
{
	uint32_t byteindex = (pixel * 11) >> 3;
	uint32_t shiftbits = ((7 + pixel * 5) & 0x7) + 14;
	uint32_t base;

	buf = buf + byteindex;
	base = (buf[0] << 24) | (buf[1] << 16) | (buf[2] << 8) | buf[3];

	return (base >> shiftbits) & 0x7ff;
}

// Initializes the depth look-up table.
// Copied from the knd daemon code, based on:
// http://groups.google.com/group/openkinect/browse_thread/thread/31351846fd33c78/e98a94ac605b9f21#e98a94ac605b9f21
void ku_init_lut();

// Finds the closest entry in the depth look-up table to the given world-space
// depth value in millimeters without going over.  Uses a binary search.
int ku_reverse_lut(int zw);

// Plots a linear depth version of the given perspective image on the 8-bit
// output surface, which must be 640x480 bytes.
void plot_linear(const uint16_t *in, uint8_t *out);

// Plots an overhead view on the given raw linear 8-bit grayscale image
// surface, which must be XPIX bytes wide by ZPIX bytes tall.
void plot_overhead(const uint16_t *in, uint8_t *out);

// Plots a side view on the given raw linear 8-bit grayscale image surface,
// which must be ZPIX bytes wide by YPIX bytes tall.
void plot_side(const uint16_t *in, uint8_t *out);

// Plots a front view on the given raw linear 8-bit grayscale image surface,
// which must be XPIX bytes wide by YPIX bytes tall.
void plot_front(const uint16_t *in, uint8_t *out);

#endif /* UNPACK_H_ */
