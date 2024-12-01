local RunService = game:GetService("RunService")
local ScreenGui = game:GetObjects("rbxassetid://99852798675591")[1]

if RunService:IsStudio() then
	ScreenGui.Parent = game.StarterGui
else
	ScreenGui.Parent = game.CoreGui
end

local Library = {
	firstTabDebounce = false,
	firstSubTabDebounce = false,
	processedEvent = false,
	lineIndex = 0,
	Connections = {},
	Exclusions = {},
	Theme = {},
	DropdownSizes = {}, -- to store previous opened dropdown size to resize scrollingFrame canvassize
}
Library.__index = Library

local Connections = Library.Connections
local Exclusions = Library.Exclusions

local Assets = ScreenGui.Assets
local Modules = {
	Dropdown = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Dropdown.lua", true))(),
	Toggle = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Toggle.lua", true))(),
	Popup = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Popup.lua", true))(),
	Slider = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Slider.lua", true))(),
	Keybind = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Keybind.lua", true))(),
	TextBox = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/TextBox.lua", true))(),
	Navigation = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Navigation.lua", true))(),
	ColorPicker = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/ColorPicker.lua", true))(),
}

local Utility = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Utility.lua", true))()
local Theme = loadstring(game:HttpGet("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Modules/Theme.lua", true))()
Library.Theme = Theme

local Popups = ScreenGui.Popups
local Glow = ScreenGui.Glow
local Background = Glow.Background

local Tabs = Background.Tabs
local Filler = Tabs.Filler
local Line = Filler.Line
local Title = Tabs.Frame.Title

