; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TRABAJO PRACTICO 3 - System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================
; definicion de rutinas de atencion de interrupciones

%include "imprimir.mac"
%define INVALIDO 666
%define IDLE	10
%define DESALOJO_SIZE 72


BITS 32


offset:		dd 0
selector:	dw 0

interrupt_0: DB "Interrupcion 0"
interrupt_0_long: EQU $-interrupt_0

interrupt_1: DB "Interrupcion 1"
interrupt_1_long: EQU $-interrupt_1

interrupt_2: DB "Interrupcion 2"
interrupt_2_long: EQU $-interrupt_2

interrupt_3: DB "Interrupcion 3"
interrupt_3_long: EQU $-interrupt_3

interrupt_4: DB "Interrupcion 4"
interrupt_4_long: EQU $-interrupt_3

interrupt_5: DB "Interrupcion 5"
interrupt_5_long: EQU $-interrupt_5

interrupt_6: DB "Interrupcion 6"
interrupt_6_long: EQU $-interrupt_6

interrupt_7: DB "Interrupcion 7"
interrupt_7_long: EQU $-interrupt_7

interrupt_8: DB "Interrupcion 8"
interrupt_8_long: EQU $-interrupt_8

interrupt_9: DB "Interrupcion 9"
interrupt_9_long: EQU $-interrupt_9

interrupt_10: DB "Interrupcion 10"
interrupt_10_long: EQU $-interrupt_10

interrupt_11: DB "Interrupcion 11"
interrupt_11_long: EQU $-interrupt_11

interrupt_12: DB "Interrupcion 12"
interrupt_12_long: EQU $-interrupt_12

interrupt_13: DB "Interrupcion 13"
interrupt_13_long: EQU $-interrupt_13

interrupt_14: DB "Interrupcion 14"
interrupt_14_long: EQU $-interrupt_14

interrupt_15: DB "Interrupcion 15"
interrupt_15_long: EQU $-interrupt_15

interrupt_16: DB "Interrupcion 16"
interrupt_16_long: EQU $-interrupt_16

interrupt_17: DB "Interrupcion 17"
interrupt_17_long: EQU $-interrupt_17

interrupt_18: DB "Interrupcion 18"
interrupt_18_long: EQU $-interrupt_18

interrupt_19: DB "Interrupcion 19"
interrupt_19_long: EQU $-interrupt_19

teclado_1: DB "1"
teclado_1_long: EQU $-teclado_1

teclado_2: DB "2"
teclado_2_long: EQU $-teclado_2

teclado_3: DB "3"
teclado_3_long: EQU $-teclado_3

teclado_4: DB "4"
teclado_4_long: EQU $-teclado_4

teclado_5: DB "5"
teclado_5_long: EQU $-teclado_5

teclado_6: DB "6"
teclado_6_long: EQU $-teclado_6

teclado_7: DB "7"
teclado_7_long: EQU $-teclado_7

teclado_8: DB "8"
teclado_8_long: EQU $-teclado_8

teclado_9: DB "9"
teclado_9_long: EQU $-teclado_9

teclado_0: DB "0"
teclado_0_long: EQU $-teclado_0

teclado_error: DB "Lo sentimos, nuestro teclado solo reconoce numeros"
teclado_error_long: EQU $-teclado_error


sched_tarea_offset:     dd 0x00

sched_tarea_selector:   dw 0x00

;; PIC
extern fin_intr_pic1

;; Sched
extern sched_master
extern hayPausa
extern tarea_actual
extern cant_validas

;; Game
extern game_mover
extern game_misil
extern game_minar
extern desalojar_tarea
extern mostrar_regs
extern printg

;; TSS
extern imprimir_regs_desalojo
extern info_desalojo

global _isr0
global _isr1
global _isr2
global _isr3
global _isr4
global _isr5
global _isr6
global _isr7
global _isr8
global _isr9
global _isr10
global _isr11
global _isr12
global _isr13
global _isr14
global _isr15
global _isr16
global _isr17
global _isr18
global _isr19
global _isr20
global _isr21
global _isr22
global _isr23
global _isr24
global _isr25
global _isr26
global _isr27
global _isr28
global _isr29
global _isr30
global _isr31
global _isr32
global _isr33
global _isr0x52
;;
;; Definición de MACROS
;; -------------------------------------------------------------------------- ;;
%macro ISR 1
_isr%1:
	cli

	
	;;; Llamo a una funcion que guarda en la estructura de desalojos los registros.
	;~ call guardar_regs_desalojo

	
	call mostrar_regs	
	imprimir_texto_mp interrupt_%1, interrupt_%1_long, 0x07,0, 51
	pusha
	push dword %1
    call desalojar_tarea
    add esp, 4
    
    call sched_master
	mov [selector], ax
	jmp far [offset]
	
    popa
    sti
    iret
 
