global trie_crear
global nodo_crear
global insertar_nodo_en_nivel
global trie_agregar_palabra
global trie_construir
global trie_borrar
global trie_imprimir
global buscar_palabra
global palabras_con_prefijo
global trie_pesar
global nodo_prefijo
global caracteres_de_tecla

; SE RECOMIENDA COMPLETAR LOS DEFINES CON LOS VALORES CORRECTOS

extern malloc
extern free
extern fopen
extern fprintf
extern fclose
extern feof
extern fscanf
extern lista_borrar
extern lista_crear
extern lista_agregar

%define offset_sig 0
%define offset_hijos 8
%define offset_c 16
%define offset_fin 17

%define size_nodo 18

%define offset_raiz 0

%define size_trie 8

%define offset_prim 0
%define offset_ultimo 8

%define offset_valor 0
%define offset_sig_lnodo 8

%define NULL 0

%define FALSE 0
%define TRUE 1              

section .rodata

	read: db "r", 0
	
	string_espacio: db '%s ', 0
	
	string: db '%s', 0
	
	char: db '%c', 0
	
	Espacio: db 0
	
	ap: db "a", 0
	
	Vacio: db "<vacio>", 0
	
    lugar: db "", 0
	
	tecla0: db "0", 0
	
	tecla1: db "1", 0
	
	tecla2: db "2abc", 0
	
	tecla3: db "3def", 0
	
	tecla4: db "4ghi", 0
	
	tecla5: db "5jkl", 0
	
	tecla6: db "6mno", 0
	
	tecla7: db "7pqrs", 0
	
	tecla8: db "8tuv", 0
	
	tecla9: db "9wxyz", 0
	
	
	
section .data

section .text

; FUNCIONES OBLIGATORIAS. PUEDEN CREAR LAS FUNCIONES AUXILIARES QUE CREAN CONVENIENTES

trie_crear:
	
	push rbp				;A
	mov rbp,rsp				
	push rbx				;D
	push r12				;A
	push r13				;D
	push r14				;A
	push r15				;D
	mov byte rdi,size_trie	
	sub rsp,8				;A
	call malloc
	add rsp,8				; reestablezco la alineacion
	mov qword [rax],0
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret	
	
	
nodo_borrar:				;rdi = *nodo

	push rbp					;A
	mov rbp,rsp
	push rbx					;D
	push r12					;A
	push r13					;D
	push r14					;A
	push r15					;D
	
	mov r12,rdi						;me guardo el puntero a nodo
	cmp qword r12,NULL				;veo si el el puntero que me pasan es nulo
	je .fin
	cmp qword [r12+offset_sig],NULL	;veo si hay siguiente
	jne .recursionSiguiente
	cmp qword [r12+offset_hijos],NULL	;veo si tiene hijos
	jne .recursionHijos
	jmp .fin
	
	.recursionSiguiente:
		mov rdi, [r12+offset_sig]
		sub rsp,8
		call nodo_borrar
		add rsp,8
		cmp qword [r12+offset_hijos],NULL
		je .fin
		
		
	.recursionHijos:
		mov rdi, [r12+offset_hijos]
		sub rsp,8
		call nodo_borrar
		add rsp,8	
		
		
		
	.fin:
		mov rdi, r12
		sub rsp,8
		call free
		add rsp,8
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret	
	
	
trie_borrar:
	
	push rbp					;A
	mov rbp,rsp
	push rbx					;D
	push r12					;A
	push r13					;D
	push r14					;A
	push r15					;D
	
	mov r12, rdi				;me guardo la raiz en r12
	cmp r12,0					;chequeo si la raiz del trie es null
	je .fin
	mov rdi,[r12+offset_raiz]	;al no ser null, paso los parametros para borrar el nodo
	sub rsp,8					;A
	call nodo_borrar
	add rsp,8					;D
	
	
	.fin:
		mov rdi, r12
		sub rsp, 8
		call free
		add rsp, 8
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret	
	
	
	
	

