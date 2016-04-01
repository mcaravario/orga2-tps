
#include <stdio.h>
#include <string.h>

#include "tp2.h"

void popart_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

void popart_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

typedef void (popart_fn_t) (unsigned char*, unsigned char*, int, int, int, int);

void leer_params_popart(configuracion_t *config, int argc, char *argv[]) {
}

void aplicar_popart(configuracion_t *config)
{
	popart_fn_t *popart = SWITCH_C_ASM ( config, popart_c, popart_asm ) ;
	buffer_info_t info = config->src;
	popart(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding);

}

void ayuda_popart()
{
	printf ( "       * popart\n" );
	printf ( "           Parámetros     : \n"
	         "                         tamx ancho del mosaico\n"
	         "                         tamy alto del mosaico\n"
	         "                         offsetx pixels a partir de los cuales copiar del source\n"
	         "                         offsety pixels a partir de los cuales copiar del source\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         popart -i c facil.bmp 20 30 40 50\n" );
}


