@echo off

:: Caminhos
set NASM=C:\Dev\nasm\nasm.exe
set QEMU=C:\Program Files\qemu\qemu-system-i386.exe
set WORK_DIR=C:\Dev\horizonsystem
set OUT=%WORK_DIR%\build

:: Criar pasta build se não existir
if not exist %OUT% mkdir %OUT%

:: Compilar cada arquivo
echo Compilando...
"%NASM%" -f bin %WORK_DIR%\boot.asm -o %OUT%\boot.bin
"%NASM%" -f bin %WORK_DIR%\stage2.asm -o %OUT%\stage2.bin
"%NASM%" -f bin %WORK_DIR%\memory.asm -o %OUT%\memory.bin
"%NASM%" -f bin %WORK_DIR%\video.asm -o %OUT%\video.bin
"%NASM%" -f bin %WORK_DIR%\audio.asm -o %OUT%\audio.bin
"%NASM%" -f bin %WORK_DIR%\filesystem.asm -o %OUT%\filesystem.bin
"%NASM%" -f bin %WORK_DIR%\main.asm -o %OUT%\main.bin

:: Criar imagem de disco
echo Criando imagem...
fsutil file createnew "%OUT%\engine001.img" 1474560
copy /b %OUT%\boot.bin + %OUT%\stage2.bin %OUT%\engine001.img

:: Copiar arquivos de dados
copy %WORK_DIR%\data.1rc %OUT%\ > nul
copy %WORK_DIR%\Engine001.js %OUT%\ > nul

:: Executar
echo Executando...
cd %OUT%
"%QEMU%" -fda engine001.img

pause