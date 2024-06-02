local next_time
local min_dt
local map = false
local renderLimit = 16

local colors = {
    red = {255,0,0},
    green = {0,255,0},
    blue = {0,0,255},
    black = {0,0,0},
    white = {255,255,255},
    light_grey = {200,200,200},
    dark_grey = {100,100,100},
}

-- float floor;
-- float ceil;
-- struct vertexes {float x,
--                float y};
-- char neighbors;
-- unsigned npoints;
-- unsigned isRendered;
local sectors = {}

-- struct where {float x,
--               float y
--               float z};
-- struct velocity {float x,
--                  float y
--                  float z};
-- float angle;
-- float angleCos;
-- float angleSin;
-- float yaw;
-- unsigned sector;
local player = {}


local function table_contains(tab, val)
    for key, value in pairs(tab) do
       if value.sectorno == val then
            return true
       end
    end

    return false
end

-- clamp value into set range
local function clamp(a, mi,ma)
    return math.min(math.max(a,mi),ma)
end
-- determines if two number of ranges overlap
local function overlap(a0,a1, b0,b1)
    return (math.min(a0, a1) <= math.max(b0, b1) and math.min(b0, b1) <= math.max(a0, a1))
end
-- determines if two 2D boxes intersect
local function intersectBox(x0,y0, x1,y1, x2,y2, x3,y3)
    return (overlap(x0,x1,x2,x3) and overlap(y0,y1,y2,y3))
end
-- vector cross product
local function vxs(x0,y0, x1,y1)
    return (x0*y1 - x1*y0)
end
-- determines wich side of the line the point is on
local function pointSide(px,py, x0,y0, x1,y1)
    return vxs(x1-x0, y1-y0, px-x0, py-y0)
end
-- calculate point of intersection between two lines
local function intersect(x1,y1, x2,y2, x3,y3, x4,y4)
    -- float x;
    -- float y
    local vertex = {}
    vertex.x = vxs(vxs(x1,y1, x2,y2), (x1)-(x2), vxs(x3,y3, x4,y4), (x3)-(x4)) / vxs((x1)-(x2), (y1)-(y2), (x3)-(x4), (y3)-(y4))
    vertex.y = vxs(vxs(x1,y1, x2,y2), (y1)-(y2), vxs(x3,y3, x4,y4), (y3)-(y4)) / vxs((x1)-(x2), (y1)-(y2), (x3)-(x4), (y3)-(y4))
    return vertex
end

-- draws a pixel on a given x,y coordinate of the window in the color r,g,b
local function drawPixel(x, y, r, g, b)
    love.graphics.setColor(love.math.colorFromBytes(r, g, b))
    love.graphics.points(x, y)
end

-- draw a vertical line with a different color top and bottom
local function vLine(x, y1, y2, top, middle, bottom)
   love.graphics.setColor(love.math.colorFromBytes(top[1], top[2], top[3]))
   love.graphics.points(x, y1)
   love.graphics.setColor(love.math.colorFromBytes(middle[1], middle[2], middle[3]))
   if y1<y2 then
        love.graphics.line(x, y1+1, x, y2)
    else
        love.graphics.line(x, y2+1, x, y1)
    end
   love.graphics.setColor(love.math.colorFromBytes(bottom[1], bottom[2], bottom[3]))
   love.graphics.points(x, y2)
end

