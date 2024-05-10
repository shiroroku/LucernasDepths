PUSH = require "libraries.push" -- Push handles viewport scaling
FLUX = require "libraries.flux" -- tweening

require "src.config.clientConfig"
require "src.config.serverConfig"
require "src.overlays.debugOverlay"
require "src.overlays.loadingOverlay"
require "src.overlays.consoleOverlay"
require "src.scenes.mainMenuScene"
require "src.scenes.serverScene"
require "src.errorScreen"
require "src.lang"
require "src.tileRegistry"
require "src.itemRegistry"

SHOW_CONSOLE = false

FontRegular = love.graphics.newFont("resources/fonts/ProggyTiny.ttf", 16)
FontRegular:setFilter("nearest", "nearest")
FontBig = love.graphics.newFont("resources/fonts/CozetteVector.ttf", 26)
FontBig:setFilter("nearest", "nearest")

---@type Scene
local current_scene = {}

---@return Scene
function GetScene() return current_scene end

---@param new_scene Scene
function SetScene(new_scene)
    ShowLoadingScreen()
    current_scene:quit()
    current_scene = new_scene
    HideLoadingScreen() -- before load so the scene can decide if the loading screen needs to be shown longer
    current_scene:load()
end

function love.load(args)
    love.graphics.setDefaultFilter("nearest", "nearest")
    PUSH:setupScreen(INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, {
        fullscreen = CLIENT_CONFIG.fullscreen,
        resizable = true,
        pixelperfect = CLIENT_CONFIG.pixel_perfect
    })
    love.graphics.setFont(FontRegular)
    love.mouse.setCursor(love.mouse.newCursor("resources/textures/ui/cursor.png", 0, 0))
    love.keyboard.setKeyRepeat(true)
    LoadTileRegistry()
    LoadItemRegistry()

    -- Arguments
    current_scene = MainMenuScene:new()
    if args[1] and args[1] == "--server" then current_scene = ServerScene:new() end
    if args[1] and args[1] == "-c" and args[2] then
        CLIENT_CONFIG_FILE = args[2]
        LoadClientConfig()
    end

    current_scene:load()
end

function love.draw()
    PUSH:start()
    current_scene:draw()
    DrawLoadingScreen()
    DrawConsoleOverlay()
    PUSH:finish()
end

function love.update(dt)
    FLUX.update(dt) -- our tweening library
    current_scene:update(dt)
    UpdateLoadingScreen(dt)
    UpdateConsoleOverlay(dt)
end

function love.keypressed(key, scancode, isrepeat)
    if KeyPressConsoleOverlay(key, scancode, isrepeat) then return end                                              -- console input
    for k, command in pairs(CLIENT_CONFIG.console_binds) do if k == key then ExecuteConsoleCommand(command) end end -- command keybinds
    if key == CLIENT_CONFIG.key_binds.toggle_debug then                                                             -- toggle debug overlay
        CLIENT_CONFIG.render_debug = not CLIENT_CONFIG.render_debug
        SaveClientConfig()
    end
    if key == CLIENT_CONFIG.key_binds.toggle_fullscreen then SetFullscreen(not CLIENT_CONFIG.fullscreen) end -- toggle fullscreen
    if current_scene:keyPress(key, scancode, isrepeat) then return end                                       -- scene
end

function love.mousepressed(x, y, button)
    x, y = GetMousePosition()                                 -- dont use loves mouse pos, we do our own scaling
    if MousePressConsoleOverlay(x, y, button) then return end -- console input (return stop players from clicking other objects when console is open)
    if current_scene:mousePress(x, y, button) then return end -- scene
end

function love.wheelmoved(x, y)
    if current_scene:mouseScroll(x, y) then return end
end

function love.textinput(text)
    if TextInputConsoleOverlay(text) then return end -- console text input
    if current_scene:textInput(text) then return end -- scene
end

function love.quit()
    SaveClientConfig()
    SaveServerConfig()
    current_scene:quit()
end

function love.resize(w, h) PUSH:resize(w, h) end

function love.errorhandler(msg) return ErrorScreen(msg) end
