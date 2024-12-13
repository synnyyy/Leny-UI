local Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/L3nyFromV3rm/Leny-UI/refs/heads/main/Library.lua", true))()

Library.new({
	sizeX = 770,
	sizeY = 600,
	title = "yo",
	tabWidth = 200, -- (72 for icons only, didn't do a min check lol)
})

-- Will add max width later
Library:notify({
	title = "Notification",
	text = "Hello world",
	scaleX = 0.165,
	sizeY = 200,
})

local Main = Library:createLabel({text = "Main"})

local Tab = Library:createTab({
	text = "Exploits",
	icon = "124718082122263", -- 20x20 icon you want here
})

local Page1 = Tab:createSubTab({
	text = "Page 1",
	sectionStyle = "Double", -- Make the page a single section style or double, "Single", "Double"
})

local Section = Page1:createSection({
	text = "Section",
	position = "Left",
})

Section:createToggle({
	text = "Toggle",
	state = false,
	callback = function(state)
		print(state)
	end
}) -- :getState(), :updateState({state = true})

Section:createKeybind({
	onHeld = false,
	text = "Keybind",
	default = "RightBracket",
	callback = function(keyName)
		print(keyName)
	end
}) -- :getKeybind(), :updateKeybind({bind = "LeftShift"})

Section:createSlider({
	text = "Slider",
	min = 0,
	max = 100,
	step = 1,
	callback = function(value)
		print(value)
	end
}) -- :getValue(), :updateValue({value = 100})

Section:createPicker({
	text = "ColorPicker",
	default = Color3.fromRGB(255, 255, 255),
	callback = function(color)
		print(color)
	end
}) -- :getColor(), :updateColor({color = Color3.fromRGB(255, 255, 0)})

Section:createDropdown({
	text = "Dropdown",
	list = {1, 2, 3},
	default = {1, 2},
	multiple = false, -- choose multiple from list, makes callback value return a table now
	callback = function(value)
		print(value)
	end
}) -- :getList() (returns the list you provided, not the value), :getValue(), :updateList({list = {1,2,3}, default = {1, 2}})

Section:createButton({
	text = "Button",
	callback = function()
		print("this is a button")
	end
})

Section:createTextBox({
	text = "TextBox",
	default = "hi",
	callback = function(text)
		print(text)
	end,
}) -- :getText(), :updateText({text = "bro"})


-- Addon example, currently supported Addons (Toggle, Slider, Dropdown, Picker)
local Toggle = Section:createToggle({
	text = "Toggle",
	state = false,
	callback = function(state)
		print(state)
	end
})

-- Same thing as above
Toggle:createPicker({})
Toggle:createSlider({})
Toggle:createDropdown({})
Toggle:createToggle({})

-- Flags example
print(shared.Flags.Toggle["Toggle"]:getState()) -- refers to the {text = "Toggle"} you set for the element

-- Creates the theme changer, config manager, etc
Library:createManager({folderName = "brah"})