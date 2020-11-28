/*
 * Code to render a basic grid for the overhead view, for later manipulation.
 * The final grid will be created from this program's output using the GIMP.
 * (C)2012 Mike Bourgeous
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "unpack.h"

void draw_grid(uint8_t *grid, uint8_t color, int spacing)
{
	int x, z;

	// Loop through x in world space, z in pixels
	for(x = 0; x < XMAX / 2; x += spacing) {
		for(z = 0; z < ZPIX; z++) {
			grid[x * XPIX / XMAX + XPIX / 2 + z * XPIX] = color;
			grid[XPIX / 2 - (x * XPIX / XMAX) + z * XPIX] = color;
		}
	}

	// Loop through z in world space, x in pixels
	for(z = 0; z < ZMAX; z += spacing) {
		for(x = 0; x < XPIX; x++) {
			grid[x + z * ZPIX / ZMAX * XPIX] = color;
		}
	}
}

int main()
{
	uint8_t out[XPIX * ZPIX];

	memset(out, 0, sizeof(out));
	draw_grid(out, 128, 500);
	draw_grid(out, 255, 1000);
	fwrite(out, 1, sizeof(out), stdout);

	return 0;
}