nodo_crear:
	
	push rbp				;A
	mov rbp,rsp				
	push rbx				;D
	push r12				;A
	push r13				;D
	push r14				;A
	push r15				;D
    
    sub rsp,8
    call cambiar_letra
    add rsp,8
    mov r12, rax			;me guardo el char
	mov rdi,size_nodo		;pongo el parametro con el que llamo a malloc
	sub rsp,8				;A
	call malloc
	add rsp,8							; reestablezco la alineacion
	mov qword [rax+offset_sig],0 		; pongo en null el puntero sig
	mov qword [rax+offset_hijos],0		; pongo en null el punteo hijos
	mov  [rax+offset_c], r12b		; pongo el char pasado como parametro en c
	mov byte [rax+offset_fin],0			; pongo en cero el booleano
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret	
	

nodo_buscar:					;devuelve null si no esta o el puntero al nodo si esta.  rdi = nodo*  rsi= char

		push rbp				;A
		mov rbp,rsp				
		push rbx				;D
		push r12				;A
		push r13				;D
		push r14				;A
		push r15				;D
						
		
	
		cmp qword rdi,NULL				; veo si el parametro pasado es null
		je .fin
			
	.ciclo:
		cmp byte [rdi+offset_c], sil		;comparo si el nodo al que apunto tiene la letra buscada   	
		je .finCiclo
		mov rdi,[rdi+offset_sig]	;si no tiene la letra buscada, actualizo el puntero al nodo siguiente
		cmp qword rdi,NULL				;veo si llegue al final ,para ver si entro de nuevo al ciclo o no    PONER RDI ENTRE CORCHETES SINO
		je .noEsta
		jmp .ciclo

  .noEsta:
		mov rax, NULL
		jmp .fin
	
	
  .finCiclo:
		mov rax,rdi
		
	
 .fin:	
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret	
			



 nodo_prefijo:			;rdi=*nodo , rsi=*char
 
		 push rbp				;A
		 mov rbp,rsp				
		 push rbx				;D
		 push r12				;A
		 push r13				;D
		 push r14				;A
		 push r15				;D

		 mov r12,rdi				;guardo al puntero al nivel en r12
		 mov r13,rsi				;guardo el puntero a la secuencia de chars
		 cmp qword rdi,NULL			;veo si el puntero que me pasan es null
		 je .noEsta
		 
		 .ciclo:
			 cmp byte [r13],0				;veo si me quedan letras para leer
			 je .finCiclo
			 mov rdi,r12					;paso el parametro del puntero a nodo para llamar a buscar nodo
			 mov sil,[r13]					;paso el parametro del char desrefernciado para llamar a buscar nodo			
			 sub rsp,8 						;A
			 call nodo_buscar
			 add rsp,8						;D
			 mov r14,rax					;me guardo el puntero al nodo encontrado
			 cmp qword r14,NULL				;veo si lo que me devolvio es null, o sea si existia o no.
			 je .noEsta
			 mov r12,[r14+offset_hijos]		;si no era nulo bajo de nivel para buscar la proxima letra.
			 add r13,1 						;avanzo la letra a buscar
			 cmp qword r12,NULL				;veo si el puntero de los hijos es nulo
			 je .noEsta
			 jmp .ciclo
			 
		.noEsta:
			mov rax,NULL
			jmp .fin
			 
		 .finCiclo:
			mov rax,r12					;guardo en rax, el puntero con el que me fui moviendo
			
		.fin:	
			pop r15
			pop r14
			pop r13
			pop r12
			pop rbx
			pop rbp
			ret	





			
