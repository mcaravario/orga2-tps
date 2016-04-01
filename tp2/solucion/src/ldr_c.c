
#include "tp2.h"

#define MIN(x,y) ( x < y ? x : y )
#define MAX(x,y) ( x > y ? x : y )

#define P 2

void ldr_c    (
    unsigned char *src,
    unsigned char *dst,
    int cols,
    int filas,
    int src_row_size,
    int dst_row_size,
	int alfa)
{
    unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
    unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
    const double max = (5 * 5 * 255 * 3 * 255);

    for (int i = 0; i < filas; i++){
        for (int j = 0; j < cols; j++){
            rgb_t *p_d = (rgb_t*) &dst_matrix[i][j * 3];
            rgb_t *p_s = (rgb_t*) &src_matrix[i][j * 3];

            if (i >= 2 && filas-i > 2 && j >= 2 && cols-j > 2){
                int res = 0;
                int fin_f = i+2;
                int fin_c = j+2;
                int ini_f = i-2;
                int ini_c = j-2;

                rgb_t *q_s = p_s;

                for(int k = ini_f; k <= fin_f; k++){
                    for(int h = ini_c; h <= fin_c; h++){
                    q_s = (rgb_t*) &src_matrix[k][h*3];
                    res = res + q_s->g + q_s->r + q_s->b;
                    }				
                }

                long temp = (alfa * res);
                
                int r = ((p_s->r)*temp) / max;
                int b = ((p_s->b)*temp) / max;
                int g = ((p_s->g)*temp) / max;
                
                r = MIN(MAX(r+p_s->r,0),255);
                b = MIN(MAX(b+p_s->b,0),255);
                g = MIN(MAX(g+p_s->g,0),255);


                p_d->r = r;
                p_d->b = b;
                p_d->g = g;

            } else {
                *p_d=*p_s;
            }
        }			

    }
}


