; Boot Sector - Stage 1
BITS 16
ORG 0x7C00

; Constantes
KERNEL_ADDR     equ 0x1000    ; 0x10000 físico
STAGE2_SECTORS  equ 32        ; Número de setores para carregar
VESA_INFO       equ 0x3000    ; Endereço para info VESA
MODE_INFO       equ 0x3200    ; Endereço para info do modo
VESA_MODE      equ 0x101     ; Modo 640x480x8 (mais compatível)

start:
    ; Setup inicial
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Salvar drive de boot
    mov [bootDrive], dl

    ; Limpar tela e configurar modo texto inicial
    mov ax, 0x0003
    int 0x10

    ; Verificar suporte VESA
    mov ax, 0x4F00
    mov di, VESA_INFO
    int 0x10
    cmp ax, 0x004F
    jne vesa_error

    ; Salvar modo atual
    mov ah, 0x0F
    int 0x10
    mov [original_mode], al

    ; Obter informações do modo
    mov ax, 0x4F01
    mov cx, VESA_MODE
    mov di, MODE_INFO
    int 0x10
    cmp ax, 0x004F
    jne vesa_error

    ; Verificar atributos do modo
    mov ax, [MODE_INFO + 0]    ; Verificar se modo é suportado
    and ax, 0x99              ; Deve ser color, gráfico e suportado
    cmp ax, 0x99
    jne vesa_error

    ; Tentar configurar modo VESA
    mov ax, 0x4F02
    mov bx, VESA_MODE         ; Sem LFB inicialmente
    int 0x10
    cmp ax, 0x004F
    jne vesa_error

    ; Verificar se entrou no modo correto
    mov ax, 0x4F03
    int 0x10
    cmp ax, 0x004F
    jne vesa_error
    cmp bx, VESA_MODE
    jne vesa_error

    ; Aguardar um pouco para estabilizar
    mov cx, 0xFFFF
.delay:
    loop .delay

    ; Testar acesso à memória de vídeo
    mov ax, [MODE_INFO + 40]   ; Obter segmento de memória
    mov es, ax
    mov di, 0
    mov al, 1                  ; Cor de teste
    mov [es:di], al           ; Tentar escrever
    mov bl, [es:di]           ; Tentar ler
    cmp al, bl                ; Verificar se escrita funcionou
    jne vesa_error

    ; Imprimir mensagem de sucesso
    mov si, msgVESA
    call print_string

    ; Resetar drive
    xor ax, ax
    int 0x13
    jc disk_error

    ; Carregar Stage 2
    mov ax, KERNEL_ADDR
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, STAGE2_SECTORS
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [bootDrive]
    int 0x13
    jc disk_error

    ; Carregar data.1rc
    mov ax, 0x9000
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 16
    mov ch, 0
    mov cl, 34
    mov dh, 0
    mov dl, [bootDrive]
    int 0x13
    jc data_error

    ; Mostrar mensagem de sucesso
    mov si, msgOK
    call print_string

    ; Pular para Stage 2
    jmp KERNEL_ADDR:0x0000

; Função para imprimir string em modo texto
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

; Handlers de erro
vesa_error:
    ; Tentar voltar para modo texto
    mov ax, 0x0003
    int 0x10
    
    mov si, msgVESAError
    call print_string
    jmp error_halt

disk_error:
    mov si, msgDiskError
    call print_string
    jmp error_halt

data_error:
    mov si, msgDataError
    call print_string
    jmp error_halt

error_halt:
    cli
    hlt

; Dados
msgVESA      db 'VESA OK - Modo grafico iniciado', 13, 10, 0
msgVESAError db 'Erro VESA!', 13, 10, 0
msgDiskError db 'Erro de disco!', 13, 10, 0
msgDataError db 'Erro ao carregar data.1rc!', 13, 10, 0
msgOK        db 'Sistema carregado com sucesso!', 13, 10, 0
bootDrive    db 0
original_mode db 0

; Padding e assinatura
times 510-($-$$) db 0
dw 0xAA55