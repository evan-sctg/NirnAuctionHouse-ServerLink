-- ------------- --
-- NirnAuctionHouse --
-- ------------- --




if NAH == nil then NAH = {} end
NAH.ServerLinkVersionRequired="0.0.0.21";
NirnAuctionHouse = {
	TrackedPriceHistoryYet = false,
	BuildRows_delay = 50,--inital delay between building rows
	BuildRows_delayMax = 50,--inital delay between building rows
	TrackedPriceHistory_delay = 3,--inital delay between price tracked
	TrackedPriceHistory_delayInt = 1,--how many seconds to add on that for each price tracke
	isSearching = false,
	sortType = 1,
	myListingsNum = 0,
	myListingsMax = 80,
	--settingsVersion = "0.0.0.1",
	colors = {
		default = "|c" .. ZO_TOOLTIP_DEFAULT_COLOR:ToHex(),
		instructional = "|c" .. ZO_TOOLTIP_INSTRUCTIONAL_COLOR:ToHex(),
		title = "|c00B5FF",
		health  = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER, POWERTYPE_HEALTH)),
		magicka = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER, POWERTYPE_MAGICKA)),
		stamina = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_POWER, POWERTYPE_STAMINA)),
		violet  = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_ARTIFACT)),
		gold    = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, ITEM_QUALITY_LEGENDARY)),
		brown   = ZO_ColorDef:New("885533"),
		teal    = ZO_ColorDef:New("66CCCC"),
		pink    = ZO_ColorDef:New("FF99CC"),
	},
	selectedItem = {},
}
local NirnAuctionHouse = NirnAuctionHouse

		
	
	local defaults = {
	}


	local defaultSettings = {
		settingsVersion = "0.0.0.1",
		ActiveAccount = "",
		ActiveCharacterId = "0",
		CurCharacterId = "0",
		OpenAuctionWindow = false,
		OpenOrdersWindow = false,
		OpenTrackedOrdersWindow = false,
		ReloadingUI = false,
		ReloadTradeData = false,
		ReloadTradeDataTracked = false,
		PostListings = false,
		PostBids = false,
		PostFilledOrders = false,
		PostPaidOrders = false,
		AddListingsToMasterMerchant = false,
		ShowMasterMerchantPrice = true,
		AutoPost = false,
		ServerLink_INITIATED = false,
		ActiveSellersOnly = false,
		PlaySounds = true,
		PlaySounds_success_listing = false,
		PlaySounds_success_buy = false,
		PlaySounds_success_cancel = false,
		ActiveTab = "",
		NAHBTN_LEFT = false,
		NAHBTN_TOP = false,
		
	data = {
		PaidOrders = {},
		ReceivedOrders = {},
		FilledOrders = {},
		Listings = {},
		Bids = {},
		SearchSettings = {
		searchType = 1,
		CurrentFilterId = 1,
		CurrentFilterSubId = 1,
		CurrentFilterCraftingId = 1,
		CurrentFilterSlotId = 1,
		CurrentFilterTraitId = 1,
		CurrentFilterEnchId = 1,
		PriceMin = 0,
		PriceMax = 0,
		LevelMin = 0,
		LevelMax = 0,
		LevelRangeTypeId = 1,
		QualityId = 1,
		CurrentSearch = "",
		PerPage = 10,
		Page = 1,
		NumResults = 0
		},
		OfferedBids = {},
		AvailableBids = {}
	}
		
		
	}

	
	
	


NAHAuctionList = ZO_SortFilterList:Subclass();
NAHSoldItemList = ZO_SortFilterList:Subclass();
NAHTrackedItemList = ZO_SortFilterList:Subclass();



function NAHTrackedItemList:New( control )
	local list = ZO_SortFilterList.New(self, control);
	list.frame = control;
	list:Setup();
--~ 	return(list);
	return(self);
end
function NAHTrackedItemList:BuildMasterList( )
	self.masterList = { };
	
	if NirnAuctionHouse.TrackedBids~= nil then
	for i,GlobalBid in ipairs(NirnAuctionHouse.TrackedBids) do
	table.insert(self.masterList, NirnAuctionHouse.CreateEntryFromRaw(GlobalBid));
	end
	end
end


function NAHTrackedItemList:FilterScrollList( )
	local scrollData = ZO_ScrollList_GetDataList(self.list);
	ZO_ClearNumericallyIndexedTable(scrollData);
	for i = 1, #self.masterList do
		local data = self.masterList[i];
	table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data));		
	end

	if (#scrollData ~= #self.masterList) then
		self.frame:GetNamedChild("Counter"):SetText(string.format("%d / %d", #scrollData, #self.masterList));
	else		
		self.frame:GetNamedChild("Counter"):SetText("");
	end
end



function NAHTrackedItemList:Setup( )
	ZO_ScrollList_AddDataType(self.list, 1, "NAHOrderRow", 60, function(control, data) self:SetupItemRow(control, data) end);
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight");
	self:SetAlternateRowBackgrounds(true);

	self.masterList = { };

	local sortKeys = {
		["name"]     = { caseInsensitive = true, tiebreaker = "price" },
		["BuyoutPrice"] = { caseInsensitive = true },
		["TimeLeft"] = { caseInsensitive = true },
		["stackCount"] = { caseInsensitive = true, tiebreaker = "name" },
		["TradeIsBidder"] = { caseInsensitive = true, tiebreaker = "name" },
	};

	self.currentSortKey = "name";
	self.currentSortOrder = ZO_SORT_ORDER_UP;
	self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey);
	self.sortFunction = function( listEntry1, listEntry2 )

		return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, sortKeys, self.currentSortOrder));
	
	end
	

	NirnAuctionHouse.scene = ZO_Scene:New("NAHSceneTrackedOrders", SCENE_MANAGER);
	NirnAuctionHouse.scene:AddFragment(ZO_SetTitleFragment:New(""));
	NirnAuctionHouse.scene:AddFragment(ZO_FadeSceneFragment:New(NAHAuctionHouseTrackingPanel));
	NirnAuctionHouse.scene:AddFragment(TITLE_FRAGMENT);
	NirnAuctionHouse.scene:AddFragment(RIGHT_BG_FRAGMENT);
	NirnAuctionHouse.scene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL);
	NirnAuctionHouse.scene:AddFragment(CODEX_WINDOW_SOUNDS);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL);
	

	self:RefreshData();
end
	

function NAHTrackedItemList:SetupItemRow( control, data )
	control.data = data;

	control:GetNamedChild("Icon"):SetTexture(data.Icon)
	control:GetNamedChild("Price").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Price"):SetText(data.BuyoutPrice);

	local itemqualColor=GetItemQualityColor(data.ItemQuality);
	control:GetNamedChild("Name").normalColor = itemqualColor;
	control:GetNamedChild("Name").mouseOverColor = itemqualColor;
	if data.TradeIsBidder=="true"  then
		if data.TradeIsHighestBid=="true" then
		control:GetNamedChild("IsBuyout"):SetText("HIGHEST BIDDER" );	 
		else
		control:GetNamedChild("IsBuyout"):SetText("OUTBID" );		
		end
		
	
	control:GetNamedChild("TimeLeft").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("TimeLeft"):SetText(data.TimeLeft);	
	if data.TimeLeft == "Complete" then
		control:GetNamedChild("IsBuyout"):SetText("Waiting on Seller");	
	end
	
	else
		control:GetNamedChild("IsBuyout"):SetText("Waiting on Seller");	
		
	
	control:GetNamedChild("TimeLeft").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("TimeLeft"):SetText("Complete");
	end
	control:GetNamedChild("Name"):SetText(data.name);	

	control:GetNamedChild("Qty").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Qty"):SetText(data.stackCount);
	
	control:GetNamedChild("Confirm"):SetHidden(true);	

	ZO_SortFilterList.SetupRow(self, control, data);
end


function NAHTrackedItemList:SortScrollList( )
	if self.initiatedAlready then
	NAH.settings.data.SearchSettings.currentSortKey_sold=self.currentSortKey;
	NAH.settings.data.SearchSettings.currentSortOrder=self.currentSortOrder;
	else
	self.initiatedAlready=true
	end

	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
		local scrollData = ZO_ScrollList_GetDataList(self.list);
--~ 		if (scrollData~=nil) then
		table.sort(scrollData, self.sortFunction);
--~ 		end
	end

	self:RefreshVisible();
end







function NAHSoldItemList:New( control )
	local list = ZO_SortFilterList.New(self, control);
	list.frame = control;
	list:Setup();
	return(self);
end
function NAHSoldItemList:BuildMasterList( )
	self.masterList = { };
	if NirnAuctionHouse.NewBids~= nil then
	for i,GlobalBid in ipairs(NirnAuctionHouse.NewBids) do
	local rowdata=NirnAuctionHouse.CreateEntryFromRaw(GlobalBid)
	table.insert(self.masterList,rowdata );
	
		if(NirnAuctionHouse.list.MyListedTrades~=nil)then
		rowdata.IsSoldItem=true
		table.insert(NirnAuctionHouse.list.MyListedTrades, rowdata);
		end
	end
	end
end


function NAHSoldItemList:FilterScrollList( )
	local scrollData = ZO_ScrollList_GetDataList(self.list);
	ZO_ClearNumericallyIndexedTable(scrollData);
	for i = 1, #self.masterList do
		local data = self.masterList[i];
	table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data));		
	end

	if (#scrollData ~= #self.masterList) then
		self.frame:GetNamedChild("Counter"):SetText(string.format("%d / %d", #scrollData, #self.masterList));
	else
		self.frame:GetNamedChild("Counter"):SetText("");
	end
end



function NAHSoldItemList:Setup( )
	ZO_ScrollList_AddDataType(self.list, 1, "NAHOrderRow", 60, function(control, data) self:SetupItemRow(control, data) end);
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight");
	self:SetAlternateRowBackgrounds(true);

	self.masterList = { };

	local sortKeys = {
		["name"]     = { caseInsensitive = true, tiebreaker = "price" },
		["TimeLeft"] = { caseInsensitive = true },
		["BuyoutPrice"] = { caseInsensitive = true },
		["stackCount"] = { caseInsensitive = true, tiebreaker = "name" },
		["TradeIsBidder"] = { caseInsensitive = true, tiebreaker = "name" },
	};

	self.currentSortKey = "name";
	self.currentSortOrder = ZO_SORT_ORDER_UP;
	self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey);
	self.sortFunction = function( listEntry1, listEntry2 )
		return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, sortKeys, self.currentSortOrder));
	end
	

	NirnAuctionHouse.scene = ZO_Scene:New("NAHSceneOrders", SCENE_MANAGER);
	NirnAuctionHouse.scene:AddFragment(ZO_SetTitleFragment:New(""));
	NirnAuctionHouse.scene:AddFragment(ZO_FadeSceneFragment:New(NAHAuctionHouseOrdersPanel));
	NirnAuctionHouse.scene:AddFragment(TITLE_FRAGMENT);
	NirnAuctionHouse.scene:AddFragment(RIGHT_BG_FRAGMENT);
	NirnAuctionHouse.scene:AddFragment(FRAME_EMOTE_FRAGMENT_JOURNAL);
	NirnAuctionHouse.scene:AddFragment(CODEX_WINDOW_SOUNDS);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL);
	

	self:RefreshData();
end
	

function NAHSoldItemList:SetupItemRow( control, data )
	control.data = data;

	control:GetNamedChild("Icon"):SetTexture(data.Icon)
	control:GetNamedChild("Price").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Price"):SetText(data.BuyoutPrice);
	local itemqualColor=GetItemQualityColor(data.ItemQuality);
	control:GetNamedChild("Name").normalColor = itemqualColor;
	control:GetNamedChild("Name").mouseOverColor = itemqualColor;
--~ 	d("TradeIsBidder: " ..data.TradeIsBidder);
	if data.TradeIsBidder=="true" then
	control:GetNamedChild("IsBuyout"):SetText("HIGH BID" );		
	control:GetNamedChild("TimeLeft").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("TimeLeft"):SetText(data.TimeLeft); 
	else
		control:GetNamedChild("IsBuyout"):SetText("BUYOUT");	
	end
	
	
		local codcost=10+math.floor(data.BuyoutPrice/20)
	control:GetNamedChild("TimeLeft").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("TimeLeft"):SetText(codcost);
	
	control:GetNamedChild("Name"):SetText(data.name);	

	control:GetNamedChild("Qty").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Qty"):SetText(data.stackCount);
	
	control:GetNamedChild("Confirm")

	ZO_SortFilterList.SetupRow(self, control, data);
end


function NAHSoldItemList:SortScrollList( )
	if self.initiatedAlready then
	NAH.settings.data.SearchSettings.currentSortKey_sold=self.currentSortKey;
	NAH.settings.data.SearchSettings.currentSortOrder=self.currentSortOrder;
	else
	self.initiatedAlready=true
	end

	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then
		local scrollData = ZO_ScrollList_GetDataList(self.list);
		table.sort(scrollData, self.sortFunction);
	end

	self:RefreshVisible();
end




function NAHAuctionList:New( control )
	local list = ZO_SortFilterList.New(self, control);
	local MyListedTrades={};
	list.frame = control;
	list:Setup();
	return(list);
end

local function NAH_FilterChanged(control, choiceText, choice)
	choice.control:UpdateValue(false, choiceText)
end

local function UpdateValue(control, forceDefault, value)
	if forceDefault then	
		value = LAM.util.GetDefaultValue(control.data.default)
		control.data.setFunc(value)
		control.dropdown:SetSelectedItem(value)
	elseif value then
		control.data.setFunc(value)
		if control.panel.data.registerForRefresh then
			cm:FireCallbacks("LAM-RefreshPanel", control)
		end
	else
		value = control.data.getFunc()
		control.dropdown:SetSelectedItem(value)
	end
end

local function UpdateChoices(control, choices)
	control.dropdown:ClearItems()
	local choices = choices or control.data.choices
	for i = 1, #choices do
		local entry = control.dropdown:CreateItemEntry(choices[i], NAH_FilterChanged)
		entry.control = control
		control.dropdown:AddItem(entry, not control.data.sort and ZO_COMBOBOX_SUPRESS_UPDATE)	--if sort type/order isn't specified, then don't sort
	end
end

function NAHAuctionList:Setup( )
	ZO_ScrollList_AddDataType(self.list, 1, "NAHRow", 60, function(control, data) self:SetupItemRow(control, data) end);
	ZO_ScrollList_EnableHighlight(self.list, "ZO_ThinListHighlight");
	self:SetAlternateRowBackgrounds(true);

	self.masterList = { };

	local sortKeys = {
		["name"]     = { caseInsensitive = true },
		["stackCount"]     = { caseInsensitive = true },
		["TimeLeft"]     = { caseInsensitive = true },
		["StartingPrice"] = { caseInsensitive = true},
		["BuyoutPrice"] = { caseInsensitive = true },
		["itemType"] = { caseInsensitive = true },
	};

	self.currentSortKey = "name";
	self.currentSortOrder = ZO_SORT_ORDER_UP;
	self.sortHeaderGroup:SelectAndResetSortForKey(self.currentSortKey);
	self.sortFunction = function( listEntry1, listEntry2 )
		return(ZO_TableOrderingFunction(listEntry1.data, listEntry2.data, self.currentSortKey, sortKeys, self.currentSortOrder));
	end
	self.masterListSortFunction = function( listEntry1, listEntry2 )
		return(ZO_TableOrderingFunction(listEntry1, listEntry2, self.currentSortKey, sortKeys, self.currentSortOrder));
	end
	self.filterDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDrop"));	
	self:InitializeComboBox(self.filterDrop, "SI_NAH_FILTERDROP", 20);
	

	self.searchDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("SearchDrop"));
	self:InitializeComboBox(self.searchDrop, "SI_NAH_SEARCHDROP", 3);

	self.filterDropSub = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDropSub"));	
	self:InitializeComboBox(self.filterDropSub, "SI_NAH_FILTERDROPSUB_1_", 15);
	
	
	self.filterDropSlot = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDropSlot"));	
	self:InitializeComboBox(self.filterDropSlot, "SI_NAH_FILTERDROPSUB_1_", 15);
	
	
	self.filterDropEnch = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDropEnch"));	
	self:InitializeComboBox(self.filterDropEnch, "SI_NAH_FILTERDROPSUB_1_", 15);
	
	
	self.filterDropTrait = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDropTrait"));	
	self:InitializeComboBox(self.filterDropTrait, "SI_NAH_FILTERDROPSUB_1_", 15);
	
	
	self.filterDropCrafting = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("FilterDropCrafting"));	
	self:InitializeComboBox(self.filterDropCrafting, "SI_NAH_FILTERDROPSUB_1_", 15);
	
	
	
	
	

	self.PriceMinBox = self.frame:GetNamedChild("PriceMinBox");
	self.PriceMinBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end);
	
	

	self.PriceMaxBox = self.frame:GetNamedChild("PriceMaxBox");
	self.PriceMaxBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end);
	
	

	self.LevelMinBox = self.frame:GetNamedChild("LevelMinBox");
	self.LevelMinBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end);
	
	
	
	self.LevelMaxBox = self.frame:GetNamedChild("LevelMaxBox");
	self.LevelMaxBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end);
	
	
	
	self.QualityDrop = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("QualityDrop"));
	self:InitializeComboBox(self.QualityDrop, "SI_NAH_QUALITYDROP", 6);
	
	
	

	self.LevelRangeType = ZO_ComboBox_ObjectFromContainer(self.frame:GetNamedChild("LevelRangeType"));
	self:InitializeComboBox(self.LevelRangeType, "SI_NAH_LEVELDROP", 3);
	


	self.searchBox = self.frame:GetNamedChild("SearchBox");
	self.searchBox:SetHandler("OnTextChanged", function() self:RefreshFilters() end);
	
	self.search = ZO_StringSearch:New();
	self.search:AddProcessor(NirnAuctionHouse.sortType, function(stringSearch, data, searchTerm, cache) return(self:ProcessItemEntry(stringSearch, data, searchTerm, cache)) end);

	NirnAuctionHouse.scene = ZO_Scene:New("NAHScene", SCENE_MANAGER);
	NirnAuctionHouse.scene:AddFragment(ZO_SetTitleFragment:New(""));
	NirnAuctionHouse.scene:AddFragment(ZO_FadeSceneFragment:New(NirnAuctionHousePanel));
	NirnAuctionHouse.scene:AddFragment(TITLE_FRAGMENT);
	NirnAuctionHouse.scene:AddFragment(CODEX_WINDOW_SOUNDS);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW);
	NirnAuctionHouse.scene:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_STANDARD_RIGHT_PANEL);
	

	self:RefreshData();
end
	

