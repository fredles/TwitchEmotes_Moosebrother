[CmdletBinding()]
param(
    # Input can be an animated GIF or AVIF (also works for other formats ImageMagick can decode)
    [Parameter(Mandatory = $true)] [string] $InputGif,
    [Parameter(Mandatory = $true)] [string] $OutputTga,
    [int] $FrameWidth = 32,
    [int] $FrameHeight = 32,
    [int] $Framerate = 15,
    [string] $EmoteKey,
    [string] $InstallDir
)

# Purpose:
# - Convert an animated GIF/AVIF to a vertical TGA spritesheet for WoW texture tags
# - Print Lua metadata for TwitchEmotes_animation_metadata and defaultpack entries
#
# Requirements:
# - ImageMagick installed and available in PATH (magick.exe)
#   https://imagemagick.org/script/download.php#windows

$ErrorActionPreference = 'Stop'

function Ensure-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        $choco = Get-Command choco -ErrorAction SilentlyContinue
        $msg = @()
        $msg += "Required command '$Name' not found in PATH. Install ImageMagick 7 and ensure 'magick' is available."
        $msg += ""
        if ($winget) {
            $msg += "Option A (winget):"
            $msg += "  winget install --silent --accept-package-agreements --accept-source-agreements ImageMagick.ImageMagick"
        }
        if ($choco) {
            $msg += "Option B (choco):"
            $msg += "  choco install imagemagick"
        }
        $msg += "Option C (manual):"
        $msg += "  Download the Windows installer from https://imagemagick.org/script/download.php#windows"
        $msg += "  During install, ensure 'Add application directory to your system path' is checked."
        $msg += ""
        $msg += "AVIF inputs: Use a build with HEIF/AVIF (libheif) support. After install, verify with:"
        $msg += "  magick identify -list format | Select-String -Pattern 'HEIF|AVIF'"
        $msg += "Then close and reopen PowerShell so PATH updates are applied."
        throw ($msg -join [Environment]::NewLine)
    }
}

function Quote([string]$s) { return '"' + $s + '"' }

