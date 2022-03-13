-- Mocks to Java Objects
Zombie = {

}

function Zombie:new (outfit)
    o = {
        outfit = o
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Zombie:pathToCharacter(character)
end

JavaList = {
    items = {}
}

function JavaList:new (o)
    o = o or {
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function JavaList:append(o)
    table.insert(self.items, o)
end

function JavaList:size()
    return #self.items
end

function JavaList:get(key)
    return self.items[key + 1]
end

function ZombRand(x)
    return math.random(1, x)
end

function addZombiesInOutfit(x, y, num, outfit, a, b, c, d, e, f)
    local l = JavaList:new()
    l:append(Zombie:new(outfit))
    return l
end