/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de estructuras para administrar tareas
*/

#include "tss.h"


tss tss1;
tss tss2;

tss tss_inicial;
tss tss_idle;
tss tareas_tss[CANT_TANQUES];


void tss_inicializar() {
	
	int y;
	for (y = 0; y < 8; y++){
		info_desalojo[y].cr0=0;
		info_desalojo[y].cr2=0;
		info_desalojo[y].cr4=0;
		info_desalojo[y].razon=UNKNOWN;		
	}
	
	
	// CAMBIAR LOS ESP0 Y CR3 DE LOS TSS1 Y TSS2, NO PUEDEN TENER EL DEL KERNEL
	
	// INICIALIZAR DE MANERA GOBAL LOS CR3 DE LAS TAREAS Y USARLAS ACA PARA CARGAR CORRECTAMENTE LOS CR3 Y LA ESP0

	
	
	//-------------------------------- Idle -----------------------------
	// Selectores de segmentos. 
	tss_idle.cs =	0x48;
	tss_idle.es =	0x58;
	tss_idle.ds	=	0x58;
	tss_idle.gs	=	0x58;
	tss_idle.fs	=	0x58;
	tss_idle.ss	=	0x58;
	tss_idle.fs	=	0x58;
	
	tss_idle.cr3 = rcr3();
	
	// Registros en 0.
	tss_idle.edi	=	0;
	tss_idle.esi	=	0;
	tss_idle.ebx	= 	0;
	tss_idle.edx	= 	0;
	tss_idle.ecx	= 	0;
	tss_idle.eax	= 	0;
	
	// Stack nivel 3
	// En teoria, la idle nunca necesitaria datos lvl 3.
	tss_idle.ebp	= 	0x27000; 	// Es la dir de la pila del kernel
	tss_idle.esp	= 	0x27000;
	tss_idle.eip	=	0x20000;
	
	// Stack nivel 0
	tss_idle.esp0	=	0x27000;
	tss_idle.ss0 	=	0x58;			//asigno el segmento de pila de nivel 0 a los datos de nivel 0. 
	
	tss_idle.iomap = 0xFFFF;
		
	// FLAGS
	tss_idle.eflags	=	0x202;
	
	//----------------------------- FIN  Idle ------------------------------

	tss1 = tss_idle;
	tss_inicial = tss_idle;


	//---------------------------- Inicializo tss de las 8 tareas
	int i;
	unsigned int code_ini	=	0x8000000;
	
	// Debugeando valor tss de los tanques. El valor se inicializa correctamente.
	for (i = 0; i < 8; i++){
		// Selectores de segmentos.
		tareas_tss[i].cs 	=	0x53;
		tareas_tss[i].ds	=	0x63;
		tareas_tss[i].es 	=	0x63;
		tareas_tss[i].fs	=	0x63;
		tareas_tss[i].gs	=	0x63;
		tareas_tss[i].ss	=	0x63;
		
		tareas_tss[i].iomap = 0xFFFF;
		
		// Registros en 0.
		tareas_tss[i].edi	=	0;
		tareas_tss[i].esi	=	0;
		tareas_tss[i].ebx	= 	0;
		tareas_tss[i].edx	= 	0;
		tareas_tss[i].ecx	= 	0;
		tareas_tss[i].eax	= 	0;
		
		// Stack nivel 3
		tareas_tss[i].ebp	= 	code_ini + 0x2000;
		tareas_tss[i].esp	= 	code_ini + 0x2000;
		tareas_tss[i].eip	=	code_ini;
					
		// FLAGS
		tareas_tss[i].eflags	=	0x202;
	
		// No la mapeo, pues ya esta mapeada con identity mapping.
		tareas_tss[i].esp0 = (unsigned int) get_free_page() + 0x1000;
		tareas_tss[i].ss0	= 0x58;
		
	}

}

void tss_inicializar_bases_en_gdt(){
	
	gdt[14].base_0_15		=	(unsigned int) &tss_inicial;
	gdt[14].base_23_16		=	((unsigned int) &tss_inicial) >> 16;
	gdt[14].base_31_24		=	((unsigned int) &tss_inicial) >> 24;	

	
	gdt[15].base_0_15		=	(unsigned int) &tss1;
	gdt[15].base_23_16		=	((unsigned int) &tss1) >> 16;
	gdt[15].base_31_24		=	((unsigned int) &tss1) >> 24;	

	gdt[16].base_0_15		=	(unsigned int) &tss2;
	gdt[16].base_23_16		=	((unsigned int) &tss2) >> 16;
	gdt[16].base_31_24		=	((unsigned int) &tss2) >> 24;	
}

void tss_inicializar_cr3_tareas(){
	
	int i;
	for (i = 0; i < 8; i++){
		mmu_inicializar_dir_usuario(i);
	}
}


void tss_copy(tss* tss_src, tss* tss_dst){
	*tss_dst = *tss_src;
}


unsigned int tss_get_cr3(unsigned int id){

	return tareas_tss[id].cr3;
	
}

