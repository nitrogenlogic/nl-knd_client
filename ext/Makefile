# This Makefile is for building standalone executables for processing raw
# 11-bit Kinect depth data from the command line.
#
# Example:
# cat depth11.raw | ./unpack -i | ./overhead | convert -size 500x500 -depth 8 GRAY:- /tmp/overhead.png
.PHONY: clean all

RUBY?=/usr/bin/env ruby

CFLAGS=-Wall -Wextra -std=gnu99 -O3 -D_GNU_SOURCE

all: unpack overhead side front ext overhead_grid side_grid front_grid

unpack: kinutils/unpack.c unpacktest.c Makefile
	gcc kinutils/unpack.c unpacktest.c -o unpack $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

overhead: kinutils/unpack.c overhead.c Makefile
	gcc kinutils/unpack.c overhead.c -o overhead $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

side: kinutils/unpack.c side.c Makefile
	gcc kinutils/unpack.c side.c -o side $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

front: kinutils/unpack.c front.c Makefile
	gcc kinutils/unpack.c front.c -o front $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

overhead_grid: kinutils/unpack.c overhead_grid.c Makefile
	gcc kinutils/unpack.c overhead_grid.c -o overhead_grid $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

side_grid: kinutils/unpack.c side_grid.c Makefile
	gcc kinutils/unpack.c side_grid.c -o side_grid $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

front_grid: kinutils/unpack.c front_grid.c Makefile
	gcc kinutils/unpack.c front_grid.c -o front_grid $(CFLAGS) -Ikinutils -lm $(EXTRACFLAGS)

clean:
	rm -f unpack overhead side front overhead_grid side_grid front_grid
