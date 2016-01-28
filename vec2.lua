Vec2 = {}
Vec2.x = 0
Vec2.y = 0
Vec2.__index = Vec2

function Vec2:setpos(x, y)
	self.x = x
	self.y = y
end

function Vec2:add(...)
	for __, v in pairs({...}) do
		self.x = self.x + v.x
		self.y = self.y + v.y
	end
end

function Vec2:mul(scalar)
	self.x = self.x * scalar
	self.y = self.y * scalar
end

function Vec2:tostring()
	return "(" .. self.x .. "," .. self.y .. ")"
end

function Vector(x, y)
	local object = {
		x = x,
		y = y
	}

	return setmetatable(object, Vec2)
end

