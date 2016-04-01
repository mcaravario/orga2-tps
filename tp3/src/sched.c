/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
  definicion de funciones del scheduler
*/

#include "sched.h"
#define IDLE 10
#define INVALIDO 666

/*
 * 	La variable tarea_actual representa la tarea que esta ejecutando, ya sea tarea de usuario, o idle.
 * 	La variable tarea_anterior representa la tarea que se estuvo ejecutando antes de la actual, ya sea
 * una tarea de usuario, o la tarea idle.
 * 	Ambas variables son inicializadas con valores especiales para que la primera vez que se llame al 
 * scheduler no se pise informacion. Dichos valores nunca seran re-asignados despues de la inicializacion.
 * 
 * 	La variable cant_validas representa la cantidad de tareas de usuario que no han sido desalojadas (destruidas),
 * es decir, aquellas tareas que pueden ser ejecutadas por el scheduler.
 * 	El arreglo pos_validas indica, dada una tarea (numeradas de 0 a 7), si esta es valida o no.
 * 	La variable indice_gdt indica cual de los 2 indices de la GDT de TSS utilizados para el cambio de tareas
 * esta siendo usado.
 * 	La variable hayPausa es usada para saber si el juego esta en pausa o no. Se inicializa en 0, y se modifica a 1 cuando se presiona la 'P'.
 * Solo se setea en 0 cuando la 'P' es apretada de vuelta.
 * 	Usamos la variable huboSyscall para saber si se invoca a schedMaster despues de una syscall o no.
 * La variable huboDesalojo la ultilazamos como flag para saber si vengo de desalojar una tarea, con lo cual hay que saltar a la idle.
 */


unsigned int tarea_actual	= 747;
unsigned int tarea_anterior = 88;
int cant_validas = 8;
int pos_validas[8] = {1,1,1,1,1,1,1,1};
int indice_gdt = 1;
unsigned char hayPausa = FALSE;
unsigned char huboSyscall = FALSE;
unsigned char huboDesalojo = FALSE;
info_desalojo_tareas info_desalojo[CANT_TANQUES];

//Devuelve el siguiente indice de la GDT libre(el que no esta siendo usado ahora)
// El primero que esta ocupado (sin contar tarea inicial) es el 15 (donde se inicializa la idle)
int proximo_indice_gdt(){
	
	if (indice_gdt == 1){			// Cambie los RPL a 0 (y los DPL de la GDT a 0)
		return 0x80;				//16 
	} else {
		return 0x78;				//15
	}
}

void desalojar_tarea(enum razon_desalojo_de_tarea razon){
	pos_validas[tarea_actual] = 0;
	cant_validas --;
	imprimir_desalojo(razon);
	matar_clock(tarea_actual);
	huboDesalojo = TRUE;
	info_desalojo[tarea_actual].cr0=(unsigned int)rcr0;
	info_desalojo[tarea_actual].cr2=(unsigned int)rcr2;
	info_desalojo[tarea_actual].cr4=(unsigned int)rcr4;
	info_desalojo[tarea_actual].razon= razon;
	 
	char p = tarea_actual + 1 + '0';

	printg(p,7,60,C_FG_LIGHT_GREY,C_BG_RED);
	}
	
void matar_clock (unsigned int id){
	printg('X',49,(54 + id*2),C_FG_RED,C_BG_LIGHT_GREY);
}

/*
	* Esta funcion actualiza las estructuras del scheduler.
	* Resuelve si tiene que saltar o no a alguna tarea.
	* Si no tiene que saltar a una tarea (de usr o idle), devuelve 0.
	* Si tiene que saltar a una tarea asd(de usr o idle), devuelve el selector. 
 */
unsigned short sched_master(){
	
	// Si hay pausa y no esta corriendo la idle, que corra la idle.
	if (hayPausa && tarea_actual != IDLE) return saltar_idle();
	
	// Si hay pausa y ya esta corriendo la idle, que siga corriendo.
	if (hayPausa) return 0;

	// Si hubo syscall tengo que saltar a la idle.
	if (huboSyscall) {
		huboSyscall = FALSE;
		return saltar_idle();
	}
	
	// Esto significa que vengo de una interrupcion.
	if (huboDesalojo) {
		huboDesalojo = FALSE;
		return saltar_idle();
	}
	
	// En este punto, no hubo desalojo, no hubo syscall y no hay pausa.
	if (cant_validas > 0) return sched_cambio_task();
	
	// cant_validas == 0
	if (tarea_actual == IDLE) return 0;
	

	return 0;
	
}

// Prepara el salto para una tarea de usuario.
unsigned short sched_cambio_task(){
	
	tss* tss_gdt_a_liberar;
	
	unsigned short prox_tarea = sched_proximo_indice();

	// Si solo hay 1 tarea, no salto.
	if (tarea_actual == prox_tarea) return 0;

	unsigned short res = proximo_indice_gdt();
	if (res == 0x80){
		tss_gdt_a_liberar = &tss2;
	} else {
		tss_gdt_a_liberar = &tss1;
	}
	
	// Cuando recien empiezo con las tareas, tarea_anterior vale 88.
	// Con lo cual, no tengo que salvar el contexto de "tarea_anterior".
    if (tarea_anterior == IDLE){
		// Salvo contexto de la idle.
		tss_copy(tss_gdt_a_liberar,&tss_idle);
	} else if (tarea_anterior != 88 ){
		// Salvo contexto de la tarea anterior.
		tss_copy(tss_gdt_a_liberar, &tareas_tss[tarea_anterior]);
	}
	// Cargo el contexto de la tarea a ejecutar.
	tss_copy(&tareas_tss[prox_tarea],tss_gdt_a_liberar);
	
	tarea_anterior	=	tarea_actual;
	tarea_actual	=	prox_tarea;
	
	if (indice_gdt == 1 ){
		indice_gdt	=	2;
	} else {
		indice_gdt	=	1;
	}
	return res;

}

