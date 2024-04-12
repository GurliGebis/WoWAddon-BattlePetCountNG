
local addon_name, addon = ...

LibStub("AceAddon-3.0"):NewAddon(addon, addon_name)

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local GREEN_FONT_COLOR_CODE = "|cff30d030"
local RED_FONT_COLOR_CODE = "|cffff3030"

--
--
--

local defaults = {
    profile = {
        enableCageTip = true,
        enableBattleTip = true,
        enableMinimapTip = true,
        enableCreatureTip = true,
        enableItemTip = true,
        itemTipIncludesAll = true,
        enableBattleIndicator = true,
        enableBattleBorderIcon = true,
        preferNamesOverQuality = false,
        enablePetCard = true,
        useOlderText = false,
        useSubTip = false,
        showBreedID = true,
        showBreedIDShort = false
    }
}

local options = {
    name = addon_name,
    handler = addon,
    type = 'group',
    get = function(info) return addon.db.profile[info[#info]] end,
    set = function(info,v) addon.db.profile[info[#info]] = v end,
    args = {
        sectionBattle = {
            type = 'group',
            name = L["OPT_HEADER_BATTLE"],
            order = 10,
            inline = true,
            args = {
                enableBattleTip = {
                    type = "toggle",
                    name = L["OPT_BATTLE_TIP"],
                    width = "double",
                    order = 1,
                },
                enableBattleIndicator = {
                    type = "toggle",
                    name = L["OPT_BATTLE_HINT_BOX"],
                    width = "double",
                    order = 2,
                },
                resetBattleIndicator = {
                    type = "execute",
                    name = L["OPT_BATTLE_HINT_RESET"],
                    disabled = function() return not addon.db.profile.enableBattleIndicator end,
                    func = function() addon:GetModule("Indicators"):ResetIndicatorPosition() end,
                    order = 3
                },
                enableBattleBorderIcon = {
                    type = "toggle",
                    name = L["OPT_BATTLE_BORDER_ICON"],
                    width = "double",
                    order = 4,
                }
            }
        },
        sectionWorld = {
            type = 'group',
            name = L["OPT_HEADER_WORLD"],
            order = 20,
            inline = true,
            args = {
                enableCreatureTip = {
                    type = "toggle",
                    name = L["OPT_CREATURE_TIP"],
                    width = "double",
                    order = 1,
                },
                enableMinimapTip = {
                    type = "toggle",
                    name = L["OPT_MINIMAP_TIP"],
                    width = "double",
                    order = 2
                },
            }
        },
        sectionItem = {
            type = 'group',
            name = L["OPT_HEADER_ITEMS"],
            order = 30,
            inline = true,
            args = {
                enableCageTip = {
                    type = "toggle",
                    name = L["OPT_CAGE_TIP"],
                    width = "double",
                    order = 1,
                },
                enableItemTip = {
                    type = "toggle",
                    name = L["OPT_ITEM_TIP"],
                    width = "double",
                    order = 10,
                },
                itemTipIncludesAll = {
                    type = "toggle",
                    name = L["OPT_ITEM_TIP_ALL"],
                    width = "double",
                    order = 11,
                },
            }
        },
        sectionOther = {
            type = 'group',
            name = L["OPT_HEADER_OTHER"],
            order = 50,
            inline = true,
            args = {
                preferNamesOverQuality = {
                    type = "toggle",
                    name = L["OPT_PREFER_NAMES_OVER_QUALITY"],
                    width = "double",
                    order = 1
                },
                enablePetCard = {
                    type = "toggle",
                    name = L["OPT_PET_CARD"],
                    width = "double",
                    order = 2
                },
                useOlderText = {
                    type = "toggle",
                    name = L["OPT_USE_OLDER_TEXT"],
                    width = "double",
                    order = 3,
                },
                multilineTooltip = {
                    type = "toggle",
                    name = L["OPT_MULTILINE_TOOLTIP"],
                    width = "double",
                    order = 4,
                },
                useSubTip = {
                    type = "toggle",
                    name = L["OPT_USE_SUB_TIP"],
                    width = "double",
                    order  = 4,
                },
                showBreedID = {
                    type = "toggle",
                    name = L["OPT_USE_BREEDID_ADDON"],
                    width = "double",
                    order = 5,
                    disabled = function() return not GetBreedID_Journal end,
                    get = function(info) return addon.db.profile[info[#info]] and GetBreedID_Journal end,
                }
            }
        }
    }
}

--
--
--

function addon:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("BattlePetCountDB", defaults, true)
    self.options = options
    
    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.name, options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name, self.name, nil)
end

--
--
--

function addon:CanObtainSpecies(speciesID)
    local _, _, _, _, _, _, _, _, _, _, obtainable = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    return obtainable
end

function addon:GetPetName(petID)
    local _, customName, _, _, _, _, _, petName = C_PetJournal.GetPetInfoByPetID(petID)
    return customName or petName
end

function addon:_breedID(petID, toggle)
    if toggle == nil then
        -- default
        toggle = self.db.profile.showBreedID
    end

    if toggle and GetBreedID_Journal then
        return " "..tostring(GetBreedID_Journal(petID))
    end
    return ""
end

do
    local tmp = {}
    function addon:OwnedList(speciesID)
        wipe(tmp)

        local linePrefix = ""
        if self.db.profile.multilineTooltip then
            linePrefix = "\n - "
        end

        for _,petID in LPJ:IteratePetIDs() do
            if C_PetJournal.GetPetInfoByPetID(petID) == speciesID then
                local _, _, level = C_PetJournal.GetPetInfoByPetID(petID)
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petID)

                local name
                if self.db.profile.preferNamesOverQuality then
                    name = self:GetPetName(petID)
                else
                    name = _G["ITEM_QUALITY"..(quality-1).."_DESC"] or UNKNOWN
                end

                tinsert(tmp, format("%s|cff%02x%02x%02x%s|r (L%d%s)",
                            linePrefix,
                            ITEM_QUALITY_COLORS[quality-1].r*255,
                            ITEM_QUALITY_COLORS[quality-1].g*255,
                            ITEM_QUALITY_COLORS[quality-1].b*255,
                            name, tostring(level), self:_breedID(petID)))
            end
        end
        
        if #tmp > 0 then
            return table.concat(tmp, ", ")
        end
    end
end

do
    local tmp = {}
    function addon:ShortOwnedListOnly(speciesID, skipPetID)
        local sep = "/"
        if self.db.profile.showBreedIDShort and GetBreedID_Journal then
            sep = ","
        end

        wipe(tmp)

        for _,petID in LPJ:IteratePetIDs() do
            if C_PetJournal.GetPetInfoByPetID(petID) == speciesID and skipPetID ~= petID then
                local _, _, level = C_PetJournal.GetPetInfoByPetID(petID)
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petID)
                
                tinsert(tmp, format("|cff%02x%02x%02xL%d%s|r",
                        ITEM_QUALITY_COLORS[quality-1].r*255,
                        ITEM_QUALITY_COLORS[quality-1].g*255,
                        ITEM_QUALITY_COLORS[quality-1].b*255,
                        level, self:_breedID(petID, self.db.profile.showBreedIDShort)))
            end
        end
        
        if #tmp > 0 then
            return table.concat(tmp, sep)
        end
    end
end

function addon:ShortOwnedList(speciesID)
    local text = self:ShortOwnedListOnly(speciesID)
    if text then
        return format("%s: %s", L["OWNED"], text)
    else
        return format("|cffee3333%s|r", L["UNOWNED"])
    end
end

function addon:PlayersBest(speciesID)
    local maxquality = -1
    local maxlevel = -1
    for iv,petid in LPJ:IteratePetIDs() do
        local sid, _, level = C_PetJournal.GetPetInfoByPetID(petid)
        if sid == speciesID then
            local _, _, _, _, quality = C_PetJournal.GetPetStats(petid)
            if maxquality < quality then
                maxquality = quality
            end
            if maxlevel < level then
                maxlevel = level
            end
        end
    end
    
    if maxquality == -1 then
        return nil
    end
    return maxquality, maxlevel
end

function addon:CollectedOlderText(speciesID)
    local ownedlist = self:OwnedList(speciesID)
    if ownedlist then
        return format("%s %s", L["YOU_OWN_COLON"], ownedlist)
    else
        return L["YOU_DONT_OWN"]
    end
end

function addon:CollectedText(speciesID)
    if not addon:CanObtainSpecies(speciesID) then
        return L["UNOBTAINABLE"]
    end

    if self.db.profile.useOlderText then
        return self:CollectedOlderText(speciesID)
    end

    local owned, maxOwned = C_PetJournal.GetNumCollectedInfo(speciesID)  
    local ownedColor
    if owned < maxOwned then
        ownedColor = GREEN_FONT_COLOR_CODE
    else
        ownedColor = RED_FONT_COLOR_CODE
    end

    return format("%s%s%s: %s",
                ownedColor,
                format(ITEM_PET_KNOWN, owned, maxOwned),
                FONT_COLOR_CODE_CLOSE,
                self:OwnedList(speciesID) or RED_FONT_COLOR_CODE..L["UNOWNED"]
                )
end
