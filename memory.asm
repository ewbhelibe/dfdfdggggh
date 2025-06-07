; Sistema de gerenciamento de memória
%ifndef MEMORY_ASM
%define MEMORY_ASM

%include "common.inc"

section .data
heap_current dd HEAP_START   ; Ponteiro atual do heap
heap_end     dd HEAP_START + HEAP_SIZE  ; Fim do heap
block_count  dd 0           ; Número de blocos alocados

; Estrutura de bloco de memória
struc MEM_BLOCK
    .size:    resd 1       ; Tamanho do bloco
    .used:    resb 1       ; Flag indicando se está em uso
    .reserved:resb 3       ; Padding para alinhamento
endstruc

section .text
global init_memory
global malloc
global free

; Inicializar sistema de memória
init_memory:
    push ebp
    mov ebp, esp
    
    ; Inicializar ponteiro do heap
    mov dword [heap_current], HEAP_START
    
    ; Criar bloco inicial livre
    mov eax, HEAP_START
    mov dword [eax + MEM_BLOCK.size], HEAP_SIZE - MEM_BLOCK_size
    mov byte [eax + MEM_BLOCK.used], 0
    
    mov esp, ebp
    pop ebp
    xor eax, eax  ; Retornar sucesso
    ret

; malloc(size) -> retorna ponteiro para memória alocada ou 0 se falhar
malloc:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    
    ; Obter tamanho requisitado
    mov ecx, [ebp + 8]
    add ecx, MEM_BLOCK_size  ; Adicionar tamanho do header
    
    ; Procurar bloco livre
    mov ebx, HEAP_START
.search:
    cmp ebx, [heap_end]
    jae .error              ; Chegou ao fim do heap
    
    ; Verificar se bloco está livre
    cmp byte [ebx + MEM_BLOCK.used], 0
    jne .next
    
    ; Verificar tamanho
    mov edx, [ebx + MEM_BLOCK.size]
    cmp edx, ecx
    jb .next               ; Bloco muito pequeno
    
    ; Encontrou bloco adequado
    mov byte [ebx + MEM_BLOCK.used], 1
    inc dword [block_count]
    
    ; Calcular endereço de retorno (após header)
    lea eax, [ebx + MEM_BLOCK_size]
    jmp .done
    
.next:
    ; Próximo bloco
    mov esi, [ebx + MEM_BLOCK.size]
    add ebx, esi
    add ebx, MEM_BLOCK_size
    jmp .search
    
.error:
    xor eax, eax          ; Retornar null
    
.done:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; free(ptr) -> libera memória alocada
free:
    push ebp
    mov ebp, esp
    
    ; Obter ponteiro
    mov eax, [ebp + 8]
    test eax, eax
    jz .done              ; Ignorar null
    
    ; Ajustar para header
    sub eax, MEM_BLOCK_size
    
    ; Marcar como livre
    mov byte [eax + MEM_BLOCK.used], 0
    dec dword [block_count]
    
.done:
    mov esp, ebp
    pop ebp
    ret

%endif