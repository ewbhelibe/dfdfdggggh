@echo off
setlocal enabledelayedexpansion

:: Definir caminhos
set NASM_PATH=C:\Dev\nasm\nasm.exe
set QEMU_PATH=C:\Program Files\qemu\qemu-system-i386.exe
set WORK_DIR=C:\Dev\horizonsystem
set OUTPUT_PATH=%WORK_DIR%\build
set ASSETS_PATH=%WORK_DIR%\assets

:: Cores para output
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set RESET=[0m

:: Verificar NASM
if not exist "%NASM_PATH%" (
    echo %RED%Erro: NASM não encontrado em %NASM_PATH%!%RESET%
    goto error
)

:: Criar diretório de saída se não existir
if not exist %OUTPUT_PATH% mkdir %OUTPUT_PATH%

echo %YELLOW%Compilando Engine001 Bare Metal...%RESET%

:: Verificar se data.1rc existe
if not exist "%ASSETS_PATH%\data.1rc" (
    echo %RED%Erro: data.1rc não encontrado em %ASSETS_PATH%!%RESET%
    goto error
)

:: Compilar bootloader
echo Compilando boot.asm...
"%NASM_PATH%" -f bin "%WORK_DIR%\boot.asm" -o "%OUTPUT_PATH%\boot.bin"
if errorlevel 1 goto error

:: Compilar stage2
echo Compilando stage2.asm...
"%NASM_PATH%" -f bin "%WORK_DIR%\stage2.asm" -o "%OUTPUT_PATH%\stage2.bin" -i "%WORK_DIR%"
if errorlevel 1 goto error

:: Criar imagem do disco
echo %YELLOW%Criando imagem do disco...%RESET%
fsutil file createnew "%OUTPUT_PATH%\engine001.img" 1474560
copy /b "%OUTPUT_PATH%\boot.bin" + "%OUTPUT_PATH%\stage2.bin" + "%ASSETS_PATH%\data.1rc" "%OUTPUT_PATH%\engine001.img" > nul

echo %GREEN%Compilação concluída!%RESET%

:: Perguntar modo de execução
set /p DEBUG=Executar em modo debug? (S/N) 
if /i "%DEBUG%"=="S" (
    echo %YELLOW%Executando em modo debug...%RESET%
    cd %OUTPUT_PATH%
    "%QEMU_PATH%" -fda engine001.img -monitor stdio
) else (
    echo %YELLOW%Executando normalmente...%RESET%
    cd %OUTPUT_PATH%
    "%QEMU_PATH%" -fda engine001.img
)
goto end

:error
echo %RED%Erro na compilação!%RESET%

:end
pause