Theme:registerToObjects({
	{object = Glow, property = "ImageColor3", theme = {"PrimaryBackgroundColor"}},
	{object = Background, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
	{object = Line , property = "BackgroundColor3", theme = {"Line"}},
	{object = Tabs , property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
	{object = Filler , property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
	{object = Title , property = "TextColor3", theme = {"PrimaryTextColor"}},
	{object = Assets.Pages.Fade, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
})

function Library:createAddons(text, imageButton, scrollingFrame, additionalAddons)	
	local Addon = Assets.Elements.Addons:Clone()
	Addon.Size = UDim2.fromOffset(scrollingFrame.AbsoluteSize.X * 0.5, Addon.Inner.UIListLayout.AbsoluteContentSize.Y)
	Addon.Parent = Popups
	
	local Inner = Addon.Inner
	
	local TextLabel = Inner.TextLabel
	TextLabel.Text = text .. " Addons"

	local PopupContext = Utility:validateContext({
		Popup = {Value = Addon, ExpectedType = "Instance"},
		Target = {Value = imageButton, ExpectedType = "Instance"},
		TransparentObjects = {Value = Utility:getTransparentObjects(Addon), ExpectedType = "table"},
		ScrollingFrame = {Value = scrollingFrame, ExpectedType = "Instance"},
		Popups = {Value = Popups, ExpectedType = "Instance"},
		Inner = {Value = Inner, ExpectedType = "Instance"},
		PositionPadding = {Value = 18 + 7, ExpectedType = "number"},
		SizePadding = {Value = 30, ExpectedType = "number"},
	})
	
	Theme:registerToObjects({
		{object = Addon, property = "BackgroundColor3", theme = {"Line"}},
		{object = Inner, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = TextLabel, property = "TextColor3", theme = {"PrimaryTextColor"}},
	})
	
    local Popup = Modules.Popup.new(PopupContext)
	imageButton.MouseButton1Down:Connect(Popup:togglePopup())

	local DefaultAddons = {
		createToggle = function(self, options)
			Library:createToggle(options, Addon.Inner, scrollingFrame)
		end,

		createSlider = function(self, options)
			Library:createSlider(options, Addon.Inner, scrollingFrame)
		end,

		createDropdown = function(self, options)
			options.default = {} -- need to do this for some reason since I clearly implied that default was as table value but guess not?
			Library:createDropdown(options, Addon.Inner, scrollingFrame)
		end,
	}

	for key, value in pairs(additionalAddons or  {}) do
		DefaultAddons[key] = value
	end

	return setmetatable({},  {
		__index = function(table, key)
			local originalFunction = DefaultAddons[key]

			if type(originalFunction) == "function" then
				return function(...)
					-- Show imageButton if the index name is "create"
					if string.match(key, "create") and not string.match(key, "createPicker") then
						imageButton.Visible = true
					end

					-- updateTransparentObjects again to account for the new creation of element after the call.
					return originalFunction(...), Popup:updateTransparentObjects(Addon)
				end
			else
				return originalFunction
			end
		end,

		__newindex = function(table, key, value)
			DefaultAddons[key] = value
		end
	})
end

function Library:destroy()
	for _, rbxSignals in ipairs(Connections) do
		rbxSignals:disconnect()
	end
	task.wait(0.1)
	ScreenGui:Destroy()
end

function Library:createLabel(options: table)
	Utility:validateOptions(options, {
		text = {Default = "Main", ExpectedType = "string"},
	})

	options.text = string.upper(options.text)

	local ScrollingFrame = Background.Tabs.Frame.ScrollingFrame

	local Line = Assets.Tabs.Line:Clone()
	Line.Visible = true
	Line.BackgroundColor3 = Theme.Line
	Line.Parent = ScrollingFrame

	local TextLabel = Assets.Tabs.TextLabel:Clone()
	TextLabel.Visible = true
	TextLabel.Text = options.text
	TextLabel.Parent = ScrollingFrame

	for _, line in ipairs(ScrollingFrame:GetChildren()) do
		if line.Name ~= "Line" then
			continue
		end

		self.lineIndex += 1

		if self.lineIndex == 1 then
			line:Destroy()
		end
	end
	
	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Line, property = "BackgroundColor3", theme = {"Line"}},
	})
end

function Library:createTab(options: table)
	Utility:validateOptions(options, {
		text = {Default = "Tab", ExpectedType = "string"},
		icon = {Default = "124718082122263", ExpectedType = "string"},
	})

	local ScrollingFrame = Background.Tabs.Frame.ScrollingFrame

	local Tab = Assets.Tabs.Tab:Clone()
	Tab.Visible = true
	Tab.Parent = ScrollingFrame

	local ImageButton = Tab.ImageButton

	local Icon = ImageButton.Icon
	Icon.Image = "rbxassetid://" .. options.icon

	local TextButton = ImageButton.TextButton
	TextButton.Text = options.text

	local Page = Assets.Pages.Page:Clone()
	Page.Parent = Background.Pages
	
	local Frame = Page.Frame
	local PageLine = Frame.Line

	local CurrentTabLabel = Frame.CurrentTabLabel
	CurrentTabLabel.Text = options.text
	CurrentTabLabel.TextColor3 = Theme.PrimaryTextColor

	local SubTabs = Page.SubTabs
	local SubLine = SubTabs.Line

	local function tweenTabAssets(tab: Instance, icon: Instance, textButton: Instance, color: textColor3, backgroundColor3: Color3, backgroundTransparency: number, textTransparency: number, imageTransparency: number)
		Utility:tween(tab, {BackgroundColor3 = backgroundColor3, BackgroundTransparency = backgroundTransparency}, 0.5):Play()
		Utility:tween(icon, {ImageTransparency = imageTransparency, ImageColor3 = color}, 0.5):Play()
		Utility:tween(textButton, {TextColor3 = color, TextTransparency = textTransparency}, 0.5):Play()
	end	

	local function fadeAnimation()
		local function tweenFadeAndPage(fade: Instance, backgroundTransparency: number, textTransparency: number, paddingY: number)
			Utility:tween(fade, {BackgroundTransparency = backgroundTransparency}, 0.2):Play()
			Utility:tween(CurrentTabLabel.UIPadding, {PaddingBottom = UDim.new(0, paddingY)}, 0.2):Play()
		end

		for _, subPage in ipairs(Page:GetChildren()) do
			if subPage.Name == "SubPage" and subPage.Visible and subPage:FindFirstChild("ScrollingFrame") then
				Utility:tween(subPage.ScrollingFrame.UIPadding, {PaddingTop = UDim.new(0, 10)}, 0.2):Play()

				task.delay(0.2, function()
					Utility:tween(subPage.ScrollingFrame.UIPadding, {PaddingTop = UDim.new(0, 0)}, 0.2):Play()
				end)
			end
		end

		local Fade = Assets.Pages.Fade:Clone()
		Fade.BackgroundTransparency = 1
		Fade.Visible = true
		Fade.Parent = Background.Pages

		tweenFadeAndPage(Fade, 0, 1, 14)

		task.delay(0.2, function()
			tweenFadeAndPage(Fade, 1, 0, 0)
			task.wait(0.2)
			Fade:Destroy()
		end)
	end
		
	local Context = Utility:validateContext({
		Page = {Value = Page, ExpectedType = "Instance"},
		Pages = {Value = Background.Pages, ExpectedType = "Instance"},
		Popups = {Value = Popups, ExpectedType = "Instance"},
		ScrollingFrame = {Value = Background.Tabs.Frame.ScrollingFrame, ExpectedType = "Instance"},
		animation = {Value = fadeAnimation, ExpectedType = "function"},

		tweenTabOn = {Value = function()
			tweenTabAssets(Tab, Icon, TextButton, Theme.PrimaryColor, Theme.TabBackgroundColor, 0, 0, 0)
		end, ExpectedType = "function"},

		tweenTabsOff = {Value = function(tab)
			tweenTabAssets(tab, tab.ImageButton.Icon, tab.ImageButton.TextButton, Theme.SecondaryTextColor, Theme.TabBackgroundColor, 1, 0, 0)
		end, ExpectedType = "function"},

		hoverOn = {Value = function()
			tweenTabAssets(Tab, Icon, TextButton, Theme.PrimaryColor, Theme.TabBackgroundColor, 0.16, 0.3, 0.3)
		end, ExpectedType = "function"},

		hoverOff = {Value = function()
			tweenTabAssets(Tab, Icon, TextButton, Theme.SecondaryTextColor, Theme.TabBackgroundColor, 1, 0, 0)
		end, ExpectedType = "function"},
	})

	local Navigation = Modules.Navigation.new(Context)

	-- this is stupid but anyways!!!
	if not self.firstTabDebounce then
		Navigation:enableFirstTab()
		self.firstTabDebounce = true
	end

	ScrollingFrame.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, ScrollingFrame.UIListLayout.AbsoluteContentSize.Y + ScrollingFrame.UIListLayout.Padding.Offset)
	end)

	ImageButton.MouseButton1Down:Connect(Navigation:selectTab())
	Icon.MouseButton1Down:Connect(Navigation:selectTab())
	TextButton.MouseButton1Down:Connect(Navigation:selectTab())
	ImageButton.MouseEnter:Connect(Navigation:hoverEffect(true))
	ImageButton.MouseLeave:Connect(Navigation:hoverEffect(false))
	
	Theme:registerToObjects({
		{object = Tab, property = "BackgroundColor3", theme = {"TabBackgroundColor"}},
		{object = Icon, property = "ImageColor3", theme = {"SecondaryTextColor", "PrimaryColor"}},
		{object = TextButton, property = "TextColor3", theme = {"SecondaryTextColor", "PrimaryColor"}},
		{object = Frame, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = SubTabs, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = PageLine, property = "BackgroundColor3", theme = {"Line"}},
		{object = SubLine, property = "BackgroundColor3", theme = {"Line"}},
		{object = CurrentTabLabel, property = "TextColor3", theme = {"PrimaryTextColor"}},
	}, "Tab")

	local PassingContext = setmetatable({Page = Page}, Library)
	return PassingContext
