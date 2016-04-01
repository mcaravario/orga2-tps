// lista es una lista simplemente enlazada de strings. Expone su estructura
// interna para poder recorrerla y provee metodos basicos para manipularla.
#ifndef _LISTASTRING_H_
#define _LISTASTRING_H_

typedef struct lsnodo_t {
    char *valor;
    struct lsnodo_t *sig;
} __attribute__((packed)) lsnodo;

typedef struct listaP_t {
    lsnodo *prim;
    lsnodo *ult;
} __attribute__((packed)) listaP;

#ifdef __cplusplus 
extern "C" {
#endif

// listaP_crear crea una nueva lista vacia.
listaP *lista_crear();

// lista_agregar agrega una copia de la palabra al final de la lista.
void lista_agregar(listaP *ls, const char *palabra);

// lista_borrar borra la lista.
void lista_borrar(listaP *ls);

// lista_concatenar une las listas xs e ys en xs, poniendo todos los elementos de
// ys al final de xs. Destruye ys.
void lista_concatenar(listaP *xs, listaP *ys);

#ifdef __cplusplus 
}
#endif

#endif // _LISTASTRING_H_

