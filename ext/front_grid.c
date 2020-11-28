/*
 * Code to render a basic grid for the side view, for later manipulation.
 * The final grid will be created from this program's output using the GIMP.
 * (C)2012 Mike Bourgeous
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "unpack.h"

void draw_grid(uint8_t *grid, uint8_t color, int spacing)
{
	int x, y;

	// Loop through x in world space, y in pixels
	for(x = 0; x < XMAX / 2; x += spacing) {
		for(y = 0; y < YPIX; y++) {
			grid[XPIX / 2 + x * XPIX / XMAX + y * XPIX] = color;
			grid[XPIX / 2 - x * XPIX / XMAX + y * XPIX] = color;
		}
	}

	// Loop through y in world space, x in pixels
	for(y = 0; y < YMAX / 2; y += spacing) {
		for(x = 0; x < XPIX; x++) {
			grid[x + YPIX / 2 * XPIX + y * YPIX / YMAX * XPIX] = color;
			grid[x + YPIX / 2 * XPIX - y * YPIX / YMAX * XPIX] = color;
		}
	}
}

int main()
{
	uint8_t out[XPIX * YPIX];

	memset(out, 0, sizeof(out));
	draw_grid(out, 128, 500);
	draw_grid(out, 255, 1000);
	fwrite(out, 1, sizeof(out), stdout);

	return 0;
}
