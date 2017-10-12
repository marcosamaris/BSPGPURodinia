include ../../common/make.config

#C compiler
CC = gcc

SRC = gaussian.c

CC_FLAGS = -std=c99  -g -O3

EXE = gaussian

release:
	$(CC) $(KERNEL_DIM) $(CC_FLAGS) $(SRC) -o $(EXE) 
	
clean: 
	rm -f $(EXE) 
