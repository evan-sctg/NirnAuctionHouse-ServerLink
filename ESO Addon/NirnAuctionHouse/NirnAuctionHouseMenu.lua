if not NirnAuctionHouse then return end

local NirnAuctionHouse = NirnAuctionHouse
local NirnAuctionHouseMenu = {}
NirnAuctionHouse.menu = NirnAuctionHouseMenu

NirnAuctionHouseMenu.EnabledTable = {
	"Enabled",
	"Disabled",
}

NirnAuctionHouseMenu.keyTable = {
	"None",
	"Shift",
	"Control",
	"Alt",
	"Command",
}

NirnAuctionHouseMenu.soundTable = {
	SOUNDS.BOOK_ACQUIRED,
	SOUNDS.ACHIEVEMENT_AWARDED,
	SOUNDS.FRIEND_REQUEST_ACCEPTED,
	SOUNDS.GUILD_SELF_JOINED,
}

function NirnAuctionHouseMenu:InitAddonMenu()
	local panelData = {
		type = "panel",
		name = "Nirn Auction House",
		displayName = NirnAuctionHouse.colors.title .. "Nirn Auction House|r",
		author = "Elo",
		version = "0.0.8",
		slashCommand = "/ahsetup",
		registerForRefresh = true
	}

	local optionsData = {
		{
			type = "dropdown",
			name = "Add Listings To Master Merchant",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AddListingsToMasterMerchant ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AddListingsToMasterMerchant = true else NAH.settings.AddListingsToMasterMerchant = false end  end,
			default = self.EnabledTable[2]
		},
--~ 		{
--~ 			type = "description",
--~ 			title = NirnAuctionHouse.colors.instructional .. "Average" .. NirnAuctionHouse.colors.default,
--~ 			text = "The average price of all items."
--~ 		},
--~ 		{
--~ 			type = "description",
--~ 			title = NirnAuctionHouse.colors.instructional .. "Median" .. NirnAuctionHouse.colors.default,
--~ 			text = "The price value for which half of the items cost more and half cost less."
--~ 		},
--~ 		{
--~ 			type = "description",
--~ 			title = NirnAuctionHouse.colors.instructional .. "Most Frequently Used (also known as Mode)" .. NirnAuctionHouse.colors.default,
--~ 			text = "The most common price value."
--~ 		},
--~ 		{
--~ 			type = "description",
--~ 			title = NirnAuctionHouse.colors.instructional .. "Weighted Average" .. NirnAuctionHouse.colors.default,
--~ 			text = "The average price of all items, with date taken into account. The latest data gets a wighting of X, where X is the number of days the data covers, thus making newest data worth more."
--~ 		},
--~ 		{
--~ 			type = "checkbox",
--~ 			name = "Show Min / Max Prices",
--~ 			tooltip = "Show minimum and maximum sell values",
--~ 			getFunc = function() return NirnAuctionHouse.settings.showMinMax end,
--~ 			setFunc = function(check) NirnAuctionHouse.settings.showMinMax = check end,
--~ 			default = true
--~ 		},
--~ 		{
--~ 			type = "checkbox",
--~ 			name = "Show 'Seen'",
--~ 			tooltip = "Show how many times an item was seen in the guild stores",
--~ 			getFunc = function() return NirnAuctionHouse.settings.showSeen end,
--~ 			setFunc = function(check) NirnAuctionHouse.settings.showSeen = check end,
--~ 			default = true
--~ 		},
--~ 		{
--~ 			type = "dropdown",
--~ 			name = "Show only if key is pressed",
--~ 			tooltip = "Show pricing on tooltip only if one of the following keys is pressed.  This is useful if you have too many addons modifying your tooltips.",
--~ 			choices = self.keyTable,
--~ 			getFunc = function() return NirnAuctionHouse.settings.keyPress or self.keyTable[1] end,
--~ 			setFunc = function(key) NirnAuctionHouse.settings.keyPress = key end,
--~ 			default = self.keyTable[1]
--~ 		},
--~ 		{
--~ 			type = "dropdown",
--~ 			name = "Limit results to a specific guild",
--~ 			tooltip = "Check pricing data from all guild, or a specific one",
--~ 			choices = self:GetGuildList(),
--~ 			getFunc = function() return self:GetGuildList()[NirnAuctionHouse.settings.limitToGuild or 1] end,
--~ 			setFunc = function(...) self:setLimitToGuild(...) end,
--~ 			default = self:GetGuildList()[1]
--~ 		},
--~ 		{
--~ 			type = "checkbox",
--~ 			name = "Ignore infrequent items",
--~ 			tooltip = "Ignore items that were seen only once or twice, as their price statistics may be inaccurate",
--~ 			getFunc = function() return NirnAuctionHouse.settings.ignoreFewItems end,
--~ 			setFunc = function(check) NirnAuctionHouse.settings.ignoreFewItems = check end,
--~ 			default = false
--~ 		},
--~ 		{
--~ 			type = "slider",
--~ 			name = "Keep item prices for (days):",
--~ 			tooltip = "Keep item prices for selected number of days. Older data will be automatically removed.",
--~ 			min = 7,
--~ 			max = 120,
--~ 			getFunc = function() return NirnAuctionHouse.settings.historyDays end,
--~ 			setFunc = function(days) NirnAuctionHouse.settings.historyDays = days end,
--~ 			default = 90
--~ 		},
--~ 		{
--~ 			type = "checkbox",
--~ 			name = "Audible notification",
--~ 			tooltip = "Play an audio notification when item scan is complete",
--~ 			getFunc = function() return NirnAuctionHouse.settings.isPlaySound end,
--~ 			setFunc = function(check) NirnAuctionHouse.settings.isPlaySound = check end,
--~ 			default = false
--~ 		},
--~ 		{
--~ 			type = "dropdown",
--~ 			name = "Sound type",
--~ 			tooltip = "Select which sound to play upon scan completion",
--~ 			choices = self.soundTable,
--~ 			getFunc = function() return NirnAuctionHouse.settings.playSound or self.soundTable[1] end,
--~ 			setFunc = function(value) NirnAuctionHouse.settings.playSound = value end,
--~ 			disabled = function() return not NirnAuctionHouse.settings.isPlaySound end,
--~ 			default = self.soundTable[1]
--~ 		},
	}

	local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel("NirnAuctionHouseOptions", panelData)
	LAM2:RegisterOptionControls("NirnAuctionHouseOptions", optionsData)
