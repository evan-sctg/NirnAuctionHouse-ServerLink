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
		version = "0.0.17",
		slashCommand = "/ahsetup",
		registerForRefresh = true
	}

	local optionsData = {
		{
			type = "checkbox",
			name = "Only show listings from active sellers",
			tooltip = "Hide trades where the seller does not have Server Link active",
			getFunc = function() return NAH.settings.ActiveSellersOnly end,
			setFunc = function(IsActiveSellersOnly) NAH.settings.ActiveSellersOnly = IsActiveSellersOnly end,
			default = false
		},
		{
			type = "checkbox",
			name = "Enable Server Link notification sounds",
			tooltip = "Allow Server Link to play notification sounds",
			getFunc = function() return NAH.settings.PlaySounds end,
			setFunc = function(DoPlaySounds) NAH.settings.PlaySounds = DoPlaySounds end,
			default = true
		},
		{
			type = "checkbox",
			name = "Enable Server Link notification on successful post Listing",
			tooltip = "Allow Server Link to play notification sounds when listings are successfully posted",
			getFunc = function() return NAH.settings.PlaySounds_success_listing end,
			setFunc = function(DoPlaySounds) NAH.settings.PlaySounds_success_listing = DoPlaySounds end,
			default = false
		},
		{
			type = "checkbox",
			name = "Enable Server Link notification on successful Buyout or Bid",
			tooltip = "Allow Server Link to play notification sounds on successfull Buyout or Bid",
			getFunc = function() return NAH.settings.PlaySounds_success_buy end,
			setFunc = function(DoPlaySounds) NAH.settings.PlaySounds_success_buy = DoPlaySounds end,
			default = false
		},
		{
			type = "checkbox",
			name = "Enable Server Link notification on successful cancel listings",
			tooltip = "Allow Server Link to play notification sounds on successfully canceling listings",
			getFunc = function() return NAH.settings.PlaySounds_success_cancel end,
			setFunc = function(DoPlaySounds) NAH.settings.PlaySounds_success_cancel = DoPlaySounds end,
			default = false
		},
		{
			type = "dropdown",
			name = "Show Master Merchant price In auction window",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.ShowMasterMerchantPrice ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.ShowMasterMerchantPrice = true else NAH.settings.ShowMasterMerchantPrice = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Add Listings To Master Merchant",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AddListingsToMasterMerchant ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AddListingsToMasterMerchant = true else NAH.settings.AddListingsToMasterMerchant = false end  end,
			default = self.EnabledTable[2]
		}
		
	}

	local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel("NirnAuctionHouseOptions", panelData)
	LAM2:RegisterOptionControls("NirnAuctionHouseOptions", optionsData)
end

