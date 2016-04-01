#include <cstdlib>
#include <cstdio>
#include <cerrno>
#include <cstring>
#include <cassert>
#include <vector>
#include <queue>
#include <iostream>

#include "test-o-matic.h"
#include "listaP.h"

using namespace std;

void debio_leer (int cantidad, int leido, FILE* fp) {
  if (cantidad == leido) {
    return;
  }
  char err_str[200], str[100];
  fgets (str, 100, fp);
  sprintf (err_str, "No se pudo leer el test a partir de >%s", str);
  perror (err_str);
  assert (false);
}

AccionCrear::AccionCrear () {
}

void AccionCrear::escribir () {
  fprintf (stdout, "crear: \n");
}

AccionCrear::~AccionCrear () {
}

void AccionCrear::ejecutar () {
  test->trie_ = trie_crear ();
}

AccionConstruir::AccionConstruir (FILE* fp) {
}

void AccionConstruir::escribir () {
  fprintf (stdout, "construir: \n");
}

AccionConstruir::~AccionConstruir () {
}

void AccionConstruir::ejecutar () {
}


AccionImprimir::AccionImprimir (FILE* fp) {
  fgets (str, 100, fp);
  char* sin = str;
  while (*sin != '\n' && (*sin == '\t' || *sin == ' ')) {
    sin++;
  }

  char* sout = str;
  while (*sin != '\n') {
    *sout = *sin;
    sin++;
    sout++;
  }
  if (sout != str) {
    *sout = ' ';    // si tiene al menos un caracter
    sout++;
  }
  *sout = 0;

}

void AccionImprimir::ejecutar () {
  FILE* stream = fopen (test->archivo_salida, "a");
  fprintf (stream, "%s", str);
  fclose (stream);
  trie_imprimir ( test->trie_, test->archivo_salida);
}

void AccionImprimir::escribir () {
  fprintf (stdout, "imprimir: \n");
}

AccionAgregarPalabra::AccionAgregarPalabra (FILE* fp) {
  int leido = fscanf (fp, " %99s", palabra_);
  debio_leer (1, leido, fp);
}

void AccionAgregarPalabra::ejecutar () {
  trie_agregar_palabra (test->trie_, palabra_);
}

void AccionAgregarPalabra::escribir () {
  fprintf (stdout, "agregarunapalabra: %s \n", palabra_);
}

AccionPrefijo::AccionPrefijo (FILE* fp) {
  int leido = fscanf (fp, "%99s", prefijo_);
  debio_leer (1, leido, fp);
}

AccionPrefijo::~AccionPrefijo () {
}

void AccionPrefijo::ejecutar () {
  FILE* stream = fopen (test->archivo_salida, "a");
  listaP* palabras = palabras_con_prefijo (test->trie_, prefijo_);
  lsnodo* recorrer = palabras->prim;
  while (recorrer) {
    fprintf (stream, "%s ", recorrer->valor);
    recorrer = recorrer->sig;
  }
  fprintf (stream, "\n");
  fclose(stream);
  lista_borrar(palabras);
}

void AccionPrefijo::escribir () {
  fprintf (stdout, "prefijo: %s \n", prefijo_);
}


AccionPredecir::AccionPredecir (FILE* fp) {
  int leido = fscanf (fp, "%99s", teclas_);
  debio_leer (1, leido, fp);
}

AccionPredecir::~AccionPredecir () {
}

void AccionPredecir::ejecutar () {
  FILE* stream = fopen (test->archivo_salida, "a");
  listaP* palabras = predecir_palabras (test->trie_, teclas_);
  lsnodo* recorrer = palabras->prim;
  while (recorrer) {
    fprintf (stream, "%s ", recorrer->valor);
    recorrer = recorrer->sig;
  }
  fprintf (stream, "\n");
  fclose(stream);
  lista_borrar(palabras);
}

void AccionPredecir::escribir () {
  fprintf (stdout, "predecir: %s \n", teclas_);
}

AccionBuscar::AccionBuscar (FILE* fp) {
  int leido = fscanf (fp, "%99s", needle_);
  debio_leer (1, leido, fp);
}

AccionBuscar::~AccionBuscar () {
}

void AccionBuscar::ejecutar () {
  FILE* stream = fopen (test->archivo_salida, "a");
  bool encontro = buscar_palabra (test->trie_, needle_);
  
  if (encontro)
    fprintf (stream, "TRUE \n");
  else
    fprintf (stream, "FALSE \n");
  
  fclose(stream);
}

void AccionBuscar::escribir () {
  fprintf (stdout, "buscar: %s\n", needle_);
}

AccionBorrar::AccionBorrar () {
}

AccionBorrar::~AccionBorrar () {
}

void AccionBorrar::ejecutar () {
  trie_borrar (test->trie_);
  test->trie_=NULL;
}

void AccionBorrar::escribir () {
  fprintf (stdout, "borrar: \n");
}

AccionPesoPalabra::AccionPesoPalabra (FILE* fp) {
  int leido = fscanf (fp, " %99s", palabra_);
  debio_leer (1, leido, fp);
}

AccionPesoPalabra::~AccionPesoPalabra () {
}

void AccionPesoPalabra::ejecutar () {
  peso_palabra(palabra_);
}

void AccionPesoPalabra::escribir () {
  fprintf (stdout, "pesopalabra: %s \n", palabra_);
}