insertar_nodo_en_nivel:				;rdi = **nodo , rsi = char
	
		push rbp				;A
		mov rbp,rsp				
		push rbx				;D
		push r12				;A
		push r13				;D
		push r14				;A
		push r15				;D
		
		mov r12,[rdi]			;muevo el puntero al primero a r12
		mov r13, rdi			;me guardo el puntero a puntero a nodo en r13	
		mov rdi,rsi				;chequeo que la letra que me pasan sea correcta
		sub rsp,8
		call cambiar_letra
		add rsp,8
		mov r14,rax				;me guardo el char a insertar en r14
		cmp r12,NULL			;veo si no hay nada abajo
		je .loInserto
		mov rdi,r12
		mov rsi,r14
		sub rsp,8
		call nodo_buscar	
		add rsp,8
		mov r15,rax				;me guardo el nodo si es que esta
		cmp r15,NULL			;veo si efectivamente lo encontre o no
		jne .fin
		
	.ciclo:
		
		cmp r14b, [r12+offset_c]			;veo si la letra del nodo es mayor a la mia
		jl .inserto
		cmp qword [r12+offset_sig],NULL		;comparo si hay algun nodo siguiente para ver si va ultimo
		je .esUltimo
		
		lea r13, [r12]					;avanzo el puntero y lo actualizo
        mov r12, [r12+offset_sig]		;avanzo el puntero al siguiente
		jmp .ciclo
		
	
	.loInserto:
		mov rdi,r14
		sub rsp,8
		call nodo_crear	
		add rsp,8
		mov [r13],rax				;lo inserto como unico elemento del nivel
		jmp .fin
		
	.esUltimo:
		mov rdi,r14
		sub rsp,8
		call nodo_crear	
		add rsp,8
		mov [r12+offset_sig],rax
		jmp .fin
		
	.inserto:	
		mov rdi,r14
		sub rsp,8
		call nodo_crear	
		add rsp,8
		mov [rax+offset_sig], r12			;hago el bypass de punteros
		mov [r13], rax			
		jmp .fin
		
	.fin:
			
		pop r15
		pop r14
		pop r13
		pop r12			
		pop rbx
		pop rbp
		ret	

		
		
trie_agregar_palabra:
		
		push rbp					;A
		mov rbp,rsp				
		push rbx					;D
		push r12					;A
		push r13					;D
		push r14					;A
		push r15					;D
		add rdi,offset_raiz
		mov r12,rdi					;puntero al trie en r12
		mov r13,rsi					;puntero a la palabra en r13
		cmp byte [r13],0			;chequeo si la palabra es nula
		je .fin
		
		.ciclo:
			mov rdi,r12					;paso parametros para llamar a insertar nodo en nivel
			xor rsi,rsi
			mov sil,[r13]				;
			sub rsp,8
			call insertar_nodo_en_nivel
			add rsp,8
			mov r12,rax					;guardo el puntero a nodo p
			add r12,offset_hijos		;actualizo el nivel a donde tengo que insertar el proximo nodo
			add r13,1					;avanzo a la letra siguiente
			cmp byte [r13],0			;veo si termine de agregar letras
			je .fin
			jmp .ciclo
			
			
			
		.fin:
		
			mov byte [rax+offset_fin], TRUE		;pongo en 1 el bool de la palabra
			pop r15
			pop r14
			pop r13
			pop r12
			pop rbx
			pop rbp
			ret	
			
			
			

