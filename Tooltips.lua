
local addon_name, addon = ...

local module = addon:NewModule("Tooltips", "AceEvent-3.0", "AceHook-3.0")

local LPJ = LibStub("LibPetJournal-2.0")
local LibQTip = LibStub("LibQTip-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("BattlePetCount")

local is5_0 = not C_PetJournal.GetNumCollectedInfo

--
--
--

local GameTooltip_OnUpdate_Hook

function module:OnInitialize()
    if ITEM_PET_KNOWN then
        local str = ITEM_PET_KNOWN
        str = gsub(gsub(str, "%(", "%%("), "%)", "%%)")
        str = gsub(str, "%%d", "%%d+")
        self.ITEM_PET_KNOWN_DEFORMAT = "^"..str
    end

    self:Initialize_BattlePetTooltip()
    self:Initialize_PetBattleUnitTooltip()
    self:Initialize_GameTooltip()

    self.savedStats = { [LE_BATTLE_PET_ALLY] = { [1] = {}, [2] = {}, [3] = {} },
                        [LE_BATTLE_PET_ENEMY] = { [1] = {}, [2] = {}, [3] = {} } }
    self:RegisterEvent("PET_BATTLE_OPENING_START")

    self:RegisterEvent("ADDON_LOADED")
    self:ADDON_LOADED()
end

function module:ADDON_LOADED()
    if not self.LibExtraTip then
        self.LibExtraTip = LibStub("LibExtraTip-1", true)
        if self.LibExtraTip then
            self.LibExtraTip:AddCallback{
                type = "extrashow",
                callback = function(tip, extratip)
                    if tip.X_BPC2 then
                        tip.X_BPC2:SetPoint("TOPLEFT", extratip, "BOTTOMLEFT")
                        tip.X_BPC2:SetPoint("TOPRIGHT", extratip, "BOTTOMRIGHT") 
                    end
                end
            }
            self.LibExtraTip:AddCallback{
                type = "extrahide",
                callback = function(tip, extratip)
                    if tip.X_BPC2 then
                        tip.X_BPC2:SetPoint("TOPLEFT", tip, "BOTTOMLEFT")
                        tip.X_BPC2:SetPoint("TOPRIGHT", tip, "BOTTOMRIGHT") 
                    end
                end
            }
        end
    end
end

function module:SubTip(tooltip, text)
    --- XXX call something when tooltip is hidden

    if not text then
        return self:HideSubTip(tooltip)
    end

    local subtip = tooltip.X_BPC2
    if not subtip then
        subtip = LibQTip:Acquire(tooltip:GetName().."_BPC_SubTip", 1, "LEFT")

        subtip:SetPoint("TOPLEFT", tooltip, "BOTTOMLEFT")
        subtip:SetPoint("TOPRIGHT", tooltip, "BOTTOMRIGHT") 
        subtip:Show()

        tooltip.X_BPC2 = subtip
    else
        subtip:Clear()
    end

    if text then
        subtip:AddLine(text)
    end
end

function module:HideSubTip(tooltip)
    if tooltip.X_BPC2 then
        LibQTip:Release(tooltip.X_BPC2)
        tooltip.X_BPC2 = nil
    end
end

function module:HookScriptSilent(frame, script, func)
    if frame:HasScript(script) then
        return self:HookScript(frame, script, func)
    end
end

function module:SaveBattleStats(petOwner, petIndex)
    self.savedStats[petOwner][petIndex].power = C_PetBattles.GetPower(petOwner, petIndex)
    self.savedStats[petOwner][petIndex].speed = C_PetBattles.GetSpeed(petOwner, petIndex)
    self.savedStats[petOwner][petIndex].health = C_PetBattles.GetMaxHealth(petOwner, petIndex)
end

function module:PET_BATTLE_OPENING_START()
    for i = 1,3 do
        self:SaveBattleStats(LE_BATTLE_PET_ALLY, i)
        self:SaveBattleStats(LE_BATTLE_PET_ENEMY, i)
    end
end

--
-- BattlePetTooltipTemplate
--

function module:Initialize_BattlePetTooltip()
    self:SecureHook("BattlePetToolTip_Show")
    self:HookScript(BattlePetTooltip, "OnHide", "BattlePetToolTip_Hide")
end

function module:BattlePetToolTip_Show(speciesID)
    local tip = BattlePetTooltip
    local Owned = tip.Owned

    if not speciesID or speciesID < 0 then
        return
    elseif not addon.db.profile.enableCageTip then
        if is5_0 then
            -- TODO fix size
            tip.Owned:Hide()
        end
        return
    elseif addon.db.profile.useSubTip then
        if Owned and Owned:IsShown() then
            tip.Owned:Hide()
            -- TODO fix size
        end

        self:SubTip(tip, addon:CollectedText(speciesID))
        return
    end

    self:HideSubTip(tip)

    if not Owned then
        -- 5.0 support
        Owned = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        Owned:SetWidth(238)
        Owned:SetJustifyH("LEFT")
        Owned:SetPoint("TOPLEFT", tip.SpeedTexture, "BOTTOMLEFT", 0, -2)
        Owned:SetVertexColor(1.0, 0.82, 0.0, 1.0)

        tip.Owned = Owned
    end

    Owned:SetText(addon:CollectedText(speciesID))
    Owned:Show()

    -- XXX TRIPLE ECKS
    tip:SetSize(260,136)
end

function module:BattlePetToolTip_Hide()
    self:HideSubTip(BattlePetTooltip)
end

--
-- PetBattleUnitTooltip
--

function module:Initialize_PetBattleUnitTooltip()
    self.PetBattleUnit_Hooked = {}
    self:SecureHook("PetBattleUnitTooltip_UpdateForUnit")

    if is5_0 then
        self:SecureHook("PetBattleUnitFrame_UpdateDisplay")
    end
end

function module:PetBattleUnitTooltip_UpdateForUnit(tip, petOwner, petIndex)
    if not self.PetBattleUnit_Hooked[tip] then
        self:HookScript(tip, "OnHide", "PetBattleUnitTooltip_Hide")
        self.PetBattleUnit_Hooked[tip] = true
    end

    local CollectedText = tip.CollectedText

    if not addon.db.profile.enableBattleTip then
        if is5_0 then
            tip.CollectedText:Hide()
            tip.HealthBorder:SetPoint("TOPLEFT", tip.Icon, "BOTTOMLEFT", -1, -6)
        end
        return
    elseif addon.db.profile.useSubTip then
        if CollectedText and CollectedText:IsShown() then
            local height = tip:GetHeight()
            tip:SetHeight(height - CollectedText:GetHeight())
            CollectedText:Hide()
        end

        self:SubTip(tip, addon:CollectedText(speciesID))
        return
    end

    self:HideSubTip(tip)
    
    if not CollectedText then
        -- 5.0 support
        CollectedText = tip:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        CollectedText:SetJustifyH("LEFT")
        CollectedText:SetPoint("TOPLEFT", tip.Icon, "BOTTOMLEFT", 0, -4)

        tip.CollectedText = CollectedText
    end

    local height = tip:GetHeight()
    if CollectedText:IsShown() and not is5_0 then
        height = height - CollectedText:GetHeight()
    end
    
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    if is5_0 then
        CollectedText:SetWidth(tip:GetWidth() - 8) -- fudge
    end
    CollectedText:SetText(addon:CollectedText(speciesID))
    CollectedText:Show()

    tip.HealthBorder:SetPoint("TOPLEFT", CollectedText, "BOTTOMLEFT", -1, -6)
    tip:SetHeight(height + CollectedText:GetHeight())
end

function module:PetBattleUnitTooltip_Hide(tip)
    self:HideSubTip(tip)
end

-- 5.0 client support
function module:PetBattleUnitFrame_UpdateDisplay(frame)
    local quality = C_PetBattles.GetBreedQuality(frame.petOwner, frame.petIndex)
    if frame.Name then
        frame.Name:SetVertexColor(ITEM_QUALITY_COLORS[quality-1].r,
                                ITEM_QUALITY_COLORS[quality-1].g,
                                ITEM_QUALITY_COLORS[quality-1].b)
    end
end

--
-- GameTooltip
--

function module:Initialize_GameTooltip()
    self:HookScriptSilent(GameTooltip, "OnTooltipSetUnit", function()
        module:AlterGameTooltip(GameTooltip)
    end)
    self:HookScriptSilent(GameTooltip, "OnTooltipSetItem", function()
        module:AlterGameTooltip(GameTooltip)
    end)
    self:HookScriptSilent(ItemRefTooltip, "OnTooltipSetItem", function()
        module:AlterGameTooltip(ItemRefTooltip)
    end)

    self:HookScript(GameTooltip, "OnUpdate", GameTooltip_OnUpdate_Hook)
end

function module:AlterGameTooltip(tt)
    if not addon.db then
        return
    end
    
    if tt.GetUnit and addon.db.profile.enableCreatureTip then
        local _, unit = tt:GetUnit()
        if unit then
            if UnitIsWildBattlePet(unit) then
                local creatureID = tonumber(strsub(UnitGUID(unit),7,10), 16)
                local speciesID = LPJ:GetSpeciesIDForCreatureID(creatureID)

                local lineno, line = 0, nil
                while true do
                    lineno = lineno + 1
                    line = _G["GameTooltipTextLeft"..lineno] 
                    if not line or not line:IsShown() then
                        line = nil
                        break
                    end

                    local text = line:GetText()
                    if text == UNIT_CAPTURABLE then
                        break
                    elseif self.ITEM_PET_KNOWN_DEFORMAT and strmatch(text, self.ITEM_PET_KNOWN_DEFORMAT) then
                        -- XXX self.ITEM_PET_KNOWN_DEFORMAT nil check for 5.0 client
                        break
                    end
                end

                local newtext = addon:CollectedText(speciesID)
                if line then
                    line:SetText(newtext)
                    line:SetVertexColor(1, 1, 1)
                else
                    tt:AddLine(newtext)
                end
                tt:Show()
            end
            return
        end
    end
    
    if tt.GetItem and addon.db.profile.enableItemTip then
        local _, link = tt:GetItem()
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
                    tt:AddLine(addon:CollectedText(speciesID))
                    tt:Show()
                end
            end
            return
        end
    end
end

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
            return format("%s (%s)", line, addon:ShortOwnedList(speciesID))          
        end
    end

    return line
end

local lastMinimapTooltip
function GameTooltip_OnUpdate_Hook(tt)
    if addon.db and not addon.db.profile.enableMinimapTip then
        return
    elseif tt:GetOwner() ~= Minimap then
        return
    end
    
    local text = GameTooltipTextLeft1:GetText()
    if text ~= lastMinimapTooltip then
        return module:UpdateMiniMapTooltip(tt, text)
    end
end

function module:UpdateMiniMapTooltip(tt, text)
    text = string.gsub(text, "([^\n]+)", sub_PetName)
    GameTooltipTextLeft1:SetText(text)
    lastMinimapTooltip = text
    tt:Show()
end
