local UnitGUID = UnitGUID;
local GetNumRaidMembers = GetNumRaidMembers;
local GetNumPartyMembers = GetNumPartyMembers;
local CTL = _G.ChatThrottleLib;
local TEXT_SPELL_LINK = "\124cff71d5ff\124Hspell:%s\124h[%s]\124h\124r";

local interr = CreateFrame("Frame", "InterruptTrackerFrame", UIParent);
interr:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
interr:SetScript("OnEvent", function(self, event, ...)
    if (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        local type, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellId, spellName, _ = select(2, ...);
        if (type == "SPELL_INTERRUPT" and sourceGUID == UnitGUID("player")) then
            local extraSpellID, extraSpellName = select(15, ...);
            local destIcon = "";
            if (destName) then
                destIcon = CombatLog_String_GetIcon(destFlags, "dest");
            end
            
            local interruptingSpell = format(TEXT_SPELL_LINK, spellId, spellName);
            local interruptedSpell = format(TEXT_SPELL_LINK, extraSpellID, extraSpellName);
            local msg = "";
            if (GetNumPartyMembers() < 1 and GetNumRaidMembers() < 1) then
                local destStr = format(TEXT_MODE_A_STRING_SOURCE_UNIT, destIcon, destGUID, destName, destName);
                msg = "\124cffff4809"..sourceName..": \124r"..interruptingSpell.." \124cffff4809interrupted "..destStr.."'s\124r "..interruptedSpell.."\124cffff4809!\124r";
            else
                msg = interruptingSpell.." interrupted "..destIcon..destName.."'s "..interruptedSpell.."!";
            end
            
            local msgType = "PARTY";
            if (GetNumRaidMembers() > 0) then
                msgType = "RAID";
            elseif (GetNumPartyMembers() < 1) then
                DEFAULT_CHAT_FRAME:AddMessage(msg);
                return;
            end
            
            if (CTL) then
                CTL:SendChatMessage("ALERT", "IA", msg, msgType);
            end
        end
    end
end);