trie_construir:						; rdi = *char
	
		push rbp					;A
		mov rbp,rsp				
		push rbx					;D
		push r12					;A
		push r13					;D
		push r14					;A
		push r15					;D
		
		
		mov r12,rdi					;me guardo el nombre del archivo en r12
		sub rsp,8					;A
		call trie_crear				
		add rsp,8					;D
		mov r13,rax					;me guardo el puntero al trie creado en r13
		cmp r12,NULL				;veo si el nombre que me pasan existe
		je .fin
		mov rdi,1024				;paso el tamaño del buffer que voy a crear
		sub rsp,8					;A
		call malloc
		add rsp,8					;D
		mov r14,rax					;me guardo el puntero al buffer creado en r14
		mov rdi,r12					;paso parametros a rdi para llamar a fopen que abre el archivo
		mov rsi,read				;																							CONSULTAR!!!
		sub rsp,8
		call fopen
		add rsp,8
		mov r15,rax					;me guardo la estructura devuelta por el fopen
		
	.ciclo:
		mov rdi,r15
		mov rsi,string				;																						CONSULTAR!!!
		mov rdx,r14
		sub rsp,8
		mov rax,1
		call fscanf
		add rsp,8
		mov rdi, r15				;paso el parametro para llamar a feof
		sub rsp,8	
		call feof
		add rsp,8
		cmp rax,0					;veo si termine de leer el archivo 																	;				CONSULTAR!!!
		jne .finCiclo
		mov rdi,r13
		mov rsi,r14
		sub rsp,8
		call trie_agregar_palabra
		add rsp,8
		jmp .ciclo
		
	.finCiclo:
		mov rdi,r14
		sub rsp,8	
		call free
		add rsp,8
		mov rdi, r15
		sub rsp,8
		call fclose
		add rsp,8
		
	.fin: 
		mov rax,r13	
		pop r15
		pop r14
		pop r13
		pop r12
		pop rbx
		pop rbp
		ret	
	
	
	
	
	
	
	
	
		
		
trie_imprimir:					;rdi = trie*  , rsi *char
	 
		 push rbp				;A
		 mov rbp,rsp				
		 push rbx				;D
		 push r12				;A
		 push r13				;D
		 push r14				;A
		 push r15				;D
		 
		 mov r12,rdi							;guardo el puntero al trie en r12
		 mov rdi, rsi
		 mov rsi, ap
		 sub rsp,8
		 call fopen
		 add rsp,8
		 mov r13,rax							;guardo en r13 el puntero a la estructura
		 cmp qword [r12+offset_raiz],NULL	;veo si el trie que me pasan tiene algo
		 je .trieVacio
		 mov rdi,r12							
		 mov rsi, Espacio		
		 sub rsp,8
		 call palabras_con_prefijo
		 add rsp,8
		 mov r14, rax						;guardo el puntero a la lista creada con todo el trie en r14
		 mov r15, [rax+offset_prim]			;guardo el puntero al primero de la lista para ir recorriendola
		 
	 .ciclo:
		 
		 cmp qword r15,[r14+offset_ultimo]					;veo si el siguiente es el ultimo de mi lista
		 je .finCiclo
		 mov rdi,r13
		 mov rsi,string_espacio
		 mov rdx,[r15+offset_valor]
		 mov rax,1
		 sub rsp,8
		 call fprintf
		 add rsp,8
	 
	     
	     mov r15, [r15+offset_sig_lnodo]		;avanzo el puntero al siguiente nodo
		 jmp .ciclo
		 
	 
	 .trieVacio:								;tengo que imprimir la palabra <vacio>
		 mov rdi,r13
		 mov rsi,string
		 mov rdx, Vacio
		 mov rax,1
		 sub rsp,8
		 call fprintf
		 add rsp,8
		 mov rdi,r13							;paso parametros para poner al final el lf
		 mov rsi,char
		 mov rdx,10
		 mov rax,1
		 sub rsp,8
		 call fprintf
		 add rsp,8
		 jmp .final
		 
	 .finCiclo:
		
		mov rdi,r13
		mov rsi,string_espacio
		;mov rsi,string
		mov rdx,[r15+offset_valor]
		sub rsp,8
		call fprintf
		add rsp,8
		
		mov rdi,r13							;paso parametros para poner al final el lf
		mov rsi,char
		mov rdx,10
		mov rax,1
		sub rsp,8
		call fprintf
		add rsp,8
		mov rdi,r14							;paso parametros para borrar la lista que cree y liberar memoria
		sub rsp,8		
		call lista_borrar
		add rsp,8
	 
	 .final:
		
		 mov rdi,r13							;paso parametros para cerrar el archivo que abri
		 sub rsp,8
		 call fclose
		 add rsp,8
		 pop r15
		 pop r14
		 pop r13
		 pop r12
		 pop rbx
		 pop rbp
		 ret	
	

