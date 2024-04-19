@echo off
setlocal enabledelayedexpansion

:: Check if at least one argument is given (the file path)
IF "%~1"=="" (
    echo Please drag and drop a TIFF file on this batch script.
    pause
    exit /b
)

:: Activate the Conda environment
CALL C:\Users\%USERNAME%\anaconda3\Scripts\activate.bat video

:: Prepare the input and output file paths
set "input=%~1"
set "output=%~dpn1.avi"

:: Run the Python script
@REM echo Input File: !input!
@REM echo Output will be saved as: !output!
python "%~dp0convert_tiff_to_avi.py" "!input!" "!output!"
IF ERRORLEVEL 1 (
    echo An error occurred during conversion.
    pause
    exit /b
)

:: Deactivate environment and clean up
CALL conda deactivate
echo Conversion completed.
pause
endlocal

@REM The batch script runs the following setps: 
@REM 1/ It first checks if at least one argument is given (the file path of the TIFF file). If no argument is given, it will display a message and exit. 
@REM 2/ If an argument is given, it will activate the Conda environment
@REM 3/ Then it prepares the input and output file paths
@REM 4/ Runs the Python script, 
@REM 5/ Deactivates the environment, and display a message before exiting.

@REM This assumes an existing Conda environment named "video" with the necessary packages installed. 
@REM Update the environment name and paths as needed (e.g., minian). 
@REM To create a new Conda environment, you can use the following command: 
@REM conda create --name video python=3.9 imageio tifffile
@REM conda activate video
@REM pip install opencv-python
