
#include "tp2.h"


rgb_t colores[] = { {255,   0,   0},
                    {127,   0, 127},
                    {255,   0, 255},
                    {  0,   0, 255},
                    {  0, 255, 255} };

void popart_c    (
	unsigned char *src,
	unsigned char *dst,
	int cols,
	int filas,
	int src_row_size,
	int dst_row_size)
{
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	for (int i_d = 0, i_s = 0; i_d < filas; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < cols; j_d++, j_s++) {
			rgb_t *p_d = (rgb_t*)&dst_matrix[i_d][j_d*3];
			rgb_t *p_s = (rgb_t*)&src_matrix[i_s][j_s*3];
			
			int suma = p_s->r + p_s->b + p_s->g;
			//~ printf("%d\n",suma);
			
			//~ char j = 255;
			//~ printf("%c\n",j);
			
			if (suma < 153){
				p_d->r = colores[0].r;
				p_d->g = colores[0].g;
				p_d->b = colores[0].b;
			}else if (suma < 306){
				p_d->r = colores[1].r;
				p_d->g = colores[1].g;
				p_d->b = colores[1].b;
			}else if (suma < 459){
				p_d->r = colores[2].r;
				p_d->g = colores[2].g;
				p_d->b = colores[2].b;
			}else if (suma < 612){
				p_d->r = colores[3].r;
				p_d->g = colores[3].g;
				p_d->b = colores[3].b;
			} else {
				p_d->r = colores[4].r;
				p_d->g = colores[4].g;
				p_d->b = colores[4].b;
			}
			
			
		}
	}

}


