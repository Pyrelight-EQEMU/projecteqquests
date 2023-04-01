-- Replacement Cross-Spell Vendor. Do everything from one NPC instead of spreading across several.

local MESSAGE_COLOR = 15

function event_say(e)
    local CLASS_ID = e.other:GetClass()
    local SPELL_CLASS_ID = CLASS_ID - 1
    local unlocked_spells_string = e.other:GetBucket("unlocked-spells") or ""
    local UNLOCKED_SPELLS = {}
    local SPELLS = {}
    local SCRIBE_SPELLS = {}
    for slot_id = 0, 720 do
        local spell_id = e.other:GetSpellIDByBookSlot(slot_id)
        if spell_id <= 44000 and spell_id > 0 and eq.get_spell(tonumber(spell_id)):Classes(SPELL_CLASS_ID) < 254 then
            table.insert(SPELLS, eq.get_spell(tonumber(spell_id)))
        end
    end
    for token in string.gmatch(unlocked_spells_string, "%S+") do
        table.insert(UNLOCKED_SPELLS, eq.get_spell(tonumber(token)))
    end
    SPELLS = table_subtract(SPELLS, UNLOCKED_SPELLS)
    for _, spell in ipairs(UNLOCKED_SPELLS) do
        if not e.other:HasSpellScribed(spell:ID()) then
            table.insert(SCRIBE_SPELLS, spell)
        end
    end
    local adapt_points = tonumber(e.other:GetBucket("SpellPoints-" .. CLASS_ID)) or 0

    if e.message:findi("Hail") then
        if e.other:GetBucket("Spellshaper-Intro") then                     
            e.self:Say("Hail, " .. e.other:GetCleanName() .. ". you've returned. Are you ready to [" .. eq.say_link("adapt_resp_1", true, "adapt your spells") .. "], do you wish to [" .. eq.say_link("adapt_resp_2", true, "provide your vital energy") .. "] in preparation for my services, or do you seek access to the [" .. eq.say_link("adapt_resp_3", true, "spells you have already had me adapt") .. "]? ")
            e.other:Message(MESSAGE_COLOR, "You have " .. adapt_points .. " toward unlocking " .. e.other:GetClassName() .. " spells available. ")
        else
            e.self:Say("Hail, " .. e.other:GetCleanName() .. ". I am Lyrisia Silvermist, the Spellshaper. I posess the unique ability to [" .. eq.say_link("adapt_resp_1", true, "adapt the spells") .. "] from your active class for use with any other class that you might have access to. I will only accept payment in the form of your [" .. eq.say_link("adapt_resp_2", true, "vital energy") .. "], this is non-negotiable. ")
        end
    elseif e.message:findi("adapt_resp_1") then        
        e.other:SetBucket("Spellshaper-Intro", tostring(1))
        if next(SPELLS) then
            if adapt_points > 0 then            
                local classLevels = {{1,10}, {11,20}, {21,30}, {31,40}, {41,50}, {51,60}, {61,65}, {66,70}, {71,75}}
                local levelAvailability = {}
                for _, spell in ipairs(SPELLS) do
                    local class = spell:Classes(SPELL_CLASS_ID)
                    for i, levelRange in ipairs(classLevels) do
                        if class >= levelRange[1] and class <= levelRange[2] then
                            levelAvailability[i] = true
                        end
                    end
                end            
                local outputString = "Which level range of spell were you interested in adapting? "            
                for i, availability in pairs(levelAvailability) do
                    if availability then
                        local range = classLevels[i]
                        outputString = outputString .. "[" .. eq.say_link("adapt " .. range[1] .. " " .. range[2], true, range[1] .. "-" .. range[2]) .. "], "
                    end
                end
                outputString = outputString:sub(1, -3) -- remove the last ", "
                outputString = outputString:gsub(", ([^,]+)$", ", or %1") -- replace the last ", " with ", or"
                e.self:Say(outputString)         
            else            
                e.self:Say("I'm sorry, " .. e.other:GetCleanName() .. ". You'll need to [" .. eq.say_link("adapt_resp_2", true, "provide your vital energy") .. "] to me in order to fuel the process of adapting your spells before I can help you. ")
            end
        else 
            e.self:Say("I'm sorry, " .. e.other:GetCleanName() .. ". You don't have any spells in your spellbook that I haven't already adapted for you. ")
        end
    elseif e.message:findi("adapt_resp_2") then
        e.other:SetBucket("Spellshaper-Intro", tostring(1))
        e.self:Say("When you are [" .. eq.say_link("adapt_resp_4", true, "prepared to begin") .. "], I will drain you of all unspent alternate advancement points. You will recieve a corresponding number of adaptation points in my ledger, which I will allow you to later redeem for adapted spells. ")
    elseif e.message:findi("adapt_resp_3") then    
        if next(SCRIBE_SPELLS) then            
            local classLevels = {{1,10}, {11,20}, {21,30}, {31,40}, {41,50}, {51,60}, {61,65}, {66,70}, {71,75}}
            local levelAvailability = {}
            for _, spell in ipairs(SCRIBE_SPELLS) do
                local class = spell:Classes(SPELL_CLASS_ID)
                for i, levelRange in ipairs(classLevels) do
                    if class >= levelRange[1] and class <= levelRange[2] then
                        levelAvailability[i] = true
                    end
                end
            end
            local outputString = "Which level range of spell were you interested in scribing? "
            for i, availability in pairs(levelAvailability) do
                if availability then
                    local range = classLevels[i]
                    outputString = outputString .. "[" .. eq.say_link("scribe " .. range[1] .. " " .. range[2], true, range[1] .. "-" .. range[2]) .. "], "
                end
            end
            outputString = outputString:sub(1, -3) -- remove the last ", "
            outputString = outputString:gsub(", ([^,]+)$", ", or %1") -- replace the last ", " with ", or"
            e.self:Say(outputString)         
        else            
            e.self:Say("I'm sorry, " .. e.other:GetCleanName() .. ". I don't see any spells that I've adapted for you that you don't already have scribed. I can [" .. eq.say_link("show all", true, "show you all of the") .. "] spells that I've adapted for you, if you'd like. Otherwise, you'll need to work with me to [" .. eq.say_link("adapt_resp_1", true, "adapt your spells") .. "] before I can scribe them for you in the guise of your alternate class. ")
        end
    elseif e.message:findi("adapt_resp_4") then
        if e.other:GetAAPoints() > 0 then
            local drained_points = e.other:GetAAPoints()
            local awarded_points = drained_points * 20;
            e.other:SetBucket("SpellPoints-" .. CLASS_ID, tostring((tonumber(e.other:GetBucket("SpellPoints-" .. CLASS_ID)) or 0) + awarded_points))
            e.other:SetAAPoints(0);
            e.other:Message(MESSAGE_COLOR, "You have lost " .. drained_points .. " AA points and been rewarded with " .. awarded_points .. " adaptation points for " .. e.other:GetClassName() .. " spells. ")
            e.self:Say("Excellent. I have taken your excess energy and will record your contribution. Do you wish to [" .. eq.say_link("adapt_resp_1", true, "adapt your spells") .. "] immediately? ")
        else
            e.self:Say("You have no excess energy to donate. Please return to me when you have unspent AA points. ")
        end    
    elseif e.message:find("^adapt%s+(%d+)%s+(%d+)$") and not e.message:find("^adapt_resp_") then
        if e.message:findi("adapt") then
            local from, to = e.message:match("(%d+)%s+(%d+)")
            if from and to then
                local spellsInRange = {}
                for _, spell in ipairs(SPELLS) do
                    local level = spell:Classes(SPELL_CLASS_ID)
                    if level >= tonumber(from) and level <= tonumber(to) then                       
                        local outputString = string.format("Cost: %d -[" .. eq.say_link(tostring("unlock "..spell:ID()), true, spell:Name()) .. "]-", tonumber(getSpellCost(spell:ID(), SPELL_CLASS_ID)))
                        e.other:Message(MESSAGE_COLOR, outputString)
                    end
                end
            else
                e.other:Message(MESSAGE_COLOR, "Invalid format. Please use the format 'adapt N N' ")
            end
        end
    elseif e.message:find("%f[%a]unlock %d+") then
        local spellID = tonumber(string.match(e.message, "%f[%a]unlock (%d+)"))
        local cost = tonumber(getSpellCost(spellID, SPELL_CLASS_ID))
        if (spellIDMatchesTable(spellID, SPELLS) and adapt_points >= cost) then
            adapt_points = adapt_points - cost
            e.other:SetBucket("unlocked-spells", unlocked_spells_string .. " " .. spellID)
            e.other:SetBucket("SpellPoints-" .. CLASS_ID, tostring(adapt_points))
            e.other:Message(MESSAGE_COLOR, "You have successfully unlocked " .. eq.get_spell(spellID):Name() .. " for " .. cost .. " adaptation points.")
            e.other:Message(MESSAGE_COLOR, "You have " .. adapt_points .. " toward unlocking " .. e.other:GetClassName() .. " spells available.")
        end   
    elseif e.message:find("^scribe%s+(%d+)%s+(%d+)$") then
        if e.message:findi("scribe") then
            local from, to = e.message:match("(%d+)%s+(%d+)")
            if from and to then
                local spellsInRange = {}
                for _, spell in ipairs(SCRIBE_SPELLS) do
                    local level = spell:Classes(SPELL_CLASS_ID)
                    if level >= tonumber(from) and level <= tonumber(to) then                       
                        local outputString = "-[" .. eq.say_link(tostring("scribe "..spell:ID()), true, spell:Name()) .. "]-"
                        e.other:Message(MESSAGE_COLOR, outputString)
                    end
                end
            else
                e.other:Message(MESSAGE_COLOR, "Invalid format. Please use the format 'scribe N N' ")
            end
        end    
    elseif e.message:find("%f[%a]scribe %d+") then
        local spellID = tonumber(string.match(e.message, "%f[%a]scribe (%d+)"))
        if (spellIDMatchesTable(spellID, SCRIBE_SPELLS)) then
            e.other:ScribeSpell(spellID, e.other:GetNextAvailableSpellBookSlot(), true)
        end
    elseif e.message:findi("show all") then
        for i, v in ipairs(UNLOCKED_SPELLS) do
            e.other:Message(MESSAGE_COLOR, "Spell: " .. v:Name() .. " ")
        end          
    end
