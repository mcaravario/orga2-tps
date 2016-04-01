#include "trie.h"
#include "listaP.h"
#include <stdio.h>
#include <stdlib.h> 


// Completar las funciones en C.




    
    void combinaciones_posibles(char* t, char* buffer, listaP* lista, trie* h, const char* buffer_original){
	 
	 
	 if(*t == 0){																	//caso base, en el que llegue a un cero y debo agregar a la lista el resultado.
		 
		 *buffer=0;
		
		
	
		 lista_concatenar(lista, palabras_con_prefijo(h, buffer_original));
		 return;
		 }
	 
	 
	 char* caracter = caracteres_de_tecla(*t);
	 
	 while(*caracter != 0){
		 
		 *buffer = *caracter;
		 
		 t++;
		 buffer++;
		 
		 combinaciones_posibles(t,buffer,lista,h,buffer_original);
		 
		 t--;
		 buffer--;
		
		 caracter++;
		 
		 }
		 
	 return;
		 
	 
	}
    
    
    
    



 listaP *predecir_palabras(trie *t, char *teclas) {
	 
	 listaP *res = lista_crear();
	 char buffer[1024];
	 char const *buffer_original = buffer;
	 
	 combinaciones_posibles(teclas,buffer,res,t,buffer_original);
	 
	 return res;
	 
	 
 }
 


double peso_palabra(char *palabra) {
	
	double peso = 0;
	double longitud = 0;
	
	while(*palabra != '\0'){													
						
		peso = peso + (double)*palabra;
		longitud++;
		palabra++;
		
	}
	
	return peso/longitud;
}

