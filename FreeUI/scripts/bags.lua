-- Originally based on aBags by Alza.

local F, C, L = unpack(select(2, ...))

if not C.bags.enable then return end

local _G = _G

local r, g, b = unpack(C.class)

--[[ Get the number of bag and bank container slots used ]]

local function CheckSlots()
	local numBags = 1

	for i = 1, NUM_BAG_FRAMES do
		local bagName = "ContainerFrame"..i+1
		if _G[bagName]:IsShown() and not _G[bagName.."BackgroundTop"]:GetTexture():find("Bank") then
			numBags = numBags + 1
		end
	end

	return numBags
end

-- [[ Fancy borders when dragging items ]]

local function onEnter(self)
	self.bg:SetBackdropBorderColor(r, g, b)
end

local function onLeave(self)
	self.bg:SetBackdropBorderColor(0, 0, 0)
end

-- [[ Function to reskin buttons and hide default bags]]

local RestyleButton = function(buName)
	local bu = _G[buName]
	local border = bu.IconBorder

	bu:SetSize(C.bags.size, C.bags.size)

	if bu.restyled then return end

	local co = _G[buName.."Count"]

	bu:SetNormalTexture("")
	bu:SetPushedTexture("")
	bu:SetHighlightTexture("")
	bu:SetFrameStrata("HIGH")

	F.SetFS(co)
	co:ClearAllPoints()
	co:SetPoint("TOP", bu, 1, -2)

	bu.icon:SetTexCoord(.08, .92, .08, .92)

	border:SetTexture(C.media.backdrop)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetDrawLayer("BACKGROUND")

	local questTexture = _G[buName.."IconQuestTexture"] or bu.IconQuestTexture
	questTexture:SetAlpha(0)

	local bg = CreateFrame("Frame", nil, bu)
	bg:SetPoint("TOPLEFT", bu, -1, 1)
	bg:SetPoint("BOTTOMRIGHT", bu, 1, -1)
	bg:SetShown(C.bags.slotsShowAlways)
	F.CreateBD(bg, 0)
	bu.bg = bg

	bu:HookScript("OnEnter", onEnter)
	bu:HookScript("OnLeave", onLeave)

	bu.restyled = true
end

local HideBag = function(bagName)
	local bag = _G[bagName]

	if bag.restyled then return end

	bag:EnableMouse(false)
	bag.ClickableTitleFrame:EnableMouse(false)
	_G[bagName.."CloseButton"]:Hide()
	_G[bagName.."PortraitButton"]:EnableMouse(false)
	for i = 1, 7 do
		select(i, bag:GetRegions()):SetAlpha(0)
	end

	bag.restyled = true
end

-- Quest texture stuff

hooksecurefunc("ContainerFrame_Update", function(frame)
	local name = frame:GetName()

	for i = 1, frame.size do
		local itemButton = _G[name.."Item"..i]

		if _G[name.."Item"..i.."IconQuestTexture"]:IsShown() then
			itemButton.IconBorder:SetVertexColor(1, 1, 0)
		end
	end
end)

hooksecurefunc("BankFrameItemButton_Update", function(button)
	if not button.isBag and button.IconQuestTexture:IsShown() then
		button.IconBorder:SetVertexColor(1, 1, 0)
	end
end)

-- [[ Local stuff ]]

local Spacing = 4
local bu, con, bag, col, row
local buttons, bankbuttons = {}, {}

--[[ Function to move buttons ]]

