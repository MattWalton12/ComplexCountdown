require("complex")
require("vec2")

local STATE_NONE = -1
local STATE_SELECT = 0
local STATE_PREPLAY = 1
local STATE_PLAYING = 2
local STATE_FINISHED = 3
local STATE_SOLUTIONS = 4
local STATE_BESTSOLUTION = 5

game = {}
game.selectedCards = {}
game.targetNumber = {}
game.solution = {}
game.playingCards = {}
game.state = STATE_NONE
game.stateChange = 0
game.timeStart = 0
game.cursor = love.mouse.getSystemCursor("arrow")
game.calculatedSolution = {}

game.options = {}
game.options.numberOfCards = 6

game.resources = {}
game.resources.sansFont = {}
-- 
game.resources.lcdFont = {}
-- http://www.dafont.com/calculator.font?text=10+%2B+9i&back=theme
game.resources.timerSound = {}

game.cardNumbers = {
	-- Top row numbers
	{
		Complex(25, 0), Complex(50, 0), Complex(75, 0), Complex(100, 0),
		Complex(0, 25), Complex(0, 50), Complex(0, 75), Complex(0, 100)
	},
	
	-- Bottom row numbers
	{
		Complex(1, 0), Complex(2, 0), Complex(3, 0), Complex(4, 0), Complex(5, 0), Complex(6, 0), Complex(7, 0), Complex(8, 0), Complex(9, 0), Complex(10, 0),
		Complex(0, 1), Complex(0, 2), Complex(0, 3), Complex(0, 4), Complex(0, 5), Complex(0, 6), Complex(0, 7), Complex(0, 8), Complex(0, 9), Complex(0, 10)
	}

}

game.operators = {
}

game.bestSolutions = {}

function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return res
end


game.placeNumber = false

local GameCard = {}
GameCard.value = 0
GameCard.hovered = false
GameCard.pos = {}
GameCard.size = {}
GameCard.selected = false
GameCard.used = false
GameCard.buffer = 0
GameCard.startPos = 0
GameCard.__index = GameCard

function GameCard:select()
	if (game.state == STATE_SELECT ) and (not self.selected and #game.selectedCards < game.options.numberOfCards) then
		
		self.selected = true
		self.size[1] = (love.graphics.getWidth() - love.graphics.getWidth()/2.3 - game.options.numberOfCards * 10) / game.options.numberOfCards
		self.size[2] = self.size[1] * 1.4
		self.pos.x = love.graphics.getWidth()/4.6 + (self.size[1] + 10) * #game.selectedCards
		self.startPos = self.pos.x
		self.pos.y = love.graphics.getHeight() - 250 - self.size[2] - 20

		self.buffer = love.graphics.getWidth() / 4.6

		table.insert(game.selectedCards, self)

		if #game.selectedCards == game.options.numberOfCards then
			game.state = STATE_PREPLAY
			game.generateRandomNumber()
			game.stateChange = love.timer.getTime()
		end
	end

	if game.placeNumber and (game.state == STATE_PLAYING or game.state == STATE_FINISHED) and not self.used then
		table.insert(game.solution, self.value)
		self.used = true
		game.placeNumber = false
	end
end

function GameCard:draw()
	if (self.selected) then
		if self.used then return end
		love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
		love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size[1], self.size[2])
		if not self.hovered then love.graphics.setColor(106, 137, 232) end
		love.graphics.rectangle("fill", self.pos.x + 3, self.pos.y + 3, self.size[1] - 6, self.size[2] - 6)

		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(game.resources.sansFont)
		love.graphics.printf(self.value:tostring(), self.pos.x + 3, self.pos.y + self.size[2]/2 - 16, self.size[1]-6, "center")
	else
		love.graphics.setColor(30, 30, 30, 255)
		love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size[1], self.size[2])
		if self.hovered then
			love.graphics.setColor(180, 180, 180, 255)
		else
			love.graphics.setColor(225, 225, 225, 255)
		end
		love.graphics.rectangle("fill", self.pos.x + 2, self.pos.y + 2, self.size[1] - 4, self.size[2] - 4)
	end
end

local handCursor = love.mouse.getSystemCursor("hand")

