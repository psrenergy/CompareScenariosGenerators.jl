@echo off

@REM Colocar variaveis de ambiente se necessário
SET BASEPATH=%~dp0

julia --color=yes --project=%BASEPATH% %BASEPATH%\main.jl %*