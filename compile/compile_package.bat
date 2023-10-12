@echo off

SET BASEPATH=%~dp0

julia --project=%BASEPATH% --color=yes %BASEPATH%\compile.jl