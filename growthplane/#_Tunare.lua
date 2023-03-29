-- #_Tunare NPCID: 127001
-- This is Tunare up in her tree.
function event_combat(e)
	if (e.joined) then
		-- spawn #tunare to fight
		eq.spawn2(127098,0,0,-247,1609,-40,424); -- needs_heading_validation
		call_zone_to_assist(e.other);
		eq.depop_with_timer();
	end
end

function call_zone_to_assist(e_other)
	-- set to true to enable debug messages
	local show_debug = false;
	-- grab the entity list
	local entity_list = eq.get_entity_list();
	-- aggro all of the bosses in the zone onto whoever attacked me.
	-- only aggro these mobs #Prince Thirneg (127096), keeper of the glades (127016), Undogo Digolo (127015)
	-- #Treah Greenroot (127021), Ail_the_Elder (127020), Rumbleroot (127019), Fayl Everstrong (127018)
	-- Guardian of Tunare (127007), Grahl Strongback (127022), Ordro (127040), Farstride Unicorn (127093)
	-- Galiel Spirithoof (127023), Sarik the Fang (127017)
	local include_npc_list = Set {127096, 127016, 127015, 127007, 127022, 127040, 127093, 127023, 127017};
	local npc_list = entity_list:GetNPCList();
	if (npc_list ~= nil) then
		for npc in npc_list.entries do
			if (include_npc_list[npc:GetNPCTypeID()] != nil) then
				-- npc.valid will be true if the NPC is actually spawned
				if (npc.valid) then
					npc:AddToHateList(e_other,1);
					if (show_debug) then e_other:Message(4,"NPCID: " .. npc:GetNPCTypeID() .. " is valid, adding hate on " .. npc:GetName() .. "."); end
				else
					if (show_debug) then e_other:Message(4,"NPCID: " .. npc:GetNPCTypeID() .. " is invalid, unable to add hate on " .. npc:GetName() .. "."); end
				end
			else
				if (show_debug) then e_other:Message(4,"NPCID: " .. npc:GetNPCTypeID() .. " is excluded, not adding hate on " .. npc:GetName() .. "."); end
			end
		end
	end
end

-- Set function example from Programming In Lua
-- http://www.lua.org/pil/11.5.html
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end
