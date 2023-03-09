-- License CC0

local imageToPolygon = require("lib.imagetopoly")
local simplify = require("lib.simplify")
local nativefs = require("lib.nativefs")
local suit = require("lib.suit.init")

-- UTILS FUNCS --

--local function getDirectory(p)
--    return p:match("(.-)[\\/][^\\/]*%.[^%.\\/]*$")  -- returns the only dir only if there is a file extension
--end

--local function getFilename(p)
--    return p:match("[^\\%/]*$")
--end

local function getExtension(p)
    return p:match("%.([^.]+)$")
end

local function getDocumentsDir()
    if package.config:sub(1,1) == "\\" then                 -- Windows
        return os.getenv("USERPROFILE").."\\Documents"
    else                                                    -- Unix (MacOS and Linux)
        return os.getenv("HOME").."/Documents"
    end
end

local function tableToString(t)
    local result = "{"
    local has_numeric_index = false
    for k, v in pairs(t) do
        if type(k) == "number" then
            if k > #t or math.floor(k) ~= k or k <= 0 then -- ignore if key is not a positive integer within the range of the table
                has_numeric_index = true
            else
                if has_numeric_index then
                    result = result..", "
                end
                result = (type(v) == "table")
                    and result..tableToString(v)
                    or result..v
                if next(t, k) ~= nil then
                    result = result..", "
                end
            end
        else
            if has_numeric_index then
                result = result..", "
            end
            result = result..k.." = "
            if type(v) == "table" then
                result = result..tableToString(v)
            elseif type(v) == "string" then
                result = result..'"'..v..'"'
            else
                result = result..tostring(v)
            end
            if next(t, k) ~= nil then
                result = result..", "
            end
        end
    end
    result = result.."}"
    return result
end

