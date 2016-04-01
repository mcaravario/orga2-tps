/* ** por compatibilidad se omiten tildes **
================================================================================
 TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
================================================================================
*/

#include "game.h"

// OBS: la estructura es tan grande que debo pedir paginas libres. (33KB)
info_pos* campo_juego;

// OBS: Si una syscall requiere el desalojo de la tarea, llama a desalojar tarea.
// OBS: Verificar el uso de x,y   i,j con respecto a las posiciones (fila,columna)
unsigned char pausa = 0;

// Guarda la posicion actual de cada tankrea.
punto pos_tanques[8];

// Guarda la ultima posicion virtual de los tanques.
unsigned int ult_pos_accesible[8];

punto hex2punto(unsigned int dir_fis){
	
	punto res;
	unsigned int offset	=	dir_fis - 0x400000;
	unsigned int res_div	=	offset / (50*4096);
	unsigned int resto		=	offset - (res_div * 50*4096);
	
	
	res.col = resto / 4096;
	res.fila = res_div;
	
	return res;
}

unsigned int punto2hex(punto pos){

	//		 res = base + tam_fila * fila * tam_elem + col * tam_elem
	return	( 0x400000 + pos.fila * (4096*50) + pos.col * (4096));
	
}

void game_inicializar() {

	int i,j;
	
	// Inicializo la memoria para el campo.
	crear_campo();

	
	// Inicializo el campo sin minas y ningun tank.
	for (i = 0;i < CAMPO_SIZE; i++){
		for (j = 0; j < CAMPO_SIZE; j++){
			campo_juego[i*CAMPO_SIZE + j].tank_1 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_2 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_3 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_4 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_5 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_6 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_7 = 0;
			campo_juego[i*CAMPO_SIZE + j].tank_8 = 0;
			campo_juego[i*CAMPO_SIZE + j].mina	 = 0;
			campo_juego[i*CAMPO_SIZE + j].mina_de= 0;
		}
	}


	// Los tanques empiezan en un lugar ya fijado. (en mmu.c)	
	pos_tanques[0] = hex2punto(dir_fis_1+0x1000);
	pos_tanques[1] = hex2punto(dir_fis_2+0x1000);
	pos_tanques[2] = hex2punto(dir_fis_3+0x1000);
	pos_tanques[3] = hex2punto(dir_fis_4+0x1000);
	pos_tanques[4] = hex2punto(dir_fis_5+0x1000);
	pos_tanques[5] = hex2punto(dir_fis_6+0x1000);
	pos_tanques[6] = hex2punto(dir_fis_7+0x1000);
	pos_tanques[7] = hex2punto(dir_fis_8+0x1000);

	// Inicializo la ultima posicion (dir virtual) accesible para la tarea.
	for (i = 0;i < 8;i++){
		ult_pos_accesible[i] = 0x8001FFF;
	 }
	 
	// Imprimo en la pantalla las posiciones iniciales (2) de los tanques.
	// Y marco su lugar en campo_juego
	unsigned char fondo = C_BG_RED;
	unsigned char letra = C_FG_WHITE;
	
	for (i = 0; i < 8;i++){
		printg((unsigned char) (i+49),pos_tanques[i].fila,pos_tanques[i].col,letra,fondo);
		punto temp = pos_tanques[i];
			
		// fila != 0, pues seria una posicion invalida
		if (temp.col == 0){
			temp.col = 49;
			temp.fila--;
		}else{
			temp.col--;
		}
		printg((unsigned char) (i+49),temp.fila,temp.col,letra,fondo);
		
		// Marco las posiciones como pisadas.
		pisar_posicion(pos_tanques[i],i);
		pisar_posicion(temp,i);
	}
}

