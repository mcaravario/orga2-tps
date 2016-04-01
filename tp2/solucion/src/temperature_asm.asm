global temperature_asm

section .data

	ALIGN 16
	
	mascara_dividir: DD 3.0,3.0,3.0,3.0
	
	pixels_1: DB 128,0,0,128,0,0,128,0,0,128,0,0,128,0,0,0
	pixels_2: DB 255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,0
	pixels_3: DB 255,255,0,255,255,0,255,255,0,255,255,0,255,255,0,0
	pixels_4: DB 0,255,255,0,255,255,0,255,255,0,255,255,0,255,255,0
	pixels_5: DB 0,0,255,0,0,255,0,0,255,0,0,255,0,0,255,0

	_0_32_0:	DB 0,32,0,0,32,0,0,32,0,0,32,0,0,32,0,0
	_f_0_0:		DB 0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0
	_0_0_f:		DB 0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0
	_96_96_96:	DB 96,96,96,96,96,96,96,96,96,96,96,96,96,96,96,0
	_0_160_0:	DB 0,160,0,0,160,0,0,160,0,0,160,0,0,160,0,0
	_0_f_0:		DB 0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0
	_0_0_224:	DB 0,0,224,0,0,224,0,0,224,0,0,224,0,0,224,0
	
	pshufb_mask: DB 0,0,0,1,1,1,2,2,2,3,3,3,15,15,15,0xFF
		
	mascara_32:  DW 31,31,31,31,31,31,31,31
	mascara_96:  DW 95,95,95,95,95,95,95,95
	mascara_160: DW 159,159,159,159,159,159,159,159
	mascara_224: DW 223,223,223,223,223,223,223,223
	
	acomodar_suma_low:		DW	0, 0, 0xFFFF, 0, 0, 0xFFFF, 0, 0xFFFF
	acomodar_suma_high:		DW	0, 0, 0, 0xFFFF, 0, 0, 0xFFFF, 0
	borrar_ultimo_word:		DW  0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0 
	
	multiplicar_4: DB 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
	
	limpiar_1: DB 0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0xFF,0,0,0
	
	
	mascara_unos: DD  0XFFFFFFFF,0XFFFFFFFF,0XFFFFFFFF,0XFFFFFFFF
	
