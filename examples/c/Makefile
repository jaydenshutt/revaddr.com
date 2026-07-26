CC ?= gcc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra
LDFLAGS ?= -lcurl

.PHONY: all clean

all: reverse

reverse: reverse.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f reverse