%endmacro

;;
;; Datos
;; -------------------------------------------------------------------------- ;;
; Scheduler
isrnumero:           dd 0x00000000
isrClock:            db '|/-\'

numero:   dd 0x00000000

message1: db '|'
message2: db '/'
message3: db '-'
message4: db '\'



isrnumero2:           dd 0x00000000
isrClock2:            db '|/-\'
isrnumero3:           dd 0x00000000
isrClock3:            db '|/-\'
isrnumero4:           dd 0x00000000
isrClock4:            db '|/-\'
isrnumero5:           dd 0x00000000
isrClock5:            db '|/-\'
isrnumero6:           dd 0x00000000
isrClock6:            db '|/-\'
isrnumero7:           dd 0x00000000
isrClock7:            db '|/-\'
isrnumero8:           dd 0x00000000
isrClock8:            db '|/-\'

;;
;; Rutina de atención de las EXCEPCIONES
;; -------------------------------------------------------------------------- ;;




ISR 0
ISR 1
ISR 2
ISR 3
ISR 4
ISR 5
ISR 6
ISR 7
ISR 8
ISR 9
ISR 10
ISR 11
ISR 12
ISR 13
ISR 14
ISR 15
ISR 16
ISR 17
ISR 18
ISR 19

;;
;; Rutina de atención del RELOJ
;; -------------------------------------------------------------------------- ;;

_isr32:

	.seguir:
	cli
	pushad

	;El clock de cada tarea se mueve justo antes de ejecturarla. Así nos ahorramos los casos borde en los que la tarea muere (por facilidad para nosotrs)
	call proximo_reloj
	
	; Deja en AX el selector a donde saltar (0 en caso de no saltar) y actualiza las estructuras.
	call sched_master
	cmp ax, 0
	je .nojump
	
	mov [selector], ax
	call task_clock
	call fin_intr_pic1
	jmp far [offset]
	jmp .end
	
	.nojump:
	call task_clock
	call fin_intr_pic1	
	
	.end:

	
.sigue:
	popad
	sti
	iret
	
	
	
;; Rutina de atención del TECLADO
;; -------------------------------------------------------------------------- ;;

_isr33:
	cli
	pusha
	
	
	in al, 0x60								;scaneo el codigo de entrada de la tecla
	cmp al, 0x19
	je .pausar
	cmp al, 0x99
	je .pausar2	
	cmp al, 0x02
	je .imprimo1
	cmp al, 0x82
	je .imprimo1
	cmp al, 0x03
	je .imprimo2
	cmp al, 0x83
	je .imprimo2
	cmp al, 0x04
	je .imprimo3
	cmp al, 0x84
	je .imprimo3
	cmp al, 0x05
	je .imprimo4
	cmp al, 0x85
	je .imprimo4
	cmp al, 0x06
	je .imprimo5
	cmp al, 0x86
	je .imprimo5
	cmp al, 0x07
	je .imprimo6
	cmp al, 0x87
	je .imprimo6
	cmp al, 0x08
	je .imprimo7
	cmp al, 0x88
	je .imprimo7
	cmp al, 0x09
	je .imprimo8
	cmp al, 0x89
	je .imprimo8
	cmp al, 0x0a
	je .imprimo9
	cmp al, 0x8a
	je .imprimo9
	cmp al, 0x0b
	je .imprimo0	
	cmp al, 0x8b
	je .imprimo0	
	;~ imprimir_texto_mp teclado_error, teclado_error_long, 0x07,0,55
	jmp .fin

.pausar:
	cmp byte [hayPausa], 0
	je .pongo1
	mov byte [hayPausa], 0
	jmp .fin
.pongo1:
	mov byte [hayPausa], 1
	jmp .fin
.pausar2:
	jmp .fin

.imprimo1:
	imprimir_texto_mp teclado_1, teclado_1_long, 0x47,7,60
	push dword 1
	call imprimir_regs_desalojo
	add esp, 4
	jmp .fin

.imprimo2:
	imprimir_texto_mp teclado_2, teclado_2_long, 0x47,7,60
	push dword 2
	call imprimir_regs_desalojo
	add esp, 4
	jmp .fin