try {
    Ensure-Command -Name 'magick'

    # Back-compat: parameter is still named InputGif but accepts .gif, .avif, etc.
    $InputPath = $InputGif
    if (-not (Test-Path -LiteralPath $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $outDir = Split-Path -Parent $OutputTga
    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir | Out-Null
    }

    $ext = [System.IO.Path]::GetExtension($InputPath).ToLower()
    $isAvif = ($ext -eq '.avif')

    $frameCount = $null
    $usedFallback = $false

    # Try ImageMagick identify first
    $frameCount = & magick identify -format "%n" -- $InputPath 2>$null
    if (-not $frameCount -or -not ($frameCount -as [int])) {
        if ($isAvif) {
            # Attempt FFmpeg fallback regardless of ImageMagick format list
            $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
            if ($ffmpeg) {
                $tmp = Join-Path $env:TEMP ("te-avif-" + [Guid]::NewGuid().ToString())
                New-Item -ItemType Directory -Path $tmp | Out-Null
                try {
                    $vf = "scale=${FrameWidth}:${FrameHeight}:force_original_aspect_ratio=decrease,pad=${FrameWidth}:${FrameHeight}:(ow-iw)/2:(oh-ih)/2:color=0x00000000"
                    & ffmpeg -hide_banner -loglevel error -y -i $InputPath -vf $vf (Join-Path $tmp 'frame_%05d.png')
                    $pngs = Get-ChildItem -LiteralPath $tmp -Filter 'frame_*.png'
                    if (-not $pngs -or $pngs.Count -le 0) {
                        throw "FFmpeg produced no frames from AVIF input."
                    }
                    $frameCount = [int]$pngs.Count
                    & magick (Join-Path $tmp 'frame_*.png') -alpha on -append -define tga:compress-rle=true $OutputTga
                    $usedFallback = $true
                    Write-Host "Used FFmpeg fallback to decode AVIF -> PNG frames." -ForegroundColor Yellow
                }
                finally {
                    try { Remove-Item -Recurse -Force -LiteralPath $tmp | Out-Null } catch {}
                }
            } else {
                $msg = @()
                $msg += "Failed to read AVIF via ImageMagick and FFmpeg is not installed."
                $msg += "Install an ImageMagick build with HEIF/AVIF OR install FFmpeg for fallback."
                $msg += "To install ImageMagick (silent):"
                $msg += "  winget install --silent --accept-package-agreements --accept-source-agreements ImageMagick.ImageMagick"
                $msg += "To install FFmpeg:"
                $msg += "  winget install --silent --accept-package-agreements --accept-source-agreements Gyan.FFmpeg"
                throw ($msg -join [Environment]::NewLine)
            }
        } else {
            # For GIF or other inputs, allow build to proceed and compute frames from output later.
            $frameCount = $null
        }
    } else {
        $frameCount = [int]$frameCount
    }

    # Build spritesheet: coalesce frames, resize to requested size, pad to exact WxH, and append vertically
    # Notes:
    #  - '-resize WxH' keeps aspect ratio; combined with '-extent WxH' to letterbox with transparency as needed
    #  - '-append' stacks frames vertically
    #  - TGA with RLE compression keeps size smaller; alpha preserved by default
    if (-not $usedFallback) {
        & magick $InputPath -coalesce -alpha on -background none -gravity center -resize "${FrameWidth}x${FrameHeight}" -extent "${FrameWidth}x${FrameHeight}" -append -define tga:compress-rle=true $OutputTga
    }

    if (-not (Test-Path -LiteralPath $OutputTga)) {
        throw "Spritesheet generation failed: $OutputTga not created"
    }

    # If frameCount wasn't determined earlier, infer it from output image height
    if (-not $frameCount -or -not ($frameCount -as [int])) {
        $outH = & magick identify -format "%h" -- $OutputTga 2>$null
        if ($outH -and ($outH -as [int])) {
            $outH = [int]$outH
            if ($FrameHeight -gt 0) {
                $div = [math]::Floor($outH / $FrameHeight)
                if ($div -lt 1) { $div = 1 }
                $frameCount = [int]$div
            } else {
                $frameCount = 1
            }
        } else {
            $frameCount = 1
        }
    }

    # Compute image dimensions for metadata
    $imageWidth = $FrameWidth
    $imageHeight = $FrameHeight * $frameCount

    Write-Host "SUCCESS: Created spritesheet -> $OutputTga" -ForegroundColor Green
    Write-Host "Frames: $frameCount  |  Frame: ${FrameWidth}x${FrameHeight}  |  Image: ${imageWidth}x${imageHeight}  |  Framerate: $Framerate" -ForegroundColor Cyan

    # If installing into the addon folder, copy and build the Interface\\ path
    $interfacePath = $null
    if ($InstallDir) {
        if (-not (Test-Path -LiteralPath $InstallDir)) {
            throw "InstallDir not found: $InstallDir"
        }
        $dest = Join-Path $InstallDir (Split-Path -Leaf $OutputTga)
        Copy-Item -LiteralPath $OutputTga -Destination $dest -Force
        Write-Host "Copied to addon folder: $dest" -ForegroundColor Yellow

        # Derive Interface\\AddOns\\TwitchEmotes\\Emotes\\... path for Lua
        $normDest = ($dest -replace '/', '\\')
        $lower = $normDest.ToLower()
        $prefix = "\\interface\\addons\\twitchemotes\\emotes\\"
        $idx = $lower.IndexOf($prefix)
        if ($idx -ge 0) {
            $after = $normDest.Substring($idx + $prefix.Length)
            $interfacePath = "Interface\\AddOns\\TwitchEmotes\\Emotes\\" + $after
            $interfacePath = $interfacePath -replace '\\', '\\\\'
        }
    }

    if (-not $interfacePath) {
        # Fallback: suggest placing under Emotes\\Custom
        $fileName = Split-Path -Leaf $OutputTga
        $interfacePath = "Interface\\\\AddOns\\\\TwitchEmotes\\\\Emotes\\\\Custom\\\\$fileName"
    }

    # Print Lua snippets for easy copy/paste
    Write-Host "`nLua metadata (paste into Emotes.lua -> TwitchEmotes_animation_metadata):" -ForegroundColor White
    $meta = "[`"$interfacePath`"] = {['nFrames']=$frameCount, ['frameWidth']=$FrameWidth, ['frameHeight']=$FrameHeight, ['imageWidth']=$imageWidth, ['imageHeight']=$imageHeight, ['framerate']=$Framerate},"
    Write-Output $meta

    if ($EmoteKey) {
        Write-Host "`nOptional: defaultpack + trigger mapping (paste in Emotes.lua):" -ForegroundColor White
    $dp = "TwitchEmotes_defaultpack[`"$EmoteKey`"] = `"$interfacePath`""
    $map = "TwitchEmotes_emoticons[`"$EmoteKey`"] = `"$EmoteKey`""
        Write-Output $dp
        Write-Output $map
    }
    else {
        Write-Host "`nTip: call with -EmoteKey 'MyEmote' to also get defaultpack and emoticon mapping lines." -ForegroundColor DarkGray
    }

    Write-Host "`nDone." -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
