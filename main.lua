---@type Position
local P = require("position")

local position = P.new(10, 20)
local position2 = position:set(20, 10)

print(position:toString())
print(position2:toString())
print(position:toString())
