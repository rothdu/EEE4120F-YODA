#Generic Makefile
#Si Teng Wu
#Assignment Name

CC=g++#Compiler
CCFLAGS=-std=c++20
SRC=main.cpp #Source Files
OBJ=main.o #Object Files

encryption.o: 
	$(CC) $(CCFLAGS) encryption.cpp -o encryption -lOpenCL

adv:
	$(CC) $(CCFLAGS) encryption.cpp -D ADVANCED -o encryptionADV -lOpenCL 

clean:
	rm -f *.o *.exe encryption

run:
	./encryption

runadv:
	./encryptionADV