local MoveButtons = function(table, frame)
	local columns = ceil(sqrt(#table))
	local iconSize = C.bags.size

	col, row = 0, 0
	for i = 1, #table do
		bu = _G[table[i]]
		bu:ClearAllPoints()
		bu:SetPoint("TOPLEFT", frame, "TOPLEFT", col * (iconSize + Spacing) + 3, -1 * row * (iconSize + Spacing) - 3)
		if(col > (columns - 2)) then
			col = 0
			row = row + 1
		else
			col = col + 1
		end
	end

	frame:SetHeight((row + (col==0 and 0 or 1)) * (iconSize + Spacing) + 19)
	frame:SetWidth(columns * iconSize + Spacing * (columns - 1) + 6)
	col, row = 0, 0
end

--[[ Bags ]]

local holder = CreateFrame("Button", "BagsHolder", UIParent)
holder:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -29, 29)
holder:SetFrameStrata("HIGH")
holder:Hide()
F.CreateBD(holder, .6)

local ReanchorButtons = function()
	table.wipe(buttons)
	for f = 1, CheckSlots() do
		con = "ContainerFrame"..f
		HideBag(con)

		for i = 1, GetContainerNumSlots(_G[con]:GetID()) do
			bu = con.."Item"..i
			RestyleButton(bu)
			tinsert(buttons, bu)
		end
	end

	MoveButtons(buttons, holder)
	holder:Show()
end

local money = _G["ContainerFrame1MoneyFrame"]
money:SetFrameStrata("DIALOG")
money:SetParent(holder)
money:ClearAllPoints()
money:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 12, 2)

--[[ Bank ]]

local bankholder = CreateFrame("Button", "BagsBankHolder", UIParent)
bankholder:SetPoint("BOTTOMRIGHT", "BagsHolder", "BOTTOMLEFT", -10 , 0)
bankholder:SetFrameStrata("HIGH")
bankholder:Hide()
F.CreateBD(bankholder, .6)

local purchase = F.CreateFS(bankholder)
purchase:SetPoint("BOTTOMLEFT", bankholder, "BOTTOMLEFT", 4, 4)
purchase:SetText("Buy new slots: Click here.")

local purchaseButton = CreateFrame("Frame", nil, bankholder)
purchaseButton:SetSize(purchase:GetStringWidth(), 8)
purchaseButton:SetPoint("BOTTOMLEFT", bankholder, "BOTTOMLEFT", 4, 4)
purchaseButton:SetScript("OnMouseUp", function()
	StaticPopup_Show("CONFIRM_BUY_BANK_SLOT")
end)

local ReanchorBankButtons = function()
	table.wipe(bankbuttons)
	for i = 1, 28 do
		bu = "BankFrameItem"..i
		RestyleButton(bu)
		tinsert(bankbuttons, bu)
	end

	-- if you don't have your bags maxed out but you are upgrading bank, bank bag name will no longer be bag index + 1
	-- so we use this workaround to find out the name
	local bagNameCount = 0

	for f = NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS do
		bagNameCount = bagNameCount + 1
		con = "ContainerFrame"..CheckSlots() + bagNameCount

		HideBag(con)
		_G[con]:SetScale(1)

		for i = GetContainerNumSlots(f), 1, -1  do
			bu = con.."Item"..i
			RestyleButton(bu)
			tinsert(bankbuttons, bu)
		end
	end
	local _, full = GetNumBankSlots()
	if full then
		purchase:Hide()
		purchaseButton:Hide()
	end

	MoveButtons(bankbuttons, bankholder)
	bankholder:Show()
end

local money = _G["BankFrameMoneyFrame"]
money:SetFrameStrata("DIALOG")
money:ClearAllPoints()
money:SetPoint("BOTTOMRIGHT", bankholder, "BOTTOMRIGHT", 12, 2)

-- [[ Button slot outline ]]

local moveHandler = CreateFrame("Frame")

local function toggleButtonBackdrops(show)
	for _, button in pairs(buttons) do
		_G[button].bg:SetShown(show)
	end
	for _, button in pairs(bankbuttons) do
		_G[button].bg:SetShown(show)
	end
end

if not C.bags.slotsShowAlways then
	moveHandler:RegisterEvent("CURSOR_UPDATE")
end

F.AddOptionsCallback("bags", "slotsShowAlways", function()
	if C.bags.slotsShowAlways then
		moveHandler:UnregisterEvent("CURSOR_UPDATE")
		toggleButtonBackdrops(true)
	else
		moveHandler:RegisterEvent("CURSOR_UPDATE")
		toggleButtonBackdrops(false)
	end
end)

moveHandler:SetScript("OnEvent", function()
	toggleButtonBackdrops(GetCursorInfo() == "item")
end)

--[[ Misc. frames ]]