end

function Library:createSubTab(options: table)
	-- Use provided options, or fall back to defaults if not provided	
	Utility:validateOptions(options, {
		text = {Default = "SubTab", ExpectedType = "string"},
	})

	local Moveable = self.Page.SubTabs.Frame.Moveable
	local Underline, ScrollingFrame = Moveable.Underline, Moveable.Parent.ScrollingFrame

	local SubPage = Assets.Pages.SubPage:Clone()
	SubPage.Parent = self.Page

	local Left, Right = SubPage.ScrollingFrame.Left, SubPage.ScrollingFrame.Right

	local SubTab = Assets.Pages.SubTab:Clone()
	SubTab.Visible = true
	SubTab.Text = options.text
	SubTab.TextColor3 = Theme.SecondaryTextColor
	SubTab.Parent = ScrollingFrame

	local TextService = game:GetService("TextService")
	SubTab.Size = UDim2.new(0, TextService:GetTextSize(options.text, 15, Enum.Font.MontserratMedium, SubTab.AbsoluteSize).X, 1, 0)

	-- Calculate subTab position to position underline
	local subTabIndex, subTabPosition = 0, 0

	for index, subTab in ipairs(ScrollingFrame:GetChildren()) do
		if subTab.Name ~= "SubTab" then
			continue
		end

		subTabIndex += 1

		if subTabIndex == 1 then
			subTabPosition = 0
		else				
			local condition, object = Utility:lookBeforeChildOfObject(index, ScrollingFrame, "SubTab")
			subTabPosition += subTab.Size.X.Offset + ScrollingFrame.UIListLayout.Padding.Offset

			if condition then
				subTabPosition -= (subTab.Size.X.Offset - object.Size.X.Offset)
			end		
		end
	end

	local function tweenSubTabAssets(subTab, underline, textColor, textTransparency: number, disableUnderlineTween: boolean)
		Utility:tween(subTab, {TextColor3 = textColor, TextTransparency = textTransparency}, 0.2):Play()

		if not disableUnderlineTween then
			Utility:tween(underline, {BackgroundColor3 = Theme.PrimaryColor, Position = UDim2.new(0, subTabPosition, 1, 0), Size = UDim2.new(0, subTab.Size.X.Offset, 0, 2)}, 0.2):Play()
		end
	end

	local function autoCanvasSizeSubPageScrollingFrame()
		local max = math.max(Left.UIListLayout.AbsoluteContentSize.Y, Right.UIListLayout.AbsoluteContentSize.Y)
		SubPage.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, max)
	end

	local function updateSectionAnimation()
		Utility:tween(SubPage.ScrollingFrame.UIPadding, {PaddingTop = UDim.new(0, 10)}, 0.2):Play()

		task.delay(0.2, function()
			Utility:tween(SubPage.ScrollingFrame.UIPadding, {PaddingTop = UDim.new(0, 0)}, 0.2):Play()
		end)
	end

	local Context = Utility:validateContext({
		Page = {Value = SubPage, ExpectedType = "Instance"},
		Pages = {Value = self.Page, ExpectedType = "Instance"},
		Popups = {Value = Popups, ExpectedType = "Instance"},
		ScrollingFrame = {Value = ScrollingFrame, ExpectedType = "Instance"},
		animation = {Value = updateSectionAnimation, ExpectedType = "function"},

		tweenTabOn = {Value = function()
			tweenSubTabAssets(SubTab, Underline, Theme.PrimaryColor, 0, false)
		end, ExpectedType = "function"},

		tweenTabsOff = {Value = function(subTab)
			tweenSubTabAssets(subTab, Underline, Theme.SecondaryTextColor, 0, true)
		end, ExpectedType = "function"},

		hoverOn = {Value = function()
			tweenSubTabAssets(SubTab, Underline, Theme.PrimaryColor, 0.3, true)
		end, ExpectedType = "function"},

		hoverOff = {Value = function()
			tweenSubTabAssets(SubTab, Underline, Theme.SecondaryTextColor, 0, true)
		end, ExpectedType = "function"},
	})

	local Navigation = Modules.Navigation.new(Context)

	if not self.firstSubTabDebounce then
		Navigation:enableFirstTab()
		self.firstSubTabDebounce = true
	end

	Left.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvasSizeSubPageScrollingFrame)
	Right.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(autoCanvasSizeSubPageScrollingFrame)

	SubTab.MouseButton1Down:Connect(Navigation:selectTab())
	SubTab.MouseEnter:Connect(Navigation:hoverEffect(true))
	SubTab.MouseLeave:Connect(Navigation:hoverEffect(false))
	
	Theme:registerToObjects({
		{object = Underline, property = "BackgroundColor3", theme = {"PrimaryColor"}},
		{object = SubTab, property = "TextColor3", theme = {"SecondaryTextColor", "PrimaryColor"}},
		{object = SubPage.ScrollingFrame, property = "ScrollBarImageColor3", theme = {"ScrollingBarImageColor"}}
	}, "SubTab")

	local PassingContext = setmetatable({Left = Left, Right = Right}, Library)
	return PassingContext
