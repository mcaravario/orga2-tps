; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================
BITS 16

extern	tareas_tss
extern	buffer8B
extern	buffer4B
extern	int2s
extern	short2s
extern	dir_tarea_1
extern	GDT_DESC
extern	gdt
extern	idt_inicializar 
extern	IDT_DESC
extern	mmu_inicializar_dir_kernel
extern	mmu_inicializar
extern	resetear_pic
extern	habilitar_pic
extern	tss_inicializar
extern	tss_inicializar_bases_en_gdt
extern	tss_inicializar_cr3_tareas
extern	game_inicializar
extern	imprimir_stack	
extern huboSyscall

global mostrar_regs
global start
global imprimir

;; Saltear seccion de datos
jmp start
%include "a20.asm"
%include "imprimir.mac"

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
iniciando_mr_msg db     'Iniciando kernel (Modo Real)...'
iniciando_mr_len equ    $ - iniciando_mr_msg

iniciando_mp_msg db     'Iniciando kernel (Modo Protegido)...'
iniciando_mp_len equ    $ - iniciando_mp_msg

grupo: db "Grecia/Gyros"
grupo_len: equ $ - grupo

tanque: db "Tanque"
tanque_len: equ $ - tanque

eax_var: db "eax"
eax_len: equ $ - eax_var

ebx_var: DB "ebx"
ebx_len: EQU $ - ebx_var

ecx_var: DB "ecx"
ecx_len: EQU $ - ecx_var

edx_var: DB "edx"
edx_len: EQU $ - edx_var

esi_var: DB "esi"
esi_len: EQU $ - esi_var

edi_var: DB "edi"
edi_len: EQU $ - edi_var

ebp_var: DB "ebp"
ebp_len: EQU $ - ebp_var

esp_var: DB "esp"
esp_len: EQU $ - esp_var

eip_var: DB "eip"
eip_len: EQU $ - eip_var

cs_var: DB "cs"
cs_len: EQU $ - cs_var

ds_var: DB "ds"
ds_len: EQU $ - ds_var

es_var: DB "es"
es_len: EQU $ - es_var

fs_var: DB "fs"
fs_len: EQU $ - fs_var

gs_var: DB "gs"
gs_len: EQU $ - gs_var

ss_var: DB "ss"
ss_len: EQU $ - ss_var

eflags_var: DB "eflags"
eflags_len: EQU $ - eflags_var

cr0_var: DB "cr0"
cr0_len: EQU $ - cr0_var

cr1_var: DB "cr1"
cr1_len: EQU $ - cr1_var

cr2_var: DB "cr2"
cr2_len: EQU $ - cr2_var

cr3_var: DB "cr3"
cr3_len: EQU $ - cr3_var

cr4_var: DB "cr4"
cr4_len: EQU $ - cr4_var

stack_var: DB "stack"
stack_len: EQU $ - stack_var


;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.


start:
    ; Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; Imprimir mensaje de bienvenida
    imprimir_texto_mr iniciando_mr_msg, iniciando_mr_len, 0x07, 0, 0
    

    ; Habilitar A20
    
    call habilitar_A20
    
    ; Cargar la GDT
    
    lgdt [GDT_DESC]
           
    ; Setear el bit PE del registro CR0
    
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    
    ; Saltar a modo protegido
    jmp (9*0x8):inicio_modo_protegido