function GameCard:update(dt)
	local x, y = love.mouse.getPosition()

	if (x > self.pos.x and x < (self.pos.x + self.size[1])) and (y > self.pos.y and y < (self.pos.y + self.size[2])) then
		self.hovered = true
		game.cursor = handCursor
	else
		self.hovered = false

	end

	
	if game.state == STATE_PREPLAY and love.timer.getTime() - game.stateChange < 1 then
		self.pos.x = self.startPos - math.min(self.buffer, (self.buffer/2) * (love.timer.getTime() - game.stateChange))
	end
	
end


local function CreateGameCard(value)
	local object = {
		value = value
	}

	return setmetatable(object, GameCard)
end

local OperatorButton = {}
OperatorButton.__index = OperatorButton
OperatorButton.value = ""
OperatorButton.pos = {}
OperatorButton.size = {}
OperatorButton.hovered = false
OperatorButton.visible = false

function OperatorButton:draw()
	love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
	love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size[1], self.size[2])
	if not self.hovered then love.graphics.setColor(106, 137, 232) end

	love.graphics.rectangle("fill", self.pos.x + 3, self.pos.y + 3, self.size[1] - 6, self.size[2] - 6)

	love.graphics.setColor(255, 255, 255)
	love.graphics.setFont(game.resources.sansFont)
	love.graphics.printf(self.value, self.pos.x, self.pos.y + self.size[2]/2 - 18, self.size[1], "center")
end

function OperatorButton:update(dt)
	local x, y = love.mouse.getPosition()

	if (x > self.pos.x and x < (self.pos.x + self.size[1])) and (y > self.pos.y and y < (self.pos.y + self.size[2])) then
		self.hovered = true
		game.cursor = handCursor
	else
		self.hovered = false

	end
end

function OperatorButton:select()
	if (not game.placeNumber or self.value == "(" or self.value == ")") then
		table.insert(game.solution, self.value)
		if (not (self.value == "(" or self.value == ")")) then 
			game.placeNumber = true
		end
	end
end

local function CreateOperatorButton(val, pos, size)
	local object = {
		value = val,
		pos = pos,
		hovered = false,
		visible = false,
		size = size
	}

	return setmetatable(object, OperatorButton)
end


