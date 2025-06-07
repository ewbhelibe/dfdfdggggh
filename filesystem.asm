; Sistema de Arquivos RC
%ifndef FILESYSTEM_ASM
%define FILESYSTEM_ASM

%include "common.inc"

section .data
rc_data         dd 0        ; Ponteiro para os dados do RC
rc_initialized  db 0        ; Flag de inicialização

; Estruturas para arquivos RC
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

section .text
global load_rc_file
global get_resource
global rc_data

; Inicializar sistema de arquivos RC
load_rc_file:
    pushad
    
    ; Verificar assinatura
    mov eax, [DATA_ADDR]
    cmp dword [eax], '1RC0'    ; Especificar tamanho dword
    jne .error
    
    ; Salvar ponteiro para os dados
    mov dword [rc_data], DATA_ADDR    ; Especificar tamanho dword
    
    ; Marcar como inicializado
    mov byte [rc_initialized], 1
    
    popad
    xor eax, eax    ; Retornar sucesso
    ret

.error:
    popad
    mov eax, 1      ; Retornar erro
    ret

; get_resource(name) -> retorna ponteiro para o recurso ou 0 se não encontrar
get_resource:
    push ebp
    mov ebp, esp
    pushad
    
    ; Verificar se sistema está inicializado
    cmp byte [rc_initialized], 0
    je .error
    
    ; Obter ponteiro para os dados
    mov esi, [rc_data]
    mov ecx, [esi + RC_HEADER.num_files]
    add esi, RC_HEADER_size        ; Pular header
    
    ; Procurar arquivo pelo nome
    mov edi, [ebp + 8]            ; Nome do arquivo a procurar
.search_loop:
    push ecx
    push edi
    push esi
    mov ecx, 12                   ; Tamanho do nome
    rep cmpsb                     ; Comparar nomes
    pop esi
    pop edi
    pop ecx
    je .found
    
    add esi, RC_FILE_ENTRY_size   ; Próxima entrada
    loop .search_loop
    jmp .error

.found:
    ; Retornar ponteiro para os dados do arquivo
    mov eax, [esi + RC_FILE_ENTRY.offset]
    add eax, [rc_data]            ; Adicionar base
    mov [esp + 28], eax           ; Salvar em eax do pushad
    popad
    mov esp, ebp
    pop ebp
    ret

.error:
    popad
    xor eax, eax                  ; Retornar 0
    mov esp, ebp
    pop ebp
    ret

%endif