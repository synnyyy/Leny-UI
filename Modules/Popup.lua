local Popup = {}
Popup.__index = Popup

local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Utility.lua", true))()

function Popup.new(context: table)
	local self = setmetatable(context, Popup)

	-- Auto size popup
	self.ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self.Popup.Size = UDim2.fromOffset((self.ScrollingFrame.AbsoluteSize.X - 7) * 0.5, self.Popup.Inner.UIListLayout.AbsoluteContentSize.Y + self.SizePadding)
	end)

	self.Popup.Inner.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		self.Popup.Size = UDim2.fromOffset((self.ScrollingFrame.AbsoluteSize.X - 7) * 0.5, self.Popup.Inner.UIListLayout.AbsoluteContentSize.Y + self.SizePadding)
	end)

	-- Hide popup if it goes above the absolutewindowsize of scrollingframe when scrolling
	self.Popup:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		local relativePosY = (self.Popup.AbsolutePosition.Y - self.ScrollingFrame.AbsolutePosition.Y) / self.ScrollingFrame.AbsoluteWindowSize.Y

		if relativePosY <= 0 then
			self:showPopup(false, 1, 0.2)
		end
	end)

	-- Auto position popup under target
	self.Target:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		--Utility:tween(self.Popup, {Position = UDim2.fromOffset(self.Target.AbsolutePosition.X, self.Target.AbsolutePosition.Y + self.PositionPadding)}):Play()
		self.Popup.Position = UDim2.fromOffset(self.Target.AbsolutePosition.X, self.Target.AbsolutePosition.Y + self.PositionPadding)
	end)

	return self
end

function Popup:togglePopup()
	return function()
		if self.Popup.BackgroundTransparency >= 0.9 then
			self:hidePopups(true)
			self:showPopup(true, 0, 0)
		else
			self:showPopup(false, 1, 0.2)		
		end
	end
end

function Popup:updateTransparentObjects(newTransparentObjects)
	self.TransparentObjects = Utility:getTransparentObjects(newTransparentObjects)
end

function Popup:hidePopups(objectCheck: boolean, popups)
	popups = self.Popups or popups

	for _, data in ipairs(Utility:getTransparentObjects(popups)) do
		if (not objectCheck) or (objectCheck and data ~= self.Popup) then
			Utility:tween(data.object, {[data.property] = 1}, 0.2):Play()
		end
	end
	
	for _, popup in ipairs(popups:GetChildren()) do
		if (not objectCheck) or (objectCheck and popup ~= self.Popup) then
			task.delay(0.2, function()
				popup.Visible = false
			end)
		end
	end
end

function Popup:showPopup(boolean, transparency: number, delayTime: number)
	for _, data in ipairs(self.TransparentObjects) do
		Utility:tween(data.object, {[data.property] = transparency}, 0.2):Play()
	end
	
	if self.Inner then
		Utility:tween(self.Inner, {BackgroundTransparency = transparency}, 0.2):Play() -- dumb fix but hey man!
	end

	Utility:tween(self.Popup, {BackgroundTransparency = transparency}, 0.2):Play()

	task.delay(delayTime, function()
		self.Popup.Visible = boolean
	end)
end

return Popup
