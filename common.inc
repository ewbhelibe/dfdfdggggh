; common.inc
%ifndef COMMON_INC
%define COMMON_INC

; Endereços de memória importantes
DATA_ADDR   equ 0x90000   ; Endereço onde data.1rc foi carregado
VESA_INFO   equ 0x3000    ; Endereço para informações VESA
MODE_INFO   equ 0x3200    ; Endereço para informações do modo
HEAP_START  equ 0x100000  ; Início do heap (1MB)
HEAP_SIZE   equ 0x100000  ; Tamanho do heap (1MB)

; Outros defines comuns aqui...

%endif