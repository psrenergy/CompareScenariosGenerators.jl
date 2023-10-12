@echo off

SET MODEL_PATH=%~dp0

Rscript %MODEL_PATH%\statsforecast_forecast.r %*