function game.init()
	game.playingCards = {{}, {}}
	game.bestSolutions = {}

	for i=1, 4 do
		game.playingCards[1][i] = CreateGameCard(game.cardNumbers[1][math.random(1, #game.cardNumbers[1])])
	end

	for i=1, 20 do
		game.playingCards[2][i] = CreateGameCard(game.cardNumbers[2][math.random(1, #game.cardNumbers[2])])
	end

	game.calculateCardPositions()

	game.state = STATE_SELECT
	game.selectedCards = {}

	local cardWidth = (love.graphics.getWidth() - love.graphics.getWidth()/2.3 - game.options.numberOfCards * 10) / game.options.numberOfCards
	local cardBuffer = love.graphics.getWidth() / 4.6
	local cardHeight = cardWidth * 1.4

	local cardY = love.graphics.getHeight() - 250 - cardHeight - 20

	local buttonWidth = cardWidth / 2
	local buttonBuffer = 10
	local buttonHeight = (cardHeight - buttonBuffer) /2
	

	local buttonStartX = love.graphics.getWidth() - ((buttonWidth + buttonBuffer) * 3) - cardBuffer/2

	game.operators = {
		CreateOperatorButton("+", Vector(buttonStartX, cardY), {buttonWidth, buttonHeight}),
		CreateOperatorButton("-", Vector(buttonStartX, cardY + buttonBuffer + buttonHeight), {buttonWidth, buttonHeight}),
		CreateOperatorButton("x", Vector(buttonStartX + buttonBuffer + buttonWidth, cardY), {buttonWidth, buttonHeight}),
		CreateOperatorButton("÷", Vector(buttonStartX + buttonBuffer + buttonWidth, cardY + buttonBuffer + buttonHeight), {buttonWidth, buttonHeight}),
		CreateOperatorButton("(", Vector(buttonStartX + (buttonBuffer + buttonWidth) * 2, cardY), {buttonWidth, buttonHeight}),
		CreateOperatorButton(")", Vector(buttonStartX + (buttonBuffer + buttonWidth) * 2, cardY + buttonBuffer + buttonHeight), {buttonWidth, buttonHeight})
	}

	game.solution = {}
	game.placeNumber = true
end

function game.startTimer()
	--love.audio.play(game.resources.timerSound)
end

function game.generateRandomNumber()
	game.targetNumber = Complex((math.random(0, 5) == 0 and 0 or math.random(0, 250)), (math.random(0, 5) == 0 and 0 or math.random(0, 250)))
end

function game.drawBackground()
	love.graphics.setColor(220, 220, 220)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(106 * .8, 137 * .8, 232 * .8)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 250, love.graphics.getWidth(), 250)
end

function game.drawTargetNumber(y)
	love.graphics.setColor(10, 10, 10)
	love.graphics.rectangle("fill", love.graphics.getWidth() /2 - 150, y - 40, 300, 80)

	local text = ""

	if love.timer.getTime() - game.stateChange <= 2 then
		text = math.random(0, 1000) .. (math.random(1, 3) == 1 and " - " or " + ") .. math.random(0, 1000) .. "i"
	else
		text = game.targetNumber:tostring()
	end

	love.graphics.setColor(235, 245, 51)
	love.graphics.setFont(game.resources.lcdFont)
	love.graphics.printf(text, love.graphics.getWidth() /2 - 150, y - 26, 300, "center")
end



function game.drawOperatorButtons() 
	for __, operator in pairs(game.operators) do
		operator:draw()
	end
end

function game.drawClock(x, y, r)
	local timePercentage = game.state == STATE_PLAYING and (100 / 30 * math.min(love.timer.getTime() - game.timeStart, 30)) or 0

	love.graphics.setColor(106, 137, 232)
	love.graphics.circle("fill", x, y, r, 512)

	love.graphics.setColor(245, 245, 245)
	love.graphics.circle("fill", x, y, r - 4, 512)

	love.graphics.setColor(70, 70, 70, 255)
	love.graphics.line(x, y - r+2, x, y + r-2)
	love.graphics.line(x - r+2, y, x + r-2, y)
	for i=1, 12 do
		love.graphics.line(x + (r/8*5-2) * math.sin((2*math.pi)/12 * i), y +  (r/8*5-2) * math.cos((2*math.pi)/12 * i), x + (r/6*5-2) * math.sin((2*math.pi)/12 * i), y +  (r/6*5-2) * math.cos((2*math.pi)/12*i))
	end

	love.graphics.setColor(106, 137, 232, 100)
	love.graphics.arc("fill", x, y, r-4, -math.pi/2 + (math.pi/100 * (timePercentage)), 3 * math.pi/2, 128)

	love.graphics.circle("fill", x, y, r/4, 128)
end

function game.calculateCardPositions()
	local buffer = love.graphics.getWidth() * 0.1
	local cardSpacing = love.graphics.getWidth() * 0.01

	local cardWidth = (love.graphics.getWidth() - buffer * 2 - cardSpacing * (#game.cardNumbers[2]-1)) / (#game.cardNumbers[2])
	local cardHeight = math.min(cardWidth * 1.6, 75)

	local topRowBuffer = love.graphics.getWidth() /2 - ((cardWidth+cardSpacing) * #game.playingCards[1]) /2
	-- Draw the top row
	for i, card in pairs(game.playingCards[1]) do
		card.pos = Vector(topRowBuffer + (cardWidth + cardSpacing) * (i-1), love.graphics.getHeight() - 200)
		card.size = {cardWidth, cardHeight}
	end

	for i, card in pairs(game.playingCards[2]) do
		card.pos = Vector(buffer + (cardWidth + cardSpacing) * (i-1), love.graphics.getHeight() - 120)
		card.size = {cardWidth, cardHeight}
	end
end

function game.drawCardSelect()
	-- Draw the top row
	for i, card in pairs(game.playingCards[1]) do
		card:draw()
	end

	for i, card in pairs(game.playingCards[2]) do
		card:draw()
	end

end

function game.drawActiveCards()
	for i, card in pairs(game.selectedCards) do
		card:draw()
	end
end

local playButtonHover = false

function game.drawPlayButton()
	local width = math.min(love.graphics.getWidth() - 20, 300)

	love.graphics.setColor(106, 137, 232)
	love.graphics.rectangle("fill", love.graphics.getWidth() /2 - width/2, love.graphics.getHeight() - 175, width, 100)

	love.graphics.setColor(225, 225, 225)
	love.graphics.rectangle("fill", love.graphics.getWidth() /2 - width/2 + 4, love.graphics.getHeight() - 175 + 4, width - 8, 92)

	love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
	love.graphics.setFont(game.resources.sansFont)
	love.graphics.printf("Play", love.graphics.getWidth() /2 - width/2 + 4, love.graphics.getHeight() - 125 - 16, width -8, "center")
end

function game.generateSolutionText(sol)
	local solution = ""
	for __, v in pairs(sol) do
		if type(v) == "table" then
			solution = solution .. " " .. v:tostring()
		else
			solution = solution .. " " .. tostring(v)
		end
	end

	return solution
end

function game.drawSolution()
	love.graphics.setFont(game.resources.sansFont)
	love.graphics.setColor(245, 245, 245)

	love.graphics.printf(game.generateSolutionText(game.solution), 0, love.graphics.getHeight() - 190, love.graphics.getWidth(), "center")
end

local deleteHover = false
local clearHover = false
local checkHover = false


function game.drawSolutionActions()

	love.graphics.setColor(106, 137, 232)
	if game.state ~= STATE_SOLUTIONS then 
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 300, love.graphics.getHeight() - 80, 120, 50)
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 + 180, love.graphics.getHeight() - 80, 120, 50)
	end

	if (game.state == STATE_FINISHED or game.state == STATE_SOLUTIONS) then
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 100, love.graphics.getHeight() - 80, 200, 50)
	end

	local x, y = love.mouse.getPosition()

	if deleteHover then
		love.graphics.setColor(180, 180, 180)
		game.cursor = handCursor
	else
		love.graphics.setColor(245, 245, 245)

	end

	if game.state ~= STATE_SOLUTIONS then 
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 298, love.graphics.getHeight() - 78, 116, 46)
	end

	if clearHover then
		love.graphics.setColor(180, 180, 180)
		game.cursor = handCursor
	else
		love.graphics.setColor(245, 245, 245)
	end

	if game.state ~= STATE_SOLUTIONS then 
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 + 182, love.graphics.getHeight() - 78, 116, 46)
	end

	if checkHover then
		love.graphics.setColor(180, 180, 180)
		game.cursor = handCursor
	else
		love.graphics.setColor(245, 245, 245)
	end


	if (game.state == STATE_FINISHED) then
		love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 98, love.graphics.getHeight() - 78, 196, 46)
	end

	love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
	love.graphics.setFont(game.resources.sansFontSmall)
	if game.state ~= STATE_SOLUTIONS then 
		love.graphics.printf("Delete", love.graphics.getWidth()/2 - 298, love.graphics.getHeight() - 67, 116, "center")
		love.graphics.printf("Clear", love.graphics.getWidth()/2 + 182, love.graphics.getHeight() - 67, 116, "center")
	end
	if (game.state == STATE_FINISHED) then
		love.graphics.printf("Check Solution", love.graphics.getWidth()/2 -98, love.graphics.getHeight() - 67, 196, "center")
	elseif (game.state == STATE_SOLUTIONS) then
		love.graphics.printf("Restart", love.graphics.getWidth()/2 -98, love.graphics.getHeight() - 67, 196, "center")
	end

	

end

local restartHover = false
local backHover = false
local bestHover = false

function game.drawRestartBackButtons()
	love.graphics.setColor(106, 137, 232)
	love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 315, love.graphics.getHeight() - 80, 190, 50)
	love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 105, love.graphics.getHeight() - 80, 190, 50)
	love.graphics.rectangle("fill", love.graphics.getWidth()/2 + 105, love.graphics.getHeight() - 80, 190, 50)

	if restartHover then
		love.graphics.setColor(180, 180, 180)
	else
		love.graphics.setColor(245, 245, 245)
	end

	love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 313, love.graphics.getHeight() - 78, 186, 46)

	if backHover then
		love.graphics.setColor(180, 180, 180)
	else
		love.graphics.setColor(245, 245, 245)
	end

	love.graphics.rectangle("fill", love.graphics.getWidth()/2 - 103, love.graphics.getHeight() - 78, 186, 46)

	if bestHover then
		love.graphics.setColor(180, 180, 180)
	else
		love.graphics.setColor(245, 245, 245)
	end

	love.graphics.rectangle("fill", love.graphics.getWidth()/2 + 107, love.graphics.getHeight() - 78, 186, 46)

	love.graphics.setFont(game.resources.sansFontSmall)
	love.graphics.setColor(106 * .8, 137 * .8, 232 * .8)

	love.graphics.printf("New game", love.graphics.getWidth()/2 - 315, love.graphics.getHeight() - 67, 190, "center")
	love.graphics.printf("Check another", love.graphics.getWidth()/2 - 105, love.graphics.getHeight() - 67, 190, "center")
	love.graphics.printf("Best solutions", love.graphics.getWidth()/2 + 105, love.graphics.getHeight() - 67, 190, "center")
