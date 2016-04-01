/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del manejador de memoria
*/

// para el otro ej es casi lo mismo, pero sin harcodear la dir de las tablas. vamos a tener que pedir por paginas libers

#include "mmu.h"

// Primer pagina libre.
void* p_free = (void*) 0x100000;

//Directorio del Kernel
t_p_desc* dir_kernel = (t_p_desc*) 0x27000;

// Directorios de las Tareas
t_p_desc* dir_tarea_1;
t_p_desc* dir_tarea_2;
t_p_desc* dir_tarea_3;
t_p_desc* dir_tarea_4;
t_p_desc* dir_tarea_5;
t_p_desc* dir_tarea_6; 
t_p_desc* dir_tarea_7;
t_p_desc* dir_tarea_8;


// Direcciones de las tareas en el mapa
unsigned int dir_fis_1	=	0x4F0000;
unsigned int dir_fis_2	=   0xA2B000;
unsigned int dir_fis_3	=	0xC3F000;
unsigned int dir_fis_4	=	0xD10000;
unsigned int dir_fis_5	=	0xAAA000;
unsigned int dir_fis_6	=	0xBB1000;
unsigned int dir_fis_7	=	0x666000;
unsigned int dir_fis_8	=	0x8AB000;

// Arreglo que guarda, para cada tarea,la siguiente direccion virtual libre.
unsigned int virtual_libre[8] = {0x8002000,0x8002000,0x8002000,0x8002000,0x8002000,0x8002000,0x8002000,0x8002000};

// Primer pagina de codigo de tarea(estan consecutivas)
int* p_tarea = (int*) 0x10000;

// Primer Pagina Libre para uso del kernel
unsigned int	p_nueva	= 0x28000;





//------------------ F U N C I O N E S -------------------------------



// Devolvera a partir de la 0x8002000, pues esa sera la primera a mapear en el juego.
unsigned int dame_virtual_libre(int id){
	
	virtual_libre[id] += 0x1000;
	return (virtual_libre[id] - 0x1000);
}

void inicializar_directorios(){
	
	dir_tarea_1 = (t_p_desc*) get_free_page();
	dir_tarea_2 = (t_p_desc*) get_free_page();
	dir_tarea_3 = (t_p_desc*) get_free_page();
	dir_tarea_4 = (t_p_desc*) get_free_page();
	dir_tarea_5 = (t_p_desc*) get_free_page();
	dir_tarea_6 = (t_p_desc*) get_free_page();
	dir_tarea_7 = (t_p_desc*) get_free_page();
	dir_tarea_8 = (t_p_desc*) get_free_page();
	
}

void mmu_inicializar_dir_kernel(){
	
	map_identity(dir_kernel);
	
	}

void* get_free_page(){

	if (p_free > (void*) 0x3FFFFF){
		return 0;
	}
	
	p_free += 0x1000;
	return (p_free - 0x1000);
}
unsigned int get_kernel_page(){
	
	// Si llegue a la memoria de video, no tengo mas paginas libres.
	// (Esto no deberia pasar, pues tengo 121 paginas libres en la memoria del kernel para crear tablas)
	if (p_nueva == 0xA0000) return 0;
	
	// Avanzo a la siguiente pagina.
	p_nueva += 0x1000;
	
	// Devuelvo la pagina libre.
	return (p_nueva - 0x1000);
}

spl_desc* get_new_table(){
	
	return (spl_desc*) get_kernel_page();
}

void map_new_table(t_p_desc* dir_entry){
	
	spl_desc* new_table	= (spl_desc*) get_free_page();
	
	dir_entry->present	=	1;
	dir_entry->dir		=	( (unsigned int) new_table ) >> 12;
	dir_entry->u_s		=	1;
	dir_entry->r_w		=	1;
	dir_entry->pwt		=	0;
	dir_entry->pcd		=	0;
	dir_entry->a		=	0;
	dir_entry->ign		=	0;
	dir_entry->ps		=	0;
	dir_entry->ignored	=	0;
	
	// Seteo en 0 el bit presente de las entradas de la nueva tabla.
	int i;
	for (i = 0; i < 1024; i++){
		new_table[i].present = 0;
	}
}

void mmu_inicializar(){
	
	// Inicializo el directotorio kernel.
	mmu_inicializar_dir_kernel();
	
	// Asigno paginas libres para los directorios de las tareas.
	inicializar_directorios();
	
	// Inicializo los directorios de las tareas.
	int i;
	for (i = 0; i < 8; i++){
		mmu_inicializar_dir_tarea(i);
	}
}