end

function Library:createSection(options: table)
	Utility:validateOptions(options, {
		text = {Default = "Section", ExpectedType = "string"},
		position = {Default = "Left", ExpectedType = "string"},
	})

	local Section = Assets.Pages.Section:Clone()
	Section.Visible = true
	Section.Parent = self[options.position]
	
	local Inner = Section.Inner

	local TextLabel = Inner.TextLabel
	TextLabel.Text = options.text

	-- Auto size section
	Section.Inner.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Section.Size = UDim2.new(1, 0, 0, Section.Inner.UIListLayout.AbsoluteContentSize.Y + 28)
	end)
	
	Theme:registerToObjects({
		{object = Section, property = "BackgroundColor3", theme = {"Line"}},
		{object = Inner, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = TextLabel, property = "TextColor3", theme = {"PrimaryTextColor"}},
	})

	local PassingContext = setmetatable({Section = Inner, ScrollingFrame = Section.Parent.Parent}, Library)
	return PassingContext
end

function Library:createToggle(options: table, parent, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Toggle", ExpectedType = "string"},
		state = {Default = false, ExpectedType = "boolean"},
		callback = {Default = function() end, ExpectedType = "function"}
	})

	scrollingFrame = self.ScrollingFrame or scrollingFrame

	local Toggle = Assets.Elements.Toggle:Clone()
	Toggle.Visible = true
	Toggle.Parent = parent or self.Section

	local TextLabel = Toggle.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local TextButton = TextLabel.TextButton
	local Background = TextButton.Background
	local Circle = Background.Circle

	local function tweenToggleAssets(backgroundColor: Color3, circleColor: Color3, anchorPoint: Vector2, position: UDim2)
		Utility:tween(Background, {BackgroundColor3 = backgroundColor}, 0.2):Play()
		Utility:tween(Circle, {BackgroundColor3 = circleColor, AnchorPoint = anchorPoint, Position = position}, 0.2):Play()
	end
	
	local circleOn = false

	local Context = Utility:validateContext({
		state = {Value = options.state, ExpectedType = "boolean"},
		callback = {Value = options.callback, ExpectedType = "function"},

		switchOff = {Value = function()
			tweenToggleAssets(Theme.SecondaryBackgroundColor, Theme.PrimaryBackgroundColor, Vector2.new(0, 0.5), UDim2.fromScale(0, 0.5), 0.2)
			circleOn = false
		end, ExpectedType = "function"},

		switchOn = {Value = function()
			tweenToggleAssets(Theme.PrimaryColor, Theme.TertiaryBackgroundColor, Vector2.new(1, 0.5), UDim2.fromScale(1, 0.5), 0.2)
			circleOn = true
		end, ExpectedType = "function"}
	})

	local Toggle = Modules.Toggle.new(Context)
	Toggle:updateState({state = options.state})
	TextButton.MouseButton1Down:Connect(Toggle:switch())
	
	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Background, property = "BackgroundColor3", theme = {"PrimaryColor", "SecondaryBackgroundColor"}},
		{object = Circle, property = "BackgroundColor3", theme = {"TertiaryBackgroundColor", "PrimaryBackgroundColor"}, circleOn = circleOn},
		{object = ImageButton, property = "ImageColor3", theme = {"SecondaryTextColor"}},
	})
	
	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getState = function(self)
			return Context.state
		end,
		
		updateState = function(self, options: table)
			Toggle:updateState(options)
		end,
	})
end