-- renders sectors->walls
local function DrawScreen()
    local renderQ = 0
    local renderQueue = {}

    table.insert(renderQueue, {
        sectorno = player.sector, -- int
        sx1 = 1, -- int
        sx2 = SW-1 -- int
    })

    local ytop = {}    --int array
    local ybottom = {}    --int array
    for i=1, SW do ytop[i] = 0 end
    for i=1, SW do ybottom[i] = SH-1 end

    print("##############################")
    while (renderQ < renderLimit) and (renderQueue[1] ~= nil) do
        
        local now = table.remove(renderQueue, 1)

        if sectors[now.sectorno].isRendered == 1 then goto SectorContinue end

        local sect = sectors[now.sectorno]
        print("Redering sector: " .. now.sectorno)
        sectors[now.sectorno].isRendered = 1
    
        -- render each wall of the sector
        for s = 1, sect.npoints do
            -- get (x,y) coords of the two ends of the sector
            -- transform into players view
            local vx1 = sect.vertexes[s+0].x - player.where.x -- float
            local vy1 = sect.vertexes[s+0].y - player.where.y -- float
            local vx2 = sect.vertexes[s+1].x - player.where.x -- float
            local vy2 = sect.vertexes[s+1].y - player.where.y -- float
            
            -- rotate them around the player
            local pcos = player.angleCos -- float
            local psin = player.angleSin -- float
            local tx1 = vx1 * psin - vy1 * pcos -- float
            local tz1 = vx1 * pcos + vy1 * psin -- float
            local tx2 = vx2 * psin - vy2 * pcos -- float
            local tz2 = vx2 * pcos + vy2 * psin -- float
    
            -- is the wall in front of the player
            if tz1 <= 0 and tz2 <=0 then goto WallContinue end
            -- if partially behind player clip
            if tz1 <= 0 or tz2 <=0 then
                local nearz = 1*(10^(-4)) -- float
                local farz = 5 -- float
                local nearside = 1*(10^(-5))
                local farside = 20.0
                local i1 = intersect(tx1,tz1,tx2,tz2, -nearside, nearz, -farside, farz) -- vertex
                local i2 = intersect(tx1,tz1,tx2,tz2,  nearside, nearz,  farside, farz) -- vertex
                if tz1 < nearz then
                    if i1.y > 0 then
                        tx1 = i1.x
                        tz1 = i1.y
                    else
                        tx1 = i2.x
                        tz1 = i2.y
                    end
                end
    
                if tz2 < nearz then
                    if i1.y > 0 then
                        tx2 = i1.x
                        tz2 = i1.y
                    else
                        tx2 = i2.x
                        tz2 = i2.y
                    end
                end
            end
            
            -- perspective transformation
            local xscale1 = H_FOV / tz1
            local yscale1 = V_FOV / tz1
            local x1 = Int:create(SW/2 - Int:create(tx1 * xscale1)[1]) -- integer
    
            local xscale2 = H_FOV / tz2
            local yscale2 = V_FOV / tz2
            local x2 = Int:create(SW/2 - Int:create(tx2 * xscale2)[1]) -- integer
            -- only render if visible
            if x1[1]>=x2[1] or x2[1]<now.sx1 or x1[1]>now.sx2 then goto WallContinue end
    
            -- floor and ceiling heights relative to player
            local yceil = sect.ceil - player.where.z -- float
            local yfloor = sect.floor - player.where.z -- float
    
            local neighbor = sect.neighbors[s]
    
            local nyceil = 0 --float
            local nyfloor = 0 --float
            if neighbor >= 0 then
                nyceil = sectors[neighbor].ceil - player.where.z
                nyfloor = sectors[neighbor].floor - player.where.z
            end
    
            -- project ceiling and floor heights into screen coodrinates
            local y1a = Int:create(SH/2 - Int:create(yceil * yscale1)[1]) -- integer
            local y1b = Int:create(SH/2 - Int:create(yfloor * yscale1)[1]) -- integer
            local y2a = Int:create(SH/2 - Int:create(yceil * yscale2)[1]) -- integer
            local y2b = Int:create(SH/2 - Int:create(yfloor * yscale2)[1]) -- integer
            -- project neighbors ceiling and floor heights into screen coodrinates
            local ny1a = Int:create(SH/2 - Int:create(nyceil * yscale1)[1]) -- integer
            local ny1b = Int:create(SH/2 - Int:create(nyfloor * yscale1)[1]) -- integer
            local ny2a = Int:create(SH/2 - Int:create(nyceil * yscale2)[1]) -- integer
            local ny2b = Int:create(SH/2 - Int:create(nyfloor * yscale2)[1]) -- integer
    
            -- render wall
    
            local beginx = math.max(x1[1], now.sx1) -- integer
            local endx = math.min(x2[1], now.sx2) -- integer
            for x = beginx, endx do  --------------------------------- i<=endx
    
                -- Y coords of ceiling and floor for this X coord
                local ya = Int:create((x - x1[1]) * (y2a[1] - y1a[1]) / (x2[1] - x1[1]) + y1a[1]) -- integer
                local cya = Int:create(clamp(ya[1], ytop[x], ybottom[x])) -- integer
                local yb = Int:create((x - x1[1]) * (y2b[1] - y1b[1]) / (x2[1] - x1[1]) + y1b[1]) -- integer
                local cyb = Int:create(clamp(yb[1], ytop[x], ybottom[x])) -- integer
                
                
                -- render ceiling
                vLine(x, ytop[x], (cya-1)[1], colors.black,colors.dark_grey,colors.black)
                -- render floor
                vLine(x, (cyb+1)[1], ybottom[x], colors.black,colors.blue,colors.black)

                -- sector neighbors
                if tonumber(neighbor) >= 0 then
                    -- Y coords of ceiling and floor for this X coord
                    local nya = Int:create((x - x1[1]) * (ny2a[1] - ny1a[1]) / (x2[1] - x1[1]) + ny1a[1]) -- integer
                    local ncya = Int:create(clamp(nya[1], ytop[x], ybottom[x])) -- integer
                    local nyb = Int:create((x - x1[1]) * (ny2b[1] - ny1b[1]) / (x2[1] - x1[1]) + ny1b[1]) -- integer
                    local ncyb = Int:create(clamp(nyb[1], ytop[x], ybottom[x])) -- integer
    
                    -- top wall
                    vLine(x, cya[1], (ncya-1)[1], colors.black,colors.light_grey,colors.black)
                    ytop[x] = clamp(math.max(cya[1], ncya[1]), ytop[x], SH-1)
    
                    -- bottom wall
                    vLine(x, (ncyb+1)[1], cyb[1], colors.black,colors.light_grey,colors.black)
                    ybottom[x] = clamp(math.min(cyb[1], ncyb[1]), 0, ybottom[x])
    
                    -- placeholder portals
                    -- vLine(x, ytop[x], ybottom[x], colors.black,colors.red,colors.black)
    
                else
                    -- render wall
                    vLine(x, cya[1], cyb[1], colors.black,colors.light_grey,colors.black)
                end
            end

            if neighbor >= 0 and endx > beginx and (sectors[neighbor].isRendered == 0 and not table_contains(renderQueue, neighbor)) then
                table.insert(renderQueue, {
                    sectorno = neighbor, -- int
                    sx1 = beginx, -- int
                    sx2 = endx -- int
                })
            end
    
            ::WallContinue::
        end

        renderQ = renderQ + 1
        print("Rendered num: " .. renderQ)

        io.write("Render queue: ")
        for key, value in pairs(renderQueue) do
            io.write(value.sectorno..", ")
        end
        print()
        print()


        ::SectorContinue::
    end
    for key, value in pairs(sectors) do
        value.isRendered = 0
    end