BankFramePurchaseInfo:Hide()
BankFramePurchaseInfo.Show = F.dummy
BankFrame:EnableMouse(false)
BankFrameCloseButton:Hide()
BankFrame:DisableDrawLayer("BACKGROUND")
BankFrame:DisableDrawLayer("BORDER")
BankFrame:DisableDrawLayer("OVERLAY")
BankSlotsFrame:DisableDrawLayer("BORDER")
BankPortraitTexture:Hide()
BankFrameMoneyFrameInset:Hide()
BankFrameMoneyFrameBorder:Hide()

local bankbagholder = CreateFrame("Frame", nil, BankFrame)
bankbagholder:SetSize(289, 43)
bankbagholder:SetPoint("BOTTOM", bankholder, "TOP", 0, -1)
F.CreateBD(bankbagholder, .6)
bankbagholder:SetAlpha(0)

local bagholder = CreateFrame("Frame", nil, ContainerFrame1)
bagholder:SetSize(32 * 5 + 4, 35)
bagholder:SetPoint("BOTTOM", holder, "TOP", 0, -1)

-- need to define this now. Used later as a dummy for default bag
local mainBag

local showBags = function()
	for i = 0, 3 do
		_G["CharacterBag"..i.."Slot"]:SetAlpha(1)
	end
	mainBag:SetAlpha(1)
end

local hideBags = function()
	for i = 0, 3 do
		_G["CharacterBag"..i.."Slot"]:SetAlpha(0)
	end
	mainBag:SetAlpha(0)
end

local bankBagAlpha = 0

local setBankBagAlpha = function()
	bankBagAlpha = 1 - bankBagAlpha

	bankbagholder:SetAlpha(bankBagAlpha)
	for i = 1, 7 do
		BankSlotsFrame["Bag"..i]:SetAlpha(bankBagAlpha)
	end
end

bagholder:SetScript("OnEnter", showBags)
bagholder:SetScript("OnLeave", hideBags)
bankbagholder:SetScript("OnEnter", setBankBagAlpha)
bankbagholder:SetScript("OnLeave", setBankBagAlpha)

local function showContainerDropdown(self)
	local id

	if self.isBankBag then
		id = self.ID
	else
		id = self.ID - CharacterBag0Slot:GetID() + 1
	end

	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		if frame:GetID() == id then
			ToggleDropDownMenu(1, nil, frame.FilterDropDown, self, 0, 0)
			return
		end
	end
end

local function configOnEnter(self)
	if self.isBankBag then
		setBankBagAlpha()
	else
		showBags()
	end

	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine(CLICK_BAG_SETTINGS)
	GameTooltip:Show()
end

local function configOnLeave(self)
	GameTooltip:Hide()

	if self.isBankBag then
		setBankBagAlpha()
	else
		hideBags()
	end
end

local function addConfigIcon(bag, id, dropdownFunction, isBankBag)
	local bu = CreateFrame("Button", nil, bag)
	bu:SetSize(16, 16)
	bu:SetPoint("BOTTOMRIGHT", 2, -2)

	bu.isBankBag = isBankBag
	bu.ID = id

	local ic = bu:CreateTexture()
	ic:SetTexture("Interface\\WorldMap\\GEAR_64GREY")
	ic:SetAllPoints()

	bu:SetScript("OnClick", dropdownFunction or showContainerDropdown)
	bu:SetScript("OnEnter", configOnEnter)
	bu:SetScript("OnLeave", configOnLeave)
end

local function bagOnMouseover(self, isEnter)
	local bgR, bgG, bgB

	if isEnter then
		showBags()
		bgR, bgG, bgB = r, g, b
	else
		hideBags()
		bgR, bgG, bgB = 0, 0, 0
	end

	if self.isMainBag then
		for j = 1, GetContainerNumSlots(0) do
			local bu = _G["ContainerFrame1Item"..j]
			bu.bg:SetBackdropBorderColor(bgR, bgG, bgB)
			bu.bg:SetShown(isEnter)
		end
	else
		local id = self:GetID() - CharacterBag0Slot:GetID() + 1

		for i = 1, NUM_CONTAINER_FRAMES do
			local frame = _G["ContainerFrame"..i]
			if frame:GetID() == id then
				for j = 1, GetContainerNumSlots(frame:GetID()) do
					local bu = _G["ContainerFrame"..i.."Item"..j]
					bu.bg:SetBackdropBorderColor(bgR, bgG, bgB)
					bu.bg:SetShown(isEnter)
				end

				break
			end
		end
	end