.imprimo3:
	imprimir_texto_mp teclado_3, teclado_3_long, 0x47,7,60
	push dword 3
	call imprimir_regs_desalojo
	add esp, 4
	jmp .fin
.imprimo4:
	imprimir_texto_mp teclado_4, teclado_4_long, 0x47,7,60
	push dword 4
	call imprimir_regs_desalojo
	add esp, 4
	jmp .fin
.imprimo5:
	imprimir_texto_mp teclado_5, teclado_5_long, 0x47,7,60
	push dword 5
	call imprimir_regs_desalojo
	add esp, 4	
	jmp .fin
.imprimo6:
	imprimir_texto_mp teclado_6, teclado_6_long, 0x47,7,60
	push dword 6
	call imprimir_regs_desalojo
	add esp, 4	
	jmp .fin
.imprimo7:
	imprimir_texto_mp teclado_7, teclado_7_long, 0x47,7,60
	push dword 7
	call imprimir_regs_desalojo
	add esp, 4	
	jmp .fin
.imprimo8:
	imprimir_texto_mp teclado_8, teclado_8_long, 0x47,7,60
	push dword 8
	call imprimir_regs_desalojo
	add esp, 4
	jmp .fin
.imprimo9:
	imprimir_texto_mp teclado_9, teclado_9_long, 0x47,0,78
	jmp .fin
.imprimo0:
	imprimir_texto_mp teclado_0, teclado_0_long, 0x07,0,78





.fin:



	popa
	call fin_intr_pic1
	sti
	iret

;;
;; Rutinas de atención de las SYSCALLS
;; -------------------------------------------------------------------------- ;;
%define SYS_MOVER     0x83D
%define SYS_MISIL     0x911
%define SYS_MINAR     0x355
%define RAZON_MINA     15
%define TRUE			1


_isr0x52:
	cli
	;;; Salvo los registros en caso de ser desalojado. Si no soy delojado, en algun memomento se pisara la informacion.
	;~ call guardar_regs_desalojo
	pusha
	
	cmp eax, SYS_MOVER
	je .mover
	
	cmp eax, SYS_MISIL
	je .misil
	
	cmp eax, SYS_MINAR
	je .minar
	
	jmp .fin_sin_return
	
	.mover:
		push ebx								; Direccion
		push dword [tarea_actual]				; ID de tarea
		call game_mover
		add esp, 8
		jmp .fin_mover
		
	.misil:
		push esi								; Tamaño
		push edx								; Misil
		push ecx								; val_y
		push ebx								; val_x
		push dword [tarea_actual]				; ID de tarea
		call game_misil
		add esp, 20
		jmp .fin_sin_return
		
	.minar:
		push ebx								; Direccion
		push dword [tarea_actual]				; ID tarea
		call game_minar
		add esp, 8
		jmp .fin_sin_return
		
.fin_mover:
	cmp eax, 0
	push eax									; Mas adelante se alinea la pila.
	jne .fin_con_return
	add esp, 4
	popad
	;~ call imprimir_regs_desalojo							; Preserva los registros.
	call mostrar_regs
	pushad
	push eax
	jmp .fin_con_return
	

	
.fin_sin_return:
	call sched_master		; Me devolvera el selector para saltar a la idle.
	mov [selector], ax
	jmp far [offset]
	
	popa
	sti	
	iret

; Mover devuelve por eax el ultimo offset valido (virtual).
.fin_con_return:
	; eax esta pusheado para ser salvado
	; ignoro el eax salvado, asi se popea bien el POPA
	call sched_master					; Me devolvera el selector para saltar a la idle.
	mov [selector], ax
	jmp far [offset]
	
	add esp, 4
	popa
	mov eax, [esp - 36]
	sti
	iret



;; Funciones Auxiliares
;; -------------------------------------------------------------------------- ;;
proximo_reloj:
        pushad
        inc DWORD [isrnumero]
        mov ebx, [isrnumero]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock
                imprimir_texto_mp ebx, 1, 0x0f, 49, 78
                popad
        ret
        
        
proximo_reloj_task_1:
        inc dword [numero]
        cmp dword [numero], 0x4
        jb .imprimir

    .reset_contador:
        mov dword [numero], 0x0

    .imprimir:
        ; Imprimir 'reloj'
        mov ebx, dword [numero]
        add ebx, message1
        imprimir_texto_mp ebx, 1, 0x7f, 49, 54
    
    ret



