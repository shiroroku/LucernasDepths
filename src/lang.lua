local json = require "libraries.json.json"
require "libraries.json.json-beautify"

local cachedLang

-- loads default english lang, then merges specified lang into it
function LoadLang(file)
    -- load english first
    local lang_default
    local lang_file_english = love.filesystem.read("resources/lang/english.json")
    if lang_file_english then
        lang_default = json.decode(lang_file_english)
    else
        error("Failed to load lang file: \"english.json\"")
    end

    -- load specified lang
    local lang
    local lang_file = love.filesystem.read(string.format("resources/lang/%s", file))
    if lang_file then
        lang = json.decode(lang_file)
    else
        error(string.format("Failed to load lang file: \"%s\"", file))
    end

    -- merge langs
    for k, v in pairs(lang) do lang_default[k] = v end
    cachedLang = lang_default
end

-- attempts to get the translation from the provided key, if a translation doesnt exist, it returns english, or the key itself
function GetTranslation(key)
    for index, value in pairs(cachedLang) do if index == key then return value end end
    return key
end
