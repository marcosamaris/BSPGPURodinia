include ../../common/make.config

#C compiler
CC = gcc

SRC = gaussian.c

CC_FLAGS = -std=gnu99  -g -O3 -w

EXE = gaussian

release:
	$(CC) $(KERNEL_DIM) $(CC_FLAGS) $(SRC) -o $(EXE) 
	
clean: 
	rm -f $(EXE) 
