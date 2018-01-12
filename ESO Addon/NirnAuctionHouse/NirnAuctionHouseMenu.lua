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
		version = "0.0.19",
		slashCommand = "/ahsetup",
		registerForRefresh = true
	}

	local optionsData = {
		{
			type = "editbox",
			name = "Notification Email",
			tooltip = "Optional Email for Auction Notifications (Verification Link sent via Email)",
			getFunc = function() return NAH.settings.NotificationEmail end,
			setFunc = function(textNotificationEmail) NAH.settings.NotificationEmail = textNotificationEmail end,
			default = ""
		},
		{
			type = "checkbox",
			name = "Notify Sold Items",
			tooltip = "Notify you by Email when items are sold",
			getFunc = function() return NAH.settings.NotifySold end,
			setFunc = function(IsNotifySold) NAH.settings.NotifySold = IsNotifySold end,
			default = false
		},
		{
			type = "checkbox",
			name = "Notify Payment Recieved",
			tooltip = "Notify you by Email when payments are recieved for orders",
			getFunc = function() return NAH.settings.NotifyPaymentRecieved end,
			setFunc = function(IsNotifyPaymentRecieved) NAH.settings.NotifyPaymentRecieved = IsNotifyPaymentRecieved end,
			default = false
		},
		{
			type = "checkbox",
			name = "Notify Items Recieved",
			tooltip = "Notify you by Email when items are recieved",
			getFunc = function() return NAH.settings.NotifyOrderRecieved end,
			setFunc = function(IsNotifyOrderRecieved) NAH.settings.NotifyOrderRecieved = IsNotifyOrderRecieved end,
			default = false
		},
		{
			type = "checkbox",
			name = "Notify Order Expired",
			tooltip = "Notify you by Email when orders expire",
			getFunc = function() return NAH.settings.NotifyExpired end,
			setFunc = function(IsNotifyExpired) NAH.settings.NotifyExpired = IsNotifyExpired end,
			default = false
		},
		{
			type = "checkbox",
			name = "Hide main NAH button",
			tooltip = "Hides main Nirn Auction House button and serverlink warning",
			getFunc = function() return NAH.settings.HideInterface end,
			setFunc = function(IsHideInterface) 
			 if IsHideInterface then
			 NAH.settings.HideInterface=true
			NirnAuctionHouse_HideBtns();
			 else
			NAH.settings.HideInterface=false
			NirnAuctionHouse_ShowBtns( );
			 end
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Hide NAH Inventory Badges",
			tooltip = "Hides Nirn Auction House for sale Badges in Inventory",
			getFunc = function() return NAH.settings.HideInventoryBadges end,
			setFunc = function(IsHideInventoryBadges) 
			NAH.settings.HideInventoryBadges=IsHideInventoryBadges 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Hide NAH Craft Bag Badges",
			tooltip = "Hides Nirn Auction House for sale Badges in Craft Bag",
			getFunc = function() return NAH.settings.HideCraftBagBadges end,
			setFunc = function(IsHideCraftBagBadges) 
			NAH.settings.HideCraftBagBadges=IsHideCraftBagBadges 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Hide NAH Bank Badges",
			tooltip = "Hides Nirn Auction House for sale Badges in Bank",
			getFunc = function() return NAH.settings.HideBankBadges end,
			setFunc = function(IsHideBankBadges) 
			NAH.settings.HideBankBadges=IsHideBankBadges 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Hide NAH Guild Bank Badges",
			tooltip = "Hides Nirn Auction House for sale Badges in Guild Bank",
			getFunc = function() return NAH.settings.HideGuildBankBadges end,
			setFunc = function(IsHideGuildBankBadges) 
			NAH.settings.HideGuildBankBadges=IsHideGuildBankBadges 
			end,
			default = false
		},
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
			name = "Set default price to sell price + COD cost when listing auctions",
			tooltip = "Prefill buyout with sell price + COD",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AddCODCost ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AddCODCost = true else NAH.settings.AddCODCost = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Show My Player Name on orders to fulfill",
			tooltip = "display what player sold the item on fulfill window",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.ShowMyCharName ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.ShowMyCharName = true else NAH.settings.ShowMyCharName = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post buyout orders",
			tooltip = "Disable to manually sync buyout orders(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostBuyouts ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostBuyouts = true else NAH.settings.AutoPostBuyouts = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post Paid COD orders",
			tooltip = "Disable to manually sync paid cod orders(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostPaid ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostPaid = true else NAH.settings.AutoPostPaid = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post fulfilled orders",
			tooltip = "Disable to manually sync fulfilled orders(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostFilled ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostFilled = true else NAH.settings.AutoPostFilled = false end  end,
			default = self.EnabledTable[2]
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
		},
		{
			type = "dropdown",
			name = "Server side listing limit",
			tooltip = "Server side listing limit",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.ServerSideListingLimits ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.ServerSideListingLimits = true else NAH.settings.ServerSideListingLimits = false end  end,
			default = self.EnabledTable[2]
		}
		
	}

	local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel("NirnAuctionHouseOptions", panelData)
	LAM2:RegisterOptionControls("NirnAuctionHouseOptions", optionsData)
end

