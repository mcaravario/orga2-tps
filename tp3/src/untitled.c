
/*
	* Esta funcion actualiza las estructuras del scheduler.
	* Resuelve si tiene que saltar o no a alguna tarea.
	* Si no tiene que saltar a una tarea (de usr o idle), devuelve 0.
	* Si tiene que saltar a una tarea (de usr o idle), devuelve el selector. 
 */
unsigned short sched_master(){
	
	// Si hay pausa y no esta corriendo la idle, que corra la idle.
	if (hayPausa && tarea_actual != IDLE) return saltar_idle();
	
	// Si hay pausa y ya esta corriendo la idle, que siga corriendo.
	if (hayPausa) return 0;

	if (cant_validas > 0) return sched_cambio_task();
	
	// cant_validas == 0
	if (tarea_actual == IDLE) return 0;
	
	// 	Si llegue hasta aca, significa que estoy llamando a esta funcion
	// desde una interrupcion que desalojo la ultima tarea valida
	return saltar_idle();
	
}

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
	
	unsigned short res
	
	if (tarea_actual == IDLE){
		 res = tarea_anterior + 1;	
	} else{ res = tarea_actual + 1; }
	
	if (res > 7) res = 0;	
	while (pos_validas[res] == 0){
		
		if (res > 7) res = 0;
		res++;
		
	}
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

	// Salvo el contexto de la tarea anterior
	tss_copy(tss_gdt_a_liberar, &tareas_tss[tarea_anterior]);
	
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
