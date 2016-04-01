
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "tp2.h"

void tiles_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size, int tamx, int tamy, int offsetx, int offsety);

void tiles_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size, int tamx, int tamy, int offsetx, int offsety);

typedef void (tiles_fn_t) (unsigned char*, unsigned char*, int, int, int, int, int, int, int, int);

typedef struct tiles_params_t {
	int tamx, tamy, offsetx, offsety;
} tiles_params_t;


tiles_params_t extra;
void leer_params_tiles(configuracion_t *config, int argc, char *argv[]) {
	config->extra_config = &extra;
    extra.tamx    = atoi(argv[argc - 4]);
    extra.tamy    = atoi(argv[argc - 3]);
    extra.offsetx = atoi(argv[argc - 2]);
    extra.offsety = atoi(argv[argc - 1]);
}

void aplicar_tiles(configuracion_t *config)
{
	tiles_fn_t *tiles = SWITCH_C_ASM ( config, tiles_c, tiles_asm ) ;
	tiles_params_t *extra = (tiles_params_t*)config->extra_config;
	buffer_info_t info = config->src;
	tiles(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding, extra->tamx, extra->tamy, extra->offsetx, extra->offsety);

}

void ayuda_tiles()
{
	printf ( "       * tiles\n" );
	printf ( "           Parámetros     : \n"
	         "                         tamx ancho del mosaico\n"
	         "                         tamy alto del mosaico\n"
	         "                         offsetx pixels a partir de los cuales copiar del source\n"
	         "                         offsety pixels a partir de los cuales copiar del source\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         tiles -i c facil.bmp 20 30 40 50\n" );
}


