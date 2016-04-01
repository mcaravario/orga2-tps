
#include "tp2.h"


void tiles_c    (
	unsigned char *src,
	unsigned char *dst,
	int cols,
	int filas,
	int src_row_size,
	int dst_row_size,
	int tamx,
	int tamy,
	int offsetx,
	int offsety)
{
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	
	for (int i_d = 0, i_s = 0; i_d < filas; i_d++, i_s++) {
		for (int j_d = 0, j_s = 0; j_d < cols; j_d++, j_s++) {
			
			rgb_t *p_d = (rgb_t*)&dst_matrix[i_d][j_d*3];
			rgb_t *p_s = (rgb_t*)&src_matrix[(i_s % tamy) + offsety][((j_s % tamx) + offsetx)*3];
			*p_d = *p_s;

		}
	}

}