section .text
;~ ;void temperature_asm(unsigned char *src, RDI
;~ ;              unsigned char *dst,		  RSI	
;~ ;              int filas,				  RDX
;~ ;              int cols,					  RCX
;~ ;              int src_row_size,			  R8	
;~ ;              int dst_row_size);		  R9	
;~ 
temperature_asm:
;~ 
	push RBP
	mov RBP, RSP
	push RBX
	push R12
	push R13
	push R14
	push R15   
    
    
	; Calculo iteraciones.
	; IDEA: Como proceso 15 B por iteración, necesito que la cantidad de iteraciones sea:
	;			[(cols*3 )/15] + [(cols*3) mod 15] * filas
	push RCX
	push RDX
	mov EAX, EDX
	mov R14D, 3
	mul R14D				; #Bytes válidos por fila.	
	mov R9D, EAX			; Me guardo este valor para unas líneas más adelante.
	sub R8D, EAX			; #Bytes de Padding.
	mov R14D, 15
	div R14D				; EAX <-- Cantidad de levantadas "estándar" por fila.
	mov R12D, EAX			; Alcanzando este valor, se que la próxima levanta es con padding.
	mov R13D, EDX			; R13D <-- #Bytes del borde.
	mul rcx					; Multiplico por el alto.
	; EAX <-- #Levantas "estándar" de la matriz.
	
	mov R14, 16
	sub R14, R13			; R14 <-- Retroceso necesario para no levantar padding. Parte alta de R13 en 0, pues hay un "mov R13D, EDX"
	
	mov R15D, R8D			; Parte alta en 0. Parte baja <-- #Bytes de padding.
	
	pop RDX
	pop RCX
	mov R8D, ECX			; R8D <-- Cant Filas
	
	xor	EBX, EBX			; Contador de iteraciones.
	xor	ECX, ECX			; Contador para saber si llegué al padding.
	
	add EAX, R8D

	;OBS: Los esquemas de los registros están de 127(izq) a 0(der). 
	
	
	
	.ciclo:
	
	
		movdqu xmm6, [mascara_32]
		movdqu xmm7, [mascara_96]
		movdqu xmm8, [mascara_160]
		movdqu xmm9, [mascara_224]
		
		movdqa xmm10, [acomodar_suma_low]
		movdqa xmm11, [acomodar_suma_high]
		movdqa xmm12, [borrar_ultimo_word]
	
		cmp	EBX, EAX
		je	.fin
		
		cmp	ECX, R12D
		je .procesamiento_fin_fila
		
		; Procesamiento
		; B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2 | G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0 
		movdqu	xmm0, [RDI]			
		
		; Desempaqueto:
		movdqu	xmm1, xmm0
		pxor xmm14,xmm14
		punpckhbw	xmm1, xmm14		; Hihg	B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2 
		punpcklbw	xmm0, xmm14		; Low	G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0  
		
		; S U M A
		; Preparo la parte baja (Low). (Me sirven las posiciones 7, 5 y 2)
		movdqu	xmm2, xmm0
		movdqu	xmm3, xmm0
		pslldq	xmm2, 2				; B2 | R1 | G1 | B1 | R0 | G0 | B0| 0
		pslldq	xmm3, 4				; R1 | G1 | B1 | R0 | G0 | B0 | 0 | 0
	
		; Quiero quedarme con el primer word en la última posición, y dejar los demás en 0.
		movdqu	xmm4, xmm1
		pslldq	xmm4, 14			;  R2 | 0 | 0 | 0 | 0 | 0  | 0 | 0

		
		; Quiero dejar B2 en la última posición de xmm3.
		pand	xmm3, xmm12			; 0  | G1 | B1 | R0 | G0 | B0 | 0  | 0
		por	xmm3, xmm4				; R2 | G1 | B1 | R0 | G0 | B0 | 0  | 0
		
		; Sumo los 3 registros.		  G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0
		paddw	xmm2, xmm0			; B2 | R1 | G1 | B1 | R0 | G0 | B0 | 0
		paddw	xmm2, xmm3			; R2 | G1 | B1 | R0 | G0 | B0 | 0  | 0
		; G2 + R2 + B2 | ... | B1 + G1 + R1 | ... | ... | B0 + G0 + R0 | ... | 0
		
		
		
		; Preparo la parte alta (High).  (Me sirven las posiciones 6 y 3)
		movdqu	xmm3, xmm1
		movdqu	xmm4, xmm1			; B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2
		pslldq	xmm3, 2				; R4 | G4 | B4 | R3 | G3 | B3 | R2 | 0
		pslldq	xmm4, 4				; G4 | B4 | R3 | G3 | B3 | R2 | 0  | 0	

		
		paddw	xmm1, xmm3
		paddw	xmm1, xmm4			; ... | B4 + G4 + R4 | ... | ... | B3 + G3 + R3 | ... | ... | ...
	
		; Muevo los resultados de la suma a 1 sólo registro. (5x2) < 16
		; Previamente dejo en 0 las posiciones que no tienen resultados.
		pand	xmm2, xmm10			; S2 | 0  | S1 | 0  | 0  | S0 | 0  | 0 
		pand	xmm1, xmm11			; 0  | S4 | 0  | 0  | S3 | 0  | 0  | 0
		
		por	xmm1, xmm2				; S2 | S4  | S1 | 0  | S3 | S0 | 0  | 0 


		; Ahora tengo que extender de word a double, para luego convertir a punto flotante y no perder precision en la division.
		
		pxor xmm14,xmm14
		movdqu xmm0,xmm1          	;xmm0 = ; S2 | S4  | S1 | 0  | S3 | S0 | 0  | 0 
		
		
		punpcklwd xmm0,xmm14		; xmm0 = S3 | S0 | 0 | 0
		
		punpckhwd xmm1,xmm14		; xmm1 = S2 | S4 | S1| 0
		
		cvtdq2ps xmm0,xmm0				;mismos valores pero en punto flotante de precision simple
		cvtdq2ps xmm1,xmm1				;mismos valores pero en punto flotante de precision simple
		
		divps xmm0,[mascara_dividir]		; xmm0 = S3/3 | S0/3 | 0 | 0
		
		divps xmm1,[mascara_dividir]		; xmm1 = S2/3 | S4/3 | S1/3| 0
		
		;; Convierto a enteros con truncamiento, es decir dejo la parte entera.
		;; REDEONDE MAL, REDONDEA PARA ARRIBA, YO QUIERO QUE REDONDEE PARA ABAJO
		cvttps2dq xmm0,xmm0			; xmm0 = T3 | T0 | 0 | 0 
		cvttps2dq xmm1,xmm1			; xmm1 = T2 | T4 | T1| 0
		
		;; Ordeno los parametros de los registros
		 
		movdqu xmm2,xmm0				;xmm2 = T3 | T0 | 0 | 0 
		pslldq xmm2,4					;xmm2 = T0 | 0  | 0 | 0
		psrldq xmm2,12					;xmm2 = 0 | 0  | 0 | T0
		
		movdqu xmm3,xmm1 				;xmm3 = T2 | T4 | T1| 0
		pslldq xmm3,8					;xmm3 = T1 | 0  | 0	| 0
		psrldq xmm3,8					;xmm3 = 0  | 0 | T1 | 0


		movdqu xmm4,xmm1				; xmm4 = T2 | T4 | T1| 0
		psrldq	xmm4,12					; xmm4 = 0 | 0 | T2| 0
		pslldq xmm4,8					; xmm4 = 0 | T2 | 0 | 0 
		
		movdqu xmm5,xmm0				; xmm5 = T3 | T0 | 0 | 0 
		psrldq xmm5,12					; xmm5 = 0 | 0 | 0 | T3 
		pslldq xmm5,12					; xmm5 = T3 | 0 | 0 | 0
		
		
		por xmm2,xmm3
		por xmm2,xmm4
		por xmm2,xmm5					;xmm2 = T3 | T2  | T1 | T0
		
		packusdw xmm2,xmm2
		packuswb xmm2,xmm2				
		
		pslldq xmm1,4
		psrldq xmm1,12					;xmm1 = 0 | 0 | 0 | T4
		
		;; Dejo en la parte alta el byte correspondiente a t4 para luego hacer or con el registro xmm2 y dejar todo en un solo registro
		pxor xmm13,xmm13
		packusdw xmm1,xmm13
		packuswb xmm1,xmm13				
		
		;; lo shifteo ya que son entero sin signo que ocupan un byte, por lo tanto entrara en el registro
		pslldq xmm1,15					;xmm1 = t4 | 0 | 0 | 0
		pslldq xmm2, 1
		psrldq xmm2, 1					; Limpio el byte mas significativo
		
		por xmm2,xmm1					;xmm2 =  t4 | 0 | 0 | t3 | 0 | 0 | 0 | t2 | 0 | 0 | 0 | t1 | 0 | 0 | 0 | t0		(Los ceros son en realidad basura, pero no me interesa, pues el pshufb los pisa)
		
		;; Acomodo los bytes para compararlos 
		
		movdqu xmm1, [pshufb_mask]
		pshufb xmm2, xmm1				;xmm2 =  0 | t4 | t4 | t4 | t3 | t3 | t3 | t2 | t2 | t2 | t1 | t1 | t1 | t0 | t0 | t0
		
		
		;; Necesito hacer las comparaciones en words, pues la comparacion es con signed ints.
		pmovzxbw xmm10, xmm2			; xmm10 =  t2 | t2 | t1 | t1 | t1 | t0 | t0 | t0
		psrldq xmm2, 8
		pmovzxbw xmm2, xmm2				;xmm2 =  0 | t4 | t4 | t4 | t3 | t3 | t3 | t2 
		
		; Salvo xmm10 para mas adelante
		movdqa xmm14, xmm10
		
		;; Hasta aca esta bien
		;; Comparaciones
		
		movdqa xmm1, xmm2
		movdqa xmm3,xmm10
		pcmpgtw xmm3, xmm6  			;xmm3 = mayores o igual a 32 (Baja)
		pcmpgtw xmm1, xmm6				;xmm1 = mayores o igual a 32 (Alta)
		
		movdqa xmm6, xmm10
		movdqa xmm4,xmm2			
		pcmpgtw xmm6,xmm7				; xmm6 = mayores o iguales a 96 (Baja)
		pcmpgtw xmm4,xmm7				; xmm4 = mayores o iguales a 96	(Alta)

		movdqa xmm7, xmm10
		movdqa xmm5,xmm2
		pcmpgtw xmm7, xmm8				;xmm7 = mayores o iguales a 160 (Baja)
		pcmpgtw xmm5, xmm8				;xmm5 = mayores o iguales a 160	(Alta)
		
		movdqa xmm8, xmm10
		movdqu xmm13,xmm2
		pcmpgtw xmm10,xmm9				;xmm10 = mayores o iguales a 224 (Baja)
		pcmpgtw xmm13,xmm9				;xmm13 = mayores o iguales a 224 (Alta)

		; Empaqueto los resultados de las comparaciones
		packsswb xmm3, xmm1				; mayores 32
		packsswb xmm6, xmm4				; mayores 96
		packsswb xmm7, xmm5				; mayores 160
		packsswb xmm10, xmm13			; mayores 224
		
		; Empaqueto t
		packuswb xmm14, xmm2
		movdqa xmm2, xmm14
		
		movdqu xmm1, [mascara_unos]
		
		; Genero las "mascaras" disjuntas
		; Menores 32
		movdqa xmm0, xmm3
		pandn xmm0, xmm1			; OJO que el byte 15 (+sig) queda en FF
		
		; Mayores 32, menores 96
		movdqa xmm14, xmm6
		pandn xmm6, xmm1
		pand xmm6, xmm3
		movdqa xmm12, xmm6
		
		; Menores 160, mayores a 96
		movdqa xmm8, xmm7
		pandn xmm8, xmm1
		pand xmm8, xmm14
		movdqa xmm11, xmm8
		
		; Menores a 224, mayores a 160
		movdqa xmm8, xmm10
		pandn xmm8, xmm1
		pand xmm8, xmm7
		movdqa xmm13, xmm8
		
		movdqa xmm14, xmm10
		movdqa xmm10, xmm13
		movdqa xmm13, xmm14
		
		; Mayores a 224
		; Ya esta  en xmm10

		; xmm0  menores a 32
		; xmm12 menores a 96 y mayores a 32 
		; xmm11 menores a 160 y mayores a 96
		; xmm13 menores a 224 y mayores a 160
		; xmm10 mayores a 224
		; xmm2 		t

		;;;; Primer Mascara ;;;  XMM0
		movdqa xmm8, xmm0
		movdqa xmm3,[pixels_1]			;xmm3 = 128,0,0,128,0,0,128,0,0,128,0,0,128,0,0,0 (esta de 0 a 127)
		pand xmm0,  xmm2				;xmm0 = quedan los t menores a 32  
		pand xmm0,[limpiar_1]			;xmm0 = t1,0,0
		psllw xmm0,2					;puedo hacer esto porque quedan bien las fronteras al shiftear de a words	
		paddb xmm0,xmm3
		pand xmm0, xmm8
		
		
		;;;; Segunda Mascara;;;  XMM12
		movdqa xmm8, xmm12
		movdqa xmm3, [pixels_2]			;xmm3 = 255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,0 (esta de 0 a 127)
		movdqa xmm6, [_0_32_0]
		pand xmm6, xmm12
		pand xmm12,xmm2					;quedan los t que cumplen que son menores a 96 y mayores a 32
		pand xmm12, [_0_f_0]			; deja los t' que me importa
		psubb xmm12, xmm6
		psllw xmm12,2
		por xmm12, xmm3				; Junto los 255 con los (t-32)*4
		pand xmm12, xmm8
		
		;;;; Tercer Mascara ;;;  XMM11
		movdqa xmm8, xmm11
		movdqa xmm3, [pixels_3]
		
		;Genero t'
		movdqa xmm6, xmm2
		psubb xmm6, [_96_96_96]
		pand xmm6, xmm11
		movdqa xmm14, xmm6
		pand xmm14, [_f_0_0]
		pand xmm6, [_0_0_f]
		psllw xmm6, 2
		psllw xmm14, 2

		
		; Calculo
		psubb xmm3, xmm14
		paddb xmm3, xmm6
		movdqa xmm11, xmm3
		
		; Aplico Filtro
		pand xmm11, xmm8
			
		
		;;;; Cuarta Mascara ;;; XMM10
		movdqa xmm8, xmm10
		
		movdqa xmm6, [pixels_4]
		pand xmm10, xmm2
		psubb xmm10, [_0_160_0]
		pand xmm10, [_0_f_0]
		psllw xmm10, 2				; EL SHIFT ROMPE REPRESENTACION
		psubb xmm6, xmm10
		movdqa xmm10, xmm6
		
		pand xmm10, xmm8
		
		;;; Quinta Mascara ;;; XMM13
		movdqa xmm8, xmm13
		
		movdqa xmm6, [pixels_5]
		pand xmm13, xmm2
		psubb xmm13, [_0_0_224]
		pand xmm13, [_0_0_f]
		psllw xmm13, 2
		psubb xmm6, xmm13
		movdqa xmm13, xmm6
		
		pand xmm13, xmm8
		
		
		;; Juntos Resultados Disjuntos
		por xmm0, xmm13
		por xmm0, xmm12
		por xmm0, xmm11
		por xmm0, xmm10
		
		movdqu [RSI], xmm0
		
		; Avanzo punteros e iteradores.
		add RSI, 15
		add RDI, 15
		
		inc EBX
		inc ECX
		
		jmp .ciclo
		
	.procesamiento_fin_fila:
	
				sub RDI, R14
				sub RSI, R14
				; Procesamiento
				; R4 | G4 | B4 | R3 | G3 | B3 | R2 | G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0 | B(-1)
				movdqu	xmm0, [RDI]			
				movdqu	xmm15, [RSI]		; Copio el byte de la posición 0. Pues es de un pixel que ya procesé.
				pslldq	xmm15, 15
				psrldq	xmm15, 15			; Dejo en 0 todos los bytes, menos el de la posición 0.

				;Quiero que mis datos "empiecen" desde el byte más bajo.
				psrldq	xmm0, 1				; 0 | R4 | G4 | B4 | R3 | G3 | B3 | R2 | G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0 
			

				; Desempaqueto:
				movdqu	xmm1, xmm0
				pxor xmm14,xmm14
				punpckhbw	xmm1, xmm14		; Hihg	B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2 
				punpcklbw	xmm0, xmm14		; Low	G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0  

				; S U M A
				; Preparo la parte baja (Low). (Me sirven las posiciones 7, 5 y 2)
				movdqu	xmm2, xmm0
				movdqu	xmm3, xmm0
				pslldq	xmm2, 2				; B2 | R1 | G1 | B1 | R0 | G0 | B0| 0
				pslldq	xmm3, 4				; R1 | G1 | B1 | R0 | G0 | B0 | 0 | 0

				; Quiero quedarme con el primer word en la última posición, y dejar los demás en 0.
				movdqu	xmm4, xmm1
				pslldq	xmm4, 14			;  R2 | 0 | 0 | 0 | 0 | 0  | 0 | 0


				; Quiero dejar B2 en la última posición de xmm3.
				pand	xmm3, xmm12			; 0  | G1 | B1 | R0 | G0 | B0 | 0  | 0
				por	xmm3, xmm4				; R2 | G1 | B1 | R0 | G0 | B0 | 0  | 0

				; Sumo los 3 registros.		  G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0
				paddw	xmm2, xmm0			; B2 | R1 | G1 | B1 | R0 | G0 | B0 | 0
				paddw	xmm2, xmm3			; R2 | G1 | B1 | R0 | G0 | B0 | 0  | 0
				; G2 + R2 + B2 | ... | B1 + G1 + R1 | ... | ... | B0 + G0 + R0 | ... | 0



				; Preparo la parte alta (High).  (Me sirven las posiciones 6 y 3)
				movdqu	xmm3, xmm1
				movdqu	xmm4, xmm1			; B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2
				pslldq	xmm3, 2				; R4 | G4 | B4 | R3 | G3 | B3 | R2 | 0
				pslldq	xmm4, 4				; G4 | B4 | R3 | G3 | B3 | R2 | 0  | 0	


				paddw	xmm1, xmm3
				paddw	xmm1, xmm4			; ... | B4 + G4 + R4 | ... | ... | B3 + G3 + R3 | ... | ... | ...

				; Muevo los resultados de la suma a 1 sólo registro. (5x2) < 16
				; Previamente dejo en 0 las posiciones que no tienen resultados.
				pand	xmm2, xmm10			; S2 | 0  | S1 | 0  | 0  | S0 | 0  | 0 
				pand	xmm1, xmm11			; 0  | S4 | 0  | 0  | S3 | 0  | 0  | 0

				por	xmm1, xmm2				; S2 | S4  | S1 | 0  | S3 | S0 | 0  | 0 


				; Ahora tengo que extender de word a double, para luego convertir a punto flotante y no perder precision en la division.

				pxor xmm14,xmm14
				movdqu xmm0,xmm1          	;xmm0 = ; S2 | S4  | S1 | 0  | S3 | S0 | 0  | 0 


				punpcklwd xmm0,xmm14		; xmm0 = S3 | S0 | 0 | 0

				punpckhwd xmm1,xmm14		; xmm1 = S2 | S4 | S1| 0

				cvtdq2ps xmm0,xmm0				;mismos valores pero en punto flotante de precision simple
				cvtdq2ps xmm1,xmm1				;mismos valores pero en punto flotante de precision simple

				divps xmm0,[mascara_dividir]		; xmm0 = S3/3 | S0/3 | 0 | 0

				divps xmm1,[mascara_dividir]		; xmm1 = S2/3 | S4/3 | S1/3| 0

				;; Convierto a enteros con truncamiento, es decir dejo la parte entera.
				;; REDEONDE MAL, REDONDEA PARA ARRIBA, YO QUIERO QUE REDONDEE PARA ABAJO
				cvttps2dq xmm0,xmm0			; xmm0 = T3 | T0 | 0 | 0 
				cvttps2dq xmm1,xmm1			; xmm1 = T2 | T4 | T1| 0

				;; Ordeno los parametros de los registros

				movdqu xmm2,xmm0				;xmm2 = T3 | T0 | 0 | 0 
				pslldq xmm2,4					;xmm2 = T0 | 0  | 0 | 0
				psrldq xmm2,12					;xmm2 = 0 | 0  | 0 | T0

				movdqu xmm3,xmm1 				;xmm3 = T2 | T4 | T1| 0
				pslldq xmm3,8					;xmm3 = T1 | 0  | 0	| 0
				psrldq xmm3,8					;xmm3 = 0  | 0 | T1 | 0


				movdqu xmm4,xmm1				; xmm4 = T2 | T4 | T1| 0
				psrldq	xmm4,12					; xmm4 = 0 | 0 | T2| 0
				pslldq xmm4,8					; xmm4 = 0 | T2 | 0 | 0 

				movdqu xmm5,xmm0				; xmm5 = T3 | T0 | 0 | 0 
				psrldq xmm5,12					; xmm5 = 0 | 0 | 0 | T3 
				pslldq xmm5,12					; xmm5 = T3 | 0 | 0 | 0


				por xmm2,xmm3
				por xmm2,xmm4
				por xmm2,xmm5					;xmm2 = T3 | T2  | T1 | T0

				packusdw xmm2,xmm2
				packuswb xmm2,xmm2				

				pslldq xmm1,4
				psrldq xmm1,12					;xmm1 = 0 | 0 | 0 | T4

				;; Dejo en la parte alta el byte correspondiente a t4 para luego hacer or con el registro xmm2 y dejar todo en un solo registro
				pxor xmm13,xmm13
				packusdw xmm1,xmm13
				packuswb xmm1,xmm13				

				;; lo shifteo ya que son entero sin signo que ocupan un byte, por lo tanto entrara en el registro
				pslldq xmm1,15					;xmm1 = t4 | 0 | 0 | 0
				pslldq xmm2, 1
				psrldq xmm2, 1					; Limpio el byte mas significativo

				por xmm2,xmm1					;xmm2 =  t4 | 0 | 0 | t3 | 0 | 0 | 0 | t2 | 0 | 0 | 0 | t1 | 0 | 0 | 0 | t0		(Los ceros son en realidad basura, pero no me interesa, pues el pshufb los pisa)

				;; Acomodo los bytes para compararlos 

				movdqu xmm1, [pshufb_mask]
				pshufb xmm2, xmm1				;xmm2 =  0 | t4 | t4 | t4 | t3 | t3 | t3 | t2 | t2 | t2 | t1 | t1 | t1 | t0 | t0 | t0


				;; Necesito hacer las comparaciones en words, pues la comparacion es con signed ints.
				pmovzxbw xmm10, xmm2			; xmm10 =  t2 | t2 | t1 | t1 | t1 | t0 | t0 | t0
				psrldq xmm2, 8
				pmovzxbw xmm2, xmm2				;xmm2 =  0 | t4 | t4 | t4 | t3 | t3 | t3 | t2 

				; Salvo xmm10 para mas adelante
				movdqa xmm14, xmm10

				;; Hasta aca esta bien
				;; Comparaciones

				movdqa xmm1, xmm2
				movdqa xmm3,xmm10
				pcmpgtw xmm3, xmm6  			;xmm3 = mayores o igual a 32 (Baja)
				pcmpgtw xmm1, xmm6				;xmm1 = mayores o igual a 32 (Alta)

				movdqa xmm6, xmm10
				movdqa xmm4,xmm2			
				pcmpgtw xmm6,xmm7				; xmm6 = mayores o iguales a 96 (Baja)
				pcmpgtw xmm4,xmm7				; xmm4 = mayores o iguales a 96	(Alta)

				movdqa xmm7, xmm10
				movdqa xmm5,xmm2
				pcmpgtw xmm7, xmm8				;xmm7 = mayores o iguales a 160 (Baja)
				pcmpgtw xmm5, xmm8				;xmm5 = mayores o iguales a 160	(Alta)

				movdqa xmm8, xmm10
				movdqu xmm13,xmm2
				pcmpgtw xmm10,xmm9				;xmm10 = mayores o iguales a 224 (Baja)
				pcmpgtw xmm13,xmm9				;xmm13 = mayores o iguales a 224 (Alta)

				; Empaqueto los resultados de las comparaciones
				packsswb xmm3, xmm1				; mayores 32
				packsswb xmm6, xmm4				; mayores 96
				packsswb xmm7, xmm5				; mayores 160
				packsswb xmm10, xmm13			; mayores 224

				; Empaqueto t
				packuswb xmm14, xmm2
				movdqa xmm2, xmm14

				movdqu xmm1, [mascara_unos]

				; Genero las "mascaras" disjuntas
				; Menores 32
				movdqa xmm0, xmm3
				pandn xmm0, xmm1			; OJO que el byte 15 (+sig) queda en FF

				; Mayores 32, menores 96
				movdqa xmm14, xmm6
				pandn xmm6, xmm1
				pand xmm6, xmm3
				movdqa xmm12, xmm6

				; Menores 160, mayores a 96
				movdqa xmm8, xmm7
				pandn xmm8, xmm1
				pand xmm8, xmm14
				movdqa xmm11, xmm8

				; Menores a 224, mayores a 160
				movdqa xmm8, xmm10
				pandn xmm8, xmm1
				pand xmm8, xmm7
				movdqa xmm13, xmm8

				movdqa xmm14, xmm10
				movdqa xmm10, xmm13
				movdqa xmm13, xmm14

				; Mayores a 224
				; Ya esta  en xmm10

				; xmm0  menores a 32
				; xmm12 menores a 96 y mayores a 32 
				; xmm11 menores a 160 y mayores a 96
				; xmm13 menores a 224 y mayores a 160
				; xmm10 mayores a 224
				; xmm2 		t

				;;;; Primer Mascara ;;;  XMM0
				movdqa xmm8, xmm0
				movdqa xmm3,[pixels_1]			;xmm3 = 128,0,0,128,0,0,128,0,0,128,0,0,128,0,0,0 (esta de 0 a 127)
				pand xmm0,  xmm2				;xmm0 = quedan los t menores a 32  
				pand xmm0,[limpiar_1]			;xmm0 = t1,0,0
				psllw xmm0,2					;puedo hacer esto porque quedan bien las fronteras al shiftear de a words	
				paddb xmm0,xmm3
				pand xmm0, xmm8


				;;;; Segunda Mascara;;;  XMM12
				movdqa xmm8, xmm12
				movdqa xmm3, [pixels_2]			;xmm3 = 255,0,0,255,0,0,255,0,0,255,0,0,255,0,0,0 (esta de 0 a 127)
				movdqa xmm6, [_0_32_0]
				pand xmm6, xmm12
				pand xmm12,xmm2					;quedan los t que cumplen que son menores a 96 y mayores a 32
				pand xmm12, [_0_f_0]			; deja los t' que me importa
				psubb xmm12, xmm6
				psllw xmm12,2
				por xmm12, xmm3				; Junto los 255 con los (t-32)*4
				pand xmm12, xmm8

				;;;; Tercer Mascara ;;;  XMM11
				movdqa xmm8, xmm11
				movdqa xmm3, [pixels_3]

				;Genero t'
				movdqa xmm6, xmm2
				psubb xmm6, [_96_96_96]
				pand xmm6, xmm11
				movdqa xmm14, xmm6
				pand xmm14, [_f_0_0]
				pand xmm6, [_0_0_f]
				psllw xmm6, 2
				psllw xmm14, 2


				; Calculo
				psubb xmm3, xmm14
				paddb xmm3, xmm6
				movdqa xmm11, xmm3

				; Aplico Filtro
				pand xmm11, xmm8


				;;;; Cuarta Mascara ;;; XMM10
				movdqa xmm8, xmm10

				movdqa xmm6, [pixels_4]
				pand xmm10, xmm2
				psubb xmm10, [_0_160_0]
				pand xmm10, [_0_f_0]
				psllw xmm10, 2				; EL SHIFT ROMPE REPRESENTACION
				psubb xmm6, xmm10
				movdqa xmm10, xmm6

				pand xmm10, xmm8

				;;; Quinta Mascara ;;; XMM13
				movdqa xmm8, xmm13

				movdqa xmm6, [pixels_5]
				pand xmm13, xmm2
				psubb xmm13, [_0_0_224]
				pand xmm13, [_0_0_f]
				psllw xmm13, 2
				psubb xmm6, xmm13
				movdqa xmm13, xmm6

				pand xmm13, xmm8


				;; Juntos Resultados Disjuntos
				por xmm0, xmm13
				por xmm0, xmm12
				por xmm0, xmm11
				por xmm0, xmm10


				; Seteo en 0 los 15 bytes mas significativos, para hacer un OR con el resultado
				pslldq xmm15, 15
				psrldq xmm15, 15
	
				; Seteo en 0 el byte 0, para poner el byte salvado en xmm15				
				pslldq xmm0, 1

				por xmm0, xmm15

				movdqu [RSI], xmm0

				
				
				add RDI, 16
				add RSI, 16
				
				add RDI, R15
				add RSI, R15
				
				xor ECX, ECX
				inc EBX
				
				jmp .ciclo


	.fin:

	pop R15
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP	
    ret
