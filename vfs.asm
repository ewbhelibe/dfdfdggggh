; vfs.asm - Sistema de Arquivos Virtual
%include "common.inc"

section .data
; Constantes do VFS
VFS_MAGIC       equ 0x00018A48  ; 48 8A 01 00
VFS_HEADER_SIZE equ 36          ; 4 (magic) + 32 (hash)
MAX_NAME_LEN    equ 256
PNG_MAGIC       equ 0x474E5089  ; 89 50 4E 47

; Tipos de arquivo
FILE_TYPE_FO    equ 1           ; Font (.1fo)
FILE_TYPE_IN    equ 2           ; Interface (.1in)
FILE_TYPE_AT    equ 3           ; Attribute (.1at)
FILE_TYPE_SP    equ 4           ; Sprite (.1sp)
FILE_TYPE_SO    equ 5           ; Sound (.1so)
FILE_TYPE_TS    equ 6           ; Tileset (.1ts)
FILE_TYPE_MP    equ 7           ; Map (.1mp)

section .bss
vfs_base:       resd 1          ; Base do VFS na memória
vfs_size:       resd 1          ; Tamanho total do VFS
file_table:     resd 1          ; Ponteiro para tabela de arquivos
num_files:      resd 1          ; Número de arquivos no VFS
temp_buffer:    resb 1024*1024  ; Buffer temporário para arquivos

section .text
; Inicializa o VFS
; Entrada: esi = ponteiro para data.1rc
; Saída: eax = 1 (sucesso) ou 0 (erro)
global init_vfs
init_vfs:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Salvar base do VFS
    mov [vfs_base], esi
    
    ; Verificar magic number
    mov eax, [esi]
    cmp eax, VFS_MAGIC
    jne .error
    
    ; Ler número de arquivos e offset da tabela
    mov eax, [esi + VFS_HEADER_SIZE]
    mov [num_files], eax
    mov ebx, [esi + VFS_HEADER_SIZE + 4]
    
    ; Calcular ponteiro para tabela
    add esi, ebx
    mov [file_table], esi
    
    mov eax, 1          ; Sucesso
    jmp .done
    
.error:
    xor eax, eax        ; Erro
    
.done:
    pop edi
    pop ebx
    pop ebp
    ret

; Encontra arquivo por nome
; Entrada: esi = nome do arquivo
; Saída: eax = ponteiro para entrada ou 0 se não encontrado
global vfs_find_file
vfs_find_file:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    mov ebx, esi           ; Nome buscado
    mov esi, [file_table]  ; Tabela de arquivos
    mov ecx, [num_files]   ; Contador
    
.loop:
    test ecx, ecx
    jz .not_found
    
    ; Comparar nome
    push ecx
    mov edi, [esi + 4]     ; Nome na entrada
    mov ecx, [esi]         ; Tamanho do nome
    push esi
    mov esi, ebx
    repe cmpsb
    pop esi
    pop ecx
    je .found
    
    ; Próxima entrada
    add esi, 12            ; Tamanho da entrada
    dec ecx
    jmp .loop
    
.found:
    mov eax, esi
    jmp .done
    
.not_found:
    xor eax, eax
    
.done:
    pop edi
    pop ebx
    pop ebp
    ret

; Carrega arquivo do VFS
; Entrada: esi = nome do arquivo, edi = buffer destino
; Saída: eax = tamanho lido ou 0 se erro
global vfs_load_file
vfs_load_file:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Encontrar arquivo
    call vfs_find_file
    test eax, eax
    jz .error
    
    ; Calcular ponteiro fonte
    mov edx, [vfs_base]
    add edx, [eax + 8]     ; Offset do arquivo
    
    ; Copiar dados
    mov ecx, [eax + 12]    ; Tamanho do arquivo
    push ecx               ; Salvar tamanho para retorno
    mov esi, edx          ; Fonte
    rep movsb             ; Copiar
    
    pop eax               ; Restaurar tamanho como retorno
    jmp .done
    
.error:
    xor eax, eax
    
.done:
    pop edi
    pop ebx
    pop ebp
    ret

; Retorna tipo do arquivo
; Entrada: esi = nome do arquivo
; Saída: eax = tipo do arquivo ou 0 se erro
global vfs_get_file_type
vfs_get_file_type:
    push ebp
    mov ebp, esp
    
    ; Encontrar arquivo
    call vfs_find_file
    test eax, eax
    jz .error
    
    ; Retornar tipo
    movzx eax, byte [eax + 16]  ; Tipo do arquivo
    jmp .done
    
.error:
    xor eax, eax
    
.done:
    pop ebp
    ret

; Verifica se arquivo existe
; Entrada: esi = nome do arquivo
; Saída: eax = 1 se existe, 0 se não
global vfs_file_exists
vfs_file_exists:
    push ebp
    mov ebp, esp
    
    call vfs_find_file
    test eax, eax
    setnz al
    movzx eax, al
    
    pop ebp
    ret