function NirnAuctionHouse:CheckIsItemListedAlready(MyListedTrade,ItemID, stackCount,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
	if (tonumber(MyListedTrade.ItemID)==tonumber(ItemID) and tonumber(MyListedTrade.stackCount)==tonumber(stackCount)) and (tonumber(MyListedTrade.ItemQuality)==tonumber(itemQuality)) and (tonumber(sellPrice)==tonumber(GetItemLinkValue(MyListedTrade.itemLink,true))) then
		if (MyListedTrade.requiredLevel==requiredLevel) and  (MyListedTrade.requiredChampPoints==requiredChampPoints) and  (MyListedTrade.abilityHeader==ability) and (MyListedTrade.enchantHeader==enchant) and (MyListedTrade.traitType==trait) then
		return MyListedTrade;
		end
	end	
	return false;
end

function NirnAuctionHouse:IsItemListedAlready(ItemID, stackCount,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
	local result
	if(NirnAuctionHouse.list.MyListedTrades~=nil) then
		for i,MyListedTrade in ipairs(NirnAuctionHouse.list.MyListedTrades) do
		result =NirnAuctionHouse:CheckIsItemListedAlready(MyListedTrade,ItemID, stackCount,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
		if(result~=nil and result~=false and result.TradeID~=nil and result.TradeID~=false)then	return result;	end
		end
	end		
	return false;
end

function NirnAuctionHouse:CheckIsItemListedCnt(MyListedTrade,ItemID,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
local stackCount=0;
	if (tonumber(MyListedTrade.ItemID)==tonumber(ItemID)) and (tonumber(MyListedTrade.ItemQuality)==tonumber(itemQuality)) and (tonumber(sellPrice)==tonumber(GetItemLinkValue(MyListedTrade.itemLink,true))) then
		if (MyListedTrade.requiredLevel==requiredLevel) and  (MyListedTrade.requiredChampPoints==requiredChampPoints) and  (MyListedTrade.abilityHeader==ability) and (MyListedTrade.enchantHeader==enchant) and (MyListedTrade.traitType==trait) then
		stackCount=tonumber(MyListedTrade.stackCount)
		end
	end
	return stackCount;
end

function NirnAuctionHouse:IsItemListedCnt(ItemID,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
local stackCount=0;
	if(NirnAuctionHouse.list.MyListedTrades~=nil) then
		for i,MyListedTrade in ipairs(NirnAuctionHouse.list.MyListedTrades) do
		stackCount=stackCount+NirnAuctionHouse:CheckIsItemListedCnt(MyListedTrade,ItemID,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,enchant,ability,trait)
		end
	end
	return stackCount;
end
	
function NAHAuctionList:BuildMasterList( )
	self.masterList = { };
	self.MyListedTrades = { };
	if NAH.settings.ActiveAccount== nil or NAH.settings.ActiveAccount=="" then
	NAH.currentAccount = GetDisplayName()
	NAH.settings.ActiveAccount=NAH.currentAccount
	end
		if NirnAuctionHouse.GlobalTrades~= nil then
		for i,GlobalTrade in ipairs(NirnAuctionHouse.GlobalTrades) do
		local rowdata=NirnAuctionHouse.CreateEntryFromRaw(GlobalTrade);
		table.insert(self.masterList, rowdata);
			if (rowdata.source==NAH.settings.ActiveAccount) then
			rowdata.IsSoldItem=false
			table.insert(self.MyListedTrades, rowdata);
			end
		end
	end
end

function NAHAuctionList:FilterScrollList( )
	local scrollData = ZO_ScrollList_GetDataList(self.list);
	ZO_ClearNumericallyIndexedTable(scrollData);
	
	if NAH.settings.data.SearchSettings.PageChange ~=true then 
	NAH.settings.data.SearchSettings.Page=1
	else
	NAH.settings.data.SearchSettings.PageChange=false
		TrackedPriceHistoryYet = false
		TrackedPriceHistory_delay=3
	end
	
	if NAH.settings.data.SearchSettings.Page== nil then NAH.settings.data.SearchSettings.Page=1 end
	NAH.settings.data.SearchSettings.PerPage=10
--~ 	if NAH.settings.data.SearchSettings.PerPage== nil then NAH.settings.data.SearchSettings.PerPage=10 end
	
	NirnAuctionHouse.myListingsNum=0;
	local numResults=0;
	local numResultMax=NAH.settings.data.SearchSettings.Page*NAH.settings.data.SearchSettings.PerPage;
	local numResultMin=numResultMax-NAH.settings.data.SearchSettings.PerPage+1;
	
	
	
	
	local filterId ,filterText, filterSubText, filterSubId, filterENCHId ,filterTRAITId, filterSLOTId ,filterCraftingId, filterCraftingText, searchInput, minprice, maxprice, minlevel, maxlevel, filterQualityId, LevelRangeTypeId
	
--~ 	local filterIds = {[]=,};

		if(self.searchDrop~=nil)then self.searchType = self.searchDrop:GetSelectedItemData().id; else self.searchType = NAH.settings.data.SearchSettings.searchType end

		if(self.filterDrop~=nil)then  filterId = self.filterDrop:GetSelectedItemData().id; else filterId = NAH.settings.data.SearchSettings.CurrentFilterId end
		if(self.filterDropSub~=nil)then  filterSubId = self.filterDropSub:GetSelectedItemData().id; else filterSubId = NAH.settings.data.SearchSettings.CurrentFilterSubId end
		
		if(self.filterDropEnch~=nil)then  filterENCHId = self.filterDropEnch:GetSelectedItemData().id; else filterENCHId = NAH.settings.data.SearchSettings.CurrentFilterEnchId end
		if(self.filterDropTrait~=nil)then  filterTRAITId = self.filterDropTrait:GetSelectedItemData().id; else filterTRAITId = NAH.settings.data.SearchSettings.CurrentFilterTraitId end
		if(self.filterDropSlot~=nil)then  filterSLOTId = self.filterDropSlot:GetSelectedItemData().id; else filterSLOTId = NAH.settings.data.SearchSettings.CurrentFilterSlotId end
		if(self.filterDropCrafting~=nil)then  filterCraftingId = self.filterDropCrafting:GetSelectedItemData().id; else filterCraftingId = NAH.settings.data.SearchSettings.CurrentFilterCraftingId end
	
	
	
		if(self.searchBox~=nil)then  searchInput = self.searchBox:GetText(); else searchInput = NAH.settings.data.SearchSettings.CurrentSearch end
	
		if(self.PriceMinBox~=nil)then  minprice = tonumber(self.PriceMinBox:GetText()); else minprice = tonumber(NAH.settings.data.SearchSettings.PriceMin) end
		if(self.PriceMaxBox~=nil)then  maxprice = tonumber(self.PriceMaxBox:GetText()); else maxprice = tonumber(NAH.settings.data.SearchSettings.PriceMax) end
		if(self.LevelMinBox~=nil)then  minlevel = tonumber(self.LevelMinBox:GetText()); else minlevel = tonumber(NAH.settings.data.SearchSettings.LevelMin) end
		if(self.LevelMaxBox~=nil)then  maxlevel = tonumber(self.LevelMaxBox:GetText()); else maxlevel = tonumber(NAH.settings.data.SearchSettings.LevelMax) end

	
	if(self.QualityDrop~=nil)then  filterQualityId = self.QualityDrop:GetSelectedItemData().id; else filterQualityId = NAH.settings.data.SearchSettings.QualityId end
	
--
	
	
	if(self.LevelRangeType~=nil)then  LevelRangeTypeId = self.LevelRangeType:GetSelectedItemData().id; else LevelRangeTypeId = NAH.settings.data.SearchSettings.LevelRangeTypeId end

	
	if NAH.settings.data.SearchSettings ==nil then
	NAH.settings.data.SearchSettings={}
	end
	

	
	
	
	
	
	
	--if sub category changes
	if (NAH.settings.data.SearchSettings.CurrentFilterSubId and NAH.settings.data.SearchSettings.CurrentFilterSubId~=filterSubId) then
		TrackedPriceHistoryYet = false
		TrackedPriceHistory_delay=3
		--update crafting categories
		if filterId==5 then--crafting
		filterCraftingId=1	
		self:UpdateChoicesComboBox(self.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_" .. filterSubId .. "_", 15);
		self.frame:GetNamedChild("FilterDropCrafting"):SetHidden(false);
		else
		self.frame:GetNamedChild("FilterDropCrafting"):SetHidden(true);		
		end
		
		--update slot dropdown with weapon types if a weapon otherwise check slot lists
		if filterId==2 then --SI_NAH_FILTERDROP_WPNTYPE_1_1 --weapon
		self:UpdateChoicesComboBox(self.filterDropSlot, "SI_NAH_FILTERDROP_WPNTYPE_" .. filterSubId .. "_", 15);
		else
		self:UpdateChoicesComboBox(self.filterDropSlot, "SI_NAH_FILTERDROP_SLOT_" .. filterId .. "_", 15);
		end
	end
	
	if (NAH.settings.data.SearchSettings.CurrentFilterId and NAH.settings.data.SearchSettings.CurrentFilterId~=filterId) then
		TrackedPriceHistoryYet = false
		TrackedPriceHistory_delay=3
		--if set to show all items then hide all other filters
		if (filterId ==1) then		
		self.frame:GetNamedChild("FilterDropSub"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropEnch"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropTrait"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropSlot"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropCrafting"):SetHidden(true);
		else
		self.frame:GetNamedChild("FilterDropSub"):SetHidden(false);
		end
	
		--check if we defined that this category could have sub categories b4 we check them
		if  (GetString("SI_NAH_FILTERDROPISSUB_", filterId) =="1") then
	--~ 	d("found sub cat")
		filterSubId=1
		filterCraftingId=1
		self:UpdateChoicesComboBox(self.filterDropSub, "SI_NAH_FILTERDROPSUB_" .. filterId .. "_", 15);
		self:UpdateChoicesComboBox(self.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_" .. filterSubId .. "_", 1);
		else	
	--~ 	d("sub cat not found")
		filterSubId=1
		filterCraftingId=1
		self:UpdateChoicesComboBox(self.filterDropSub, "SI_NAH_FILTERDROPSUB_1_", 1);
		self:UpdateChoicesComboBox(self.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_1_", 1);
		end
		
		-- update encahnt and triat filters if filter is set to weapons or armor
		if filterId==2 or filterId==3 then--weapon or apparel
		self:UpdateChoicesComboBox(self.filterDropEnch, "SI_NAH_FILTERDROP_ENCH_" .. filterId .. "_", 15);
		self:UpdateChoicesComboBox(self.filterDropTrait, "SI_NAH_FILTERDROP_TRAIT_" .. filterId .. "_", 15);	
			if filterId==2 then --SI_NAH_FILTERDROP_WPNTYPE_1_1 --weapon
			self:UpdateChoicesComboBox(self.filterDropSlot, "SI_NAH_FILTERDROP_WPNTYPE_" .. filterSubId .. "_", 15);
			else
			self:UpdateChoicesComboBox(self.filterDropSlot, "SI_NAH_FILTERDROP_SLOT_" .. filterId .. "_", 15);
			end
		self.frame:GetNamedChild("FilterDropEnch"):SetHidden(false);
		self.frame:GetNamedChild("FilterDropTrait"):SetHidden(false);
		self.frame:GetNamedChild("FilterDropSlot"):SetHidden(false);
		else
		self.frame:GetNamedChild("FilterDropEnch"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropTrait"):SetHidden(true);
		self.frame:GetNamedChild("FilterDropSlot"):SetHidden(true);
		
		end
		
		
		--show the crafting sub filter if crafting is selected
		if filterId==5 then	--crafting
		self.frame:GetNamedChild("FilterDropCrafting"):SetHidden(false);
		else
		self.frame:GetNamedChild("FilterDropCrafting"):SetHidden(true);		
		end
	
	end
	
--~ 	
	if self.initiatedAlready then
	--store search selections for future use - so ou are always rigth where you left off
	NAH.settings.data.SearchSettings.LastFilterId=NAH.settings.data.SearchSettings.CurrentFilterId;
	NAH.settings.data.SearchSettings.CurrentFilterId=filterId;
	NAH.settings.data.SearchSettings.CurrentSearch=searchInput;
	NAH.settings.data.SearchSettings.CurrentFilterSubId=filterSubId;
	NAH.settings.data.SearchSettings.searchType=self.searchType;
	
	
	NAH.settings.data.SearchSettings.CurrentFilterEnchId=filterENCHId;	
	NAH.settings.data.SearchSettings.CurrentFilterTraitId=filterTRAITId;	
	NAH.settings.data.SearchSettings.CurrentFilterSlotId=filterSLOTId;
	NAH.settings.data.SearchSettings.CurrentFilterCraftingId=filterCraftingId;
	
	
	NAH.settings.data.SearchSettings.PriceMin=minprice;
	NAH.settings.data.SearchSettings.PriceMax=maxprice;
	NAH.settings.data.SearchSettings.LevelMin=minlevel;
	NAH.settings.data.SearchSettings.LevelMax=maxlevel;
	NAH.settings.data.SearchSettings.LevelRangeTypeId=LevelRangeTypeId;
	NAH.settings.data.SearchSettings.QualityId=filterQualityId;
	
	
	
--~ 	----d("set CurrentFilterEnchId to: " .. NAH.settings.data.SearchSettings.CurrentFilterEnchId)
	
	
	NAH.settings.data.SearchSettings.currentSortKey=self.currentSortKey;
	NAH.settings.data.SearchSettings.currentSortOrder=self.currentSortOrder;
	
	
	end
--~ 	
		     
--loop through each item and choose if we should show it or not
	for i = 1, #self.masterList do
		local data = self.masterList[i];


local equiptype=GetString("SI_EQUIPTYPE", data.EquipType)
local typename=GetString("SI_ITEMTYPE", data.TypeID);
local wpntypename=GetString("SI_WEAPONTYPE", data.WeaponTypeID);
local armortypename=GetString("SI_ARMORTYPE", data.armorTypeID);

local isFurnishing=false
local isCrafting=false
local isConsumable=false

local isOnehand=false;
local isOther=true;

--if item is weapon determine if ne hand or two
if(data.WeaponTypeID>0)then 
if equiptype=="One-Handed" then
	isOnehand=true;
	end
end





local addedyet=false

local DoAddRow=false




local checkchamppoints=false

if(LevelRangeTypeId==2)then checkchamppoints=true end
	
	
	--check price range
	if minprice~=nil and minprice>0 then
		if data.StartingPrice>0 then		
	if data.StartingPrice<minprice then
	addedyet=true--tell the system not to add this item	
	end
		else	
	if data.BuyoutPrice<minprice then
	addedyet=true--tell the system not to add this item	
	end		
		end
	
	end

	if maxprice~=nil and maxprice>0 then
		if data.StartingPrice>0 then		
	if data.StartingPrice>maxprice then
	addedyet=true--tell the system not to add this item	
	end
		else	
	if data.BuyoutPrice>maxprice then
	addedyet=true--tell the system not to add this item	
	end		
		end
	
	end
	
	
	
	--check level range
	if minlevel~=nil and minlevel>0 then
	
		if checkchamppoints then		
	if data.requiredChampPoints<minlevel then
	addedyet=true--tell the system not to add this item	
	end
		else	
	if data.requiredLevel<minlevel then
	addedyet=true--tell the system not to add this item	
	end		
		end
	
	end

	if maxlevel~=nil and maxlevel>0 then
	
		if checkchamppoints then		
	if data.requiredChampPoints>maxlevel then
	addedyet=true--tell the system not to add this item	
	end
		else	
	if data.requiredLevel>maxlevel then
	addedyet=true--tell the system not to add this item	
	end		
		end
	
	end


--cehck item quality
if filterQualityId ~=1  and addedyet~=true then 
--~ 	if filterQualityText =="Normal" and data.ItemQuality ~= 1 then --Normal
	if filterQualityId ==2 and data.ItemQuality ~= 1 then --Normal
	addedyet=true
	end
--~ 	if filterQualityText =="Fine" and data.ItemQuality ~= 2 then --Fine
	if filterQualityId ==3 and data.ItemQuality ~= 2 then --Fine
	addedyet=true
	end
--~ 	if filterQualityText =="Superior" and data.ItemQuality ~= 3 then --Superior
	if filterQualityId ==4 and data.ItemQuality ~= 3 then --Superior
	addedyet=true
	end
--~ 	if filterQualityText =="Epic" and data.ItemQuality ~= 4 then --Epic
	if filterQualityId ==5 and data.ItemQuality ~= 4 then --Epic
	addedyet=true
	end
--~ 	if filterQualityText =="Legendary" and data.ItemQuality ~= 5 then --Legendary
	if filterQualityId ==6 and data.ItemQuality ~= 5 then --Legendary
	addedyet=true
	end
end




if filterId==5 then--crafting
if(data.TypeID==8)then isCrafting=true; end--motif
if(data.TypeID==10)then isCrafting=true; end--ingredient
if(data.TypeID==31)then isCrafting=true; end--reagent
if(data.TypeID==33)then isCrafting=true; end--potion solvent
if(data.TypeID==35)then isCrafting=true; end--raw material
if(data.TypeID==36)then isCrafting=true; end--material
if(data.TypeID==38)then isCrafting=true; end--material
if(data.TypeID==39)then isCrafting=true; end--raw material
if(data.TypeID==40)then isCrafting=true; end--material
if(data.TypeID==41)then isCrafting=true; end--temper
if(data.TypeID==42)then isCrafting=true; end--temper
if(data.TypeID==46)then isCrafting=true; end--weapon trait
if(data.TypeID==51)then isCrafting=true; end--potency runestone
if(data.TypeID==52)then isCrafting=true; end--aspect runestone
if(data.TypeID==53)then isCrafting=true; end--essence runestone
if(data.TypeID==58)then isCrafting=true; end--poison solvent
if(data.TypeID==62)then isCrafting=true; end--furnishing material


	if addedyet~=true then
	if isCrafting then
		if filterSubId==1 
		or (filterId==5 and filterSubId==6 and data.CraftingSkillType==CRAFTING_TYPE_PROVISIONING) --Provisioning
		or (filterId==5 and filterSubId==2 and data.CraftingSkillType==CRAFTING_TYPE_ALCHEMY) --Alchemy
		or (filterId==5 and filterSubId==3 and (data.CraftingSkillType==CRAFTING_TYPE_BLACKSMITHING or data.TypeID==8)) --Blacksmithing
		or (filterId==5 and filterSubId==4 and (data.CraftingSkillType==CRAFTING_TYPE_CLOTHIER or data.TypeID==8)) --Clothing
		or (filterId==5 and filterSubId==5 and data.CraftingSkillType==CRAFTING_TYPE_ENCHANTING) --Enchanting
		or (filterId==5 and filterSubId==7 and (data.CraftingSkillType==CRAFTING_TYPE_WOODWORKING or data.TypeID==8)) then--Woodworking
	
		if filterCraftingId==1
		or (GetString("SI_NAH_FILTERDROP_CRAFTING_" .. filterSubId .. "_" , filterCraftingId) == typename)
		or (filterSubId==2 and filterCraftingId==4 and (data.TypeID==31 or typename=="Herb" or typename=="Fungus" or typename=="Animal Parts" ) )--Reagent
		or (filterSubId==6 and filterCraftingId==2 and (data.itemFlavor=="An ingredient for crafting food." ) )--Food Ingredients
		or (filterSubId==6 and filterCraftingId==3 and (data.itemFlavor=="An ingredient for crafting beverages." ) )--Drink Ingredients
		or (filterSubId==6 and filterCraftingId==4 and (data.itemFlavor=="Used in crafting decorative food or finishing touches." ) )--Rare Ingredients
		then
		
			if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
			(searchInput == "" or self:CheckForMatch(data, searchInput)) then
			addedyet=true
			DoAddRow=true
			end
			
			end
			
		end
	end
	end
end

if filterId==6 then--Consumable
if(data.TypeID==4)then isConsumable=true; end--Food
if(data.TypeID==12)then isConsumable=true; end--Drink
if(data.TypeID==7)then isConsumable=true; end--Potion
if(data.TypeID==30)then isConsumable=true; end--Poison
if(data.TypeID==29)then isConsumable=true; end--recipe

	if addedyet~=true then
		if isConsumable then--~ 			
			if filterSubId==1 or (GetString("SI_NAH_FILTERDROPSUB_"..filterId.."_", filterSubId) == typename) then
				if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
				(searchInput == "" or self:CheckForMatch(data, searchInput))  then
					addedyet=true
					DoAddRow=true
				end
			end
		end
	end
end



if filterId==4 then--Soul Gems & Glyphs
	if addedyet~=true then
--~ 		if typename=="Soul Gem" or typename=="Weapon Glyph" or typename=="Armor Glyph" or typename=="Jewlery Glyph" then
		if data.TypeID==19 or data.TypeID==20 or data.TypeID==21 or data.TypeID==26 then
			if filterSubId==1 or (GetString("SI_NAH_FILTERDROPSUB_"..filterId.."_", filterSubId) == typename) then
				if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
				(searchInput == "" or self:CheckForMatch(data, searchInput))  then
					addedyet=true
					DoAddRow=true
				end
			end
		end
	end
end

if filterId==7 then--Furnishings

if(data.TypeID==61)then isFurnishing=true; end--Furnishing
	if addedyet~=true then
	if isFurnishing then
	if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
	(searchInput == "" or self:CheckForMatch(data, searchInput))  then
		addedyet=true
		DoAddRow=true
	end
	end
	end
end

if filterId==8 then--Other
--crafting
if(data.TypeID==8)then isOther=false; end--motif
if(data.TypeID==10)then isOther=false; end--ingredient
if(data.TypeID==31)then isOther=false; end--reagent
if(data.TypeID==33)then isOther=false; end--potion solvent
if(data.TypeID==35)then isOther=false; end--raw material
if(data.TypeID==36)then isOther=false; end--material
if(data.TypeID==38)then isOther=false; end--material
if(data.TypeID==39)then isOther=false; end--raw material
if(data.TypeID==40)then isOther=false; end--material
if(data.TypeID==41)then isOther=false; end--temper
if(data.TypeID==42)then isOther=false; end--temper
if(data.TypeID==46)then isOther=false; end--weapon trait
if(data.TypeID==51)then isOther=false; end--potency runestone
if(data.TypeID==52)then isOther=false; end--aspect runestone
if(data.TypeID==53)then isOther=false; end--essence runestone
if(data.TypeID==58)then isOther=false; end--poison solvent
if(data.TypeID==62)then isOther=false; end--furnishing material
--Consumable

if(data.TypeID==4)then isOther=false; end--Food
if(data.TypeID==12)then isOther=false; end--Drink
if(data.TypeID==7)then isOther=false; end--Potion
if(data.TypeID==30)then isOther=false; end--Poison
if(data.TypeID==29)then isOther=false; end--recipe
--Soul Gems
if data.TypeID==19 or data.TypeID==20 or data.TypeID==21 or data.TypeID==26 then isOther=false; end 
--Furnishings
if(data.TypeID==61)then isOther=false; end--Furnishing
--weapons
if filterId==2 then isOther=false; end --weapons
--Apparel
if filterId==3 then isOther=false; end --Apparel

	if addedyet~=true then
	if isOther then
		if filterSubId==1 or (GetString("SI_NAH_FILTERDROPSUB_"..filterId.."_", filterSubId) == typename) or (filterId==8 and filterSubId==2 and data.TypeID==16) then--bait or lure
			if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
			(searchInput == "" or self:CheckForMatch(data, searchInput))  then
				addedyet=true
				DoAddRow=true
			end
		end
		end
	end
end



if filterId==2 then--Weapon
	if addedyet~=true then
	if typename=="Weapon" then
		if filterSubId==1 or (filterId==2 and ((filterSubId==2 and isOnehand) or (filterSubId==3 and isOnehand==false)) ) then
		if filterSLOTId==1 or (wpntypename==GetString("SI_NAH_FILTERDROP_WPNTYPE_" .. filterSubId .. "_" , filterSLOTId) ) then
--~ 		d(data.enchantHeader.." - "..GetString("SI_NAH_FILTERDROP_ENCH_" .. filterId .. "_" , filterENCHId).." Enchantment")
		if filterENCHId==1 
		or (data.enchantHeader==GetString("SI_NAH_FILTERDROP_ENCH_" .. filterId .. "_" , filterENCHId).." Enchantment" ) 
		or (data.enchantHeader== "Fiery Weapon Enchantment" and  filterENCHId==9 ) 
		or (data.enchantHeader== "Frozen Weapon Enchantment" and  filterENCHId==10 ) 
		or ("Other"== GetString("SI_NAH_FILTERDROP_ENCH_" .. filterId .. "_" , filterENCHId)  and data.enchantHeader~="" and (
		zo_plainstrfind(data.enchantHeader:lower(), "fiery weapon" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "frozen weapon" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "absorb health" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "absorb magicka" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "befouled" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "berserker" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "charged" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "damage health" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "damage shield" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "poisoned" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "reduce armore" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "reduced armore" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "reduce power" )==false
		and zo_plainstrfind(data.enchantHeader:lower(), "stamina regen" )==false
		) ) 
		then
			if  filterTRAITId==1 or ( NirnAuctionHouse_ReadableTraitTypeNorm(data.traitType)==GetString("SI_NAH_FILTERDROP_TRAIT_"..filterId.."_", filterTRAITId) ) then
			if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
			(searchInput == "" or self:CheckForMatch(data, searchInput))  then
				addedyet=true
				DoAddRow=true
			end
		end
		end
		end
		end
	end
	end
end




if filterId==3 then--Furnishings
	if addedyet~=true then
		if data.TypeID==2 then --Apparel
		if filterSubId==1 
		or ( filterId==3 and filterSubId==2 and data.armorTypeID==1 ) --Light Armor
		or ( filterId==3 and filterSubId==3 and data.armorTypeID==2 )  --Medium Armor
		or ( filterId==3 and filterSubId==4 and data.armorTypeID==3 )  --Heavy Armor
		or ( filterId==3 and filterSubId==5 and data.armorTypeID==4 )  --Shield
		or ( filterId==3 and filterSubId==6 and data.armorTypeID==0 )  --Accessory
		then
			if  filterSLOTId==1 or ( equiptype==GetString("SI_NAH_FILTERDROP_SLOT_"..filterId.."_", filterSLOTId) ) then
			if  filterENCHId==1 
			or ( zo_plainstrfind(data.enchantHeader:lower(), GetString("SI_NAH_FILTERDROP_ENCH_"..filterId.."_", filterENCHId):lower() )  )  
			or  (filterENCHId==5  and (zo_plainstrfind(data.enchantHeader:lower(), "health" )==false and zo_plainstrfind(data.enchantHeader:lower(), "magicka" ) == false and zo_plainstrfind(data.enchantHeader:lower(), "stamina" )==false and data.enchantHeader~=""  ) ) 
			then 
			if  filterTRAITId==1 or ( NirnAuctionHouse_ReadableTraitTypeNorm(data.traitType)==GetString("SI_NAH_FILTERDROP_TRAIT_"..filterId.."_", filterTRAITId) ) then
				if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
				(searchInput == "" or self:CheckForMatch(data, searchInput)) then
--~ 				d(GetString("SI_NAH_FILTERDROP_SLOT_"..filterId.."_", filterSLOTId).."-"..equiptype)
					addedyet=true
					DoAddRow=true
				end
			end
			end
			end
		end
		end
	end
end


if filterId==1  then--All Items
	if addedyet~=true then
	if ( (data.source==NAH.currentAccount and NAH.settings.ActiveTab=="MyListings")  or (data.source~=NAH.currentAccount and NAH.settings.ActiveTab~="MyListings")) and
	(searchInput == "" or self:CheckForMatch(data, searchInput)) then
		addedyet=true
		DoAddRow=true
	end
	end
end


if data.source==NAH.currentAccount then
NirnAuctionHouse.myListingsNum=NirnAuctionHouse.myListingsNum+1;
end

	if  DoAddRow then
	numResults=numResults+1;	
		if numResults >= numResultMin  and numResults <= numResultMax then	
			table.insert(scrollData, ZO_ScrollList_CreateDataEntry(1, data));
		end
	end

		
	end--end loop

	
	
	NAH.settings.data.SearchSettings.NumResults=numResults;
	NAH.settings.data.SearchSettings.NumPages=math.ceil(NAH.settings.data.SearchSettings.NumResults/NAH.settings.data.SearchSettings.PerPage)
	
	if (#scrollData ~= NAH.settings.data.SearchSettings.NumResults) then
			if(NAH.settings.data.SearchSettings.Page>1)then 
			self.frame:GetNamedChild("AuctionHouse_LastPage"):SetHidden(false);
			else
			self.frame:GetNamedChild("AuctionHouse_LastPage"):SetHidden(true);
			end 
			
			
			if(NAH.settings.data.SearchSettings.Page<NAH.settings.data.SearchSettings.NumPages)then 
			self.frame:GetNamedChild("AuctionHouse_NextPage"):SetHidden(false);
			else
			self.frame:GetNamedChild("AuctionHouse_NextPage"):SetHidden(true);
			end 
		self.frame:GetNamedChild("Counter"):SetText(string.format("%s %d - %d  (%s %d)   %s %d / %d", GetString(SI_NAH_STRING_SHOWING),numResultMin,numResultMax, GetString(SI_NAH_STRING_TOTAL),NAH.settings.data.SearchSettings.NumResults,GetString(SI_NAH_STRING_PAGE),NAH.settings.data.SearchSettings.Page,NAH.settings.data.SearchSettings.NumPages));
		
if NAH.settings.ActiveTab=="MyListings" then 
self.frame:GetNamedChild("Counter"):SetText(string.format("%s %d - %d  (%s %d)   %s %d / %d  (%s %d / %d)", GetString(SI_NAH_STRING_SHOWING),numResultMin,numResultMax, GetString(SI_NAH_STRING_TOTAL),NAH.settings.data.SearchSettings.NumResults,GetString(SI_NAH_STRING_PAGE),NAH.settings.data.SearchSettings.Page,NAH.settings.data.SearchSettings.NumPages,GetString(SI_NAH_MYLISTINGS),NirnAuctionHouse.myListingsNum,NirnAuctionHouse.myListingsMax));
end		
	else
		self.frame:GetNamedChild("Counter"):SetText("");		
		if NAH.settings.ActiveTab=="MyListings" then 
		self.frame:GetNamedChild("Counter"):SetText(string.format("(%s %d / %d)", GetString(SI_NAH_MYLISTINGS),NirnAuctionHouse.myListingsNum,NirnAuctionHouse.myListingsMax));
		end
		self.frame:GetNamedChild("AuctionHouse_LastPage"):SetHidden(true);
		self.frame:GetNamedChild("AuctionHouse_NextPage"):SetHidden(true);
	end
	TrackedPriceHistoryYet = true		
end--end function

function NAHAuctionList:SortScrollList( )
	if (self.currentSortKey ~= nil and self.currentSortOrder ~= nil) then

		table.sort(self.masterList, self.masterListSortFunction);
		NAH.settings.data.SearchSettings.PageChange=true;
		self:FilterScrollList();
	end

end


			  
			  
function NAHAuctionList:SetupRow(control, data)
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    local mocBelongsToRow = false
    while(mouseOverControl ~= nil) do
        if(mouseOverControl == control) then
            mocBelongsToRow = true
            break
        end
        mouseOverControl = mouseOverControl:GetParent()
    end
    if(self.lockedForUpdates) then
        self:ColorRow(control, data, self.mouseOverRow == control)
    else
        if(mocBelongsToRow) then
            self:EnterRow(control)
        else 
            self:ColorRow(control, data, false)
        end
    end
    if(self.alternateRowBackgrounds) then
        local bg = GetControl(control, "BG")
        local hidden = (data.sortIndex % 2) == 0
        bg:SetHidden(hidden)
    end
end
			
			
function NAHAuctionList:SetupItemRow( control, data )
zo_callLater(function()
	control.data = data;
--~ d("creating item row for: " .. data.name)
	control:GetNamedChild("Icon"):SetTexture(data.Icon)
	control:GetNamedChild("DoBuyout"):SetHidden(true);
	
	control:GetNamedChild("DoBid"):SetHidden(true);
	
	if(data.StartingPrice ~= data.BuyoutPrice and data.StartingPrice > 0)then	
	control:GetNamedChild("DoBid"):SetHidden(false);
	end
	
	control:GetNamedChild("Bid"):SetText("-");
	if(data.StartingPrice > 0 and data.StartingPrice ~= "0" and data.StartingPrice ~= "")then
	control:GetNamedChild("Bid").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Bid"):SetText(data.StartingPrice);
	end
	
	control:GetNamedChild("Buyout"):SetText("-");
	if(data.BuyoutPrice > 0 and data.BuyoutPrice ~= "0" and data.BuyoutPrice ~= "")then
	control:GetNamedChild("Buyout").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Buyout"):SetText(data.BuyoutPrice);
	control:GetNamedChild("DoBuyout"):SetHidden(false);
	end
	
	control:GetNamedChild("DoCancel"):SetHidden(true);
	if data.source==NAH.currentAccount then
	control:GetNamedChild("DoBuyout"):SetHidden(true);	
	control:GetNamedChild("DoBid"):SetHidden(true);
	control:GetNamedChild("DoCancel"):SetHidden(false);
	
	end
	

	local itemqualColor=GetItemQualityColor(data.ItemQuality);
	control:GetNamedChild("Name").normalColor = itemqualColor;
	control:GetNamedChild("Name").mouseOverColor = itemqualColor;
	control:GetNamedChild("Name"):SetText(data.name);
	control:GetNamedChild("Qty").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("Qty"):SetText(data.stackCount);
	
	control:GetNamedChild("Type").nonRecolorable = true;
	control:GetNamedChild("Type"):SetColor(data.color:UnpackRGBA());
	control:GetNamedChild("Type"):SetText(data.itemType);
	
	
	

	control:GetNamedChild("TimeLeft").normalColor = ZO_DEFAULT_TEXT;
	control:GetNamedChild("TimeLeft"):SetText(data.TimeLeft);


	
	control:GetNamedChild("Buy")
	

----------------------------------MasterMerchant Integration-----------------------------------------
if(MasterMerchant)then
if(NAH.settings.AddListingsToMasterMerchant)then
if(data.BuyoutPrice and data.BuyoutPrice > 0 and data.BuyoutPrice ~= "" and data.BuyoutPrice ~= "0")then
--~ d("adding item to MasterMerchant: " .. data.itemLink)
if TrackedPriceHistoryYet == false then
		--delay price tracking to be safe as to spamming limits
		zo_callLater(function()
			    local guildID = GetGuildId(1)
			    if guildID then
			    local guildName = GetGuildName(guildID)
			    if guildName then
				local theEvent = {}      
			      theEvent.id = data.TradeID--eventid
			      theEvent.itemName = data.itemLink--really item link
			      theEvent.seller = data.source
			      theEvent.buyer = data.source
			      theEvent.guild = guildName
			      theEvent.quant = data.stackCount
			      theEvent.salePrice = data.BuyoutPrice
			      theEvent.saleTime = GetTimeStamp()
			      theEvent.kioskSale = false
			      
			MasterMerchant:addToHistoryTables(theEvent, true)
			end
			end

			end, (TrackedPriceHistory_delay*1000)
			)
			TrackedPriceHistory_delay=TrackedPriceHistory_delay+TrackedPriceHistory_delayInt
			
			end



end
end
end
----------------------------------MasterMerchant Integration-----------------------------------------

--~ 	ZO_SortFilterList.SetupRow(self, control, data);
	NAHAuctionList.SetupRow(self, control, data);
	end, (NirnAuctionHouse.BuildRows_delay)
			)
--~ 			NirnAuctionHouse.BuildRows_delay=NirnAuctionHouse.BuildRows_delay+50
--~ 			
--~ 			if NirnAuctionHouse.BuildRows_delay>NirnAuctionHouse.BuildRows_delayMax then
--~ 			NirnAuctionHouse.BuildRows_delay=NirnAuctionHouse.BuildRows_delayMax
--~ 			end
end


function NAHAuctionList:CheckForMatch( data, searchInput )
		return(self.search:IsMatch(searchInput, data));
end

function NAHAuctionList:ProcessItemEntry( stringSearch, data, searchTerm, cache )
if (self.searchType == 1) then
	if ( zo_plainstrfind(data.name:lower(), searchTerm) or
	     zo_plainstrfind(data.itemType:lower(), searchTerm) ) then
		return(true);
	end
	
	elseif (self.searchType == 2) then
	if ( zo_plainstrfind(data.name:lower(), searchTerm) or
		zo_plainstrfind(data.abilityHeader:lower(), searchTerm) or
		zo_plainstrfind(data.abilityDescription:lower(), searchTerm) or
		zo_plainstrfind(data.enchantHeader:lower(), searchTerm) or
		zo_plainstrfind(data.traitDescription:lower(), searchTerm) or
		zo_plainstrfind(data.traitSubtypeDescription:lower(), searchTerm) or
		zo_plainstrfind(data.itemFlavor:lower(), searchTerm) or
		zo_plainstrfind(NirnAuctionHouse_ReadableTraitType(data.traitType):lower(), searchTerm) or
		zo_plainstrfind(NirnAuctionHouse_ReadableTraitType(data.traitSubtype):lower(), searchTerm) or
	     zo_plainstrfind(data.itemType:lower(), searchTerm) ) then
		return(true);
	end
	
	elseif (NAH.settings.ActiveTab=="MyListings") then
	
	if ( zo_plainstrfind(data.name:lower(), searchTerm) or
	     zo_plainstrfind(data.itemType:lower(), searchTerm) ) then
		return(true);
	end
	
	
	end

	return(false);
end

function NAHAuctionList:UpdateChoicesComboBox( control, prefix, max )
	
	control:SetSortsItems(false);
	control:ClearItems();
local callback = function( comboBox, entryText, entry, selectionChanged )
		self:RefreshFilters();
	end

	for i = 1, max do
		local entry = ZO_ComboBox:CreateItemEntry(GetString(prefix, i), callback);
		entry.id = i;
		control:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE);
	end

	control:SelectItemByIndex(1, true);
end

function NAHAuctionList:InitializeComboBox( control, prefix, max )
	control:SetSortsItems(false);
	control:ClearItems();

	local callback = function( comboBox, entryText, entry, selectionChanged )
		self:RefreshFilters();
	end

	for i = 1, max do
		local entry = ZO_ComboBox:CreateItemEntry(GetString(prefix, i), callback);
		entry.id = i;
		control:AddItem(entry, ZO_COMBOBOX_SUPRESS_UPDATE);
	end

	control:SelectItemByIndex(1, true);
end



function NAHRow_OnMouseEnter( control )

	if NirnAuctionHouse.PriceTable==nil then
	NirnAuctionHouse:LoadPrices()
	if NirnAuctionHouse.PriceTable==nil then
	--d("No price table")
	return
	end
	end
	NirnAuctionHouse.list:Row_OnMouseEnter(control);
	if(control==nil or control.data==nil or control.data.itemLink==nil)then return   end
	InitializeTooltip(NAHTooltip, NirnAuctionHousePanel, TOPRIGHT, -100, 0, TOPLEFT);
	NAHTooltip:SetLink(control.data.itemLink);

	if (control.data.style) then
		NAHTooltip:AddLine(LocalizeString("\n|c<<1>><<Z:2>>|r", ZO_NORMAL_TEXT:ToHex(), control.data.style), "ZoFontGameSmall");
	end
	
	local Rawitem = {
		dataEntry = {
			data = {
				stackCount = 1,
				itemId = control.data.ItemID,
				level = NirnAuctionHouse:GetItemLevel(control.data.itemLink),
				quality = GetItemLinkQuality(control.data.itemLink),
			}
		}
	}
	
	
	NirnAuctionHouse:PCtoTooltip(NAHTooltip,control.data.stackCount,control.data.itemLink,control:GetId())
	
    
----------------------------------MasterMerchant Integration-----------------------------------------
	if(MasterMerchant)then
	if(NAH.settings.ShowMasterMerchantPrice)then
	MasterMerchant:addStatsAndGraph(NAHTooltip, control.data.itemLink)	
	end
	end
----------------------------------MasterMerchant Integration-----------------------------------------
end



function NirnAuctionHouse:PCtoTooltip(TooltipInst,QTY,itemLink,UID)
	
	if NirnAuctionHouse.PriceTable==nil then
	NirnAuctionHouse:LoadPrices()
	if NirnAuctionHouse.PriceTable==nil then
	return
	end
	end
	
	if (itemLink==nil) then	
	return 
	end
	
	local itemId=NirnAuctionHouse:GetItemID(itemLink)
local requiredLevel=GetItemLinkRequiredLevel(itemLink)
local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)
local ItemQuality=GetItemLinkQuality(itemLink)

	local statval=GetItemLinkWeaponPower(itemLink)+GetItemLinkArmorRating(itemLink, false)
local Priceuid=itemId..":"..ItemQuality..":"..statval..":"..requiredLevel..":"..requiredChampPoints	
	
	if ((TooltipInst.PCYet==nil or TooltipInst.PCYet~=itemLink..UID)) then	
		if (NirnAuctionHouse.PriceTable ~=nil and NirnAuctionHouse.PriceTable[Priceuid]~=nil and NirnAuctionHouse.PriceTable[Priceuid].price~=nil) then	
		TooltipInst.PCYet=itemLink..UID
		
			TooltipInst:AddVerticalPadding(8)
			ZO_Tooltip_AddDivider(TooltipInst)
			TooltipInst:AddLine("NAH "..GetString(SI_NAH_STRING_PRICECHECK).." : "..NirnAuctionHouse.PriceTable[Priceuid].price.." |t18:18:esoui/art/currency/currency_gold_32.dds|t", "ZoFontGameLarge");
			if(QTY~=nil and QTY>1)then
			TooltipInst:AddLine("x"..QTY.." : "..tonumber(string.format("%.2f", NirnAuctionHouse.PriceTable[Priceuid].price*QTY)).." |t18:18:esoui/art/currency/currency_gold_32.dds|t", "ZoFontGameLarge");
			end
			else
		TooltipInst.PCYet=false
		end
	end
	
	end

function NAHRow_OnMouseExit( control )
	NirnAuctionHouse.list:Row_OnMouseExit(control);
----------------------------------MasterMerchant Integration-----------------------------------------
		---MasterMerchant:remStatsItemTooltip()
		if(MasterMerchant)then
  if NAHTooltip.graphPool then
    NAHTooltip.graphPool:ReleaseAllObjects()
  end
  NAHTooltip.mmGraph = nil
  if NAHTooltip.textPool then
    NAHTooltip.textPool:ReleaseAllObjects()
  end
  NAHTooltip.mmText = nil  
  NAHTooltip.mmCraftText = nil
  NAHTooltip.mmTextDebug = nil
  NAHTooltip.mmQualityDown = nil
		end
-----------------------------------MasterMerchant Integration----------------------------------------
NAHTooltip.PCYet=nil
	ClearTooltip(NAHTooltip);
end

function NAHRow_OnMouseUp( control )
	NirnAuctionHouse.AddToChat(control.data.itemLink);
end	




function NirnAuctionHouse:OnUIPosUpdate(UIElement)
  if UIElement == NAHAuctionHouseBtn then
    NAHAuctionHouseBtn:ClearAnchors()
    NAH.settings.NAHBTN_LEFT=NAHAuctionHouseBtn:GetLeft()
    NAH.settings.NAHBTN_TOP=NAHAuctionHouseBtn:GetTop()
    NAHAuctionHouseBtn:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, NAH.settings.NAHBTN_LEFT, NAH.settings.NAHBTN_TOP)
  end
end



 function NirnAuctionHouse_FillOrderData(controlData )
	local control={}
	control.data=controlData
	NirnAuctionHouse_FillOrder(control )
end	

 function NirnAuctionHouse_FillOrder(control )
  
 
 local codcost=10+math.floor(control.data.BuyoutPrice/20)
--~  local codcost=10+control.data.BuyoutPrice
 d( "Filling order for " ..control.data.buyer .. " sending " .. control.data.itemLink .. " x" .. control.data.stackCount .. " for " .. control.data.BuyoutPrice .. " COD (postage: " .. codcost .. ")");
 
			NirnAuctionHouse.FillingOrderID=control.data.TradeID
			NirnAuctionHouse.FillingOrderBidID=control.data.BidID
 NirnAuctionHouse:COD(control.data.buyer,control.data.itemLink,control.data.stackCount,control.data.BuyoutPrice)
 ---------------------
--~  cod costs a base cost of 10 with 1g for every 20g of your cod cost
-----------------
 end

 
 function NirnAuctionHouse_BidItem(control )
	NirnAuctionHouse.ActiveBidListingId=control.data.TradeID
	
		if(not NAH.settings.data.Bids)then
		NAH.settings.data.Bids = {}
	end
	if(not NAH.settings.data.Bids[control.data.TradeID])then
			NAH.settings.data.Bids[control.data.TradeID] = {}			
			NAH.settings.data.Bids[control.data.TradeID].Bid ={}
	end


NAH.settings.data.Bids[control.data.TradeID].Bid.stackCount=control.data.stackCount;
NAH.settings.data.Bids[control.data.TradeID].Bid.Price=control.data.StartingPrice;
NAH.settings.data.Bids[control.data.TradeID].Bid.ItemLink=control.data.itemLink;
NAH.settings.data.Bids[control.data.TradeID].Bid.ItemID=control.data.ItemID;
NAH.settings.data.Bids[control.data.TradeID].Bid.seller=control.data.source;
NAH.settings.data.Bids[control.data.TradeID].Bid.TradeID=control.data.TradeID;
	
	
NAHAuctionHouseGoldCostBid:GetNamedChild("BidName"):SetText(control.data.name);
NirnAuctionHouse.GoldAmountBidcont = NAHAuctionHouseGoldCostBid:GetNamedChild("GoldAmountBid");
NirnAuctionHouse.GoldAmountBid = NirnAuctionHouse.GoldAmountBidcont:GetNamedChild("GoldAmountBoxBid");
NirnAuctionHouse.GoldAmountBidVal = NirnAuctionHouse.GoldAmountBid:SetText(tonumber(NAH.settings.data.Bids[control.data.TradeID].Bid.Price)+1);
	
NirnAuctionHouse_OpenGoldCostBid();
	
end	

 
 function NirnAuctionHouse_CancelListing(control )
NirnAuctionHouse_CancelListing_func(control.data.TradeID,control.data.itemLink )
	
end	


 
 function NirnAuctionHouse_CancelListing_func(TradeID,itemLink )
		if(not NAH.settings.data.FilledOrders)then
		NAH.settings.data.FilledOrders = {}
	end
	if(not NAH.settings.data.FilledOrders[TradeID])then
		NAH.settings.data.FilledOrders[TradeID] = {}			
		NAH.settings.data.FilledOrders[TradeID].Order ={}
	end

		NAH.settings.data.FilledOrders[TradeID].Order.TradeID =TradeID
		NAH.settings.data.FilledOrders[TradeID].Order.BidID ="1"
		
	NAH.settings.PostFilledOrders=true;
	
d("Queued Trade for: " .. itemLink .. " For Removal sync to Remove now")
	
end	



function NirnAuctionHouse_CloseGoldCostBuyout()
    NAHAuctionHouseGoldCostBuyout:SetHidden(true)
end

function NirnAuctionHouse_OpenGoldCostBuyout()
    NAHAuctionHouseGoldCostBuyout:SetHidden(false)
end



 function NirnAuctionHouse_Docancel_BuyoutOrder( )

	
	NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId] = {}			
	NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid ={}
	NirnAuctionHouse_CloseGoldCostBuyout()
end	

 function NirnAuctionHouse_DoPost_BuyoutOrder( )	
	NAH.settings.PostBids=true;-- tell the server link to post bids 	
	NirnAuctionHouse:forceWriteSavedVars()
	
end	


 function NirnAuctionHouse_BuyItem(control )
 
 if (GetCurrentMoney() +GetBankedMoney()) < tonumber(control.data.BuyoutPrice) then  d("You do Not Have Enough Gold In your Inventory For this Purchase") return; end
	
	NirnAuctionHouse.ActiveBidListingId=control.data.TradeID
	
	
	if(not NAH.settings.data.Bids)then
		NAH.settings.data.Bids = {}
	end
	if(not NAH.settings.data.Bids[control.data.TradeID])then
			NAH.settings.data.Bids[control.data.TradeID] = {}			
			NAH.settings.data.Bids[control.data.TradeID].Bid ={}
	end

NAH.settings.data.Bids[control.data.TradeID].Bid.stackCount=control.data.stackCount;
NAH.settings.data.Bids[control.data.TradeID].Bid.Price=control.data.BuyoutPrice;
NAH.settings.data.Bids[control.data.TradeID].Bid.ItemLink=control.data.itemLink;
NAH.settings.data.Bids[control.data.TradeID].Bid.ItemID=control.data.ItemID;
NAH.settings.data.Bids[control.data.TradeID].Bid.seller=control.data.source;
NAH.settings.data.Bids[control.data.TradeID].Bid.TradeID=control.data.TradeID;


NAHAuctionHouseGoldCostBuyout:GetNamedChild("buyoutlabel"):SetText("Are You Sure Your Want to Buyout \n".. control.data.name .." (x".. control.data.stackCount ..") for ".. control.data.BuyoutPrice .." Gold?");
NirnAuctionHouse_OpenGoldCostBuyout()
	
end	

 function NirnAuctionHouse_NextPage( )
  if not NirnAuctionHousePanel:IsHidden() then
	 if (NAH.settings.data.SearchSettings.NumPages>NAH.settings.data.SearchSettings.Page) then
	NAH.settings.data.SearchSettings.Page=NAH.settings.data.SearchSettings.Page+1
	NAH.settings.data.SearchSettings.PageChange=true
	NirnAuctionHouse.list:RefreshFilters()
	 end
	 end
 end
 
 function NirnAuctionHouse_LastPage( )
  if not NirnAuctionHousePanel:IsHidden() then
	 if NAH.settings.data.SearchSettings.Page > 1 then
	NAH.settings.data.SearchSettings.Page=NAH.settings.data.SearchSettings.Page-1
	NAH.settings.data.SearchSettings.PageChange=true
	NirnAuctionHouse.list:RefreshFilters()
	 end
	 end
 end
 
 
 function NirnAuctionHouse_ToggleAHButtons( )
 if(NirnAuctionHouse.ServerLink_INITIATED)then
 if NAHAuctionHouseBtn:IsHidden() then
NirnAuctionHouse_ShowBtns( );
 else
NirnAuctionHouse_HideBtns();
 end
 end

 end	 
 


 function NirnAuctionHouse_ToggleNAH( )
 if(NirnAuctionHouse.ServerLink_INITIATED)then
 if NAH.settings.ActiveTab=="" then 
NirnAuctionHousePanel:GetNamedChild("title"):SetText(GetString(SI_NAH_AUCTION))
--~ NirnAuctionHousePanel:GetNamedChild("AuctionHouse"):SetHidden(true);
--~ NirnAuctionHousePanel:GetNamedChild("MyListings"):SetHidden(false);
 NAH.settings.ActiveTab="Auction";
 SCENE_MANAGER:Show("NAHScene");
 else

	SCENE_MANAGER:Hide("NAHScene");
	SCENE_MANAGER:Hide("NAHSceneOrders");
	SCENE_MANAGER:Hide("NAHSceneTrackedOrders");
	NAHAuctionHouseTrackingPanel:SetHidden(true)   
	NAHAuctionHouseOrdersPanel:SetHidden(true)   
	NirnAuctionHousePanel:SetHidden(true)   
	NAH.settings.ActiveTab="";
 end
 end

 end	
 

 function NirnAuctionHouse_ToggleAH( )
 if(NirnAuctionHouse.ServerLink_INITIATED)then
 if NirnAuctionHousePanel:IsHidden() then 
NirnAuctionHousePanel:GetNamedChild("title"):SetText(GetString(SI_NAH_AUCTION))
--~ NirnAuctionHousePanel:GetNamedChild("AuctionHouse"):SetHidden(true);
--~ NirnAuctionHousePanel:GetNamedChild("MyListings"):SetHidden(false);
 NAH.settings.ActiveTab="Auction";
 SCENE_MANAGER:Show("NAHScene");
 else
 NirnAuctionHousePanel:SetHidden(true);  
SCENE_MANAGER:Hide("NAHScene");
NAH.settings.ActiveTab="";
 end
 end

 end	
 
 function NirnAuctionHouse_ServerLink_Recheck( )
NAH.settings.ReloadTradeData=true
NirnAuctionHouse:forceWriteSavedVars()
 end	
 
 
 function NirnAuctionHouse_ServerLink_INITIATED( versionnum)
if(not NAH.settings.ServerLink_INITIATED or not NirnAuctionHouse.ServerLink_INITIATED)then
if ( NAH.ServerLinkVersionRequired==versionnum ) then

NirnAuctionHouse.ServerLink_INITIATED=true;
NAH.settings.ServerLink_INITIATED=true;
--~   d("Nirn Auction House ServerLink INITIATED")
NirnAuctionHouse_HideServerLink( );
NirnAuctionHouse_HideServerLinkVersion( );
NirnAuctionHouse_ShowBtns( );
else
NirnAuctionHouse_HideServerLink( );
NirnAuctionHouse_ShowServerLinkVersion( );

end
end
 end	
 
 function NirnAuctionHouse_RefreshAHTrackedBids( )
	if(NirnAuctionHouse.ServerLink_INITIATED)then
		NirnAuctionHouse:NAHWindowTrackedOrders_Open()
	end	
 end	
 
 function NirnAuctionHouse_RefreshAHBids( )
	if(NirnAuctionHouse.ServerLink_INITIATED)then
		NirnAuctionHouse:NAHWindowOrders_Open()
	end	
 end	
 
 
 function NirnAuctionHouse_RefreshAH( )
	if(NirnAuctionHouse.ServerLink_INITIATED)then
		NirnAuctionHouse:NAHWindow_Open()
	end
 end	
 
 function NirnAuctionHouse_LoadBids( )	
 
	if NirnAuctionHouse.LoadBids ~=nil then	
	NirnAuctionHouse:LoadBids()
	end
 end	
	
	
 
 function NirnAuctionHouse_NewBids( )
NirnAuctionHouse_ServerLink_INITIATED( ) 
 if(NirnAuctionHouse.ServerLink_INITIATED)then
 NAHAuctionHouseOrdersBtnNEW:SetHidden(false); 
 NAHAuctionHouseOrdersBtn:SetHidden(true); 
 end
 end	
 
  
 function NirnAuctionHouse_RegularBids( )	
 NAHAuctionHouseOrdersBtnNEW:SetHidden(true);  
 NAHAuctionHouseOrdersBtn:SetHidden(false);  
 end	
	
  
 function NirnAuctionHouse_ShowServerLinkVersion( )	
 NAHAuctionHouse_ServerLink_VERSION:SetHidden(false);  
 end	  
  
 function NirnAuctionHouse_HideServerLinkVersion( )	
 NAHAuctionHouse_ServerLink_VERSION:SetHidden(true);  
 end	  
  
 function NirnAuctionHouse_HideServerLink( )	
 NAHAuctionHouse_ServerLink:SetHidden(true);  
 end	  
 
 function NirnAuctionHouse_HideBtns( )	
 NAHAuctionHouseBtn:SetHidden(true);  
--~  NAHAuctionHouseOrdersBtnNEW:SetHidden(true);  
--~  NAHAuctionHouseOrdersBtn:SetHidden(true); 
--~  NAHAuctionHouseOrdersTRKBtn:SetHidden(true);   
 end	
 
 	
  
 function NirnAuctionHouse_ShowBtns( )	
--~  NAHAuctionHouseOrdersBtnNEW:SetHidden(true);  
 NAHAuctionHouseBtn:SetHidden(false);  
--~  NAHAuctionHouseOrdersBtn:SetHidden(false);  
--~  NAHAuctionHouseOrdersTRKBtn:SetHidden(false);  
 end	
		
 function NirnAuctionHouse_ShowMyListings( )
NirnAuctionHousePanel:GetNamedChild("title"):SetText(GetString(SI_NAH_MYLISTINGS))
--~ NirnAuctionHousePanel:GetNamedChild("AuctionHouse"):SetHidden(false);
--~ NirnAuctionHousePanel:GetNamedChild("MyListings"):SetHidden(true);
	    NAH.settings.ActiveTab="MyListings";	
	 NirnAuctionHouse.list:RefreshFilters()
	if NirnAuctionHousePanel:IsHidden() then
	 SCENE_MANAGER:Show("NAHScene"); 
	end
 end	
	

	
 function NirnAuctionHouse_ToggleOrders( )	
 if NAHAuctionHouseOrdersPanel:IsHidden() then
  if SCENE_MANAGER.currentScene.name ~= "NAHSceneOrders" then
 NAH.settings.ActiveTab="Orders";
 SCENE_MANAGER:Show("NAHSceneOrders"); 
 end

 else
 
 if SCENE_MANAGER.currentScene.name == "NAHSceneOrders" then
 NAH.settings.ActiveTab="";
 SCENE_MANAGER:Hide("NAHSceneOrders");
 end
 
 end
 end	
	
	
 function NirnAuctionHouse_ToggleTrackedOrders( )	
 if NAHAuctionHouseTrackingPanel:IsHidden() then
  if SCENE_MANAGER.currentScene.name ~= "NAHSceneTrackedOrders" then
  NAH.settings.ActiveTab="TrackedOrders";
 SCENE_MANAGER:Show("NAHSceneTrackedOrders"); 
 end

 else
 
 if SCENE_MANAGER.currentScene.name == "NAHSceneTrackedOrders" then
 NAH.settings.ActiveTab="";
 SCENE_MANAGER:Hide("NAHSceneTrackedOrders");
 end
 
 end
 end	
	
	
	
	
	
	




function NirnAuctionHouse:MailSent()
	if(NirnAuctionHouse.FillingOrderID)then
	if(not NAH.settings.data.FilledOrders)then
		NAH.settings.data.FilledOrders = {}
	end
	if(not NAH.settings.data.FilledOrders[NirnAuctionHouse.FillingOrderID])then
		NAH.settings.data.FilledOrders[NirnAuctionHouse.FillingOrderID] = {}			
		NAH.settings.data.FilledOrders[NirnAuctionHouse.FillingOrderID].Order ={}
	end

		NAH.settings.data.FilledOrders[NirnAuctionHouse.FillingOrderID].Order.TradeID =NirnAuctionHouse.FillingOrderID
		NAH.settings.data.FilledOrders[NirnAuctionHouse.FillingOrderID].Order.BidID =NirnAuctionHouse.FillingOrderBidID
		
NAH.settings.PostFilledOrders=true;
NirnAuctionHouse.FillingOrderID=nil
NirnAuctionHouse.FillingOrderBidID=nil

 d("EVENT_MAIL_SEND_SUCCESS")
	NirnAuctionHouse:NAHWindowOrders_Open()
end
end



function NirnAuctionHouse:MailFailed()
NirnAuctionHouse.FillingOrderID=nil
NirnAuctionHouse.FillingOrderBidID=nil
d("EVENT_MAIL_SEND_FAILED")
end
	





local function NAH_EventOnPlayerUnloaded()
	
	
	
if NAH.settings.ReloadingUI ~= true then 	
	NirnAuctionHouse:clearActiveAccountNoRefresh()
	NAH.settings.data.ReceivedOrders = {}	
	NAH.settings.PostPaidOrders=false;
	NAH.settings.data.PaidOrders = {}	
	NAH.settings.PostFilledOrders=false;
	NAH.settings.data.FilledOrders = {}
end
end

local function NAH_SetAccountCharData()
	NAH.currentCharacterId = GetCurrentCharacterId()
	NAH.currentAccount = GetDisplayName()
	NAH.settings.ActiveAccount=NAH.currentAccount
	NAH.settings.ActiveCharacterId=NAH.currentCharacterId
	NAH.settings.CurCharacterId=NAH.currentCharacterId
	
	
	SCENE_MANAGER:Hide("NAHScene");
	SCENE_MANAGER:Hide("NAHSceneOrders");
	SCENE_MANAGER:Hide("NAHSceneTrackedOrders");
	NAHAuctionHouseTrackingPanel:SetHidden(true)   
	NAHAuctionHouseOrdersPanel:SetHidden(true)   
	NirnAuctionHousePanel:SetHidden(true)   

	
			
	NAH.settings.data.Listings = {}
	NAH.settings.data.Bids = {}
	
 
	
	if( NAH.settings.settingsVersion==nil or NAH.settings.settingsVersion~=NAH.ServerLinkVersionRequired)then
	d("(your settigns for Nirn Auction House have been reset)")

	NAH.settings.settingsVersion=NAH.ServerLinkVersionRequired;
	
	NAH.settings.AddListingsToMasterMerchant = false
	NAH.settings.ActiveSellersOnly = defaultSettings.ActiveSellersOnly
	NAH.settings.PlaySounds = defaultSettings.PlaySounds
	NAH.settings.PlaySounds_success_listing = defaultSettings.PlaySounds_success_listing
	NAH.settings.PlaySounds_success_buy = defaultSettings.PlaySounds_success_buy
	NAH.settings.PlaySounds_success_cancel = defaultSettings.PlaySounds_success_cancel
	NAH.settings.NAHBTN_TOP = defaultSettings.NAHBTN_TOP
	NAH.settings.NAHBTN_LEFT = defaultSettings.NAHBTN_LEFT
	NAH.settings.ActiveTab = ""
	NAH.settings.data.searchType = defaultSettings.data.searchType
	NAH.settings.data.Listings = {}
	NAH.settings.data.Bids = {}
	NAH.settings.data.FilledOrders = {}
	NAH.settings.data.ReceivedOrders = {}
	NAH.settings.data.PaidOrders = {}
	NAH.settings.data.OfferedBids = {}
	NAH.settings.data.AvailableBids = {}
	NAH.settings.data.PerPage = defaultSettings.data.PerPage
	end
	
	

	if (NAH.settings.NAHBTN_LEFT~=false and NAH.settings.NAHBTN_TOP~=false) then
	    NAHAuctionHouseBtn:ClearAnchors()
	    NAHAuctionHouseBtn:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, NAH.settings.NAHBTN_LEFT, NAH.settings.NAHBTN_TOP)
	    end
	
	
	
	if (NAH.settings.ActiveTab=="MyListings") then  
NirnAuctionHousePanel:GetNamedChild("title"):SetText(GetString(SI_NAH_MYLISTINGS))
--~ NirnAuctionHousePanel:GetNamedChild("AuctionHouse"):SetHidden(false);
--~ NirnAuctionHousePanel:GetNamedChild("MyListings"):SetHidden(true);
	end
	
	if NAH.settings.OpenTrackedOrdersWindow == false then
	else
	NAH.settings.OpenTrackedOrdersWindow= false	
	NAH.settings.ActiveTab="TrackedOrders";
	SCENE_MANAGER:Show("NAHSceneTrackedOrders");	
	end
	
	if NAH.settings.OpenOrdersWindow == false then
	else
	NAH.settings.OpenOrdersWindow= false	
	NAH.settings.ActiveTab="Orders";
	SCENE_MANAGER:Show("NAHSceneOrders");	
	end
	
	if NAH.settings.OpenAuctionWindow == false then
	else
	NAH.settings.OpenAuctionWindow= false	
	SCENE_MANAGER:Show("NAHScene");	
	end
	
 NAHAuctionHouseOrdersBtnNEW:SetHidden(true);  
	NirnAuctionHouse_HideBtns( );
	
	NirnAuctionHouse:CheckServerLinkInitiated()
	NirnAuctionHouse:CheckNotifications()

	
	if NAH.settings.ReloadTradeData then
	NAH.settings.ReloadTradeData=false;
	end
	
	if NAH.settings.ReloadTradeDataTracked then
	NAH.settings.ReloadTradeDataTracked=false;
	end
	

if(NirnAuctionHouse.list~=nil)then 
		
	NirnAuctionHouse.list.searchDrop = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("SearchDrop"));
	NirnAuctionHouse.list.filterDrop = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDrop"));
	NirnAuctionHouse.list.filterDropSub = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSub"));
	NirnAuctionHouse.list.My_searchBox = NirnAuctionHousePanel:GetNamedChild("Search"):GetNamedChild("Box");
	NirnAuctionHouse.list.filterDropEnch = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDropEnch"));
	NirnAuctionHouse.list.filterDropTrait = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDropTrait"));
	NirnAuctionHouse.list.filterDropCrafting = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDropCrafting"));
	NirnAuctionHouse.list.filterDropSlot = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSlot"));
	
	NirnAuctionHouse.list.PriceMinBox = (NirnAuctionHouse.list.frame:GetNamedChild("PriceMinBox"));
	NirnAuctionHouse.list.PriceMaxBox = (NirnAuctionHouse.list.frame:GetNamedChild("PriceMaxBox"));
	NirnAuctionHouse.list.LevelMinBox = (NirnAuctionHouse.list.frame:GetNamedChild("LevelMinBox"));
	NirnAuctionHouse.list.LevelMaxBox = (NirnAuctionHouse.list.frame:GetNamedChild("LevelMaxBox"));
	NirnAuctionHouse.list.LevelRangeType = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("LevelRangeType"));
	
	
	
	NirnAuctionHouse.list.QualityDrop = ZO_ComboBox_ObjectFromContainer(NirnAuctionHouse.list.frame:GetNamedChild("QualityDrop"));
	
	
	
	
	
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSub"):SetHidden(false);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropEnch"):SetHidden(true);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropTrait"):SetHidden(true);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSlot"):SetHidden(true);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropCrafting"):SetHidden(true);
		
--~ 		zo_callLater(function()
	if NAH.settings.data.SearchSettings.searchType then
	NirnAuctionHouse.list.searchDrop:SelectItemByIndex(NAH.settings.data.SearchSettings.searchType,true)
	NirnAuctionHouse.list.searchType=NAH.settings.data.SearchSettings.searchType
	end
	
	if NAH.settings.data.SearchSettings.CurrentFilterId then
	NirnAuctionHouse.list.filterDrop:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterId,true)
	
	if (NAH.settings.data.SearchSettings.CurrentFilterId ==1) then		
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSub"):SetHidden(true);
	end
	
	if (GetString("SI_NAH_FILTERDROP", NAH.settings.data.SearchSettings.CurrentFilterId) =="Weapon") or (GetString("SI_NAH_FILTERDROP", NAH.settings.data.SearchSettings.CurrentFilterId) =="Apparel") then	
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropEnch"):SetHidden(false);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropTrait"):SetHidden(false);
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropSlot"):SetHidden(false);
	end
	
	if (GetString("SI_NAH_FILTERDROP", NAH.settings.data.SearchSettings.CurrentFilterId) =="Crafting") then	
	NirnAuctionHouse.list.frame:GetNamedChild("FilterDropCrafting"):SetHidden(false);
	end
	
	
	NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropSub, "SI_NAH_FILTERDROPSUB_" .. NAH.settings.data.SearchSettings.CurrentFilterId .. "_", 15);	
	
	NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropEnch, "SI_NAH_FILTERDROP_ENCH_" .. NAH.settings.data.SearchSettings.CurrentFilterId .. "_", 15);
	NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropTrait, "SI_NAH_FILTERDROP_TRAIT_" .. NAH.settings.data.SearchSettings.CurrentFilterId .. "_", 15);	
	
	
		if NAH.settings.data.SearchSettings.CurrentFilterSubId then	
		NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_" .. NAH.settings.data.SearchSettings.CurrentFilterSubId .. "_", 15);	
		else	
		NirnAuctionHouse.list.filterDropCrafting:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_1_", 1);
		end
	
	
		if(GetString("SI_NAH_FILTERDROP", NAH.settings.data.SearchSettings.CurrentFilterId) =="Weapon") then --SI_NAH_FILTERDROP_WPNTYPE_1_1
		NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropSlot, "SI_NAH_FILTERDROP_WPNTYPE_" .. NAH.settings.data.SearchSettings.CurrentFilterSubId .. "_", 15);
		else
		NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropSlot, "SI_NAH_FILTERDROP_SLOT_" .. NAH.settings.data.SearchSettings.CurrentFilterId .. "_", 15);
		end
	
	end
	
	
	
	
	


		
	if NAH.settings.data.SearchSettings.PriceMin then
	NirnAuctionHouse.list.PriceMinBox:SetText(NAH.settings.data.SearchSettings.PriceMin)
	end
	
		
	if NAH.settings.data.SearchSettings.PriceMax then
	NirnAuctionHouse.list.PriceMaxBox:SetText(NAH.settings.data.SearchSettings.PriceMax)
	end
	
		
	if NAH.settings.data.SearchSettings.LevelMin then
	NirnAuctionHouse.list.LevelMinBox:SetText(NAH.settings.data.SearchSettings.LevelMin)
	end
	
	if NAH.settings.data.SearchSettings.QualityId then
	NirnAuctionHouse.list.QualityDrop:SelectItemByIndex(NAH.settings.data.SearchSettings.QualityId,true)
	end
	
		
	if NAH.settings.data.SearchSettings.LevelMax then
	NirnAuctionHouse.list.LevelMaxBox:SetText(NAH.settings.data.SearchSettings.LevelMax)
	end
	
		
	if NAH.settings.data.SearchSettings.LevelRangeTypeId then	
	NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.LevelRangeType, "SI_NAH_LEVELDROP", 2);	
	NirnAuctionHouse.list.LevelRangeType:SelectItemByIndex(NAH.settings.data.SearchSettings.LevelRangeTypeId,true)
	end
	
	
	
	if NAH.settings.data.SearchSettings.CurrentFilterEnchId then
	NirnAuctionHouse.list.filterDropEnch:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterEnchId,true)
	end
	
	if NAH.settings.data.SearchSettings.CurrentFilterTraitId then
	NirnAuctionHouse.list.filterDropTrait:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterTraitId,true)
	end
	
	
	if NAH.settings.data.SearchSettings.CurrentFilterSlotId then
	NirnAuctionHouse.list.filterDropSlot:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterSlotId,true)
	end
	
	
	
	if NAH.settings.data.SearchSettings.CurrentFilterSubId then	
	NirnAuctionHouse.list.filterDropSub:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterSubId,true)
		
	if NAH.settings.data.SearchSettings.CurrentFilterCraftingId then
	NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_"..NAH.settings.data.SearchSettings.CurrentFilterSubId.."_", 1);
		zo_callLater(function()
			NirnAuctionHouse.list.filterDropCrafting:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterCraftingId,true)
		end, 50)
	end
	
	end
	
	if NAH.settings.data.SearchSettings.CurrentFilterCraftingId then
		if NAH.settings.data.SearchSettings.CurrentFilterSubId then	
			NirnAuctionHouse.list:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_" .. NAH.settings.data.SearchSettings.CurrentFilterSubId .. "_", 15);	
		zo_callLater(function()
			NirnAuctionHouse.list.filterDropCrafting:SelectItemByIndex(NAH.settings.data.SearchSettings.CurrentFilterCraftingId,true)
		end, 50)
		else	
			NirnAuctionHouse.list.filterDropCrafting:UpdateChoicesComboBox(NirnAuctionHouse.list.filterDropCrafting, "SI_NAH_FILTERDROP_CRAFTING_1_", 1);
		zo_callLater(function()
			NirnAuctionHouse.list.filterDropCrafting:SelectItemByIndex(1,true)
		end, 50)
		end
	end
	

	
	if NAH.settings.data.SearchSettings.CurrentSearch then
	NirnAuctionHouse.list.My_searchBox:SetText(NAH.settings.data.SearchSettings.CurrentSearch)
	end
	
	

	
	
	
	
	
	
	
	
	if NAH.settings.data.SearchSettings.currentSortKey then
	NirnAuctionHouse.list.currentSortKey = NAH.settings.data.SearchSettings.currentSortKey;
	end
	if NAH.settings.data.SearchSettings.currentSortOrder then
	NirnAuctionHouse.list.currentSortOrder = NAH.settings.data.SearchSettings.currentSortOrder;
	end
	if NAH.settings.data.SearchSettings.currentSortKey or NAH.settings.data.SearchSettings.currentSortOrder  then	
	NirnAuctionHouse.list.sortHeaderGroup:SelectAndResetSortForKey(NirnAuctionHouse.list.currentSortKey);
	end
	
	
	
	if NAH.settings.data.SearchSettings.currentSortKey_sold then
	NirnAuctionHouse.SoldItemList.currentSortKey = NAH.settings.data.SearchSettings.currentSortKey_sold;
	end
	if NAH.settings.data.SearchSettings.currentSortOrder_sold then
	NirnAuctionHouse.SoldItemList.currentSortOrder = NAH.settings.data.SearchSettings.currentSortOrder_sold;
	end

	end -- if NirnAuctionHouse.list not nil

	if NAH.settings.ReloadTradeDataTracked then
	NAH.settings.ReloadTradeDataTracked=false;
	end
	
	if NAH.settings.ReloadTradeData then
	NAH.settings.ReloadTradeData=false;
	end
	
	if NAH.settings.PostPaidOrders then
	NAH.settings.PostPaidOrders=false;
	NAH.settings.data.PaidOrders = {}
	end
	
	if NAH.settings.PostFilledOrders then
	NAH.settings.PostFilledOrders=false;
	NAH.settings.data.FilledOrders = {}
	end
	
	if NAH.settings.PostListings then
	NAH.settings.PostListings=false;
	NAH.settings.data.Listings = {}
	end
	
	if NAH.settings.PostBids then
	NAH.settings.PostBids=false;
	NAH.settings.data.Bids = {}
	end
	
	
	if NAH.settings.ReloadingUI then 
	NAH.settings.ReloadingUI=false
	end

	
	if (NirnAuctionHouse.list~=nil) then 
	NirnAuctionHouse.list.initiatedAlready=true--initiated saved search history -- until this flag is set no changes to search settigns will be saved
	end
	
	NirnAuctionHouse:setActiveAccount()
	
