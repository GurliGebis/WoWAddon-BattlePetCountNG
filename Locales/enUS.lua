
--[[

Translations are maintained at http://wow.curseforge.com/projects/battlepetcount/localization/

This is the master import file for the localization system.  All changes to this
file need to be updated in the localization system.

--]]

local L = LibStub("AceLocale-3.0"):NewLocale("BattlePetCount", "enUS", true)
if not L then return end

--

L["YOU_OWN_COLON"] = "You own this pet:" -- XXX remove me?
L["YOU_OWN"] = "You own this pet." -- XXX remove me?
L["YOU_DONT_OWN"] = "You don't own this pet." -- XXX remove me?
L["ITEM_PET_KNOWN_5_0"] = "Collected (%d/%d)" -- 5.0 support
L["UPGRADE"] = "Upgrade"
L["OWNED"] = "Owned"
L["UNOWNED"] = "Unowned"
L["OPT_HEADER_BATTLE"] = "Battle"
L["OPT_HEADER_WORLD"] = "World"
L["OPT_HEADER_ITEMS"] = "Items"
L["OPT_BATTLE_TIP"] = "Alter In Battle Tooltip"
L["OPT_BATTLE_HINT_BOX"] = "Show In Battle Hint Box"
L["OPT_BATTLE_BORDER"] = "Alter Battle Pet Border Color"
L["OPT_BATTLE_BORDER_ICON"] = "Show Battle Pet Border Notice Icon"
L["OPT_CREATURE_TIP"] = "Alter Creature Tooltip"
L["OPT_MINIMAP_TIP"] = "Alter Minimap Tooltip"
L["OPT_CAGE_TIP"] = "Alter Caged Pet Tooltip"
L["OPT_ITEM_TIP"] = "Alter Learnable Item Tooltip"
L["OPT_ITEM_TIP_ALL"] = "Item Tooltip Includes Non-Battle Pets"
L["OPT_PREFER_NAMES_OVER_QUALITY"] = "Prefer to Show Pet Names"
L["OPT_USE_OLDER_TEXT"] = "Use original collected text style."
L["OPT_USE_SUB_TIP"] = "Use extra attached tooltip."
