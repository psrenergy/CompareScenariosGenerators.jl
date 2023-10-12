@echo off

SET MODEL_PATH=%~dp0

python %MODEL_PATH%\smart_forecast.py %*
