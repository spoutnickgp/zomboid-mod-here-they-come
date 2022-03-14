require("media/lua/server/HereTheyComeSpawn")
require("media/lua/server/HereTheyComeHelpers")
require("./tests/lib/ZomboidMocks")
lu = require('./tests/lib/luaunit')

function test_spawn_outfit()
    local z = HTC_spawnZombieAt(0, 0, {"toto"})
    lu.assertEquals(z:size(), 1)
end

function test_circle_offset_positive_start_positive_angle()
    local pos = HTC_getPointOnCircle(5, 5, 45, 100)
    lu.assertTrue(math.abs(75 - pos.x) < 1.0)
    lu.assertTrue(math.abs(75 - pos.y) < 1.0)
end

function test_circle_offset_negative_start_positive_angle()
    local pos = HTC_getPointOnCircle(-5, -5, 45, 100)
    lu.assertTrue(math.abs(65 - pos.x) < 1.0)
    lu.assertTrue(math.abs(65 - pos.y) < 1.0)
end


os.exit( lu.LuaUnit.run() )