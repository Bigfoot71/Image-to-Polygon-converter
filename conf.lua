_OW = 600
_OH = 200
_SX = 1
_SY = 1

function love.conf(t)

    t.window.width = _OW
    t.window.height = _OH
    t.window.resizable = true
    t.window.title = "Image to Polygon converter"

    t.modules.image = true
    t.modules.window = true
    t.modules.graphics = true
    t.modules.system = true
    t.modules.event = true
    t.modules.timer = true
    t.modules.mouse = true
    t.modules.font = true

    t.modules.audio = false
    t.modules.data = false
    t.modules.joystick = false
    t.modules.keyboard = false
    t.modules.math = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.thread = false
    t.modules.touch = false
    t.modules.video = false

end
