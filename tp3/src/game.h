/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#ifndef __GAME_H__
#define __GAME_H__

#include "defines.h"
#include "screen.h"
#include "mmu.h"
#include "sched.h"
#include "colors.h"

#define CAMPO_SIZE 50

// Describe las posiciones en el mapa.
typedef struct posicion_en_mapa {
	short fila;
	short col;
	} punto;


// Describe la informacion del campo, es deciir, si esta minado o no, y si cada tanque paso por la posicion.
typedef struct info_mapa_posicion{
	unsigned char tank_1;
	unsigned char tank_2;
	unsigned char tank_3;
	unsigned char tank_4;
	unsigned char tank_5;
	unsigned char tank_6;
	unsigned char	tank_7;
	unsigned char	tank_8;
	unsigned char	mina;
	int				mina_de;	// Especifica a quien corresponde la mina.
	} info_pos;
	

typedef enum direccion_e { NE = 12, N  = 11, NO = 14,
                           E  = 22, C  = 0,  O  = 44,
                           SE = 32, S  = 33, SO = 34 } direccion;


// Convierte unsigned int a string(hexa) y lo deja en un buffer.
void int2s(unsigned int valor);

// Convierte unsigned short a string(hexa) y lo deja en un buffer.
void short2s(unsigned short valor);

// Buffer de 8 bytes.
char buffer8B[8];

// Buffer de 4 bytes.
char buffer4B[4];

// En estos buffers escribo para imprimir informacion de los registros desde ASM.
// Las hago extern para usarlas desde kernel.asm
extern char buffer4B[];
extern char buffer8B[];
extern unsigned char pausa;

// Dada una direccion de "El mapa", la traduce en un punto.
punto hex2punto(unsigned int dir);

// Dado un punto del mapa, devuelve la direccion fisica correspondiente
unsigned int punto2hex(punto posicion);

void imprimir_stack(unsigned int* pila);

// Marca como TRUE la posicion pasada como parametro, del tanque pasado como parametro
void pisar_posicion(punto pos, unsigned int id);

// Devuelve 1 se el tanque (id) paso por el punto descripto por "posicion".
unsigned int ya_pase(unsigned int id, punto posicion);

// Dada una posicion devuelve 1 si algun tanque paso por alli.
unsigned char yaPasoUnTanque(punto entrada);

// Dada una direccion virtual, devuelve 1 si dicha direccion está mapeada dentro de "el mapa".
unsigned int esDirValida(unsigned int id,unsigned int virtual);

// Inicializa las estructuras necesarias para el juego.
void game_inicializar();

// Syscall mover, devuelve 0 si el tanque es desalojado.
unsigned int game_mover(unsigned int id, direccion d);

// Syscall misil.
void game_misil(unsigned int id, int val_x, int val_y, unsigned int misil, unsigned int size);

// Syscall minar.
void game_minar(unsigned int id, direccion d);

// No lo ponemos en screen.c porque, por algun motivo, no reconocia el tipo "punto" (y si, estaba el include)
// Imprime por pantalla el char c en la posicion correspondiente.
void printg (unsigned char c, unsigned short fila, unsigned short columna , unsigned char formato_letra, unsigned char formato_fondo);

void imprimir_desalojo(razon_desalojo razon);

char* razon2s(razon_desalojo razon);

// Crea la estructura.
void crear_campo();

#endif  /* !__GAME_H__ */