end

local function bagOnEnter(self)
	bagOnMouseover(self, true)
end

local function bagOnLeave(self)
	bagOnMouseover(self, false)
end

-- add extra button for default bag
do
	mainBag = CreateFrame("Frame", nil, holder)
	mainBag:SetSize(30, 30)
	mainBag:SetPoint("RIGHT", bagholder)
	mainBag:SetAlpha(0)

	local icon = mainBag:CreateTexture(nil, "OVERLAY")
	icon:SetAllPoints()
	icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
	icon:SetTexCoord(.08, .92, .08, .92)

	addConfigIcon(mainBag, nil, function(self)
		ToggleDropDownMenu(1, nil, ContainerFrame1.FilterDropDown, self, 0, 0)
	end)

	F.CreateBG(mainBag)

	mainBag.isMainBag = true

	mainBag:SetScript("OnEnter", bagOnEnter)
	mainBag:SetScript("OnLeave", bagOnLeave)
end

for i = 0, 3 do
	local bag = _G["CharacterBag"..i.."Slot"]
	local ic = _G["CharacterBag"..i.."SlotIconTexture"]
	local border = bag.IconBorder

	bag:UnregisterEvent("ITEM_PUSH") -- gets rid of the animation

	bag:SetParent(holder)
	bag:ClearAllPoints()

	if i == 0 then
		bag:SetPoint("RIGHT", mainBag, "LEFT", -3, 0)
	else
		bag:SetPoint("RIGHT", _G["CharacterBag"..(i-1).."Slot"], "LEFT", -3, 0)
	end

	bag:SetNormalTexture("")
	bag:SetCheckedTexture("")
	bag:SetPushedTexture("")

	ic:SetTexCoord(.08, .92, .08, .92)
	F.CreateBG(ic)

	border:SetTexture(C.media.backdrop)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetDrawLayer("BACKGROUND", 1)

	bag:SetAlpha(0)
	bag:HookScript("OnEnter", bagOnEnter)
	bag:HookScript("OnLeave", bagOnLeave)
	bag:SetScript("OnClick", nil)

	addConfigIcon(bag, bag:GetID())
end

local function bankBagOnMouseover(self, isEnter)
	local bgR, bgG, bgB

	setBankBagAlpha()

	if isEnter then
		bgR, bgG, bgB = r, g, b
	else
		bgR, bgG, bgB = 0, 0, 0
	end

	local id = self:GetID() + NUM_BAG_SLOTS

	for i = 1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		if frame:GetID() == id then
			for j = 1, GetContainerNumSlots(frame:GetID()) do
				local bu = _G["ContainerFrame"..i.."Item"..j]
				bu.bg:SetBackdropBorderColor(bgR, bgG, bgB)
				bu.bg:SetShown(isEnter)
			end

			break
		end
	end
end

local function bankBagOnEnter(self)
	bankBagOnMouseover(self, true)
end

local function bankBagOnLeave(self)
	bankBagOnMouseover(self, false)
end

for i = 1, 7 do
	local bag = BankSlotsFrame["Bag"..i]
	local border = bag.IconBorder

	bag:SetParent(bankholder)
	bag:ClearAllPoints()

	if i == 1 then
		bag:SetPoint("BOTTOM", bankholder, "TOP", -123, 2)
	else
		bag:SetPoint("LEFT", BankSlotsFrame["Bag"..i-1], "RIGHT", 4, 0)
	end

	bag:SetNormalTexture("")
	bag:SetPushedTexture("")

	bag.icon:SetTexCoord(.08, .92, .08, .92)

	border:SetTexture(C.media.backdrop)
	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)
	border:SetDrawLayer("BACKGROUND", 1)

	bag:SetAlpha(0)
	bag:HookScript("OnEnter", bankBagOnEnter)
	bag:HookScript("OnLeave", bankBagOnLeave)

	addConfigIcon(bag, bag:GetID() + NUM_BAG_SLOTS, nil, true)
