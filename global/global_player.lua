-- items: 67704, 72091, 62621, 62622, 62844, 62827, 62828, 62836, 62883, 62876, 47100, 62878, 62879

local don = require("dragons_of_norrath")

function event_connect(e)
    don.fix_invalid_faction_state(e.self)

	check_level_flag(e)
	e.self:GrantAlternateAdvancementAbility(938, 8, true)

	check_class_switch_aa(e)
	check_starting_attunement(e)
	refresh_instance_task(e);

	local bucket = e.self:GetBucket("FirstLoginAnnounce")
	if (not bucket or bucket == "") and e.self:GetLevel() == 1 then
	  e.self:SetBucket("FirstLoginAnnounce", "1")
	  eq.world_emote(15, e.self:GetCleanName() .. " has logged in for the first time!")
	  eq.discord_send("ooc", e.self:GetCleanName() .. " has logged in for the first time!")
	end
end

function event_level_up(e)
  local free_skills =  {0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76};

  for k,v in ipairs(free_skills) do
    if ( e.self:MaxSkill(v) > 0 and e.self:GetRawSkill(v) < 1 and e.self:CanHaveSkill(v) ) then 
      e.self:SetSkill(v, 1);
    end      
  end

  if (e.self:GetLevel() % 5 == 0) then
	eq.world_emote(15,e.self:GetCleanName() .. " has reached level " .. e.self:GetLevel() .. "!")
	eq.discord_send("ooc", e.self:GetCleanName() .. " has reached level " .. e.self:GetLevel() .. "!")
  end
end

function check_level_flag(e)
	local key = e.self:CharacterID() .. "-CharMaxLevel"
	
	if eq.get_data(key) == "" then
		eq.set_data(key, "60")
		e.self:Message(15, "Your Level Cap has been set to 60.")
	end
end

function event_enter_zone(e)
	refresh_instance_task(e);
end

function refresh_instance_task(e)
    -- Get client and dynamic zone info
    local client = e.self
    local dz     = client:GetExpedition()
    local dz_id  = dz:GetZoneID()
    local config = eq.get_data("instance-" .. eq.get_zone_short_name_by_id(dz_id) .. "-" .. dz:GetInstanceID())
	local reward = tonumber(string.match(config, 'reward=(%d+)')) or 0

    -- Loop over the tasks from 1 to 999
    for i = 1, 999 do
        if client:IsTaskActive(1000 + i) then
			if i ~= dz_id or reward == 0 then
            	client:FailTask(1000 + i)				
			end
        end
    end

	if reward > 0 then
		eq.debug("zone_id:" .. dz:GetZoneID() .. " reward:" .. reward)
		if eq.get_zone_id() ==  dz:GetZoneID() and eq.get_zone_instance_id() == dz:GetInstanceID() then
			eq.debug("check")
			if not client:IsTaskActive(1000 + dz_id) then
				client:AssignTask(1000 + dz_id)
			end
		end
	end
end

function event_loot(e)
	eq.debug("event_loot:" .. eq.get_item_name(e.item:GetID()))
    if string.find(eq.get_item_name(e.item:GetID()), "^Fabled ") ~= nil then
        eq.world_emote(15, e.self:GetCleanName() .. " has claimed the " .. eq.item_link(e.item:GetID()) .. "!")
		eq.discord_send("ooc", e.self:GetCleanName() .. " has claimed the " .. eq.get_item_name(e.item:GetID()) .. "! (https://www.pyrelight.net/allaclone/?a=item&id=" .. e.item:GetID() ..")")
    end
end

function event_discover_item(e)
	if e.item:HP() > 0 or e.item:Mana() > 0 or e.item:AStr() > 0 or e.item:ASta() > 0 or e.item:ADex() > 0 or e.item:AAgi() > 0 or e.item:AInt() > 0 or e.item:AWis() > 0 or e.item:ACha() > 0 or e.item:AugType() > 0 then
		local key = e.self:CharacterID() .. "-DiscoCount";
		if (eq.get_data(key) == nil or eq.get_data(key) == "") then
			eq.set_data(key,tostring(1));
		else
			eq.set_data(key,tostring(tonumber(eq.get_data(key)) + 1));
		end
		eq.world_emote(15,e.self:GetCleanName() .. " is the first to discover " .. eq.item_link(e.item:ID()) .. "!")
		eq.discord_send("ooc", e.self:GetCleanName() .. " is the first to discover " .. e.item:Name() .. "! (https://www.pyrelight.net/allaclone/?a=item&id=" .. e.item:ID() ..")")
	end
