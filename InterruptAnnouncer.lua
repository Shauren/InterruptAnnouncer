local UnitGUID = UnitGUID;
local GetNumRaidMembers = GetNumRaidMembers;
local GetNumPartyMembers = GetNumPartyMembers;
local IsInInstance = IsInInstance;
local InstanceType = "none"
local CTL = _G.ChatThrottleLib;
local TEXT_SPELL_LINK = "\124cff71d5ff\124Hspell:%s\124h[%s]\124h\124r";
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
interr:SetScript("OnEvent", function(self, event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local type, _, sourceGUID, sourceName, _, _, destGUID, destName, _, destRaidFlags, spellId, spellName, _ = select(2, ...);
        if (type == "SPELL_INTERRUPT" and UnitGUID("player") == sourceGUID) then
            local extraSpellID, extraSpellName = select(15, ...);
            local destIcon = "";
            if (destName) then
                destIcon = GetRaidIcon(destRaidFlags);
            end
            
            local interruptingSpell = format(TEXT_SPELL_LINK, spellId, spellName);
            local interruptedSpell = format(TEXT_SPELL_LINK, extraSpellID, extraSpellName);
            local msg = "";
            if (IsInGroup()) then
                msg = interruptingSpell.." interrupted "..destIcon..destName.."'s "..interruptedSpell.."!";
            else
                local destStr = format(TEXT_MODE_A_STRING_SOURCE_UNIT, "", destGUID, destName, destName); -- empty icon, destRaidFlags = 0 when solo
                msg = "\124cffff4809"..sourceName..": \124r"..interruptingSpell.." \124cffff4809interrupted "..destStr.."'s\124r "..interruptedSpell.."\124cffff4809!\124r";
            end
            
            local msgType = "PARTY";
            if (GetNumGroupMembers() > 0) then
                if (InstanceType == "pvp") then
                    msgType = "BATTLEGROUND";
                elseif (IsInRaid()) then
                    msgType = "RAID";
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage(msg);
                return;
            end
            
            if (CTL) then
                CTL:SendChatMessage("ALERT", "IA", msg, msgType);
            end
        end
    elseif (event == "PLAYER_ENTERING_WORLD") then
        _, InstanceType = IsInInstance();
    end
end);