// PRE: Hay una tarea que correr.
unsigned short sched_proximo_indice(){
	
	unsigned short res;
	
	if (tarea_actual == IDLE){
		 res = tarea_anterior + 1;	
	} else{ res = tarea_actual + 1; }
	
	if (res > 7) res = 0;	
	while (pos_validas[res] == 0){
		
		res++;
		if (res > 7) res = 0;
		
	}
	
	return res;
}

//Salva contexto de la tarea anterior,carga contexto idle y actualiza las estructuras
unsigned short saltar_idle(){
	
	
	tss* tss_gdt_a_liberar;
	unsigned short res = proximo_indice_gdt();
	if (res == 0x80){
		tss_gdt_a_liberar = &tss2;
	} else {
		tss_gdt_a_liberar = &tss1;
	}

	tss* tss_a_salvar = (tarea_anterior == IDLE) ? &tss_idle : &tareas_tss[tarea_anterior];
		
	// Salvo el contexto de la tarea anterior
	tss_copy(tss_gdt_a_liberar, tss_a_salvar);
	
	// Cargo el conexto de la idle.
	tss_copy(&tss_idle,tss_gdt_a_liberar);

	
	tarea_anterior	=	tarea_actual;
	tarea_actual	=	IDLE;
	
	if (indice_gdt == 1){
		indice_gdt = 2;
		 
	}else {
		indice_gdt	=	1;
	}
	
	return res;
}

// El ID llega de 1 a 8
void imprimir_regs_desalojo(unsigned int id){
	
	unsigned short fila = 0;
	unsigned short col  = 0;
	
	int i;
	char* imprimir = buffer8B;
	unsigned char letra = C_FG_LIGHT_BROWN;
	unsigned char	formato = C_BG_LIGHT_GREY;
	
	razon_desalojo t;
	t = (razon_desalojo) info_desalojo[id-1].razon;
	imprimir_desalojo(t);
	
	
	
	// Imprimo EAX
	fila = 9;
	col = 56;
	int2s(tareas_tss[id-1].eax);
	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);	
		imprimir++;
		col++;	
	}
	
	// Imprimo EBX
	imprimir = buffer8B;
	fila=11;
	col= 56;
	int2s(tareas_tss[id-1].ebx);
	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo ECX
	imprimir = buffer8B;
	fila=13;
	col=56;
	int2s(tareas_tss[id-1].ecx);
	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo EDX
	imprimir = buffer8B;
	fila= 15;
	col= 56;
	int2s(tareas_tss[id-1].edx);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	

	// Imprimo ESI
	imprimir = buffer8B;
	fila=17;
	col=56;
	int2s(tareas_tss[id-1].esi);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo EDI
	imprimir = buffer8B;
	fila=19;
	col=56;
	int2s(tareas_tss[id-1].edi);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo EBP
	imprimir = buffer8B;
	fila=21;
	col=56;
	int2s(tareas_tss[id-1].ebp);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo CR0
	imprimir = buffer8B;
	fila=9;
	col=71;
	int2s(info_desalojo[id-1].cr0);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	
	// Imprimo CR2
	imprimir = buffer8B;
	fila=11;
	col=71;
	int2s(info_desalojo[id-1].cr2);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo CR3
	imprimir = buffer8B;
	fila=13;
	col=71;
	int2s(info_desalojo[id-1].cr3);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	
	// Imprimo CR4
	imprimir = buffer8B;
	fila=15;
	col=71;
	int2s(info_desalojo[id-1].cr4);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	
	// Imprimo DS
	imprimir = buffer4B;
	fila=29;
	col=56;
	short2s(tareas_tss[id-1].ds);

	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	
	// Imprimo ES
	imprimir = buffer4B;
	fila=31;
	col=56;
	short2s(tareas_tss[id-1].es);

	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	
	// Imprimo FS
	imprimir = buffer4B;
	fila=33;
	col=56;
	short2s(tareas_tss[id-1].fs);

	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	

	
	// Imprimo GS
	imprimir = buffer4B;
	fila=35;
	col=56;
	short2s(tareas_tss[id-1].gs);

	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}

	// Imprimo EIP
	imprimir = buffer8B;
	fila= 25;
	col= 56;
	int2s(tareas_tss[id-1].eip);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);	
		imprimir++;
		col++;
	}
	
	// Imprimo CS
	imprimir = buffer4B;
	fila=27;
	col=56;
	short2s(tareas_tss[id-1].cs);			// Lo trunco a short
	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}	
	
	// Imprimo EFLAGS
	imprimir = buffer8B;
	fila=39;
	col=59;
	int2s(tareas_tss[id-1].eflags);
	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	// Imprimo ESP
	imprimir = buffer8B;
	fila=23;
	col=56;
	int2s(tareas_tss[id-1].esp);

	for (i = 0; i < 8; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
	
	// Imprimo SS
	imprimir = buffer4B;
	fila=37;
	col=56;
	short2s(tareas_tss[id-1].ss);
	for (i = 0; i < 4; i++){
		printg(*imprimir,fila,col,letra,formato);
		imprimir++;
		col++;
	}
		

	// Imprimo PILA
	unsigned int j;
	fila=28;
	col=65;
	unsigned int* p = (unsigned int*) tareas_tss[id-1].esp;
	for (i = 0; i < 5; i++){
		unsigned short col_temp = col;
		imprimir = buffer8B;
		int2s(*p);
		for (j = 0; j < 8; j++){
			printg(*imprimir,fila,col_temp,letra,formato);
			imprimir++;
			col_temp++;
		}
		p++;
		fila++;	
	}
	
}