end

function getSpellCost(spellID, SPELL_CLASS_ID)
    local spell_info = eq.get_spell(spellID)
    local spell_level = spell_info:Classes(SPELL_CLASS_ID)
    
    if (spell_level >= 1 and spell_level <= 10) then
        return 10
    elseif (spell_level >= 11 and spell_level <= 20) then
        return 20
    elseif (spell_level >= 21 and spell_level <= 30) then
        return 30
    elseif (spell_level >= 31 and spell_level <= 40) then
        return 40
    elseif (spell_level >= 41 and spell_level <= 50) then
        return 50
    elseif (spell_level >= 51 and spell_level <= 60) then
        return 100
    elseif (spell_level >= 61 and spell_level <= 65) then
        return 500
    elseif (spell_level >= 66 and spell_level <= 70) then
        return 1000
    elseif (spell_level >= 71 and spell_level <= 75) then
        return 2500
    end
end

-- Define the custom comparison function
function compareSpellsByClass(spell1, spell2, classId)
    -- Get the class value for each spell
    local classValue1 = spell1:Classes(tonumber(classId)) or 0
    local classValue2 = spell2:Classes(tonumber(classId)) or 0
  
    -- Compare the class values
    if classValue1 == classValue2 then
      -- If the class values are the same, use the spell names to break ties
      return spell1:Name() < spell2:Name()
    else
      -- Sort spells with higher class values first
      return classValue1 < classValue2
    end
end

function table_subtract(t1, t2)
    local result = {}
    for _, v1 in ipairs(t1) do
        local found = false
        for _, v2 in ipairs(t2) do
            if v1:ID() == v2:ID() then
                found = true
                break
            end
        end
        if not found then
            table.insert(result, v1)
        end
    end
    return result
end

function levelToString(range)
    return range[1] .. "-" .. range[2]
end

function spellIDMatchesTable(spellID, spellTable)
    for _, spell in ipairs(spellTable) do
        if spell:ID() == spellID then
            return true
        end
    end
end