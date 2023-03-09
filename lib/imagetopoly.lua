-- License CC0

local ccw = function(a,b,c)
    return (b[1]-a[1]) * (c[2]-a[2]) > (b[2]-a[2]) * (c[1]-a[1])
end

local function distance(x1,y1,x2,y2)
    return math.sqrt((x1-x2)^2+(y1-y2)^2)
end

local function convexHull(poly)

    if #poly == 0 then return {} end

    local pl = {}
    for i = 1, #poly-1, 2 do
        pl[#pl+1] = {poly[i], poly[i+1]}
    end

    table.sort(pl, function(left,right)
        return left[1] < right[1]
    end)

    local h = {}

    for i,pt in ipairs(pl) do
        while #h >= 2 and not ccw(h[#h-1], h[#h], pt) do
            table.remove(h,#h)
        end
        table.insert(h,pt)
    end

    local t = #h + 1
    for i=#pl, 1, -1 do
        local pt = pl[i]
        while #h >= t and not ccw(h[#h-1], h[#h], pt) do
            table.remove(h,#h)
        end
        table.insert(h,pt)
    end

    table.remove(h,#h)

    pl = {}
    for _, v in pairs(h) do
        pl[#pl+1] = v[1]
        pl[#pl+1] = v[2]
    end

    return pl

end

local function reduceVerts(verts, to)
    while #verts/2 > to do
        local minDist = math.huge
        local minIndex = 0
        for i = 1, #verts-3, 2 do
            local d1 = distance(verts[i], verts[i+1], verts[i+2], verts[i+3])
            local d2 = distance(verts[i], verts[i+1], verts[(i-2>1) and i-2 or #verts-1], verts[(i-1>1) and i-1 or #verts])
            if d1+d2 < minDist then
                minDist = d1+d2
                minIndex = i
            end
        end
        table.remove(verts, minIndex)
        table.remove(verts, minIndex)
    end
    return verts
end

return function (imageData, threshold, max_verts)

    max_verts = max_verts and math.max(max_verts,3) or math.huge

    local width, height = imageData:getDimensions()

    local verts = {}
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local _, _, _, alpha = imageData:getPixel(x, y)
            if alpha >= threshold then
                verts[#verts+1] = x
                verts[#verts+1] = y
            end
        end
    end

    verts = convexHull(verts)

    if max_verts then
        if #verts/2 > max_verts then
            reduceVerts(verts, max_verts)
        end
    end

    return verts

end