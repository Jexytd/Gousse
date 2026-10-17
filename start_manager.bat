@echo off
title Gousse Script Hub Manager
echo ========================================================
echo  Starting Gousse Script Hub Manager
echo  URL: http://localhost:3456
echo ========================================================
start "" "http://localhost:3456"
node manager\server.js
pause
