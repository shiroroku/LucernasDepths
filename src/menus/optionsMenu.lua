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
        local scrollbox_w = INTERNAL_RES_WIDTH - padding_x * 2
        self.scrollbox = ScrollBox:new {
            x = padding_x,
            y = padding_y,
            w = scrollbox_w,
            h = INTERNAL_RES_HEIGHT - padding_y * 2 - 16,
            item_constructor = function()
                local item_table = {
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
                    }
                }

                local sorted = {}
                for key_name, key_bind in pairs(CLIENT_CONFIG.key_binds) do
                    table.insert(sorted, {
                        name = GetTranslation("options.items." .. key_name),
                        type = "key",
                        key = key_bind,
                        onChange = function(_, item)
                            CLIENT_CONFIG.key_binds[key_name] = item.key
                            SaveClientConfig()
                        end
                    })
                end
                table.sort(sorted, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
                for _, value in pairs(sorted) do table.insert(item_table, value) end

                table.insert(item_table, {
                    name = GetTranslation("options.group.developer"),
                    centered = true
                })
                table.insert(item_table, {
                    name = GetTranslation("options.items.show_debug"),
                    type = "boolean",
                    enabled = CLIENT_CONFIG.render_debug,
                    onChange = function(_, item)
                        CLIENT_CONFIG.render_debug = item.enabled
                        SaveClientConfig()
                    end
                })
                return item_table
            end
        }
        self.buttons = {
            Button:new {
                name = GetTranslation("options.back"),
                x = padding_x + 1,
                y = INTERNAL_RES_HEIGHT - 24,
                w = scrollbox_w / 2 - 10,
                onClick = self.return_function
            },
            Button:new {
                name = GetTranslation("options.reset"),
                x = INTERNAL_RES_WIDTH - padding_x - 1 - scrollbox_w / 2 + 5,
                y = INTERNAL_RES_HEIGHT - 24,
                w = scrollbox_w / 2 - 5,
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
