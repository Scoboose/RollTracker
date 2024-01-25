-- RollTracker.lua

-- ----Start of options----

-- Check if the DB exists and if not, initialize it
if not options then
    options = {}
end

local optionsPanel = CreateFrame("Frame")
optionsPanel:RegisterEvent("ADDON_LOADED")
optionsPanel.name = "Roll Tracker"
InterfaceOptions_AddCategory(optionsPanel)

-- Create the scrolling parent frame and size it to fit inside the texture
local optionsScrollFrame = CreateFrame("ScrollFrame", nil, optionsPanel, "UIPanelScrollFrameTemplate")
optionsScrollFrame:SetPoint("TOPLEFT", 3, -4)
optionsScrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
local optionsScrollChild = CreateFrame("Frame")
optionsScrollFrame:SetScrollChild(optionsScrollChild)
optionsScrollChild:SetWidth(InterfaceOptionsFramePanelContainer:GetWidth()-18)
optionsScrollChild:SetHeight(1)

-- Add widgets to the scrolling child frame as desired
local optionsTitle = optionsScrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
optionsTitle:SetPoint("TOP")
optionsTitle:SetText("Roll Tracker")

displayDateCheckButton = CreateFrame("CheckButton", "displayDateCheckButton", optionsScrollChild, "ChatConfigCheckButtonTemplate");
displayDateCheckButton:SetPoint("TOPLEFT", 10, -15);
displayDateCheckButton:SetText("Display Dates");
displayDateCheckButton.tooltip = "When checked Roll Tracker will display the date the roll was made on";

optionsPanel:SetScript("OnEvent", function (self, event)
    if event == "ADDON_LOADED" then
        if options["displayDate"] then
            displayDateCheckButton:SetChecked(true)
            -- print("Display date was true") -- Debug
            else
                displayDateCheckButton:SetChecked(false)
                -- print("Display date was false") -- Debug
        end
    end
end)
displayDateCheckButton:SetScript("OnClick", 
  function()
    if displayDateCheckButton:GetChecked() then
        options["displayDate"] = true
        -- print("Checked!") -- Debug
    else
        options["displayDate"] = false
        -- print("Unchecked!") -- Debug
    end
  end
);

optionsScrollChild.rollTypeText = optionsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
optionsScrollChild.rollTypeText:SetText("Display Date?")
optionsScrollChild.rollTypeText:SetTextColor(1, 1, 1) -- White color
optionsScrollChild.rollTypeText:SetPoint("TOPLEFT",35,-20)

local optionsFooter = optionsScrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
optionsFooter:SetPoint("TOP", 0, -5000)
optionsFooter:SetText("This is 5000 below the top, so the scrollChild automatically expanded.")

-- ----End of options----

-- Create a frame to handle events
local frame = CreateFrame("FRAME")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_LOOT")

local dropDowns = {["dropDownPlayer"] = "", ["dropDownLocation"] = "",["dropDownItem"] = "", ["dropDownRollType"] = ""}

local firstUse = true

-- Get the player's name
local playerName = UnitName("player")

-- Set Roll Reason
local rollReason = nil

-- Event handler function
local function OnEvent(self, event, ...)
    local message = ...
    local player, roll, min, max, rollType

    -- Check if it's a standard roll format
    player, roll, min, max = message:match("(" .. playerName .. ") rolls (%d+) %((%d+)%-(%d+)%)")
    if roll and ((min == "1" and max == "100") or (min == "1" and max == "99") or (min == "1" and max == "98")) then
        rollType = "Roll"
        item = rollReason
		-- print(rollType)  -- debugging
    end

    -- Check if it's a "Need Roll" format
    if not rollType then
		roll, item, player = message:match(".*Need Roll %- (%d+) for (.*) by (" .. playerName .. ")")
        if player and roll then
            rollType = "Need"
			-- print(rollType)  -- debugging
			-- print(item)  -- debugging
        end
    end

    -- Check if it's a "Greed Roll" format
    if not rollType then
		roll, item, player = message:match(".*Greed Roll %- (%d+) for (.*) by (" .. playerName .. ")")
        if player and roll then
            rollType = "Greed"
			-- print(rollType)  -- debugging
			-- print(item)  -- debugging
        end
    end

    if rollType and roll then
        local location = GetRealZoneText()
		-- print(location)  -- debugging

        -- Check if the DB exists and if not, initialize it
        if not RollTrackerDB then
            RollTrackerDB = {}
        end

        -- Insert roll data into the database
        table.insert(RollTrackerDB, { roll = tonumber(roll), name=playerName, type = rollType, location = location, item = item, timestamp = time() })
        -- print(item) -- Debug
        rollReason = nil -- Set back to nil after logging a roll with reason
        -- print(rollReason) -- Debug
		-- print("Roll captured:", tonumber(roll))  -- debugging
    end
end