// DEVOLVER ULT OFFSET VALIDO DE LA VIRTUAL
// Tengo que devolver el offset valido de la ultima pagina mapeada. Si no se mapeo nada, devuelvo la pagina donde "esta parado".
unsigned int game_mover(unsigned int id, direccion d) {

    
    // Calculo el offset que me tengo que mover en el mapa.
    short i,j;
    switch (d){
		case NE:
			i = -1;
			j = 1;
			break;
		case E:
			i = 0;
			j = 1;
			break;
		case SE:
			i = 1;
			j = 1;
			break;
		case N:
			i = -1;
			j = 0;
			break;
		case C:
			i = 0;
			j = 0;
			break;
		case S:
			i = 1;
			j = 0;
			break;
		case NO:
			i = -1;
			j = -1;
			break;
		case O:
			i = 0;
			j = -1;
			break;
		case SO:
			i = 1;
			j = -1;
			break;
		
		default:
			i = 0;
			j = 0;
	}
    
    // Sumo el offset a la posicion del tanque.
    // Si el tanque se pasa de los limites aprezco al principio (mapa circular)
    pos_tanques[id].col		= (pos_tanques[id].col + j + CAMPO_SIZE) % CAMPO_SIZE;
    pos_tanques[id].fila	= (pos_tanques[id].fila + i + CAMPO_SIZE) % CAMPO_SIZE;
    
    // Imprimo el numero de tarea por el lugar donde paso
	// pos_tanques[id].fila vale FFFF
    printg(id+49 , pos_tanques[id].fila,pos_tanques[id].col,C_FG_WHITE,C_BG_LIGHT_GREY);
    
    // Si por esta posicion ya habia pasado un tanque, imprimo por pantalla una X.
    if (yaPasoUnTanque(pos_tanques[id])){
		printg('X',pos_tanques[id].fila,pos_tanques[id].col,0x0,0x40);
    }
    
    // Si el lugar a donde me voy a mover esta minado y la mina no es mia, desalojo/destruyo el tank.
    if ((campo_juego[pos_tanques[id].fila * CAMPO_SIZE + pos_tanques[id].col].mina == 1) && (campo_juego[pos_tanques[id].fila * CAMPO_SIZE + pos_tanques[id].col].mina_de != id)){
		// Limpiar mina
		campo_juego[pos_tanques[id].fila * CAMPO_SIZE + pos_tanques[id].col].mina = 0;
		
		// Actualizo estructuras. Se marca la tarea como no valida.
		desalojar_tarea(MINA);
		
		// Tengo que pintar la pantalla de forma "normal".
		printg(0,pos_tanques[id].fila,pos_tanques[id].col,C_FG_WHITE,C_BG_GREEN);
		
		return FALSE;
    }
    
    // Si no, tengo que evaluar si la pagina destino está mapeada o no en mi directorio.    
	if (ya_pase(id,pos_tanques[id]) == 0){
		unsigned int virtual = dame_virtual_libre(id);
		mmu_mapear_pagina(virtual,tss_get_cr3(id),punto2hex(pos_tanques[id]));
		ult_pos_accesible[id] = virtual + 0xFFF;
		// Actualizo la posicion como "pisada"
		pisar_posicion(pos_tanques[id],id);
		
	}

	// Seteo en TRUE huboSyscall
	huboSyscall = TRUE;
    return ult_pos_accesible[id];
}

void pisar_posicion(punto posicion, unsigned int id){

switch (id){
	case 0:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_1 = 1;
		break;
	case 1:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_2 = 1;
		break;
	case 2:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_3 = 1;
		break;
	case 3:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_4 = 1;
		break;
	case 4:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_5 = 1;
		break;
	case 5:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_6 = 1;
		break;
	case 6:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_7 = 1;
		break;
	case 7:
		campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_8 = 1;
		break;
	default:
		break;
	}	

}

unsigned int ya_pase(unsigned int id, punto posicion){
	switch (id){
	case 0:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_1;
	case 1:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_2;
	case 2:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_3;
	case 3:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_4;
	case 4:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_5;
	case 5:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_6;
	case 6:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_7;
	case 7:
		return (unsigned int)campo_juego[posicion.fila*CAMPO_SIZE + posicion.col].tank_8;
	default:
		return 0;
	}	
}

unsigned char yaPasoUnTanque(punto entrada){
	
	info_pos* pos	=	&campo_juego[entrada.fila * CAMPO_SIZE + entrada.col];
	unsigned char res = 0;
	res = pos->tank_1 || pos->tank_2 || pos->tank_3 || pos->tank_4 || pos->tank_5 || pos->tank_6 || pos->tank_7 || pos->tank_8;
	return res;
	
}

void game_misil(unsigned int id, int val_x, int val_y, unsigned int misil, unsigned int size) {
	

	if ( (val_x <= 50) && (val_x >= -50) && (val_y <= 50) && (val_y >= -50) && (size < 4097) ){
		
		// La suma de CAMPO_SIZE es para evitar problemas con la operacion modulo,
		// por si al sumarle el desplazamiento (que puede ser negativo), se genere
		// un problema de representacion numerica.
		punto temp;
		temp.col	= ((pos_tanques[id].col + val_x) + CAMPO_SIZE) % CAMPO_SIZE;
		temp.fila	= ((pos_tanques[id].fila +val_y) + CAMPO_SIZE) % CAMPO_SIZE;
		
		campo_juego[temp.fila * CAMPO_SIZE + temp.col].mina = 0;
		
		// Copio a la direccion provista, el buffer (misil).
		int* src = (int*) misil;
		int* dst = (int*) punto2hex(temp);
		int i;
		size = size / 4;
		
		for (i = 0; i < size; i++){
			*dst = *src;
			dst++;
			src++;
		}
		
		// Imprimo por pantalla la posicion donde cae el misil.
		printg(176,temp.fila,temp.col,C_FG_LIGHT_BROWN,C_BG_BROWN | C_BLINK);
		
	}
	// Seteo en TRUE huboSyscall
	huboSyscall = TRUE;
}