local function formatTableString(str)
    if str == "" then return "" end

    -- Remove opening and closing braces
    str = string.sub(str, 2, -2)

    -- Splits the string into table elements
    local elements = {}
    for element in string.gmatch(str, "[^,]+") do
        if string.sub(element, 1, 1) == " " then
            element = string.sub(element, 2)
        end
        table.insert(elements, element)
    end

    -- Formatting inline elements
    local formatted_elements = {}
    local line = "  "
    for i, element in ipairs(elements) do
        line = line..element..","..(i%2~=0 and " " or "")
        if i % 2 == 0 then
            table.insert(formatted_elements, line)
            line = "  "
        end
    end

    -- Add the last two elements if there are any
    if #elements % 2 ~= 0 then
        table.insert(formatted_elements, "  "..elements[#elements-1]..", "..elements[#elements])
    end

    -- Concatenate formatted lines
    local formatted_str = "{\n"..table.concat(formatted_elements, "\n").."\n}"

    if string.find(str, "=") then
      formatted_str = string.gsub(formatted_str, ",\n", ";\n")      -- Replace commas at the end of lines with semicolons
      formatted_str = string.gsub(formatted_str, "%s*=%s*", " = ")  -- Remove spaces around equal signs
    end

    return formatted_str
end




local function getStringVerts(verts, formated, tbl_of_tbl)

    local result;

    if tbl_of_tbl then
        result = {}
        for i = 1, #verts-1, 2 do
            result[#result+1] = {x=verts[i],y=verts[i+1]}
        end; result = tableToString(result)
    else
        result = tableToString(verts)
    end

    if formated then
        result = formatTableString(result)
    end

    return result

end

local function exportVerts(path,string)

    local file = nativefs.newFile(path)

    file:open("a")

    if not file then
        file:open("w")
    end

    local fileIndex = 0
    for line in io.lines(path) do
        if line:sub(1,1) == "v" then
            fileIndex = fileIndex + 1
        end
    end

    file:write("verts_"..(fileIndex+1).." = "..string.."\n\n")
    file:close()

end


-- VARIABLES --

local valid_formats = {
    jpg = true,
    jpeg = true,
    png = true,
    bmp = true,
    tga = true,
    hdr = true,
    pic = true,
    exr = true
}

local result; -- Contain result verts of imageToPolygon
local time;     -- Polygon generation time

local image;
local data;
local path;

local path_input = {text = ""}
local nverts_input = {text = ""}
local slider_simplify= {value = 0.1, min = 0.1, max = 10}

local on_export = false
local export_path_input = {text=getDocumentsDir().."/verts.lua"}

local check_formated = {checked=false,text="Get foramted table string"}
local check_tbl_of_tbl = {checked=false,text="Get table of table {x = x, y = y}"}


-- PROGRAM --

local function checkFile(p)
    if nativefs.getInfo(p) then
        return valid_formats[getExtension(p)]
    end
end

function love.load()
    love.graphics.setBackgroundColor(.2,.2,.2)
    love.graphics.setPointSize(2)
end

function love.update(dt)

    if not on_export then

        suit.layout:reset(50,30)

        suit.Label("Type the path or drag and drop the image.", {align = "left"}, suit.layout:row(300,25))
        suit.Input(path_input, suit.layout:row())

        if path_input.text ~= "" and checkFile(path_input.text) then

            suit.layout:row(0,4)

            if path_input.text ~= path then

                if image then
                    data:release()
                    image:release()
                end

                path = path_input.text
                data = love.image.newImageData(nativefs.newFileData(path))
                image = love.graphics.newImage(data)

            end

            suit.Label("Max vertices:", {align = "left"}, suit.layout:row(90,25))

            suit.layout:col(0,0)
            suit.Input(nverts_input, suit.layout:col(38,25))
            nverts_input.text = nverts_input.text:gsub("%D", "")

            suit.layout:col(0,0)
            if suit.Button("Generate polygon", suit.layout:row(172,25)).hit then
                time = os.clock()
                result = imageToPolygon(data, .5, tonumber(nverts_input.text))
                time = os.clock()-time
            end

            suit.layout:reset(50,suit.layout._y+29)

        end

    end

    if on_export then

        suit.layout:reset(50,5)

        suit.Label("Export path:", {align = "left"}, suit.layout:row(300,25))
        suit.Input(export_path_input, suit.layout:row())

        suit.Checkbox(check_formated, suit.layout:row(300,25))
        suit.Checkbox(check_tbl_of_tbl, suit.layout:row(300,25))

        suit.layout:row(0,4)
        if suit.Button("Copy to clipboard", suit.layout:row(300,25)).hit then
            love.system.setClipboardText(getStringVerts(result, check_formated.checked, check_tbl_of_tbl.checked))
        end

        suit.layout:row(0,4)
        if suit.Button("Export to file (.lua)", suit.layout:row(300,25)).hit then
            exportVerts(export_path_input.text, getStringVerts(result, check_formated.checked, check_tbl_of_tbl.checked))
        end

        suit.layout:row(0,4)
        if suit.Button("Cancel", suit.layout:row(300,25)).hit then
            on_export = false
        end

    elseif result then

        suit.layout:row(0,4)
        suit.Slider(slider_simplify, suit.layout:col(128,25))

        suit.layout:col(0,0)
        if suit.Button(("Simplify (%.2f)"):format(slider_simplify.value), suit.layout:row(172,25)).hit then
            time = os.clock()
            result = simplify(result, slider_simplify.value)
            time = os.clock()-time
        end

        suit.layout:reset(50,138)

        suit.layout:row(0,4)
        if suit.Button("Export", suit.layout:row(300,25)).hit then
            on_export = true
        end

        suit.layout:row(0,4)
        suit.Label(("Operation performed in: %.4f secondes"):format(time), {align = "left"}, suit.layout:row(300,25))

    end

end

function love.filedropped(file)
	if not on_export and valid_formats[file:getExtension()] then
        path_input.text = file:getFilename()
	end
end

function love.textedited(text, start, length)
    suit.textedited(text, start, length)
end

function love.textinput(t)
	suit.textinput(t)
end

function love.keypressed(key)
	suit.keypressed(key)
end

function love.draw()

    love.graphics.push()
    love.graphics.scale(_SX,_SY)

        suit.draw()

        -- Image preview --

        love.graphics.rectangle(
            "line", 420, 20, 160, 160
        )

        if image then

            love.graphics.draw(
                image, 440, 40, 0,
                120/image:getWidth(),
                120/image:getHeight()
            )

            if result then

                love.graphics.push()
                love.graphics.translate(440, 40)
                love.graphics.scale(120/image:getWidth(), 120/image:getHeight())

                    love.graphics.setColor(0,1,0)
                    love.graphics.polygon("line",result)
                    love.graphics.setColor(1,1,0)
                    love.graphics.points(result)
                    love.graphics.setColor(1,1,1)

                love.graphics.pop()

            end

        else
            love.graphics.print(
                "No image.", 500, 100, 0, 1, 1, 30.5, 7
            )
        end

    love.graphics.pop()

end

function love.resize()
    _SX = love.graphics.getWidth()/_OW
    _SY = love.graphics.getHeight()/_OH
end