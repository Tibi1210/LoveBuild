_G.love = require("love")
local mapLoader = require "lib/mapLoader"

local next_time
local min_dt

local sectors = {
    -- float floor
    -- float ceil
    -- struct vertexes {float x,
    --                float y}
    -- char neighbors
    -- unsigned npoints
}
local numSectors = 0

local player = {
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
}

local function drawPixel(x, y, r, g, b)

    love.graphics.setColor(love.math.colorFromBytes(r, g, b))
    love.graphics.points(x, y)
end


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    love.keyboard.setKeyRepeat(true)
    min_dt = 1 / FPS
    next_time = love.timer.getTime()

    sectors, player = mapLoader.loadMap("map-clear")
    print(player.angleSin)
end

function love.update(dt)
    next_time = next_time + min_dt

    if love.keyboard.isDown("a") then
    end

    if love.keyboard.isDown("d") then
    end

    if love.keyboard.isDown("w") then
    end

    if love.keyboard.isDown("s") then
    end
end

function love.draw()
    love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 12)

    for i = 1, #sectors, 1 do
        for j = 1, #sectors[i].vertexes do
            drawPixel((sectors[i].vertexes[j].x+10)*10, (sectors[i].vertexes[j].y+10)*10, 255,255,255)
        end
    end

    drawPixel((player.where.x+10)*10, (player.where.y+10)*10, 255,0,0)

    local cur_time = love.timer.getTime()
    if next_time <= cur_time then
        next_time = cur_time
        return
    end
    love.timer.sleep(next_time - cur_time)

end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end
    if key == 'space' then
        love.event.quit("restart")
      end

end
