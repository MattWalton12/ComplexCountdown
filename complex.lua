local CNumber = {}
CNumber.__index = CNumber

function CNumber:mul(param)
	if type(param) == "number" then param = Complex(param, 0) end
	return Complex(self.real * param.real - self.imaginary * param.imaginary, self.real * param.imaginary + param.real * self.imaginary)
end

function CNumber:div(param)
	if type(param) == "number" then param = Complex(param, 0) end
	return self:mul(Complex(param.real, -param.imaginary))
end

function CNumber:add(param)
	if type(param) == "number" then param = Complex(param, 0) end
	return Complex(self.real + param.real, self.imaginary + param.imaginary)
end

function CNumber:sub(param)
	if type(param) == "number" then param = Complex(param, 0) end
	return Complex(self.real - param.real, self.imaginary - param.imaginary)
end

function CNumber:equals(param)
	if type(param) == "number" then param = Complex(param, 0) end
	return (math.floor(self.real * 100000 + 0.5) == math.floor(param.real * 100000 + 0.5)) and (math.floor(self.imaginary * 100000 + 0.5) == math.floor(param.imaginary * 100000 + 0.5)) 
end

function CNumber:square()
	return self:mul(self)
end

function CNumber:mod()
	return math.sqrt(math.pow(self.real, 2) + math.pow(self.imaginary, 2))
end

function CNumber:tostring()
	if (self.real == 0) then return self.imaginary .. "i" end
	if (self.imaginary == 0) then return tostring(self.real) end
	return self.real .. (self.imaginary < 0 and "-" or "+") .. math.abs(self.imaginary) .. "i"
end

function Complex(real, imaginary)
	local object = {
		real = real,
		imaginary = imaginary
	}


	return setmetatable(object, CNumber)
end