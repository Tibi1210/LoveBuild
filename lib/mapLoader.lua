local mapLoader = {}

-- float floor
-- float ceil
-- struct vertexes {float x,
--                float y}
-- char neighbors
-- unsigned npoints
local sectors = {}

-- float x
-- float y
local vertex = {}

-- struct where {float x,
--               float y}
--               float z}
-- struct velocity {float x,
--                  float y}
--                  float z}
-- float angle
-- float angleCos
-- float angleSin
-- float yaw
-- unsigned sector
local player = {}

local function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end

local function loadVertexes(y, listX)
    local v = split(listX, ",")
    for i = 1, #v do
        table.insert(vertex, {})
        vertex[#vertex].x = v[i]
        vertex[#vertex].y = y
    end
end

local function loadSectors(heights, vert, neighbors)
    table.insert(sectors, {})
    local h = split(heights, ",")
    local v = split(vert, ",")
    local n = split(neighbors, ",")
    sectors[#sectors].floor = tonumber(h[1])
    sectors[#sectors].ceil = tonumber(h[2])
    sectors[#sectors].npoints = #v
    sectors[#sectors].neighbors = n

    sectors[#sectors].vertexes = {}
    table.insert(sectors[#sectors].vertexes, vertex[v[#v] + 1])
    for i = 1, #v do
        table.insert(sectors[#sectors].vertexes, vertex[v[i] + 1])
    end
end

local function loadPlayer(pos, angle, sector)
    local p = split(pos, ",")
    player.angle = tonumber(angle)
    player.angleCos = math.cos(player.angle)
    player.angleSin = math.sin(player.angle)
    player.sector = tonumber(sector)
    player.where = {}
    player.where.x = p[1]
    player.where.y = p[2]
    player.where.z = 6
    player.velocity = {}
    player.velocity.x = 0
    player.velocity.y = 0
    player.velocity.z = 0
    player.yaw = 0
end


function mapLoader.loadMap(file)
    sectors = {}
    vertex = {}
    player = {}
    for line in io.lines("maps/" .. file .. ".txt") do
        local data = split(line, " ")
        if data[1] == "vertex" then
            loadVertexes(data[2], data[3])
        end
        if data[1] == "sector" then
            loadSectors(data[2], data[3], data[4])
        end
        if data[1] == "player" then
            loadPlayer(data[2], data[3], data[4])
        end
    end
    return sectors, player
end

return mapLoader