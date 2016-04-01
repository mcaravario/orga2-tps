#include <cstdlib>
#include <cstdio>
#include <cerrno>
#include <cstring>

#include <vector>
#include <queue>

using namespace std;

#include "test-o-matic.h"
#include "listaP.h"

#ifdef DEBUG
#define DLOG(...) printf("DEBUG:: "); printf(__VA_ARGS__);
#else
#define DLOG(...)
#endif

int isParam (char* needle, char* haystack[], int count);
char* getParam (char* needle, char* haystack[], int count);

void showusage (char* filename) {
  printf ("Uso: %s [-s] -i ARCHIVO_IN -o ARCHIVO_OUT\n", filename);
  printf ("\n");
  printf ("Utiliza ARCHIVO como un conjunto de acciones a seguir. Cada linea del archivo de texto representa una accion a realizar. Los casos de test se separan con ---. El archivo de salida se escribira en el mismo directorio con el mismo nombre que la entrada pero extension .out.\n");
  printf ("\n");
  printf ("Las acciones posibles son:\n");
  printf ("crear:\n");
  printf ("agregarunapalabra: <palabra>\n");
  printf ("agregarmaspalabras: <cantidad> <palabra> [<palabra> ... ]\n");
  printf ("buscar: <palabra>\n");
  printf ("caracter: <letra>\n");
  printf ("prefijo: <palabra>\n");
  printf ("predecir: <letras>\n");
  printf ("pesopalabra: <palabra>\n");
  printf ("pesartrie: \n");
  printf ("imprimir: \n");
  printf ("borrar: \n");
  printf ("\n");
  printf ("<cantidad> corresponde a una numero con la cantidad de palabras a leer.");
  printf ("<palabra> corresponde a una secuencia de char de hasta 50 caracteres.");
  printf ("[palabra] corresponde a una secuencia opcional de char de hasta 50 caracteres.");
  printf ("\n");
  printf ("Para ver ejemplos, se puden consultar los archivos *.in provistos por la catedra.\n");
}


int main (int argc, char* argv[]) {
  char* testin  = getParam ((char*)"-i", (char**)argv, argc);
  char* testout = getParam ((char*)"-o", (char**)argv, argc);

  if (!isParam ((char*)"-i", argv, argc) || testin==NULL) {
    DLOG ("No hay parametros\n");
    showusage (argv[0]);
    exit (-1);
  }

  if (strnlen(testin, 1024) == 1024) {
    DLOG("testin path is too large.");
    showusage (argv[0]);
    exit (-1);
  }

  char testout_replacement[1024];
  if (!isParam ((char*)"-o", argv, argc) || testout==NULL) {
    snprintf(testout_replacement, 1024, "%s.out", testin);
    testout=testout_replacement;
  }

  bool intercalar = (bool)isParam ((char*)"-s", argv, argc);

  vector<TestOMatic*> tests;
  TestOMatic::cargar (testin, testout, tests);
  if (intercalar) {
    TestOMatic::correrIntercalados (tests);
  } else {
    TestOMatic::correrDeAUno (tests);
  }

  TestOMatic::liberar (tests);
}


char* getParam (char* needle, char* haystack[], int count) {
  int i = 0;
  for (i = 0; i < count; i ++) {
    if (strcmp (needle, haystack[i]) == 0) {
      if (i < count -1) {
        return haystack[i+1];
      }
    }
  }
  return 0;
}


int isParam (char* needle, char* haystack[], int count) {
  int i = 0;
  for (i = 0; i < count; i ++) {
    if (strcmp (needle, haystack[i]) == 0) {
      return 1;
    }
  }
  return 0;
}

