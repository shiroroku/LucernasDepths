---@diagnostic disable: param-type-mismatch
require "src.config.clientConfig"
require "src.helperFunctions"
require "src.components.ui.panel"

local gridTexture = love.graphics.newImage("resources/textures/ui/grid.png")
gridTexture:setWrap("repeat")

local function writeLineRight(text, line_number, color)
    DrawText(text, INTERNAL_RES_WIDTH - FontRegular:getWidth(text) - 2, 2 + line_number * 11, color or { 1, 1, 1 })
end

local function writeLineLeft(text, line_number, color)
    DrawText(text, 2, 2 + line_number * 11, color or { 1, 1, 1 })
end

function DrawDebugRenderer(drawn_tiles, udp_client)
    if CLIENT_CONFIG.render_debug then
        love.graphics.push()
        love.graphics.setColor(1, 1, 1, 0.05)
        love.graphics.draw(gridTexture, love.graphics.newQuad(ClientCamera.x + 1, ClientCamera.y + 9, INTERNAL_RES_WIDTH, INTERNAL_RES_HEIGHT, 16, 16))
        love.graphics.setColor(1, 1, 1, 0.2)
        local stats = love.graphics.getStats()

        writeLineLeft(string.format("Chunk: [%d, %d]", PointToChunkPos(ClientCamera.x, ClientCamera.y)), 0)
        writeLineLeft(string.format("Mouse: [%d, %d]", GetMousePositionWorld(ClientCamera)), 1)
        writeLineLeft(string.format("Drawn Tiles: %d", drawn_tiles), 2)

        writeLineRight(string.format("FPS: %d", love.timer.getFPS()), 0, { 0, 1, 0 })
        writeLineRight(string.format("Draw Calls: %d", stats.drawcalls), 1)
        writeLineRight(string.format("Textures: %d", stats.images), 2)
        writeLineRight(string.format("Tex memory: %.2f MB", stats.texturememory / 1024 / 1024), 3)


        if udp_client then
            writeLineRight(string.format("Ping: %s", tostring(udp_client:getPing()) .. "ms"), 4)
        else
            writeLineRight("Ping: n/a", 4)
        end
        love.graphics.pop()
    end
end