end



function NirnAuctionHouse:ProcInbox()
local mailId
local lastMailId
local NumMailItems=GetNumMailItems()
   if NumMailItems > 0 then    
--~    d("You've got mail")
	for Mailnum=0, NumMailItems, 1 do
	   mailId=GetNextMailId(mailId)
	   if mailId ~= nil and lastMailId ~= mailId then
	   lastMailId=mailId
	   local senderDisplayName,_,subject,_,_,fromSystem,fromCustomerService,returned,numAttachments,attachedMoney,codAmount,_,_ =GetMailItemInfo(mailId)
	    if returned==false and fromSystem==false and fromCustomerService==false and subject=="Nirn Auction House Order" and codAmount > 0 and numAttachments > 0 then
		mailinfo(mailId,codAmount)
	   end
	   end
	end
   end
   end



function NirnAuctionHouse:OnInboxUpdate()
--~ 		zo_callLater(function()
			NAH.settings.ActiveTab="";
			SCENE_MANAGER:Show("mailInbox");
			NirnAuctionHouse:ProcInbox()
--~ 		end, 50)
end

function NirnAuctionHouse:OnMailNumUnreadChanged(numUnread)
   if numUnread > 0 then        
--~ 		zo_callLater(function()
			NirnAuctionHouse:ProcInbox()
--~ 		end, 500)
   end