BITS 32   
    inicio_modo_protegido:
    
    ; Establecer selectores de segmentos
    xor eax, eax
    mov ax, 0b1011000			;ver diapo 11 (formato de selector de segmento)
    mov ss, ax
	mov ds, ax
    mov es, ax
    mov gs, ax
    mov ax, 0b1101000			;
    mov fs, ax					;
    
    ; Establecer la base de la pila
    mov ebp, 0x27000
    mov esp, ebp
    
    ; Imprimir mensaje de bienvenida
    
     
    imprimir_texto_mp iniciando_mp_msg, iniciando_mp_len, 0x07, 0, 0
    
    
    ; Inicializar pantalla	 
	call limpiar_mem_pantalla	
	call escribir_pantalla

    ; Inicializar el manejador de memoria
     call mmu_inicializar
    
    ; Inicializar el directorio de paginas
	; El directorio de paginas, tanto del kernel como de las tareas, se inicializa junto al manejador de la memoria.
    
    ; Cargar directorio de paginas
    mov eax, 0x27000			; Los demas bits van en 0
    mov cr3, eax
    
    
    ; Habilitar paginacion
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
     
  
  
    ; Inicializar la IDT    
    call idt_inicializar

    
    ; Inicializar Game
    call game_inicializar
    
    ; Cargar IDT    
    lidt [IDT_DESC]
    
     
    
    ; Inicializar tss
    mov eax, tareas_tss
	call tss_inicializar

    ; Inicializar tss de la tarea Idle y de los tanques.
	call tss_inicializar_bases_en_gdt
	call tss_inicializar_cr3_tareas

    
    ; Inicializar el scheduler
	; No hace falta inicializar nada desde ASM, pues las estructuras estan inicializadas desde C.
    
    
    ; Configurar controlador de interrupciones
	call resetear_pic
	call habilitar_pic
    
    ; Pintar posiciones inciales de tanques
    
    ; Cargar tarea inicial
	mov ax, 0x73
	ltr	ax

    ; Habilitar interrupciones
    sti


    ; Saltar a la primera tarea: Idle
	jmp 0x78:0					; Tarea Idle, gdt[15]


    ; Ciclar infinitamente (por si algo sale mal...)
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $
    jmp $

;; -------------------------------------------------------------------------- ;;


limpiar_mem_pantalla:
	
	; Tengo que limpiar el buffer de video. De la posicion 0xA0000 hasta 0xB8000   (98304 Bytes)
	; Para acceder al buffer podria crear una nueva posicion en la tabla de segmentos y usar un selector aux.
	; O usar un selector de datos que incluya a la memoria de video y poner el offset correspondiente.
	; Voy a usar DS, el segmento de la posicion 11 de la tabla. (Datos nivel 0) (data segment)
	
	mov esi, 0xA0000				; (direccion effectiva, offset)
	mov eax, 24576					; Cantidad de itearaciones (98304 / 4). Computo de a 4 bytes.
	
	
	.clean_mem:
		cmp eax, 0
		je .continuar_1
		
		mov dword [ds:esi],	0
		add esi, 4
		dec eax
		jmp .clean_mem
	
	.continuar_1:
		 
	; Seteo la pantalla en fondo negro y verde.
	call limpiar_pantalla
	call pintar_gris_grande
	call pintar_rojo_chico
	;call pintar_rojo_grande    (quedaba feo)
	call pintar_gris_chico
	
	ret



	
; Los offset los calculo (filas* tamfila + columnas) * tamElto
; Las iteraciones son la cant de elementos en cada rectangulo.

pintar_gris_chico:
	;Pinto de gris el rectangulo (47,53), (47,69), (49,53), (49,69)
	; Offset: 7626
	; Iteraciones: 48
	
	

	mov esi, 7626
	mov eax, 48
	xor edi, edi
	mov bh, 0b01110111				; Buscar el valor del gris en 3-bit	(pongo blanco para testear)	
	mov bl, 0b00000000
	
	.gris_chico:
		cmp eax, 0
		je .fin
		
		cmp edi, 16
		je .sig_fila
		
		mov [fs:esi], bx
		add esi, 2
		dec eax
		inc edi
		jmp .gris_chico
		
		
		.sig_fila:
			xor edi, edi
			add esi, 128
			jmp .gris_chico
	.fin:
	ret
;----------------------------------------------------------------------
pintar_gris_grande:

	; Pinto de gris el rectangulo (8,51) , (8,79) , (38,51) , (38,79)
	; Offset: 1382
	; Iteraciones: 840
	mov esi, 1382
	mov eax, 896
	mov edi, 0
	mov bh, 0b01110111				; Buscar el valor del gris en 3-bit		
	mov bl, 0b00000000				; Ascci null
	
	.gris_grande:
	
		cmp eax, 0
		je .fin
		
		cmp edi, 28
		je .sig_fila
		
		mov [fs:esi], bx
		add esi, 2
		dec eax
		inc edi
		jmp .gris_grande
		
		.sig_fila:
			xor edi, edi
			add esi, 104
			jmp .gris_grande
	
	.fin:
	ret

;----------------------------------------------------------------------
pintar_rojo_grande:
	; Pinto de rojo el rectangulo (39,51), (39,79), (41,51), (41,79)
	; Offset: 6342
	; Iteraciones: (3 * 28) = 84
	mov esi, 6662
	mov eax, 84
	mov edi, 0
	mov bh, 0b01000111				;Blink: 0 | Fondo: Rojo | Brillante: 0 | Char: Blanco
	mov bl, 0b00000000
	
	.rojo_grande:
		cmp eax, 0
		je .fin
		
		cmp edi, 28
		je .sig_fila
		
		mov [fs:esi], bx
		add esi, 2
		dec eax
		inc edi
		jmp .rojo_grande
		
		.sig_fila:
			xor edi, edi
			add esi, 104
			jmp .rojo_grande

	.fin:
	ret
	