end

local moneytext = {"ContainerFrame1MoneyFrameGoldButtonText", "ContainerFrame1MoneyFrameSilverButtonText", "ContainerFrame1MoneyFrameCopperButtonText", "BankFrameMoneyFrameGoldButtonText", "BankFrameMoneyFrameSilverButtonText", "BankFrameMoneyFrameCopperButtonText", "BackpackTokenFrameToken1Count", "BackpackTokenFrameToken2Count", "BackpackTokenFrameToken3Count"}

for i = 1, 9 do
	F.SetFS(_G[moneytext[i]])
end

--[[ Show & Hide functions etc ]]

local CloseBags = function()
	bankholder:Hide()
	holder:Hide()
	for i = 0, 11 do
		CloseBag(i)
	end
end

local CloseBags2 = function()
	bankholder:Hide()
	holder:Hide()
	CloseBankFrame()
end

local OpenBags = function()
	for i = 0, 4 do
		OpenBag(i)
	end
end

local ToggleBags = function()
	if(IsBagOpen(0)) then
		CloseBankFrame()
		CloseBags()
	else
		OpenBags()
	end
end

for i = 1, 5 do
	local bag = _G["ContainerFrame"..i]
	hooksecurefunc(bag, "Show", ReanchorButtons)
	hooksecurefunc(bag, "Hide", CloseBags2)
	bag.SetScale = F.dummy
end
hooksecurefunc(BankFrame, "Show", function()
	for i = 0, 11 do
		OpenBag(i)
	end

	ReanchorBankButtons()
end)
hooksecurefunc(BankFrame, "Hide", CloseBags)

ToggleBackpack = ToggleBags
ToggleBag = ToggleBags
OpenAllBags = OpenBags
OpenBackpack = OpenBags
CloseAllBags = CloseBags

-- [[ Currency ]]

BackpackTokenFrame:GetRegions():Hide()
BackpackTokenFrameToken1:ClearAllPoints()
BackpackTokenFrameToken1:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 2)
for i = 1, 3 do
	local bu = _G["BackpackTokenFrameToken"..i]
	local ic = _G["BackpackTokenFrameToken"..i.."Icon"]
	_G["BackpackTokenFrameToken"..i.."Count"]:SetShadowOffset(0, 0)

	bu:SetFrameStrata("DIALOG")
	ic:SetDrawLayer("OVERLAY")
	ic:SetTexCoord(.08, .92, .08, .92)

	F.CreateBG(ic)
end

-- [[ Search ]]

BankItemSearchBox:Hide()
BankItemSearchBox.Show = F.dummy

BagItemSearchBox.Left:Hide()
BagItemSearchBox.Middle:Hide()
BagItemSearchBox.Right:Hide()

BagItemSearchBox:SetHeight(18)
BagItemSearchBox:ClearAllPoints()
BagItemSearchBox:SetPoint("TOPLEFT", holder, "BOTTOMLEFT", 0, 1)
BagItemSearchBox:SetPoint("TOPRIGHT", holder, "BOTTOMRIGHT", 0, 1)
BagItemSearchBox.SetPoint = F.dummy
BagItemSearchBox:SetWidth(holder:GetWidth())
F.SetFS(BagItemSearchBox)
BagItemSearchBox:SetShadowColor(0, 0, 0, 0)
BagItemSearchBox:SetJustifyH("CENTER")
BagItemSearchBox:SetAlpha(0)
F.CreateBD(BagItemSearchBox, .6)

BagItemSearchBoxSearchIcon:SetPoint("LEFT", BagItemSearchBox, "LEFT", 4, -2)

local HideSearch = function()
	BagItemSearchBox:SetAlpha(0)
end

BagItemSearchBox:HookScript("OnEditFocusGained", function(self)
	self:SetScript("OnLeave", nil)
	self:SetTextColor(1, 1, 1)
	BagItemSearchBoxSearchIcon:SetVertexColor(1, 1, 1)
end)