function Library:createSlider(options: table, parent, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Slider", ExpectedType = "string"},
		min = {Default = 0, ExpectedType = "number"},
		max = {Default = 100, ExpectedType = "number"},
		step = {Default = 1, ExpectedType = "number"},
		callback = {Default = function() end, ExpectedType = "function"}
	})

	options.default = options.default or options.min
	options.value = options.default 
	scrollingFrame = self.ScrollingFrame or scrollingFrame

	local Slider = Assets.Elements.Slider:Clone()
	Slider.Visible = true
	Slider.Parent = parent or self.Section
	
	local TextLabel = Slider.TextButton.TextLabel
	local ImageButton = TextLabel.ImageButton
	local TextBox = TextLabel.TextBox

	local Line = Slider.Line
	local TextButton = Slider.TextButton
	local Fill = Line.Fill
	
	local TextLabel = TextButton.TextLabel
	TextLabel.Text = options.text
	
	local Circle = Fill.Circle
	local InnerCircle = Circle.InnerCircle
	local CurrentValueLabel = Circle.TextButton.CurrentValueLabel

	local function tweenSliderInfoAssets(transparency: number)
		local TextBoundsX = math.clamp(CurrentValueLabel.TextBounds.X + 14, 10, 200)
		Utility:tween(CurrentValueLabel, {Size = UDim2.fromOffset(TextBoundsX, 20), BackgroundTransparency = transparency, TextTransparency = transparency}):Play()
	end

	local Context = Utility:validateContext({
		min = {Value = options.min, ExpectedType = "number"},
		max = {Value = options.max, ExpectedType = "number"},
		step = {Value = options.step, ExpectedType = "number"},
		value = {Value = options.default, ExpectedType = "number"},
		callback = {Value = options.callback, ExpectedType = "function"},
		Line = {Value = Line, ExpectedType = "Instance"},
		TextBox = {Value = TextLabel.TextBox, ExpectedType = "Instance"},
		CurrentValueLabel = {Value = CurrentValueLabel, ExpectedType = "Instance"},
		Connections = {Value = Connections, ExpectedType = "table"},

		autoSizeTextBox = {Value = function()
			local TextBoundsX = math.clamp(TextLabel.TextBox.TextBounds.X + 14, 10, 200)
			Utility:tween(TextLabel.TextBox, {Size = UDim2.fromOffset(TextBoundsX, 20)}, 0.2):Play()
		end, ExpectedType = "function"},

		updateFill = {Value = function(sizeX)
			Utility:tween(Line.Fill, {Size = UDim2.fromScale(sizeX, 1)}, 0.2):Play()
		end, ExpectedType = "function"},

		showInfo = {Value = function()
			tweenSliderInfoAssets(0)
		end, ExpectedType = "function"},

		dontShowInfo ={Value = function()
			tweenSliderInfoAssets(1)
		end, ExpectedType = "function"},
	})

	local Slider = Modules.Slider.new(Context)
	Slider:handleSlider()
	
	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Line, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = Fill, property = "BackgroundColor3", theme = {"PrimaryColor"}},
		{object = Circle, property = "BackgroundColor3", theme = {"PrimaryColor"}},
		{object = ImageButton, property = "ImageColor3", theme = {"SecondaryTextColor"}},
		{object = TextBox, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = TextBox, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = CurrentValueLabel, property = "TextColor3", theme = {"TertiaryBackgroundColor"}},
		{object = CurrentValueLabel, property = "BackgroundColor3", theme = {"PrimaryColor"}},
		{object = InnerCircle, property = "BackgroundColor3", theme = {"TertiaryBackgroundColor"}},
	})
	
	Fill.BackgroundColor3 = Theme.PrimaryColor
	Circle.BackgroundColor3 = Theme.PrimaryColor
	InnerCircle.BackgroundColor3 = Theme.TertiaryBackgroundColor
	CurrentValueLabel.BackgroundColor3 = Theme.PrimaryColor
	
	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getValue = function(self)
			return Context.value
		end,
		
		updateValue = function(self, options: table)
			Slider:updateValue(options)
		end,
	})
end

function Library:createPicker(options: table, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Picker", ExpectedType = "string"},
		default = {Default = Color3.fromRGB(255, 0, 0), ExpectedType = "Color3"},
		color = {Default = Color3.fromRGB(255, 0, 0), ExpectedType = "Color3"},
		callback = {Default = function() end, ExpectedType = "function"},
	})

	options.color = options.default
	scrollingFrame = self.ScrollingFrame or scrollingFrame

	local Picker = Assets.Elements.Picker:Clone()
	Picker.Visible = true
	Picker.Parent = self.Section

	local TextLabel = Picker.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local Background = TextLabel.Background
	local TextButton = Background.TextButton

	local ColorPicker = Assets.Elements.ColorPicker:Clone()
	ColorPicker.Parent = Popups
	
	-- Put transparent objects to not be visible to make cool effect later!!
	local ColorPickerTransparentObjects = Utility:getTransparentObjects(ColorPicker)
	
	for _, data in ipairs(ColorPickerTransparentObjects) do
		data.object[data.property] = 1
	end
		
	local Inner = ColorPicker.Inner
	local HSV = Inner.HSV
	local Slider = Inner.Slider
	local Submit = Inner.Submit
	local Hex = Inner.HexAndRGB.Hex
	local RGB = Inner.HexAndRGB.RGB

	local PopupContext = Utility:validateContext({
		Popup = {Value = ColorPicker, ExpectedType = "Instance"},
		Target = {Value = Background, ExpectedType = "Instance"},
		TransparentObjects = {Value = ColorPickerTransparentObjects, ExpectedType = "table"},
		Popups = {Value = Popups, ExpectedType = "Instance"},
		ScrollingFrame = {Value = scrollingFrame, ExpectedType = "Instance"},
		PositionPadding = {Value = 18 + 7, ExpectedType = "number"},
		Connections = {Value = Connections, ExpectedType = "table"},
		SizePadding = {Value = 14, ExpectedType = "number"},
	})
	
	local Popup = Modules.Popup.new(PopupContext)
	TextButton.MouseButton1Down:Connect(Popup:togglePopup())
	
	local ColorPickerContext = Utility:validateContext({
		ColorPicker = {Value = ColorPicker, ExpectedType = "Instance"},
		Hex = {Value = Hex, ExpectedType = "Instance"},
		RGB = {Value = RGB, ExpectedType = "Instance"},
		Slider = {Value = Slider, ExpectedType = "Instance"},
		HSV = {Value = HSV, ExpectedType = "Instance"},
		Submit = {Value = Submit, ExpectedType = "Instance"},
		Background = {Value = Background, ExpectedType = "Instance"},
		Connections = {Value = Connections, ExpectedType = "table"},
		
		hidePopup = {Value = function()
			Popup:showPopup(false, 1, 0.2)
		end, ExpectedType = "function"},

		color = {Value = options.color, ExpectedType = "Color3"},
		callback = {Value = options.callback, ExpectedType = "function"},
	})

	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = ColorPicker, property = "BackgroundColor3", theme = {"Line"}},
		{object = ImageButton, property = "ImageColor3", theme = {"SecondaryTextColor"}},
		{object = Inner, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = Submit, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = Hex, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = RGB, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = Submit.TextLabel, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}}
	})
	
	local ColorPicker = Modules.ColorPicker.new(ColorPickerContext)
	ColorPicker:handleColorPicker()
	
	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getColor = function(self)
			return ColorPickerContext.color
		end,

		updateColor = function(self, options: table)
			ColorPicker:updateColor(options)
		end,
	})