;----------------------------------------------------------------------	
pintar_rojo_chico:

	; Al ser una sola fila, no hay que hacer doble if.
	; Pinto de rojo el rectangulo (7,51), (7,79)
	; Offset: 1222
	; Iteraicones: 28
	mov esi, 1222
	mov eax, 28
	mov bh, 0b01000111				;Blink: 0 | Fondo: Rojo | Brillante: 0 | Char: Blanco
	mov bl, 0b00000000
	
	.rojo_chico:
		cmp eax, 0
		je .fin
		
		mov [fs:esi], bx
		add esi, 2
		dec eax
		jmp .rojo_chico


	.fin:
	ret
	
	
;----------------------------------------------------------------------	
; OK
limpiar_pantalla:
	

	; Iteraciones = 2000 (80*25)
	mov ebx, 4000
	xor eax, eax
	mov al, 0b00100000				;blink | R | G | B | brillo | R | G | B (del caracter)
	xor ecx, ecx
	mov cl, 0b00000000				;ASCII del espacio 
	xor edx, edx
	mov dl, 0b00000111				; fondo negro, caracter negro
	xor esi, esi
		
	
	.ciclo:
		cmp ebx, 0
		je .pantalla_limpia
		mov [fs:esi],cl
		inc esi
		mov [fs:esi],al
		inc esi
		dec ebx
		jmp .ciclo
	
	.pantalla_limpia:
		xor esi, esi
		add esi, 100				;100 decimal, arranco de la columna 50
		xor ebx, ebx
		mov ebx, 1500				;1500 decimal
		xor eax, eax				;ya no necesito el verde
	
	
	
	.ciclo_dos:
		cmp ebx, 0
		je .fin
		cmp eax, 30					;30 decimal
		je .cambiar_fila
	.volver:
		
		mov [fs:esi],cl
		inc esi
		mov [fs:esi],dl
		inc esi
		dec ebx
		inc eax
		jmp .ciclo_dos
		
	.cambiar_fila:
		add esi, 100
		xor eax, eax
		jmp .volver
		
	.fin:
		ret


escribir_pantalla:
	
	imprimir_texto_mp grupo, grupo_len, 0x03, 5, 55
	imprimir_texto_mp tanque, tanque_len, 0x47, 7,53
	imprimir_texto_mp eax_var, eax_len, 0x70, 9,52
	imprimir_texto_mp ebx_var, ebx_len, 0x70, 11,52
	imprimir_texto_mp ecx_var, ecx_len, 0x70, 13,52
	imprimir_texto_mp edx_var, edx_len, 0x70, 15,52
	imprimir_texto_mp esi_var, esi_len, 0x70, 17,52
	imprimir_texto_mp edi_var, edi_len, 0x70, 19,52
	imprimir_texto_mp ebp_var, ebp_len, 0x70, 21,52
	imprimir_texto_mp esp_var, esp_len, 0x70, 23,52
	imprimir_texto_mp eip_var, eip_len, 0x70, 25,52
	imprimir_texto_mp cs_var, cs_len, 0x70, 27,53
	imprimir_texto_mp ds_var, ds_len, 0x70, 29,53
	imprimir_texto_mp es_var, es_len, 0x70, 31,53
	imprimir_texto_mp fs_var, fs_len, 0x70, 33,53
	imprimir_texto_mp gs_var, gs_len, 0x70, 35,53
	imprimir_texto_mp ss_var, ss_len, 0x70, 37,53
	imprimir_texto_mp eflags_var, eflags_len, 0x70, 39,53
	imprimir_texto_mp stack_var, stack_len, 0x70, 26,65
	imprimir_texto_mp cr0_var, cr0_len, 0x70, 9,66
	imprimir_texto_mp cr2_var, cr2_len, 0x70, 11,66
	imprimir_texto_mp cr3_var, cr3_len, 0x70, 13,66
	imprimir_texto_mp cr4_var, cr4_len, 0x70, 15,66
	
	ret


;------------------------------------------------------------------------

