require "src.components.ui.button"
require "src.components.ui.scrollbox"
require "src.config.clientConfig"
require "src.lang"
require "src.components.ui.tooltip"
require "src.components.scene"

OptionsMenuConstructor = Scene:extend {
    init = function(self, return_function)
        Scene.init(self, "Options Menu")
        self.return_function = return_function
        local padding_x, padding_y = 96, 16
        self.scrollbox = ScrollBox:new {
            x = padding_x,
            y = padding_y,
            w = INTERNAL_RES_WIDTH - padding_x * 2,
            h = INTERNAL_RES_HEIGHT - padding_y * 2 - 16,
            item_constructor = function()
                return {
                    {
                        name = GetTranslation("options.group.general"),
                        centered = true
                    },
                    {
                        name = GetTranslation("options.items.fullscreen"),
                        type = "boolean",
                        enabled = CLIENT_CONFIG.fullscreen,
                        onChange = function(_, item)
                            SetFullscreen(item.enabled)
                        end
                    },
                    {
                        name = GetTranslation("options.items.pixel_perfect"),
                        type = "boolean",
                        enabled = CLIENT_CONFIG.pixel_perfect,
                        onChange = function(_, item)
                            CLIENT_CONFIG.pixel_perfect = item.enabled
                            SaveClientConfig()
                        end,
                        tooltip = ToolTip:new {
                            text = GetTranslation("options.items.pixel_perfect.tooltip"),
                            x = 16,
                            y = 16,
                            w = INTERNAL_RES_WIDTH - 48, -- -16 for scrollbar
                            h = INTERNAL_RES_HEIGHT - 46
                        }
                    },
                    {
                        name = GetTranslation("options.group.controls"),
                        centered = true
                    },
                    {
                        name = GetTranslation("options.items.jump"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.jump,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.jump = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.up"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.up,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.up = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.down"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.down,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.down = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.left"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.left,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.left = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.right"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.right,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.right = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.inventory"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.inventory,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.inventory = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.back"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.back,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.back = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.pause"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.pause,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.pause = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.select"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.select,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.select = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.toggle_fullscreen"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.toggle_fullscreen,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.toggle_fullscreen = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.group.developer"),
                        centered = true
                    },
                    {
                        name = GetTranslation("options.items.show_debug"),
                        type = "boolean",
                        enabled = CLIENT_CONFIG.render_debug,
                        onChange = function(_, item)
                            CLIENT_CONFIG.render_debug = item.enabled
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.toggle_console"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.toggle_console,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.toggle_console = item.key
                            SaveClientConfig()
                        end
                    },
                    {
                        name = GetTranslation("options.items.toggle_debug"),
                        type = "key",
                        key = CLIENT_CONFIG.key_binds.toggle_debug,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds.toggle_debug = item.key
                            SaveClientConfig()
                        end
                    }
                }
            end
        }
        self.buttons = {
            Button:new {
                name = GetTranslation("options.back"),
                x = padding_x + 2,
                y = INTERNAL_RES_HEIGHT - 20,
                onClick = self.return_function
            },
            Button:new {
                name = GetTranslation("options.reset"),
                x = INTERNAL_RES_WIDTH - padding_x - GetTextWidth(GetTranslation("options.reset")) - 2,
                y = INTERNAL_RES_HEIGHT - 20,
                onClick = function()
                    CLIENT_CONFIG = DefaultClientConfig()
                    SetFullscreen(false)
                    SaveClientConfig()
                    self.scrollbox:refreshItems()
                end,
                color = { 1, 0.6, 0.6 }
            }
        }
    end,

    Draw = function(self)
        love.graphics.setColor({ 0, 0, 0, 0.2 })
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
        love.graphics.setColor(1, 1, 1, 1)
        for _, button in pairs(self.buttons) do button:draw() end
        self.scrollbox:draw()
    end,

    Update = function(self, dt)
        self.scrollbox:update(dt)
    end,

    KeyPress = function(self, key, scancode, isrepeat)
        if self.scrollbox:keyPress(key, scancode, isrepeat) then return true end
        if key == CLIENT_CONFIG.key_binds.back then
            self.return_function()
            return true
        end
        if key == CLIENT_CONFIG.key_binds.toggle_fullscreen or key == CLIENT_CONFIG.key_binds.toggle_debug then self.scrollbox:refreshItems() end -- refreshes items when toggle buttons are pressed
    end,

    MousePress = function(self, x, y, mouse_button)
        for _, button in pairs(self.buttons) do button:mousePress(x, y, mouse_button) end
        self.scrollbox:mousePress(x, y, mouse_button)
        return true
    end,

    MouseScroll = function(self, x, y)
        self.scrollbox:mouseWheelScroll(x, y)
        return true
    end
}
