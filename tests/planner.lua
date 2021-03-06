local TestEZ = script.Parent.Parent.TestEZ
local TestPlanner = require(TestEZ.TestPlanner)
local TestBootstrap = require(TestEZ.TestBootstrap)
local TestEnum = require(TestEZ.TestEnum)

local testRoot = script.Parent.planning

local function verifyPlan(plan, expected, notSkip)
	local nodes = plan:findNodes(function(node)
		return (not notSkip) or (node.modifier ~= TestEnum.NodeModifier.Skip)
	end)

	local nodeNames = {}
	for _, node in pairs(nodes) do
		table.insert(nodeNames, node:getFullName())
	end

	local pass = true
	local message = ""

	for _, exp in ipairs(expected) do
		local ok = false
		for _, got in ipairs(nodeNames) do
			if exp == got then
				ok = true
				break
			end
		end
		if not ok then
			pass = false
			message = message .. string.format("expected name '%s' not found, ", exp)
		end
	end

	for _, got in ipairs(nodeNames) do
		local ok = false
		for _, exp in ipairs(expected) do
			if exp == got then
				ok = true
				break
			end
		end
		if not ok then
			pass = false
			message = message .. string.format("additional name '%s' found, ", got)
		end
	end

	return pass, message
end

return {
	["it should build the full plan with no arguments"] = function()
		local modules = TestBootstrap:getModules(testRoot)
		local plan = TestPlanner.createPlan(modules)
		assert(verifyPlan(plan, {
			"planning",
			"planning a",
			"planning a test1",
			"planning a test2",
			"planning b",
			"planning b test1",
			"planning b test2",
			"planning b test2 test3",
		}))
	end,
	["it should mark skipped tests as skipped"] = function()
		local modules = TestBootstrap:getModules(testRoot)
		local plan = TestPlanner.createPlan(modules)
		assert(verifyPlan(plan, {
			"planning",
			"planning a",
			"planning a test2",
			"planning b",
			"planning b test1",
			"planning b test2 test3", -- This isn't marked skip, its parent is
		}, true))
	end,
	["it should skip tests that don't match the filter"] = function()
		local modules = TestBootstrap:getModules(testRoot)
		local plan = TestPlanner.createPlan(modules, false, "test2")
		assert(verifyPlan(plan, {
			"planning a test2",
			"planning b test2 test3", -- Gets focus because only its parent is skip
		}, true))
	end,
}