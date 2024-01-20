-- RollTracker.lua

-- Create a frame to handle events
local frame = CreateFrame("FRAME")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:RegisterEvent("CHAT_MSG_LOOT")

-- Get the player's name
local playerName = UnitName("player")

-- Event handler function
local function OnEvent(self, event, ...)
    local message = ...
    local player, roll, min, max, rollType

    -- Check if it's a standard roll format
    player, roll, min, max = message:match("(" .. playerName .. ") rolls (%d+) %((%d+)%-(%d+)%)")
    if roll and ((min == "1" and max == "100") or (min == "1" and max == "99") or (min == "1" and max == "98")) then
        rollType = "Roll"
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
        table.insert(RollTrackerDB, { roll = tonumber(roll), type = rollType, location = location, item = item, timestamp = time() })
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
containerFrame.historyFrame:SetSize(450, 300)
containerFrame.historyFrame:SetPoint("TOPLEFT",10,-48)
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

-- Create location drop-down menu
containerFrame.locationDropDown = CreateFrame("Frame", "RollTrackerLocationDropDown", containerFrame, "UIDropDownMenuTemplate")
--containerFrame.locationDropDown:ClearAllPoints() -- Reset window position
--containerFrame.locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
containerFrame.locationDropDown:SetPoint("TOPLEFT",-15,-20)
containerFrame.locationDropDown:SetPoint("TOPRIGHT",0,0)
containerFrame.locationDropDown:Hide() -- Hide initially

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

-- Function to update history based on selected location
local function UpdateHistoryByLocation(location)
    -- print("UpdateHistoryByLocation called with location:", location)  -- debugging

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

    for i, rollData in ipairs(RollTrackerDB) do
        if location == "All" or rollData.location == location then
			if rollData.item == nil then
				rollData.item = "Unknown"
			end
            local dateText = date("%m/%d/%Y", rollData.timestamp or 0)
            local rollText = containerFrame.contentFrame:CreateFontString("RollTrackerRollText", "HIGHLIGHT", "GameFontNormalSmall")
            --rollText:SetPoint("TOPLEFT",0,-0)
            --rollText:SetPoint("TOPRIGHT",-0,0)
            --rollText:SetJustifyH("CENTER")
            rollText:SetText(dateText .. "    |    " .. rollData.location .. "    |    " .. rollData.item .. "    |    " ..rollData.type .. "    |    " .. rollData.roll)
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

    -- Calculate percentages for the selected location
    local totalRolls = 0

    if location == "All" then
        totalRolls = #RollTrackerDB
    else
        for _, rollData in ipairs(RollTrackerDB) do
            if rollData.location == location then
                totalRolls = totalRolls + 1
            end
        end
    end

    if totalRolls > 0 then
        local percentage25AndUnder = (rolls25AndUnder / totalRolls) * 100
        local percentage75AndAbove = (rolls75AndAbove / totalRolls) * 100
        containerFrame.percentageText:SetText(string.format("Percentage of rolls 25 and under: %.2f%%   |   Percentage of rolls 75 and over: %.2f%%", percentage25AndUnder, percentage75AndAbove))
        containerFrame.NoRolls:Hide()
    else
        containerFrame.percentageText:SetText("No roll history available for " .. location)
        containerFrame.NoRolls:Show()
        containerFrame.NoRolls:SetText("No roll history available for " .. location)
    end
end

-- Function to handle drop-down menu selection
local function OnLocationDropDownSelect(self, arg1, arg2, checked)
    -- print("OnLocationDropDownSelect location:", arg1)  -- debugging
    local selectedLocation = arg1 or "All"  -- Use "All" if arg1 is nil
    UIDropDownMenu_SetText(containerFrame.locationDropDown, selectedLocation)
    UpdateHistoryByLocation(selectedLocation)
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

-- Set the initial selected value for locationDropDown
local initialLocation = "All"
UIDropDownMenu_SetText(containerFrame.locationDropDown, initialLocation)
OnLocationDropDownSelect(nil, initialLocation) -- Manually trigger the initial selection




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
                UpdateHistoryByLocation() -- Was UpdateHistory()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("CLEAR_ROLL_HISTORY")
    end
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
		if not RollTrackerDB or #RollTrackerDB == 0 then
			containerFrame.historyFrame:Hide()
			--titleBar:Hide()  -- Show the title bar when the command is used
			--closeButton:Hide()  -- Show the close button when the command is used
			--clearButton:Hide()  -- Show the clear history button when the command is used
			--bgFrame:Hide() -- Show the black frame when the command is used
			containerFrame.locationDropDown:Hide()
            containerFrame:Hide()
			containerFrame:EnableMouse(false)
			print("No rolls recorded.")
		elseif not containerFrame.historyFrame:IsShown() then
			--local initialLocation = "All"
            --UIDropDownMenu_SetText(containerFrame.locationDropDown, initialLocation)
            UpdateHistoryByLocation(GetRealZoneText()) -- Update history for current location
            OnLocationDropDownSelect(nil, GetRealZoneText()) -- Manually trigger the initial selection
            
            -- UpdateHistory()
			--UpdateHistoryByLocation("All")
			containerFrame.historyFrame:Show()
			--titleBar:Show()  -- Show the title bar when the command is used
			--closeButton:Show()  -- Show the close button when the command is used
			--clearButton:Show()  -- Show the clear history button when the command is used
			--bgFrame:Show() -- Show the black frame when the command is used
			containerFrame.locationDropDown:Show()
            containerFrame:Show()
			containerFrame:EnableMouse(true)
		else 
			containerFrame.historyFrame:Hide()
			--titleBar:Hide()  -- Show the title bar when the command is used
			--closeButton:Hide()  -- Show the close button when the command is used
			--clearButton:Hide()  -- Show the clear history button when the command is used
			--bgFrame:Hide() -- Show the black frame when the command is used
			containerFrame.locationDropDown:Hide()
            containerFrame:Hide()
			containerFrame:EnableMouse(false)
		end
    elseif IsShiftKeyDown() and IsLeftAltKeyDown() and button == "RightButton" then
        --print("Shift Alt Right!") -- Debug
        ClearHistory()
    elseif IsShiftKeyDown() and button == "RightButton" then
        containerFrame:ClearAllPoints() -- Reset window position
        containerFrame:SetSize(450, 360)
        containerFrame:SetPoint("CENTER")
        --locationDropDown:ClearAllPoints() -- Reset window position
        --locationDropDown:SetPoint("TOPLEFT", containerFrame, "TOPLEFT", 120, 00)
        print("Secret button press detected! Window positions reset <3")
    elseif button == "RightButton" then
        -- Use the built-in /roll command for right-click
        RandomRoll(1, 100) -- Roll
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
    GameTooltip:AddLine("|cFFD3D3D3Shift + Alt + Right Click:|r Clear History")
    GameTooltip:Show()
end)

minimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


containerFrame:EnableMouse(false)