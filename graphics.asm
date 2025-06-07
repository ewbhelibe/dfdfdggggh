; graphics.asm
%ifndef GRAPHICS_ASM
%define GRAPHICS_ASM

%include "common.inc"

extern vfs_load_file
extern vfs_get_file_type
extern draw_rectangle
extern clear_buffer
extern flip_buffer
extern set_color

section .data
FILE_TYPE_SP  equ 4   ; Tipo de arquivo sprite

section .text
; Função para desenhar sprite do VFS
; Entrada: esi = buffer do sprite, edi = destino na tela, ecx = largura, edx = altura
global draw_sprite
draw_sprite:
    pushad
    
    ; Verificar header PNG
    mov eax, [esi]
    cmp eax, 0x474E5089  ; PNG magic
    jne .error
    
    ; Por enquanto, apenas copia os pixels diretamente
    ; Você pode adicionar decodificação PNG depois
.copy_loop:
    push ecx
    rep movsb            ; Copiar linha
    pop ecx
    add edi, 640         ; Próxima linha
    dec edx
    jnz .copy_loop
    
.error:
    popad
    ret

%endif