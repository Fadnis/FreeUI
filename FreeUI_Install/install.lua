local F, C, L = unpack(FreeUI)

local addon = ...

-- Smooth bars

local smoothing = {}
local function Smooth(self, value)
	local _, max = self:GetMinMaxValues()
	if value == self:GetValue() or (self._max and self._max ~= max) then
		smoothing[self] = nil
		self:SetValue_(value)
	else
		smoothing[self] = value
	end
	self._max = max
end

local function SmoothBar(bar)
	bar.SetValue_ = bar.SetValue
	bar.SetValue = Smooth
end

local smoother, min, max = CreateFrame('Frame'), math.min, math.max
smoother:SetScript('OnUpdate', function()
	local rate = GetFramerate()
	local limit = 30/rate
	for bar, value in pairs(smoothing) do
		local cur = bar:GetValue()
		local new = cur + min((value-cur)/3, max(value-cur, limit))
		if new ~= new then
			-- Mad hax to prevent QNAN.
			new = value
		end
		bar:SetValue_(new)
		if cur == value or abs(new - value) < 2 then
			bar:SetValue_(value)
			smoothing[bar] = nil
		end
	end
end)

-- Create frames

local f = CreateFrame("Frame", "FreeUI_InstallFrame", UIParent)
f:SetSize(400, 400)
f:SetPoint("CENTER")
f:SetFrameStrata("HIGH")
F.CreateBD(f)
F.CreateSD(f)

local sb = CreateFrame("StatusBar", nil, f)
sb:SetPoint("BOTTOM", f, "BOTTOM", 0, 60)
sb:SetSize(320, 20)
sb:SetStatusBarTexture(C.media.texture)
sb:Hide()
SmoothBar(sb)

local sbd = CreateFrame("Frame", nil, sb)
sbd:SetPoint("TOPLEFT", sb, -1, 1)
sbd:SetPoint("BOTTOMRIGHT", sb, 1, -1)
sbd:SetFrameLevel(sb:GetFrameLevel()-1)
F.CreateBD(sbd, .25)

local header = f:CreateFontString(nil, "OVERLAY")
header:SetFont(C.media.font2, 16, "THINOUTLINE")
header:SetPoint("TOP", f, "TOP", 0, -20)

local body = f:CreateFontString(nil, "OVERLAY")
body:SetJustifyH("LEFT")
body:SetFont(C.media.font2, 13, "THINOUTLINE")
body:SetWidth(f:GetWidth()-40)
body:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -60)

local credits = f:CreateFontString(nil, "OVERLAY")
credits:SetFont(C.media.font2, 9, "THINOUTLINE")
credits:SetText("FreeUI by Lightsword @ Argent Dawn - EU / Haleth on wowinterface.com")
credits:SetPoint("BOTTOM", f, "BOTTOM", 0, 4)

local sbt = sb:CreateFontString(nil, "OVERLAY")
sbt:SetFont(C.media.font2, 13, "THINOUTLINE")
sbt:SetPoint("CENTER", sb)

local option1 = CreateFrame("Button", "FreeUI_Install_Option1", f, "UIPanelButtonTemplate")
option1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 20, 20)
option1:SetSize(128, 25)

local option2 = CreateFrame("Button", "FreeUI_Install_Option2", f, "UIPanelButtonTemplate")
option2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 20)
option2:SetSize(128, 25)

