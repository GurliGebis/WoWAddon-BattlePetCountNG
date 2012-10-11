
local addon_name, addon = ...

LibStub("AceAddon-3.0"):NewAddon(addon, addon_name)

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

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

local function SubTip(t)
    if t.X_BPC then
        t.X_BPC:Show()
        return t.X_BPC
    end
    
    local subtip = CreateFrame("FRAME", nil, t)
    subtip:SetPoint("TOPLEFT", t, "BOTTOMLEFT")
    subtip:SetPoint("TOPRIGHT", t, "BOTTOMRIGHT")
    
    subtip:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
        tile = true, tileSize = 16, edgeSize = 16, 
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    subtip:SetBackdropColor(0,0,0,1)
    
    subtip.Text = subtip:CreateFontString("ARTWORK")
    subtip.Text:SetFontObject(GameTooltipTextSmall)
    subtip.Text:SetWordWrap(true)
    subtip.Text:SetPoint("TOPLEFT", subtip, 8, -8)
    subtip.Text:SetWidth(220)
    
    t.X_BPC = subtip
    return subtip
end

local function HideSubTip(t)
    if t.X_BPC then
        t.X_BPC:Hide()
    end
end

local BuildOwnedListS, BuildOwnedListC
do
    local tmp = {}
    local function BuildOwnedList(p_sp, p_c)
        wipe(tmp)

        for iv,petid in LPJ:IteratePetIDs() do
            local speciesID, customName, level, _, _, _, name, _, _, creatureID = C_PetJournal.GetPetInfoByPetID(petid)
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
    
    function BuildOwnedListS(speciesid)
        return BuildOwnedList(speciesid, nil)
    end
    
    function BuildOwnedListC(creatureid)
        return BuildOwnedList(nil, creatureid)
    end
end

local function OwnedListOrNot(ownedlist)
    if ownedlist then
        return format("%s %s", L["YOU_OWN_COLON"], ownedlist)
    else
        return L["YOU_DONT_OWN"]
    end
end

local ShortOwnedList
do
    local tmp = {}
    
    function ShortOwnedList(speciesID)
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

local function PlayersBest(speciesID)
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

--
-- BattlePetTooltipTemplate
--

hooksecurefunc("BattlePetTooltipTemplate_SetBattlePet", function(self, data)
    if not addon.db.profile.enableCageTip then
        return HideSubTip(self)
    end

    local subtip = SubTip(self)
    subtip.Text:SetText(OwnedListOrNot(BuildOwnedListS(self.speciesID)))
    subtip:SetHeight(subtip.Text:GetHeight()+16)
end)

--
-- PetBattleUnitTooltip
--

hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", function(self, petOwner, petIndex)
    if not addon.db.profile.enableBattleTip then
        return HideSubTip(self)
    end

    local subtip = SubTip(self)
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    subtip.Text:SetText(OwnedListOrNot(BuildOwnedListS(speciesID)))
    subtip:SetHeight(subtip.Text:GetHeight()+16)
end)

hooksecurefunc("PetBattleUnitFrame_UpdateDisplay", function(self)
    local quality = C_PetBattles.GetBreedQuality(self.petOwner, self.petIndex)
    if self.Name then
        self.Name:SetVertexColor(ITEM_QUALITY_COLORS[quality-1].r,
                                 ITEM_QUALITY_COLORS[quality-1].g,
                                 ITEM_QUALITY_COLORS[quality-1].b)
    end
end)


--
-- GameTooltip
--

GameTooltip:HookScript("OnShow", function(self)
    if not addon.db then
        return
    end

    if self.GetUnit and addon.db.profile.enableCreatureTip then
        local _, unit = self:GetUnit()
        if unit then
            if UnitIsWildBattlePet(unit) then
                local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
                self:AddLine(OwnedListOrNot(BuildOwnedListC(creatureID)))
                self:Show()
            end
            return
        end
    end
    
    if self.GetItem and addon.db.profile.enableItemTip then
        local _, link = self:GetItem()
        if link then
            local _, _, itemid = strfind(link, "|Hitem:(%d+):")
            if itemid then
                local speciesID = addon.Item2Species[tonumber(itemid)]
                if speciesID then
                    if not addon.db.profile.itemTipIncludesAll then
                        local _, _, _, _, _, _, _, canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                        if not canBattle then
                            return
                        end
                    end
                    self:AddLine(OwnedListOrNot(BuildOwnedListS(speciesID)))
                    self:Show()
                end
            end
            return
        end
    end
end)

local function sub_PetName(line)
    local name = line
    local start, stop = strfind(line, "|t")
    if start then
        name = strsub(line, stop+1)
    end
    local _, _, subname = strfind(name, "|c%x%x%x%x%x%x%x%x([^|]+)|r")
    if subname then
        name = subname
    end
    
    for _,speciesID in LPJ:IterateSpeciesIDs() do
        local s_name = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if s_name == name then
            return format("%s (%s)", line, ShortOwnedList(speciesID))          
        end
    end

    return line
end

