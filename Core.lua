--Credit: https://github.com/Pewtro/TwitchEmotes_Solaris

---@diagnostic disable: deprecated
TwitchEmotes_Moosebrother = LibStub("AceAddon-3.0"):NewAddon("TwitchEmotes_Moosebrother", "AceConsole-3.0", "AceEvent-3.0")

--Init
function TwitchEmotes_Moosebrother:OnInitialize()

    TwitchEmotes_Moosebrother:SetAutoComplete(true)

end

-- Helper to register animation metadata for spritesheets
-- path: full texture path (Interface\\AddOns\\TwitchEmotes_Moosebrother\\emotes\\name.tga)
-- nFrames: total number of frames in the spritesheet
-- frameWidth/frameHeight: single frame dimensions
-- imageWidth/imageHeight: full image dimensions
-- framerate: frames per second
-- pingpong: optional boolean to play forward then backward
function TwitchEmotesMoosebrother_AddAnimation(path, nFrames, frameWidth, frameHeight, imageWidth, imageHeight, framerate, pingpong)
    TwitchEmotes_animation_metadata = TwitchEmotes_animation_metadata or {}
    TwitchEmotes_animation_metadata[path] = {
        ["nFrames"] = nFrames,
        ["frameWidth"] = frameWidth,
        ["frameHeight"] = frameHeight,
        ["imageWidth"] = imageWidth,
        ["imageHeight"] = imageHeight,
        ["framerate"] = framerate,
        ["pingpong"] = pingpong and true or nil,
    }
end