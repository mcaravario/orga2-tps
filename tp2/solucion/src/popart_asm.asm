global popart_asm

section .data

	ALIGN 16
	
	constante_611: DW	611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611, 611
	constante_458: DW	458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458, 458
	constante_305: DW	305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305, 305
	constante_152: DW	152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152, 152

	acomodar_suma_low:		DW	0, 0, 0xFFFF, 0, 0, 0xFFFF, 0, 0xFFFF
	acomodar_suma_high:		DW	0, 0, 0, 0xFFFF, 0, 0, 0xFFFF, 0
	borrar_ultimo_word:		DW  0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0xFFFF, 0 
	setear_0_B15:			DB	0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0
	setear_0_B0:			DB	0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	extender_cmp_a_3B:		DB	0x04, 0x04, 0x04, 0x0A, 0x0A, 0x0A, 0x0F, 0x0F, 0x0F, 0x06, 0x06, 0x06, 0x0C, 0x0C, 0x0C, 0xFF
	
	
	; Pixeles:
	; En la ultima posición pongo '0', pues es 'basura'.
	pixels_1:		DB	255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 0
	pixels_2:		DB	127, 0, 127, 127, 0, 127, 127, 0, 127, 127, 0, 127, 127, 0, 127, 0
	pixels_3:		DB	255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 0
	pixels_4:		DB	0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0
	pixels_5:		DB	0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0
	
	
section .text
;~ void popart_c    (
	;~ unsigned char *src,    rdi
	;~ unsigned char *dst,    rsi
	;~ int cols,			  rdx		
	;~ int filas,			  rcx	
	;~ int src_row_size,	  r8	
	;~ int dst_row_size)	  r9	 

