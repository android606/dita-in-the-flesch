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
set RANDOMID=-%RANDOM%

set STYLEROOT=%~dp0

set OUTPUTFOLDER=%STYLEROOT%\Output
set SCRIPTSFOLDER=%STYLEROOT%
set SAXONFOLDER=%STYLEROOT%\saxon
set XSLFOLDER=%STYLEROOT%\XSL

REM // XML Catalog for Saxon
set CATALOG=%STYLEROOT%\Catalog\catalog-dita.xml




:start
ECHO [START] %0

mkdir %OUTPUTFOLDER%




:generate
REM /*
REM  * Generate output with Saxon and wkhtmltopdf
REM  */
ECHO ============================================================
ECHO = Generating Flesch-Kincaid PDF
ECHO = Wait for "Press any key to continue..."
ECHO ============================================================

MKDIR %OUTPUTFOLDER% >> "%LOGFILE%" 2>&1

REM // Create HTML and then PDF

ECHO - Step 1/3: Create Summary Report HTML
COPY /Y "%XSLFOLDER%\fkstyle.css" "%OUTPUTFOLDER%"
CALL ".\saxon\Transform.exe" -catalog:"%CATALOG%" -s:"%INPUTFOLDER%\%INPUTFILE%" -xsl:"%XSLFOLDER%\FKRA.xsl" -o:"%OUTPUTFOLDER%\FKScore.html" detail=2
if %errorlevel% neq 0 goto exit_with_error

ECHO - Step 2/3: Create Debug HTML (%OUTPUTFOLDER%\FKScore-debug.html)
CALL ".\saxon\Transform.exe" -catalog:"%CATALOG%" -s:"%INPUTFOLDER%\%INPUTFILE%" -xsl:"%XSLFOLDER%\FKRA.xsl" -o:"%OUTPUTFOLDER%\FKScore-debug.html" detail=10
if %errorlevel% neq 0 goto exit_with_error

ECHO - Step 3/3: Convert HTML to PDF
CALL ".\wkhtmltox\bin\wkhtmltopdf.exe" --print-media-type --page-size Letter -O portrait --dpi 115 --header-line --header-left [date] --header-center "Flesch Kincaid Readability Assessment" --header-right "Page [page]/[toPage]" "%OUTPUTFOLDER%\FKScore.html" "%OUTPUTFOLDER%\FKScore%RANDOMID%.pdf"




REM // Exit points
:exit_no_error
REM // Put something sorta useful at the bottom
ECHO [END] %0 
echo FKRA Done
echo .
pause
start explorer "%OUTPUTFOLDER%"
exit /B 0


:exit_with_error
REM // Put something sorta useful at the bottom
ECHO [END (Errors)] %0
echo FKRA Done (with errors)
echo .
pause
exit /B 1
