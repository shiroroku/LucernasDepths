local json = require "libraries.json.json"

function HexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255
    return r, g, b
end

function HSLToRGB(h, s, l)
    if s <= 0 then return l, l, l, 1 end
    h, s, l = h * 6, s, l
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = (1 - math.abs(h % 2 - 1)) * c
    local m, r, g, b = (l - .5 * c), 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r + m, g + m, b + m, 1
end

function RGBToHSL(r, g, b)
    local M, m = math.max(r, g, b), math.min(r, g, b)
    local c, H = M - m, 0
    if M == r then
        H = (g - b) / c % 6
    elseif M == g then
        H = (b - r) / c + 2
    elseif M == b then
        H = (r - g) / c + 4
    end
    local L = 0.5 * M + 0.5 * m
    local S = c == 0 and 0 or c / (1 - math.abs(2 * L - 1))
    return ((1 / 6) * H), S, L
end

function ColorFormatting(text)
    text = text .. "<#"
    local color_table = {}
    for key, value in string.gmatch(text, "(%w%w%w%w%w%w)>(.-)<#") do
        table.insert(color_table, { key, value })
    end
    return color_table
end

function GetTextWidth(text, font)
    font = font or FontRegular
    return font:getWidth(text:gsub("<#%w%w%w%w%w%w>", ""))
end

function DrawText(text, x, y, color, bordercolor)
    local color_formatting = ColorFormatting(text)
    if next(color_formatting) ~= nil then
        love.graphics.setColor(color or { 1, 1, 1, 1 })
        local love_color_table = {}
        local love_color_table_border = {}
        for _, value in pairs(color_formatting) do
            local hex_color = value[1]
            local string = value[2]
            local r, g, b = HexToRGB(hex_color)
            local _, _, _, a = love.graphics.getColor()
            local rgb = {
                r,
                g,
                b,
                a
            }
            table.insert(love_color_table, rgb)
            table.insert(love_color_table, string)
            table.insert(love_color_table_border, bordercolor or { 0, 0, 0, math.max(0.5 - a, 0) })
            table.insert(love_color_table_border, string)
        end

        for i = -1, 1 do
            if i ~= 0 then
                love.graphics.print(love_color_table_border, x + i, y)
                love.graphics.print(love_color_table_border, x, y + i)
            end
        end

        love.graphics.print(love_color_table, x, y)
    else
        love.graphics.setColor(bordercolor or { 0, 0, 0, 0.5 })
        for i = -1, 1 do
            if i ~= 0 then
                love.graphics.print(text, x + i, y)
                love.graphics.print(text, x, y + i)
            end
        end
        love.graphics.setColor(color or { 1, 1, 1 })
        love.graphics.print(text, x, y)
    end
end

function Round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function Clamp(number, min, max)
    return math.min(max, math.max(min, number))
end

function IsMouseWithin(mousex, mousey, x, y, w, h)
    return mousex >= x and mousey >= y and mousex <= x + w and mousey <= y + h
end

function GetMousePositionWorld(camera)
    local x, y = PUSH:toGame(love.mouse.getPosition())
    return camera:toWorldCoords(x or 0, y or 0)
end

function GetMousePosition()
    local x, y = PUSH:toGame(love.mouse.getPosition())
    return x or 0, y or 0
end

function Lerp(a, b, x)
    return a * (1 - x) + b * x
end

function EncodeAndCompress(table)
    return love.data.compress("string", "zlib", json.encode(table), 9)
end

function DecompressAndDecode(data)
    return json.decode(love.data.decompress("string", "zlib", tostring(data)))
end

function SplitKey(key)
    local parsed_key = {}
    for str in string.gmatch(key, "([^:]+)") do table.insert(parsed_key, str) end
    return tonumber(parsed_key[1]), tonumber(parsed_key[2])
end

function RayCast(x1, y1, x2, y2, max_distance, hit_condition)
    local mag = math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2)
    local vec_nx, vec_ny = (x2 - x1) / mag, (y2 - y1) / mag
    local step_size_x, step_size_y = math.sqrt(1 + (vec_ny / vec_nx) ^ 2), math.sqrt(1 + (vec_nx / vec_ny) ^ 2)
    local ray_length_x = vec_nx < 0 and (x1 - x1) * step_size_x or ((x1 + 1) - x1) * step_size_x
    local ray_length_y = vec_ny < 0 and (y1 - y1) * step_size_y or ((y1 + 1) - y1) * step_size_y
    local distance = 0
    local step_x, step_y = vec_nx < 0 and -1 or 1, vec_ny < 0 and -1 or 1
    local x_check, y_check = x1, y1
    while distance < max_distance do
        if ray_length_x < ray_length_y then
            x_check = x_check + step_x
            distance = ray_length_x
            ray_length_x = ray_length_x + step_size_x
        else
            y_check = y_check + step_y
            distance = ray_length_y
            ray_length_y = ray_length_y + step_size_y
        end
        if hit_condition(x_check, y_check) then
            return true, x_check, y_check
        end
    end
    return false, x_check, y_check
end