-- Register the event handler
frame:SetScript("OnEvent", OnEvent)

-- Create a table to keep track of the roll texts
local rollTexts = {}

-- Create a container frame
local containerFrame = CreateFrame("Frame", "RollTrackerContainer", UIParent, "BasicFrameTemplate")
containerFrame:ClearAllPoints() -- Reset window position
containerFrame:SetSize(450, 360)  -- Increase the width to accommodate the text
containerFrame:SetPoint("CENTER")
containerFrame:SetFrameStrata("BACKGROUND")
containerFrame:SetFrameLevel(0)
containerFrame:SetMovable(true)  -- Make the container frame movable
containerFrame:EnableMouse(false)  -- Enable mouse interaction
containerFrame:Hide()


containerFrame.CloseButton:SetScript("OnClick", function()
    containerFrame.historyFrame:Hide()
    containerFrame:Hide()
end)


containerFrame:SetScript("OnMouseDown",function(self)
  self:StartMoving()
end)
containerFrame:SetScript("OnMouseUp",function(self)
  self:StopMovingOrSizing()
end)
containerFrame:SetResizable(true)
containerFrame:SetResizeBounds(450, 360, 1500, 360)
containerFrame.ResizeGrip = CreateFrame("Button","RollTrackerRisizeButton",containerFrame)
containerFrame.ResizeGrip:SetSize(20,20)
containerFrame.ResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
containerFrame.ResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
containerFrame.ResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
containerFrame.ResizeGrip:SetPoint("BOTTOMRIGHT")
containerFrame.ResizeGrip:SetScript("OnMouseDown",function(self)
  self:GetParent():StartSizing()
end)
containerFrame.ResizeGrip:SetScript("OnMouseUp",function(self)
  self:GetParent():StopMovingOrSizing()
end)

containerFrame.percentageText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
containerFrame.percentageText:SetTextColor(1, 1, 1) -- White color
containerFrame.percentageText:SetPoint("TOPLEFT",10,-8)
containerFrame.percentageText:SetPoint("TOPRIGHT",-30,0)

containerFrame.TitleText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
containerFrame.TitleText:SetText("ROLL HISTORY")
containerFrame.TitleText:SetPoint("TOPLEFT",0,15)
containerFrame.TitleText:SetPoint("TOPRIGHT",-0,0)

containerFrame.historyFrame = CreateFrame("ScrollFrame", "RollTrackerHistoryFrame", containerFrame, "UIPanelScrollFrameTemplate")
containerFrame.historyFrame:SetSize(450, 280)
containerFrame.historyFrame:SetPoint("TOPLEFT",10,-68)
containerFrame.historyFrame:SetPoint("TOPRIGHT",-30,0)
--containerFrame.historyFrame:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, 0) -- Position to the bottom of the container frame
containerFrame.historyFrame:SetFrameStrata("BACKGROUND")
containerFrame.historyFrame:Hide()

containerFrame.contentFrame = CreateFrame("Frame", "RollTrackerContentFrame", containerFrame.historyFrame)
containerFrame.contentFrame:SetSize(240, 240)  -- Adjust the size to accommodate the text
containerFrame.contentFrame:SetPoint("TOPLEFT",10,-48)
containerFrame.contentFrame:SetPoint("TOPRIGHT",-30,0)
--containerFrame.contentFrame:SetPoint("TOPLEFT", containerFrame.historyFrame, "TOPLEFT", 5, -5)  -- Adjust the position and add a small padding
containerFrame.contentFrame:SetFrameStrata("BACKGROUND")
containerFrame.contentFrame:SetHyperlinksEnabled(true)

-- Tooltips
containerFrame.contentFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
	SetItemRef(link, text, button, self)
end)

containerFrame.contentFrame:SetScript("OnHyperlinkEnter", function(_, link)
	GameTooltip:SetOwner(containerFrame.contentFrame, "ANCHOR_CURSOR")
	GameTooltip:SetHyperlink(link)
	GameTooltip:Show()
end)

containerFrame.contentFrame:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)

-- Set historyFrame as the scroll child of contentFrame
containerFrame.historyFrame:SetScrollChild(containerFrame.contentFrame)

-- Create player drop-down menu
containerFrame.playerDropDown = CreateFrame("Frame", "RollTrackerPlayerDropDown", containerFrame, "UIDropDownMenuTemplate")
--containerFrame.locationDropDown:ClearAllPoints() -- Reset window position
--containerFrame.locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
containerFrame.playerDropDown:SetPoint("TOPLEFT",-15,-35)
--containerFrame.playerDropDown:SetPoint("TOPRIGHT",0,0)
UIDropDownMenu_SetWidth(containerFrame.playerDropDown,80,0)
UIDropDownMenu_JustifyText(containerFrame.playerDropDown,"LEFT")
containerFrame.playerDropDown:Hide() -- Hide initially

