
global ldr_asm

section .data

ALIGN 16

%define MAX 4876875.0

MAX_MEM: dq	MAX, MAX
ALPHA_MEM: dd 0,0,0,0

dejar_primeros_6_bytes: db	0xFF,0xFF,0xFF,0xFF,0xFF,0xFF, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

dejar_ultimos_10_bytes: db 0, 0, 0, 0, 0, 0, 0xFF,0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF,0xFF

dejar_primeros_10_bytes: db 0xFF,0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF,0xFF, 0, 0, 0, 0, 0, 0

dejar_ultimos_6_bytes: db 0,0, 0, 0, 0, 0, 0, 0, 0, 0, 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF

section .text
;void popart_c    (
	;unsigned char *src,    	RDI
	;unsigned char *dst,    	RSI
	;int cols,				  	EDX		
	;int filas,				  	ECX	
	;int src_row_size,		  	R8D
	;int dst_row_size	  		R9D 
	;int alpha					[RBP + 16]


;;;; IDEA DE LA FUNCION
;;;;;; La idea es:
;;;;;;
;;;;;;		* Con un ciclo hacer el procesamiento de datos pedido, sobre el cuadrado interior de la matriz.
;;;;;;		Levanto con 2 registros 8 pixels para poder procesar 4 pixeles por iteracion. Uso 4 acumuladores en el
;;;;;;		ciclo para la SUMA_RGB y preparo la suma para cada pixel. Hago las multiplicaciones en formato entero, y luego
;;;;;;		paso a FP para realizar la division. Por ultimo, paso todo a entero y guardo el resultado en DST.
;;;;;;
;;;;;;		* Con otros 3 ciclos copio src  a  dst (la parte que no se modifica), las dos filas de arriba, las dos de abajo
;;;;;;		las dos columnas de la izquierda y las dos columnas de la derecha.


;;;;;; OBSERVACIONES:
;;;;;;			* Las representaciones de los registros estan de Parte Alta a Parte Baja    (127)--->(0)
;;;;;;			* Se utilizan mucho los shifts para acomodar registros
;;;;;;			* Proceso de a 4 pixeles (12 Bytes)
;;;;;;




%macro duplicar_dword 2

		;;; Descripcion: 
		;;;		* Duplica el word menos significativo en el registro.
		;;;			%1 --> Registro con el valor a Duplicar
		;;;			%2 --> Registro Auxiliar		
		
		
		;Limpio los 3 DWORDS altos
		pslldq	%1, 12
		psrldq	%1, 12
		
		;Copio el original limpio al aux		
		movdqa	%2, %1
		
		pslldq	%2, 4
		por	%1, %2
		movdqa	%2, %1
		pslldq	%1, 8
		por	%1, %2

%endmacro


ldr_asm:

	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15
	
	;; Salvo los punteros y el tamaño de fila para mas adelante
	push RCX
	push RDI
	push RSI
	
	;;; Avanzo el puntero de las matrices fuente y destino en dos filas.
	add RDI, R8
	add RDI, R8
	
	add RSI, R9
	add RSI, R9
	
	; Avanzo los punteros a la 3
	;~ add RDI, 6
	;~ add RSI, 6
	
	; Filas - 4
	sub ecx, 4
	
	;;;;  Utilizo R14 como flag para saber como acomodar los punteros y contadores.
	;;;;  Esto es asi porque reutilizo el cuerpo del ciclo para no repetir codigo.
	;;;;  Si R14 vale 0, los valores se incrementan normalmente. Si vale 1 significa
	;;;; que se hubo un salto al cuerpo del ciclo desde .fin_de_fila, con lo cual
	;;;; se deben resetear los valores e incrementar la fila.
	xor R14, R14 
	
	
	;; Duplico alpha en un XMM  (pues despues sera multiplicado)
	mov		r13d, [RBP + 16]					; R13D <-- Alpha
	movd	xmm14, r13d
	duplicar_dword	xmm14, xmm13				; XMM14 <-- Alpha | Alpha | Alpha | Alpha	(macro)
	movdqu	[ALPHA_MEM], xmm14


	;;;; Preparo los registros contadores para recorrer la matriz		
	push	rdx
	mov		eax, 3
	mul		edx									; EAX  <-- (cols * 3)
	mov		r12d, eax							; R12D <-- (cols * 3)      Voy a necesitar este valor mas adelante
	sub 	eax, 24								; EAX  <-- (cols * 3) - 24  Limite (para saber si voy a leer padding), pues leo 24 bytes por iteracion
	
	pop		rdx
		
	xor ebx, ebx								; EBX  <-- #Bytes procesados de la fila
	xor	r13d, r13d								; R13D <-- Numero de Fila  (para saber cuando termino de recorrer todo)
	
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;; 		  CICLO 1 	     ;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	.ciclo_cuadrado_medio:
	
		;; TERMINE CICLO?
		cmp	r13d, ecx
		je .fin_ciclo
		
		;; FINAL DE FILA?
		cmp ebx, eax
		jge .fin_de_fila

		.procesamiento:

		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;; PROCESAMIENTO DE DATOS ;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
		;; Uso 4 registros acumuladores.
		pxor	xmm0, xmm0					; XMM0 <-- ACUM_low1
		pxor	xmm1, xmm1					; XMM1 <-- ACUM_high1
		pxor	xmm2, xmm2					; XMM2 <-- ACUM_low2
		pxor	xmm3, xmm3					; XMM3 <-- ACUM_high2
		
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;;Carga de datos y suma acum;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;; Quiero obtener registros asi:
		;;;		 G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0		P0, P1 y B2, G2
		;;;		  0 | R4 | G4 | B4 | R3 | G3 | B3 | R2		P3, P4 y R2
		;;;		  0 | 0  | R6 | G6 | B6 | R5 | G5 | B5		P5 y P6
		;;;		  0 | 0  | 0  | 0  | 0  | R7 | G7 | B7 		P7
		
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		;; Cargo SRC (i,j)
	 	movdqu	xmm5, [RDI]
	 	movdqu	xmm6, [RDI + 8]				; Solo quiero quedarme con P5, P6 y P7
	 	
		;; Borro los P4 , P3 y R2 
		psrldq	xmm6, 7
		
		;; Limpio el byte basura
		pslldq	xmm5, 1
		psrldq	xmm5, 1
	
		;; Desempaqueto
		;	Primer registro
		pxor	xmm15, xmm15				; Auxiliar
		movdqa	xmm7, xmm5
		
		punpcklbw	xmm5, xmm15				; XMM5 <-- SRC_low1
		punpckhbw	xmm7, xmm15				; XMM7 <-- SRC_high1
		
		;	Segundo Registro
		movdqa	xmm8, xmm6
		
		punpcklbw	xmm6, xmm15				; XMM6 <-- SRC_low2
		
		; Me quedo solo con los pixeles 5 y 6
		pslldq		xmm6, 4
		psrldq		xmm6, 4		
					
		psrldq		xmm8, 6					; Lo shifteo 6 a la derecha para obtener de P7 en adelante
		punpcklbw	xmm8, xmm15				; XMM8 <-- SRC_high2
		
		;;; Me guardo SRC para mas adelante
		
		;;; Sumo SRC a los acumuladores		
		paddw	xmm0, xmm5
		paddw	xmm1, xmm7
		paddw	xmm2, xmm6
		paddw	xmm3, xmm8
		
		
		;;;;;; Cargo los SRC de las distintas filas y los voy sumando a los acumuladores
		
		;;;;;;;;;;;;;;;;;;;;;
		;;; SRC FILA + 1 ;;;;	
		;;;;;;;;;;;;;;;;;;;;;
		movdqu	xmm9, [RDI + R8]
		movdqu	xmm10, [RDI + R8 + 8]				; Solo quiero quedarme con P5, P6 y P7
		;; Borro los P4 , P3 y R2 
		psrldq	xmm10, 7
		
		;; Limpio el byte basura
		pslldq	xmm9, 1
		psrldq	xmm9, 1
		
		movdqu xmm11, xmm9
		
		punpcklbw	xmm9, xmm15
		punpckhbw	xmm11, xmm15
		
		movdqu	xmm12, xmm10
		
		punpcklbw	xmm10, xmm15
		
		; Me quedo solo con los pixeles 5 y 6
		pslldq		xmm10, 4
		psrldq		xmm10, 4
			
		psrldq		xmm12, 6					; Lo shifteo 6 a la derecha para obtener de P6 en adelante
		punpcklbw	xmm12, xmm15
		
		paddw	xmm0, xmm9
		paddw	xmm1, xmm11
		paddw	xmm2, xmm10
		paddw	xmm3, xmm12
		
		
		;;;;;;;;;;;;;;;;;;;;;
		;;; SRC FILA + 2 ;;;;	
		;;;;;;;;;;;;;;;;;;;;;
		movdqu	xmm9, [RDI + 2*R8]
		movdqu	xmm10, [RDI + 2*R8 + 8]				; Solo quiero quedarme con P5, P6 y P7
		;; Borro los P4 , P3 y R2 
		psrldq	xmm10, 7

		;; Limpio el byte basura
		pslldq	xmm9, 1
		psrldq	xmm9, 1
		
		movdqu xmm11, xmm9
		
		punpcklbw	xmm9, xmm15
		punpckhbw	xmm11, xmm15
		
		movdqu	xmm12, xmm10
		
		punpcklbw	xmm10, xmm15
		
		; Me quedo solo con los pixeles 5 y 6
		pslldq		xmm10, 4
		psrldq		xmm10, 4
		
		psrldq		xmm12, 6					; Lo shifteo 6 a la derecha para obtener de P6 en adelante
		punpcklbw	xmm12, xmm15
		
		paddw	xmm0, xmm9
		paddw	xmm1, xmm11
		paddw	xmm2, xmm10
		paddw	xmm3, xmm12
		
		
		;;;;;;;;;;;;;;;;;;;;;
		;;; SRC FILA - 1 ;;;;	
		;;;;;;;;;;;;;;;;;;;;;
		sub RDI, R8
		movdqu	xmm9, [RDI]
		movdqu	xmm10, [RDI+ 8]					; Solo quiero quedarme con P5, P6 y P7
		;; Borro los P4 , P3 y R2 
		psrldq	xmm10, 7
		;; Limpio el byte basura
		pslldq	xmm9, 1
		psrldq	xmm9, 1
		add RDI, R8
		
		movdqu xmm11, xmm9
		
		punpcklbw	xmm9, xmm15
		punpckhbw	xmm11, xmm15
		
		movdqu	xmm12, xmm10
		
		punpcklbw	xmm10, xmm15
		
		; Me quedo solo con los pixeles 5 y 6
		pslldq		xmm10, 4
		psrldq		xmm10, 4
		
		psrldq		xmm12, 6					; Lo shifteo 6 a la derecha para obtener de P6 en adelante
		punpcklbw	xmm12, xmm15
		
		paddw	xmm0, xmm9
		paddw	xmm1, xmm11
		paddw	xmm2, xmm10
		paddw	xmm3, xmm12
		
		
		;;;;;;;;;;;;;;;;;;;;;
		;;; SRC FILA - 2 ;;;;	
		;;;;;;;;;;;;;;;;;;;;;
		sub RDI, R8
		sub RDI, R8
		movdqu	xmm9, [RDI]
		movdqu	xmm10, [RDI+ 8]					; Solo quiero quedarme con P5, P6 y P7
		;; Borro los P4 , P3 y R2 
		psrldq	xmm10, 7
		;; Limpio el byte basura
		pslldq	xmm9, 1
		psrldq	xmm9, 1
		add RDI, R8
		add RDI, R8
		
		movdqu xmm11, xmm9
		
		punpcklbw	xmm9, xmm15
		punpckhbw	xmm11, xmm15
		
		movdqu	xmm12, xmm10
		
		punpcklbw	xmm10, xmm15
		
		; Me quedo solo con los pixeles 5 y 6
		pslldq		xmm10, 4
		psrldq		xmm10, 4
		
		psrldq		xmm12, 6					; Lo shifteo 6 a la derecha para obtener de P6 en adelante
		punpcklbw	xmm12, xmm15
		
		paddw	xmm0, xmm9
		paddw	xmm1, xmm11
		paddw	xmm2, xmm10
		paddw	xmm3, xmm12
	
	
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;;;;; FIN DE CARGADO Y SUMADO ;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
		
		
		;;;  En este punto tengo en los registros acumuladores las sumas verticales de las distintas filas.
		;;;	 Tengo:
		;;;		XMM0 <-- G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0		P0, P1 y B2, G2
		;;;		XMM1 <--  0 | R4 | G4 | B4 | R3 | G3 | B3 | R2		P3, P4 y R2
		;;;		XMM2 <--  0 | 0  | R6 | G6 | B6 | R5 | G5 | B5		P5 y P6
		;;;		XMM3 <--  0 | 0  | 0  | 0  | 0  | R7 | G7 | B7 		P7
		
		
		
		;;; Ahora tengo que obtener las sumas correspondientes a cada pixel.
		;; S1 = XMM0 + XMM1
		;; S1 =  suma de P0, P1, P2, P3, y P4
		
		movdqa	xmm9, xmm0
		paddw	xmm9, xmm1
		phaddw	xmm9, xmm9
		phaddw	xmm9, xmm9
		phaddw	xmm9, xmm9
		;; En la parte baja de xmm9 obtuve S1.
		
		;;; Genero la S2
		;; S2 = XMM0[3:8] + XMM1 + XMM2[0:3]
		;; S2 = suma de P1, P2, P3, P4 y P5
		movdqa	xmm10, xmm0
		psrldq	xmm10, 6					; Limpio el pixel 0
		movdqa	xmm11, xmm2
		pslldq	xmm11, 10					; Limpio el pixel 6
		paddw	xmm10, xmm1
		paddw	xmm10, xmm11
		
		phaddw	xmm10, xmm10
		phaddw	xmm10, xmm10
		phaddw	xmm10, xmm10
		;; En la parte baja de xmm10 obtuve S2
		
		;;; Genero la S3
		;;  S3 = XMM0[6:8] + XMM1 + XMM2
		;;  S3 = la suma de P2, P3, P4, P5 y P6
		movdqa	xmm11, xmm0
		psrldq	xmm11, 12
		paddw	xmm11, xmm1
		paddw	xmm11, xmm2
		
		phaddw	xmm11, xmm11
		phaddw	xmm11, xmm11
		phaddw	xmm11, xmm11
		;; En la parte baja de xmm10 obtuve S3
		
		;;; Genero la S4
		;; S4 = XMM1[1:8] + XMM2 + XMM3
		;; S4 = P3, P4, P5, P6 y P7
		movdqa	xmm12, xmm1
		psrldq	xmm12, 2
		paddw	xmm12, xmm2
		paddw	xmm12, xmm3
		
		phaddw	xmm12, xmm12
		phaddw	xmm12, xmm12
		phaddw	xmm12, xmm12
		;; En la parte baja de xmm12 obtuve S4
		

		;; Paso las sumas a DWORD
		pxor	xmm15, xmm15
		punpcklwd	xmm9, xmm15
		punpcklwd	xmm10, xmm15
		punpcklwd	xmm11, xmm15
		punpcklwd	xmm12, xmm15
		
		;;; Ahora voy a poner las 4 sumas en 3 registros, para despues realizar la multiplicacion.
		;;; Necesito dejarlos de la siguiente forma:
		;;;		XMM9 <--   S2 | S1 | S1 | S1 
		;;;		XMM10 <--  S3 | S3 | S2 | S2 
		;;;		XMM11 <--  S4 | S4 | S4 | S3
		
		;; Preparo XMM9
		duplicar_dword xmm9, xmm13					; XMM9  <--  S1 | S1 | S1 | S1
		psrldq	xmm9, 4								; XMM9  <--  0  | S1 | S1 | S1

		pslldq	xmm10, 12							; XMM10 <--  S2 | 0  | 0  | 0
		por		xmm9, xmm10							; XMM9  <--  S2 | S1 | S1 | S1
		
		;; Preparo XMM10
		psrldq	xmm10, 12							; XMM10 <--  0  | 0  | 0  | S2 
		duplicar_dword	xmm10, xmm13				; XMM10 <--  S2 | S2 | S2 | S2
		
		psrldq	xmm10, 8							; XMM10 <--  0  | 0  | S2 | S2 
		duplicar_dword	xmm11, xmm13				; XMM11 <--  S3 | S3 | S3 | S3
		pslldq	xmm11, 8							; XMM11 <--  S3 | S3 | 0  | 0
		
		por		xmm10, xmm11						; XMM10 <--  S3 | S3 | S2 | S2
	
		;; Preparo XMM11	
		psrldq	xmm11, 12							; XMM11 <--  0  | 0  | 0  | S3
		duplicar_dword	xmm12, xmm13				; XMM12 <--  S4 | S4 | S4 | S4
		pslldq	xmm12,	4							; XMM12 <--  S4 | S4 | S4 | 0
		
		por		xmm11, xmm12
		
		;;; En este punto necesito SRC(i,j) contenidos en xmm5, xmm7 y xmm6 en el siguiente formato:
		;;;		XMM5 <-- G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0
		;;;		XMM7 <--  0 | R4 | G4 | B4 | R3 | G3 | B3 | R2
		;;;		XMM6 <--  0 | 0  | R6 | G6 | B6 | R5 | G5 | B5

		
		;;; Necesito dejarlos de la siguiente forma:
		;;;		XMM0 <--  B3 | R2 | G2 | B2 
		;;;		XMM1 <--  G4 | B4 | R3 | G3 
		;;;		XMM2 <--  R5 | G5 | B5 | R4


		;;; Armo XMM0
		;;Limpio XMM5 del P1 y P0
		pxor	xmm0, xmm0
		psrldq	xmm5, 12			; XMM5  = 0  | 0  | 0  | 0  | 0  | 0  | G2 | B2 
		por		xmm0, xmm5			; XMM0  = 0  | 0  | 0  | 0  | 0  | 0  | G2 | B2 
		movdqa	xmm13, xmm7			; XMM13 = 0  | R4 | G4 | B4 | R3 | G3 | B3 | R2
		pslldq	xmm13, 12			; XMM13 = B3 | R2 | 0  | 0  | 0  | 0  | 0  | 0 
		psrldq	xmm13, 8			; XMM13 = 0  | 0  | 0  | 0  | B3 | R2 | 0  | 0
		por		xmm0, xmm13			; XMM0  = 0  | 0  | 0  | 0  | B3 | R2 | G2 | B2
		pxor	xmm13, xmm13
		punpcklwd	xmm0, xmm13		; XMM0 =  B3 | R2 | G2 | B2

		
		;;; Armo XMM1
		movdqa	xmm13, xmm7			; XMM13 =  0  | R4 | G4 | B4 | R3 | G3 | B3 | R2
		pslldq	xmm13, 4			; XMM13 =  G4 | B4 | R3 | G3 | B3 | R2 | 0  | 0
		psrldq	xmm13, 8			; XMM13 =   0 | 0  | 0  | 0  | G4 | B4 | R3 | G3
		movdqa	xmm1, xmm13
		pxor	xmm13, xmm13
		punpcklwd	xmm1, xmm13 	; XMM1 =  G4 | B4 | R3 | G3
		
		;;; Armo XMM2
		movdqa	xmm13, xmm7
		psrldq	xmm13, 12			; XMM13 = 0  | 0  | 0  | 0  | 0  | 0  | 0  | R4
		movdqa	xmm2, xmm6			; XMM2 =  0  | 0  | R6 | G6 | B6 | R5 | G5 | B5
		pslldq	xmm2, 10			; XMM2 =  R5 | G5 | B5 | 0  | 0  | 0  | 0  | 0 
		psrldq	xmm2, 8				; XMM2 =  0  | 0  | 0  | 0  | R5 | G5 | B5 | 0
		por		xmm2, xmm13			; XMM2 =  0  | 0  | 0  | 0  | R5 | G5 | B5 | R4
		pxor	xmm13, xmm13
		punpcklwd	xmm2, xmm13		; XMM2 = R5 | G5 | B5 | R4
		

		
		;;; Ya tengo los registros fuente como dwords de la siguiente forma:
		;;;		XMM0 <--  B3 | R2 | G2 | B2 
		;;;		XMM1 <--  G4 | B4 | R3 | G3 
		;;;		XMM2 <--  R5 | G5 | B5 | R4 
		;;;
		;;;
		;;; Tengo la sumas RGB en:
		;;;		XMM9 <--   S2 | S1 | S1 | S1 
		;;;		XMM10 <--  S3 | S3 | S2 | S2 
		;;;		XMM11 <--  S4 | S4 | S4 | S3		
		;;;
		;;;  Estos registros seran mis "var(i,j)"
		
		;; Cargo el valor Alpha (ya distribuido como dword en todo el registro)
		movdqu	xmm5, [ALPHA_MEM]
		
		;; Multiplico la suma RGB por Alpha
		;; Esta parte puede ser "peligrosa", quizas no se respete bien el signo. Deberia, pero si hay un error chequear aca.
		
	
		pmulld	xmm9, xmm5
		pmulld	xmm10, xmm5
		pmulld	xmm11, xmm5
		
		;; Ahora multiplico por SRC
		pmulld	xmm9, xmm0
		pmulld	xmm10, xmm1
		pmulld	xmm11, xmm2
		
		;; Divido por max (ya esta en presicion doble, distribuido en todo el registro)
		movdqu	xmm15, [MAX_MEM]
		
		; Tengo que pasar el resultado de la multiplicacion a double para realizar la division.
		cvtdq2pd	xmm3, xmm9
		psrldq		xmm9, 8
		cvtdq2pd	xmm4, xmm9
		cvtdq2pd	xmm5, xmm10
		psrldq		xmm10, 8
		cvtdq2pd	xmm6, xmm10
		cvtdq2pd	xmm7, xmm11
		psrldq		xmm11, 8
		cvtdq2pd	xmm8, xmm11
		
		divpd	xmm3, xmm15
		divpd	xmm4, xmm15
		divpd	xmm5, xmm15
		divpd	xmm6, xmm15
		divpd	xmm7, xmm15
		divpd	xmm8, xmm15
		
		
		;;; Paso a enteros de 32 bits
		cvttpd2dq	xmm3, xmm3
		cvttpd2dq	xmm4, xmm4
		cvttpd2dq	xmm5, xmm5
		cvttpd2dq	xmm6, xmm6
		cvttpd2dq	xmm7, xmm7
		cvttpd2dq	xmm8, xmm8
		
		; Junto los registros.
		pslldq	xmm4, 8
		pslldq	xmm6, 8
		pslldq	xmm8, 8
		
		por	xmm3, xmm4
		por xmm5, xmm6
		por xmm7, xmm8

		
		
		;; Var(i,j) ya esta calculada, ahora falta sumarle src(i,j)
		paddd	xmm3, xmm0
		paddd	xmm5, xmm1
		paddd	xmm7, xmm2
		
		;; Ahora voy a empaquetar con saturacion con signo, para cumplir con "  max (src + var, 0)  "
		pxor		xmm6, xmm6
		packusdw	xmm3, xmm5
		packusdw	xmm7, xmm6
		packuswb	xmm3, xmm7	
		

		; xmm3 = 0  | 0  | 0  | 0 | R5 | G5 | B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2 | G2 | B2 

		
		
		;; Cargo en la imagen destino XMM6
		movdqu	[RSI + 6], xmm3
		
		cmp R14, 0
		jne .vengo_de_fin_fila
		
			;;;;;;; Fin Iteracion Normal ;;;;;;;;;
			;; Avanzo punteros en 12 bytes, pues proceso 4 bytes por iteracion
			add RDI, 12
			add RSI, 12
			
			;; Avanzo contador de bytes por fila
			add ebx, 12
			
			jmp .ciclo_cuadrado_medio
		
		
		.vengo_de_fin_fila:
			;;;;;;; Fin Iteracion De Fin de Fila  ;;;;;;;;;
			
			; Reinicio el flag
			xor R14, R14
			
			;; Si resto los bytes que recorri y le sumo row_size, me voy a parar en la siguiente fila, en la tercer columna
			mov ebx, eax			; Limpio la parte alta
			
			sub RDI, RBX
			sub RSI, RBX
			
			add RDI, R8
			add RSI, R9
			
			; Reinicio contador de bytes por fila a 6, pues equivale a los 2 pixeles del comienzo
			mov ebx, 0
			
			; Incremento la fila
			inc r13d
			
			jmp .ciclo_cuadrado_medio
			
			
		
	.fin_de_fila:
	
		; Caulculo el retroceso del puntero que es #bytes recorridos + (24 - 2*3) - cols * 3
		; 24 - 2*3    corresponde a 24 bytes que quiero leer, y los 6 bytes de las 2 columnas del fondo
		;~ mov r15d, ebx
		;~ add r15d, 18 
		;~ sub r15d,r12d
		

		mov r15d, ebx
		sub r15d, eax
		;~ sub r15d, 6

		
		; Retrocedo los punteros
		
		sub RDI, R15
		sub RSI, R15	

		
		;; Levanto el flag para saber como acomodar los punteros y demas valores.
		mov R14, 1
		
		
		;; Procesar
		jmp .procesamiento
		
		
		
.fin_ciclo:

	;;; Restauro valores de los punteros:
	pop RSI
	pop RDI
	pop RCX
	
	push RSI
	push RDI
	
	;;; Pinto el recuadro de la imagen
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; 		  CICLO 2 	     ;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; 	Pinto Filas de arriba  ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	xor rbx, rbx				; Filas recorridas   (quiero tener la parte alta limpia)
	xor rax, rax				; Bytes Copiados 	 (quiero tener la parte alta limpia)
	
	; En R12D tengo (cols*3)
	mov r10d, r12d
	sub r10d, 16				; R10D <-- (Cols * 3) - 16   Este es mi limite, si alcanzo este valor tengo que retroceder

	.ciclo_filas_top:
	
		cmp ebx, 2
		je .fin_top
		
		cmp eax, r10d
		jge .fin_fila_top
		
		movdqu	xmm0, [RDI + rax]
		movdqu	[RSI + RAX], xmm0
		
		add eax, 16
		
		jmp .ciclo_filas_top
		
	.fin_fila_top:
		
		; Calculo el retroceso
		; R11D = #Bytes_Procesados + 16 - (cols * 3)
		mov r11d, eax
		add r11d, 16
		sub r11d, r12d
		
		sub eax, r11d
		
		movdqu	xmm0, [RDI + RAX]
		movdqu	[RSI + RAX], xmm0
				
		xor rax, rax
		inc ebx
		add RDI, R8
		add RSI, R9
		
		jmp .ciclo_filas_top

	.fin_top:


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; 	Pinto Filas de abajo   ;;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	pop RDI
	pop RSI
	
	push RSI
	push RDI

	; Acomodo los punteros en la ultima fila
	; Calculo cuanto tengo que mover el puntero de la matriz fuente
	
	; Limpio las partes altas
	mov ecx, ecx
	mov r8d, r8d
	
	mov r15d, ecx
	sub r15d, 2
	mov eax, r8d
	mul r15d
	
	add RDI, RAX
	
	; Calculo cuanto tengo que mover el puntero de la matriz destino
	mov r15d, ecx
	sub r15d, 2
	mov eax, r9d
	mul r15d
	
	add RSI, RAX
	
	xor rbx, rbx				; Filas recorridas   (quiero tener la parte alta limpia)
	xor rax, rax				; Bytes Copiados 	 (quiero tener la parte alta limpia)
	
	; En R12D tengo (cols*3)
	mov r10d, r12d
	sub r10d, 16				; R10D <-- (Cols * 3) - 16   Este es mi limite, si alcanzo este valor tengo que retroceder

	.ciclo_filas_bot:
	
		cmp ebx, 2
		je .fin_bot
		
		cmp eax, r10d
		jge .fin_fila_bot
		
		movdqu	xmm0, [RDI + rax]
		movdqu	[RSI + RAX], xmm0
		
		add eax, 16
		
		jmp .ciclo_filas_bot
		
	.fin_fila_bot:
		
		; Calculo el retroceso
		; R11D = #Bytes_Procesados + 16 - (cols * 3)
		mov r11d, eax
		add r11d, 16
		sub r11d, r12d
		
		sub eax, r11d
		
		movdqu	xmm0, [RDI + RAX]
		movdqu	[RSI + RAX], xmm0
				
		xor rax, rax
		inc ebx
		add RDI, R8
		add RSI, R9
		
		jmp .ciclo_filas_bot
		
	.fin_bot:

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;; 		Pinto Columnas		;;;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Tengo que pintar las Columnas: 0,1, j-2 y j-1, desde la fila 2, hasta la i-2
	; Tengo que preservar los valores que ya escribi
	
	pop RDI
	pop RSI
	
	; Empiezo desde la fila 2
	add RDI, R8
	add RDI, R8
	
	add RSI, R9
	add RSI, R9
	
	; Preparo dos mascaras
	movdqa	xmm10, [dejar_primeros_6_bytes]
	movdqa	xmm11, [dejar_ultimos_10_bytes]
	movdqa	xmm12, [dejar_primeros_10_bytes]
	movdqa	xmm13, [dejar_ultimos_6_bytes]
	
	
	; Calculo la cantidad de padding SRC
	; Es lo que me tengo de mover para irdesde el fin de una fila al inicio de la proxima.
	mov r10d, r8d
	sub r10d, r12d
	add r10d, 6					; R10D = Row_size_src - cols * 3 + 12
	
	; Calculo la cantidad de padding DST
	mov r11d, r9d
	sub r11d, r12d
	add r11d, 6 				; R11D = Row_size_dst - cols * 3 + 12
	
	; Calculo la distancia entre la columna 1 y la j-2
	mov r13d, r12d
	sub r13d, 6				; R13D = Cols*3 - 2*3
	
	; Voy a procesar una fila por iteracion, y son (filas - 4) las que tengo que procesar
	
	xor ebx, ebx
	sub ecx, 4
	
	.ciclo_columnas:
	
	cmp ebx, ecx
	je .fin_columnas
	
		movdqu xmm0, [RDI]
		movdqu xmm1, [RSI]
		
		pand xmm0, xmm10
		pand xmm1, xmm11
		
		por xmm0, xmm1
		
		movdqu [RSI], xmm0
		
		; Me paro cerca del fin de la fila.
		add RDI, R13
		add RSI, R13
		
		; Procuro no levantar padding y preservar los valores ya procesados.
		movdqu	xmm0, [RDI - 10]
		movdqu	xmm1, [RSI - 10]
		
		pand	xmm0, xmm13
		pand	xmm1, xmm12
		
		por	xmm0, xmm1
		
		movdqu [RSI - 10], xmm0
		
		; Incremento los punteros a la siguiente fila.
		add RDI, r10
		add RSI, r11
	
		; Incremento el contador
		inc ebx
		
		jmp .ciclo_columnas

	.fin_columnas:


    pop R15
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP
    ret	
 
