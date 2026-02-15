# Raksha: Download ONNX Models
# Run this script from the project root directory:
#   powershell -ExecutionPolicy Bypass -File download_models.ps1

$modelsDir = "assets/models"

Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Raksha: Downloading ONNX Models" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Create models directory if not exists
if (-not (Test-Path $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null
}

# ============================================
# 1. Silero VAD Model (~2MB)
# ============================================
Write-Host "[1/2] Downloading Silero VAD model..." -ForegroundColor Yellow

$vadUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"
$vadFile = "$modelsDir/silero_vad.onnx"

if (Test-Path $vadFile) {
    Write-Host "  Already exists, skipping." -ForegroundColor Green
} else {
    try {
        Invoke-WebRequest -Uri $vadUrl -OutFile $vadFile -UseBasicParsing
        Write-Host "  Downloaded silero_vad.onnx" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to download from primary URL, trying alternate..." -ForegroundColor Red
        $vadUrlAlt = "https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-20M-2023-02-17/resolve/main/silero_vad.onnx"
        try {
            Invoke-WebRequest -Uri $vadUrlAlt -OutFile $vadFile -UseBasicParsing
            Write-Host "  Downloaded silero_vad.onnx (alternate)" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Could not download silero_vad.onnx" -ForegroundColor Red
        }
    }
}

# ============================================
# 2. Streaming ASR Model - Paraformer English (PROVEN WORKING)
# Small, fast, and actually works for streaming
# ============================================
Write-Host "[2/4] Downloading Paraformer streaming model..." -ForegroundColor Yellow

$modelUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2"
$modelArchive = "$modelsDir/paraformer.tar.bz2"

if ((Test-Path "$modelsDir/encoder.int8.onnx") -and (Test-Path "$modelsDir/decoder.onnx")) {
    Write-Host "  Models already exist, skipping download." -ForegroundColor Green
} else {
    try {
        Write-Host "  Downloading model archive (~80MB)..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $modelUrl -OutFile $modelArchive -UseBasicParsing
        
        Write-Host "  Extracting models..." -ForegroundColor Yellow
        tar -xjf $modelArchive -C $modelsDir
        
        # Find and move the extracted files
        $extractedDir = Get-ChildItem -Path $modelsDir -Directory | Where-Object { $_.Name -like "*paraformer*" } | Select-Object -First 1
        
        if ($extractedDir) {
            Write-Host "  Installing model files..." -ForegroundColor Yellow
            
            # Paraformer uses different file structure
            Copy-Item "$($extractedDir.FullName)/encoder.int8.onnx" "$modelsDir/encoder.int8.onnx" -Force
            Copy-Item "$($extractedDir.FullName)/decoder.int8.onnx" "$modelsDir/decoder.onnx" -Force
            Copy-Item "$($extractedDir.FullName)/joiner.int8.onnx" "$modelsDir/joiner.int8.onnx" -Force
            Copy-Item "$($extractedDir.FullName)/tokens.txt" "$modelsDir/tokens.txt" -Force
            
            # Cleanup
            Remove-Item $extractedDir.FullName -Recurse -Force
            Remove-Item $modelArchive -Force
            
            Write-Host "  ✅ Paraformer model installed successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ERROR: Download failed. Trying direct links..." -ForegroundColor Red
        
        # Fallback: Try simpler Zipformer model
        $baseUrl = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models"
        
        try {
            Write-Host "  Downloading Zipformer (fallback)..." -ForegroundColor Yellow
            Invoke-WebRequest -Uri "$baseUrl/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20.tar.bz2" -OutFile $modelArchive -UseBasicParsing
            tar -xjf $modelArchive -C $modelsDir
            
            $extractedDir = Get-ChildItem -Path $modelsDir -Directory | Where-Object { $_.Name -like "*zipformer*" } | Select-Object -First 1
            
            if ($extractedDir) {
                Copy-Item "$($extractedDir.FullName)/*.onnx" $modelsDir -Force
                Copy-Item "$($extractedDir.FullName)/tokens.txt" $modelsDir -Force
                Remove-Item $extractedDir.FullName -Recurse -Force
                Remove-Item $modelArchive -Force
                Write-Host "  ✅ Zipformer model installed" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ❌ ERROR: Could not download any working model" -ForegroundColor Red
            Write-Host "  Please download manually from: https://github.com/k2-fsa/sherpa-onnx/releases" -ForegroundColor Yellow
        }
    }
}

# ============================================
# Summary
# ============================================
Write-Host ""
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "  Download Complete!" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Models directory: $modelsDir" -ForegroundColor White
Write-Host ""

# List downloaded files
Write-Host "Files:" -ForegroundColor White
Get-ChildItem $modelsDir -File | ForEach-Object {
    $sizeMB = [math]::Round($_.Length / 1MB, 1)
    Write-Host "  $($_.Name) ($sizeMB MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next step: Run 'flutter run' to test the pipeline!" -ForegroundColor Yellow
Write-Host ""