containerFrame.characterNameText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
containerFrame.characterNameText:SetText("Character")
containerFrame.characterNameText:SetTextColor(1, 1, 1) -- White color
containerFrame.characterNameText:SetPoint("TOPLEFT",30,-25)
-- containerFrame.characterNameText:SetPoint("TOPRIGHT",0,0)

-- Create location drop-down menu
containerFrame.locationDropDown = CreateFrame("Frame", "RollTrackerLocationDropDown", containerFrame, "UIDropDownMenuTemplate")
--containerFrame.locationDropDown:ClearAllPoints() -- Reset window position
--containerFrame.locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
containerFrame.locationDropDown:SetPoint("TOPLEFT",85,-35)
--containerFrame.locationDropDown:SetPoint("TOPRIGHT",0,0)
UIDropDownMenu_SetWidth(containerFrame.locationDropDown,80,0)
UIDropDownMenu_JustifyText(containerFrame.locationDropDown,"LEFT")
containerFrame.locationDropDown:Hide() -- Hide initially

containerFrame.locationText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
containerFrame.locationText:SetText("Location")
containerFrame.locationText:SetTextColor(1, 1, 1) -- White color
containerFrame.locationText:SetPoint("TOPLEFT",130,-25)

-- Create item drop-down menu
containerFrame.itemDropDown = CreateFrame("Frame", "RollTrackerItemDropDown", containerFrame, "UIDropDownMenuTemplate")
--containerFrame.locationDropDown:ClearAllPoints() -- Reset window position
--containerFrame.locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
containerFrame.itemDropDown:SetPoint("TOPLEFT",185,-35)
--containerFrame.locationDropDown:SetPoint("TOPRIGHT",0,0)
UIDropDownMenu_SetWidth(containerFrame.itemDropDown,120,0)
UIDropDownMenu_JustifyText(containerFrame.itemDropDown,"LEFT")
containerFrame.itemDropDown:Hide() -- Hide initially

containerFrame.itemText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
containerFrame.itemText:SetText("Item")
containerFrame.itemText:SetTextColor(1, 1, 1) -- White color
containerFrame.itemText:SetPoint("TOPLEFT",260,-25)

-- Create roll type drop-down menu
containerFrame.rollTypeDropDown = CreateFrame("Frame", "RollTrackerrollTypeDropDown", containerFrame, "UIDropDownMenuTemplate")
--containerFrame.locationDropDown:ClearAllPoints() -- Reset window position
--containerFrame.locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
containerFrame.rollTypeDropDown:SetPoint("TOPLEFT",325,-35)
--containerFrame.locationDropDown:SetPoint("TOPRIGHT",0,0)
UIDropDownMenu_SetWidth(containerFrame.rollTypeDropDown,60,0)
UIDropDownMenu_JustifyText(containerFrame.rollTypeDropDown,"LEFT")
containerFrame.rollTypeDropDown:Hide() -- Hide initially

containerFrame.rollTypeText = containerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
containerFrame.rollTypeText:SetText("Roll Type")
containerFrame.rollTypeText:SetTextColor(1, 1, 1) -- White color
containerFrame.rollTypeText:SetPoint("TOPLEFT",360,-25)

-- Text area for when no rolls are found in a location
containerFrame.NoRolls  = containerFrame:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
containerFrame.NoRolls:SetPoint("TOPLEFT",8,-24)
containerFrame.NoRolls:SetPoint("BOTTOMRIGHT",-10,8)

--f.Text  = f:CreateFontString(nil,"ARTWORK","GameFontNormalLarge")
--f.Text:SetPoint("TOPLEFT",8,-24)
--f.Text:SetPoint("BOTTOMRIGHT",-10,8)
--f.Text:SetText("This is centered text.\n\nDrag the lower right corner of the window to resize it. Drag any other part of the window to move it.")
--f.Text:SetJustifyH("CENTER") -- probably not needed
--f.Text:SetJustifyV("CENTER") -- probably not needed either

-- Create a background frame
--local bgFrame = CreateFrame("Frame", "RollTrackerBgFrame", containerFrame)
--bgFrame:SetSize(450, 300)  -- Set the size to match historyFrame
--bgFrame:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, 0)  -- Position to match historyFrame
--bgFrame:SetFrameLevel(0) -- To ensure it stays behind the contentFrame
--bgFrame:SetFrameStrata("BACKGROUND")
--bgFrame:Hide() -- Hide the black frame on load

-- Create background background
--local bgFrameBackground = bgFrame:CreateTexture(nil, "BACKGROUND")
--bgFrameBackground:SetAllPoints()
--bgFrameBackground:SetColorTexture(0, 0, 0, 0.50) -- Black color with 50% opacity