mostrar_regs:

	; Imprimo EAX
	pushad
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 9, 56	
	add esp, 4
	popad
	 
	; Imprimo EBX
	pushad
	push	ebx
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 11, 56
	add		esp, 4
	popad
	
	; Imprimo ECX
	pushad
	push	ecx
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 13, 56
	add		esp, 4
	popad
	
	; Imprimo EDX
	pushad
	push	edx
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 15, 56
	add		esp, 4
	popad
	 
	 ; Imprimo ESI
	pushad
	push	esi
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 17, 56
	add		esp, 4
	popad
	 
	; Imprimo EDI
	pushad
	push	edi
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 19, 56
	add		esp, 4
	popad
	
	; Imprimo EBP
	pushad
	push	ebp
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 21, 56
	add		esp, 4
	popad
	
	; Imprimo CR0
	pushad
	mov		eax, cr0
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 9, 71
	add		esp, 4
	popad
	
	; Imprimo CR2
	pushad
	mov		eax, cr2
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 11, 71
	add		esp, 4
	popad
	
	; Imprimo CR3
	pushad
	mov		eax, cr3
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 13, 71
	add		esp, 4
	popad
	
	; Imprimo CR4
	pushad
	mov		eax, cr4
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 15, 71
	add		esp, 4
	popad
	 

	
 
	; Imprimo los registros de segmento (16b)
	
	 
	pushad
	push	ds
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 29, 56
	add esp, 4
	popad
	 
	pushad
	push	es
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 31, 56
	add esp, 4
	popad
	 
	pushad
	push	fs
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 33, 56
	add esp, 4
	popad
	 
	pushad
	push	gs
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 35, 56
	add esp, 4
	popad
	
	cmp byte [huboSyscall], 0
	je .hubo_cambio_de_nivel
	
	
	pushad
	push	ss
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 35, 56
	add esp, 4
	popad
	
	pushad
	push	cs
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 35, 56
	add esp, 4
	popad
	
	; Imprimo ESP
	pushad
	push	esp
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 15, 56
	add		esp, 4
	popad
	
	; Imprimo EIP
	pushad
	push dword [esp+36]
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 15, 56
	add		esp, 4
	popad
	
	; Imprimo EFLAGS
	pushad
	push dword [esp+44]
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 15, 56
	add		esp, 4
	popad
	
	
	;Imprimo stack 
	
	pushad
	mov eax, esp
	xor ebx, ebx
	mov ecx, 28
	
	.ciclo:
	cmp ebx, 5
	je .fin_stack
	push dword [eax]
	call int2s
	imprimir_texto_mp buffer8B, 8, 0x7f, ecx, 65 
	add esp, 4
	inc ecx
	inc ebx
	add eax, 4
	jmp .ciclo
	
	
	
	.fin_stack:
	popad
	
	jmp .fin
	
	.hubo_cambio_de_nivel:
	
	; Imprimo ss

	pushad
	mov	ax, [esp + 52]
	push	ax
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 37, 56
	add esp, 2
	popad
	 
	;~ ; Muestro el valor del stack (5 primeros valores)
	pushad
	mov	ecx, [esp+48]
	xor esi, esi

	mov ebx, 28
	.ciclo2:
		cmp esi, 5
		je .fin_ciclo
		mov eax, [ecx]
		push eax
		call int2s 
		imprimir_texto_mp buffer8B, 8, 0x7F, ebx, 65
		add esp, 4
		inc ebx
		inc esi
		add ecx, 4 
		jmp .ciclo2
	.fin_ciclo:
	popad
	
	; Asumo que la pila esta como entra a la interrupcion
	; Tomo el EIP de la tarea desde la pila del handler
	;Imprimo EIP
	pushad
	mov eax, [esp + 36]								
	push eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 25, 56
	add	esp, 4
	popad
	
 	; Imprimo cs
	pushad
	mov		ax, [esp + 40]
	push	ax
	call	short2s
	imprimir_texto_mp buffer4B, 4, 0x7F, 27, 56
	add esp, 2
	popad
	
 	; Imprimo EFLAGS.
	pushad
	mov eax, [esp + 44]
	push eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 39, 59
	add		esp, 4
	popad
 	
 	; Imprimo ESP
	pushad
	mov eax, [esp+48]
	push	eax
	call	int2s
	imprimir_texto_mp buffer8B, 8, 0x7F, 23, 56
	add		esp, 4
	popad
 	
 	.fin:
 	 
	ret
	