end

function mailinfo(mailId,codAmount)
zo_callLater(function()
		
		
	local itemLink=GetAttachedItemLink(mailId,1,LINK_STYLE_DEFAULT)
	if itemLink~=nil and itemLink~="" then
	CacheFilledOrderInMail(mailId,itemLink,codAmount)

		else
		zo_callLater(function()
		itemLink=GetAttachedItemLink(mailId,1,LINK_STYLE_DEFAULT)
		if itemLink~=nil and itemLink~="" then
		CacheFilledOrderInMail(mailId,itemLink,codAmount)
		else
		
			zo_callLater(function()
			itemLink=GetAttachedItemLink(mailId,1,LINK_STYLE_DEFAULT)
			if itemLink~=nil and itemLink~="" then
			CacheFilledOrderInMail(mailId,itemLink,codAmount)
			else			
					zo_callLater(function()
				itemLink=GetAttachedItemLink(mailId,1,LINK_STYLE_DEFAULT)
				if itemLink~=nil and itemLink~="" then
				CacheFilledOrderInMail(mailId,itemLink,codAmount)
				else			
					itemLink=GetAttachedItemLink(mailId,1,LINK_STYLE_DEFAULT)
					if itemLink~=nil and itemLink~="" then
					CacheFilledOrderInMail(mailId,itemLink,codAmount)
					end
				end
				end, 800)
			end
			end, 800)
		
		end
		end, 800)
		end
		
		end, 50)
	end
	
	
	
	
	
	function CacheFilledOrderInMail(mailId,itemLink,codAmount)
		
		
		local senderDisplayName,senderCharacterName=GetMailSender(mailId)
		local icon,stack,creatorName,sellPrice,meetsUsageRequirement,equipType,itemStyleId,ItemQuality=GetAttachedItemInfo(mailId,1)
		ItemQuality=GetItemLinkQuality(itemLink)
		local itemCharges=GetItemLinkNumEnchantCharges(itemLink)
		sellPrice=GetItemLinkValue(itemLink,true)
		local itemId=NirnAuctionHouse:GetItemID(itemLink)
		--~ 	d("senderDisplayName: "..senderDisplayName)
		--~ 	d("stack: "..stack)
		--~ 	d("sellPrice: "..sellPrice)
		--~ 	d("quality: "..ItemQuality)
		--~ 	d("itemLink: "..itemLink)
		--~ 	d("itemId: "..itemId)
	
	
		mailId=tostring(mailId)
		if(not NAH.settings.data.ReceivedOrders)then
		NAH.settings.data.ReceivedOrders = {}
		end
		if(not NAH.settings.data.ReceivedOrders[mailId])then		
		d("Auction Order Recieved in mail: "..itemLink)
		NAH.settings.data.ReceivedOrders[mailId] = {}			
		end

		NAH.settings.data.ReceivedOrders[mailId].senderDisplayName =senderDisplayName
		NAH.settings.data.ReceivedOrders[mailId].itemId =itemId
		NAH.settings.data.ReceivedOrders[mailId].stack =stack
		NAH.settings.data.ReceivedOrders[mailId].itemQuality =ItemQuality
		NAH.settings.data.ReceivedOrders[mailId].sellPrice =sellPrice
		NAH.settings.data.ReceivedOrders[mailId].codAmount =codAmount
	end
	
	

	
