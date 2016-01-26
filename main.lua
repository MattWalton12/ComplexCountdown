require("complex")
require("vec2")

local STATE_NONE = -1
local STATE_SELECT = 0
local STATE_PREPLAY = 1
local STATE_PLAYING = 2
local STATE_FINISHED = 3

game = {}
game.selectedCards = {}
game.randomNumber = {}
game.solution = {}
game.playingCards = {}
game.state = STATE_NONE
game.timeStart = 0
game.timerSound = {}
game.cursor = love.mouse.getSystemCursor("arrow")
game.font = 0

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

local GameCard = {}
GameCard.value = 0
GameCard.hovered = false
GameCard.pos = {}
GameCard.size = {}
GameCard.selected = false
GameCard.__index = GameCard

function GameCard:select()
	if (#game.selectedCards < 6) then
		
		self.selected = true
		self.size[1] = (love.graphics.getWidth() - love.graphics.getWidth()/2.3 - 60) / 6
		self.size[2] = self.size[1] * 1.4
		self.pos.x = love.graphics.getWidth()/4.6 + (self.size[1] + 10) * #game.selectedCards
		self.pos.y = love.graphics.getHeight() - 250 - self.size[2] - 20

		table.insert(game.selectedCards, self)

		if #game.selectedCards == 6 then
			game.state = STATE_PREPLAY
		end
	end
end

function GameCard:draw()

	if (self.selected) then
		love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
		love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size[1], self.size[2])
		love.graphics.setColor(106, 137, 232)
		love.graphics.rectangle("fill", self.pos.x + 3, self.pos.y + 3, self.size[1] - 6, self.size[2] - 6)

		love.graphics.setColor(255, 255, 255)
		love.graphics.setFont(game.font)
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
end


local function CreateGameCard(value)
	local object = {
		value = value
	}

	return setmetatable(object, GameCard)
end

function game.init()
	game.playingCards = {{}, {}}

	for i=1, 4 do
		game.playingCards[1][i] = CreateGameCard(game.cardNumbers[1][math.random(1, #game.cardNumbers[1])])
	end

	for i=1, 20 do
		game.playingCards[2][i] = CreateGameCard(game.cardNumbers[2][math.random(1, #game.cardNumbers[2])])
	end

	game.calculateCardPositions()

	game.state = STATE_SELECT
	game.selectedCards = {}
	
end

function game.startTimer()
	game.timeStart = love.timer.getTime()
	love.audio.play(game.timerSound)
end

function game.drawBackground()
	love.graphics.setColor(220, 220, 220)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColor(106 * 0.8, 137 * 0.8, 232 * 0.8)
	love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 250, love.graphics.getWidth(), 250)
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

function love.load()
	-- need a seed to randomly generate numbers
	math.randomseed(os.time())
	-- and the random number generator is a bit sketchy for the first couple of values, so we'll disgard them
	math.random()
	math.random()
	math.random()


	local mycom = Complex(3, 2)
	print(mycom:tostring())
	print(mycom:square():tostring())

	game.timerSound = love.audio.newSource("resources/clock.wav", "static")
	game.font = love.graphics.newFont("resources/KeepCalm-Medium.ttf", 32)

	game.init()
end

function love.update(dt)
	game.cursor = love.mouse.getSystemCursor("arrow")

	if (game.state == STATE_SELECT) then
		for i, card in pairs(game.playingCards[1]) do
			card:update(dt)
		end

		for i, card in pairs(game.playingCards[2]) do
			card:update(dt)
		end
	end

	love.mouse.setCursor(game.cursor)
end

function love.mousereleased(x, y, button)
	if game.state == STATE_SELECT then
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
end

function love.draw()
	game.drawBackground()
	game.drawClock(love.graphics.getWidth() / 2, love.graphics.getHeight() * 0.05 + (love.graphics.getHeight() / 8), love.graphics.getHeight() / 8)

	if (game.state == STATE_SELECT) then
		game.drawCardSelect()
	elseif (game.state == STATE_PREPLAY or game.state == STATE_PLAYING) then
		game.drawActiveCards()
	end
end

