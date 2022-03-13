require("media/lua/server/HereTheyComeSpawn")
require("./tests/lib/ZomboidMocks")
lu = require('./tests/lib/luaunit')

function test_spawn_outfit()
    local z = HTC_spawnZombieAt(0, 0, {"toto"})
    lu.assertEquals(z:size(), 1)
end


function test_circle_offset_positive_start_positive_angle()
    local pos = HTC_getPointOnCircle(5, 5, 45, 100)
    lu.assertTrue(pos.x > 75)
    lu.assertTrue(pos.x < 76)
    lu.assertTrue(pos.y > 75)
    lu.assertTrue(pos.y < 76)

end

function test_circle_offset_negative_start_positive_angle()
    local pos = HTC_getPointOnCircle(-5, -5, 45, 100)
    lu.assertTrue(pos.x > 65)
    lu.assertTrue(pos.x < 66)
    lu.assertTrue(pos.y > 65)
    lu.assertTrue(pos.y < 66)
end


os.exit( lu.LuaUnit.run() )