local close = CreateFrame("Button", "FreeUI_Install_CloseButton", f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT")
close:SetScript("OnClick", function()
	UIFrameFade(f,{
		mode = "OUT",
		timeToFade = 0.5,
		finishedFunc = function(f) f:SetAlpha(1); f:Hide() end,
		finishedArg1 = f,
	})
	DisableAddOn(addon)
end)

F.Reskin(option1)
F.Reskin(option2)
F.ReskinClose(close)

-- Setup

local scale = min(2, max(.64, 768/string.match(({GetScreenResolutions()})[GetCurrentResolution()], "%d+x(%d+)")))
if scale > 1 then scale = 1 end

local function Setup()
	SetCVar("screenshotQuality", 10)
	SetCVar("cameraDistanceMax", 50)
	SetCVar("cameraDistanceMaxFactor", 3.4)
	SetCVar("nameplateShowFriends", 0)
	SetCVar("nameplateShowEnemies", 1)
	SetCVar("ShowClassColorInNameplate", 1)
	SetCVar("bloatThreat", 0)
	SetCVar("miniWorldMap", 1)
end

local function SetupChat()
	FCF_ResetChatWindows()
	FCF_DockFrame(ChatFrame2)

	ChatFrame1:ClearAllPoints()
	ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 50, 50)
	if C.resolution == 3 then
		ChatFrame1:SetHeight(145)
		ChatFrame1:SetWidth(410)
	else
		ChatFrame1:SetHeight(121)
		ChatFrame1:SetWidth(342)
	end
	ChatFrame1:SetUserPlaced(true)

	FCF_SavePositionAndDimensions(ChatFrame1)
	FCF_SetLocked(ChatFrame1, 1)

	local channels = {
		"SAY",
		"EMOTE",
		"YELL",
		"GUILD",
		"OFFICER",
		"GUILD_ACHIEVEMENT",
		"ACHIEVEMENT",
		"WHISPER",
		"PARTY",
		"PARTY_LEADER",
		"INSTANCE_CHAT",
		"INSTANCE_CHAT_LEADER",
		"RAID",
		"RAID_LEADER",
		"RAID_WARNING",
		"BATTLEGROUND",
		"BATTLEGROUND_LEADER",
		"CHANNEL1",
		"CHANNEL2",
		"CHANNEL3",
		"CHANNEL4",
		"CHANNEL5",
		"CHANNEL6",
		"CHANNEL7",
		"CHANNEL8",
		"CHANNEL9",
		"CHANNEL10",
	}

	for _, channel in next, channels do
		ToggleChatColorNamesByClassGroup(true, channel)
	end
end

local function SetupDBM()
	if(DBM_SavedOptions) then table.wipe(DBM_SavedOptions) end

	DBM_SavedOptions = {
		["SpecialWarningFontSize"] = 50,
		["ShowWarningsInChat"] = true,
		["DontSetIcons"] = false,
		["BigBrotherAnnounceToRaid"] = false,
		["ArrowPosX"] = 0,
		["InfoFrameY"] = -75,
		["SpecialWarningSound"] = "Sound\\Spells\\PVPFlagTaken.wav",
		["AutoRespond"] = true,
		["HealthFrameGrowUp"] = false,
		["StatusEnabled"] = true,
		["HideBossEmoteFrame"] = false,
		["InfoFrameX"] = 75,
		["ShowBigBrotherOnCombatStart"] = false,
		["BlockVersionUpdatePopup"] = true,
		["WarningColors"] = {
			{
				["b"] = 0.9411764705882353,
				["g"] = 0.8,
				["r"] = 0.4117647058823529,
			}, -- [1]
			{
				["b"] = 0,
				["g"] = 0.9490196078431372,
				["r"] = 0.9490196078431372,
			}, -- [2]
			{
				["b"] = 0,
				["g"] = 0.5019607843137255,
				["r"] = 1,
			}, -- [3]
			{
				["b"] = 0.1019607843137255,
				["g"] = 0.1019607843137255,
				["r"] = 1,
			}, -- [4]
		},
		["AlwaysShowSpeedKillTimer"] = true,
		["RangeFrameY"] = -50,
		["InfoFrameShowSelf"] = false,
		["SpecialWarningFont"] = "Fonts\\FRIZQT__.TTF",
		["UseMasterVolume"] = true,
		["AlwaysShowHealthFrame"] = false,
		["SpamBlockRaidWarning"] = true,
		["ShowFakedRaidWarnings"] = false,
		["LatencyThreshold"] = 200,
		["DontSendBossAnnounces"] = false,
		["InfoFramePoint"] = "CENTER",
		["SpecialWarningSound2"] = "Sound\\Creature\\AlgalonTheObserver\\UR_Algalon_BHole01.wav",
		["HPFrameMaxEntries"] = 5,
		["SettingsMessageShown"] = true,
		["WarningIconRight"] = false,
		["RangeFramePoint"] = "CENTER",
		["SpecialWarningPoint"] = "CENTER",
		["ShowSpecialWarnings"] = true,
		["RaidWarningSound"] = "Sound\\Doodad\\BellTollNightElf.wav",
		["DontShowBossAnnounces"] = false,
		["SpecialWarningY"] = 75,
		["RangeFrameSound2"] = "none",
		["SpecialWarningX"] = 0,
		["ShowLHFrame"] = true,
		["RaidWarningPosition"] = {
			["Y"] = -185,
			["X"] = 0,
			["Point"] = "TOP",
		},
		["HPFramePoint"] = "RIGHT",
		["Enabled"] = true,
		["RangeFrameLocked"] = false,
		["WarningIconLeft"] = false,
		["HelpMessageShown"] = false,
		["RangeFrameSound1"] = "none",
		["DontSendBossWhispers"] = false,
		["SpecialWarningFontColor"] = {
			0, -- [1]
			0, -- [2]
			1, -- [3]
		},
		["HPFrameY"] = -176.2242279052734,
		["HealthFrameWidth"] = 150,
		["RangeFrameX"] = 50,
		["ShowMinimapButton"] = false,
		["HPFrameX"] = -92.86503601074219,
		["HealthFrameLocked"] = true,
		["SpamBlockBossWhispers"] = false,
		["ArrowPosY"] = -150,
		["ArrowPoint"] = "TOP",
	}
	DBT_SavedOptions = {
		["DBM"] = {
			["EndColorG"] = 1,
			["FillUpBars"] = true,
			["HugeBarXOffset"] = 0,
			["Scale"] = 1,
			["IconLeft"] = true,
			["HugeBarYOffset"] = 0,
			["HugeWidth"] = 206,
			["BarYOffset"] = 3,
			["IconRight"] = false,
			["HugeTimerY"] = -167.9991455078125,
			["TimerX"] = -264,
			["ExpandUpwards"] = false,
			["TimerPoint"] = "CENTER",
			["StartColorG"] = 0,
			["HugeScale"] = 1,
			["StartColorB"] = 0,
			["EndColorR"] = 0,
			["Width"] = 206,
			["HugeTimerPoint"] = "CENTER",
			["StartColorR"] = 1,
			["FontSize"] = 10,
			["HugeBarsEnabled"] = false,
			["HugeTimerX"] = -274.9999389648438,
			["TimerY"] = -157,
			["BarXOffset"] = 0,
			["EndColorB"] = 0,
		},
	}