end

-- moves and rotates player
local function movePlayer(dx, dy, dt)
    local px = player.where.x
    local py = player.where.y
    local sect = sectors[player.sector]
    local acceleration = 1

    for s = 1, sect.npoints do
        if sect.neighbors[s] >= 0
         and intersectBox(px,py, px+dx,py+dy, sect.vertexes[s+0].x, sect.vertexes[s+0].y, sect.vertexes[s+1].x, sect.vertexes[s+1].y)
          and pointSide(px+dx, py+dy, sect.vertexes[s+0].x, sect.vertexes[s+0].y, sect.vertexes[s+1].x, sect.vertexes[s+1].y) < 0 then
            player.sector = sect.neighbors[s]
            print("Player is now in sector: " .. player.sector)
        end
    end

    player.velocity.x = player.velocity.x * (1-acceleration) + dx * acceleration *dt
    player.velocity.y = player.velocity.y * (1-acceleration) + dy * acceleration *dt

    player.where.x = player.where.x + player.velocity.x
    player.where.y = player.where.y + player.velocity.y
    
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest", 0)
    love.keyboard.setKeyRepeat(true)
    min_dt = 1 / FPS
    next_time = love.timer.getTime()

    sectors, player = MapLoader.loadMap("map-clear")

end

function love.update(dt)
    next_time = next_time + min_dt

    local move_vec = {0.0, 0.0}
    if love.keyboard.isDown("a") then
        move_vec[1] = move_vec[1] + player.angleSin*0.2
        move_vec[2] = move_vec[2] - player.angleCos*0.2
    end

    if love.keyboard.isDown("d") then
        move_vec[1] = move_vec[1] - player.angleSin*0.2
        move_vec[2] = move_vec[2] + player.angleCos*0.2
    end

    if love.keyboard.isDown("w") then
        move_vec[1] = move_vec[1] + player.angleCos*0.2
        move_vec[2] = move_vec[2] + player.angleSin*0.2
    end

    if love.keyboard.isDown("s") then
        move_vec[1] = move_vec[1] - player.angleCos*0.2
        move_vec[2] = move_vec[2] - player.angleSin*0.2
    end

    movePlayer(move_vec[1], move_vec[2], dt)

end


function love.draw()

    if map then
        for i = 1, #sectors, 1 do
            for j = 1, #sectors[i].vertexes do
                drawPixel((sectors[i].vertexes[j].x+(SW/2)), (sectors[i].vertexes[j].y+(SH/2)), 255,255,255)
            end
        end
        drawPixel((player.where.x+(SW/2)), (player.where.y+(SH/2)), 255,0,0)
    else
        DrawScreen()
    end
   
    love.graphics.setColor(love.math.colorFromBytes(255, 255, 255))
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 12)
    
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
    
    if key == 'm' then
        map = not map
        print("Map opened: ".. tostring(map))
    end

    if key == '[' then
        renderLimit = renderLimit - 1
    end
    if key == ']' then
        renderLimit = renderLimit + 1
    end

    if key == "tab" then
        --local state = not love.mouse.isVisible()
        --love.mouse.setVisible(state)
        --local state = not love.mouse.isGrabbed()
        --love.mouse.setGrabbed(state)
        local relative = love.mouse.getRelativeMode()
        love.mouse.setRelativeMode(not relative)
     end
    
end

function love.mousemoved( x, y, dx, dy, istouch )
    player.angle = player.angle + dx * 0.01
    player.angleCos = math.cos(player.angle)
    player.angleSin = math.sin(player.angle)
    local yaw = 0
    yaw = clamp(yaw - dy * 0.05, -5, 0)
    player.yaw = yaw - player.velocity.z * 0.5
end