; Stage 2 - Carregador Principal
%include "common.inc"

BITS 16
ORG 0x1000

; Constantes
TRAMPOLINE_ADDR equ 0x2000    ; Endereço para onde copiaremos o código de transição
CODE_SEG    equ 0x08      ; Seletor de código
DATA_SEG    equ 0x10      ; Seletor de dados

; Estruturas RC
struc RC_HEADER
    .magic:     resd 1      ; Deve ser '1RC0'
    .version:   resd 1      ; Versão do formato
    .num_files: resd 1      ; Número de arquivos
endstruc

struc RC_FILE_ENTRY
    .name:      resb 12     ; Nome do arquivo (8.3 format)
    .offset:    resd 1      ; Offset dos dados
    .size:      resd 1      ; Tamanho dos dados
    .type:      resb 1      ; Tipo do arquivo (sp, so, mp, etc)
endstruc

section .data
framebuffer      dd 0          ; Endereço do framebuffer
saved_esp        dd 0
saved_ss         dw 0
rc_initialized   db 0          ; Flag de inicialização do RC
current_rc_file  dd 0          ; Ponteiro para arquivo RC atual

section .text
; Ponto de entrada
start:
    ; NÃO limpar a tela - manter modo VESA do boot
    mov si, msgInit
    call print_string

    ; Verificar se data.1rc foi carregado
    mov esi, DATA_ADDR
    mov eax, [esi]              ; Ler magic number
    cmp eax, 0x31524330        ; '1RC0' em hexadecimal
    jne data_error             ; Pular para handler de erro se não encontrado

    ; Enable A20
    in al, 0x92
    or al, 2
    out 0x92, al
    
    ; Mensagem de progresso
    mov si, msgA20
    call print_string

    ; Copiar trampoline
    mov si, trampoline_start
    mov di, TRAMPOLINE_ADDR
    mov cx, trampoline_end - trampoline_start
    rep movsb

    ; Carregar GDT
    lgdt [gdtr]
    
    mov si, msgGDT
    call print_string

    ; Salvar estado
    pushf
    cli
    push ds
    push es

    ; Mensagem final antes do trampoline
    mov si, msgJump
    call print_string

    ; Pular para o trampoline
    jmp TRAMPOLINE_ADDR

; Funções do sistema de vídeo
init_video_vesa:
    ; Configurar modo VESA
    mov eax, [MODE_INFO + 40]  ; Offset do framebuffer
    mov [framebuffer], eax
    xor eax, eax  ; Retornar sucesso
    ret

; Funções do sistema de memória
init_memory:
    ; Inicializar sistema de memória
    ret

; Funções do sistema de áudio
init_audio:
    ; Inicializar sistema de áudio
    ret

; Loop principal
main_loop:
    ; Loop principal do sistema
    jmp main_loop    ; Loop infinito

; Funções de utilidade
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; Handlers de erro em modo real
data_error:
    mov si, msgDataError
    call print_string
    cli
    hlt

vesa_error:
    mov si, msgVESAError
    call print_string
    cli
    hlt

; Código do Trampoline
align 16
trampoline_start:
    cli
    mov [saved_esp], esp
    mov [saved_ss], ss
    lgdt [temp_gdtr]
    mov al, 0x80
    out 0x70, al
    nop
    nop
    mov eax, cr0
    or al, 1
    mov cr0, eax
    jmp dword CODE_SEG:protected_mode

[BITS 32]
protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, [saved_esp]
    
    ; Inicializar sistemas
    call init_video_vesa
    test eax, eax
    jnz vesa_error_pm
    
    call init_memory
    call init_audio
    
    ; Carregar e verificar data.1rc
    call load_rc_file
    test eax, eax
    jnz data_error_pm
    
    ; Pular para o loop principal
    jmp main_loop

; Sistema de arquivos RC
load_rc_file:
    pushad
    
    ; Verificar assinatura do RC
    mov esi, [DATA_ADDR]
    mov eax, [esi]              ; Ler magic number
    cmp eax, 0x31524330        ; '1RC0' em hexadecimal
    jne .error
    
    ; Salvar ponteiro para dados RC
    mov [current_rc_file], esi
    
    ; Ler número de arquivos
    mov ecx, [esi + RC_HEADER.num_files]
    test ecx, ecx               ; Verificar se tem arquivos
    jz .error
    
    ; Calcular ponteiro para primeira entrada
    add esi, RC_HEADER_size     ; Pular header
    
    ; Debug: Mostrar número de arquivos (em vermelho)
    push ecx
    mov edi, 0xB8000           ; Endereço do buffer de vídeo texto
    mov ah, 0x0C               ; Atributo: vermelho em fundo preto
    mov al, '0'
    add al, cl                 ; Converter número para ASCII
    mov [edi], ax             ; Escrever na tela
    pop ecx
    
    ; Processar cada arquivo