end

function event_combine_validate(e)
	-- e.validate_type values = { "check_zone", "check_tradeskill" }
	-- criteria exports:
	--	["check_zone"].         = e.zone_id
	--	["check_tradeskill"]    = e.tradeskill_id (not active)
	if (e.recipe_id == 10344) then
		if (e.validate_type:find("check_zone")) then
			if (e.zone_id ~= 289 and e.zone_id ~= 290) then
				return 1;
			end
		end
	end

	return 0;
end

function event_combine_success(e)
	if (e.recipe_id == 10904 or e.recipe_id == 10905 or e.recipe_id == 10906 or e.recipe_id == 10907) then
		e.self:Message(1,
		"The gem resonates with power as the shards placed within glow unlocking some of the stone's power. "
		.. "You were successful in assembling most of the stone but there are four slots left to fill, "
		.. "where could those four pieces be?"
		);
	elseif(e.recipe_id == 10903 or e.recipe_id == 10346 or e.recipe_id == 10334) then
		local reward = { };
		reward["melee"] =  { ["10903"] = 67665, ["10346"] = 67660, ["10334"] = 67653 };
		reward["hybrid"] = { ["10903"] = 67666, ["10346"] = 67661, ["10334"] = 67654 };
		reward["priest"] = { ["10903"] = 67667, ["10346"] = 67662, ["10334"] = 67655 };
		reward["caster"] = { ["10903"] = 67668, ["10346"] = 67663, ["10334"] = 67656 };

		local ctype = eq.ClassType(e.self:GetClass());
		e.self:SummonItem(reward[ctype][tostring(e.recipe_id)]);
		e.self:SummonItem(67704); -- Item: Vaifan's Clockwork Gemcutter Tools
		e.self:Message(1, "Success");
	--cleric 1.5
	elseif(e.recipe_id == 19460) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(15,'You have gained 5 ability points!');
		eq.set_global("cleric_epic","7",5,"F");
	--rogue 1.5
	elseif(e.recipe_id == 13402 or e.recipe_id == 13403 or e.recipe_id == 13404 or e.recipe_id == 13405) then
		e.self:Message(15,"The piece of the metal orb fuses together with the blue diamonds under the intense heat of the forge. As it does, a flurry of images flash through your mind... A ranger and his bear side by side, stoic and unafraid, in a war-torn forest. A bitter tattooed woman with bluish skin wallowing in misery in a waterfront tavern. An endless barrage of crashing thunder and lightning illuminating a crimson brick ampitheater. Two halflings locked in a battle of wits using a checkered board. The images then fade from your mind");
	--ranger 1.5 tree
	elseif(e.recipe_id ==13412) then
		eq.set_global("ranger_epic","3",5,"F");
		if(eq.get_zone_short_name()=="jaggedpine") then
			e.self:Message(15,"The seed grows rapidly the moment you push it beneath the soil. It appears at first as a mere shoot, but within moments grows into a stout sapling and then into a gigantic tree. The tree is one you've never seen before. It is the coloration and thick bark of a redwood with the thick bole indicative of the species. The tree is, however, far too short and has spindly branches sprouting from it with beautiful flowers that you would expect on a dogwood. You take all of this in at a glance. It takes you a moment longer to realize that the tree is moving.");			
			eq.spawn2(181222, 0, 0, e.self:GetX()+3,e.self:GetY()+3,e.self:GetZ(),0); -- NPC: Red_Dogwood_Treant
		else
			e.self:Message(15,"The soil conditions prohibit the seed from taking hold");
			e.self:SummonItem(72091); -- Item: Fertile Earth
			e.self:SummonItem(62621); -- Item: Senvial's Blessing
			e.self:SummonItem(62622); -- Item: Grinbik's Blessing
			e.self:SummonItem(62844); -- Item: Red Dogwood Seed
		end
	--ranger 1.5 final
	elseif(e.recipe_id ==13413) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(15,'You have gained 5 ability points!');
		eq.set_global("ranger_epic","5",5,"F");
	--ranger 2.0
	elseif(e.recipe_id ==19914 or e.recipe_id==19915) then
		e.self:Message(15,'Very Good. Now we must attune the cage to the specific element we wish to free. You will need two items, one must protect from the element and the other must be able to absorb an incredible amount of that element. This is not a simple task. You must first discover the nature of the spirit that you wish to free and then find such items that will allow you to redirect its power. You must know that each spirit represents a specific area within their element and that is what you must focus on, not their element specifically. For example, Grinbik was an earth spirit, but his area of power was fertility. Senvial was a spirit of Water, but his power was in mist and fog.');
		eq.set_global("ranger_epic","8",5,"F");
	elseif(e.recipe_id ==19916) then
		e.self:Message(15,"The Red Dogwood Treant speaks to you from within your sword. 'Well done. This should allow me to free a spirit with power over cold and ice. Now you need to find the power that binds the spirit and unleash it where that spirit is bound.'");	
	elseif(e.recipe_id ==19917) then
		if(eq.get_zone_short_name()=="anguish") then
			eq.spawn2(317113, 0, 0, e.self:GetX(),e.self:GetY(),e.self:GetZ(),0); -- NPC: #Oshimai_Spirit_of_the_High_Air
		end
	-- paladin 1.5 final
	elseif(e.recipe_id ==19880) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(15,'You have gained 5 ability points!');	
		eq.set_global("paladin_epic","8",5,"F");
		e.self:Message(6,"As the four soulstones come together, a soft blue light eminates around the dark sword. The soulstones find themselves at home within the sword. A flash occurs and four voices in unison speak in your mind, 'Thank you for saving us and giving us a purpose again. You are truly our savior and our redeemer, and we shall serve you from now on. Thank you, noble knight!")
	--bard 1.5 final	
	elseif(e.recipe_id == 19882) then
		e.self:AddEXP(25000);
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(15,'You have gained 5 ability points!');	
		eq.set_global("bard15","6",5,"F");
	--druid 1.5 feerrott
	elseif(e.recipe_id == 19888) then
		if(eq.get_zone_short_name()=="feerrott") then
			eq.spawn2(47209, 0, 0, e.self:GetX()+10,e.self:GetY()+10,e.self:GetZ(),0); -- NPC: corrupted_spirit
			e.self:Message(0,"compelled spirit screams as his essences is forced back into the world of the living. 'What is this? Where am I? Who are you? What do you want from me?");
		else
			e.self:SummonItem(62827); -- Item: Mangled Head
			e.self:SummonItem(62828); -- Item: Animating Heads
			e.self:SummonItem(62836); -- Item: Soul Stone
		end
	-- druid 1.5 final
	elseif(e.recipe_id ==19892) then
		e.self:AddAAPoints(5);
		e.self:Ding();
		e.self:Message(15,'You have gained 5 ability points!');	
		eq.set_global("druid_epic","8",5,"F");	
		e.self:SendMarqueeMessage(15, 510, 1, 100, 10000, "You plant the Mind Crystal and the Seed of Living Brambles in the pot. The pot grows warm and immediately you see a vine sprouting from the soil. The vine continues to grow at a tremendous rate. Brambles grow into the heart of the crystal where the core impurity is and split it. They continue to grow at an astounding speed and soon burst the pot and form the Staff of Living Brambles");
	--druid 2.0 sub final
	elseif(e.recipe_id ==19908) then
		if(eq.get_zone_short_name()=="anguish") then
			eq.spawn2(317115, 0, 0, e.self:GetX()+3,e.self:GetY()+3,e.self:GetZ(),0); -- NPC: #Yuisaha
			e.self:SummonItem(62883); -- Item: Essence of Rainfall
			e.self:SummonItem(62876); -- Item: Insulated Container
		else
			e.self:Message(15,"The rain spirit cannot be reached here");
			e.self:SummonItem(47100); -- Item: Globe of Discordant Energy
			e.self:SummonItem(62876); -- Item: Insulated Container
			e.self:SummonItem(62878); -- Item: Frozen Rain Spirit
			e.self:SummonItem(62879); -- Item: Everburning Jagged Tree Limb
		end
	--druid 2.0 final
	elseif(e.recipe_id ==19909) then	
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(15,'You have gained 10 ability points!');	
		eq.set_global("druid_epic","13",5,"F");	
		--e.self:SendMarqueeMessage(15, 510, 1, 100, 10000, "You plant the Mind Crystal and the Seed of Living Brambles in the pot. The pot grows warm and immediately you see a vine sprouting from the soil. The vine continues to grow at a tremendous rate. Brambles grow into the heart of the crystal where the core impurity is and split it. They continue to grow at an astounding speed and soon burst the pot and form the Staff of Living Brambles");
	--warrior 2.0
	elseif(e.recipe_id ==19902) then	
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(15,'You have gained 10 ability points!');	
		eq.set_global("warrior_epic","21",5,"F");		
	-- CLR 2.0
	elseif (e.recipe_id == 19893) then
		e.self:Message(13, "Omat should probably see this.");
	--ench 2.0
	elseif (e.recipe_id == 19919) then
		eq.set_global("ench_epic","9",5,"F");
		e.self:Message(15,"Your Oculus of Persuasion gleams with a blinding light for a moment, dimming quickly to its previous understated beauty. The light has left an image burned into your mind, a strangely tattooed woman chanting by a waterfall.");
	--ench 2.0 final
	elseif (e.recipe_id == 19920) then
		e.self:Message(15,"The discordant energy shoots through the staff, sending a shower of sparks through the air. The crystal shatters before you, and as the sparks fade away you notice the changes in your staff.");
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(15,'You have gained 10 ability points!');
		eq.set_global("ench_epic","10",5,"F");
	--pal 2.0 final
	elseif (e.recipe_id == 19925) then
		e.self:Message(15,"As you combine all six tokens in the scabbard with Redemption, you feel a tugging at your soul. An energy flows through you as you feel the virtues of your inner self being tugged and tempered into the weapon. For a second you feel drained, but now that feeling has subsided. A final flash of light occurs and a new sword is tempered; Nightbane, Sword of the Valiant");
		e.self:AddEXP(50000);
		e.self:AddAAPoints(10);
		e.self:Ding();
		e.self:Message(15,'You have gained 10 ability points!');
		eq.set_global("paladin_epic","11",5,"F");
		eq.delete_global("paladin_epic_mmcc");
		eq.delete_global("paladin_epic_hollowc");
	elseif (e.recipe_id == 2182) then -- Pumpkin Pie
		if (eq.is_task_activity_active(8013, 0)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 0, 1);
		end
	elseif (e.recipe_id == 2181) then -- Pumpkin Bread
		if (eq.is_task_activity_active(8013, 1)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 1, 1);
		end
	elseif (e.recipe_id == 7811) then -- Spiced Pumpkin Cider
		if (eq.is_task_activity_active(8013, 2)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 2, 1);
		end
	elseif (e.recipe_id == 2183) then -- Pumpkin Shake
		if (eq.is_task_activity_active(8013, 3)) then -- The Hungry Halfling
			eq.update_task_activity(8013, 3, 1);
		end
	end
