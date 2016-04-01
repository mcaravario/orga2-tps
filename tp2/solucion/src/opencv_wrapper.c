
#include <highgui.h>
#include <cv.h>
#include <stdio.h>

#include "tp2.h"
#include "opencv_wrapper.h"
#include "utils.h"

typedef struct CvVideoWriter CvVideoWriter;



// atenti, se puede tener solo 1 video in, 1 video out, 1 imagen in y 1 imagen out
CvCapture     *srcVid = NULL;
CvVideoWriter *dstVid = NULL;
IplImage      *srcImg = NULL;
IplImage      *dstImg = NULL;

struct CvVideoWriter *abrir_writer(const char *archivo_salida, int fps, CvSize size);
CvCapture *abrir_video(const char *archivo_entrada);

void opencv_abrir_imagenes(configuracion_t *config)
 {
	// Cargo la imagen
	if( (srcImg = cvLoadImage (config->archivo_entrada, CV_LOAD_IMAGE_COLOR)) == 0 ) {
    	fprintf(stderr, "Error abriendo la imagen fuente\n");
		exit(EXIT_FAILURE);
	}


	// Creo una IplImage para cada salida esperada
	if( (dstImg = cvCreateImage (cvGetSize (srcImg), IPL_DEPTH_8U, 3) ) == 0 ) {
    	fprintf(stderr, "Error creando la imagen destino\n");
		exit(EXIT_FAILURE);
	}

	config->src.bytes = (unsigned char*)srcImg->imageData;
	config->dst.bytes = (unsigned char*)dstImg->imageData;
	config->src.width              = srcImg->width;
	config->src.height             = srcImg->height;
	config->src.width_with_padding = srcImg->widthStep;
	config->dst.width              = dstImg->width;
	config->dst.height             = dstImg->height;
	config->dst.width_with_padding = dstImg->widthStep;
}

void opencv_liberar_imagenes(configuracion_t *config)
{
	// Guardo imagen resultado y libero los buffers
	if (cvSaveImage(config->archivo_salida, dstImg, NULL) == 0)
	    fprintf(stderr, "Error guardando la imagen destino (%s)\n", config->archivo_salida);


	cvReleaseImage(&srcImg);
	cvReleaseImage(&dstImg);
}



void opencv_abrir_video(configuracion_t *config)
{
    srcVid = abrir_video(config->archivo_entrada);

	CvSize dst_size;
    dst_size.width = cvGetCaptureProperty(srcVid,CV_CAP_PROP_FRAME_WIDTH);
    dst_size.height = cvGetCaptureProperty(srcVid,CV_CAP_PROP_FRAME_HEIGHT);

	config->src.width  = dst_size.width;
	config->src.height = dst_size.height;
	config->src.width_with_padding = dst_size.width*3;
	config->dst.width  = dst_size.width;
	config->dst.height = dst_size.height;
	config->dst.width_with_padding = dst_size.width*3;

	double fps = cvGetCaptureProperty(srcVid,CV_CAP_PROP_FPS);

    /* Armo el buffer destino. */
    int nchannels = 3;
    dstImg = cvCreateImage (dst_size, IPL_DEPTH_8U, nchannels);
    if (dstImg == NULL) {
        fprintf(stderr, "Error armando la imagen destino\n");
        exit(EXIT_FAILURE);
    }

	config->dst.bytes = (unsigned char*)dstImg->imageData;

    if (!config->frames) {
        dstVid = abrir_writer(config->archivo_salida, fps, dst_size);
    }

    if (config->verbose) {
        cvNamedWindow("procesanding", CV_WINDOW_AUTOSIZE);
    }
}


void opencv_frames_do(configuracion_t *config, aplicador_fn_t aplicador)
{
    unsigned int framenum = 0;
    while(1) {
        /* Capturo un frame */
        IplImage *frame = cvQueryFrame(srcVid);
        framenum ++;

        if (frame == NULL) {
            break;
        }
		config->src.bytes = (unsigned char*)frame->imageData;
		
		aplicador(config);
		
        if (config->frames) { 
		    const char *filename = basename(config->archivo_entrada);

			/* Escribo el frame en bmp */
            snprintf(config->archivo_salida, sizeof(config->archivo_salida), "%s/%s.%s.%d.bmp",
                                    config->carpeta_salida, filename, config->nombre_filtro, framenum);
            cvSaveImage(config->archivo_salida, dstImg, NULL);
        } else {
			/* Escribo el frame en el video */
            cvWriteFrame(dstVid, dstImg);
        }

        if (config->verbose) {
            cvShowImage("procesanding", dstImg);
            cvWaitKey(1);
        }
    }
}

void opencv_liberar_video(configuracion_t *config)
{
    cvReleaseImage(&dstImg);
    if (config->verbose) {
        cvDestroyWindow("procesanding");
    }

    if (!config->frames) {
        cvReleaseVideoWriter(&dstVid);
    }
    cvReleaseCapture(&srcVid);

}

struct CvVideoWriter *abrir_writer(const char *archivo_salida, int fps, CvSize size) {
    struct CvVideoWriter *dstVid = NULL;
    dstVid = cvCreateVideoWriter(archivo_salida, CV_FOURCC('M','J','P','G'), fps, size, 1);
    if(dstVid == NULL) {
        fprintf(stderr, "Invalid dstVid\n");
        exit(EXIT_FAILURE);
    }

    return dstVid;
}


CvCapture *abrir_video(const char *archivo_entrada) {
    CvCapture *srcVid = NULL;
    srcVid = cvCaptureFromFile(archivo_entrada);
    if( srcVid == NULL) {
        /* Esto no está documentado. No debería pasar nunca. */
        fprintf(stderr, "Invalid srcVid\n%s \n", archivo_entrada);
        exit(EXIT_FAILURE);
    }

    return srcVid;
}


