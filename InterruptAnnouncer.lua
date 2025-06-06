local UnitGUID = UnitGUID;
local IsInInstance = IsInInstance;
local GetSpellLink = C_Spell and C_Spell.GetSpellLink or GetSpellLink
local InstanceType = "none"
local RaidIconMaskToIndex =
{
	[COMBATLOG_OBJECT_RAIDTARGET1] = 1,
	[COMBATLOG_OBJECT_RAIDTARGET2] = 2,
	[COMBATLOG_OBJECT_RAIDTARGET3] = 3,
	[COMBATLOG_OBJECT_RAIDTARGET4] = 4,
	[COMBATLOG_OBJECT_RAIDTARGET5] = 5,
	[COMBATLOG_OBJECT_RAIDTARGET6] = 6,
	[COMBATLOG_OBJECT_RAIDTARGET7] = 7,
	[COMBATLOG_OBJECT_RAIDTARGET8] = 8,
};

local function GetRaidIcon(unitFlags)
	-- Check for an appropriate icon for this unit
	local raidTarget = bit.band(unitFlags, COMBATLOG_OBJECT_RAIDTARGET_MASK);
	if (raidTarget == 0) then
		return "";
	end

	return "{rt"..RaidIconMaskToIndex[raidTarget].."}";
end

local interr = CreateFrame("Frame", "InterruptTrackerFrame", UIParent);
interr:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
interr:RegisterEvent("PLAYER_ENTERING_WORLD");
interr:RegisterEvent("ZONE_CHANGED_NEW_AREA");
interr:SetScript("OnEvent", function(self, event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local type, _, sourceGUID, sourceName, _, _, destGUID, destName, _, destRaidFlags, spellId = select(2, CombatLogGetCurrentEventInfo());
        if (type == "SPELL_INTERRUPT" and UnitGUID("player") == sourceGUID) then
            local extraSpellID = select(15, CombatLogGetCurrentEventInfo());
            local destIcon = "";
            if (destName) then
                destIcon = GetRaidIcon(destRaidFlags);
            end

            local interruptingSpell = GetSpellLink(spellId);
            local interruptedSpell = GetSpellLink(extraSpellID);
            local msg = "";
            if (IsInGroup()) then
                msg = interruptingSpell.." interrupted "..destIcon..destName.."'s "..interruptedSpell.."!";
            else
                local destStr = format(TEXT_MODE_A_STRING_SOURCE_UNIT, "", destGUID, destName, destName); -- empty icon, destRaidFlags = 0 when solo
                msg = "\124cffff4809"..sourceName..": \124r"..interruptingSpell.." \124cffff4809interrupted "..destStr.."'s\124r "..interruptedSpell.."\124cffff4809!\124r";
            end

            if (GetNumGroupMembers() > 0) then
                local msgType = "PARTY";
                if ((IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE)) and (InstanceType == "party" or InstanceType == "raid" or InstanceType == "pvp" or InstanceType == "scenario")) then -- Dungeon/Raid Finder/Battleground
                    msgType = "INSTANCE_CHAT";
                elseif (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
                    msgType = "RAID";
                end

                SendChatMessage(msg, msgType);
            else
                DEFAULT_CHAT_FRAME:AddMessage(msg);
            end
        end
    elseif (event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
        local _, iType = IsInInstance();
        InstanceType = iType;
    end
end);