proximo_reloj_task_2:
        pushad
        inc DWORD [isrnumero2]
        mov ebx, [isrnumero2]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero2], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock2
                imprimir_texto_mp ebx, 1, 0x7f, 49, 56
                popad
        ret
                
proximo_reloj_task_3:
        pushad
        inc DWORD [isrnumero3]
        mov ebx, [isrnumero3]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero3], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock3
                imprimir_texto_mp ebx, 1, 0x7f, 49, 58
                popad
        ret
           
           
proximo_reloj_task_4:
        pushad
        inc DWORD [isrnumero4]
        mov ebx, [isrnumero4]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero4], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock4
                imprimir_texto_mp ebx, 1, 0x7f, 49, 60
                popad
        ret     
        
proximo_reloj_task_5:
        pushad
        inc DWORD [isrnumero5]
        mov ebx, [isrnumero5]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero5], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock5
                imprimir_texto_mp ebx, 1, 0x7f, 49, 62
                popad
        ret
        
proximo_reloj_task_6:
        pushad
        inc DWORD [isrnumero6]
        mov ebx, [isrnumero6]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero6], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock6
                imprimir_texto_mp ebx, 1, 0x7f, 49, 64
                popad
        ret
        
proximo_reloj_task_7:
        pushad
        inc DWORD [isrnumero7]
        mov ebx, [isrnumero7]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero7], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock7
                imprimir_texto_mp ebx, 1, 0x7f, 49, 66
                popad
        ret
        
proximo_reloj_task_8:
        pushad
        inc DWORD [isrnumero8]
        mov ebx, [isrnumero8]
        cmp ebx, 0x4
        jl .ok
                mov DWORD [isrnumero8], 0x0
                mov ebx, 0
        .ok:
                add ebx, isrClock8
                imprimir_texto_mp ebx, 1, 0x7f, 49, 68
                popad
        ret
task_clock:
	cmp dword [tarea_actual], 0
	je proximo_reloj_task_1
	
	cmp dword [tarea_actual], 1
	je proximo_reloj_task_2
	
	cmp dword [tarea_actual], 2
	je proximo_reloj_task_3
	
	cmp dword [tarea_actual], 3
	je proximo_reloj_task_4
	
	cmp dword [tarea_actual], 4
	je proximo_reloj_task_5
	
	cmp dword [tarea_actual], 5
	je proximo_reloj_task_6
	
	cmp dword [tarea_actual], 6
	je proximo_reloj_task_7
	
	cmp dword [tarea_actual], 7
	je proximo_reloj_task_8
ret 

;;; Recibe la misma pila que los handlers de Interrupsiones.
;;; pero con la direccion de la pila en el tope.
;;; Los registros de control y la razon las setea la funcion desalojar_tarea en sched.c
guardar_regs_desalojo:

	;; Debo guardar en mi estructura auxiliar los valores de los registros.
	push eax						; Puntero al inicio del arreglo de structs
	push ebx						; offset en el arreglo
	push ecx						; Auxiliar
	mov eax, [tarea_actual]
	mov ebx, DESALOJO_SIZE
	mul ebx
	
	
	mov ebx, eax
	mov eax, info_desalojo

	mov ecx, [esp + 16]
	mov [eax + ebx], ecx		; EIP
	mov ecx, [esp + 24]
	mov [eax + ebx + 4], ecx	; EFLAGS
	mov ecx, [esp + 4]
	mov [eax + ebx + 8], ecx	; EAX
	mov ecx, [esp]
	mov [eax + ebx + 12], ecx	; ECX
	mov [eax + ebx + 16], edx	; EDX
	mov ecx, [esp + 4]
	mov [eax + ebx + 20], ecx	; EBX
	mov ecx, [esp + 28]
	mov [eax + ebx + 24], ecx	; ESP
	mov [eax + ebx + 28], ebp	; EBP
	mov [eax + ebx + 32], esi	; ESI
	mov [eax + ebx + 36], edi	; EDI
	
	;;Registros de segmento
	mov [eax + ebx + 40], es	; ES
	mov ecx, [esp + 20]
	mov [eax + ebx + 42], ecx	; CS
	mov ecx, [esp + 32]
	mov [eax + ebx + 44], ecx	; SS
	mov [eax + ebx + 46], ds	; DS
	mov [eax + ebx + 48], fs	; FS
	mov [eax + ebx + 50], gs	; GS

	pop ecx
	pop ebx
	pop eax
	
	ret
	
	
	
