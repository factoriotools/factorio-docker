# Optimization
OPT = -O3 -flto
TARGET = rcon

CC = gcc
CFLAGS = -std=c17 -Wall -Wextra -pedantic $(OPT)
REMOVE = rm -f

all:
	$(CC) $(CFLAGS) main.c -o $(TARGET)

clean:
	$(REMOVE) $(TARGET)