function NirnAuctionHouse:OnTakeAttachedItemSuccess(mailId)
--~ 	d("OnTakeAttachedItemSuccess: "..mailId)
zo_callLater(function()
		mailId=tostring(mailId)
	local Maildata=NAH.settings.data.ReceivedOrders[mailId];
--~ 	d("senderDisplayName: "..Maildata.senderDisplayName)
--~ 	d("stack: "..Maildata.stack)
--~ 	d("sellPrice: "..Maildata.sellPrice)
--~ 	d("quality: "..Maildata.itemQuality)
	--d("itemLink: "..itemLink)
--~ 	d("itemId: "..Maildata.itemId)
--~ 	d("mailId: "..mailId)
	if Maildata~=nil then
	if Maildata.itemId ~=nil then
	if(not NAH.settings.data.PaidOrders)then
		NAH.settings.data.PaidOrders = {}
	end
	if(not NAH.settings.data.PaidOrders[mailId])then
		NAH.settings.data.PaidOrders[mailId] = {}			
	end
		NAH.settings.data.PaidOrders[mailId].Seller =Maildata.senderDisplayName
		NAH.settings.data.PaidOrders[mailId].Buyer =NAH.settings.ActiveAccount
		NAH.settings.data.PaidOrders[mailId].ItemID =Maildata.itemId
		NAH.settings.data.PaidOrders[mailId].stack =Maildata.stack
		NAH.settings.data.PaidOrders[mailId].itemQuality =Maildata.itemQuality
		NAH.settings.data.PaidOrders[mailId].sellPrice =Maildata.sellPrice
		NAH.settings.data.PaidOrders[mailId].codAmount =Maildata.codAmount
		NAH.settings.data.PaidOrders[mailId].mailId =mailId
		NAH.settings.PostPaidOrders=true;-- tell the server link to post PaidOrders 
		NirnAuctionHouse:forceWriteSavedVars()
		end
		end
			end,2000)