BagItemSearchBox:HookScript("OnEditFocusLost", function(self)
	self:SetScript("OnLeave", HideSearch)
	self.clearButton:Click()
	HideSearch()
	self:SetText(SEARCH)
	self:SetTextColor(.5, .5, .5)
	BagItemSearchBoxSearchIcon:SetVertexColor(.6, .6, .6)
end)

BagItemSearchBox:HookScript("OnEnter", function(self)
	self:SetAlpha(1)
end)
BagItemSearchBox:HookScript("OnLeave", HideSearch)

-- [[ Money ]]

local function Format(money)
	return format("%s\124TInterface\\MoneyFrame\\UI-GoldIcon:0:0:2:0\124t", BreakUpLargeNumbers(floor((money / 10000) + .5)))
end

local name = UnitName("player")
local realm = GetRealmName()
local r, g, b = unpack(C.class)
local keys = {}

local function ShowMoney()
	GameTooltip:SetOwner(ContainerFrame1MoneyFrameGoldButton, "ANCHOR_NONE")
	GameTooltip:SetPoint("BOTTOMRIGHT", BagsHolder, "BOTTOMLEFT", -1, -1)

	local total, totalAlliance, totalHorde, totalNeutral = 0, 0, 0, 0
	local goldList = FreeUIGlobalConfig[realm].gold
	local factionList = FreeUIGlobalConfig[realm].faction
	local allianceList, hordeList, neutralList = {}, {}, {}
	local headerAdded = false

	for k, v in pairs(goldList) do
		if factionList[k] == "Alliance" then
			totalAlliance = totalAlliance + v
			allianceList[k] = v
		elseif factionList[k] == "Horde" then
			totalHorde = totalHorde + v
			hordeList[k]= v
		else
			totalNeutral = totalNeutral + v
			neutralList[k] = v
		end

		total = total + v
	end


	GameTooltip:AddDoubleLine(realm, Format(total), r, g, b, 1, 1, 1)

	for n in pairs(allianceList) do
		table.insert(keys, n)
	end
	table.sort(keys)

	for _, k in pairs(keys) do
		local class = FreeUIGlobalConfig[realm].class[k]
		local v = allianceList[k]
		if v and v >= 10000 then
			if not headerAdded then
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(strupper(FACTION_ALLIANCE), Format(totalAlliance), 0, 0.68, 0.94, 1, 1, 1)
				headerAdded = true
			end
			GameTooltip:AddDoubleLine(k, Format(v), C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b, 1, 1, 1)
		end
	end

	headerAdded = false
	table.wipe(keys)

	for n in pairs(hordeList) do
		table.insert(keys, n)
	end
	table.sort(keys)

	for _, k in pairs(keys) do
		local class = FreeUIGlobalConfig[realm].class[k]
		local v = hordeList[k]
		if v and v >= 10000 then
			if not headerAdded then
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(strupper(FACTION_HORDE), Format(totalHorde), 1, 0, 0, 1, 1, 1)
				headerAdded = true
			end
			GameTooltip:AddDoubleLine(k, Format(v), C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b, 1, 1, 1)
		end
	end

	headerAdded = false
	table.wipe(keys)

	for n in pairs(neutralList) do
		table.insert(keys, n)
	end
	table.sort(keys)

	for _, k in pairs(keys) do
		local class = FreeUIGlobalConfig[realm].class[k]
		local v = neutralList[k]
		if v and v >= 10000 then
			if not headerAdded then
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(strupper(FACTION_OTHER), Format(totalNeutral), .9, .9, .9, 1, 1, 1)
				headerAdded = true
			end
			GameTooltip:AddDoubleLine(k, Format(v), C.classcolours[class].r, C.classcolours[class].g, C.classcolours[class].b, 1, 1, 1)
		end
	end

	GameTooltip:Show()
end

ContainerFrame1MoneyFrameGoldButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameSilverButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameCopperButton:HookScript("OnEnter", ShowMoney)
ContainerFrame1MoneyFrameGoldButton:HookScript("OnLeave", GameTooltip_Hide)
ContainerFrame1MoneyFrameSilverButton:HookScript("OnLeave", GameTooltip_Hide)
ContainerFrame1MoneyFrameCopperButton:HookScript("OnLeave", GameTooltip_Hide)