popart_asm:

	push rbp
	mov rbp, rsp
	push rbx
	push r12
	push r13
	push r14
	push r15

	; Valores constantes para hacer la comparacion. Mascaras definidas en Words.
	movdqa xmm6, [constante_611]
	movdqa xmm7, [constante_458]
	movdqa xmm8, [constante_305]
	movdqa xmm9, [constante_152]
	
	; Mascaras
	movdqa xmm10, [acomodar_suma_low]
	movdqa xmm11, [acomodar_suma_high]
	movdqa xmm12, [borrar_ultimo_word]
	
	;Mascara para dejar solamente el primero byte.
	movdqu xmm13, [setear_0_B15]
	
	; Registro usado para el unpck
	pxor xmm14, xmm14


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
		cmp	EBX, EAX
		je	.fin
		
		cmp	ECX, R12D
		je .procesamiento_fin_fila
		
		; Procesamiento
		; B5 | R4 | G4 | B4 | R3 | G3 | B3 | R2 | G2 | B2 | R1 | G1 | B1 | R0 | G0 | B0 
		movdqu	xmm0, [RDI]			
		movdqu	xmm15, xmm0			; Copio el byte que pertenece al pixel incompleto.
		psrldq	xmm15, 15
		pslldq	xmm15, 15			; Dejo en 0 todos los bytes menos el de la posición 15.
		
		
		; Desempaqueto:
		movdqu	xmm1, xmm0
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
	
		
		; Aplico las comparaciones.
		; OBS: como la instrucción compara por mayor estricto, y yo quiero mayor o igual.
		; Decremento en 1 todos los valores umbrales, pues al ser naturales, 144 <= x sii x > 143.
		; Verificar razonamiento.
		
		
		; C O M P A R A C I O N
		; Esta máscara ordena y extiende los resultados de la comparación.
		; Recordar que la suma viene en desorden: S2 | S4  | S1 | 0  | S4  | S0 | 0  | 0
		; Aplicar PSHUFB con esa máscara dejaría los resultados de las comparaciones en orden (suma más alta en posición mas alta)
		; Y extendería a 3 Bytes cada resultado (que está en tamaño 2).
		movdqa xmm14, [extender_cmp_a_3B]
		
		; suma(i,j) > 152
		movdqu xmm2, xmm1
		pcmpgtw	xmm2, xmm9
		pshufb xmm2, xmm14
		
		; suma(i,j) > 305
		movdqu xmm3, xmm1
		pcmpgtw	xmm3, xmm8
		pshufb xmm3, xmm14
		
		; suma(i,j) > 458
		movdqu xmm4, xmm1
		pcmpgtw	xmm4, xmm7
		pshufb xmm4, xmm14
		
		; suma(i,j) > 611
		movdqu xmm5, xmm1
		pcmpgtw	xmm5, xmm6
		pshufb xmm5, xmm14
		
		movdqu	xmm0, xmm2
		pandn	xmm0, [pixels_1]		;suma < 153
		
		movdqu	xmm14, xmm3
		pandn	xmm14, xmm2				; 153 <= suma < 306 
		pand	xmm14, [pixels_2]
		
		movdqu	xmm2, xmm4
		pandn	xmm2, xmm3				; 306 <= suma < 459
		pand	xmm2, [pixels_3]
		
		movdqu	xmm3, xmm5
		pandn	xmm3, xmm4				; 459 <= suma < 612
		pand	xmm3, [pixels_4]
		
		pand	xmm5, [pixels_5]		; 612 <= suma
		
		
		; Juntos los resultados.
		; Son conjuntos disjuntos.
		
		por xmm0, xmm14
		por xmm2, xmm3
		por xmm0, xmm5
		por xmm0, xmm2
		
		; Ahora tengo que restaurar el último byte, que está guardado en xmm15.
		; Primero pongo en 0 el byte de la posición 15.
		pand	xmm0, xmm13
		por	xmm0, xmm15
		
		; Guardo el resultado en la matriz resultante.
		movdqu [RSI], xmm0
		
		; Seteo xmm14 en 0, pues lo uso para desempaquetar.
		pxor xmm14, xmm14
		
		; Avanzo punteros e iteradores.
		add RSI, 15
		add RDI, 15
		
		inc EBX
		inc ECX
		
		jmp .ciclo
		
		
		; Acá llegué si estoy en el último pedazo de una fila, a punto de leer padding.
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
		
			
			; Aplico las comparaciones.
			; OBS: como la instrucción compara por mayor estricto, y yo quiero mayor o igual.
			; Decremento en 1 todos los valores umbrales, pues al ser naturales, 144 <= x sii x > 143.
			; Verificar razonamiento.
			
			
			; C O M P A R A C I O N
			; Esta máscara ordena y extiende los resultados de la comparación.
			; Recordar que la suma viene en desorden: S2 | S4  | S1 | 0  | S4  | S0 | 0  | 0
			; Aplicar PSHUFB con esa máscara dejaría los resultados de las comparaciones en orden (suma más alta en posición mas alta)
			; Y extendería a 3 Bytes cada resultado (que está en tamaño 2).
			movdqa xmm14, [extender_cmp_a_3B]
			
			; suma(i,j) > 152
			movdqu xmm2, xmm1
			pcmpgtw	xmm2, xmm9
			pshufb xmm2, xmm14
			
			; suma(i,j) > 305
			movdqu xmm3, xmm1
			pcmpgtw	xmm3, xmm8
			pshufb xmm3, xmm14
			
			; suma(i,j) > 458
			movdqu xmm4, xmm1
			pcmpgtw	xmm4, xmm7
			pshufb xmm4, xmm14
			
			; suma(i,j) > 611
			movdqu xmm5, xmm1
			pcmpgtw	xmm5, xmm6
			pshufb xmm5, xmm14
			
			movdqu	xmm0, xmm2
			pandn	xmm0, [pixels_1]		;suma < 153
			
			movdqu	xmm14, xmm3
			pandn	xmm14, xmm2				; 153 <= suma < 306 
			pand	xmm14, [pixels_2]
			
			movdqu	xmm2, xmm4
			pandn	xmm2, xmm3				; 306 <= suma < 459
			pand	xmm2, [pixels_3]
			
			movdqu	xmm3, xmm5
			pandn	xmm3, xmm4				; 459 <= suma < 612
			pand	xmm3, [pixels_4]
			
			pand	xmm5, [pixels_5]		; 612 <= suma
			
			
			; Juntos los resultados.
			; Son conjuntos disjuntos.
			
			por xmm0, xmm14
			por xmm2, xmm3
			por xmm0, xmm5
			por xmm0, xmm2
			
			; Ahora tengo que restaurar el primer byte, que está guardado en xmm15.
			; Primero pongo en 0 el byte de la posición 0.
			pslldq	xmm0, 1
			pand	xmm0, [setear_0_B0]
			por	xmm0, xmm15
			
			; Guardo el resultado en la matriz resultante.
			movdqu [RSI], xmm0
			
			; Seteo xmm14 en 0, pues lo uso para desempaquetar.
			pxor xmm14, xmm14
			; FIN PROCESAMIENTO
			
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
