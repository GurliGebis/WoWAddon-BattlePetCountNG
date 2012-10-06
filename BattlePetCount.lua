
local addon_name, addon = ...

local LPJ = LibStub("LibPetJournal-2.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local HEALTH_COORD, POWER_COORD,
      SPEED_COORD, QUALITY_COORD = 
    {0.5, 1.0, 0.5, 1.0}, {0.0, 0.5, 0.0, 0.5},
    {0.0, 0.5, 0.5, 1.0}, {0.5, 1.0, 0.0, 0.5}

local UP_ARROW = "Interface\\PetBattles\\BattleBar-AbilityBadge-Strong-Small"
local DOWN_ARROW = "Interface\\PetBattles\\BattleBar-AbilityBadge-Weak-Small"
    
--
--
--

local function Create_SubTip(t)
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
    
    return subtip
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
    if not self.X_BPC then
        self.X_BPC = Create_SubTip(self)
    end
    
    self.X_BPC.Text:SetText(OwnedListOrNot(BuildOwnedListS(self.speciesID)))
    self.X_BPC:SetHeight(self.X_BPC.Text:GetHeight()+16)
end)

--
-- PetBattleUnitTooltip
--

hooksecurefunc("PetBattleUnitTooltip_UpdateForUnit", function(self, petOwner, petIndex)
    if not self.X_BPC then
        self.X_BPC = Create_SubTip(self)
    end
    
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    self.X_BPC.Text:SetText(OwnedListOrNot(BuildOwnedListS(speciesID)))
    self.X_BPC:SetHeight(self.X_BPC.Text:GetHeight()+16)
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
    local _, unit = self:GetUnit()
    if unit then
        if UnitIsWildBattlePet(unit) then
            local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
            self:AddLine(OwnedListOrNot(BuildOwnedListC(creatureID)))
            self:Show()
        end
        return
    end
    
    local _, link = self:GetItem()
    if link then
        local _, _, itemid = strfind(link, "|Hitem:(%d+):")
        if itemid then
            local speciesID = addon.Item2Species[tonumber(itemid)]
            if speciesID then
                self:AddLine(OwnedListOrNot(BuildOwnedListS(speciesID)))
                self:Show()
            end
        end
        return
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
            local quality = PlayersBest(speciesID)
            if quality then
               return format("%s (|cff%02x%02x%02x%s|r)", line,
                            ITEM_QUALITY_COLORS[quality-1].r*255,
                            ITEM_QUALITY_COLORS[quality-1].g*255,
                            ITEM_QUALITY_COLORS[quality-1].b*255,
                            L["OWNED"])
            else
                return format("%s (|cffee3333%s|r)", line, L["UNOWNED"])
            end
        end
    end

    return line
end

local lastMinimapTooltip
GameTooltip:HookScript("OnUpdate", function(self)
    if self:GetOwner() ~= Minimap then
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
    Text:Hide()
    
    local function CreateTexturePair(texture1, t1coord, texture2, t2coord)
        local frame = CreateFrame("FRAME", nil, InBattleIndicator)
        frame:SetHeight(16)
        frame:SetWidth(28)
        
        local t1 = frame:CreateTexture("ARTWORK")
        t1:SetTexture(texture1)
        t1:SetWidth(16)
        t1:SetHeight(16)
        if t1coord then
            t1:SetTexCoord(unpack(t1coord))
        end
        t1:SetPoint("LEFT")
            
        local t2 = frame:CreateTexture("ARTWORK") 
        t2:SetTexture(texture2)
        t2:SetWidth(16)
        t2:SetHeight(16)
        if t2coord then
            t2:SetTexCoord(unpack(t1coord))
        end
        t2:SetPoint("RIGHT")

        frame:SetScale(1)
        frame:Hide()
        return frame
    end
    
    --
    -- Textures
    --
        
    local TLevel = CreateTexturePair("Interface\\AddOns\\BattlePetCount\\Media\\level")
    local TQuality = CreateTexturePair("Interface\\PetBattles\\PetBattle-StatIcons", QUALITY_COORD)
    local THealth = CreateTexturePair("Interface\\PetBattles\\PetBattle-StatIcons", QUALITY_COORD)
    local TPower = CreateTexturePair("Interface\\PetBattles\\PetBattle-StatIcons", QUALITY_COORD)
    local TSpeed = CreateTexturePair("Interface\\PetBattles\\PetBattle-StatIcons", QUALITY_COORD)

    --
    --
    --    
    local shown = {}
    
    InBattleIndicator:RegisterEvent("PET_BATTLE_PET_CHANGED")
    InBattleIndicator:RegisterEvent("PET_BATTLE_OPENING_START")
    InBattleIndicator:SetScript("OnEvent", function(self, event, ...)
        if not C_PetBattles.IsWildBattle() then
            return self:Hide()
        end
        
        for i, item in ipairs(shown) do
            item:Hide()
        end
        wipe(shown)
        
        local activePet = C_PetBattles.GetActivePet(LE_BATTLE_PET_ENEMY)
        local speciesID = C_PetBattles.GetPetSpeciesID(LE_BATTLE_PET_ENEMY, activePet)
        local quality = C_PetBattles.GetBreedQuality(LE_BATTLE_PET_ENEMY, activePet)
        local bestquality, bestlevel = PlayersBest(speciesID)
        
        if not bestquality then
            Text:SetText(L["UNOWNED"])
            Text:Show()
        elseif true then
            -- text
            if bestquality < quality then
                Text:SetText(L["UPGRADE"])
            else
                Text:SetText(L["OWNED"])
            end
            Text:Show()
        else
            Text:Hide()
            
            local level = C_PetBattles.GetLevel(LE_BATTLE_PET_ENEMY, activePet)
            
            if bestquality < quality then
                tinsert(shown, TQualityUpgrade)
            elseif bestquality > quality  then
                tinsert(shown, TQualityDowngrade)
            end
            
            if bestlevel < level then
                tinsert(shown, TLevelUpgrade)
            elseif bestlevel > level then
                tinsert(shown, TLevelDowngrade)
            end
        end
        
        local last
        for i,item in ipairs(shown) do
            if last == nil then
                item:SetPoint("RIGHT", self, "RIGHT", -4, 0)
            else
                item:SetPoint("RIGHT", last, "LEFT", -4, 0)
            end
            last = item
            item:Show()
        end
        
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
