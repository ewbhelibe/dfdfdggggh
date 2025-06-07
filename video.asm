; video.asm (mantido como está)
%ifndef VIDEO_ASM
%define VIDEO_ASM

%include "common.inc"

section .data
current_color db 1    ; Cor atual para desenho (8bpp)

section .text
; draw_rectangle(x, y, width, height)
global draw_rectangle
draw_rectangle:
    ; ... seu código existente ...

; clear_buffer()
global clear_buffer
clear_buffer:
    ; ... seu código existente ...

; flip_buffer()
global flip_buffer
flip_buffer:
    ; ... seu código existente ...

; set_color(color)
global set_color
set_color:
    ; ... seu código existente ...

%endif