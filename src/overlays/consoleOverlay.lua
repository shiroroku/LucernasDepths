local enet = require "enet"
require "src.components.ui.textbox"

local log_length = 0
local consoleLog = {}

function ClearLog()
    consoleLog = {}
    log_length = 0
end

--- @enum
COLORS = {
    red = { 1, 0.6, 0.6 },
    green = { 0.6, 1, 0.6 },
    grey = { 0.5, 0.5, 0.5 },
    blue = { 0.6, 0.6, 1 }
}

local commands = {
    help = function(args)
        local help = {
            "[help]             - shows this",
            "[clear]            - clears the console",
            "[saveconfig]       - saves config file",
            "[loadconfig]       - reloads config file",
            "[lua] code         - runs lua code",
            "[info]             - shows system info",
            "[exit]             - exits game",
            "[bind] key command - binds a command to a key",
            "[clearbinds]       - removes all command keybinds"
        }

        for _, line in pairs(help) do
            Log(line, COLORS.grey)
        end
    end,

    clear = ClearLog,

    saveconfig = function(args)
        SaveClientConfig()
        Log("Config Saved!", COLORS.green)
    end,

    loadconfig = function(args)
        LoadClientConfig()
        Log("Config Loaded!", COLORS.green)
    end,

    lua = function(args)
        local code = ""
        for i, arg in pairs(args) do
            if i ~= 1 then
                code = code .. " " .. arg
            end
        end
        local out, err = load(code)
        if err then
            Log(err, COLORS.red)
        else
            ---@diagnostic disable-next-line: param-type-mismatch
            local ok, err2 = pcall(out)
            if not ok then
                Log(err2, COLORS.red)
            else
                Log(tostring(ok), COLORS.green)
            end
        end
    end,

    info = function(args)
        Log(love.system.getOS() .. ", " .. love.system.getProcessorCount() .. " Cores", COLORS.grey)
        local renderer, driver, _, device = love.graphics.getRendererInfo()
        Log(renderer .. " " .. driver, COLORS.grey)
        Log(device, COLORS.grey)
        Log("Love " .. string.format("%d.%d.%d - %s", love.getVersion()), COLORS.grey)
        Log("Enet " .. tostring(enet.linked_version()), COLORS.grey)
        Log(_VERSION, COLORS.grey)
    end,

    exit = function(args)
        love.event.quit()
    end,

    bind = function(args)
        local key = ""
        local command = ""
        for i, arg in pairs(args) do
            if i ~= 1 then
                if i == 2 then
                    key = arg
                else
                    if command == "" then
                        command = arg
                    else
                        command = command .. " " .. arg
                    end
                end
            end
        end
        CLIENT_CONFIG.console_binds[key] = command
        Log("Set key \"" .. key .. "\" to \"" .. command .. "\"", COLORS.green)
        SaveClientConfig()
    end,

    clearbinds = function(args)
        CLIENT_CONFIG.console_binds = {}
        SaveClientConfig()
        Log("Cleared command keybinds", COLORS.green)
    end
}


function ExecuteConsoleCommand(text)
    Log("> " .. text)
    local command = {}
    for word in text:gmatch("%S+") do
        table.insert(command, word)
    end

    if command == nil or command[1] == nil or commands[command[1]] == nil then
        Log("Unknown command: " .. text, COLORS.red)
        return
    end
    commands[command[1]](command)
end

local consoleInput = TextBox:new {
    x = 0,
    y = INTERNAL_RES_HEIGHT - 16,
    w = INTERNAL_RES_WIDTH,
    h = 16,
    onSubmit = function(textbox)
        ExecuteConsoleCommand(textbox.text)
        textbox.text = ""
    end
}


local textScrollDuration = 200
local textScroll = 0
local paused = true
local textScrollPauseDuration = 200
local textScrollPause = 0

local function resetScrolls()
    textScrollPause = 0
    textScroll = 0
    paused = true
end

function Log(text, color)
    log_length = log_length + 1
    if log_length > 5000 then
        ClearLog()
    end
    print(text)
    resetScrolls()
    table.insert(consoleLog, {
        text = text,
        color = color or { 1, 1, 1, 1 }
    })
end

function DrawConsoleOverlay()
    if SHOW_CONSOLE then
        love.graphics.setColor({ 0, 0, 0, 0.75 })
        love.graphics.rectangle("fill", 0, 0, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
        love.graphics.setColor({ 1, 1, 1, 1 })
        consoleInput:draw()

        local y_offset = INTERNAL_RES_HEIGHT - 26
        local x_offset = 3
        local text_padding = 1
        for _, line in pairs(consoleLog) do
            y_offset = y_offset - FontRegular:getHeight() - text_padding
        end
        for k, line in pairs(consoleLog) do
            local text = tostring(line.text) or "nil"
            local font_height = FontRegular:getHeight() + text_padding
            local font_width = FontRegular:getWidth(text)
            local x_scroll = 0
            if font_width > INTERNAL_RES_WIDTH then
                local overflow = font_width - INTERNAL_RES_WIDTH + 8
                x_scroll = overflow * (textScroll / textScrollDuration)
            end
            DrawText(text, x_offset - x_scroll, y_offset + (k * font_height), line.color)
        end
    end
end

function UpdateConsoleOverlay(dt)
    if SHOW_CONSOLE then
        consoleInput:update(dt)

        if paused then
            if textScrollPause >= textScrollPauseDuration then
                paused = false
                textScrollPause = 0
                if textScroll == 0 then
                    textScroll = textScroll + 1
                end
                if textScroll >= textScrollDuration then
                    textScroll = 0
                end
            else
                textScrollPause = textScrollPause + 1
            end
        else
            if textScroll >= textScrollDuration then
                textScroll = 0
            else
                textScroll = textScroll + 1
            end
        end

        if textScroll == 0 or textScroll >= textScrollDuration then
            paused = true
        end

        return true
    end
end

function KeyPressConsoleOverlay(key, scancode, isrepeat)
    if SHOW_CONSOLE then
        consoleInput:keyPress(key, scancode, isrepeat)
        if key == CLIENT_CONFIG.key_binds.back then
            SHOW_CONSOLE = false
        end
    end
    if key == CLIENT_CONFIG.key_binds.toggle_console then
        SHOW_CONSOLE = not SHOW_CONSOLE
        if SHOW_CONSOLE then
            consoleInput.focused = true
        else
            consoleInput.focused = false
        end
    end
    if SHOW_CONSOLE then
        -- this needs to be after
        return true
    end
end

function TextInputConsoleOverlay(text)
    if SHOW_CONSOLE then
        consoleInput:textInput(text)
        return true
    end
end

function MousePressConsoleOverlay(x, y, mouse_button)
    if SHOW_CONSOLE then
        consoleInput:mousePress(x, y, mouse_button)
        return true
    end
end
