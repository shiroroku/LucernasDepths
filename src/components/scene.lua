---Changes the state of the game, can have scenes within itself for submenus
---@class Scene
---@field sub_scene Scene?
Scene = {}

---@return Scene
function Scene:new()
    local o = {}
    setmetatable(o, { __index = self })
    o.sub_scene = nil
    return o
end

function Scene:load() end

---@param dt number
---@return boolean? cancel
function Scene:update(dt)
    if self.sub_scene == nil then return false end
    if self.sub_scene:update(dt) then return true end
end

function Scene:draw()
    if self.sub_scene == nil then return end
    self.sub_scene:draw()
end

function Scene:quit()
    if self.sub_scene == nil then return end
    self.sub_scene:quit()
end

---@param key love.KeyConstant
---@param scancode love.Scancode
---@param isrepeat boolean
---@return boolean? cancel
function Scene:keyPress(key, scancode, isrepeat)
    if self.sub_scene == nil then return false end
    if self.sub_scene:keyPress(key, scancode, isrepeat) then return true end
end

---@param x number
---@param y number
---@param mouse_button number
---@return boolean? cancel
function Scene:mousePress(x, y, mouse_button)
    if self.sub_scene == nil then return false end
    if self.sub_scene:mousePress(x, y, mouse_button) then return true end
end

---@param x number
---@param y number
---@return boolean? cancel
function Scene:mouseScroll(x, y)
    if self.sub_scene == nil then return false end
    if self.sub_scene:mouseScroll(x, y) then return true end
end

---@param text string
---@return boolean? cancel
function Scene:textInput(text)
    if self.sub_scene == nil then return false end
    if self.sub_scene:textInput(text) then return true end
end

---@return boolean
function Scene:isSubSceneOpen()
    return self.sub_scene ~= nil
end

---@param new_scene Scene?
function Scene:changeSubScene(new_scene)
    if self.sub_scene ~= nil then self.sub_scene:quit() end
    self.sub_scene = new_scene
    if self.sub_scene ~= nil then self.sub_scene:load() end
end
