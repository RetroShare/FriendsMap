@echo off
setlocal EnableExtensions EnableDelayedExpansion
rem ===========================================================================
rem  deploy-friendsmap.bat - copy FriendsMap plugin + Marble + GeoIP data
rem  into a RetroShare folder on Windows (MSYS2 MinGW64 build).
rem
rem  Usage:
rem    deploy-friendsmap.bat "C:\path\to\RetroShare"      (folder with retroshare.exe)
rem
rem  Edit the paths below if your layout is different.
rem ===========================================================================

rem --- MSYS2 install (for the MinGW runtime / Qt DLLs Marble needs)
set "MSYS2_DIR=C:\msys64"
rem --- Marble install prefix (CMAKE_INSTALL_PREFIX used for Marble)
set "MARBLE_DIR=%~dp0..\..\..\marble\install"
rem --- GeoIP legacy City database (IPv4), converted from GeoLite2 by Miyuru Sankalpa
set "GEOIP_URL=https://dl.miyuru.lk/geoip/maxmind/city/maxmind4.dat.gz"
set "GEOIP_CACHE=%~dp0GeoLiteCity.dat"

rem ---------------------------------------------------------------------------
set "RS_DIR=%~1"
rem No argument (e.g. double-clicked): use the default below, else ask.
rem Default: the qmake build output of this RetroShare checkout.
if "%RS_DIR%"=="" set "RS_DIR=%~dp0..\..\retroshare-gui\src\release"
if not exist "%RS_DIR%\retroshare.exe" (
    echo retroshare.exe not found in "%RS_DIR%"
    set "RS_DIR="
    set /p "RS_DIR=Folder that contains retroshare.exe: "
)
if "%RS_DIR%"=="" goto :fail
set "RS_DIR=%RS_DIR:"=%"
if not exist "%RS_DIR%\retroshare.exe" (
    echo [ERROR] retroshare.exe not found in "%RS_DIR%"
    goto :fail
)
for %%I in ("%RS_DIR%") do set "RS_DIR=%%~fI"
for %%I in ("%MARBLE_DIR%") do set "MARBLE_DIR=%%~fI"
set "MINGW_BIN=%MSYS2_DIR%\mingw64\bin"
set "LDD=%MSYS2_DIR%\usr\bin\ldd.exe"

rem --- Extensions folder: portable (Data\ next to the exe) or %APPDATA%
if exist "%RS_DIR%\Data\" (
    set "EXT_DIR=%RS_DIR%\Data\extensions6"
) else (
    set "EXT_DIR=%APPDATA%\RetroShare\extensions6"
)
if not exist "%EXT_DIR%" mkdir "%EXT_DIR%"

echo RetroShare : %RS_DIR%
echo Extensions : %EXT_DIR%
echo Marble     : %MARBLE_DIR%
echo.

rem ===========================================================================
rem 1. Plugin DLL (qmake: lib\FriendMap.dll, CMake: build\plugins\libFriendMap.dll)
rem ===========================================================================
set "PLUGIN_DLL="
for %%F in ("%~dp0lib\FriendMap.dll" "%~dp0release\FriendMap.dll" "%~dp0..\..\Build-cmake\plugins\libFriendMap.dll" "%~dp0build\plugins\libFriendMap.dll") do (
    if not defined PLUGIN_DLL if exist "%%~F" set "PLUGIN_DLL=%%~fF"
)
if not defined PLUGIN_DLL (
    echo [ERROR] FriendMap plugin DLL not found. Build the plugin first.
    goto :fail
)
echo [1/5] Plugin: %PLUGIN_DLL%
copy /y "%PLUGIN_DLL%" "%EXT_DIR%\" >nul || (echo [ERROR] copy failed & goto :fail)

rem ===========================================================================
rem 2. Marble library DLLs (libmarblewidget-qt5.dll, libastro.dll, ...)
rem ===========================================================================
echo [2/5] Marble DLLs
set "MARBLE_DLL_FOUND="
for %%D in ("%MARBLE_DIR%" "%MARBLE_DIR%\bin" "%MARBLE_DIR%\lib") do (
    if exist "%%~D\*.dll" (
        for %%L in ("%%~D\*.dll") do (
            copy /y "%%~L" "%RS_DIR%\" >nul
            echo        %%~nxL
            set "MARBLE_DLL_FOUND=1"
        )
    )
)
if not defined MARBLE_DLL_FOUND (
    echo [ERROR] No Marble DLLs found in "%MARBLE_DIR%". Did "make install" succeed?
    goto :fail
)

