-- Replacement Cross-Spell Vendor. Do everything from one NPC instead of spreading across several.

local MESSAGE_COLOR = 15

function event_say(e)

    local CLASS_ID = e.other:GetClass()
    -- Corrected for off-by-one in some calls
    local SPELL_CLASS_ID = CLASS_ID - 1

    local SPELLS = {}
    for slot_id = 0, 720 do
        local spell_id = e.other:GetSpellIDByBookSlot(slot_id)
        local unlocked = e.other:GetBucket("Spell-" .. spell_id .. "-unlocked")
        if unlocked == nil or unlocked == "" then
            table.insert(SPELLS, spell_id)
        end
    end

    local UNLOCKED_SPELLS = {}
    
    -- Sort spells arrays by level
    table.sort(SPELLS, function(a, b) return compareSpells(a, b, SPELL_CLASS_ID) end)   

    local adapt_points = tonumber(e.other:GetBucket("SpellPoints-" .. CLASS_ID)) or 0

    if e.message:findi("Hail") then
        if e.other:GetBucket("Spellshaper-Intro") then            
            e.self:Say("Hail, " .. e.other:GetCleanName() .. ". you've returned. Are you ready to [" .. eq.say_link("adapt_resp_1", true, "adapt your spells") .. "], do wish to [" .. eq.say_link("adapt_resp_2", true, "provide your vital energy") .. "] in preparation for my services, or do you seek access to the [" .. eq.say_link("adept_resp_3", true, "spells you have already had me adapt") .. "]?")
        else
            e.self:Say("Hail, " .. e.other:GetCleanName() .. ". I am Lyrisia Silvermist, the Spellshaper. I posess the unique ability to [" .. eq.say_link("adapt_resp_1", true, "adapt the spells") .. "] from your active class for use with any other class that you might have access to. I will only accept payment in the form of your [" .. eq.say_link("adapt_resp_2", true, "vital energy") .. "], this is non-negotiable")
        end
    -- Do-unlocks branch
    elseif e.message:findi("adapt_resp_1") then        
        e.other:SetBucket("Spellshaper-Intro", tostring(1))
        

    -- Convert AA branch
    elseif e.message:findi("adapt_resp_2") then
        e.other:SetBucket("Spellshaper-Intro", tostring(1))
        e.self:Say("When you are [" .. eq.say_link("adapt_resp_4", true, "prepared to begin") .. "], I will drain you of all unspent alternate advancement points. You will recieve a corresponding number of adaptation points in my ledger, which I will allow you to later redeem for adapted spells.")
    elseif e.message:findi("adept_resp_3") then
        for spell_id = 1, 44000 do
            local unlocked = e.other:GetBucket("Spell-" .. spell_id .. "-unlocked")
            if unlocked and unlocked ~= "" then
                table.insert(UNLOCKED_SPELLS, unlocked)
            end
        end        
        table.sort(UNLOCKED_SPELLS, function(a, b) return compareSpells(a, b, SPELL_CLASS_ID) end)
        e.self:Say("Done.")
    elseif e.message:findi("adept_resp_4") then
        if (e.other:GetAAPoints() > 0) then
            local drained_points = e.other:GetAAPoints()
            local awarded_points = drained_points * 20;
            e.other:SetBucket("SpellPoints-" .. CLASS_ID, tostring(tonumber(e.other:GetBucket("SpellPoints-" .. CLASS_ID)) + awarded_points))
            e.other:SetAAPoints(0);
            e.other:Message(MESSAGE_COLOR, "You have lost " .. drained_points .. " AA points and been rewarded with " .. awarded_points .. " adaptation points for " .. e.other:GetClassNam() .. " spells.")
            e.self:Say("Excellent. I have taken your excess energy and will record your contribution. Do you wish to [" .. eq.say_link("adapt_resp_1", true, "adapt your spells") .. "] immediately?")
        else
            e.self:Say("You have no excess energy to donate. Please return to me when you have unspent AA points.")
        end
    end
end

function getSpellCost(spellID)

    local spell_info = eq.get_spell(spellID)
    local spell_level = spell_info:Classes(SPELL_CLASS_ID)

    if (spell_level <= 50) then
        return math.floor(spell_level)
    elseif (spell_level <= 60) then
        return math.floor(spell_level * 2)
    elseif (spell_level <= 65) then
        return math.floor(spell_level * 4)
    elseif (spell_level <= 70) then
        return math.floor(spell_level * 8)
    elseif (spell_level <= 75) then
        return math.floor(spell_level * 16)
    end
end

-- Define the function that will be used to compare two spells
function compareSpells(spellId1, spellId2, spellClassId)
    local spell1 = eq.get_spell(to_number(spellId1))
    local spell2 = eq.get_spell(to_number(spellId2))
  
    -- Get the class value for each spell
    local classValue1 = spell1:Classes(to_number(spellClassId)) or 0
    local classValue2 = spell2:Classes(to_number(spellClassId)) or 0
  
    -- Compare the class values
    if classValue1 == classValue2 then
      -- If the class values are the same, use the spell IDs to break ties
      return spell1:Name() < spell2:Name()
    else
      -- Sort spells with higher class values first
      return classValue1 < classValue2
    end
end