end

	
	
	

-- Addon initialization
function NirnAuctionHouse:OnLoad(eventCode, addOnName)
	if(addOnName ~= "NirnAuctionHouse") then return end
	
	
	NAH.WroteDataFileYet=false
	
	
	-- Load saved settings
	NAH.settings = ZO_SavedVars:NewAccountWide("NirnAuctionHouseData", 1, nil, defaultSettings)
	NAH.SearchResults = ZO_SavedVars:NewAccountWide("NirnAuctionHouseSearchResults", 1, nil, {})
	
	d("loaded settigns")
	
	
	if NirnAuctionHouse.LoadTrades ~=nil then	
	NirnAuctionHouse:LoadTrades()	
	end
	
	if NirnAuctionHouse.LoadBids ~=nil then	
	NirnAuctionHouse:LoadBids()	
	end

	if NirnAuctionHouse.LoadTrackedBids ~=nil then	
	NirnAuctionHouse:LoadTrackedBids();
	end
	
	
	
	NirnAuctionHouse_CloseGoldCost()
	NirnAuctionHouse_CloseGoldCostBid()
	
	NAHAuctionHouseOrdersPanel:SetHidden(true);  
	
	NirnAuctionHouse.list = NAHAuctionList:New(NirnAuctionHousePanel);	
		NirnAuctionHouse.SoldItemList = NAHSoldItemList:New(NAHAuctionHouseOrdersPanel);
	NirnAuctionHouse.TrackingItemList = NAHTrackedItemList:New(NAHAuctionHouseTrackingPanel);
	NirnAuctionHouse.GoldCostPanel = NAHAuctionHouseGoldCost:GetNamedChild("GoldAmount");
	
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_INBOX_UPDATE", EVENT_MAIL_INBOX_UPDATE, function() NirnAuctionHouse:OnInboxUpdate() end)
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_NUM_UNREAD_CHANGED", EVENT_MAIL_NUM_UNREAD_CHANGED, function(_, numUnread) NirnAuctionHouse:OnMailNumUnreadChanged(numUnread) end)
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_OPEN_MAILBOX", EVENT_MAIL_OPEN_MAILBOX, function(_) NAH.settings.ActiveTab="";SCENE_MANAGER:Show("mailInbox");NirnAuctionHouse:ProcInbox() end)
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS", EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, function(_, mailId) NirnAuctionHouse:OnTakeAttachedItemSuccess(mailId) end)
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_SEND_SUCCESS", EVENT_MAIL_SEND_SUCCESS, function() NirnAuctionHouse:MailSent() end)
  EVENT_MANAGER:RegisterForEvent("NAH_EVENT_MAIL_SEND_FAILED", EVENT_MAIL_SEND_FAILED, function() NirnAuctionHouse:MailFailed() end)

	EVENT_MANAGER:RegisterForEvent("NAH_PLAYER_UNLOADED_EVENTS", EVENT_PLAYER_DEACTIVATED, NAH_EventOnPlayerUnloaded)
	EVENT_MANAGER:RegisterForEvent("NAH_EVENT_PLAYER_ACTIVATED", EVENT_PLAYER_ACTIVATED, NAH_SetAccountCharData)
	
	
  
	
	ZO_PreHook('ZO_InventorySlot_ShowContextMenu', function(rowControl) self:NAH_OnRightClickUp(rowControl) end)
	
	
	ZO_CreateStringId("SI_BINDING_NAME_NAH_TOGGLE_AUCTION_HOUSE", "Show/Hide Auction Window")
	ZO_CreateStringId("SI_BINDING_NAME_NAH_REFRESH_AUCTION_HOUSE", "Refresh Auction House Data")
	ZO_CreateStringId("SI_BINDING_NAME_NAH_TOGGLE_AUCTION_BUTTONS", "Show/Hide Auction Buttons")
	
	local NAHButton = {
		name = "Show/Hide Auction Window",
		keybind = "NAH_TOGGLE_AUCTION_HOUSE",
	}
	if (not KEYBIND_STRIP:HasKeybindButton(NAHButton)) then
		KEYBIND_STRIP:AddKeybindButton(NAHButton)	
	end
	---
	
	NAHButton = {
		name = "Refresh Auction House Data",
		keybind = "NAH_REFRESH_AUCTION_HOUSE",
	}
	if (not KEYBIND_STRIP:HasKeybindButton(NAHButton)) then
		KEYBIND_STRIP:AddKeybindButton(NAHButton)	
	end
	---
	NAHButton = {
		name = "Show/Hide Auction Buttons",
		keybind = "NAH_TOGGLE_AUCTION_BUTTONS",
	}
	if (not KEYBIND_STRIP:HasKeybindButton(NAHButton)) then
		KEYBIND_STRIP:AddKeybindButton(NAHButton)	
	end
	---
	

	
	
	SLASH_COMMANDS["/ah"] = function(...) self:CommandHandler(...) end
	SLASH_COMMANDS["/nah"] = function(...) self:CommandHandler(...) end
	SLASH_COMMANDS["/NirnAuctionHouse"] = function(...) self:CommandHandler(...) end

	
	if KEYBIND_STRIP:HasKeybindButtonGroup(keybindDescriptor) then
			KEYBIND_STRIP:RemoveKeybindButtonGroup(keybindDescriptor) 
		end
	

	
	
	self.menu:InitAddonMenu()

	NirnAuctionHouse:SetItemBadgeHooks()
	
	-----------------------------------add rigth click price check to item links--------------------------------------------------
	LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, function(link, button, keyword, linkStyle, linkType)
	if(linkType == "item" and link~= nil and link~="") then	
	if( button==2) then	
	NAH.Link_MenuItem="";		
		zo_callLater(function()		
		if NAH.Link_MenuItem =="" then
		NAH.Link_MenuItem = link
		
		--AddMenuItem("Price Check", function() self:PriceCheckItem(control,false) end, MENU_ADD_OPTION_LABEL)--output only visible to user
		AddMenuItem(GetString(SI_NAH_STRING_PRICECHECK), function() NirnAuctionHouse:PriceCheckItemLink(link,true) end, MENU_ADD_OPTION_LABEL)
		  ShowMenu()
		return true
		end
		end, 1)
		
	end
	end
end)
-----------------------------------------------------------------------------------------

	
	ZO_PreHookHandler(PopupTooltip, 'OnHide', function() PopupTooltip.PCYet=nil;PopupTooltip.PCUID=nil end)
--~ 	
		  ZO_PreHookHandler(PopupTooltip, 'OnUpdate', function()
			if PopupTooltip.PCUID==nil then 
				if PopupTooltip.lastLink~=nil then 
				local itemLink = PopupTooltip.lastLink	
					if itemLink == nil then	
						return
					end
				PopupTooltip.PCUID=itemLink
				NirnAuctionHouse:PCtoTooltip(PopupTooltip,stackCount,itemLink,"::popup::")
				end
			end
			end)
	
	ZO_PreHookHandler(ItemTooltip, 'OnHide', function() ItemTooltip.PCYet=nil end)
--~ 	
		  ZO_PreHookHandler(ItemTooltip, 'OnUpdate', function()	  
		    local hoveredElem = WINDOW_MANAGER:GetMouseOverControl()	    

	  
		    if(hoveredElem~=nil and hoveredElem.dataEntry~=nil )then	   
		    if(hoveredElem.dataEntry.data~=nil and hoveredElem.dataEntry.data.bagId~=nil and hoveredElem.dataEntry.data.slotIndex~=nil)then	    
		    local bagId = hoveredElem.dataEntry.data.bagId
	local slotIndex = hoveredElem.dataEntry.data.slotIndex
	local stackCount = hoveredElem.dataEntry.data.stackCount
	local itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)	
	if itemLink == nil then	
		return
	end
		NirnAuctionHouse:PCtoTooltip(ItemTooltip,stackCount,itemLink,"::"..bagId.."::"..slotIndex)
		end
		end
		end) 

	
end



function NirnAuctionHouse:setActiveAccount()
NAH.currentCharacterId = GetCurrentCharacterId()
	NAH.currentAccount = GetDisplayName()
	NAH.settings.WorldName=GetWorldName("");--Returns "NA Megaserver"
	NAH.settings.ActiveAccount=NAH.currentAccount
	NAH.settings.ActiveCharacterId=NAH.currentCharacterId
	NAH.settings.CurCharacterId=NAH.currentCharacterId
	end
	
	
function NirnAuctionHouse:clearActiveAccount()
	self:clearActiveAccountNoRefresh()
	self:forceWriteSavedVars()
	end
	
	
	
	
function NirnAuctionHouse:clearActiveAccountNoRefresh()
NAH.currentCharacterId = ""
	NAH.currentAccount = ""
	NAH.settings.ServerLink_INITIATED=false;
	NAH.settings.ActiveAccount=NAH.currentAccount
	NAH.settings.ActiveCharacterId=NAH.currentCharacterId
	end
	
	
	function NirnAuctionHouse:forceWriteSavedVars()
	NAH.settings.ReloadingUI=true
	ReloadUI("ingame")
	end
	
	
-- Handle slash commands
function NirnAuctionHouse:CommandHandler(text)
	text = text:lower()

	if #text == 0 or text == "help" then
		self:ShowHelp()
		return
	end
	
	if text == "show_account" then
		d("Curr Account" .. NAH.currentAccount)
		return
	end
	
	
	
	
	if text == "set_account" then
		self:setActiveAccount()
		return
	end
	
	
	
	if text == "clear_account" then
		self:clearActiveAccount()
		return
	end
	
	
	
	

	if text == "init" then
		NirnAuctionHouse_ServerLink_INITIATED( )
		return
	end

	if text == "showah" then
		self:NAHWindow_show()
		return
	end
	
	if text == "openah" then
		self:NAHWindow_Open()
		return
	end
	if text == "clear" then
		NAH.settings.data.ReceivedOrders={}
		NAH.settings.data.PaidOrders = {}
		return
	end
	

	if text == "closeah" then
		self:NAHWindow_hide()
		return
	end
	
	
	
	
end



function NirnAuctionHouse:COD(to,ItemLink,stackCount,amount)
local locatedbagslot = nil
			locatedbagslot = NirnAuctionHouse:SearchBag(1,ItemLink,stackCount)
			if locatedbagslot~=nil then
			if CanItemBePlayerLocked(1, locatedbagslot) then
			SetItemIsPlayerLocked(1, locatedbagslot, false)
			end
 local codcost=10+math.floor(amount/20)
 SCENE_MANAGER:Hide("mailSend");
 SCENE_MANAGER:Show("mailSend");
 
	zo_callLater(function()
			QueueItemAttachment(1, locatedbagslot, 1)
	d("Queued Attachment")
	zo_callLater(function()
	QueueCOD(amount)
	zo_callLater(function()
	SendMail(to, "Nirn Auction House Order", "Order for " .. to .. ", Containing: " .. ItemLink .. " x" .. stackCount .. " for " .. amount .. " |t18:18:esoui/art/currency/currency_gold_32.dds|t COD (postage: " .. codcost .. "|t18:18:esoui/art/currency/currency_gold_32.dds|t )")
			d("Order Filled")
		end, 800)
		end, 200)
		end, 900)
	
			else
	d("Failed to find "..ItemLink)			
			end
	--end
	end



function NirnAuctionHouse:SendMail(to,subject,message)
	if SCENE_MANAGER.currentScene.name == 'mailSend' then 

	SendMail(to, subject, message)
	
	d("mail sent")
	else
	RequestOpenMailbox()	
	zo_callLater(function()
			SendMail(to, subject, message)
			d("mail sent")
	zo_callLater(function()
			CloseMailbox()
		end, 1000)
		end, 300)
	
	end
	end


function NirnAuctionHouse:ShowHelp()
	d("/nah help - Show this help")
	d("/nah init - Initiate Auction House Server Link")
	d("/nah showah - Open Auction House")
	d("/nah closeah - close Auction House")
	d("/nah openah - Open Auction House after a fresh reload")
end


function NirnAuctionHouse:OnLinkClicked(rawLink, mouseButton, linkText, linkStyle, linkType, itemId, ...)
	if linkType ~= ITEM_LINK_TYPE then return end

	local item = {
		dataEntry = {
			data = {
				stackCount = 1,
				itemId = itemId,
				level = self:GetItemLevel(rawLink),
				quality = GetItemLinkQuality(rawLink),
			}
		}
	}
	self.clickedItem = item
end

	




function NirnAuctionHouse:GetItemLink(item)
	if not item or not item.GetParent then return nil end

	local parent = item:GetParent()
	if not parent then return nil end
	local parentName = parent:GetName()

	if parentName == "ZO_PlayerInventoryQuestContents" then
		return nil
	end
	if parentName == "ZO_StoreWindowListContents" then
		return GetStoreItemLink(item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
	end
	if parentName == "ZO_TradingHouseItemPaneSearchResultsContents" then
		if item.dataEntry.data.timeRemaining > 0 then
			return GetTradingHouseSearchResultItemLink(item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
		end
		return nil
	end
	if parentName == "ZO_TradingHousePostedItemsListContents" then
		return GetTradingHouseListingItemLink(item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
	end
	if parentName == "ZO_BuyBackListContents" then
		return GetBuybackItemLink(item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
	end
	if parentName:find("ZO_ListDialog%d+ListContents") then
		if item.dataEntry and item.dataEntry.data then 
			return GetItemLink(item.dataEntry.data.bag, item.dataEntry.data.index, LINK_STYLE_DEFAULT)
		end
		return nil
	end
	if parentName == "ZO_LootAlphaContainerListContents" then
		return GetLootItemLink(item.dataEntry.data.lootId, LINK_STYLE_DEFAULT)
	end
	if parentName == "NirnAuctionHousePanelListContents" then
		return item.data.itemLink
	end

	if item.bagId and item.slotIndex then
		return GetItemLink(item.bagId, item.slotIndex, LINK_STYLE_DEFAULT)
	end
	if item.dataEntry and item.dataEntry.data and item.dataEntry.data.bagId and item.dataEntry.data.slotIndex then  
		return GetItemLink(item.dataEntry.data.bagId, item.dataEntry.data.slotIndex, LINK_STYLE_DEFAULT)
	end

	d("Could not get item link for " .. parentName)
	return nil
end

function NirnAuctionHouse:GetItemLevel(itemLink)
	local level = GetItemLinkRequiredLevel(itemLink)
	if level == 50 then
		level = level + GetItemLinkRequiredVeteranRank(itemLink)
	end
	return level
end


function NirnAuctionHouse:NAH_OnRightClickUp(rowControl)
		self:ProcessRightClick(rowControl)
	end
	
	
	

	
function NirnAuctionHouse:ProcessRightClick(control)
	if control == nil then
--~ 	d("control is not set.")
		return
	end

	local bagId = control.bagId
	local slotIndex = control.slotIndex
	local ItemBound = IsItemBound(bagId,slotIndex)
	local ItemStolen = IsItemStolen(bagId,slotIndex)
	local ItemBoPTradable = IsItemBoPAndTradeable(bagId,slotIndex)	
--~ 			
				
	local stackCount = control.stackCount
	itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)	
	if itemLink == nil then
		return
	end
	local _, _, _, itemId = ZO_LinkHandler_ParseLink(itemLink)
	
	zo_callLater(function()
		--AddMenuItem("Price Check", function() self:PriceCheckItem(control,false) end, MENU_ADD_OPTION_LABEL)--output only visible to user
		AddMenuItem(GetString(SI_NAH_STRING_PRICECHECK), function() self:PriceCheckItem(control,true) end, MENU_ADD_OPTION_LABEL)
		end, 20
			)
	if ItemBound ~= true and ItemStolen ~= true and ItemBoPTradable ~= true then

				
		local Charges,_ =GetChargeInfoForItem(bagId, slotIndex)		
		local itemQuality=GetItemLinkQuality(itemLink)
		local sellPrice=GetItemLinkValue(itemLink,true)	
	local _hasCharges,_enchantHeader,_enchantDescription = GetItemLinkEnchantInfo(itemLink)
	local _hasAbility,_abilityHeader,_abilityDescription,_,_,_,_,_ = GetItemLinkOnUseAbilityInfo(itemLink)
	local _traitType,_traitDescription,_traitSubtype,_traitSubtypeName,_traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	
	
	local requiredLevel=GetItemLinkRequiredLevel(itemLink)
local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)
				
									
		zo_callLater(function()
		local tmpMyListedTrade=NirnAuctionHouse:IsItemListedAlready(itemId, stackCount ,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,_enchantHeader,_abilityHeader,_traitType)
				
		AddMenuItem(GetString(SI_NAH_STRING_AUCTIONITEM), function() self:AuctionOffItem(control) end, MENU_ADD_OPTION_LABEL)
			
			if ( tmpMyListedTrade~=nil and tmpMyListedTrade~=false  and tmpMyListedTrade.TradeID ) then			
				if ( tmpMyListedTrade.IsSoldItem) then	
				AddMenuItem(GetString(SI_NAH_STRING_FULFILLORDER), function() NirnAuctionHouse_ToggleOrders() end, MENU_ADD_OPTION_LABEL)
--~ 				AddMenuItem("Fulfill Order", function() NirnAuctionHouse_FillOrderData(tmpMyListedTrade) end, MENU_ADD_OPTION_LABEL)--fills order withought openiong sold window-- better to show details first
				else			
				AddMenuItem(GetString(SI_NAH_STRING_CANCELAUCTION), function() NirnAuctionHouse_CancelListing_func(tmpMyListedTrade.TradeID,itemLink ) end, MENU_ADD_OPTION_LABEL)
				end
				else
				
			end
			ShowMenu(control)
			end, 70
			)
			
	end
	
end



function NirnAuctionHouse:GetItemID(itemLink)
	local ret = nil
	if (itemLink) then
		local data = itemLink:match("|H.:item:(.-)|h.-|h")
		local itemID = zo_strsplit(':', data)	
		ret = itemID
	end
	return ret
end


function NirnAuctionHouse:SearchBag(bagId,itemLink,qty)
bagItems = GetBagSize and GetBagSize(bagId)
local itemCharges=GetItemLinkNumEnchantCharges(itemLink)
local sellPrice=GetItemLinkValue(itemLink,true)
local itemId=NirnAuctionHouse:GetItemID(itemLink)
local ItemQuality=GetItemLinkQuality(itemLink)


	local _hasCharges,_enchantHeader,_enchantDescription = GetItemLinkEnchantInfo(itemLink)
	local _hasAbility,_abilityHeader,_abilityDescription,_,_,_,_,_ = GetItemLinkOnUseAbilityInfo(itemLink)
	local _traitType,_traitDescription,_traitSubtype,_traitSubtypeName,_traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	local requiredLevel=GetItemLinkRequiredLevel(itemLink)
local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)

--~ 	d("Searching for Copper: "..qty.." ["..sellPrice.."]["..itemId.."]["..ItemQuality.."]["..itemCharges.."]")
		for slotNum=0, bagItems, 1 do
				local bagslotdata=self:ProcBagSlot(itemId,bagId, slotNum)
				if(bagslotdata~=nil) then	
				
				if( tonumber(bagslotdata.itemId) == tonumber(itemId) and 
				tonumber(bagslotdata.sellPrice) == tonumber(sellPrice) and
				tonumber(bagslotdata.itemCharges) == tonumber(itemCharges) and
				tonumber(bagslotdata.itemQuality) == tonumber(ItemQuality) and
				bagslotdata.requiredLevel == requiredLevel and
				bagslotdata.requiredChampPoints == requiredChampPoints and
				bagslotdata._enchantHeader == _enchantHeader and
				bagslotdata._abilityHeader == _abilityHeader and
				bagslotdata._traitDescription == _traitDescription and
				tonumber(bagslotdata.stackCount) == tonumber(qty)) then			
--~ 			d("found Item: ".. itemName .. "x"..bagslotdata.stackCount)				
					return slotNum	
				
				end
				end
			end
			
			return nil
			end

function NirnAuctionHouse:ProcBagSlot(SearchItemId,bagId, slotNum)

	itemName = GetItemName(bagId, slotNum)
	if itemName > '' then
		itemLink = GetItemLink(bagId, slotNum, LINK_STYLE_BRACKETS)
		local itemId=NirnAuctionHouse:GetItemID(itemLink)
		if itemId==SearchItemId then
		local Charges,_ =GetChargeInfoForItem(bagId, slotNum)
		local itemIconFile, itemCount, _, _, _, equipType, _, itemQuality = GetItemInfo(bagId, slotNum)
		
		itemQuality=GetItemLinkQuality(itemLink)
		local sellPrice=GetItemLinkValue(itemLink,true)
		
	local _hasCharges,_enchantHeader,_enchantDescription = GetItemLinkEnchantInfo(itemLink)
	local _hasAbility,_abilityHeader,_abilityDescription,_,_,_,_,_ = GetItemLinkOnUseAbilityInfo(itemLink)
	local _traitType,_traitDescription,_traitSubtype,_traitSubtypeName,_traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)	
	local requiredLevel=GetItemLinkRequiredLevel(itemLink)
