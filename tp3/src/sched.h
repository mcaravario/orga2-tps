/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#ifndef __SCHED_H__
#define __SCHED_H__
#define INVALIDO 666


typedef enum razon_desalojo_de_tarea razon_desalojo;

#include "screen.h"
#include "tss.h"
#include "game.h"


enum razon_desalojo_de_tarea {
	DIVIDE_ERROR, RESERVED, 
	NIMI_INTERRUPT, BREAKPOINT, OVERFLOW,
	BOUND_RANGED_EXCEEDED, INVALID_OPCODE,
	DEVICE_NOT_AVAIBLE, DOUBLE_FAULT,
	COPROCESSOR_SEG_OVERRUN, INVALID_TSS,
	SEG_NOT_PRESENT, STACK_SEG_FAULT,
	GENERAL_PROTECTION, PAGE_FAULT,
	MINA, UNKNOWN   
};

// Tamañao: 72 Bytes
// Observacion para el corrector: Esta es la estructura que ibamos a usar para mostrar la informacion de desalojo.
typedef struct informacion_auxiliar_desalojo {
    unsigned int    eip;			// 0
    unsigned int    eflags;		// 4
    unsigned int    eax;			// 8
    unsigned int    ecx;			// 12 
    unsigned int    edx;			// 16
    unsigned int    ebx;			// 20
    unsigned int    esp;			// 24
    unsigned int    ebp;			// 28
    unsigned int    esi;			// 32
    unsigned int    edi;			// 36
    unsigned short  es;			// 40
    unsigned short  cs;			// 42
    unsigned short  ss;			// 44
    unsigned short  ds;			// 46
    unsigned short  fs;			// 48
    unsigned short  gs;			// 50
	unsigned int	  cr0;			// 52
	unsigned int    cr2;			// 56
	unsigned int    cr3;			// 60
	unsigned int    cr4;			// 64
	unsigned int    razon; 		// 68		//puse unsigned int y no razon desalojo por problemas al compilar (includes anidados)
} __attribute__((__packed__, aligned (4))) info_desalojo_tareas;


// Necesito modificar hayPausa desde el handler del teclado y chequear el valor de tarea_actual.
// Modifo huboSyscall desde game.c (desde las syscalls).
extern unsigned char hayPausa;
extern unsigned int tarea_actual;
extern unsigned char huboSyscall;
extern int cant_validas;
extern info_desalojo_tareas info_desalojo[];


unsigned short sched_master();
unsigned short sched_proximo_indice();
unsigned short saltar_idle();
unsigned short sched_cambio_task();
int proximo_indice_gdt();
void desalojar_tarea(enum razon_desalojo_de_tarea razon);
void matar_clock(unsigned int id);
void imprimir_regs_desalojo(unsigned int id);

#endif	/* !__SCHED_H__ */