local lastMinimapTooltip
GameTooltip:HookScript("OnUpdate", function(self)
    if addon.db and not addon.db.profile.enableMinimapTip then
        return
    elseif self:GetOwner() ~= Minimap then
        return
    end
    
    local text = GameTooltipTextLeft1:GetText()
    if text ~= lastMinimapTooltip then
        text = string.gsub(text, "([^\n]+)", sub_PetName)
        GameTooltipTextLeft1:SetText(text)
        lastMinimapTooltip = text
        self:Show()
    end
end)

--
-- Pet Battle Text
--

do   
    local InBattleIndicator = CreateFrame("FRAME", nil, PetBattleFrame.ActiveEnemy, "InsetFrameTemplate3")
    InBattleIndicator:SetPoint("RIGHT", PetBattleFrame.ActiveEnemy, "LEFT", -6, 0)
    InBattleIndicator:SetPoint("LEFT", PetBattleFrame.TopVersusText, "RIGHT", 22, 0)
    InBattleIndicator:SetHeight(30)
    
    local Text = InBattleIndicator:CreateFontString("OVERLAY")
    Text:SetFontObject(GameFontHighlightLeft)
    Text:SetJustifyH("CENTER")
    Text:SetAllPoints()

    --
    --
    --
    
    for _,frame in pairs{PetBattleFrame.Enemy2, PetBattleFrame.Enemy3} do
        local overlay = CreateFrame("FRAME", nil, frame)
        overlay:SetWidth(16)
        overlay:SetHeight(16)
        overlay:SetPoint("TOPRIGHT", 7, 0)
        local texture = overlay:CreateTexture("OVERLAY")
        texture:SetAllPoints()
        texture:SetTexture("Interface\\AddOns\\"..addon_name.."\\Media\\investigate")
        overlay.Texture = texture
        overlay:Hide()
        frame.X_BPC_UP = overlay
    end
    
    local border_touched = {}           -- try not to mess up other addons?
    local function updateBorder(owner, slot, frame)
        if not frame:IsShown() then
            return
        end
        
        local border = frame.Border or frame.BorderAlive
        local quality = C_PetBattles.GetBreedQuality(owner, slot)
        if addon.db.profile.enableBattleBorder then
            border:SetVertexColor(ITEM_QUALITY_COLORS[quality-1].r,
                                ITEM_QUALITY_COLORS[quality-1].g,
                                ITEM_QUALITY_COLORS[quality-1].b)
            border_touched[border] = true
        elseif border_touched[border] then
            border:SetVertexColor(1, 1, 1)
            border_touched[border] = nil
        end
        
        local upgradeIcon = frame.X_BPC_UP
        if upgradeIcon then
            if addon.db.profile.enableBattleBorderIcon and C_PetBattles.IsWildBattle() then
                local hp = C_PetBattles.GetHealth(owner, slot)
                local speciesID = C_PetBattles.GetPetSpeciesID(owner, slot)
                local bestquality = PlayersBest(speciesID)
                if hp > 0 and (not bestquality or quality > bestquality) then
                    upgradeIcon.Texture:SetVertexColor(
                        ITEM_QUALITY_COLORS[quality-1].r,
                        ITEM_QUALITY_COLORS[quality-1].g,
                        ITEM_QUALITY_COLORS[quality-1].b)
                    upgradeIcon:Show()
                else
                    upgradeIcon:Hide()
                end
            else
                upgradeIcon:Hide()
            end
        end
    end

    local function updateBorders()
        local activeEnemy = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local activeAlly = C_PetBattles.GetActivePet(LE_BATTLE_PET_ALLY)
        local inactiveEnemy, inactiveAlly = 2, 2
        for i=1, NUM_BATTLE_PETS_IN_BATTLE do
            if i ~= activeEnemy then
                updateBorder(LE_BATTLE_PET_ENEMY, i, PetBattleFrame["Enemy"..inactiveEnemy])
                inactiveEnemy = inactiveEnemy + 1
            else
                updateBorder(LE_BATTLE_PET_ENEMY, i, PetBattleFrame.ActiveEnemy)
            end
            
            if i ~= activeAlly then
                updateBorder(LE_BATTLE_PET_ALLY, i, PetBattleFrame["Ally"..inactiveAlly])
                inactiveAlly = inactiveAlly + 1
            else
                updateBorder(LE_BATTLE_PET_ALLY, i, PetBattleFrame.ActiveAlly)
            end
        end
    end
    
    --
    --
    --

    InBattleIndicator:RegisterEvent("PET_BATTLE_PET_CHANGED")
    InBattleIndicator:RegisterEvent("PET_BATTLE_OPENING_START")
    InBattleIndicator:SetScript("OnEvent", function(self, event, ...)
        updateBorders()

        if not addon.db.profile.enableBattleIndicator then
            return self:Hide()
        elseif not C_PetBattles.IsWildBattle() then
            return self:Hide()
        end
        
        local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)
        Text:SetText(ShortOwnedList(speciesID))
        self:Show()
    end)
    
    InBattleIndicator:SetScript("OnEnter", function(self)
        local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        
        GameTooltip:AddLine(OwnedListOrNot(BuildOwnedListS(speciesID)))
        GameTooltip:Show()
    end)
    
    InBattleIndicator:SetScript("OnLeave", function(self)
        if self == GameTooltip:GetOwner() then
            GameTooltip:Hide()
        end
    end)
end