buscar_palabra:  ;rdi = trie*			rsi= char*

		push rbp				;A
		mov rbp,rsp				
		push rbx				;D
		push r12				;A
		push r13				;D
		push r14				;A
		push r15				;D
		
		mov r13,rsi					;me guardo el puntero a la palabra a buscar en r13
		mov r12,[rdi+offset_raiz]	;me guardo el puntero al primer nodo en r12
		cmp qword r12,NULL				;veo si hay algun nodo en el trie que me pasaron
		je .falso
		cmp qword r13,NULL				;veo si me pasaron alguna palabra o no
		je .falso
		
		.ciclo:
			cmp qword r12,NULL	
			je .termineCiclo
			cmp qword r13,NULL
			je .termineCiclo
			xor rsi,rsi
			mov dil,[r13]
			sub rsp,8
			call cambiar_letra
			add rsp,8
			mov rdi,r12
			mov sil,al
			sub rsp,8						;A
			call nodo_buscar	
			add rsp,8						;D
			mov r14, rax					;me guardo el nodo encontrado
			cmp qword r14,NULL				;chequeo si el nodo devuelto es null
			je .falso
			mov r12, [r14+offset_hijos]		;si estaba, actualizo mi puntero a los hijos del nodo encontrado
			add r13,1						;avanzo el char a leer
			jmp .ciclo
			
		.falso:
			mov rax,FALSE
			jmp .fin
			
		.termineCiclo:	
			xor rax,rax
			mov al,[r14+offset_fin]
	
			
		.fin:		
			pop r15
			pop r14
			pop r13
			pop r12
			pop rbx
			pop rbp
			ret	