local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)

		local results = {}
		results.itemName=itemName
		results.itemId=itemId
		results.itemQuality=itemQuality
		results.sellPrice=sellPrice
		results.itemCharges=Charges
		results.itemLink=itemLink
		results.stackCount=tonumber(itemCount)
		results._enchantHeader=_enchantHeader
		results._abilityHeader=_abilityHeader
		results._traitDescription=_traitDescription
		results.requiredLevel=requiredLevel
		results.requiredChampPoints=requiredChampPoints
--~ 	d(itemName..": "..results.stackCount.." ["..results.sellPrice.."]["..results.itemId.."]["..results.itemQuality.."]["..results.itemCharges.."]")
		return results;
		end
		else
		
	end
	return nil
end




function NirnAuctionHouse:ReadableTraitType(TraitType)
		
if TraitType==ITEM_TRAIT_TYPE_ARMOR_DIVINES then return "ARMOR_DIVINES" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE then return "ARMOR_IMPENETRABLE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INFUSED then return "ARMOR_INFUSED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INTRICATE then return "ARMOR_INTRICATE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_NIRNHONED then return "ARMOR_NIRNHONED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_ORNATE then return "ARMOR_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS then return "ARMOR_PROSPEROUS" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_REINFORCED then return "ARMOR_REINFORCED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_STURDY then return "ARMOR_STURDY" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_TRAINING then return "ARMOR_TRAINING" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED then return "ARMOR_WELL_FITTED" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ARCANE then return "JEWELRY_ARCANE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_HEALTHY then return "JEWELRY_HEALTHY" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ORNATE then return "JEWELRY_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ROBUST then return "JEWELRY_ROBUST" end
if TraitType==ITEM_TRAIT_TYPE_NONE then return "NONE" end
if TraitType==ITEM_TRAIT_TYPE_SPECIAL_STAT then return "SPECIAL_STAT" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_CHARGED then return "WEAPON_CHARGED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DECISIVE then return "WEAPON_DECISIVE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DEFENDING then return "WEAPON_DEFENDING" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INFUSED then return "WEAPON_INFUSED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INTRICATE then return "WEAPON_INTRICATE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_NIRNHONED then return "WEAPON_NIRNHONED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_ORNATE then return "WEAPON_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_POWERED then return "WEAPON_POWERED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_PRECISE then return "WEAPON_PRECISE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_SHARPENED then return "WEAPON_SHARPENED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_TRAINING then return "WEAPON_TRAINING" end
end


function NirnAuctionHouse_ReadableTraitType(TraitType)
		
if TraitType==ITEM_TRAIT_TYPE_ARMOR_DIVINES then return "ARMOR_DIVINES" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE then return "ARMOR_IMPENETRABLE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INFUSED then return "ARMOR_INFUSED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INTRICATE then return "ARMOR_INTRICATE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_NIRNHONED then return "ARMOR_NIRNHONED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_ORNATE then return "ARMOR_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS then return "ARMOR_PROSPEROUS" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_REINFORCED then return "ARMOR_REINFORCED" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_STURDY then return "ARMOR_STURDY" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_TRAINING then return "ARMOR_TRAINING" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED then return "ARMOR_WELL_FITTED" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ARCANE then return "JEWELRY_ARCANE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_HEALTHY then return "JEWELRY_HEALTHY" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ORNATE then return "JEWELRY_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ROBUST then return "JEWELRY_ROBUST" end
if TraitType==ITEM_TRAIT_TYPE_NONE then return "NONE" end
if TraitType==ITEM_TRAIT_TYPE_SPECIAL_STAT then return "SPECIAL_STAT" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_CHARGED then return "WEAPON_CHARGED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DECISIVE then return "WEAPON_DECISIVE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DEFENDING then return "WEAPON_DEFENDING" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INFUSED then return "WEAPON_INFUSED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INTRICATE then return "WEAPON_INTRICATE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_NIRNHONED then return "WEAPON_NIRNHONED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_ORNATE then return "WEAPON_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_POWERED then return "WEAPON_POWERED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_PRECISE then return "WEAPON_PRECISE" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_SHARPENED then return "WEAPON_SHARPENED" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_TRAINING then return "WEAPON_TRAINING" end
end

function NirnAuctionHouse_ReadableTraitTypeNorm(TraitType)
		
if TraitType==ITEM_TRAIT_TYPE_ARMOR_DIVINES then return "Divines" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE then return "Impenetrable" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INFUSED then return "Infused" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_INTRICATE then return "Intricate" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_NIRNHONED then return "Nirnhoned" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_ORNATE then return "Ornate" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS then return "Prosperous" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_REINFORCED then return "Reinforced" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_STURDY then return "Sturdy" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_TRAINING then return "Training" end
if TraitType==ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED then return "Well-Fitted" end

if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ARCANE then return "JEWELRY_ARCANE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_HEALTHY then return "JEWELRY_HEALTHY" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ORNATE then return "JEWELRY_ORNATE" end
if TraitType==ITEM_TRAIT_TYPE_JEWELRY_ROBUST then return "JEWELRY_ROBUST" end
if TraitType==ITEM_TRAIT_TYPE_NONE then return "NONE" end
if TraitType==ITEM_TRAIT_TYPE_SPECIAL_STAT then return "SPECIAL_STAT" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_CHARGED then return "Charged" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DECISIVE then return "Decisive" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_DEFENDING then return "Defending" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INFUSED then return "Infused" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_INTRICATE then return "Intricate" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_NIRNHONED then return "Nirnhoned" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_ORNATE then return "Ornate" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_POWERED then return "Powered" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_PRECISE then return "Precise" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_SHARPENED then return "Sharpened" end
if TraitType==ITEM_TRAIT_TYPE_WEAPON_TRAINING then return "Training" end
end


function NirnAuctionHouse_CloseGoldCostBid()
    NAHAuctionHouseGoldCostBid:SetHidden(true)
end

function NirnAuctionHouse_OpenGoldCostBid()
    NAHAuctionHouseGoldCostBid:SetHidden(false)
end

function NirnAuctionHouse_CloseGoldCost()
    NAHAuctionHouseGoldCost:SetHidden(true)
end

function NirnAuctionHouse_OpenGoldCost()
    NAHAuctionHouseGoldCost:SetHidden(false)
end

function NirnAuctionHouse_Docancel_BidOrder()

	NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId] = {}			
	NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid ={}
NirnAuctionHouse_CloseGoldCostBid()
end

function NirnAuctionHouse_DoPost_BidOrder(GoldAmountPanel)


NirnAuctionHouse.GoldAmountBidcont = NAHAuctionHouseGoldCostBid:GetNamedChild("GoldAmountBid");
NirnAuctionHouse.GoldAmountBid = NirnAuctionHouse.GoldAmountBidcont:GetNamedChild("GoldAmountBoxBid");
NirnAuctionHouse.GoldAmountBidVal = tonumber(NirnAuctionHouse.GoldAmountBid:GetText());

 if not NirnAuctionHouse.GoldAmountBidVal or NirnAuctionHouse.GoldAmountBidVal < 1 then  d("Please Enter a Valid Bid") return; end
 if (GetCurrentMoney() +GetBankedMoney()) < NirnAuctionHouse.GoldAmountBidVal then  d("You do Not Have Enough Gold In your Inventory For this Bid") return; end

	if(not NAH.settings.data.Bids)then
		NAH.settings.data.Bids = {}
	end
	if(not NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId])then
			NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId] = {}			
			NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid ={}
	end

	if(not NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid)then	
			NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid ={}
	end
	
	if(not NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.Price)then	
			NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.Price =1
	end
	
	 if NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.Price >= NirnAuctionHouse.GoldAmountBidVal then  d("Please Enter a Bid of at least: " .. tonumber(NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.Price)+1) return; end
 
 if (NirnAuctionHouse.GoldAmountBidVal ~=nil and NirnAuctionHouse.GoldAmountBidVal > 2100000000) then d("Please Enter at least Valid Bid (2,100,000,000 Max)") return; end 
	
NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.Price=NirnAuctionHouse.GoldAmountBidVal;


d("Queued Bid for: " .. NAH.settings.data.Bids[NirnAuctionHouse.ActiveBidListingId].Bid.ItemLink .. " sync to post now")
 
	NAH.settings.PostBids=true;-- tell the server link to post Bids 
	NirnAuctionHouse_CloseGoldCostBid();
	
	 if NAH.settings.AutoPost and NAH.settings.AutoPost == true then
	NirnAuctionHouse:forceWriteSavedVars()
	end

end
function NirnAuctionHouse_DocancelListing()
	if(not NAH.settings.data.Listings)then
		NAH.settings.data.Listings = {}
	end
	if(NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId])then
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId] = {}			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing ={}
	end
NirnAuctionHouse_CloseGoldCost()
end

function NirnAuctionHouse_DoPostListing(GoldAmountPanel)


	if(not NAH.settings.data.Listings)then
		NAH.settings.data.Listings = {}
	end
	if(not NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId])then
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId] = {}			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing ={}
	end

NirnAuctionHouse.GoldAmountStarting = NAHAuctionHouseGoldCost:GetNamedChild("GoldAmountStarting"):GetNamedChild("GoldAmountBoxStarting");
NirnAuctionHouse.GoldAmountBuyout = NAHAuctionHouseGoldCost:GetNamedChild("GoldAmountBuyout"):GetNamedChild("GoldAmountBoxBuyout");



NirnAuctionHouse.GoldAmountStartingVal = tonumber(NirnAuctionHouse.GoldAmountStarting:GetText());
NirnAuctionHouse.GoldAmountBuyoutVal = tonumber(NirnAuctionHouse.GoldAmountBuyout:GetText());
 if (not NirnAuctionHouse.GoldAmountStartingVal or NirnAuctionHouse.GoldAmountStartingVal < 1 ) then   if not NirnAuctionHouse.GoldAmountBuyoutVal or NirnAuctionHouse.GoldAmountBuyoutVal < 1 then  d("Please Enter at least Valid Starting Bid or a Valid Buyout Bid") return; end end
 if (NirnAuctionHouse.GoldAmountStartingVal ~=nil and NirnAuctionHouse.GoldAmountStartingVal > 2099999999) then d("Please Enter at least Valid Starting Bid (2,099,999,999 Max)") return; end 
 if (NirnAuctionHouse.GoldAmountBuyoutVal ~=nil and NirnAuctionHouse.GoldAmountBuyoutVal > 2100000000) then d("Please Enter at least Valid Buyout Bid (2,100,000,000 Max)") return; end 


NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.StartingPrice=NirnAuctionHouse.GoldAmountStarting:GetText();
NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.BuyoutPrice=NirnAuctionHouse.GoldAmountBuyout:GetText();


if(NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.BuyoutPrice)then
NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.IsBuyout=1;
end


	
	if NirnAuctionHouse.ActivePostListingBag~=nil and NirnAuctionHouse.ActivePostListingSlot~=nil then
	if CanItemBePlayerLocked(NirnAuctionHouse.ActivePostListingBag, NirnAuctionHouse.ActivePostListingSlot) then
	SetItemIsPlayerLocked(NirnAuctionHouse.ActivePostListingBag, NirnAuctionHouse.ActivePostListingSlot, true)
	end
	end
d("Queued Listing for: " .. NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemLink .. " sync to post now")
	NAH.settings.PostListings=true;-- tell the server link to post listings 
--~ 	RequestOpenUnsafeURL("https://nirnah.com/debug/")
	NirnAuctionHouse_CloseGoldCost();
	
	 if NAH.settings.AutoPost and NAH.settings.AutoPost == true then
	NirnAuctionHouse:forceWriteSavedVars()
	end

end

function NirnAuctionHouse:PriceCheckItem(control,tochat)
	if NirnAuctionHouse.PriceTable==nil then
	NirnAuctionHouse:LoadPrices()
	if NirnAuctionHouse.PriceTable==nil then
	--d("No price table")
	return
	end
	end

	local itemLink	
	local bagId = control.bagId	
	local slotIndex = control.slotIndex
	local stackCount = control.stackCount
	local ItemSellValueWithBonuses = GetItemSellValueWithBonuses(bagId,slotIndex)
	
	itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
	
	if itemLink == nil then
		return
	end
	
NirnAuctionHouse:PriceCheckItemLink(itemLink,tochat)
	
	 
	

	
end
	
function NirnAuctionHouse:PriceCheckItemLink(itemLink,tochat)
	if NirnAuctionHouse.PriceTable==nil then
	NirnAuctionHouse:LoadPrices()
	if NirnAuctionHouse.PriceTable==nil then
	--d("No price table")
	return
	end
	end

	
	if itemLink == nil then
		return
	end
	
	local itemName = LocalizeString("<<t:1>>", GetItemLinkName(itemLink));
	local _, _, _, itemId = ZO_LinkHandler_ParseLink(itemLink)
	   
	local itemId=NirnAuctionHouse:GetItemID(itemLink)
local requiredLevel=GetItemLinkRequiredLevel(itemLink)
local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)
local ItemQuality=GetItemLinkQuality(itemLink)

	local statval=GetItemLinkWeaponPower(itemLink)+GetItemLinkArmorRating(itemLink, false)
local Priceuid=itemId..":"..ItemQuality..":"..statval..":"..requiredLevel..":"..requiredChampPoints	

	if NirnAuctionHouse.PriceTable[Priceuid] ~= nil then
	if NirnAuctionHouse.PriceTable[Priceuid].price ~= nil then
	if(tochat)then
	NirnAuctionHouse.AddToChat("Price Check: "..itemLink.." sells for "..NirnAuctionHouse.PriceTable[Priceuid].price.."(g)");	
	else
	d(GetString(SI_NAH_STRING_PRICECHECK)..": "..itemLink.." sells for "..NirnAuctionHouse.PriceTable[Priceuid].price.."|t18:18:esoui/art/currency/currency_gold_32.dds|t" );
	end
	end
	
	else
	d("No Price Data For  "..itemLink.."")	
	end
--~ 	d("Price check complete")
	
	 
	

	
end
	
function NirnAuctionHouse:AuctionOffItem(control)
	if NirnAuctionHouse.myListingsNum >= NirnAuctionHouse.myListingsMax then
	d("Auction Limit Reached: " .. NirnAuctionHouse.myListingsMax)
	return
end

	if NirnAuctionHouse.PriceTable==nil then
	NirnAuctionHouse:LoadPrices()
	end

	local itemLink	
	local bagId = control.bagId	
	local slotIndex = control.slotIndex
	local stackCount = control.stackCount
	
	itemLink = GetItemLink(bagId, slotIndex, LINK_STYLE_BRACKETS)
	itemName = LocalizeString("<<t:1>>", GetItemLinkName(itemLink));
	
	if itemLink == nil then
		return
	end
	

	local _, _, _, itemId = ZO_LinkHandler_ParseLink(itemLink)
	local level = self:GetItemLevel(itemLink)
	local quality = GetItemLinkQuality(itemLink)
	