-- Create frame border
--[[
bgFrame.border = CreateFrame("Frame", nil, bgFrame, "BackdropTemplate")
bgFrame.border:SetPoint("TOPLEFT", -5, 5)
bgFrame.border:SetPoint("BOTTOMRIGHT", 5, -5)
bgFrame.border:SetBackdrop({
    bgFile = "Interface\\Stationery\\StationeryTest1",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})
bgFrame.border:SetBackdropBorderColor(0.6, 0.6, 0.6) -- Light gray color

--]]

--[[
-- Create history frame
local historyFrame = CreateFrame("ScrollFrame", "RollTrackerHistoryFrame", containerFrame, "UIPanelScrollFrameTemplate")
historyFrame:SetSize(450, 300)
historyFrame:SetPoint("BOTTOM", containerFrame, "BOTTOM", 0, 0) -- Position to the bottom of the container frame
historyFrame:SetFrameStrata("BACKGROUND")
historyFrame:Hide()
--]]

--[[
-- Create scrollable content frame
local contentFrame = CreateFrame("Frame", "RollTrackerContentFrame", containerFrame.historyFrame)
contentFrame:SetSize(240, 240)  -- Adjust the size to accommodate the text
contentFrame:SetPoint("TOPLEFT", containerFrame.historyFrame, "TOPLEFT", 5, -5)  -- Adjust the position and add a small padding
contentFrame:SetFrameStrata("BACKGROUND")
contentFrame:SetHyperlinksEnabled(true)
--]]

--[[
-- Create a title bar
local titleBar = CreateFrame("Frame", "RollTrackerTitleBar", containerFrame)
titleBar:SetSize(450, 70)  -- Increase the height to accommodate the text
titleBar:SetPoint("BOTTOM", historyFrame, "TOP", 0, 0) -- Position at the top of the history frame
titleBar:SetFrameStrata("BACKGROUND")
titleBar:Hide() -- Hide the title bar initially

-- Create title bar background
local titleBarBackground = titleBar:CreateTexture(nil, "BACKGROUND")
titleBarBackground:SetAllPoints()
titleBarBackground:SetColorTexture(0, 0, 0, 0.50) -- Black color with 50% opacity

-- Create title text
local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetText("ROLL HISTORY")
titleText:SetPoint("CENTER", titleBar, "TOP", 0, -10)

-- Create percentage text
local percentageText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
percentageText:SetTextColor(1, 1, 1) -- White color
percentageText:SetPoint("TOP", titleText, "BOTTOM", 0, -5)
--]]

function rpairs(t)
	return function(t, i)
		i = i - 1
		if i ~= 0 then
			return i, t[i]
		end
	end, t, #t + 1
end

