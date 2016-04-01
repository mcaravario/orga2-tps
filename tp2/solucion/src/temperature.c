
#include <stdio.h>
#include <string.h>

#include "tp2.h"

void temperature_asm    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

void temperature_c    (unsigned char *src, unsigned char *dst, int cols, int filas,
                      int src_row_size, int dst_row_size);

typedef void (temperature_fn_t) (unsigned char*, unsigned char*, int, int, int, int);


void leer_params_temperature(configuracion_t *config, int argc, char *argv[]) {

}

void aplicar_temperature(configuracion_t *config)
{
	temperature_fn_t *temperature = SWITCH_C_ASM ( config, temperature_c, temperature_asm ) ;
	buffer_info_t info = config->src;
	temperature(info.bytes, config->dst.bytes, info.width, info.height, info.width_with_padding,
	         config->dst.width_with_padding);

}

void ayuda_temperature()
{
	printf ( "       * temperature\n" );
	printf ( "           Parámetros     : \n"
	         "                         no tiene\n");
	printf ( "           Ejemplo de uso : \n"
	         "                         temperature -i c facil.bmp\n" );
}