end

function event_command(e)
	return eq.DispatchCommands(e);
end

function event_task_complete(e)
  don.on_task_complete(e.self, e.task_id)
end

function check_class_switch_aa(e)
	accum = 0
	for i=16,1,-1
	do
		eq.debug("Checking class: " .. i);
		if (e.self:GetBucket("class-"..i.."-unlocked") == '1') then
			eq.debug("Unlocked Class: " .. i);
			e.self:GrantAlternateAdvancementAbility(20000 + i, 1, true)			
			accum = accum + 1			
		end		 
	end
	eq.debug("Unlocked Classes: " .. accum);
	expPenalty = calculate_modifier(accum)
	e.self:SetEXPModifier(0, expPenalty)
	eq.debug("Setting your Exp Modifier to: " .. expPenalty)
end

function calculate_modifier(count)
    if count == 1 then
        return 1
    end

    modifier = 1
    for i=count,2,-1 do
        modifier = modifier * .90
    end
	modifier = 1
    return modifier
end


function convert_spellunlocks(e)
	if e.self:GetBucket("unlocked-spells") == nil or e.self:GetBucket("unlocked-spells") == "" then
		local UNLOCKED_SPELLS = {}
		for spell_id = 1, 44000 do
			local unlocked = e.self:GetBucket("Spell-" .. spell_id .. "-unlocked")
			if unlocked and unlocked ~= "" then
				table.insert(UNLOCKED_SPELLS, spell_id)
			end
		end
		e.self:SetBucket("unlocked-spells", table.concat(UNLOCKED_SPELLS, " "))
	end
end

-- Serializer for List
function SerializeList(list)
    return table.concat(list, ',')
end

-- Deserializer for List
function DeserializeList(str)
    local list = {}
    for match in (str..','):gmatch("(.-)"..',') do
        table.insert(list, match)
    end
    return list
end

-- Serializer for Hash (Table in Lua context)
function SerializeHash(tbl)
    local str = ""
    for k, v in pairs(tbl) do
        str = str..k.."="..v..";"
    end
    return str
end

-- Deserializer for Hash (Table in Lua context)
function DeserializeHash(str)
    local hash = {}
    for match in (str..';'):gmatch("(.-)"..';') do
        local k, v = match:match("(%w+)=(%w+)")
        hash[k] = v
    end
    return hash
end
