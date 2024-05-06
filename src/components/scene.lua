local class = require "libraries.clasp"

-- Changes the state of the game, can have scenes within itself for submenus
--- @class Scene
--- @field init function
--- @field IsSubSceneOpen function
--- @field ChangeSubScene function
--- @field Load function
--- @field Update function
--- @field Draw function
--- @field Quit function
--- @field KeyPress function
--- @field MousePress function
--- @field MouseScroll function
--- @field TextInput function
--- @field extend function
Scene = class {

    init = function(self, name)
        self.name = name
        self.sub_scene = nil
    end,

    IsSubSceneOpen = function(self)
        return self.sub_scene and next(self.sub_scene)
    end,

    ---@param new_sub_scene Scene
    ChangeSubScene = function(self, new_sub_scene)
        if self.sub_scene ~= nil and self.sub_scene.Quit ~= nil then self.sub_scene:Quit() end
        self.sub_scene = new_sub_scene
        if self.sub_scene ~= nil and self.sub_scene.Load ~= nil then self.sub_scene:Load() end
    end,

    Load = function(self)
        -- empty because changesubscene handles loading and quitting
    end,

    ---@param dt number
    Update = function(self, dt)
        if self.sub_scene == nil or self.sub_scene.Update == nil then return false end
        if self.sub_scene:Update(dt) then return true end
    end,

    Draw = function(self)
        if self.sub_scene == nil or self.sub_scene.Draw == nil then return false end
        self.sub_scene:Draw()
    end,

    Quit = function(self)
        if self.sub_scene == nil or self.sub_scene.Quit == nil then return false end
        self.sub_scene:Quit()
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if self.sub_scene == nil or self.sub_scene.KeyPress == nil then return false end
        if self.sub_scene:KeyPress(key, scancode, isrepeat) then return true end
    end,

    MousePress = function(self, x, y, mouse_button)
        if self.sub_scene == nil or self.sub_scene.MousePress == nil then return false end
        if self.sub_scene:MousePress(x, y, mouse_button) then return true end
    end,

    MouseScroll = function(self, x, y)
        if self.sub_scene == nil or self.sub_scene.MouseScroll == nil then return false end
        if self.sub_scene:MouseScroll(x, y) then return true end
    end,

    TextInput = function(self, text)
        if self.sub_scene == nil or self.sub_scene.TextInput == nil then return false end
        if self.sub_scene:TextInput(text) then return true end
    end,

    __ = {
        tostring = function(self)
            return "Scene(" .. tostring(self.name) .. ")"
        end
    }
}