cambiar_letra: 			;rdi = char
	
	
	
	
	cmp dil,48
	jl .devolverA
	cmp dil,57
	jle .correcto
	cmp dil,65
	jl .devolverA
	cmp dil,90
	jle .convertirEnMinuscula
	cmp dil,97
	jl .devolverA
	cmp dil,122
	jg .devolverA
	mov rax,rdi
	jmp .fin
	
		
 .devolverA:
	mov rax,97	
	jmp .fin
	
 .correcto:	
	mov rax,rdi
	jmp .fin
	
 .convertirEnMinuscula:	
  
   add rdi,32
   mov rax,rdi
   jmp .fin
 
 .fin:
   ret	




 trie_pesar:			;	rdi = *trie  rsi = *funcionpesar
	 
	 push rbp				;A
	 mov rbp,rsp				
	 push rbx				;D
	 push r12				;A
	 push r13				;D
	 push r14				;A
	 push r15				;D
	 
	 mov r12,rdi							;me guardo el puntero al trie en r12
	 mov r13,rsi							;me guardo el puntero a la funcion pesar en r13
	 cmp qword [r12+offset_raiz],NULL		;veo si hay algo en el trie que me pasan
	 je .trieVacio
	 mov rsi, Espacio
	 sub rsp,8
	 call palabras_con_prefijo
	 add rsp,8
	 mov r14,rax					;me guardo un puntero a la lista con las palabras del trie en r14
	 mov r15,[r14+offset_prim]		;guardo un puntero al primero de la lista para poder recorrerla en r15
	 xor rbx,rbx					;guardo un contador en rbx, para poder sacar el promedio despues
	 pxor xmm1,xmm1					;guardo un contador del peso que llevo en xmm1 , lo inicializo en cero
	 
   .ciclo:
	
	
	 cmp qword r15,NULL				;veo si el puntero termino de recorrer la lista
	 je .finCiclo
  	 mov rdi,[r15+offset_valor]		;paso el parametro de la palabra que esta en el nodo actual

	sub rsp, 16							; ME RESGUARDO EN LA PILA A XMMM1 ANTES DEL CALL, NO HAY GARANTÌAS DE QUÈ HCE EL LLAMAO CON EL REGISTRO
	movdqu [rsp], xmm1					; ME RESGUARDO EN LA PILA A XMMM1 ANTES DEL CALL, NO HAY GARANTÌAS DE QUÈ HCE EL LLAMAO CON EL REGISTRO
	sub rsp,8							; ALINEO A 16
	call r13
	add rsp,8
	movdqu xmm1, [rsp]
	add rsp, 16
	addsd xmm1,xmm0					;sumo el peso que me devolvio la funcion pesar
	 
	 add rbx,1 							;actualizo el contador de palabras de rbx
	 
	 
	 						
	 mov r15,[r15+offset_sig_lnodo]		;actualizo el puntero al nodo siguiente
	 jmp .ciclo
	 
	 
  .trieVacio:
	 
	 pxor xmm0,xmm0					;si el trie esta vacio devuelvo el valor cero
	 jmp .fin
	 
  .finCiclo:
	 
	 
				
     pxor xmm2, xmm2                
     movq xmm2, rbx 
     
     cvtdq2pd xmm3, xmm2    		;convierto el contador int a double para poder dividir
     divsd xmm1, xmm3
     ;movdqu xmm1,xmm0
	 mov rdi,r14 					;paso parametros para llamar a lista_borrar
	 sub rsp,8	
	 call lista_borrar	 
	 add rsp,8
	 movdqu xmm0, xmm1 				;pongo en xmmo el resultado
	 
	 
	 .fin:
	  pop r15
	  pop r14
	  pop r13
	  pop r12
	  pop rbx
	  pop rbp
	  ret	
	
	

	
	
	
	
	
	
	
	
	
	
	
	

 palabras_con_prefijo:			;rdi = trie*   rsi = char*
	
	 
	 
	  push rbp				;A
	  mov rbp,rsp				
	  push rbx				;D
	  push r12				;A
	  push r13				;D
	  push r14				;A
	  push r15				;D
	  
	  push NULL				;A
	 
	 
	  mov rbx,rsi					;guardo el puntero al char en rbx
	  mov r15,rdi					;guardo el puntero a trie en r15
	  
	  call lista_crear
	  
	  mov r12,rax					;me guardo en r12 la lista creada
	  
	  mov rdi,[r15+offset_raiz]		;paso el parametro de la raiz a rdi
	  mov rsi,rbx
	  
	  call nodo_prefijo
	  
	  mov r13,rax					;muevo a r13 el prefijo del nodo
	  cmp qword r13,NULL			;veo si existen prefijos en el trie, sino devuelvo la lista vacia
	  je .finVacia
	  mov rdi,rbx
	 
	  call crear_buffer
	  
	  mov r14,rax					;muevo a r14 el puntero al buffer
	  
	  
	  
	 .ciclo:
		 cmp qword r13,NULL 				;veo si el puntero al prefijo es nulo
		 je .fin
	 
	 .check1:	
		 cmp qword [r13+offset_sig],NULL	;veo si hay un siguiente en el nodo que estoy parado, si es asi lo guardo		
		 jne .pushear	
		 
	 .check2:	
	 
		 
		 mov rdi,r14
		 
		
		 mov sil,[r13+offset_c]
		 
		 call concatenar_char	
		 mov rbx,rax					;en rbx tengo mi buffer actualizado
		 
		 cmp byte [r13+offset_fin],TRUE	;veo si en donde estoy parado hay una palabra, si es asi la agrego a mi lista
		 je .agregoAlista
		 
	 .check3:		
		 cmp qword [r13+offset_hijos],NULL	;veo si donde estoy parado tengo hijos, si es asi actualizo el puntero y lo muevo hacia abajo
		 jne .actualizo
		 
	
		 cmp qword [rsp],NULL
		 je .fin
		 mov rdi,r14
		 call free
		 pop qword r13
		 pop qword r14
		 jmp .ciclo
	 
	 .pushear:
	 
		 mov rdi,r14
		 call crear_buffer
		 push  rax	
		 push qword [r13+offset_sig]
		 jmp .check2
		 
	 .agregoAlista:
		 
		 mov rdi,r12
		 mov rsi,r14
		 call lista_agregar
		 
		 jmp .check3
		 
	 .actualizo:
				 
		 mov r13,[r13+offset_hijos]		;actualizo el puntero del nodo por el que voy
		 mov r14,rbx					;actualizo el buffer
		 
		 jmp .ciclo
 
	 
	 
 
	 .fin:
		  mov rdi,r14					;libero el buffer con el que empiezo
		  call free	
		 
	
	.finVacia:
	     
	      mov rax,r12	
	      add rsp,8
	      pop r15
		  pop r14
	      pop r13
	      pop r12
		  pop rbx
		  pop rbp
		  ret	


