FPS = 60
SW = 800
SH = 600


function love.conf(t)
    t.window.title = "LoveBuild"

    t.window.height = SH
    t.window.width = SW
    t.window.resizable = false

    t.console = true
    
    --t.window.borderless = true
end