end

function Library:createDropdown(options: table, parent, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Dropdown", ExpectedType = "string"},
		list = {Default = {"Option 1", "Option 2"}, ExpectedType = "table"},
		default = {Default = {}, ExpectedType = "table"},
		multiple = {Default = false, ExpectedType = "boolean"},
		callback = {Default = function() end, ExpectedType = "function"},
	})

	scrollingFrame = self.ScrollingFrame or scrollingFrame

	local Dropdown = Assets.Elements.Dropdown:Clone()
	Dropdown.Visible = true
	Dropdown.Parent = parent or self.Section
	
	local TextLabel = Dropdown.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local Box = Dropdown.Box
	
	local TextButton = Box.TextButton
	TextButton.Text = table.concat(options.default, ", ")

	if options.default[1] == nil then
		TextButton.Text = "None"
	end

	local List = Dropdown.List
	local Inner = List.Inner
	local DropButtons = Inner.ScrollingFrame
	local Search = Inner.TextBox

	-- Auto size ScrollingFrame and List
	DropButtons.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		DropButtons.CanvasSize = UDim2.new(0, 0, 0, DropButtons.UIListLayout.AbsoluteContentSize.Y + Inner.UIListLayout.Padding.Offset)
		DropButtons.Size = UDim2.new(1, 0, 0, math.clamp(DropButtons.UIListLayout.AbsoluteContentSize.Y + Inner.UIListLayout.Padding.Offset, 0, 164))

		if List.Size.Y.Offset > 0 then
			Utility:tween(List, {Size = UDim2.new(1, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))}, 0.2):Play()
			
			for index, value in ipairs(self.DropdownSizes) do
				scrollingFrame.CanvasSize = scrollingFrame.CanvasSize - value.size
				scrollingFrame.CanvasSize = scrollingFrame.CanvasSize + UDim2.new(0, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))
				table.remove(Library.DropdownSizes, index)
				table.insert(Library.DropdownSizes, {object = Dropdown, size = UDim2.new(0, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))})
			end
		end
	end)

	-- As long we don't spam it were good i guess when changing canvassize when tweened but let's not do that
	local function toggleList()
		if List.Size.Y.Offset <= 0 then
			for index, value in ipairs(Library.DropdownSizes) do
				if value.object ~= Dropdown then
					scrollingFrame.CanvasSize = scrollingFrame.CanvasSize - value.size
					table.remove(Library.DropdownSizes, index)
				end
			end

			-- Hide current open dropdowns and make sure enabled dropdown is on top
			for _, object in ipairs(scrollingFrame:GetDescendants()) do
				if object.Name == "Section" then
					object.ZIndex = 1
				end

				if object.Name == "List" and object ~= List then
					object.Parent.ZIndex = 1
					Utility:tween(object, {Size = UDim2.new(1, 0, 0, 0)}, 0.2):Play()
				end
			end

			for _, object in ipairs(Popups:GetDescendants()) do
				if object.Name == "List" and object ~= List then
					object.Parent.ZIndex = 1
					Utility:tween(object, {Size = UDim2.new(1, 0, 0, 0)}, 0.2):Play()
				end
			end

			Dropdown.ZIndex = 2
			
			if self.Section then
				self.Section.Parent.ZIndex = 2
			end
			
			Utility:tween(List, {Size = UDim2.new(1, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))}, 0.2):Play()
			table.insert(Library.DropdownSizes, {object = Dropdown, size = UDim2.new(0, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))})

			scrollingFrame.CanvasSize = scrollingFrame.CanvasSize + UDim2.new(0, 0, 0, math.clamp(Inner.UIListLayout.AbsoluteContentSize.Y, 0, 210))
		else
			Utility:tween(List, {Size = UDim2.new(1, 0, 0, 0)}, 0.2):Play()

			for index, value in ipairs(Library.DropdownSizes) do
				if value.object == Dropdown then
					scrollingFrame.CanvasSize = scrollingFrame.CanvasSize - value.size
					table.remove(Library.DropdownSizes, index)
				end
			end
		end
	end

	local function createDropButton(value)
		local DropButton = Assets.Elements.DropButton:Clone()
		DropButton.Visible = true
		DropButton.Parent = DropButtons

		local TextButton = DropButton.TextButton
		local Background = TextButton.Background
		local Checkmark = TextButton.Checkmark

		local TextLabel = DropButton.TextLabel
		TextLabel.Text = tostring(value)
		
		Theme:registerToObjects({
			{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
			{object = Background, property = "BackgroundColor3", theme = {"PrimaryColor", "SecondaryBackgroundColor"}},
			{object = Checkmark, property = "ImageColor3", theme = {"TertiaryBackgroundColor"}},
		})
		
		return TextButton
	end

	local function tweenDropButton(dropButton: Instance, backgroundColor: Color3, imageTransparency: number)
		Utility:tween(dropButton.Background, {BackgroundColor3 = backgroundColor}, 0.2, "Circular", "InOut"):Play()
		Utility:tween(dropButton.Checkmark, {ImageTransparency = imageTransparency}, 0.3):Play()
	end

	local Context = Utility:validateContext({
		text = {Value = options.text, ExpectedType = "string"},
		default = {Value = options.default, ExpectedType = "table"},
		list = {Value = options.list, ExpectedType = "table"},
		callback = {Value = options.callback, ExpectedType = "function"},
		TextButton = {Value = TextButton, ExpectedType = "Instance"},
		DropButtons = {Value = DropButtons, ExpectedType = "Instance"},
		createDropButton = {Value = createDropButton, ExpectedType = "function"},
		ScrollingFrame = {Value = scrollingFrame, ExpectedType = "Instance"},
		multiple = {Value = options.multiple, ExpectedType = "boolean"},

		tweenDropButtonOn = {Value = function(dropButton)
			tweenDropButton(dropButton, Theme.PrimaryColor, 0)
		end, ExpectedType = "function"},

		tweenDropButtonOff = {Value = function(dropButton)
			tweenDropButton(dropButton, Theme.SecondaryBackgroundColor, 1)
		end, ExpectedType = "function"},
	})

	TextButton.MouseButton1Down:Connect(toggleList)

	-- Search drop buttons function
	Search:GetPropertyChangedSignal("Text"):Connect(function()
		for _, dropButton in ipairs(DropButtons:GetChildren()) do
			if not dropButton:IsA("Frame") then
				continue
			end

			if Search.Text == "" or string.match(string.lower(dropButton.TextLabel.Text), string.lower(Search.Text)) then
				dropButton.Visible = true
			else
				dropButton.Visible = false
			end
		end
	end)

	local Dropdown = Modules.Dropdown.new(Context)
	Dropdown:handleDropdown()
	
	Theme:registerToObjects({
		{object = ImageButton, property = "ImageColor3", theme = {"SecondaryTextColor"}},
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Box, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = TextButton, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = List, property = "BackgroundColor3", theme = {"Line"}},
		{object = Inner, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = Search, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Search, property = "PlaceholderColor3", theme = {"SecondaryTextColor"}},
		{object = Search, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = Search.Parent, property =  "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
	})
	
	List.BackgroundColor3 = Theme.Line
	Inner.BackgroundColor3 = Theme.PrimaryBackgroundColor
	Box.BackgroundColor3 = Theme.SecondaryBackgroundColor
	Search.BackgroundColor3 = Theme.SecondaryBackgroundColor

	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getList = function(self)
			return Context.list
		end,

		updateList = function(self, options: table)
			Dropdown:updateList(options)
		end,
	})