rem ===========================================================================
rem 3. Marble data + plugins  ->  RetroShare\marble\data, RetroShare\marble\plugins
rem    (FriendMapSettings looks for <exe dir>\marble first)
rem ===========================================================================
echo [3/5] Marble data and plugins
set "M_DATA="
for %%D in ("%MARBLE_DIR%\data" "%MARBLE_DIR%\share\marble\data") do (
    if not defined M_DATA if exist "%%~D\" set "M_DATA=%%~fD"
)
set "M_PLUGINS="
for %%D in ("%MARBLE_DIR%\plugins" "%MARBLE_DIR%\lib\marble\plugins" "%MARBLE_DIR%\lib\plugins\marble") do (
    if not defined M_PLUGINS if exist "%%~D\" set "M_PLUGINS=%%~fD"
)
if not defined M_DATA    (echo [ERROR] Marble data folder not found under "%MARBLE_DIR%" & goto :fail)
if not defined M_PLUGINS (echo [ERROR] Marble plugins folder not found under "%MARBLE_DIR%" & goto :fail)
echo        data    : !M_DATA!
echo        plugins : !M_PLUGINS!
robocopy "!M_DATA!"    "%RS_DIR%\marble\data"    /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo [ERROR] copying Marble data failed & goto :fail)
robocopy "!M_PLUGINS!" "%RS_DIR%\marble\plugins" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo [ERROR] copying Marble plugins failed & goto :fail)

rem ===========================================================================
rem 4. MinGW / Qt runtime DLLs needed by the plugin, Marble and Marble plugins
rem    (only copies DLLs that are missing in the RetroShare folder)
rem ===========================================================================
echo [4/5] Runtime DLLs from MSYS2
if not exist "%LDD%" (
    echo        [WARN] %LDD% not found - skipping. Copy missing DLLs by hand.
    goto :geoip
)
set "DEPLIST=%TEMP%\friendsmap_deps.txt"
if exist "%DEPLIST%" del "%DEPLIST%"
"%LDD%" "%PLUGIN_DLL%" >> "%DEPLIST%" 2>nul
for %%L in ("%RS_DIR%\libmarblewidget*.dll" "%RS_DIR%\libastro*.dll") do "%LDD%" "%%~fL" >> "%DEPLIST%" 2>nul
for /r "%RS_DIR%\marble\plugins" %%L in (*.dll) do "%LDD%" "%%~fL" >> "%DEPLIST%" 2>nul
set /a NCOPIED=0
for /f "usebackq tokens=1,3" %%A in ("%DEPLIST%") do (
    echo %%B | findstr /i /b "/mingw64/" >nul && (
        if not exist "%RS_DIR%\%%A" if exist "%MINGW_BIN%\%%A" (
            copy /y "%MINGW_BIN%\%%A" "%RS_DIR%\" >nul
            echo        %%A
            set /a NCOPIED+=1
        )
    )
)
del "%DEPLIST%" 2>nul
echo        !NCOPIED! DLL(s) copied

:geoip
rem ===========================================================================
rem 5. GeoLiteCity.dat (legacy GeoIP City, IPv4) -> extensions folder
rem    Downloaded once and cached next to this script. Delete the cached
rem    GeoLiteCity.dat to download a newer one. Please don't download more
rem    than a few times per day (requested by the host).
rem ===========================================================================
echo [5/5] GeoLiteCity.dat
if not exist "%GEOIP_CACHE%" (
    echo        downloading %GEOIP_URL%
    curl.exe -L --fail -o "%GEOIP_CACHE%.gz" "%GEOIP_URL%" || (
        echo [ERROR] download failed. Download it by hand from https://www.miyuru.lk/geoiplegacy
        echo         ^(City, MaxMind, IPv4^), unpack it and save it as "%GEOIP_CACHE%"
        goto :fail
    )
    powershell -NoProfile -Command ^
      "$i=[IO.File]::OpenRead('%GEOIP_CACHE%.gz'); $o=[IO.File]::Create('%GEOIP_CACHE%');" ^
      "$g=New-Object IO.Compression.GZipStream($i,[IO.Compression.CompressionMode]::Decompress);" ^
      "$g.CopyTo($o); $g.Close(); $o.Close(); $i.Close()" || (echo [ERROR] unpacking failed & goto :fail)
    del "%GEOIP_CACHE%.gz"
) else (
    echo        using cached "%GEOIP_CACHE%"
)
copy /y "%GEOIP_CACHE%" "%EXT_DIR%\GeoLiteCity.dat" >nul || (echo [ERROR] copy failed & goto :fail)

echo.
echo Done. Start RetroShare - the first start can be slow.
echo GeoIP data: Geolocation database of MaxMind converted by Miyuru Sankalpa.
echo This product includes GeoLite2 data created by MaxMind.
call :maybe_pause
endlocal
exit /b 0

:fail
echo.
echo Deploy FAILED.
call :maybe_pause
endlocal
exit /b 1

:maybe_pause
rem Keep the window open when the script was started by double-click
echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul && pause
exit /b 0
