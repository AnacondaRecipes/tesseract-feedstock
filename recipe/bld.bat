:: cmd

echo "Building %PKG_NAME%."
cd tesseract
if errorlevel 1 exit /b 1

:: Isolate the build.
mkdir build
cd build
if errorlevel 1 exit /b 1

:: Generate the build files. Ninja + MSVC, matching upstream's cmake-win64.yml
:: and the conda-forge recipe. SW_BUILD=OFF drops the old Software Network
:: client dependency that used to block the Windows build (removed upstream in 5.5.x).
echo "Generating the build files..."
cmake -G "Ninja" ^
    %CMAKE_ARGS% ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -D CMAKE_INCLUDE_PATH=%LIBRARY_INC% ^
    -D CMAKE_LIBRARY_PATH=%LIBRARY_LIB% ^
    -D CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -D Leptonica_DIR=%LIBRARY_PREFIX% ^
    -D SW_BUILD=OFF ^
    -D BUILD_TRAINING_TOOLS=OFF ^
    -D BUILD_SHARED_LIBS=ON ^
    ..
if errorlevel 1 exit 1

cmake --build . --config Release
if errorlevel 1 exit 1

cmake --build . --config Release --target install
if errorlevel 1 exit 1

:: Make a copy of the import lib without the embedded version number so
:: downstream consumers can link plain -ltesseract. Upstream names the
:: Windows lib tesseract<MAJOR><MINOR> (CMakeLists OUTPUT_NAME), i.e.
:: tesseract55 for 5.5.x -- NOT tesseract41 (that was the 4.1 name).
copy %LIBRARY_LIB%\tesseract55.lib %LIBRARY_LIB%\tesseract.lib
if errorlevel 1 exit /b 1

:: Copy tessdata to the shared directory that TESSDATA_PREFIX points at
:: (see activate.bat: %CONDA_PREFIX%\share\tessdata).
mkdir %PREFIX%\share\tessdata
copy ..\..\tessdata_fast\*.traineddata %PREFIX%\share\tessdata
if errorlevel 1 exit /b 1

:: The install lands under %LIBRARY_PREFIX% (= %PREFIX%\Library), so the
:: installed tessdata configs need to move across the Library split to where
:: TESSDATA_PREFIX expects them.
move %LIBRARY_PREFIX%\share\tessdata\configs %PREFIX%\share\tessdata
if errorlevel 1 exit /b 1

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
