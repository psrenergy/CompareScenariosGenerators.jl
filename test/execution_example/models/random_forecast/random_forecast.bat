@echo off

SET MODEL_PATH=%~dp0

julia --project=%MODEL_PATH% %MODEL_PATH%\random_forecast.jl %*