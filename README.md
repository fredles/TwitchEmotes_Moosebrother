# Moosebrother Twitch Emotes

## Submission Guide

### Static Emotes

1. Clone the repository locally and create a branch
2. Save your emote as a `.tga` file in the `/emotes` directory
   - Image must be 128x128 pixels
3. Edit `Emotes.lua` to register the emote:
   - Add to `TwitchEmotes_Moosebrother_Emoticons`: maps emote name to itself
   - Add to `TwitchEmotes_Moosebrother_Emoticons_Pack`: maps emote name to file path with `:28:28` suffix
4. Commit your changes and submit a Pull Request

**Example registration for static emote:**
```lua
-- In TwitchEmotes_Moosebrother_Emoticons:
["myEmote"] = "myEmote",

-- In TwitchEmotes_Moosebrother_Emoticons_Pack:
["myEmote"] = "Interface\\AddOns\\TwitchEmotes_Moosebrother\\emotes\\myEmote.tga:28:28",
```

### Animated Emotes

Animated emotes require a TGA sprite sheet and animation metadata. Do NOT include the `:28:28` suffix for animated emotes.

1. Convert your GIF/WebP to a TGA sprite sheet (see conversion instructions below)
2. Place the `.tga` file in `/emotes`
3. Edit `Emotes.lua`:
   - Add to `TwitchEmotes_Moosebrother_Emoticons`
   - Add to `TwitchEmotes_Moosebrother_Emoticons_Pack` (no `:28:28` suffix)
   - Add to `TwitchEmotes_Moosebrother_Animation_Metadata`

**Example registration for animated emote:**
```lua
-- In TwitchEmotes_Moosebrother_Emoticons:
["myAnimatedEmote"] = "myAnimatedEmote",

-- In TwitchEmotes_Moosebrother_Emoticons_Pack (NO :28:28 suffix):
["myAnimatedEmote"] = "Interface\\AddOns\\TwitchEmotes_Moosebrother\\emotes\\myAnimatedEmote.tga",

-- In TwitchEmotes_Moosebrother_Animation_Metadata:
["Interface\\AddOns\\TwitchEmotes_Moosebrother\\emotes\\myAnimatedEmote.tga"] = {
    nFrames = 24,       -- number of frames
    frameWidth = 32,    -- width of each frame
    frameHeight = 32,   -- height of each frame
    imageWidth = 32,    -- total image width (power of 2)
    imageHeight = 1024, -- total image height (power of 2)
    framerate = 15      -- playback speed (fps)
},
```

## Converting Animated Emotes

### Prerequisites

- [ImageMagick](https://imagemagick.org/script/download.php) - for image manipulation
- [FFmpeg](https://ffmpeg.org/download.html) - for TGA encoding

### Square Emotes (1:1 aspect ratio)

For standard square emotes (e.g., 112x112, 128x128):

```bash
# 1. Check frame count
magick identify "input.gif"

# 2. Convert to sprite sheet
magick "input.gif" -coalesce -resize 32x32 -append -background none -gravity North -extent 32x<HEIGHT> temp.png
ffmpeg -i temp.png -pix_fmt bgra "emotes/output.tga" -y
rm temp.png
```

**Height values by frame count:**
| Frames | Height |
|--------|--------|
| 2      | 64     |
| 3-4    | 128    |
| 5-8    | 256    |
| 9-16   | 512    |
| 17-32  | 1024   |
| 33-64  | 2048   |

### Non-Square Emotes (wide/tall aspect ratios)

For emotes with non-1:1 aspect ratios:

**Step 1: Get source dimensions and frame count**
```bash
magick identify "input.gif"
# Note the WxH dimensions (e.g., 384x128) and count the frames
```

**Step 2: Calculate target dimensions**
- Frame height: 32px (standard)
- Frame width: `32 * (sourceWidth / sourceHeight)`, rounded to integer
- Image width: Next power of 2 >= frame width (32, 64, 128, 256...)
- Image height: Next power of 2 >= (frameCount * 32)

**Step 3: Convert**
```bash
magick "input.gif" -coalesce -resize <FRAME_W>x32 -append -background none -gravity NorthWest -extent <IMG_W>x<IMG_H> temp.png
ffmpeg -i temp.png -pix_fmt bgra "emotes/output.tga" -y
rm temp.png
```

**Example: 384x128 GIF with 36 frames (3:1 aspect ratio)**
- Frame: 96x32 (32 * 384/128 = 96)
- Image: 128x2048 (next power of 2 for 96 is 128, for 36*32=1152 is 2048)

```bash
magick "input.gif" -coalesce -resize 96x32 -append -background none -gravity NorthWest -extent 128x2048 temp.png
ffmpeg -i temp.png -pix_fmt bgra "emotes/output.tga" -y
rm temp.png
```

**Metadata for this example:**
```lua
["Interface\\AddOns\\TwitchEmotes_Moosebrother\\emotes\\output.tga"] = {
    nFrames = 36,
    frameWidth = 96,
    frameHeight = 32,
    imageWidth = 128,
    imageHeight = 2048,
    framerate = 15
},
```

## Key Files

- `Emotes.lua` - Emote definitions and animation metadata
- `Animator.lua` - Animation system implementation
- `TwitchEmotes_Moosebrother.toc` - Addon manifest

## Pull Request Process

1. Fork/clone the repository
2. Create a feature branch
3. Add your emote files and update `Emotes.lua`
4. Test in-game if possible
5. Submit a Pull Request with a description of the emote(s) added
