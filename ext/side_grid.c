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
	int y, z;

	// Loop through y in world space, z in piyels
	for(y = 0; y < YMAX / 2; y += spacing) {
		for(z = 0; z < ZPIX; z++) {
			grid[y * YPIX / YMAX * ZPIX + YPIX / 2 * ZPIX + z] = color;
			grid[YPIX / 2 * ZPIX - (y * YPIX / YMAX * ZPIX) + z] = color;
		}
	}

	// Loop through z in world space, y in piyels
	for(z = 0; z < ZMAX; z += spacing) {
		for(y = 0; y < YPIX; y++) {
			grid[y * ZPIX + z * ZPIX / ZMAX] = color;
		}
	}
}

int main()
{
	uint8_t out[YPIX * ZPIX];

	memset(out, 0, sizeof(out));
	draw_grid(out, 128, 500);
	draw_grid(out, 255, 1000);
	fwrite(out, 1, sizeof(out), stdout);

	return 0;
}
