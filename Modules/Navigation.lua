local Navigation = {}
Navigation.__index = Navigation

local Utility = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/synnyyy/Leny-UI/refs/heads/main/Modules/Utility.lua", true))()
local Popup = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Popup.lua", true))()

function Navigation.new(context: table)
	local self = setmetatable(context, Navigation)
	Utility:validateKeys(self, {"ScrollingFrame", "Pages", "Page", "tweenTabOn", "tweenTabsOff", "animation", "hoverOn", "hoverOff", "Popups"})
	return self
end

function Navigation:enableFirstTab()
	self.tweenTabOn()
	self.Page.Visible = true
end

function Navigation:selectTab()
	local isSwitching = false

	local function showPage()
		for _, page in ipairs(self.Pages:GetChildren()) do
			if string.match(page.Name, "Page") and page.Visible then
				page.Visible = false
			end
		end

		self.Page.Visible = true
		if self.animation then
			self.animation()
		end
	end

	local function tweenTabs()
		-- Reduce loop calls by checking the active tab only
		for _, tab in ipairs(self.ScrollingFrame:GetChildren()) do
			if string.match(tab.Name, "Tab") then
				self.tweenTabsOff(tab)
			end
		end

		self.tweenTabOn()
	end

	return function()
		if isSwitching or self.Page.Visible then
			return
		end

		isSwitching = true
		Popup:hidePopups(false, self.Popups)

		showPage()
		tweenTabs()

		task.defer(function() isSwitching = false end)
	end
end

function Navigation:hoverEffect(isHovering)
	return function()
		if self.Page.Visible then
			return
		end

		if isHovering then
			if self.hoverOn then
				self.hoverOn()
			end
		else
			if self.hoverOff then
				self.hoverOff()
			end
		end
	end
end


return Navigation