crear_buffer:		;rdi = *char

	 push rbp				;A
	 mov rbp,rsp				
	 push rbx				;D
	 push r12				;A
	 push r13				;D
	 push r14				;A
	 push r15				;D
	
	 mov r12,rdi			;me guardo el puntero a los chars a insertar en el buffer
	 mov rdi,1024
	 sub rsp,8
	 call malloc
	 add rsp,8
	 mov r13,rax			;guardo el puntero al buffer creado
	 mov r15,rax			;guardo otro puntero al buffer para devolverlo
	 cmp qword r12,NULL		; veo si me pasan algun parametro	
	 je .fin
	 
	.ciclo:
		cmp byte [r12],0
		je .fin
		mov r14b,[r12]		;muevo el char sobre el que estoy parado a un registro intermedio
		mov [r13],r14b			;muevo el char al buffer
		add r13,1				;avanzo el puntero al buffer
		add r12,1				;avanzo el char a leer
		jmp .ciclo
		
		
	.fin:	
	  
	  mov rax,r15
	  mov byte [r13],0
	  pop r15
	  pop r14
	  pop r13
	  pop r12
	  pop rbx
	  pop rbp
	  ret	

		
concatenar_char:		;rdi = *char		rsi = char
	
	push rbp				;A
	mov rbp,rsp				
    push rbx				;D
	push r12				;A
	push r13				;D
	push r14				;A
	push r15				;D
  
	mov r12,rdi				;me guardo el puntero para devolverlo cambiado
	
	
  .ciclo:
	cmp byte [rdi],0
	je .insertar
	add rdi,1
	jmp .ciclo
	
 .insertar:
	mov [rdi],rsi		
	add rdi,1
	mov byte [rdi],0
	mov rax,r12
	
	
	pop r15
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
			
	 
caracteres_de_tecla:		;rdi = char

	cmp dil, '0'
	jne .uno
	mov rax,tecla0
	jmp .fin
	
  .uno:
	cmp dil, '1'
	jne .dos
	mov rax,tecla1
	jmp .fin
	
  .dos:	
	cmp dil, '2'
	jne .tres
	mov rax,tecla2
	jmp .fin
	
  .tres:	
	cmp dil, '3'
	jne .cuatro
	mov rax,tecla3
	jmp .fin
	
  .cuatro:	
	cmp dil, '4'
	jne .cinco
	mov rax,tecla4
	jmp .fin
	
  .cinco:	
	cmp dil, '5'
	jne .seis
	mov rax,tecla5
	jmp .fin
 
 .seis:	
	cmp dil, '6'
	jne .siete
	mov rax,tecla6
	jmp .fin

 .siete:	
	cmp dil, '7'
	jne .ocho
	mov rax,tecla7
	jmp .fin

 .ocho:	
	cmp dil, '8'
	jne .nueve
	mov rax,tecla8
	jmp .fin
 .nueve:	
	cmp dil, '9'
	jne .invalida
	mov rax,tecla9
	jmp .fin
	
 .invalida:
	mov rax,NULL
	jmp .fin
	
 .fin:
   ret		
	 
	 
	

