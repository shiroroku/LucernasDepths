local json = require "libraries.json.json"
require "libraries.json.json-beautify"
require "src.lang"

INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT = 480, 270
SHOW_CONSOLE = false

CLIENT_CONFIG_FILE = "client_config.json"

math.randomseed(os.time())
function DefaultClientConfig()
    return {
        language = "english.json",
        fullscreen = false,
        render_debug = false,
        pixel_perfect = false,
        key_binds = {
            jump = "space",
            up = "w",
            down = "s",
            left = "a",
            right = "d",
            back = "escape",
            pause = "escape",
            toggle_debug = "f2",
            toggle_fullscreen = "f11",
            select = "return",
            toggle_console = "f1",
            inventory = "tab"
        },
        console_binds = {},
        player_skin = "chroma",
        player_skin_colors = {
            skin = {
                h = 0,
                s = 0,
                l = 0
            },
            clothes = {
                h = 0,
                s = 0,
                l = 0
            },
            primary = {
                h = 0,
                s = 0,
                l = 0
            },
            secondary = {
                h = 0,
                s = 0,
                l = 0
            }
        },
        multiplayer_token = string.format("%d-%d-%d", math.random(99999), math.random(99999), math.random(99999)), -- unique token, for logging back into your player
        multiplayer_name = "Meower",
        server_timeout = 5,
        server_ip = "127.0.0.1",
        server_port = 12345
    }
end

CLIENT_CONFIG = DefaultClientConfig()

function SaveClientConfig()
    local success, error = love.filesystem.write(CLIENT_CONFIG_FILE, json.beautify(CLIENT_CONFIG))
    if not success then
        error(string.format("Failed to save client config json: \"%s\"", error))
    end
end

function LoadClientConfig()
    local config_file = love.filesystem.read(CLIENT_CONFIG_FILE)
    if config_file then
        local loaded = json.decode(config_file)
        for key, value in pairs(loaded) do CLIENT_CONFIG[key] = value end
    end
    SaveClientConfig()
    LoadLang(CLIENT_CONFIG.language)
end

LoadClientConfig()

function SetFullscreen(value)
    Log(string.format("Setting fullscreen to %s", value), COLORS.grey)
    local _, _, flags = love.window.getMode()
    if value == false and flags.fullscreen == false then
        return
    end
    if value == true and flags.fullscreen == true then
        return
    end
    PUSH:switchFullscreen(INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT)
    CLIENT_CONFIG.fullscreen = value
    SaveClientConfig()
end
