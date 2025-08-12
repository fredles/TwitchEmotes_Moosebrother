# GIF -> TGA spritesheet tool

This PowerShell script converts an animated GIF or AVIF (animated or static) into a vertical TGA spritesheet for WoW texture tags and prints Lua snippets for TwitchEmotes.

## Prereqs
- Windows PowerShell
- ImageMagick installed (magick.exe in PATH): https://imagemagick.org/script/download.php#windows
  - AVIF requires an ImageMagick build with libheif (HEIF/AVIF) support. If identify fails on .avif, install a recent ImageMagick or enable HEIF.

### Installing ImageMagick on Windows
Pick one:
- winget
  - winget install ImageMagick.ImageMagick
- Chocolatey
  - choco install imagemagick
- Manual
  - Download the latest ImageMagick 7 installer for Windows.
  - During setup, check “Add application directory to your system path”.

Verify installation:
```
magick -version
magick identify -list format | Select-String -Pattern "HEIF|AVIF"
```
If the second command shows HEIF/AVIF, AVIF decoding is enabled.

## Usage
```
# Basic (GIF): write to a temp path
pwsh -File tools/gif-to-tga-spritesheet.ps1 -InputGif C:\path\in.gif -OutputTga C:\path\out.tga -FrameWidth 32 -FrameHeight 32 -Framerate 15 -EmoteKey myEmote

# Install directly into your addon Emotes/Custom folder
pwsh -File tools/gif-to-tga-spritesheet.ps1 `
  -InputGif C:\path\in.gif `
  -OutputTga C:\temp\myEmote.tga `
  -FrameWidth 32 -FrameHeight 32 -Framerate 15 -EmoteKey myEmote `
  -InstallDir "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\TwitchEmotes\Emotes\Custom"

# AVIF example (animated or static)
pwsh -File tools/gif-to-tga-spritesheet.ps1 -InputGif C:\path\in.avif -OutputTga C:\path\out.tga -FrameWidth 32 -FrameHeight 32 -Framerate 15 -EmoteKey myAvifEmote
```

The script prints:
- A TwitchEmotes_animation_metadata entry with correct nFrames, frame/image sizes, and framerate
- Optional TwitchEmotes_defaultpack + TwitchEmotes_emoticons lines when you pass -EmoteKey

Paste those into `Emotes.lua`.

Notes:
- Script coalesces GIF frames, scales to the requested size, letterboxes to exact WxH, and stacks frames vertically.
- Use -FrameWidth/-FrameHeight to match the emote’s intended display size (commonly 32x32 in your metadata).
