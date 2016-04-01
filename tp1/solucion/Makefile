CC=c99
CXX=g++
CFLAGS=-Wall -Wextra -pedantic -O0 -ggdb
CXXFLAGS=-Wall -Werror -pedantic -ggdb -O0 -Wno-long-long -Wno-variadic-macros -I.
OBJS=listaP.o trie_c.o trie_asm.o
TESTOBJS=test-o-matic.o
NASM=nasm
NASMFLAGS=-f elf64 -g -F DWARF

# main solo depende de $(OBJS), se va a terminar compilando usando $(CC) $(CFLAGS) main.c $(OBJS) -o main
main: $(OBJS)

tester: $(TESTOBJS) $(OBJS)

# los archivos .o pueden depender del correspondiente archivo .asm (si existe).
# Se van a compilar como $(NASM) $(NASMFLAGS) deps -o output
# Hay una regla implícita que matchea los .o con los %.c correspondientes y los compila de forma similar.
%.o: %.asm
	$(NASM) $(NASMFLAGS) $< -o $@

all: tester main

clean:
	rm -f *.o
	rm -f main tester
