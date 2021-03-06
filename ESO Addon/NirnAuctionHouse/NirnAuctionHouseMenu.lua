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
		version = "0.0.37",
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
			name = "Always show NAH HUD",
			tooltip = "Shows Nirn Auction House heads up display even when not in bank or mail",
			getFunc = function() return NAH.settings.AlwaysNAH_HUD end,
			setFunc = function(IsAlwaysNAH_HUD) 
			NAH.settings.AlwaysNAH_HUD=IsAlwaysNAH_HUD 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Disable Mail NAH HUD",
			tooltip = "Disables Nirn Auction House heads up display when in mail",
			getFunc = function() return NAH.settings.DisableNAH_HUD_Mail end,
			setFunc = function(IsDisableNAH_HUD_Mail) 
			NAH.settings.DisableNAH_HUD_Mail=IsDisableNAH_HUD_Mail 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Disable Bank NAH HUD",
			tooltip = "Disables Nirn Auction House heads up display when in bank",
			getFunc = function() return NAH.settings.DisableNAH_HUD_Bank end,
			setFunc = function(IsDisableNAH_HUD_Bank) 
			NAH.settings.DisableNAH_HUD_Bank=IsDisableNAH_HUD_Bank 
			end,
			default = false
		},
		{
			type = "checkbox",
			name = "Disable Guild Bank NAH HUD",
			tooltip = "Disables Nirn Auction House heads up display when in guild bank",
			getFunc = function() return NAH.settings.DisableNAH_HUD_GuildBank end,
			setFunc = function(IsDisableNAH_HUD_GuildBank) 
			NAH.settings.DisableNAH_HUD_GuildBank=IsDisableNAH_HUD_GuildBank 
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
			name = "Hide FAQ notice in the order tab ( WTB )",
			tooltip = "Hides FAQ notice in the order tab ( WTB ) - how to place orders",
			getFunc = function() return NAH.settings.HideFAQNoticeWTB end,
			setFunc = function(IsHideFAQNoticeWTB) 
			NAH.settings.HideFAQNoticeWTB=IsHideFAQNoticeWTB
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
			name = "Auto Retrieve from Craft Bag",
			tooltip = "automatically retrieve items from craft bag for filling orders",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoRetrieveCraftBag ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoRetrieveCraftBag = true else NAH.settings.AutoRetrieveCraftBag = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Lock Item when listing",
			tooltip = "Locks items that are lockable (prevents vendoring, trading and deconstruction)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoLockItems ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoLockItems = true else NAH.settings.AutoLockItems = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Unlock Item when filling order",
			tooltip = "Unocks items that are locked when filling orders",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoUnLockItems ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoUnLockItems = true else NAH.settings.AutoUnLockItems = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post new auctions",
			tooltip = "Disable to manually sync new auctions(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostNewAuctions ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostNewAuctions = true else NAH.settings.AutoPostNewAuctions = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post bids",
			tooltip = "Disable to manually sync bids(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostBids ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostBids = true else NAH.settings.AutoPostBids = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post new wtb orders",
			tooltip = "Disable to manually sync new wtb orders(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostNewWTB ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostNewWTB = true else NAH.settings.AutoPostNewWTB = false end  end,
			default = self.EnabledTable[2]
		},
		{
			type = "dropdown",
			name = "Auto Post Canceled orders",
			tooltip = "Disable to manually sync Canceled orders(queue multiple)",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.AutoPostCanceled ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.AutoPostCanceled = true else NAH.settings.AutoPostCanceled = false end  end,
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
			name = "Show TTC price In auction window",
			choices = self.EnabledTable,
			getFunc = function() if NAH.settings.ShowTTCPrice ==true then return "Enabled" else return "Disabled" end end,
			setFunc = function(isEnabled) if isEnabled =="Enabled" then NAH.settings.ShowTTCPrice = true else NAH.settings.ShowTTCPrice = false end  end,
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
		},
		{
			type = "checkbox",
			name = "Enable Hot Key Labels on Keybind Strip",
			tooltip = "Displays the Nirn Aucion House Hot keys on Keybind Strip ( bottom of screen ) [resync to apply]",
			getFunc = function() return NAH.settings.EnableHotKeyStrip end,
			setFunc = function(DoEnableHotKeyStrip) NAH.settings.EnableHotKeyStrip = DoEnableHotKeyStrip end,
			default = false
		}
		
	}

	local LAM2 = LibStub:GetLibrary("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel("NirnAuctionHouseOptions", panelData)
	LAM2:RegisterOptionControls("NirnAuctionHouseOptions", optionsData)
end

