; Sistema de Áudio
%ifndef AUDIO_ASM
%define AUDIO_ASM

section .text
global init_audio
global play_sound
global stop_sound

init_audio:
    pushad
    ; Configurar PIT para som
    mov al, 0xB6
    out 0x43, al
    popad
    ret

play_sound:
    push ebp
    mov ebp, esp
    pushad
    
    mov eax, [ebp+8]    ; Frequência
    
    ; Calcular valor para PIT
    mov edx, 0
    mov ecx, 1193180
    div ecx
    
    ; Programar speaker
    out 0x42, al
    mov al, ah
    out 0x42, al
    
    ; Ligar speaker
    in al, 0x61
    or al, 0x03
    out 0x61, al
    
    popad
    mov esp, ebp
    pop ebp
    ret

stop_sound:
    pushad
    ; Desligar speaker
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    popad
    ret

%endif