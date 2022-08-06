local _, addon = ...
local NamePlateUnitFilter = CreateFrame("Frame", nil, WorldFrame)

local GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit
local GetNamePlates = C_NamePlate.GetNamePlates

local filterList = { }

local function IndexOfNameInFilterList(unitName)
	unitName = string.lower(unitName)
	for i, filterName in ipairs(filterList) do
		if filterName == unitName then
			return i
		end
	end
	return -1
end

local function IsNameInFilterList(unitName)
	return IndexOfNameInFilterList(unitName) > -1
end

local function FilterNameplate(plate)
	plate.UnitFrame:SetAlpha(0.8)
	plate.UnitFrame.name:SetScale(0.6)
	plate.UnitFrame.healthBar:SetAlpha(0)
	plate.UnitFrame.healthBar:SetScale(0.1)
	plate.UnitFrame.castBar:SetScale(0.2)
end

local function UnfilterNameplate(plate)
	plate.UnitFrame:SetAlpha(1)
	plate.UnitFrame.name:SetScale(1)
	plate.UnitFrame.healthBar:SetAlpha(1)
	plate.UnitFrame.healthBar:SetScale(1)
	plate.UnitFrame.castBar:SetScale(1)
end

local function FilterUnit(plate, unitId)
	local targetPlate = GetNamePlateForUnit("target")
	local focusPlate = GetNamePlateForUnit("focus")
	if unitId and plate ~= targetPlate and plate ~= focusPlate then
		local name = UnitName(unitId)
		if IsNameInFilterList(name) then
			FilterNameplate(plate)
		else
			UnfilterNameplate(plate)
		end
	else
		UnfilterNameplate(plate)
	end
end

local function RefreshNamePlates()
	local namePlates = GetNamePlates()
	for _, namePlate in ipairs(namePlates) do
		FilterUnit(namePlate, namePlate.namePlateUnitToken)
	end
end

local function PrintHelp()
	print("Valid commands: list, add [unit name], remove [unit name], addtarget, removetarget.")
end

local function PrintFilterList()
	local output = "Filtered unit names: "
	for i, unitName in ipairs(filterList) do
		if i ~= 1 then output = output .. ", " end
		output = output .. unitName
	end
	print(output)
end

local function AddToFilterList(unitName)
	unitName = string.lower(unitName)
	if not IsNameInFilterList(unitName) then
		table.insert(filterList, unitName)
		RefreshNamePlates()
		print("Added " .. unitName .. " to unit filter list.")
		return true;
	end
	print(unitName .. " already exists in unit filter list.")
	return false
end

local function RemoveFromFilterList(unitName)
	unitName = string.lower(unitName)
	local index = IndexOfNameInFilterList(unitName)
	if index > -1 then
		table.remove(filterList, index)
		RefreshNamePlates()
		print("Removed " .. unitName .. " from unit filter list.")
		return true
	end
	print("Could not find " .. unitName .. " in unit filter list.")
	return false
end

local function AddTargetToFilterList()
	if UnitExists("target") then
		local unitName = UnitName("target")
		AddToFilterList(unitName)
	else
		print("Target does not exist.")
	end
end

local function RemoveTargetFromFilterList()
	if UnitExists("target") then
		local unitName = UnitName("target")
		RemoveFromFilterList(unitName)
	else
		print("Target does not exist.")
	end
end

local function SlashCmdHandler(msg)
	if #msg == 0 then
		PrintHelp()
		return
	end

	if msg == "list" then
		PrintFilterList()
		return
	elseif msg == "addtarget" then
		AddTargetToFilterList()
		return
	elseif msg == "removetarget" then
		RemoveTargetFromFilterList()
		return
	end

	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "add" and args ~= "" then
		AddToFilterList(args)
	elseif cmd == "remove" and args ~= "" then
		RemoveFromFilterList(args)
	else
		PrintHelp()
	end
end

local GameEvents = {}

local function EventHandler(self, event, ...)
	GameEvents[event](event, ...)
end

function GameEvents:PLAYER_LOGIN(...)
	-- addon.SetupSettings()
end

function GameEvents:NAME_PLATE_UNIT_ADDED(...)
	local unitId = ...
	local plate = GetNamePlateForUnit(unitId)
	if plate and
		not plate:IsForbidden() and
		not UnitIsUnit("player", unitId) and
		not UnitNameplateShowsWidgetsOnly(unitId) then
			FilterUnit(plate, unitId)
	end
end

function GameEvents:PLAYER_TARGET_CHANGED(...)
	RefreshNamePlates()

	local unitId = "target"
	local plate = GetNamePlateForUnit(unitId)
	if plate and
		-- not plate:IsForbidden() and
		not UnitIsUnit("player", unitId) and
		not UnitNameplateShowsWidgetsOnly(unitId) then
			UnfilterNameplate(plate)
	end
end

function GameEvents:PLAYER_FOCUS_CHANGED(...)
	RefreshNamePlates()

	local unitId = "focus"
	local plate = GetNamePlateForUnit(unitId)

	if plate and
		-- not plate:IsForbidden() and
		not UnitIsUnit("player", unitId) and
		not UnitNameplateShowsWidgetsOnly(unitId) then
			UnfilterNameplate(plate)
	end
end

local function Initialize ()
	NamePlateUnitFilter:SetScript("OnEvent", EventHandler)
	for eventName in pairs(GameEvents) do NamePlateUnitFilter:RegisterEvent(eventName) end

	RegisterNewSlashCommand(SlashCmdHandler, "NPUF", "NAMEPLATEUNITFILTER")

	table.insert(filterList, "Wild Imp")
	table.insert(filterList, "Malicious Imp")
	table.insert(filterList, "Dreadstalker")
	table.insert(filterList, "Risen Skulker")
	table.insert(filterList, "Army of the Dead")
	table.insert(filterList, "Magus of the Dead")
	table.insert(filterList, "Kevin's Oozeling")
end

Initialize()
