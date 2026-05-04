[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$REPO_DIR = "C:\Users\unsemana\PB_tracker"
$NEW_FILE = Join-Path $REPO_DIR "index_new.html"
$TARGET   = Join-Path $REPO_DIR "index.html"

Write-Host ""
Write-Host "=== 훈련 일지 배포 시작 ===" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $NEW_FILE)) {
    Write-Host "[X] 파일 없음: index_new.html" -ForegroundColor Red
    Write-Host "    저장 위치: $NEW_FILE" -ForegroundColor Cyan
    Read-Host "엔터로 종료"
    exit 1
}

if (-not (Test-Path "$REPO_DIR\.git")) {
    Write-Host "[X] git repo 없음: $REPO_DIR" -ForegroundColor Red
    Read-Host "엔터로 종료"
    exit 1
}

$size = (Get-Item $NEW_FILE).Length
if ($size -lt 100000) {
    Write-Host "[X] 파일 크기 비정상: $size bytes" -ForegroundColor Red
    Read-Host "엔터로 종료"
    exit 1
}
$sizeKB = [math]::Round($size / 1024, 1)
Write-Host "[OK] 새 파일 검증: $sizeKB KB" -ForegroundColor Green

Copy-Item -Path $NEW_FILE -Destination $TARGET -Force
Write-Host "[OK] index.html 덮어쓰기 완료" -ForegroundColor Green

Push-Location $REPO_DIR
try {
    git diff --quiet index.html 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[!] 파일 변화 없음. 종료." -ForegroundColor Yellow
        Pop-Location
        Read-Host "엔터로 종료"
        exit 0
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    git add index.html
    git commit -m "Update tracker $timestamp" 2>&1 | Out-Null
    Write-Host "[OK] Git commit 완료" -ForegroundColor Green

    git push origin main 2>&1 | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] GitHub push 완료" -ForegroundColor Green
    } else {
        Write-Host "[X] Push 실패" -ForegroundColor Red
        Pop-Location
        Read-Host "엔터로 종료"
        exit 1
    }
} finally {
    Pop-Location
}

$archiveName = "deployed-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".html.bak"
$archivePath = Join-Path $REPO_DIR $archiveName
Move-Item -Path $NEW_FILE -Destination $archivePath
Write-Host "[OK] 백업: $archiveName" -ForegroundColor Green

Write-Host ""
Write-Host "=== 배포 성공 ===" -ForegroundColor Green
Write-Host "URL: https://hanjujang.github.io/PB_tracker/"
Write-Host "1-2분 후 iPhone 새로고침"
Write-Host ""
Read-Host "엔터로 종료"