AccionPesoTrie::AccionPesoTrie() {
}

AccionPesoTrie::AccionPesoTrie (FILE* fp) {
}

AccionPesoTrie::~AccionPesoTrie () {
}

void AccionPesoTrie::ejecutar () {
  FILE* stream = fopen (test->archivo_salida, "a");
  double peso = trie_pesar(test->trie_, &peso_palabra);
  fprintf (stream, "%f \n", peso);
  fclose (stream);
}

void AccionPesoTrie::escribir () {
  fprintf (stdout, "pesotrie: \n");
}

TestReader::TestReader (const char* archivo_in, const char* archivo_out, vector<TestOMatic*>& tests) {
  FILE* fp = fopen (archivo_in, "r");
  if (fp == NULL) {
    perror ("No se pudo abrir el archivo de test");
  }

  char str[100];
  size_t str_size = 100;
  int line_number = 0;
  while (fscanf (fp, "%99s: ", (char*)str) != EOF) {
    line_number++;
    if (str[0] == '-') {
      TestOMatic* test = new TestOMatic;
      strcpy ((char*)test->archivo_salida,archivo_out);
      tests.push_back (test);
      fgets (str, str_size, fp);

    } else {
      cargar_accion (fp, (char*)str, *tests.back ());
    }
  }
  fclose (fp);
}


TestReader::~TestReader () { }

enum AccionToken {
    CrearToken,
    AgregarPalabraToken,
    ConstruirToken,
    ImprimirToken,
    BuscarToken,
    PalabrasConPrefijoToken,
    PredecirPalabrasToken,
    PesoPalabraToken,
    PesoTrieToken, 
    BorrarToken,
    ErrorToken
};

AccionToken tokenizar (char* accion) {
  switch (accion[0]) {
  case 'c':
    if (accion[1] == 'r') {
      return CrearToken;
    }
    if (accion[1] == 'o') {
      return ConstruirToken;
    }
    break;
  case 'a':
    if (accion[7] == 'u') {
      return AgregarPalabraToken;
    }
    break;
  case 'p':
    if (accion[4] == 'p') {
      return PesoPalabraToken;
    }
    if (accion[4] == 't') {
      return PesoTrieToken;
    }
    if (accion[3] == 'd') {
      return PredecirPalabrasToken;
    }
    if (accion[3] == 'f') {
      return PalabrasConPrefijoToken;
    }
    break;
  case 'i':
    return ImprimirToken;
    break;
  case 'b':
    if (accion[1] == 'u') {
      return BuscarToken;
    }
    if (accion[1] == 'o') {
      return BorrarToken;
    }
    break;
  default:
    perror ("accion desconocida");
    printf ("%s", accion);
  }
  return ErrorToken;
}

void TestReader::cargar_accion (FILE* fp, char* accion_str, TestOMatic& test) {
  AccionTest* accion = NULL;
  AccionToken token = tokenizar (accion_str);
  switch (token) {
  case CrearToken:
    accion = new AccionCrear ();
    break;
  case ConstruirToken:
    accion = new AccionConstruir (fp);
    break;
  case AgregarPalabraToken:
    accion = new AccionAgregarPalabra (fp);
    break;
  case PalabrasConPrefijoToken:
    accion = new AccionPrefijo (fp);
    break;
  case PredecirPalabrasToken:
    accion = new AccionPredecir (fp);
    break;
  case PesoPalabraToken:
    accion = new AccionPesoPalabra (fp);
    break;
  case PesoTrieToken:
    accion = new AccionPesoTrie (fp);
    break;
  case ImprimirToken:
    accion = new AccionImprimir (fp);
    break;
  case BuscarToken:
    accion = new AccionBuscar (fp);
    break;
  case BorrarToken:
    accion = new AccionBorrar ();
    break;
  default:
    perror ("accion no implementada");
    printf ("%s", accion_str);
  }

  if (accion != NULL) {
    test.agregar_accion (accion);
  } else {
    perror ("Error parseando accion");
  }
}


void TestOMatic::cargar (const char* archivo_in, const char* archivo_out, vector<TestOMatic*>& tests) {
  TestReader reader (archivo_in, archivo_out, tests);
}

void TestOMatic::liberar (std::vector<TestOMatic*>& tests) {
  for (size_t i = 0; i < tests.size (); i++) {
    delete tests[i];
  }
}

void TestOMatic::correrDeAUno (std::vector<TestOMatic*>& tests) {
  for (size_t i = 0; i < tests.size (); i++) {
    tests[i]->correr ();
  }
}

void TestOMatic::correrIntercalados (std::vector<TestOMatic*>& tests) {
  size_t cantidad = 0;
  for (size_t i = 0; i < tests.size (); i++) {
    cantidad = max (cantidad, tests[i]->cantAcciones () );
  }

  for (size_t i = 0; i < cantidad; i++)
    for (size_t j = 0; j < tests.size (); j++) {
      tests[j]->correr (i);
    }
}

TestOMatic::~TestOMatic () {
  for (size_t i = 0; i < acciones.size (); i++) {
    delete acciones[i];
  }
}

void TestOMatic::correr () {
  for (size_t i = 0; i < acciones.size (); i++) {
    correr (i);
  }
}

void TestOMatic::correr (size_t i) {
  if (i < acciones.size ()) {
    acciones[i]->ejecutar ();
  }
}

