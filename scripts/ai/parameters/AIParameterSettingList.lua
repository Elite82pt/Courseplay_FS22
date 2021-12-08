--- Selection list with values and texts.
---@class AIParameterSettingList : AIParameter
AIParameterSettingList = {}
local AIParameterSettingList_mt = Class(AIParameterSettingList, AIParameter)

function AIParameterSettingList.new(data,customMt)
	local self = AIParameter.new(customMt or AIParameterSettingList_mt)
	self.type = AIParameterType.SELECTOR
	self.name = data.name
	if next(data.values) ~=nil then 
		self.values = data.values
		self.texts = data.texts
	else 
		self.values = {}
		self.texts = {}
		AIParameterSettingList.generateValues(self.values,self.texts,data.min,data.max,data.incremental)
	end
	self.title = data.title 
	self.tooltip = data.tooltip

	-- index of the current value/text
	self.current = 1
	-- index of the previous value/text
	self.previous = 1

	self.data = data

	self.guiElementId = data.uniqueID

	self.guiElement = nil

	return self
end

--- Generates numeric values and texts from min to max with incremental of inc or 1.
function AIParameterSettingList.generateValues(values,texts,min,max,inc)
	inc = inc or 1
	for i=min,max,inc do 
		table.insert(values,i)
		table.insert(texts,tostring(i))
	end
end

-- Is the current value same as the param?
function AIParameterSettingList:is(value)
	return self.values[self.current] == value
end

-- Get the current text key (for the logs, for example)
function AIParameterSettingList:__tostring()
	return self.texts[self.current]
end

-- private function to set to the value at ix
function AIParameterSettingList:setToIx(ix)
	if ix ~= self.current then
		self.previous = self.current
		self.current = ix
		self:onChange()
		self:updateGuiElementValues()
	end
end

function AIParameterSettingList:checkAndSetValidValue(new)
	if new > #self.values then
		return 1
	elseif new < 1 then
		return #self.values
	else
		return new
	end
end

function AIParameterSettingList:onChange()
	-- setting specific implementation in the derived classes
end

function AIParameterSettingList:validateCurrentValue()
	local new = self:checkAndSetValidValue(self.current)
	self:setToIx(new)
end

function AIParameterSettingList:getDebugString()
	-- replace % as this string goes through multiple formats (%% does not seem to work and I have no time to figure it out
	return string.format('%s: %s', self.name, string.gsub(self.texts[self.current], '%%', 'percent'))
end
function AIParameterSettingList:saveToXMLFile(xmlFile, key, usedModNames)
--	CpUtil.debugFormat(CP.D"")
	xmlFile:setInt(key .. "#value", self.current)
end

function AIParameterSettingList:loadFromXMLFile(xmlFile, key)
	self:setToIx(xmlFile:getInt(key .. "#value", self.current))
end

function AIParameterSettingList:readStream(streamId, connection)
	self:setToIx(streamReadInt32(streamId))
end

function AIParameterSettingList:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.current)
end

local function setValueInternal(self, value, comparisonFunc)
	local new
	-- find the value requested
	for i = 1, #self.values do
		if comparisonFunc(self.values[i], value) then
			new = self:checkAndSetValidValue(i)
			self:setToIx(new)
			return
		end
	end
end

function AIParameterSettingList:setFloatValue(value)
	setValueInternal(self, value, function(a, b)  return MathUtil.equalEpsilon(a, b, 0.01) end)
end

--- Set to a specific value.
function AIParameterSettingList:setValue(value)
	setValueInternal(self, value, function(a, b)  return a == b end)
end

--- Gets a specific value.
function AIParameterSettingList:getValue()
	return self.values[self.current]
end

function AIParameterSettingList:getString()
	return self.texts[self.current]
end

--- Set the next value
function AIParameterSettingList:setNextItem()
	local new = self:checkAndSetValidValue(self.current + 1)
	self:setToIx(new)
end

--- Set the previous value
function AIParameterSettingList:setPreviousItem()
	local new = self:checkAndSetValidValue(self.current - 1)
	self:setToIx(new)
end

function AIParameterSettingList:clone()
	local aiParameter = AIParameterSettingList.new(self.data)
	aiParameter:setToIx(self.current)
	return aiParameter
end

function AIParameterSettingList:getTitle()
	return self.title	
end

function AIParameterSettingList:getTooltip()
	return self.tooltip	
end

function AIParameterSettingList:setGenericGuiElementValues(guiElement)
	guiElement.leftButtonElement:setCallback("onClickCallback", "setPreviousItem")
	guiElement.rightButtonElement:setCallback("onClickCallback", "setNextItem")
	guiElement:setLabel(self:getTitle())
	local toolTipElement = guiElement.elements[6]
	toolTipElement:setText(self:getTooltip())
end

function AIParameterSettingList:getGuiElementTexts()
	return self.texts
end

function AIParameterSettingList:getGuiElementStateFromValue(value)
	for i = 1, #self.values do
		if self.values[i] == value then
			return i
		end
	end
	return nil
end

function AIParameterSettingList:getGuiElementState()
	return self:getGuiElementStateFromValue(self.values[self.current])
end

function AIParameterSettingList:updateGuiElementValues()
	if self.guiElement == nil then return end
	self.guiElement:setState(self:getGuiElementState())
end

function AIParameterSettingList:setGuiElement(guiElement)
	self.guiElement = guiElement
	self.guiElement.leftButtonElement.target = self
	self.guiElement.rightButtonElement.target = self
	self.guiElement.leftButtonElement.onClickCallback = self.setPreviousItem
	self.guiElement.rightButtonElement.onClickCallback = self.setNextItem
	self:updateGuiElementValues()
	self.guiElement:setTexts(self:getGuiElementTexts())
end

function AIParameterSettingList:resetGuiElement()
	self.guiElement = nil
end

function AIParameterSettingList:getName()
	return self.name	
end