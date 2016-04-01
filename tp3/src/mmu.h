/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

#ifndef __MMU_H__
#define __MMU_H__

#include "defines.h"
#include "i386.h"
#include "tss.h"
#include "game.h"



typedef struct table_page_descriptor {
    unsigned char   present:1;
    unsigned char   r_w:1;
    unsigned char   u_s:1;
    unsigned char   pwt:1;
    unsigned char   pcd:1;
    unsigned char   a:1;
    unsigned char   ign:1;
    unsigned char   ps:1;
    unsigned char   ignored:4;
    unsigned int	  dir:20;
} __attribute__((__packed__, aligned (4))) t_p_desc;

typedef struct second_page_level_descriptor {
    unsigned char   present:1;
    unsigned char   r_w:1;
    unsigned char   u_s:1;
    unsigned char   pwt:1;
    unsigned char   pcd:1;
    unsigned char   a:1;
    unsigned char   d:1;
    unsigned char   pat:1;
    unsigned char   g:1;
    unsigned char   ignored:3;
    unsigned int    page_frame:20;
} __attribute__((__packed__, aligned (4))) spl_desc;

unsigned int dame_virtual_libre(int i);
void mmu_inicializar_dir_kernel();
void mmu_inicializar();
void mmu_inicializar_dir_tarea(int i);
void mmu_inicializar_dir_usuario(int i);
void mmu_unmapear_pagina(unsigned int virtual, unsigned int cr3);
void mmu_mapear_pagina(unsigned int virtual,unsigned int cr3,unsigned int fisica);


// Exporto la variable que me indica la proxima pagina libre del kernel.
extern unsigned int p_nueva;

// Pide paginas libres para los directorios de las tareas.
void inicializar_directorios();

// Devuelve la primer posicion libre de memoria (tamaño 4K), del sector "Area Libre" (0x100000 - 0x3FFFFF)
void* get_free_page();

// Devulve la primer posicion de memoria libre (tamaño 4K), empezando de 0x28000, hasta 0xA0000 (no inclusive).
spl_desc* get_new_table();

// Crea una tabla de segundo nivel y la relaciona con la entrada del directorio pasado como parametro.
void map_new_table(t_p_desc* dir_entry);

// Hace identity mapping del kernel sobre el directorio dado.
void map_identity(t_p_desc* directorio);

// Devuelve una pagina libre del kernel.
unsigned int get_kernel_page();

extern t_p_desc* dir_tarea_1;
extern t_p_desc* dir_tarea_2;
extern t_p_desc* dir_tarea_3;
extern t_p_desc* dir_tarea_4;
extern t_p_desc* dir_tarea_5;
extern t_p_desc* dir_tarea_6; 
extern t_p_desc* dir_tarea_7;
extern t_p_desc* dir_tarea_8;

// Si no se requiere en otro archivo, borrar
extern unsigned int dir_fis_1;
extern unsigned int dir_fis_2;
extern unsigned int dir_fis_3;
extern unsigned int dir_fis_4;
extern unsigned int dir_fis_5;
extern unsigned int dir_fis_6; 
extern unsigned int dir_fis_7;
extern unsigned int dir_fis_8;

#endif	/* !__MMU_H__ */




