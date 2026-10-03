@echo off
set TMP=.gluk_platforms
if exist %TMP% rmdir /s /q %TMP%
flutter create --project-name gluk_wave --platforms=android,ios,windows,linux,macos %TMP%
if errorlevel 1 exit /b 1
for %%D in (android ios windows linux macos) do (
  if exist %%D rmdir /s /q %%D
  move %TMP%\%%D %%D >nul
)
rmdir /s /q %TMP%
flutter pub get
if errorlevel 1 exit /b 1
echo.
echo Gluk Wave is ready. Try: flutter run -d windows
