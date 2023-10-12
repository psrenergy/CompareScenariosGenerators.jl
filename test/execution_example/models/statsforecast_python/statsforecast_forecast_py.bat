@echo off

SET MODEL_PATH=%~dp0

python %MODEL_PATH%\statsforecast_forecast.py %*