-- Function to update history based on selected location
local function UpdateHistoryByLocation(location)
    -- print("UpdateHistoryByLocation called with location:", location)  -- debugging

    --[[
    for k, v in pairs(dropDowns) do -- Debug
        print(k,v) -- Debug
    end
    --]]

    -- Check if RollTrackerDB exists
    if not RollTrackerDB then
        RollTrackerDB = {}
    end

    -- Clear content frame
    for _, rollText in ipairs(rollTexts) do
        rollText:Hide()
    end
    wipe(rollTexts)

    -- Print the content of RollTrackerDB for debugging
    -- print("RollTrackerDB content:", #RollTrackerDB)
    for i, rollData in ipairs(RollTrackerDB) do
        -- print(i, rollData.location, rollData.roll)
    end

    -- Populate content frame with roll history for the selected location
    local rolls25AndUnder = 0
    local rolls75AndAbove = 0

    for i, rollData in rpairs(RollTrackerDB) do
        --if location == "All" or rollData.location == location or then -- Old
        --if dropDowns["dropDownLocation"] == "All" or rollData.location == dropDowns["dropDownLocation"] and dropDowns["dropDownPlayer"] == "All" or rollData.name == dropDowns["dropDownPlayer"] then
		--if dropDowns["dropDownLocation"] == "All" or rollData.location == dropDowns["dropDownLocation"] then -- Debug Works
        --if dropDowns["dropDownPlayer"] == "All" or rollData.name == dropDowns["dropDownPlayer"] then -- Debug Works
        if dropDowns["dropDownLocation"] == "All" or rollData.location == dropDowns["dropDownLocation"] then
            if dropDowns["dropDownPlayer"] == "All" or rollData.name == dropDowns["dropDownPlayer"] then
                if dropDowns["dropDownItem"] == "All" or rollData.item == dropDowns["dropDownItem"] then
                    if dropDowns["dropDownRollType"] == "All" or rollData.type == dropDowns["dropDownRollType"] then
                        
                    
                    
                        -- print("Drop downs - Location: " .. dropDowns["dropDownLocation"] .. " Player: " .. dropDowns["dropDownPlayer"]) -- debug
                        -- print("Roll data - Location: " .. rollData.location .. " Player: " .. rollData.name) -- debug
                        if rollData.item == nil then
                            rollData.item = "Unknown"
                        end
                        local dateText = date("%m/%d/%Y", rollData.timestamp or 0)
                        local rollText = containerFrame.contentFrame:CreateFontString("RollTrackerRollText", "HIGHLIGHT", "GameFontNormalSmall")
                        --rollText:SetPoint("TOPLEFT",0,-0)
                        --rollText:SetPoint("TOPRIGHT",-0,0)
                        --rollText:SetJustifyH("CENTER")
                        --rollText:SetText(dateText .. "    |    " .. rollData.name .. "    |    " .. rollData.location .. "    |    " .. rollData.item .. "    |    " ..rollData.type .. "    |    " .. rollData.roll)
                        
                        local showDate
                        
                        if options["displayDate"] then
                            showDate = dateText .. "    |    "
                            else
                                showDate = ""
                        end
                        rollText:SetText(showDate .. rollData.name .. "    |    " .. rollData.location .. "    |    " .. rollData.item .. "    |    " ..rollData.type .. "    |    " .. rollData.roll)
                        -- print(dateText .. "    |    " .. rollData.location .. "    |    " .. rollData.item .. "    |    " ..rollData.type .. "    |    " .. rollData.roll) -- Debug
                        rollText:SetTextColor(1, 1, 1)

                        if rollData.roll >= 75 then
                            rollText:SetTextColor(0, 1, 0)
                            rolls75AndAbove = rolls75AndAbove + 1
                        elseif rollData.roll <= 25 then
                            rollText:SetTextColor(1, 0, 0)
                            rolls25AndUnder = rolls25AndUnder + 1
                        else
                            rollText:SetTextColor(1, 1, 0)
                        end

                        --rollText:SetPoint("TOPLEFT", containerFrame.contentFrame, "TOPLEFT", 10, -10 - 15 * (#rollTexts + 1))
                        rollText:SetPoint("TOPLEFT", containerFrame.contentFrame, "TOPLEFT", 0, - 15 * (#rollTexts + 1))
                        rollText:SetDrawLayer("OVERLAY")
                        rollText:Show()

                        table.insert(rollTexts, rollText)
                    end
                end
            end
        end
    end

    -- Calculate percentages for the selected location
    local totalRolls = 0

    if dropDowns["dropDownLocation"] == "All" and dropDowns["dropDownPlayer"] == "All" and dropDowns["dropDownItem"] == "All" then
        totalRolls = #RollTrackerDB
    else
        for _, rollData in ipairs(RollTrackerDB) do
            if rollData.location == dropDowns["dropDownLocation"] or dropDowns["dropDownLocation"] == "All" then
                if rollData.name == dropDowns["dropDownPlayer"] or dropDowns["dropDownPlayer"] == "All" then
                    if rollData.item == dropDowns["dropDownItem"] or dropDowns["dropDownItem"] == "All" then
                        if dropDowns["dropDownRollType"] == "All" or rollData.type == dropDowns["dropDownRollType"] then
                            totalRolls = totalRolls + 1
                        end
                    end
                end
            end
                
        end
    end

    if totalRolls > 0 then
        local percentage25AndUnder = (rolls25AndUnder / totalRolls) * 100
        local percentage75AndAbove = (rolls75AndAbove / totalRolls) * 100
        containerFrame.percentageText:SetText(string.format("Percentage of rolls 25 and under: %.2f%%   |   Percentage of rolls 75 and over: %.2f%%", percentage25AndUnder, percentage75AndAbove))
        containerFrame.NoRolls:Hide()
    else
        containerFrame.percentageText:SetText("No roll history available")
        containerFrame.NoRolls:Show()
        containerFrame.NoRolls:SetText("No roll history available for " .. dropDowns["dropDownPlayer"] .. " at " .. dropDowns["dropDownLocation"] .. "\nfor " .. dropDowns["dropDownItem"] .. " with a roll type of " .. dropDowns["dropDownRollType"])
    end
end

-- Function to handle location drop-down menu selection
local function OnLocationDropDownSelect(self, arg1, arg2, checked)
    -- print("OnLocationDropDownSelect location:", arg1)  -- debugging
    local selectedLocation = arg1 or "All"  -- Use "All" if arg1 is nil
    UIDropDownMenu_SetText(containerFrame.locationDropDown, selectedLocation)
    dropDowns["dropDownLocation"] = selectedLocation
    UpdateHistoryByLocation(selectedLocation)
end

-- Function to handle player drop-down menu selection
local function OnPlayerDropDownSelect(self, arg1, arg2, checked)
    -- print("OnLocationDropDownSelect location:", arg1)  -- debugging
    local selectedPlayer = arg1 or "All"  -- Use Player name if arg1 is nil
    UIDropDownMenu_SetText(containerFrame.playerDropDown, selectedPlayer)
    dropDowns["dropDownPlayer"] = selectedPlayer
    UpdateHistoryByLocation(selectedPlayer)
end

-- Function to handle item drop-down menu selection
local function OnItemDropDownSelect(self, arg1, arg2, checked)
    -- print("OnLocationDropDownSelect location:", arg1)  -- debugging
    local selectedItem = arg1 or "All"  -- Use Player name if arg1 is nil
    UIDropDownMenu_SetText(containerFrame.itemDropDown, selectedItem)
    dropDowns["dropDownItem"] = selectedItem
    UpdateHistoryByLocation(selectedItem)
end

-- Function to handle roll type drop-down menu selection
local function OnRollTypeDropDownSelect(self, arg1, arg2, checked)
    -- print("OnLocationDropDownSelect location:", arg1)  -- debugging
    local selectedRollType = arg1 or "All"  -- Use Player name if arg1 is nil
    UIDropDownMenu_SetText(containerFrame.rollTypeDropDown, selectedRollType)
    dropDowns["dropDownRollType"] = selectedRollType
    UpdateHistoryByLocation(selectedRollType)
end

-- Initialize location drop-down menu with default value
UIDropDownMenu_Initialize(containerFrame.locationDropDown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All"
    info.func = OnLocationDropDownSelect
    UIDropDownMenu_AddButton(info)

    if RollTrackerDB then
        local locations = {}
        for _, rollData in ipairs(RollTrackerDB) do
            locations[rollData.location] = true
        end

        for location in pairs(locations) do
            info.text = location
            info.func = OnLocationDropDownSelect
            info.arg1 = location  -- Pass the location as arg1
            UIDropDownMenu_AddButton(info)
        end
    end
end)

-- Initialize player drop-down menu with default value
UIDropDownMenu_Initialize(containerFrame.playerDropDown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All"
    info.func = OnPlayerDropDownSelect
    UIDropDownMenu_AddButton(info)

    if RollTrackerDB then
        local players = {}
        for _, rollData in ipairs(RollTrackerDB) do
            players[rollData.name] = true
        end

        for player in pairs(players) do
            info.text = player
            info.func = OnPlayerDropDownSelect
            info.arg1 = player  -- Pass the location as arg1
            UIDropDownMenu_AddButton(info)
        end
    end
end)

-- Initialize item drop-down menu with default value
UIDropDownMenu_Initialize(containerFrame.itemDropDown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All"
    info.func = OnItemDropDownSelect
    UIDropDownMenu_AddButton(info)

    if RollTrackerDB then
        local items = {}
        for _, rollData in ipairs(RollTrackerDB) do
            items[rollData.item] = true
        end

        for item in pairs(items) do
            info.text = item
            info.func = OnItemDropDownSelect
            info.arg1 = item  -- Pass the location as arg1
            UIDropDownMenu_AddButton(info)
        end
    end
end)

-- Initialize roll type drop-down menu with default value
UIDropDownMenu_Initialize(containerFrame.rollTypeDropDown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All"
    info.func = OnRollTypeDropDownSelect
    UIDropDownMenu_AddButton(info)

    if RollTrackerDB then
        local types = {}
        for _, rollData in ipairs(RollTrackerDB) do
            types[rollData.type] = true
        end

        for type in pairs(types) do
            info.text = type
            info.func = OnRollTypeDropDownSelect
            info.arg1 = type  -- Pass the location as arg1
            UIDropDownMenu_AddButton(info)
        end
    end
end)

-- Set the initial selected value for locationDropDown
local initialLocation = "All"
UIDropDownMenu_SetText(containerFrame.locationDropDown, initialLocation)
OnLocationDropDownSelect(nil, initialLocation) -- Manually trigger the initial selection

-- Set the initial selected value for playerDropDown
local initialPlayer = playerName
UIDropDownMenu_SetText(containerFrame.playerDropDown, initialPlayer)
OnPlayerDropDownSelect(nil, initialPlayer) -- Manually trigger the initial selection

-- Set the initial selected value for itemDropDown
local initialItem = "All"
UIDropDownMenu_SetText(containerFrame.itemDropDown, initialItem)
OnItemDropDownSelect(nil, initialItem) -- Manually trigger the initial selection

-- Set the initial selected value for rollType
local initialRollType = "All"
UIDropDownMenu_SetText(containerFrame.rollTypeDropDown, initialRollType)
OnItemDropDownSelect(nil, initialRollType) -- Manually trigger the initial selection




--[[
-- Create close button
local closeButton = CreateFrame("Button", nil, containerFrame.historyFrame, "GameMenuButtonTemplate")
closeButton:SetPoint("TOP", containerFrame.historyFrame, "BOTTOM", -55, -10) -- Adjust the X position to center the button
closeButton:SetSize(100, 25)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    containerFrame.historyFrame:Hide()
    titleBar:Hide()  -- Hide the title bar when clicked
    --bgFrame:Hide() -- Hide the black frame when clicked
	locationDropDown:Hide()
	RollTrackerContainer:EnableMouse(false)
end)
closeButton:Hide() -- Hide the close button on load
--]]

--[[
-- Create clear history button
local clearButton = CreateFrame("Button", nil, containerFrame.historyFrame, "GameMenuButtonTemplate")
clearButton:SetPoint("TOP", containerFrame.historyFrame, "TOP", 110, 0) -- Adjust the X position to center the button
clearButton:SetSize(100, 25)
clearButton:SetText("Clear History")
clearButton:Hide() -- Hide the clear button on load
--]]

-- Function to update history
--[[
local function UpdateHistory()
    -- Clear content frame
    for _, rollText in ipairs(rollTexts) do
        rollText:Hide()
    end
    wipe(rollTexts)

    -- Populate content frame with roll history
    -- Check if the DB exists and if not, initialize it
    if not RollTrackerDB then
        RollTrackerDB = {}
    end

    local rolls25AndUnder = 0
    local rolls75AndAbove = 0

    for i, rollData in ipairs(RollTrackerDB) do
		if rollData.item == nil then
			rollData.item = "Unknown"
		end
        local dateText = date("%m/%d/%Y", rollData.timestamp or 0)  -- Get the date in MM/DD/YYYY format
        local rollText = contentFrame:CreateFontString(nil, "HIGHLIGHT", "GameFontNormalSmall")
        rollText:SetText(dateText .. "    |    " .. rollData.location .. "    |    " .. rollData.item .. "    |    " ..rollData.type .. "    |    " .. rollData.roll)
        rollText:SetTextColor(1, 1, 1) -- White color

        -- Change text color based on roll value
        if rollData.roll >= 75 then
            rollText:SetTextColor(0, 1, 0) -- Green for rolls 75 and above
            rolls75AndAbove = rolls75AndAbove + 1
        elseif rollData.roll <= 25 then
            rollText:SetTextColor(1, 0, 0) -- Red for rolls 25 and below
            rolls25AndUnder = rolls25AndUnder + 1
        else
            rollText:SetTextColor(1, 1, 0) -- Yellow for all other rolls
        end

        rollText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, -10 - 15 * (i - 1))  -- Adjust the starting point and set draw layer
        rollText:SetDrawLayer("OVERLAY")  -- Set the draw layer to OVERLAY

        rollText:Show()

        -- Add the roll text to the table
        table.insert(rollTexts, rollText)
    end

    -- Calculate percentages
    local totalRolls = #RollTrackerDB
    if totalRolls > 0 then
        local percentage25AndUnder = (rolls25AndUnder / totalRolls) * 100
        local percentage75AndAbove = (rolls75AndAbove / totalRolls) * 100

        -- Update percentage text
        percentageText:SetText(string.format("Percentage of rolls 25 and under: %.2f%%   |   Percentage of rolls 75 and over: %.2f%%", percentage25AndUnder, percentage75AndAbove))
    else
        percentageText:SetText("No roll history available")
    end
end
--]]

-- Function to clear history
local function ClearHistory()
    if next(RollTrackerDB) ~= nil then
        StaticPopupDialogs["CLEAR_ROLL_HISTORY"] = {
            text = "Are you sure you want to clear the roll history?",
            button1 = "Accept",
            button2 = "Decline",
            OnAccept = function()
                wipe(RollTrackerDB)
                UpdateHistoryByLocation("Unknown") -- Was UpdateHistory()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CLEAR_ROLL_HISTORY")
    end
end

-- Function to handle rolling for a reason
local function RollReason()
    StaticPopupDialogs["Roll_With_Reason"] = {
        text = "What is the reason for rolling?",
        hasEditBox = 1,
        maxLetters = 500,
        button1 = "Roll",
        button2 = "Cancel",
        OnShow = function(self)
            local editBox = self.editBox
            editBox:SetText("Chest")
            editBox:HighlightText()
            if editBox:HasFocus() then
                hooksecurefunc("ChatEdit_InsertLink", function(text)
                    editBox:SetText(text)
                    --local clickedItem = text
                    --print(clickedItem)
                end)
            end
        end,
        OnAccept = function(self)
            local editBox = self.editBox
            rollReason = editBox:GetText()
            RandomRoll(1, 100) -- Roll
            -- print(rollReason) -- Debug
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("Roll_With_Reason")
end

-- clearButton:SetScript("OnClick", ClearHistory)

--[[
-- Make the container frame draggable
containerFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
    end
end)
containerFrame:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end)
containerFrame:SetScript("OnHide", function(self)
    if self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end)
--]]

--[[
-- Slash command to display roll history
SLASH_rolltracker1 = "/rh"
SLASH_rolltracker2 = "/rollhistory"
SlashCmdList["rolltracker"] = function()
    -- Check if the DB exists and if not, print no rolls recorded
    if not RollTrackerDB or #RollTrackerDB == 0 then
        print("No rolls recorded.")
    else
        -- UpdateHistory()
        containerFrame.historyFrame:Show()
		UpdateHistoryByLocation("All")
        titleBar:Show()  -- Show the title bar when the command is used
        --closeButton:Show()  -- Show the close button when the command is used
        clearButton:Show()  -- Show the clear history button when the command is used
        --bgFrame:Show() -- Show the black frame when the command is used
		locationDropDown:Show()
		RollTrackerContainer:EnableMouse(true)
    end
end
--]]

-- Create a button frame
local minimapButton = CreateFrame("Button", "RollTrackerMinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("LOW")
minimapButton:SetFrameLevel(8) -- Place it above other UI elements
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

-- Set the button texture
minimapButton:SetNormalTexture("Interface\\Icons\\INV_Misc_Dice_01")
minimapButton:SetPushedTexture("Interface\\Icons\\INV_Misc_Dice_02")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

-- Register events for the button
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- Set the button's click functionality
minimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- Check if the DB exists and if not, print no rolls recorded
        if not containerFrame.historyFrame:IsShown() then
            if firstUse == true then
                firstUse = false
                dropDowns = {["dropDownPlayer"] = playerName, ["dropDownLocation"] = GetRealZoneText(), ["dropDownItem"] = "All", ["dropDownRollType"] = "All"}
                OnLocationDropDownSelect(nil, GetRealZoneText()) -- Manually trigger the initial selection
            end
            --local initialLocation = "All"
            --UIDropDownMenu_SetText(containerFrame.locationDropDown, initialLocation)
            
            -- UpdateHistory()
            --UpdateHistoryByLocation("All")
            containerFrame.historyFrame:Show()
            --titleBar:Show()  -- Show the title bar when the command is used
            --closeButton:Show()  -- Show the close button when the command is used
            --clearButton:Show()  -- Show the clear history button when the command is used
            --bgFrame:Show() -- Show the black frame when the command is used
            containerFrame.locationDropDown:Show()
            containerFrame.playerDropDown:Show()
            containerFrame.itemDropDown:Show()
            containerFrame.rollTypeDropDown:Show()
            containerFrame:Show()
            containerFrame:EnableMouse(true)
            UpdateHistoryByLocation(GetRealZoneText()) -- Update history for current location
		else 
			containerFrame.historyFrame:Hide()
			--titleBar:Hide()  -- Show the title bar when the command is used
			--closeButton:Hide()  -- Show the close button when the command is used
			--clearButton:Hide()  -- Show the clear history button when the command is used
			--bgFrame:Hide() -- Show the black frame when the command is used
			containerFrame.locationDropDown:Hide()
            containerFrame.playerDropDown:Hide()
            containerFrame.itemDropDown:Hide()
            containerFrame.rollTypeDropDown:Hide()
            containerFrame:Hide()
			containerFrame:EnableMouse(false)
		end
    elseif IsShiftKeyDown() and IsLeftAltKeyDown() and button == "RightButton" then
        --print("Shift Alt Right!") -- Debug
        ClearHistory()
    elseif IsShiftKeyDown() and button == "RightButton" then
        RollReason()
    elseif IsLeftControlKeyDown() and button == "RightButton" then
        containerFrame:ClearAllPoints() -- Reset window position
        containerFrame:SetSize(450, 360)
        containerFrame:SetPoint("CENTER")
        --locationDropDown:ClearAllPoints() -- Reset window position
        --locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
    elseif IsLeftAltKeyDown() and button == "RightButton" then
        InterfaceAddOnsList_Update()
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        --InterfaceOptionsFrame_Show()
    elseif button == "RightButton" then
        -- Use the built-in /roll command for right-click
        RandomRoll(1, 100) -- Roll
        UpdateHistoryByLocation(GetRealZoneText())
    end
end)

-- Add the minimap icon
local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
icon:SetPoint("CENTER")

-- drag functionality for the button
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)
minimapButton:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("|cFF00FF00RollTracker|r")
    GameTooltip:AddLine("|cFFD3D3D3Left Click:|r Show/Hide Roll History")
    GameTooltip:AddLine("|cFFD3D3D3Right Click:|r Roll")
    GameTooltip:AddLine("|cFFD3D3D3Shift + Right Click:|r Roll with a reason")
    GameTooltip:AddLine("|cFFD3D3D3Alt + Right Click:|r Options")
    GameTooltip:AddLine("|cFFD3D3D3Control + Right Click:|r Reset window positions")
    GameTooltip:AddLine("|cFFD3D3D3Shift + Alt + Right Click:|r Clear History")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


UpdateHistoryByLocation("All")  -- Maybe not needed?
containerFrame:EnableMouse(false)