--~ 	NirnAuctionHouse.ActivePostListingId=itemId
	NirnAuctionHouse.ActivePostListingBag=bagId
	NirnAuctionHouse.ActivePostListingSlot=slotIndex
	NirnAuctionHouse.ActivePostListingId=(1+(#NAH.settings.data.Listings))
	
	local itemLevel
	itemLevel = self:GetItemLevel(itemLink)
	
	local hasSetInfo, setName
	hasSetInfo, setName = GetItemLinkSetInfo(itemLink, false)


	local statVal = GetItemStatValue(bagId,slotIndex)
	local hasCharges,enchantHeader,enchantDescription = GetItemLinkEnchantInfo(itemLink)
	local traitType,traitDescription,traitSubtype,traitSubtypeName,traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	
	local ItemCharge = GetItemLinkNumEnchantCharges(bagId,slotIndex)
	local ItemChargeMax = GetItemLinkMaxEnchantCharges(itemLink)
	
	local ItemChargePercent = 0;
	
	if ItemChargeMax > 0 then 
	ItemChargePercentItemChargePercent=math.floor((ItemCharge/ItemChargeMax)*100)
	end
	
	local ItemCondition = GetItemLinkCondition(itemLink)
	local ItemWeaponPower = GetItemLinkWeaponPower(itemLink)
	local ItemArmorRating = GetItemLinkArmorRating(itemLink,false)
	local ItemType = GetItemLinkItemType(itemLink)
	local ItemWeaponType = GetItemLinkWeaponType(itemLink)
	local ItemArmorType = GetItemLinkArmorType(itemLink)
	
	local ItemRepairCost = GetItemRepairCost(bagId,slotIndex)
	local ItemRequiredLevel = GetItemLinkRequiredLevel(itemLink)
	local ItemRequiredChampionPoints = GetItemLinkRequiredChampionPoints(itemLink)
	local ItemSellValueWithBonuses = GetItemSellValueWithBonuses(bagId,slotIndex)
	
	local ItemBound = IsItemBound(bagId,slotIndex)
	
	if(not NAH.settings.data.Listings)then
		NAH.settings.data.Listings = {}
	end
	if(not NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId])then
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId] = {}			
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing ={} -- infor about your listing price and hoew long to list for
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.Price=ItemSellValueWithBonuses --in gold -- just set to vendor cost atm
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].Listing.Expire=30 --in days
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes ={}
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemLink = itemLink
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.itemId = itemId
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.itemLevel = itemLevel
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.itemQuality = quality
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.itemName = itemName
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.stackCount = stackCount
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.itemStatVal=statVal
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.setName=setName
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant ={}
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.ItemChargePercent = ItemChargePercent
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.ItemCharge = ItemCharge
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.ItemChargeMax = ItemChargeMax
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.hasCharges = hasCharges
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.enchantHeader = enchantHeader
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Enchant.enchantDescription = enchantDescription
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait ={}
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait.traitType = self:ReadableTraitType(traitType)
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait.traitDescription = traitDescription
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait.traitSubtype = self:ReadableTraitType(traitSubtype)
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait.traitSubtypeName = traitSubtypeName
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Trait.traitSubtypeDescription = traitSubtypeDescription
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemRequiredLevel = ItemRequiredLevel
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemRequiredChampionPoints = ItemRequiredChampionPoints
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemWeaponPower = ItemWeaponPower
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.ItemArmorRating = ItemArmorRating
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Type ={}
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Type.ItemType = ItemType
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Type.ItemWeaponType = ItemWeaponType
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Type.ItemArmorType = ItemArmorType
			
			
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Condition ={}
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Condition.ItemSellValueWithBonuses =ItemSellValueWithBonuses
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Condition.ItemRepairCost =ItemRepairCost
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Condition.ItemCondition =ItemCondition
			NAH.settings.data.Listings[NirnAuctionHouse.ActivePostListingId].attributes.Condition.ItemCondition =ItemCondition
			
	end
	
	
	NirnAuctionHouse.GoldAmountStarting = NAHAuctionHouseGoldCost:GetNamedChild("GoldAmountStarting"):GetNamedChild("GoldAmountBoxStarting");
	NirnAuctionHouse.GoldAmountBuyout = NAHAuctionHouseGoldCost:GetNamedChild("GoldAmountBuyout"):GetNamedChild("GoldAmountBoxBuyout");
	
	local codcost=10+math.floor(ItemSellValueWithBonuses*stackCount/20)
	NirnAuctionHouse.GoldAmountStarting:SetText()
	NirnAuctionHouse.GoldAmountBuyout:SetText(math.ceil(ItemSellValueWithBonuses*stackCount)+codcost) --add codcost

	NAHAuctionHouseGoldCost:GetNamedChild("BidName").normalColor = ZO_NORMAL_TEXT;
	NAHAuctionHouseGoldCost:GetNamedChild("BidName"):SetText(itemName);


	local statval=ItemWeaponPower+ItemArmorRating
	local Priceuid=itemId..":"..quality..":"..statval..":"..ItemRequiredLevel..":"..ItemRequiredChampionPoints

	
		if (NirnAuctionHouse.PriceTable ~=nil and NirnAuctionHouse.PriceTable[Priceuid]~=nil and NirnAuctionHouse.PriceTable[Priceuid].price~=nil) then
			if NirnAuctionHouse.PriceTable[Priceuid].price > 0  and NirnAuctionHouse.PriceTable[Priceuid].price > ItemSellValueWithBonuses then
			NirnAuctionHouse.GoldAmountStarting:SetText()
			codcost=10+math.floor(NirnAuctionHouse.PriceTable[Priceuid].price*stackCount/20)
			NirnAuctionHouse.GoldAmountBuyout:SetText(math.ceil(NirnAuctionHouse.PriceTable[Priceuid].price*stackCount)+codcost) --add codcost
			end		
		else	
			 ----------------------------------MasterMerchant Integration-----------------------------------------
		if(MasterMerchant)then  
		local tipStats = MasterMerchant:itemStats(itemLink, false)
			if tipStats then		
				if tipStats.avgPrice and tipStats.avgPrice > 0  and tipStats.avgPrice > ItemSellValueWithBonuses then
				NirnAuctionHouse.GoldAmountStarting:SetText()
				codcost=10+math.floor(tipStats.avgPrice*stackCount/20)
				NirnAuctionHouse.GoldAmountBuyout:SetText(math.ceil(tipStats.avgPrice*stackCount)+codcost) --add codcost
				end
			end
		end
-----------------------------------MasterMerchant Integration----------------------------------------

		end	
	NirnAuctionHouse_OpenGoldCost()	
end
	
	function NirnAuctionHouse:NAHWindowOrders_Open()
	NAH.settings.ReloadTradeData=true
	NAH.settings.OpenOrdersWindow=true
	NirnAuctionHouse:forceWriteSavedVars()
	end
	
	function NirnAuctionHouse:NAHWindowTrackedOrders_Open()
	NAH.settings.ReloadTradeDataTracked=true
	NAH.settings.ReloadTradeData=true
	NAH.settings.OpenTrackedOrdersWindow=true
	NirnAuctionHouse:forceWriteSavedVars()
	end




		
	function NirnAuctionHouse:NAHWindowTracked_show()
	    NAHAuctionHouseTrackingPanel:SetHidden(false)    
	    NAH.settings.ActiveTab="TrackedOrders";
	 SCENE_MANAGER:Show("NAHScene");
	end

	function NirnAuctionHouse:NAHWindowTracked_hide()
	    NAHAuctionHouseTrackingPanel:SetHidden(true)    
	 SCENE_MANAGER:Hide("NAHScene");
	end


	
	function NirnAuctionHouse:NAHWindow_Open()
	NAH.settings.ReloadTradeData=true
	NAH.settings.OpenAuctionWindow=true
	NirnAuctionHouse:forceWriteSavedVars()
	end
		
	
	
	
	function NirnAuctionHouse:NAHWindow_show()
		 if(NirnAuctionHouse.ServerLink_INITIATED)then
			NAH.settings.ActiveTab="Auction";
			NirnAuctionHousePanel:GetNamedChild("title"):SetText(GetString(SI_NAH_AUCTION))
			 NirnAuctionHouse.list:RefreshFilters()
			 if NirnAuctionHousePanel:IsHidden() then
			 SCENE_MANAGER:Show("NAHScene");
			 end
		 end	
	end

	function NirnAuctionHouse:NAHWindow_hide()
	NAH.settings.OpenAuctionWindow=false
	 SCENE_MANAGER:Hide("NAHScene");
	end
	
		
	function NirnAuctionHouse:NAHWindow_orders_show()
	    NAHAuctionHouseOrdersPanel:SetHidden(false)   
	    NAH.settings.ActiveTab="Orders";
	 SCENE_MANAGER:Show("NAHSceneOrders");
	end

	function NirnAuctionHouse:NAHWindow_orders_hide()
	 SCENE_MANAGER:Hide("NAHSceneOrders");
	end






	function NirnAuctionHouse.CreateEntryFromRaw( rawEntry )

		EntryData=rawEntry;

		local TradeID = EntryData["ID"];
		local TradeIsBidder = EntryData["TradeIsBidder"];
		local BidID = EntryData["ID"];
		if EntryData["TradeID"] then TradeID = EntryData["TradeID"] end
		
		
		local id = EntryData["Item"]["ID"];
		local StartingPrice = EntryData["Item"]["StartingPrice"];
		local BuyoutPrice = EntryData["Item"]["BuyoutPrice"];
		local stackCount = EntryData["Item"]["stackCount"];
		local Buyer = "";
		if EntryData["Buyer"] then
		 Buyer = EntryData["Buyer"];
		 end
		 
		local TradeIsHighestBid = "";
		if EntryData["TradeIsHighestBid"] then
		 TradeIsHighestBid = EntryData["TradeIsHighestBid"];
		 end
		 
		 
		 
		local TimeLeft = "";	
		if EntryData["TimeLeft"] then
		 TimeLeft = EntryData["TimeLeft"];
		 end
		
		
		local itemLink = EntryData["Item"]["ItemLink"];
		local name, type, color, style, bonuses;
		local zoneType = { };
		
		
		local icon, sellPrice, meetsUsageRequirement, equipTypeinfo, itemStyle;
		---Returns: string icon, number sellPrice, boolean meetsUsageRequirement, number equipType, number itemStyle
		icon, sellPrice, meetsUsageRequirement, equipTypeinfo, itemStyle= GetItemLinkInfo(itemLink)
		
		local ItemType = GetItemLinkItemType(itemLink)
		local ItemWeaponType = GetItemLinkWeaponType(itemLink)
		local armorType = GetItemLinkArmorType(itemLink)
		
		local EquipType = GetItemLinkEquipType(itemLink)
		local CraftingSkillType = GetItemLinkCraftingSkillType(itemLink)
		if(CraftingSkillType==nil or CraftingSkillType=="" or CraftingSkillType=="do not translate")then
		CraftingSkillType = GetItemLinkRecipeCraftingSkillType(itemLink)
		end
		
		local RuneType = GetItemLinkEnchantingRuneClassification(itemLink)

		local _hasCharges,_enchantHeader,_enchantDescription = GetItemLinkEnchantInfo(itemLink)
		local _hasAbility,_abilityHeader,_abilityDescription,_,_,_,_,_ = GetItemLinkOnUseAbilityInfo(itemLink)
		local _traitType,_traitDescription,_traitSubtype,_traitSubtypeName,_traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
		local _itemFlavor=GetItemLinkFlavorText(itemLink)
		local requiredLevel=GetItemLinkRequiredLevel(itemLink)
		local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)
		local ItemQuality=GetItemLinkQuality(itemLink)

		
			_, name, bonuses = GetItemLinkSetInfo(itemLink);
			name = LocalizeString("<<t:1>>", GetItemLinkName(itemLink));
			type = LocalizeString("<<C:1>>", GetString("SI_ITEMTYPE", ItemType));
			if (ItemWeaponType > 0) then
			type = type .. " , " .. LocalizeString("<<C:1>>", GetString("SI_WEAPONTYPE", ItemWeaponType));
			end
			if (armorType > 0) then
			type = type .. " , " .. LocalizeString("<<C:1>>", GetString("SI_ARMORTYPE", armorType)) ;
			end
			local source =  EntryData["CharName"];
			color = NirnAuctionHouse.colors.gold;
			
	--~ 		type =  ItemType .. " , " .. type

		zoneType[(GetItemLinkBindType(itemLink) == BIND_TYPE_ON_EQUIP) and 5 or 6] = true;

		return({
			type = NirnAuctionHouse.sortType,
			Icon = icon,
			TimeLeft = TimeLeft,
			TradeID = TradeID,
			TradeIsBidder = TradeIsBidder,
			TradeIsHighestBid = TradeIsHighestBid,
			BidID = BidID,
			ItemID = id,
			StartingPrice = StartingPrice,
			BuyoutPrice = BuyoutPrice,
			stackCount = stackCount,
			requiredLevel = requiredLevel,
			requiredChampPoints = requiredChampPoints,
			name = name,
			itemType = type,
			TypeID = ItemType,
			WeaponTypeID = ItemWeaponType,
			armorTypeID = armorType,
			source = source,
			zoneType = zoneType,
			color = color,
			style = style,
			bonuses = bonuses,
			itemLink = itemLink,
			buyer = Buyer,
			abilityHeader = _abilityHeader,
			abilityDescription = _abilityDescription,
			enchantHeader = _enchantHeader,
			enchantDescription = _enchantDescription,
			traitType = _traitType,
			traitDescription = _traitDescription,
			traitSubtype = _traitSubtype,
			traitSubtypeDescription = _traitSubtypeDescription,
			itemFlavor = _itemFlavor,
			EquipType = EquipType,
			CraftingSkillType = CraftingSkillType,
			RuneType = RuneType,
			ItemQuality = ItemQuality,
		});
	end



	function NirnAuctionHouse.AddToChat( message )
		StartChatInput(CHAT_SYSTEM.textEntry:GetText() .. message);
	end




	
	function NirnAuctionHouse:NotifyNewBid()
	d("new bid recieved")
	end
	
	function NirnAuctionHouse:ProcBids()
		if NirnAuctionHouse.NewBids == nil then NirnAuctionHouse.NewBids={} end	 --clearlsit 
	end
	
	

	
			function NirnAuctionHouse:SetItemBadgeHooks()
			for bagId,inventory in pairs(PLAYER_INVENTORY.inventories) do
			if inventory~=nil and inventory.listView and inventory.listView.dataTypes and inventory.listView.dataTypes[1] and inventory.listView.dataTypes[1].setupCallback then
			    ZO_PreHook(inventory.listView.dataTypes[1], "setupCallback", function(control, slot)    
			      if ( control.slotControlType~=nil and control.slotControlType == 'listSlot' and slot.stackCount~=nil  ) then
				NirnAuctionHouse:SetItemBadges(control, slot)
			      end
			    end)
		    end
		    end
		  end
		  
		  
		  
	  
		  
		  function NirnAuctionHouse:SetItemBadges(parentControl, slot)        
			
			local AuctionBadge,itemLink
    
			local AuctionBadgeName = "NAH_ActiveBadge_"..slot.bagId.."_"..slot.slotIndex
   
		if NAH.AuctionBadges==nil then  NAH.AuctionBadges={} end
		if parentControl.ControlBadge==nil and slot.stackCount~=nil then
		if NAH.AuctionBadges[slot.bagId]==nil then  NAH.AuctionBadges[slot.bagId]={} end
		if NAH.AuctionBadges[slot.bagId][slot.slotIndex]==nil then  
		NAH.AuctionBadges[slot.bagId][slot.slotIndex] = WINDOW_MANAGER:CreateControl(AuctionBadgeName,parentControl , CT_TEXTURE)
		end
		if NAH.AuctionBadgeLabels==nil then  NAH.AuctionBadgeLabels={} end
		if NAH.AuctionBadgeLabels[slot.bagId]==nil then  NAH.AuctionBadgeLabels[slot.bagId]={} end
		if NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]==nil then  
		NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex] = WINDOW_MANAGER:CreateControl(AuctionBadgeName.."_qty",NAH.AuctionBadges[slot.bagId][slot.slotIndex] , CT_LABEL)
		end
			if(NAH.AuctionBadges[slot.bagId][slot.slotIndex]) then	
			NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetDrawTier(DT_HIGH)
			NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetHeight(parentControl:GetHeight()-20)
			NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetWidth(parentControl:GetHeight()-20)
			 parentControl.ControlBadge=NAH.AuctionBadges[slot.bagId][slot.slotIndex]
			end	
			if(NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]) then	
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetFont("ZoFontGame")
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetDrawTier(DT_HIGH)
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:ClearAnchors()
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetAnchor(center, AuctionBadge, center, 28, -10)
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetHeight(parentControl:GetHeight())
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetWidth(180)
			 parentControl.ControlBadgeLabel=NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]
			end		 
		else
		
		if parentControl~=nil  and slot.bagId~=nil and slot.slotIndex~=nil then
		NAH.AuctionBadges[slot.bagId][slot.slotIndex]=parentControl.ControlBadge
		NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]= parentControl.ControlBadgeLabel
		end
		end
			if(NAH.AuctionBadges[slot.bagId][slot.slotIndex]) then--~ 	

--~ 			
			local ItemBound = IsItemBound(slot.bagId,slot.slotIndex)
			local ItemStolen = IsItemStolen(slot.bagId,slot.slotIndex)	
			local ItemBoPTradable = IsItemBoPAndTradeable(slot.bagId,slot.slotIndex)	
--~ 			
			if ItemBound ~= true and ItemStolen ~= true and ItemBoPTradable ~= true then
				local stackCount = slot.stackCount
				itemLink = GetItemLink(slot.bagId, slot.slotIndex, LINK_STYLE_BRACKETS)	
				if itemLink == nil then
				NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetHidden(true)	
				NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetHidden(true)	
					return
				end
				local _, _, _, itemId = ZO_LinkHandler_ParseLink(itemLink)
				
				
				
		local Charges,_ =GetChargeInfoForItem(slot.bagId, slot.slotIndex)		
		local itemQuality=GetItemLinkQuality(itemLink)
		local sellPrice=GetItemLinkValue(itemLink,true)		
		local _hasCharges,_enchantHeader,_enchantDescription = GetItemLinkEnchantInfo(itemLink)
		local _hasAbility,_abilityHeader,_abilityDescription,_,_,_,_,_ = GetItemLinkOnUseAbilityInfo(itemLink)
		local _traitType,_traitDescription,_traitSubtype,_traitSubtypeName,_traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	
		local requiredLevel=GetItemLinkRequiredLevel(itemLink)
		local requiredChampPoints=GetItemLinkRequiredChampionPoints(itemLink)

		
				local tmptradeCnt=NirnAuctionHouse:IsItemListedCnt(itemId,itemQuality,sellPrice,requiredLevel,requiredChampPoints,Charges,_enchantHeader,_abilityHeader,_traitType)		
				if(tmptradeCnt>0) then--~ 		
				NAH.AuctionBadges[slot.bagId][slot.slotIndex]:ClearAnchors()
				NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetAnchor(LEFT, parentControl, LEFT,0, 0)
					NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetText(tmptradeCnt)
					NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetTexture([[NirnAuctionHouse\media\SaleIcon.dds]])
					NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetHidden(false)
					NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetHidden(false)
				else
				NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetHidden(true)
				NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetHidden(true)
				
				end
			else
			NAH.AuctionBadges[slot.bagId][slot.slotIndex]:SetHidden(true)	
			NAH.AuctionBadgeLabels[slot.bagId][slot.slotIndex]:SetHidden(true)	
			end
			
					
			end
		
		end
	
	
EVENT_MANAGER:RegisterForEvent("NirnAuctionHouseLoaded", EVENT_ADD_ON_LOADED, function(...) NirnAuctionHouse:OnLoad(...) end)



