
local addon_name, addon = ...

LibStub("AceAddon-3.0"):NewAddon(addon, addon_name)

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local is5_1 = not not C_PetJournal.GetNumCollectedInfo

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
        enableBattleBorder = false,
        enableBattleBorderIcon = true,
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
                enableBattleBorder = {
                    type = "toggle",
                    name = L["OPT_BATTLE_BORDER"],
                    width = "double",
                    order = 3,
                    hidden = is5_1
                },
                enableBattleBorderIcon = {
                    type = "toggle",
                    name = L["OPT_BATTLE_BORDER_ICON"],
                    width = "double",
                    order = 4
                }
            }
        },
        sectionWorld = {
            type = 'group',
            name = L["OPT_HEADER_WORLD"],
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

do
    local tmp = {}
    local function BuildOwnedList(p_sp, p_c)
        wipe(tmp)

        for iv,petid in LPJ:IteratePetIDs() do
            local _, speciesID, customName, level, name, creatureID
            if is5_1 then
                speciesID, customName, level, _, _, _, _, name, _, _, creatureID = C_PetJournal.GetPetInfoByPetID(petid)
            else
                speciesID, customName, level, _, _, _, name, _, _, creatureID = C_PetJournal.GetPetInfoByPetID(petid)
            end
            
            if (p_sp and speciesID == p_sp) or (p_c and creatureID == p_c) then
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petid)
                
                tinsert(tmp, format("|cff%02x%02x%02x%s|r (L%d)",
                            ITEM_QUALITY_COLORS[quality-1].r*255,
                            ITEM_QUALITY_COLORS[quality-1].g*255,
                            ITEM_QUALITY_COLORS[quality-1].b*255,
                            customName or name, tostring(level)))
            end
        end
        
        if #tmp > 0 then
            return table.concat(tmp, ", ")
        end
    end
    
    function addon:BuildOwnedListS(speciesid)
        return BuildOwnedList(speciesid, nil)
    end
    
    function addon:BuildOwnedListC(creatureid)
        return BuildOwnedList(nil, creatureid)
    end
end

function addon:OwnedListOrNot(ownedlist)
    if ownedlist then
        return format("%s %s", L["YOU_OWN_COLON"], ownedlist)
    else
        return L["YOU_DONT_OWN"]
    end
end

do
    local tmp = {}
    function addon:ShortOwnedList(speciesID)
        wipe(tmp)
        
        for _, petID in LPJ:IteratePetIDs() do
            local sid, _, level = C_PetJournal.GetPetInfoByPetID(petID)
            if sid == speciesID then
                local _, _, _, _, quality = C_PetJournal.GetPetStats(petID)
                
                tinsert(tmp, format("|cff%02x%02x%02xL%d|r",
                        ITEM_QUALITY_COLORS[quality-1].r*255,
                        ITEM_QUALITY_COLORS[quality-1].g*255,
                        ITEM_QUALITY_COLORS[quality-1].b*255,
                        level))
            end
        end
        
        if #tmp > 0 then
            return format("%s: %s", L["OWNED"], table.concat(tmp, "/"))
        else
            return format("|cffee3333%s|r", L["UNOWNED"])
        end
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
