@echo off
REM Docker utility commands for easy management

echo ================================
echo   Docker Management Menu
echo ================================
echo.
echo 1. Start services
echo 2. Stop services
echo 3. View logs (all)
echo 4. View backend logs
echo 5. View database logs
echo 6. Restart services
echo 7. Rebuild and restart
echo 8. Check status
echo 9. Connect to database
echo 10. Backup database
echo 11. Clean everything (DANGER!)
echo 0. Exit
echo.

set /p choice="Enter your choice: "

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto logs_all
if "%choice%"=="4" goto logs_backend
if "%choice%"=="5" goto logs_postgres
if "%choice%"=="6" goto restart
if "%choice%"=="7" goto rebuild
if "%choice%"=="8" goto status
if "%choice%"=="9" goto db_connect
if "%choice%"=="10" goto backup
if "%choice%"=="11" goto clean
if "%choice%"=="0" goto end

:start
echo Starting services...
docker-compose up -d
pause
goto end

:stop
echo Stopping services...
docker-compose down
pause
goto end

:logs_all
echo Showing all logs (Ctrl+C to exit)...
docker-compose logs -f
goto end

:logs_backend
echo Showing backend logs (Ctrl+C to exit)...
docker-compose logs -f backend
goto end

:logs_postgres
echo Showing postgres logs (Ctrl+C to exit)...
docker-compose logs -f postgres
goto end

:restart
echo Restarting services...
docker-compose restart
pause
goto end

:rebuild
echo Rebuilding and restarting...
docker-compose up -d --build
pause
goto end

:status
echo Checking service status...
docker-compose ps
echo.
echo Testing backend health...
curl -s http://localhost:5010/health
echo.
pause
goto end

:db_connect
echo Connecting to database...
echo Type \q to exit database shell
echo.
docker-compose exec postgres psql -U postgres -d sensor_db
goto end

:backup
echo Creating database backup...
set timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
docker-compose exec postgres pg_dump -U postgres sensor_db > backup_%timestamp%.sql
echo Backup created: backup_%timestamp%.sql
pause
goto end

:clean
echo.
echo WARNING: This will delete ALL data and containers!
echo.
set /p confirm="Are you sure? (type YES): "
if "%confirm%"=="YES" (
    echo Cleaning everything...
    docker-compose down -v
    docker system prune -f
    echo Done!
) else (
    echo Cancelled.
)
pause
goto end

:end
echo.
echo Bye!