end

local step4 = function()
	sb:SetValue(400)
	PlaySoundFile("Sound\\interface\\LevelUp.wav")
	header:SetText("Success!")
	body:SetText("Installation is complete.\n\nPlease click the 'Finish' button to reload the UI.\n\nEnjoy!")
	sbt:SetText("4/4")
	option1:Hide()
	option2:SetText("Finish")

	option2:SetScript("OnClick", function()
		DisableAddOn(addon)
		ReloadUI()
	end)
end

local step3 = function()
	sb:SetValue(300)
	header:SetText("3. DBM")
	body:SetText("The third and final step applies the DBM settings.\n\nThis step is recommended for any user.\n\nMake sure that DBM is running if you want to apply these settings.")
	sbt:SetText("3/4")

	option1:SetScript("OnClick", step4)
	option2:SetScript("OnClick", function()
		SetupDBM()
		step4()
	end)
end

local step2 = function()
	sb:SetValue(200)
	header:SetText("2. Chat")
	body:SetText("The second step applies the correct chat setup.\n\nIf you are a new user, this step is recommended. If you are an existing user, you may want to skip this step.\n\nPlease be aware that any custom chat channels will need to be re-enabled through the in-game chat settings.")
	sbt:SetText("2/4")

	option1:SetScript("OnClick", step3)
	option2:SetScript("OnClick", function()
		SetupChat()
		step3()
	end)
end

local step1 = function()
	sb:SetMinMaxValues(0, 400)
	sb:Show()
	sb:SetValue(0)
	sb:SetValue(100)
	sb:GetStatusBarTexture():SetGradient("VERTICAL", 0.20, .9, 0.12, 0.36, 1, 0.30)
	header:SetText("1. Core")
	body:SetText("These steps will apply the correct setup for FreeUI.\n\nThe first step applies the essential settings.\n\nThis is recommended for any user, unless you want to apply only a specific part of the settings.\n\nClick 'Continue' to apply the settings, or click 'Skip' if you wish to skip this step.")
	sbt:SetText("1/4")

	option1:Show()

	option1:SetText("Skip")
	option2:SetText("Continue")

	option1:SetScript("OnClick", step2)
	option2:SetScript("OnClick", function()
		Setup()
		step2()
	end)
end

local tut6 = function()
	sb:SetValue(600)
	header:SetText("6. Finished")
	body:SetText("The tutorial is complete. You can choose to reconsult it at any time by typing |cff00c1ff/freeui install|r.\n\nI suggest you have a look through the options to customize the UI to your needs, or get started straight away if you like the default settings.\n\nYou can now continue to install the UI.")

	sbt:SetText("6/6")

	option1:Show()

	option1:SetText("Close")
	option2:SetText("Install")

	option1:SetScript("OnClick", function()
		UIFrameFade(f,{
			mode = "OUT",
			timeToFade = 0.5,
			finishedFunc = function(f) f:Hide() end,
			finishedArg1 = f,
		})
		DisableAddOn(addon)
	end)
	option2:SetScript("OnClick", step1)
end