void game_minar(unsigned int id, direccion d) {
	

	int fila = pos_tanques[id].fila;
	int col = pos_tanques[id].col;
	
	int i = 0;
	int j = 0;
	

	
    // Calculo el offset que me tengo que mover en el mapa.
    switch (d){
		case NE:
			i = -1;
			j = 1;
			break;
		case E:
			i = 0;
			j = 1;
			break;
		case SE:
			i = 1;
			j = 1;
			break;
		case N:
			i = -1;
			j = 0;
			break;
		case C:
			i = 0;
			j = 0;
			break;
		case S:
			i = 1;
			j = 0;
			break;
		case NO:
			i = -1;
			j = -1;
			break;
		case O:
			i = 0;
			j = -1;
			break;
		case SO:
			i = 1;
			j = -1;
			break;
		
		default:
			i = 0;
			j = 0;
	}
    
    fila = (fila + i + CAMPO_SIZE) % CAMPO_SIZE;
	col = (col + j + CAMPO_SIZE) % CAMPO_SIZE;
    
    // Imprimo por pantalla la posicion de la mina.
    printg(15,fila,col,C_FG_LIGHT_BROWN,C_BG_BROWN | C_BLINK);
    
    
    
	campo_juego[fila*CAMPO_SIZE + col].mina		= 1;
	campo_juego[fila*CAMPO_SIZE + col].mina_de	= id;
	
	// Seteo en TRUE huboSyscall
	huboSyscall = TRUE;
}

void int2s(unsigned int valor){
	
	unsigned char digito;
	int i;
	
	for (i = 0; i < 8; i++){
		
		digito = (unsigned char) (valor >> 28);
		valor = valor << 4;
		
		if (digito < 10){
			digito+= 48;
		}else{
			digito+= 55;
		}
		
		buffer8B[i] = digito;
	}
}

void short2s(unsigned short valor){
	
	unsigned char digito;
	int i;
	
	for (i = 0; i < 4; i++){
		
		digito = (unsigned char) (valor >> 12);
		valor = valor << 4;
		
		if (digito < 10){
			digito+= 48;
		}else{
			digito+= 55;
		}
		
		buffer4B[i] = digito;
	}
}

void printg (unsigned char c, unsigned short fila, unsigned short columna , unsigned char formato_letra, unsigned char formato_fondo){
	unsigned short atributos = (formato_fondo) | (formato_letra & 0x0F);
	unsigned short* video;
	video = (unsigned short*)0xB8000 + (fila * 80 + columna);
	*video = c | (atributos << 8);
	
	}

char* razon2s(razon_desalojo razon){
	// Como se definen con "" , los strings son null-terminated, entonces se cuando terminan.
	switch (razon){
		case DIVIDE_ERROR:
			return "DIVIDE_ERROR";
		case RESERVED:
			return "RESERVED";
		case NIMI_INTERRUPT:
			return "NIMI_INTERRUPT";
		case BREAKPOINT:
			return "BREAKPOINT";
		case OVERFLOW:
			return "OVERFLOW";
		case BOUND_RANGED_EXCEEDED:
			return "BOUND_RANGED_EXCEEDED";
		case INVALID_OPCODE:
			return "INVALID_OPCODE";
		case DEVICE_NOT_AVAIBLE:
			return	"DEVICE_NOT_AVAIBLE";
		case DOUBLE_FAULT:
			return "DOUBLE_FAULT";
		case COPROCESSOR_SEG_OVERRUN:
			return "COPROCESSOR_SEG_OVERRUN";
		case INVALID_TSS:
			return "INVALID_TSS";
		case SEG_NOT_PRESENT:
			return "SEG_NOT_PRESENT";
		case STACK_SEG_FAULT:
			return "STACK_SEG_FAULT";
		case GENERAL_PROTECTION:
			return "GENERAL_PROTECTION";
		case PAGE_FAULT:
			return "PAGE_FAULT";
		case MINA:
			return "MINA";
		default:
			return "UNKNOWN";
	}
}

void imprimir_desalojo(razon_desalojo razon){
	unsigned short fila	= 42;
	unsigned short col	= 51;
	int i = 28;
	while (i != 0){
		printg(' ',fila, col, C_FG_LIGHT_BROWN,C_BG_BLACK);
		col++;
		i--;
	}
	char* razonS = razon2s(razon);
	col	= 51;
	while (*razonS != 0){
		printg(*razonS,fila,col,C_FG_LIGHT_BROWN,C_BG_BLACK);
		col++;
		razonS++;
	}

}

// Tengo que pedir 33 paginas para la estructura, (creeria que 32, pero para asegurarse pido 33)
void crear_campo(){

	campo_juego	= (info_pos*) p_nueva;
	p_nueva += (33*0x1000);
}
