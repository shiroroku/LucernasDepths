local function buildPanel(texture)
    local d = love.image.newImageData(texture)
    return {
        data = d,
        atlas = love.graphics.newSpriteBatch(love.graphics.newImage(d)),
        TL = love.graphics.newQuad(0, 0, 3, 3, 7, 7),
        TC = love.graphics.newQuad(3, 0, 1, 3, 7, 7),
        TR = love.graphics.newQuad(4, 0, 3, 3, 7, 7),
        BL = love.graphics.newQuad(0, 4, 3, 3, 7, 7),
        BC = love.graphics.newQuad(3, 4, 1, 3, 7, 7),
        BR = love.graphics.newQuad(4, 4, 3, 3, 7, 7),
        LC = love.graphics.newQuad(0, 3, 3, 1, 7, 7),
        RC = love.graphics.newQuad(4, 3, 3, 1, 7, 7),
    }
end


-- All panel textures must be 7x7
PanelBasic = buildPanel("resources/textures/ui/panel.png")
PanelIn = buildPanel("resources/textures/ui/panel_in.png")


function DrawPanel(x, y, w, h, panelTable)
    panelTable = panelTable or PanelBasic
    panelTable.atlas:clear()
    w = math.max(7, w)
    h = math.max(7, h)

    -- Corners
    panelTable.atlas:add(panelTable.TL, x, y)
    panelTable.atlas:add(panelTable.TR, x + w - 3, y)
    panelTable.atlas:add(panelTable.BL, x, y + h - 3)
    panelTable.atlas:add(panelTable.BR, x + w - 3, y + h - 3)

    -- Top/Bottom
    for i = 3, w - 4 do
        panelTable.atlas:add(panelTable.TC, x + i, y)
        panelTable.atlas:add(panelTable.BC, x + i, y + h - 3)
    end

    -- Left/Right
    for i = 3, h - 4 do
        panelTable.atlas:add(panelTable.LC, x, y + i)
        panelTable.atlas:add(panelTable.RC, x + w - 3, y + i)
    end

    -- Center: instead of using the texture itself, we are just getting the color and drawing a rectangle
    -- Because our center sprite is 1x1, meaning we would be doing w*h number of draws >.>
    local r, g, b, a = panelTable.data:getPixel(4, 4)
    local r2, g2, b2, a2 = love.graphics.getColor()
    love.graphics.setColor(r * r2, g * g2, b * b2, a * a2) -- Multiply current color to center color
    love.graphics.rectangle("fill", x + 3, y + 3, w - 6, h - 6)
    love.graphics.setColor(r2, g2, b2, a2)                 -- Restore previous color

    love.graphics.draw(panelTable.atlas)
    love.graphics.setColor(1, 1, 1, 1)
end