end

function game.drawGameStatistics()
	local distance
	local text = ""

	if (game.calculatedSolution:mod() > game.targetNumber:mod()) then
		distance = game.calculatedSolution:sub(game.targetNumber)
	else
		distance = game.targetNumber:sub(game.calculatedSolution)
	end

	distance.real = math.abs(distance.real)
	distance.imaginary = math.abs(distance.imaginary)

	love.graphics.setFont(game.resources.sansFont)
	if (game.calculatedSolution:equals(game.targetNumber)) then
		love.graphics.setColor(125, 125, 245)

		text = "Well done! Your solution equals the target number!"
	else
		love.graphics.setColor(245, 245, 245)
		text = "Your solution is " .. distance:tostring() .. " (" .. math.floor(distance:mod()) .. ") away from the target!"
	end 

	love.graphics.printf(text, 0, love.graphics.getHeight() - 150, love.graphics.getWidth(), "center")
	love.graphics.setColor(245, 245, 245)
	love.graphics.printf("Your solution: " .. game.calculatedSolution:tostring(), 0, love.graphics.getHeight() - 190, love.graphics.getWidth(), "center")
end

local function PrintTable(tab)
	for k, v in pairs(tab) do
		if type(v) == "table" then PrintTable(v) else print(k, v) end
	end