end

function NirnAuctionHouseMenu:IsKeyPressed()
--~ 	return NirnAuctionHouse.settings.keyPress == self.keyTable[1] or
--~ 		(NirnAuctionHouse.settings.keyPress == self.keyTable[2] and IsShiftKeyDown()) or
--~ 		(NirnAuctionHouse.settings.keyPress == self.keyTable[3] and IsControlKeyDown()) or
--~ 		(NirnAuctionHouse.settings.keyPress == self.keyTable[4] and IsAltKeyDown()) or
--~ 		(NirnAuctionHouse.settings.keyPress == self.keyTable[5] and IsCommandKeyDown())
end

--~ function NirnAuctionHouseMenu:GetGuildList()
--~ 	local guildList = {}
--~ 	guildList[1] = "All Guilds"
--~ 	for i = 1, GetNumGuilds() do
--~ 		guildList[i + 1] = GetGuildName(GetGuildId(i))
--~ 	end
--~ 	return guildList
--~ end

--~ function NirnAuctionHouseMenu:setLimitToGuild(guildName)
--~ 	local guildList = self:GetGuildList()
--~ 	for i, name in pairs(guildList) do
--~ 		if name == guildName then
--~ 			NirnAuctionHouse.settings.limitToGuild = i
--~ 			return
--~ 		end
--~ 	end
--~ 	-- Guild not found.  Default to 'All Guilds'
--~ 	NirnAuctionHouse.settings.limitToGuild = 1
--~ end

