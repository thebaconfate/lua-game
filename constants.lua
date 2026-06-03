-- constants.lua

---@class Constants
---@field WIDTH number
---@field HEIGHT number
---@field SCALE number
---@field VRAM_SIZE number
local M = {}
M.WIDTH = 320
M.HEIGHT = 240
M.SCALE = 4
M.VRAM_SIZE = M.WIDTH * M.HEIGHT * M.SCALE -- RGBA

local constants = {}
setmetatable(constants, {
    __index = M,
    __newindex = function(_, key, _)
        error("Attempt to modify read-only constant: " .. tostring(key), 2)
    end,
})

---@cast constants Constants
return constants
