
function table.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[table.copy(k, s)] = table.copy(v, s) end
  return res
end

local function appendTable(tab1, tab2)
	local tab1copy = table.copy(tab1)
	for __, v in pairs(tab2) do
		table.insert(tab1copy, v)
	end

	return tab1copy
end



function calculateAllSolutions()
	local target = Complex(100, 100)
	local targetMod = target:mod()
	local numbers = {Complex(10, 0), Complex(0, 10), Complex(6, 0), Complex(0, 2), Complex(50, 0), Complex(1, 0)}
	
	local combinations = {}

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

	return perfectSolution, bestConjugate, bestSolution
end
