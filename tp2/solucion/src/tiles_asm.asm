global tiles_asm

section .data

ALIGN 16

section .text


;; Asegurarse de no necesitar RDX, pues lo piso con la multiplicacion
;; Calcula el puntero en base a los offset y a los contadores de src
;;			(offsety + i_s)*src_row_size + (offsetx + j_s)
;; 			los i_s y j_s son parametros de entrada
;;  Deja el offset en EAX
;; Usa eax y R14


%macro __calcular_offset_SRC__ 2
	mov R14D, [RBP + 40]
	add R14D, %1
	
	push RDX
	mov eax, R8D
	mul R14D
	pop RDX
	
	add eax, [RBP + 32]
	add eax, %2	
%endmacro


; i_d(1) j_d(2)
; Usa eax y R14
%macro __calcular_offset_DST__ 2
	push RDX
	mov R14D, R9D
	mov eax, %1
	
	mul R14D
	pop RDX
	add eax, %2
%endmacro


; Setea los flags de comparacion para saber si es el final de la submatriz, mismo procedimiento que con la matriz grande
; Usa R14
%macro __check_fin_fila_submatriz__ 0
	mov R14D, [RBP+16]			; R14D = TAM_X
	sub R14D, 16				; R14D = TAM_X - 16
	cmp R10D, R14D
%endmacro

; Multiplica [RBP + imm] por 3 y lo deja en [RBP + imm]
; Usa eax y R14
%macro __mul_pila_3__ 1
	mov eax, [RBP + %1]
    mov R15D, 3
    mul R15D
    mov [RBP + %1], eax
%endmacro


; Reinicia el contador de bytes de la columna y avanza el de fila (DST)
%macro __reiniciar_j_avanzar_i_DST__ 0
	xor R12D, R12D
	inc R11D
%endmacro

;void tiles_asm(
	;~ unsigned char *src, 	RDI
	;~ unsigned char *dst, 	RSI
	;~ int cols,			RDX
	;~ int filas,			RCX
	;~ int src_row_size,	R8
	;~ int dst_row_size,	R9
	;~ int tamx,			pila (primero en popearse)
	;~ int tamy,			pila
	;~ int offsetx,			pila
	;~ int offsety)			pila (ultimo en popearse)

tiles_asm:
 	push RBP
	mov RBP, RSP
	push RBX
	push R12
	push R13
	push R14
	push R15   
    
    push RDX
    
    ; Multiplico los offsets y tamaños por 3, para tenerlo en bytes
    
    __mul_pila_3__ 16
	__mul_pila_3__ 32

    pop RDX
    
	; Contadores (en bytes)
	xor ebx, ebx			; i_s		
	xor R10D, R10D			; j_s
	
	xor R11D, R11D			; i_d
	xor R12D, R12D			; j_d
	
	; Registros para cuentas auxiliares
	xor eax, eax
	xor R14D, R14D
	xor R15D, R15D
	
	; Calculo cols*3
	mov R15D, edx
	
	mov R13D, edx
	mov eax, 3
	mul R13D
	mov edx, R15D
	
	mov R13D, eax			; R13D <-- cols*3

	.ciclo:
		
		cmp R11D, ecx
		je .fin_ciclo
		
		mov R14D, R13D
		sub R14D, 16
		
		cmp R12D, R14D		; j_d < cols*3 - 16
		jge .fin_fila_grande
		
		; Tengo que ver si estoy en el fin de la fila de la submatriz
		__check_fin_fila_submatriz__				; Deja en R14D = TAM_X - 16
		jle .no_fin_fila_chica_no_fin_fila_grande	; Chequear si tendria que ser solo less
		
; CASO 1.A:
		;		* No Fin Fila Grande
		;		* Fin Fila Chica
		
		; Estoy en fin de fila de la submatriz, pero no de la destino. O sea, tengo suficiente espacio para escribir, pero no para leer
		; Tengo que leer "atrasado" y despues shiftear a la derecha y avanzar los contadores en la cantidad correcta
		; Puedo pisar DST
		
		; Levanto desde TAM_X - 16
		mov		R15D, R14D
		__calcular_offset_SRC__ ebx, R15D
		movdqu xmm0, [RDI + RAX]
		
		; Calculo la #bytes que escribo en DST (lo que leo de SRC)
		mov R14D, [RBP + 16]
		sub R14D, R10D
		mov R15D, 16
		sub R15D, R14D
		
		; Retrocedo para escribir
		sub R12D, R15D
				
		__calcular_offset_DST__ R11D, R12D
		movdqu	[RSI + RAX], xmm0
		
		; Reinicio j_s, sin incrementar la fila
		xor R10D, R10D
		
		
		; Avanzo j_d en 16
		add R12D, 16
		
		jmp .ciclo
		
		
	.fin_fila_grande:
; CASO 2:
		;		* Fin Fila Grande
		;		* (A determinar) Fin Fila Chica 
		; Estoy en el fin de fila de la matriz. Esto significa que no puedo escribir 16 bytes, o sea que tengo que retroceder.
		; Pero cuando retrocedo, tengo que salvar los datos copiados en destino, para no pisarlos al momento de copiar.
		; Como termino de escribir la fila, tengo que reiniciar ambos, sin importar si es el fin de fila de la submatriz. 
		

		__check_fin_fila_submatriz__						; Deja en R14D = TAM_X - 16
		jle .no_fin_fila_chica_fin_fila_grande

