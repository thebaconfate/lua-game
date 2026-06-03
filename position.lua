---@class Position
---@field private _x number
---@field private _y number
local Position = {}
Position.__index = Position

--- Position constructor
---@param x number The initial X coordinate
---@param y number The initial Y coordinate
---@return Position
function Position.new(x, y)
    local self = setmetatable({}, Position)
    --- @private
    self._x = x or 0
    --- @private
    self._y = y or 0
    return self
end

--- Gets the current X coordinate.
--- @return number
function Position:get_x()
    return self._x
end

--- Gets the current Y coordinate.
---@return number
function Position:get_y()
    return self._y
end

--- Creates a new Position instance with the updated X coordinate.
---@param new_x number A new X coordinate.
---@return Position
function Position:set_x(new_x)
    return Position.new(new_x, self._y)
end

---Creates a new Position instance with the updated Y coordinate.
---@param new_y number A new Y coordinate.
---@return Position
function Position:set_y(new_y)
    return Position.new(self._x, new_y)
end

---Gets the current X and Y coordinate.
---@return number
---@return number
function Position:get()
    return self._x, self._y
end

---Creates a new Position instance with the updated X and Y coordinates.
---@param new_x number A new X coordinate.
---@param new_y number A new Y coordinate.
---@return Position
function Position:set(new_x, new_y)
    return Position.new(new_x, new_y)
end

---Returns the string representation of the Position instance
---@return string
function Position:toString()
    return "x: " .. self._x .. ", y: " .. self._y
end

return Position