/* 	Esta funcion hace 3 cosas, dada una tarea:
 * 		1.- Identity Mapping sobre el kernel.
 * 		2.- Copia el codigo.
 * 		3.- Mapea el codigo desde la posicion
*/
void mmu_inicializar_dir_tarea(int num_tarea){

	unsigned int dir_fis;
	t_p_desc* dir_tarea;
	switch (num_tarea + 1){
		
		case 1:
			dir_tarea = dir_tarea_1;
			dir_fis	= dir_fis_1;
			break;
		case 2:
			dir_tarea = dir_tarea_2;
			dir_fis	= dir_fis_2;
			break;
		case 3:
			dir_tarea = dir_tarea_3;
			dir_fis	= dir_fis_3;
			break;
		case 4:
			dir_tarea = dir_tarea_4;
			dir_fis	= dir_fis_4;
			break;
		case 5:
			dir_tarea = dir_tarea_5;
			dir_fis	= dir_fis_5;
			break;
		case 6:
			dir_tarea = dir_tarea_6;
			dir_fis	= dir_fis_6;
			break;
		case 7:
			dir_tarea = dir_tarea_7;
			dir_fis	= dir_fis_7;
			break;
		case 8:
			dir_tarea = dir_tarea_8;
			dir_fis	= dir_fis_8;
			break;
	
		default:
			dir_tarea = 0;
	
	}
	
	
	// Identity Mapping
	map_identity(dir_tarea);


	// Copiar Codigo
	// Copio de a 4 B
	int i;
	int fin_iteraciones		= 2048;
	int* dst	=	(int*) dir_fis;
	// Copio las dos paginas de la tarea.
	for (i = 0; i < fin_iteraciones; i++){
		*dst = *p_tarea;
		dst++;
		p_tarea++;
	}
	// MAPEO CODIGO
	// Se mapean consecutivamente.
	int dir_virt	=	0x8000000;
	unsigned int physical	=	dir_fis;
	for (i = 0; i < 2; i++){
		mmu_mapear_pagina(dir_virt,(unsigned int)dir_tarea,physical);
		dir_virt += 0x1000;
		physical += 0x1000;
	}


}

// Mapea con priviligios de USUARIO
void mmu_mapear_pagina(unsigned int virtual,unsigned int cr3,unsigned int fisica){
	
	t_p_desc* prt_dir 					= (t_p_desc*) (cr3 & 0xFFFFF000);
	int dir_i 							=  virtual >> 22;
	int table_i 						= virtual >> 12;
	table_i								= table_i & 0x00000FFF;
	unsigned int base_fisica			= fisica >> 12;
	
	prt_dir += dir_i;
	
	// Chequeo si la posicion del directorio es valida.
	// Si no lo es, creo la tabla y la relaciono con el directorio.
	
	if (prt_dir->present == 0) map_new_table(prt_dir);
	
	unsigned int pde = prt_dir->dir;
	pde = pde << 12;
	pde += (table_i*4);
	
	
	((spl_desc*)pde)->page_frame 	= base_fisica;
	((spl_desc*)pde)->present		= 1;
	((spl_desc*)pde)->u_s			= 1;		
	((spl_desc*)pde)->r_w			= 1;
	((spl_desc*)pde)->pwt			= 0;
	((spl_desc*)pde)->pcd			= 0;
	((spl_desc*)pde)->a				= 0;		
	((spl_desc*)pde)->d				= 0;
	((spl_desc*)pde)->pat			= 0;
	((spl_desc*)pde)->g				= 0;
	((spl_desc*)pde)->ignored		= 0;	
	tlbflush();
}

void mmu_unmapear_pagina(unsigned int virtual, unsigned int cr3){
	
	t_p_desc* prt_dir 					= (t_p_desc*) (cr3 & 0xFFC00000);
	int dir_i 							=  virtual >> 22;
	int table_i 						=  virtual >> 12;
	table_i								= table_i & 0x00000FFF;
	
	prt_dir += dir_i;
	unsigned int pde = prt_dir->dir;
	pde = pde << 12;
	pde += (table_i*4);
	
	
	((spl_desc*)pde)->present 	= 0;
	
	tlbflush();
}

void mmu_inicializar_dir_usuario(int num_tarea){
	
	t_p_desc* dir_tarea;
	
	switch (num_tarea + 1){
		
		case 1:
			dir_tarea = dir_tarea_1;
			break;
		case 2:
			dir_tarea = dir_tarea_2;
			break;
		case 3:
			dir_tarea = dir_tarea_3;
			break;
		case 4:
			dir_tarea = dir_tarea_4;
			break;
		case 5:
			dir_tarea = dir_tarea_5;
			break;
		case 6:
			dir_tarea = dir_tarea_6;
			break;
		case 7:
			dir_tarea = dir_tarea_7;
			break;
		case 8:
			dir_tarea = dir_tarea_8;
			break;
	
		default:
			dir_tarea = 0;
	
	}
	
	tareas_tss[num_tarea].cr3 = (unsigned int) dir_tarea;

	
}

