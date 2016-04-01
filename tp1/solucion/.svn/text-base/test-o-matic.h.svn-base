
#ifndef _TEST_O_MATIC_H_
#define _TEST_O_MATIC_H_

#include <cstdlib>
#include <cstdio>
#include <cerrno>
#include <cstring>

#include <vector>
#include <queue>

#include "trie.h"

#define MAXIMO_LARGO 200

class TestOMatic;

class AccionTest {
public:
  virtual void ejecutar () = 0;
  virtual ~AccionTest () {};
  virtual void escribir () = 0;
public:
  TestOMatic* test;
};

class AccionCrear : public AccionTest {
public:
  AccionCrear ();
  ~AccionCrear ();

  virtual void ejecutar ();
  virtual void escribir ();
};

class AccionConstruir : public AccionTest {
public:
  explicit AccionConstruir (FILE* fp);
  ~AccionConstruir ();

  virtual void ejecutar ();
  virtual void escribir ();
};

class AccionImprimir : public AccionTest {
public:
  AccionImprimir (FILE* fp);
  AccionImprimir() {}

  virtual void ejecutar ();
  virtual void escribir ();
  char str[MAXIMO_LARGO];
};

class AccionAgregarPalabra : public AccionTest {
public:
  AccionAgregarPalabra (FILE* fp);
  AccionAgregarPalabra (char* p) {
    strncpy (palabra_, p, MAXIMO_LARGO);
  }

  virtual void ejecutar ();
  virtual void escribir ();
  char palabra_[MAXIMO_LARGO];
};

class AccionAgregarPalabras : public AccionTest {
public:
  AccionAgregarPalabras (FILE* fp);
  AccionAgregarPalabras (std::vector<char*> p) {
    palabras_ = std::vector<char*>(p.begin(), p.end());
  }
  ~AccionAgregarPalabras ();

  virtual void ejecutar ();
  virtual void escribir ();
  std::vector<char*> palabras_;
};

class AccionPrefijo : public AccionTest {
public:
  AccionPrefijo (FILE* fp);
  AccionPrefijo (char* prefijo) {
    strncpy(prefijo_, prefijo, MAXIMO_LARGO);
  }
  ~AccionPrefijo ();

  virtual void ejecutar ();
  virtual void escribir ();
  char prefijo_[MAXIMO_LARGO];
};

class AccionPredecir : public AccionTest {
public:
  AccionPredecir (FILE* fp);
  AccionPredecir (char* teclas) {
    strncpy(teclas_, teclas, MAXIMO_LARGO);
  }
  ~AccionPredecir ();

  virtual void ejecutar ();
  virtual void escribir ();
  char teclas_[MAXIMO_LARGO];
};

class AccionBuscar : public AccionTest {
public:
  AccionBuscar (FILE* fp);
  AccionBuscar (char* needle) {
    strncpy(needle_, needle, MAXIMO_LARGO);
  }
  ~AccionBuscar ();

  virtual void ejecutar ();
  virtual void escribir ();
  char needle_[MAXIMO_LARGO];
};

class AccionBorrar : public AccionTest {
public:
  explicit AccionBorrar ();
  ~AccionBorrar ();

  virtual void ejecutar ();
  virtual void escribir ();
};

class AccionPesoPalabra : public AccionTest {
public:
  AccionPesoPalabra (FILE* fp);
  AccionPesoPalabra (char* palabra) {
    strncpy(palabra_, palabra, MAXIMO_LARGO);
  }
  ~AccionPesoPalabra();

  virtual void ejecutar ();
  virtual void escribir ();
  char palabra_[MAXIMO_LARGO];
};

class AccionPesoTrie : public AccionTest {
public:
  AccionPesoTrie ();
  AccionPesoTrie (FILE* fp);
  ~AccionPesoTrie ();

  virtual void ejecutar ();
  virtual void escribir ();
};

class AccionCaracterTecla : public AccionTest {
public:
  AccionCaracterTecla ();
  AccionCaracterTecla (char caracter);
  AccionCaracterTecla (FILE* fp);
  ~AccionCaracterTecla ();

  virtual void ejecutar ();
  virtual void escribir ();
  char tecla_;
};


class TestReader;

class TestOMatic {

public:
  TestOMatic (const TestOMatic& copy) : trie_ (copy.trie_) {};
  TestOMatic () :trie_ (NULL) {
  }
  ~TestOMatic ();

  static void cargar (const char* archivo_in, const char* archivo_out, std::vector<TestOMatic*>& tests);
  static void correrIntercalados (std::vector<TestOMatic*>& tests);
  static void correrDeAUno (std::vector<TestOMatic*>& tests);
  static void liberar (std::vector<TestOMatic*>& tests);

  void correr ();
  void correr (size_t i);

  void agregar_accion (AccionTest* accion) {
    acciones.push_back (accion);
    accion->test = this;
  }

  trie* trie_;
  char archivo_salida[MAXIMO_LARGO];
  size_t cantAcciones () {
    return acciones.size ();
  }
private:
  std::vector<AccionTest*> acciones;
};


class TestReader {
public:
  TestReader (const char* archivo_in, const char* archivo_out, std::vector<TestOMatic*>& tests);
  void cargar_accion (FILE* fp, char* accion, TestOMatic& test);
  ~TestReader ();

private:

};


#endif /// _TEST_O_MATIC_H_

