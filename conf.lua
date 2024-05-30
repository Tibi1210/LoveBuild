_G.love = require("love")
Int = require "lib/int"
MapLoader = require "lib/mapLoader"

FPS = 60
SW = 800
SH = 600

EyeHeight = 6
CrouchHeight = 2.5
HeadMargin = 1
KneeHeight = 2

H_FOV = 0.73*SH
V_FOV = 0.2*SW


function love.conf(t)
    t.window.title = "LoveBuild"

    t.window.height = SH
    t.window.width = SW
    t.window.resizable = false

    t.console = true
    
    --t.window.borderless = true
end