end

function Library:createKeybind(options: table, parent, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Keybind", ExpectedType = "string"},
		default = {Default = "None", ExpectedType = "string"},
		onHeld = {Default = false, ExpectedType = "boolean"},
		callback = {Default = function() end, ExpectedType = "function"},
	})
	
	scrollingFrame = self.ScrollingFrame or scrollingFrame

	local Keybind = Assets.Elements.Keybind:Clone()
	Keybind.Visible = true
	Keybind.Parent = parent or self.Section

	local TextLabel = Keybind.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	local Background = TextLabel.Background
	
	local TextButton = Background.TextButton
	
	if options.default ~= "None" then
		table.insert(Exclusions, options.default)
	end
	
	if not table.find(self.Exclusions, options.default) then
		TextButton.Text = options.default
	else
		TextButton.Text = "None"
		warn("You already have this key binded")
	end

	local Context = Utility:validateContext({
		default = {Value = options.default, ExpectedType = "string"},
		callback = {Value = options.callback, ExpectedType = "function"},
		Background = {Value = TextButton.Parent, ExpectedType = "Instance"},
		TextButton = {Value = TextButton, ExpectedType = "Instance"},
		Connections = {Value = Connections, ExpectedType = "table"},
		Library = {Value = Library, ExpectedType = "table"},
		onHeld = {Value = options.onHeld, ExpectedType = "boolean"},
		Exclusions = {Value = Exclusions, ExpectedType = "table"},

		autoSizeBackground = {Value = function()
			local TextBoundsX = math.clamp(TextButton.TextBounds.X + 14, 10, 200)
			Utility:tween(TextButton.Parent, {Size = UDim2.fromOffset(TextBoundsX, 20)}, 0.2):Play()
		end, ExpectedType = "function"},
	})

	local Keybind = Modules.Keybind.new(Context)
	Keybind:handleKeybind()
	
	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = ImageButton, property = "ImageColor3", theme = {"SecondaryTextColor"}},
		{object = Background, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = TextButton, property = "TextColor3", theme = {"SecondaryTextColor"}}
	})
	
	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getKeybind = function(self)
			return TextButton.Text
		end,

		updateKeybind = function(self, options: table)
			Keybind:updateKeybind(options)
		end,
	})
end

