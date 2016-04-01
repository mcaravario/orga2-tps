#include <stdio.h>
#include "trie.h"
extern char* caracteres_de_tecla(char c);
double trie_pesar(trie *t, double (*funcion_pesaje)(char*));
int main(void) {
	
	
	//TEST 1)
	trie* t = trie_crear();
	trie_imprimir(t , "trieVacio");
	trie_borrar(t);
	
	
	// Test 2)
	
	trie* r = trie_crear();
	trie_agregar_palabra(r, "cazador");
	trie_imprimir(r, "trie2");
	trie_borrar(r);
	
	
	// Test 3)
	
	trie* j = trie_crear();
	trie_agregar_palabra(j, "casa");
	trie_agregar_palabra(j, "casco");
	trie_agregar_palabra(j, "ala");
	trie_agregar_palabra(j, "cama");
	trie_imprimir(j, "trie3");

	
	trie_borrar(j);
	
	
	
	
	//char* prefijo = "caz";
		 
	//nodo* res = nodo_prefijo(n,prefijo);
	 
	
	
	  char* a = "ave";
	  char* b = "hola";
	  char* c = "ho";
	  char* d = "ala";
	  char* e = "caza";	
	  char* f = "cazador";
	  char* g = "come";	
	  char* i = "comida";
	  char* k = "cazon";
	  	  
	  char *tecla = caracteres_de_tecla('5');
	 
	 trie* h = trie_crear();
	 trie_agregar_palabra(h, b);
	 trie_agregar_palabra(h, a);
	 trie_agregar_palabra(h, c);
	 trie_agregar_palabra(h, d);
	 trie_agregar_palabra(h, e);
	 trie_agregar_palabra(h, f);
	 trie_agregar_palabra(h, g);
	 trie_agregar_palabra(h, i);
	 trie_agregar_palabra(h, k);
	 
	 trie_borrar(h);
	 
	 trie* pepe = trie_crear();
	 
	 listaP *prefijosss = palabras_con_prefijo(pepe,"com");
	 
	 lista_borrar(prefijosss);
	 
	 trie_borrar(pepe);
	 
	 listaP *prefijos = palabras_con_prefijo(h,"com");
	
	 listaP *pre = predecir_palabras(h,"87");
	 
	  lista_borrar(prefijos);
	  
	  lista_borrar(pre);
	 
	 
	 //~ 
	 //~ listaP* ls = palabras_con_prefijo(h,"");
	 //~ lsnodo *n;
	 //~ n = ls->prim;
	 //~ while (n != NULL) {
		 //~ printf(n->valor);
		 //~ n= n->sig;
	 //~ }
	 //~ lista_borrar(ls);
//~ 
	 //~ trie_imprimir(h,"trie.txt");
 //~ 
	 //~ trie_borrar(h);
	 //~ 
	 //~ trie* m = trie_construir("construir");
 //~ 
	 //~ trie_borrar(m);
	 //~ 
	 
	 
	 printf("\n\npeso A = %s y espero PROMEDIO = %f\n\n", a, peso_palabra(a));
	 printf("\n\npeso C = %s y espero PROMEDIO = %f\n\n", c, peso_palabra(c));

	  //char* c = "ho";
	 
	 trie* esa = trie_crear();
	 trie_agregar_palabra(esa, a);
	 trie_agregar_palabra(esa, c);
	 double PROM = trie_pesar(esa,  (*peso_palabra));
	 printf("\n\npeso ESA = %s y %s y espero PROMEDIO = %f\n\n", a, c, PROM);
	 
	 trie_borrar(esa);
	 //double (*peso_palabra)(char*)
	 
    return 0;
}