void map_identity(t_p_desc* dir_tarea){

	// Creo las cuatro tablas de segundo nivel.
	spl_desc* tablita_2do_nivel_0 = (spl_desc*) get_free_page();
	spl_desc* tablita_2do_nivel_1 = (spl_desc*) get_free_page();
	spl_desc* tablita_2do_nivel_2 = (spl_desc*) get_free_page();
	spl_desc* tablita_2do_nivel_3 = (spl_desc*) get_free_page();

	
	int j;
	for (j = 0; j < 4; j++){
		dir_tarea[j].present	=	0x1;
		dir_tarea[j].r_w 		=	0x1;
		dir_tarea[j].u_s		=	0x1;
		dir_tarea[j].pwt		=	0x0;
		dir_tarea[j].pcd		=	0x0;
		dir_tarea[j].a			=	0x0;
		dir_tarea[j].ign		=	0x0;
		dir_tarea[j].ps			=	0x0;
		dir_tarea[j].ignored	=	0x0;
	}
	
			
	dir_tarea[0].dir		=	((unsigned int) tablita_2do_nivel_0)  >> 12;	
	dir_tarea[1].dir		=	((unsigned int) tablita_2do_nivel_1)  >> 12;	
	dir_tarea[2].dir		=	((unsigned int) tablita_2do_nivel_2)  >> 12;	
	dir_tarea[3].dir		=	((unsigned int) tablita_2do_nivel_3)  >> 12;
	
	int i;
	for (i = 4; i < 1024; i++){
		dir_tarea[i].present	=	0x0;
	}
	

	int destino = 0;
	for (i = 0; i < 1024; i++){
			
		tablita_2do_nivel_0[i].present		= 1;
		tablita_2do_nivel_0[i].r_w			= 1;
		tablita_2do_nivel_0[i].u_s			= 0;
		tablita_2do_nivel_0[i].pwt			= 0;
		tablita_2do_nivel_0[i].pcd			= 0;
		tablita_2do_nivel_0[i].a			= 0;
		tablita_2do_nivel_0[i].d			= 0;
		tablita_2do_nivel_0[i].pat			= 0;
		tablita_2do_nivel_0[i].g			= 0;
		tablita_2do_nivel_0[i].ignored		= 0;
		tablita_2do_nivel_0[i].page_frame	= destino;
		
		destino += 1;
	
	}

	for (i = 0; i < 1024; i++){
		
		
		tablita_2do_nivel_1[i].present		= 1;
		tablita_2do_nivel_1[i].r_w			= 1;
		tablita_2do_nivel_1[i].u_s			= 0;
		tablita_2do_nivel_1[i].pwt			= 0;
		tablita_2do_nivel_1[i].pcd			= 0;
		tablita_2do_nivel_1[i].a			= 0;
		tablita_2do_nivel_1[i].d			= 0;
		tablita_2do_nivel_1[i].pat			= 0;
		tablita_2do_nivel_1[i].g			= 0;
		tablita_2do_nivel_1[i].ignored		= 0;
		tablita_2do_nivel_1[i].page_frame	= destino;
		
		destino += 1;

}

	for (i = 0; i < 1024; i++){
		
		
		tablita_2do_nivel_2[i].present		= 1;
		tablita_2do_nivel_2[i].r_w			= 1;
		tablita_2do_nivel_2[i].u_s			= 0;
		tablita_2do_nivel_2[i].pwt			= 0;
		tablita_2do_nivel_2[i].pcd			= 0;
		tablita_2do_nivel_2[i].a			= 0;
		tablita_2do_nivel_2[i].d			= 0;
		tablita_2do_nivel_2[i].pat			= 0;
		tablita_2do_nivel_2[i].g			= 0;
		tablita_2do_nivel_2[i].ignored		= 0;
		tablita_2do_nivel_2[i].page_frame	= destino;
		
		destino += 1;

}

	for (i = 0; i < 452; i++){
		
		
		tablita_2do_nivel_3[i].present		= 1;
		tablita_2do_nivel_3[i].r_w			= 1;
		tablita_2do_nivel_3[i].u_s			= 0;
		tablita_2do_nivel_3[i].pwt			= 0;
		tablita_2do_nivel_3[i].pcd			= 0;
		tablita_2do_nivel_3[i].a			= 0;
		tablita_2do_nivel_3[i].d			= 0;
		tablita_2do_nivel_3[i].pat			= 0;
		tablita_2do_nivel_3[i].g			= 0;
		tablita_2do_nivel_3[i].ignored		= 0;
		tablita_2do_nivel_3[i].page_frame	= destino;
		
		destino += 1;

}

	// Marco como no presente las demas entradas.
	for (i = 452; i < 1024; i++){
		tablita_2do_nivel_3[i].present = 0;
	}
	
}

