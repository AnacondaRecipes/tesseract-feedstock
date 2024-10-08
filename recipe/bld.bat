:: cmd

echo "Building %PKG_NAME%."
cd tesseract
if errorlevel 1 exit /b 1

:: Isolate the build.
mkdir Build-%PKG_NAME%
cd Build-%PKG_NAME%
if errorlevel 1 exit /b 1

:: Generate the build files.
echo "Generating the build files..."
cmake -G "NMake Makefiles" ^
    %CMAKE_ARGS% ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -D CMAKE_INCLUDE_PATH=%LIBRARY_INC% ^
    -D CMAKE_LIBRARY_PATH=%LIBRARY_LIB% ^
    -D CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -D Leptonica_DIR=%LIBRARY_PREFIX% ^
    :: The real place where leptonica headers are:
    ::-D Leptonica_INCLUDE_DIRS=%LIBRARY_PREFIX%\include\leptonica ^
    -D SW_BUILD=OFF ^
    -D BUILD_TRAINING_TOOLS=OFF ^
    -D BUILD_SHARED_LIBS=ON ^
    -D CMAKE_MODULE_LINKER_FLAGS=-whole-archive ^
    ..
if errorlevel 1 exit 1

cmake --build . --config Release
if errorlevel 1 exit 1

cmake --build . --config Release --target install 
if errorlevel 1 exit 1

:: Make copies of the .lib file without the embedded version number
copy %LIBRARY_LIB%\tesseract41.lib %LIBRARY_LIB%\tesseract.lib

:: Copy tessdata to shared directory
mkdir %PREFIX%\share\tessdata
copy ..\..\tessdata_fast\*.traineddata %PREFIX%\share\tessdata

setlocal EnableDelayedExpansion
:: Copy the [de]activate scripts to %PREFIX%\etc\conda\[de]activate.d.
:: This will allow them to be run on environment activation.
for %%F in (activate deactivate) DO (
    if not exist %PREFIX%\etc\conda\%%F.d mkdir %PREFIX%\etc\conda\%%F.d
    copy %RECIPE_DIR%\%%F.bat %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.bat
    if %errorlevel% neq 0 exit /b %errorlevel%

    :: Copy unix shell activation scripts, needed by Windows Bash users
    copy %RECIPE_DIR%\%%F.sh %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.sh
    if %errorlevel% neq 0 exit /b %errorlevel%

    :: Copy unix shell activation scripts, needed by Windows Bash users
    copy %RECIPE_DIR%\%%F.ps1 %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.ps1
    if %errorlevel% neq 0 exit /b %errorlevel%
)

:: Error free exit.
echo "Error free exit!"
exit 0