; CASO 2.A:
		;		* Fin Fila Grande
		;		* Fin Fila Chica
		; Este es el caso mas complicado, pues no tengo suficiente espacio para escribir ni para copiar.
		
		; Calculo S (bytes que quedan en fuente)
		mov R15D, [RBP + 16]
		sub R15D, R10D
		
		; Calculo D (bytes que quedan en destino)
		mov eax, R13D
		sub eax, R12D
		
		cmp R15D, eax
		je .caso_facil
		
		jg .destino_menor
		
		; CASO: S es menor que D
			mov R14D, 16
			sub R14D, R15D
			
			sub R10D, R14D
			sub R12D, R14D
			
			__calcular_offset_SRC__ ebx, R10D
			movdqu xmm0, [RDI + RAX]
			
			__calcular_offset_DST__ R11D, R12D
			movdqu [RSI + RAX], xmm0
		
			; Reinicio j_s, pero no incremento fila
			xor R10D, R10D
			
			
			; Avanzo en R15D, que es lo que escribi
			add R12D, 16
			
			jmp .ciclo
		
		
		.caso_facil:
		
			; Calculo retroceso, los dos al fin de fila
			
			mov R12D, R13D
			sub R12D, 16
			
			mov R10D, [RBP + 16]
			sub R10D, 16
		
			__calcular_offset_SRC__ ebx, R10D
			movdqu xmm0, [RDI + RAX]
			
			__calcular_offset_DST__ R11D, R12D
			movdqu [RSI + RAX], xmm0
			
			
			; Reinicio ambos contadores
			call __reiniciar_j_avanzar_i_SRC__
			__reiniciar_j_avanzar_i_DST__
			
			jmp .ciclo
			
		
		.destino_menor:
			mov R14D, 16
			sub R14D, eax
			
			sub R10D, R14D
			sub R12D, R14D
			
			__calcular_offset_SRC__ ebx, R10D
			movdqu xmm0, [RDI + RAX]
				
			__calcular_offset_DST__ R11D, R12D
			movdqu [RSI + RAX], xmm0
			
			__reiniciar_j_avanzar_i_DST__
			call __reiniciar_j_avanzar_i_SRC__
			
			jmp .ciclo
		
	
	.no_fin_fila_chica_fin_fila_grande:		
; CASO 2.B:
		;		* Fin Fila Grande
		;		* No Fin Fila Chica
		; En este caso tengo espacio para leer los datos fuente, pero no para escribirlos.
		
				
		; Calculo cuantos bytes voy a escribir. (cols*3 - #bytes_recorridos)
		mov R15D, R13D
		sub R15D, R12D
		
		mov R14D, 16
		sub R14D, R15D
		
		push R14			; #retroceso_en_destino
		
		sub R12D, R14D
		
		__calcular_offset_DST__ R11D, R12D
		movdqu xmm0, [RSI + RAX]

		
		; Limpio los bytes altos para luego hacer el OR.
		call __pslldq__				; xmm0, R15D		(me resguarda R15)
		call __psrldq__ 			; xmm0, R15D
		
		; Calculo cuantos bytes tengo que shiftear al xmm SRC.
		movdqa xmm1, xmm0
		__calcular_offset_SRC__ ebx, R10D
		movdqu xmm0, [RDI + RAX]
		
				
		pop R14
		
		mov R15D, R14D
		
		call __pslldq__				; xmm0, R15D
		
		por xmm0, xmm1
		__calcular_offset_DST__ R11D, R12D
		movdqu [RSI + RAX], xmm0
		
		; SOLO LA LLAMO EN FIN DE FILA DST
		call __reiniciar_j_avanzar_i_SRC__
		__reiniciar_j_avanzar_i_DST__
		
		jmp .ciclo
		
		.no_fin_fila_chica_no_fin_fila_grande:
; CASO 1.A:
		;		* No Fin Fila Grande
		;		* No Fin Fila Chica
		; Este caso es el mas sencillo, simplemente leo en SRC 16B y los escribo en DST, avanzando en 16 bytes los contadores de columna.

		__calcular_offset_SRC__ ebx, R10D
		movdqu xmm0, [RDI + RAX]

		__calcular_offset_DST__ R11D, R12D
		movdqu [RSI + RAX], xmm0
		
		add R10D, 16
		add R12D, 16
		
		jmp .ciclo
		
.fin_ciclo:    
    
    pop R15
	pop R14
	pop R13
	pop R12
	pop RBX
	pop RBP
    ret


;----------------------------------------------------------------------
; FUNCIONES AUXILIARES (No descubri como hacer ciclos en macros, evitando reedefinicion de etiquetas)

; Shiftea a derecha el XMM0 la cantidad de veces que indique R15D
; Usa eax
__psrldq__:

	xor eax, eax
	
	.while:
		cmp eax, R15D
		je .end_while
		
		psrldq xmm0, 1
		inc eax
		
		jmp .while
	
	.end_while:	
ret

;-------------------------------------------------------

; Shiftea a izquierda el XMM0 la cantidad de veces que indique R15D
; Usa eax
__pslldq__:

	xor eax, eax	
	._while:
		cmp eax, R15D
		je ._end_while
		
		pslldq xmm0, 1
		inc eax
		
		jmp ._while
	
	._end_while:	
ret

;-------------------------------------------------------


; Reinicia el contador de bytes de la columna y avanza el de fila (SRC)
__reiniciar_j_avanzar_i_SRC__:
	xor R10D, R10D
	inc ebx
	
	cmp ebx, [RBP + 24]
	jl .no_reiniciar_i
	
	xor ebx, ebx
	
	.no_reiniciar_i:
ret
