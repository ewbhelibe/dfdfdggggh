; main.asm
%ifndef MAIN_ASM
%define MAIN_ASM

%include "common.inc"

; Declarar funções externas do video.asm
extern clear_buffer
extern flip_buffer
extern draw_rectangle
extern set_color

; Declarar funções externas do filesystem
extern get_resource
extern init_vfs
extern vfs_load_file

section .data
frame_count  dd 0
game_state   dd 0    ; 0 = menu, 1 = jogando, 2 = game over
player_x     dd 320  ; Posição X do jogador
player_y     dd 400  ; Posição Y do jogador
player_speed dd 5    ; Velocidade do jogador
vfs_path     db 'data.1rc', 0
error_msg    db 'Error: Could not initialize VFS', 0
sprite_name  db 'player.1sp', 0

section .bss
sprite_buffer resb 1024*1024  ; Buffer para sprites

section .text
global main_loop

; Inicialização do VFS antes do loop principal
init_game:
    pushad
    
    ; Carregar e inicializar VFS
    mov esi, vfs_path
    call get_resource
    test eax, eax
    jz .error_vfs
    
    mov esi, eax
    call init_vfs
    test eax, eax
    jz .error_vfs
    
    ; Carregar sprite do jogador
    mov esi, sprite_name
    mov edi, sprite_buffer
    call vfs_load_file
    test eax, eax
    jz .error_vfs
    
    popad
    mov eax, 1
    ret

.error_vfs:
    popad
    xor eax, eax
    ret

main_loop:
    ; Inicializar VFS e recursos
    call init_game
    test eax, eax
    jz .error

    ; Inicializar estado do jogo
    mov dword [game_state], 0
    mov dword [frame_count], 0

.loop:
    ; Incrementar contador de frames
    inc dword [frame_count]
    
    ; Limpar buffer
    call clear_buffer
    
    ; Atualizar estado do jogo
    call update_game
    
    ; Renderizar frame
    call render_frame
    
    ; Mostrar frame
    call flip_buffer
    
    ; Repetir
    jmp .loop

.error:
    ret

update_game:
    pushad
    
    ; Ler input do teclado
    in al, 0x60     ; Ler scancode
    
    cmp al, 0x4B    ; Seta esquerda
    je .move_left
    cmp al, 0x4D    ; Seta direita
    je .move_right
    cmp al, 0x01    ; ESC
    je .exit
    jmp .done

.move_left:
    mov eax, [player_x]
    sub eax, [player_speed]
    cmp eax, 0              ; Limite esquerdo
    jl .done
    mov [player_x], eax
    jmp .done

.move_right:
    mov eax, [player_x]
    add eax, [player_speed]
    cmp eax, 640           ; Limite direito
    jg .done
    mov [player_x], eax
    jmp .done

.exit:
    cli
    hlt

.done:
    popad
    ret

render_frame:
    pushad
    
    ; Renderizar baseado no estado
    mov eax, [game_state]
    cmp eax, 0
    je render_menu
    cmp eax, 1
    je render_game
    cmp eax, 2
    je render_gameover
    
    popad
    ret

render_menu:
    ; Desenhar retângulo de fundo
    push dword 100         ; Height
    push dword 200         ; Width
    push dword 190         ; Y
    push dword 220         ; X
    call draw_rectangle
    add esp, 16
    ret

render_game:
    ; Desenhar jogador como sprite ou retângulo
    push dword 20          ; Height
    push dword 20          ; Width
    push dword [player_y]  ; Y
    push dword [player_x]  ; X
    call draw_rectangle
    add esp, 16
    ret

render_gameover:
    ; Desenhar tela de game over
    push dword 100         ; Height
    push dword 300         ; Width
    push dword 190         ; Y
    push dword 170         ; X
    call draw_rectangle
    add esp, 16
    ret

%endif