.process_files:
    push ecx
    
    ; Debug: Mostrar nome do arquivo (em verde)
    mov edi, 0xB8002          ; Próxima posição na tela
    mov ah, 0x0A              ; Atributo: verde em fundo preto
    mov ecx, 12               ; Tamanho do nome
.show_name:
    mov al, [esi + RC_FILE_ENTRY.name]
    mov [edi], ax
    add edi, 2
    inc esi
    loop .show_name
    
    ; Ajustar ponteiro para próxima entrada
    add esi, RC_FILE_ENTRY_size - 12  ; -12 porque já avançamos o nome
    
    pop ecx
    loop .process_files
    
    ; Marcar como inicializado
    mov byte [rc_initialized], 1
    
    popad
    xor eax, eax              ; Retornar sucesso
    ret

.error:
    popad
    mov eax, 1                ; Retornar erro
    ret

; Função para obter recurso por nome
get_resource:
    push ebp
    mov ebp, esp
    pushad
    
    ; Verificar se RC está inicializado
    cmp byte [rc_initialized], 0
    je .error
    
    ; Obter ponteiro para os dados RC
    mov esi, [current_rc_file]
    mov ecx, [esi + RC_HEADER.num_files]
    add esi, RC_HEADER_size    ; Pular header
    
    ; Procurar arquivo pelo nome
    mov edi, [ebp + 8]         ; Nome do arquivo a procurar
.search:
    push ecx
    push edi
    push esi
    mov ecx, 12                ; Tamanho do nome
    rep cmpsb                  ; Comparar nomes
    pop esi
    pop edi
    pop ecx
    je .found
    
    add esi, RC_FILE_ENTRY_size
    loop .search
    jmp .error

.found:
    ; Retornar ponteiro para os dados do arquivo
    mov eax, [esi + RC_FILE_ENTRY.offset]
    add eax, [current_rc_file] ; Adicionar base
    mov [esp + 28], eax        ; Salvar em eax do pushad
    popad
    mov esp, ebp
    pop ebp
    ret

.error:
    popad
    xor eax, eax              ; Retornar null
    mov esp, ebp
    pop ebp
    ret

; Handlers de erro em modo protegido
vesa_error_pm:
    mov edi, 0xB8000
    mov esi, msgVESAErrorPM
    mov ah, 0x0C    ; Vermelho em fundo preto
.print:
    lodsb
    test al, al
    jz .done
    mov [edi], ax
    add edi, 2
    jmp .print
.done:
    cli
    hlt

data_error_pm:
    mov edi, 0xB8000
    mov esi, msgDataErrorPM
    mov ah, 0x0C    ; Vermelho em fundo preto
.print:
    lodsb
    test al, al
    jz .done
    mov [edi], ax
    add edi, 2
    jmp .print
.done:
    cli
    hlt

trampoline_end:

; GDTs
align 8
gdt:
    dq 0                    ; Null descriptor
    dw 0xFFFF              ; Limit 0-15
    dw 0                   ; Base 0-15
    db 0                   ; Base 16-23
    db 10011010b           ; Flags
    db 11001111b          ; Flags + Limit 16-19
    db 0                   ; Base 24-31
    
    dw 0xFFFF              ; Data Segment
    dw 0                   
    db 0                   
    db 10010010b           
    db 11001111b           
    db 0                   

gdtr:
    dw $ - gdt - 1         ; Limit
    dd gdt                 ; Base

temp_gdtr:
    dw $ - gdt - 1         ; Limit
    dd gdt                 ; Base

section .data
; Mensagens
msgInit       db 'Engine001 - Iniciando...', 13, 10, 0
msgA20        db 'A20 Line habilitada', 13, 10, 0
msgGDT        db 'GDT carregada', 13, 10, 0
msgJump       db 'Iniciando transicao para modo protegido...', 13, 10, 0
msgVESAError  db 'Erro: VESA nao suportado!', 13, 10, 0
msgDataError  db 'Erro: data.1rc nao encontrado!', 13, 10, 0
msgVESAErrorPM db 'Erro: VESA nao suportado em modo protegido!', 0
msgDataErrorPM db 'Erro: data.1rc invalido ou corrompido!', 0