end

function game.calculateSolution(solutionTable)
	if (#solutionTable == 0) then return 0 end

	solutionTable = table.copy(solutionTable)

	local err = false

	local openBracketCount = 0
	local closeBracketCount = 0

	for __, v in pairs(solutionTable) do
		if (v == "(") then
			openBracketCount = openBracketCount + 1
		elseif (v == ")") then
			closeBracketCount = closeBracketCount + 1
		end
	end

	local bracketDeepness = {}
	for pos, v in pairs(solutionTable) do
		if (v == "(") then
			table.insert(bracketDeepness, pos)
		end

		if (v == ")") then
			if (#bracketDeepness == 0) then
				err = "Math error: bracket order"
				print("math error - bracket order")
			else
				local startBracketPos = bracketDeepness[#bracketDeepness]
				local bracketlength = pos - startBracketPos + 1

				local bracketSolution = {}
				for i=startBracketPos + 1, pos - 1 do
					table.insert(bracketSolution, solutionTable[i])
				end

				local solution = game.calculateSolution(bracketSolution)


				local newSolutionTable = {}

				if (startBracketPos > 1) then
					for i=1, startBracketPos-1 do
						table.insert(newSolutionTable, solutionTable[i])
					end
				end

				for i=1, bracketlength-1 do
					table.insert(newSolutionTable, " ") -- fill with blanks so not to disrupt table structure
				end

				table.insert(newSolutionTable, solution)

				for i=pos+1, #solutionTable do
					table.insert(newSolutionTable, solutionTable[i])
				end

				solutionTable = newSolutionTable

				table.remove(bracketDeepness, #bracketDeepness)
			end
		end
	end

	if (openBracketCount ~= closeBracketCount) then
		print("math error - bracket count")
		err = "Math error: Bracket count"
		return false, err
	end

	local sol = Complex(0, 0)
	local lastOp = "+"

	for __, v in pairs(solutionTable) do
		if (type(v) == "string") then
			if (v ~= " ") then
				lastOp = v
			end
		else
			if (lastOp == "+" and v) then
				sol = sol:add(v)
			elseif (lastOp == "-" and v) then
				sol = sol:sub(v)
			elseif (lastOp == "x" and v) then
				sol = sol:mul(v)
			elseif (lastOp == "÷" and v) then
				if (v == 0) then
					print("math error - dividing by 0")
					err = "Math error: dividing by 0"
					sol = false
					break
				else
					sol = sol:div(v)
				end
			end
		end
	end

	if err then sol = false end

	return sol, err
end

local function appendTable(tab1, tab2)
	local tab1copy = table.copy(tab1)
	for __, v in pairs(tab2) do
		table.insert(tab1copy, v)
	end

	return tab1copy
end

function game.calculateAllSolutions(target, numbers)
	local combinations = {}
	local targetMod = target:mod()

	local function appendAllNumbers(sol, k)
		if (k == #numbers) then
			return false
		end

		for i=k+1, #numbers do
			local plus = appendTable(sol, {"+", numbers[i]})
			local take = appendTable(sol, {"-", numbers[i]})
			local times = appendTable(sol, {"x", numbers[i]})
			local divide = appendTable(sol, {"÷", numbers[i]})
			table.insert(combinations, plus)
			table.insert(combinations, take)
			table.insert(combinations, times)
			table.insert(combinations, divide)

			appendAllNumbers(plus, i)
			appendAllNumbers(take, i)
			appendAllNumbers(times, i)
			appendAllNumbers(divide, i)
		end


	end

	for k, v in pairs(numbers) do
		appendAllNumbers({v}, k)
	end

	-- add brackets now

	local function insertBrackets(comb, open, close)
		local combCopy = table.copy(comb)
		table.insert(comb, open, "(")
		table.insert(comb, close, ")")
		return combCopy
	end

	local bracketLength = 3 -- has two numbers inside

	local curCombinations = table.copy(combinations)
	for __, comb in pairs(curCombinations) do
		for bracketLength = 3, 12, 3 do

			for bOpen=1, math.floor(#comb/bracketLength) * bracketLength, bracketLength do
				table.insert(combinations, insertBrackets(comb, bOpen, bOpen + bracketLength))
			end

		end

	end

	local perfectSolution = false
	local bestConjugate = false
	local bestSolution = {}
	local bestMod = 9999999999999999

	for __, comb in pairs(combinations) do
		local sol = game.calculateSolution(comb)

		if (sol) then
			local solMod = sol:mod()

			if (sol:equals(target)) and (not perfectSolution or #sol < #perfectSolution) then
				perfectSolution = sol
			elseif math.abs(solMod - targetMod) < math.abs(bestMod - targetMod) or (math.abs(solMod - targetMod) == math.abs(bestMod - targetMod) and #sol < #bestSolution) then
				bestSolution = comb
				bestMod = solMod
			elseif (solMod == targetMod and not sol:equals(target)) then
				if (not bestConjugate or #bestConjugate > #sol) then
					bestConjugate = comb
				end
			end
		end
	end


	PrintTable(bestSolution)

	return perfectSolution, bestConjugate, best
end

function game.drawBestSolutions()
	love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setFont(game.resources.sansFont)

	if (not game.bestSolutions.mod) then
		love.graphics.setColor(245, 245, 245)
		love.graphics.print("Calculating Solutions...", 30, 30)

		love.graphics.setFont(game.resources.sansFontSmall)
		love.graphics.print("This may take upto 1 minute", 30, 90)
	else

		love.graphics.setColor(245, 245, 245)
		love.graphics.print("Best solutions: ", 30, 30)

		love.graphics.print("Perfect Solution: ", 30, 90)
		if (game.bestSolutions.perfect) then
			love.graphics.setFont(game.resources.sansFontSmall)
			love.graphics.print(game.generateSolutionText(game.bestSolutions.perfect), 30, 120)
		else
			love.graphics.setFont(game.resources.sansFontSmall)
			love.graphics.print("No perfect solution found", 30, 120)
		end

		love.graphics.setFont(game.resources.sansFont)
		love.graphics.print("Perfect Conjugate: ", 30, 180)

		if (game.bestSolutions.conjugate) then
			love.graphics.setFont(game.resources.sansFontSmall)
			love.graphics.print(game.generateSolutionText(game.bestSolutions.perfect), 30, 210)
		else
			love.graphics.setFont(game.resources.sansFontSmall)
			love.graphics.print("No perfect conjugate found", 30, 210)
		end

		love.graphics.setFont(game.resources.sansFont)
		love.graphics.print("Closest Solution: ", 30, 270)

		local answer = game.calculateSolution(game.bestSolutions.mod)
		love.graphics.setFont(game.resources.sansFontSmall)
		love.graphics.print(game.generateSolutionText(game.bestSolutions.mod) .. " = " .. answer:tostring() , 30, 300)
		love.graphics.print("Modulus difference: " .. math.abs(answer:mod() - game.targetNumber:mod()) , 60, 320)
	end
end



function game.play()
	game.state = STATE_PLAYING
	game.timeStart = love.timer.getTime()
	game.startTimer()
end

function love.load()
	-- need a seed to randomly generate numbers
	math.randomseed(os.time())
	-- and the random number generator is a bit sketchy for the first couple of values, so we'll disgard them
	math.random()
	math.random()
	math.random()

	game.resources.timerSound = love.audio.newSource("resources/clock.wav", "static")
	game.resources.sansFont = love.graphics.newFont("resources/KeepCalm-Medium.ttf", 26)
	game.resources.sansFontSmall = love.graphics.newFont("resources/KeepCalm-Medium.ttf", 18)
	game.resources.lcdFont = love.graphics.newFont("resources/Calculator.ttf", 48)

	game.init()
end

function love.update(dt)
	game.cursor = love.mouse.getSystemCursor("arrow")

	deleteHover = false
	clearHover = false
	checkHover = false
	backHover = false
	restartHover = false

	if (game.state >= STATE_SELECT) then
		for i, card in pairs(game.playingCards[1]) do
			card:update(dt)
		end

		for i, card in pairs(game.playingCards[2]) do
			card:update(dt)
		end
	end

	if (game.state == STATE_PLAYING or game.state == STATE_FINISHED) then
		for __, operator in pairs(game.operators) do
			operator:update(dt)
		end

		if (love.timer.getTime() - game.timeStart >= 30) then
			game.state = STATE_FINISHED
		end
	end

	local x, y = love.mouse.getPosition()

	if (game.state == STATE_PLAYING or game.state == STATE_FINISHED) then
		if (x > love.graphics.getWidth()/2 - 300 and x < love.graphics.getWidth()/2 - 300 + 120) and (y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 30) then
			game.cursor = handCursor
			deleteHover = true
		else
			deleteHover = false
		end

		if (x > love.graphics.getWidth()/2 + 180 and x < love.graphics.getWidth()/2 + 300) and (y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 30) then
			clearHover = true
			game.cursor = handCursor
		else
			clearHover = false
		end
	end

	if (game.state == STATE_FINISHED) then

		if (x > love.graphics.getWidth()/2 -100 and x < love.graphics.getWidth()/2 + 100) and (y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 30) then
			checkHover = true
			game.cursor = handCursor
		else
			checkHover = false
		end

	end

	if (game.state == STATE_SOLUTIONS) then
		if (x > love.graphics.getWidth()/2 - 315 and x < love.graphics.getWidth()/2 - 125) and (y > love.graphics.getHeight() - 80 and y < love.graphics.getHeight() - 30) then
			restartHover = true
			game.cursor = handCursor
		else
			restartHover = false
		end

		if (x > love.graphics.getWidth()/2 - 105 and x < love.graphics.getWidth()/2 + 85) and (y > love.graphics.getHeight() - 80 and y < love.graphics.getHeight() - 30) then
			backHover = true
			game.cursor = handCursor
		else
			backHover = false
		end

		if (x > love.graphics.getWidth()/2 + 105 and x < love.graphics.getWidth()/2 + 295) and (y > love.graphics.getHeight() - 80 and y < love.graphics.getHeight() - 30) then
			bestHover = true
			game.cursor = handCursor
		else
			bestHover = false
		end
	end


	love.mouse.setCursor(game.cursor)
end

function love.mousereleased(x, y, button)
	if game.state == STATE_SELECT or game.state == STATE_PLAYING or game.state == STATE_FINISHED then
		local done = false
		for i, card in pairs(game.playingCards[1]) do
			if card.hovered then
				card:select()
				done = true
				break
			end
		end

		if done then return end

		for i, card in pairs(game.playingCards[2]) do
			if card.hovered then
				card:select()
				break
			end
		end
	end

	if (game.state == STATE_PLAYING or game.state == STATE_FINISHED) then
		for __, operator in pairs(game.operators) do
			if (operator.hovered) then
				operator:select()
				break
			end
		end

		if (x > love.graphics.getWidth()/2 - 300 and x < love.graphics.getWidth()/2 - 300 + 120) and (y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 30) then
			if (type(game.solution[#game.solution]) == "table" or game.solution[#game.solution] == "(" or game.solution[#game.solution] == ")") then
				if (type(game.solution[#game.solution]) == "table") then
					for __, card in pairs(game.selectedCards) do
						if (card.value:equals(game.solution[#game.solution])) then
							card.used = false
						end
					end
				end

				game.placeNumber = true
			else
				game.placeNumber = false
			end
			table.remove(game.solution, #game.solution)
		end

		if (x > love.graphics.getWidth()/2 + 180 and x < love.graphics.getWidth()/2 + 300) and (y > love.graphics.getHeight() - 100 and y < love.graphics.getHeight() - 30) then
			for __, card in pairs(game.selectedCards) do
				card.used = false
			end
			game.solution = {}
			game.placeNumber = true
		else
			clearHover = false
		end

	end

	if (game.state == STATE_FINISHED and checkHover) then
	
		game.state = STATE_SOLUTIONS
		backHover = false
		game.calculatedSolution = game.calculateSolution(game.solution)
	end

	if (game.state == STATE_SOLUTIONS) then
		if (backHover) then
			game.state = STATE_FINISHED
		elseif (restartHover) then
			game.init()
		elseif (bestHover) then
			game.state = STATE_BESTSOLUTION
			local selectedNumbers = {}

			for __, v in pairs(game.selectedCards) do
				table.insert(selectedNumbers, v.value)
			end

			local perfectSolution, bestConjugate, best = game.calculateAllSolutions(game.targetNumber, selectedNumbers)
			game.bestSolutions = {
				perfect = perfectSolution,
				conjugate = bestConjugate,
				mod = best
			}
		end
	end

	if game.state == STATE_PREPLAY and love.timer.getTime() - game.stateChange > 2 then
		local width = math.min(love.graphics.getWidth() - 20, 300)
		if (x > love.graphics.getWidth() /2 - width/2 and x < love.graphics.getWidth() /2 + width/2)
			and (y > love.graphics.getHeight() - 175 and y < love.graphics.getHeight() - 75) then
			game.play()
		end
	end
end

function love.draw()

	if (game.state ~= STATE_BESTSOLUTION) then
		game.drawBackground()
		game.drawClock(love.graphics.getWidth() / 2, love.graphics.getHeight() * 0.05 + (love.graphics.getHeight() / 8), love.graphics.getHeight() / 8)

		if (game.state == STATE_SELECT) then
			game.drawCardSelect()
		elseif (game.state == STATE_PREPLAY or game.state == STATE_PLAYING or game.state == STATE_FINISHED or game.state == STATE_SOLUTIONS) then
			game.drawActiveCards()
			game.drawTargetNumber((love.graphics.getHeight() * 0.05 + (love.graphics.getHeight() / 8) + love.graphics.getHeight() / 8) + (game.selectedCards[1].pos.y - (love.graphics.getHeight() * 0.05 + (love.graphics.getHeight() / 8) + love.graphics.getHeight() / 8))/2)
		end

		if (game.state == STATE_PREPLAY and love.timer.getTime() - game.stateChange > 2) then
			game.drawPlayButton()
			game.drawOperatorButtons()
		end

		if (game.state == STATE_PLAYING or game.state == STATE_FINISHED) then
			game.drawOperatorButtons()
			game.drawSolution()
			game.drawSolutionActions()
		end

		if (game.state == STATE_SOLUTIONS) then
			game.drawRestartBackButtons()
			game.drawGameStatistics()
		end

	else
		game.drawBestSolutions()
	end
end

