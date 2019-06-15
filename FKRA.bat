@ECHO OFF
SETLOCAL EnableExtensions EnableDelayedExpansion
ECHO Called: %*
ECHO    CWD: %cd%

REM /*******************************************************************************
REM  * FKRA.bat
REM  *
REM  * Generate Flesch-Kincaid Readability Assessment PDF
REM  * From Merged XML
REM  * Via saxon and wkhtmltopdf
REM  *
REM  * $1 = Full path to .xml file (E.G. V:\Extracts\m7341315\m7341315.xml)
REM  *
REM  *******************************************************************************/

ECHO ************************************************************
ECHO * Flesch-Kincaid Readability Assessment (FKRA) PDF
ECHO *
ECHO ************************************************************

REM // Settings overrides used by the batch scripts
REM # Get commandline args before loading settings
set INPUTFILE=%~nx1
set INPUTFOLDER=%~dp1

REM # Settings and Variables
REM # Random number used for temp folder and log
set LAMEID=-%RANDOM%

set STYLEROOT=%~dp0

REM // LOGFILE - The path / filename where batch logs should be stored
set LOGFILE=.\FKRA.LOG
set TEMPFOLDER=%STYLEROOT%Temp
set OUTPUTFOLDER=%STYLEROOT%Output
set SCRIPTSFOLDER=%STYLEROOT%
set SAXONFOLDER=S:\Processors\saxon
set XSLFOLDER=%STYLEROOT%XSL

REM // Environment variables for Saxon
set CATALOG=S:\DITA_LFS_12\catalog-dita.xml



:start
REM // Clear the logfile and put something sorta useful at the top
ECHO [START] %0 > %LOGFILE% 2>&1

REM // Save a copy of the input files to temp folder and work on them from there
MKDIR %TEMPFOLDER%
COPY /Y %INPUTFOLDER%%INPUTFILE% %TEMPFOLDER%



:generate
REM /*
REM  * Generate output with Saxon and wkhtmltopdf
REM  */
ECHO ============================================================
ECHO = Generating PDF
ECHO = Wait for "Press any key to continue..."
ECHO ============================================================

MKDIR %OUTPUTFOLDER% >> "%LOGFILE%" 2>&1

REM // Create PDF
ECHO - Step 1/3: Create Summary Report HTML
COPY /Y "%XSLFOLDER%\fkstyle.css" "%TEMPFOLDER%"

CALL "%SAXONFOLDER%\Transform.exe" -catalog:"%CATALOG%" -s:"%TEMPFOLDER%\%INPUTFILE%" -xsl:"%XSLFOLDER%\FKRA.xsl" -o:"%TEMPFOLDER%\FKScore.html" detail=2
if %errorlevel% neq 0 goto exit_with_error


ECHO - Step 2/3: Create Debug HTML (%TEMPFOLDER%\FKScore-debug.html)
CALL "%SAXONFOLDER%\Transform.exe" -catalog:"%CATALOG%" -s:"%TEMPFOLDER%\%INPUTFILE%" -xsl:"%XSLFOLDER%\FKRA.xsl" -o:"%TEMPFOLDER%\FKScore-debug.html" detail=10
if %errorlevel% neq 0 goto exit_with_error


ECHO - Step 3/3: Convert HTML to PDF
ECHO --SKIPPED--
goto :EOF

CALL "%TOOLSFOLDER%\wkhtmltopdf32\bin\wkhtmltopdf.exe" --print-media-type --page-size Letter -O portrait --dpi 115 --header-line --header-left [date] --header-center "Flesch Kincaid Readability Assessment" --header-right "Page [page]/[toPage]" "%TEMPFOLDER%\FKScore.html" "%OUTPUTFOLDER%\%VASONTID%-fkra.pdf" >> "%LOGFILE%" 2>&1



REM // Exit points
:exit_no_error
REM // Put something sorta useful at the bottom
ECHO [END] %0 >> "%LOGFILE%" 2>&1
echo FKRA Done
echo .
pause
start explorer "%OUTPUTFOLDER%"
exit /B 0


:exit_with_error
REM // Put something sorta useful at the bottom
ECHO [END (Errors)] %0 >> "%LOGFILE%" 2>&1
echo FKRA Done (with errors: See %LOGFILE%)
echo .
pause
start notepad "%LOGFILE%"
exit /B 1