-- Redo textbox later
function Library:createTextBox(options: table, parent, scrollingFrame)
	Utility:validateOptions(options, {
		text = {Default = "Textbox", ExpectedType = "string"},
		default = {Default = "", ExpectedType = "string"},
		callback = {Default = function() end, ExpectedType = "function"},
	})
	
	scrollingFrame = self.ScrollingFrame or scrollingFrame
	
	local TextBox = Assets.Elements.TextBox:Clone()
	TextBox.Visible = true
	TextBox.Parent = parent or self.Section

	local TextLabel = TextBox.TextLabel
	TextLabel.Text = options.text
	
	local ImageButton = TextLabel.ImageButton
	
	local Box = TextLabel.TextBox
	Box.Text = options.default

	local Context = Utility:validateContext({
		default = {Value = options.default, ExpectedType = "string"},
		callback = {Value = options.callback, ExpectedType = "function"},
		TextBox = {Value = Box, ExpectedType = "Instance"},

		autoSizeTextBox = {Value = function()
			local TextBoundsX = math.clamp(Box.TextBounds.X + 14, 0, 100)
			Utility:tween(Box, {Size = UDim2.fromOffset(TextBoundsX, 20)}, 0.2):Play()
		end, ExpectedType = "function"}
	})

	local TextBox = Modules.TextBox.new(Context)
	TextBox:handleTextBox()
	
	Theme:registerToObjects({
		{object = TextLabel, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Box, property = "TextColor3", theme = {"SecondaryTextColor"}},
		{object = Box, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
	})
	
	return self:createAddons(options.text, ImageButton, scrollingFrame, {
		getText = function(self)
			return Box.Text
		end,

		updateText = function(self, options: table)
			Box.Text = options.text or ""
			Context.callback(Box.Text)
		end,
	})
end

-- Later put this into a module, but this is fine if it's put here anyways.
local ChildRemoved = false
function Library:notify(options: table)
	Utility:validateOptions(options, {
		title = {Default = "Notification", ExpectedType = "string"},
		text = {Default = "Hello world", ExpectedType = "string"},
		duration = {Default = 3, ExpectedType = "number"},
		height = {Default = 100, ExpectedType = "number"},
	})
	
	local Notification = Assets.Elements.Notification:Clone()
	Notification.Visible = true
	Notification.Parent = ScreenGui.Notifications
	Notification.Size = UDim2.fromOffset(300, options.height)
	
	local Title = Notification.Title
	Title.Text = options.title
	
	local Body = Notification.Body
	Body.Text = options.text
	
	local Line = Notification.Line
	
	-- Put transparent objects to not be visible to make cool effect
	local NotificationTransparentObjects = Utility:getTransparentObjects(Notification)
	
	for _, data in ipairs(NotificationTransparentObjects) do
		data.object[data.property] = 1
	end

	Notification.BackgroundTransparency = 1
	
	-- Get back NotificationTransparentObjects again and make it visible now with cool effect!!
	for _, data in ipairs(NotificationTransparentObjects) do
		Utility:tween(data.object, {[data.property] = 0}, 0.2):Play()
	end

	Utility:tween(Notification, {["BackgroundTransparency"] = 0}, 0.2):Play()

	local notificationPosition = -24
	local notificationSize = 0
	local PADDING_Y = 14
	
	for index, notification in ipairs(ScreenGui.Notifications:GetChildren()) do
		if index == 1 then
			notificationSize = notification.Size.Y.Offset
			Utility:tween(notification, {Position = UDim2.new(1, -24, 1, notificationPosition)}, 0.2):Play()
			continue
		end
		
		-- Current notification position
		notificationPosition -= notificationSize + PADDING_Y
		-- Update notification size for next time to get proper position
		notificationSize = notification.Size.Y.Offset
		Notification.Position = UDim2.new(1, Notification.Position.X.Offset, 1, notificationPosition)
	end
	
	-- Update notification position when notification is removed
	if not ChildRemoved then
		ScreenGui.Notifications.ChildRemoved:Connect(function(child)		
			for index, notification in ipairs(ScreenGui.Notifications:GetChildren()) do
				if index == 1 then
					notificationPosition = -14
					notificationSize = notification.Size.Y.Offset
					Utility:tween(notification, {Position = UDim2.new(1, -24, 1, notificationPosition)}, 0.2):Play()
					continue
				end

				-- Current notification position
				notificationPosition -= notificationSize + PADDING_Y
				-- Update notification size for next time to get proper position
				notificationSize = notification.Size.Y.Offset
				Utility:tween(notification, {Position = UDim2.new(1, -24, 1, notificationPosition)}, 0.2):Play()
			end
		end)
		
		ChildRemoved = true
	end
	
	-- Auto remove notification after a delay
	task.delay(options.duration, function()
		if Notification then
			for _, data in ipairs(Utility:getTransparentObjects(Notification)) do
				Utility:tween(data.object, {[data.property] = 1}, 0.2):Play()
			end
			
			Utility:tween(Notification, {["BackgroundTransparency"] = 1}, 0.2):Play()
			
			task.wait(0.2)
			Notification:Destroy()
		end
	end)
	
	-- Show notification
	Utility:tween(Notification, {Position = UDim2.new(1, -24, 1, notificationPosition)}, 0.2):Play()
	task.wait(0.2)
	
	-- Register to Theme
	Theme:registerToObjects({
		{object = Notification, property = "BackgroundColor3", theme = {"SecondaryBackgroundColor"}},
		{object = Title, property = "BackgroundColor3", theme = {"PrimaryBackgroundColor"}},
		{object = Title, property = "TextColor3", theme = {"PrimaryTextColor"}},
		{object = Line, property = "BackgroundColor3", theme = {"Line"}},
		{object = Body, property = "TextColor3", theme = {"SecondaryTextColor"}},
	})
end

-- Make UI Draggable and Resizable
Utility:draggable(Connections, Glow)
Utility:resizable(Connections, Glow.Background.Pages.Resize, Glow)

return Library