local tut5 = function()
	sb:SetValue(500)
	header:SetText("5. /Commands")
	body:SetText("Lastly, FreeUI includes useful slash commands. Below is a list.\n\n|cff00c1ff/freeui|r brings up a list of UI-specific commands (you might want to try this now). |cff00c1ff/en|r and |cff00c1ff/dis|r are used to quickly enable and disable addons. |cff00c1ff/rl|r reloads the UI.\n\n|cff00c1ff/tt|r lets you whisper your target. |cff00c1ff/rc|r initiates a ready check. |cff00c1ff/rd|r disbands a party or raid. |cff00c1ff/rolepoll|r or |cff00c1ff/rolecheck|r initiates a role check.\n\n|cff00c1ff/gm|r toggles the Help frame. |cff00c1ff/vol|r lets you set the master volume (0-1).")

	sbt:SetText("5/6")

	option2:SetScript("OnClick", tut6)
end

local tut4 = function()
	sb:SetValue(400)
	header:SetText("4. Features (2)")
	body:SetText("To copy text from the chat frame, shift-click the first chat tab, which will show on mouseover.\n\nThe minimap will display a text saying 'Mail' if you have unread mail. Below it is a Tol Barad timer which is enabled by default for level 85 characters.\n\nTo show the time manager and stopwatch, click the info text at the bottom of the screen.\n\nTo collect mail money and items easily, click the button at the bottom of your inbox.\n\nThe rest should explain itself. If you have any questions, you can always ask.")

	sbt:SetText("4/6")

	option2:SetScript("OnClick", tut5)
end

local tut3 = function()
	sb:SetValue(300)
	header:SetText("3. Features")
	body:SetText("There's a couple of small tools in this UI you might be interested in as well. For example, there are two ways to track buffs; an embedded buff tracker, to monitor buffs; and a selfbuff reminder, which will display an icon if the buff is missing while in combat.\n\nYou can set up these buff trackers in the options. Examples are included. Selfbuffs are already set up, so no worries.\n\nYou can mark mobs by alt+shift-clicking mobs in the game world and selecting an icon from the dropdown menu.\n\nClicking the bottom left corner of the screen toggles the chat menu. Left/right-clicking the bottom right corner toggles alDamageMeter and DBM respectively. Clicking and holding the bottom right corner brings up the micro menu.")

	sbt:SetText("3/6")

	option2:SetScript("OnClick", tut4)
end

local tut2 = function()
	sb:SetValue(200)
	header:SetText("2. Unitframes")
	body:SetText("FreeUI includes an embedded version of oUF. This handles all of the unitframes on the screen, the buffs and debuffs, and the class-specific elements like Holy Power.\n\nIf you play as a healer, you may want to enable healer unitframes. Type |cff00c1ff/freeui dps/heal(er)|r to switch between layouts.\n\nThe source code for the unitframes is located in FreeUI/scripts/unitframes.lua. If you're any good with lua, you can edit them there.\n\nMost of the basics can be changed in the options file, to make it easier.")

	sbt:SetText("2/6")

	option2:SetScript("OnClick", tut3)
end

local tut1 = function()
	sb:SetMinMaxValues(0, 600)
	sb:Show()
	sb:SetValue(100)
	sb:GetStatusBarTexture():SetGradient("VERTICAL", 0, 0.65, .9, .1, .9, 1)
	header:SetText("1. Essentials")
	body:SetText("Good! First, here's a few things that's important to know about this UI.\n\nFor starters, the options for this UI can be found in FreeUI/options.lua, and can be opened with any simple text editor.\n\nYou might want to know about the bags as well. It's pretty simple.\n\nYour bags consist of an all-in-one window. To show which bags are equipped, mouseover just above the top of the bag or bank window.\n\nTo search, mouseover just below the bag and click the search box. You can search for item names, or slots; e.g. 'trinket' will highlight both items with 'trinket' in their name as well as all of your trinkets.")

	sbt:SetText("1/6")

	option1:Hide()

	option2:SetText("Next")

	option2:SetScript("OnClick", tut2)
end


header:SetText("Hello")
body:SetText("Thank you for choosing FreeUI!\n\nIn just a moment, you can get started. All that's needed is for the correct settings to be applied. Don't worry, none of your personal preferences will be changed.\n\nYou can also take a brief tutorial on some of the features of FreeUI, which is recommended if you're a new user.\n\nPress the 'Tutorial' button to do so now, or press 'Install' to go straight to the setup.")

option1:SetText("Tutorial")
option2:SetText("Install")

option1:SetScript("OnClick", tut1)
option2:SetScript("OnClick", step1)