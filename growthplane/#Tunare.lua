-- #Tunare NPCID: 127098
-- This is Tunare out in the middle of the zone
function event_death_complete(e)
	send_signal_to_all_npc_in_zone(2);
end

function event_combat(e)
	if (e.joined) then
		send_signal_to_all_npc_in_zone(1);
	else
		send_signal_to_all_npc_in_zone(2);
	end
end

function send_signal_to_all_npc_in_zone(signal_to_send)
	-- set to true for debugging messages
	local show_debug = false;
	-- create list of NPCID that will be signalled.
	-- only aggro these mobs #Prince Thirneg (127096), keeper of the glades (127016), Undogo Digolo (127015)
	-- #Treah Greenroot (127021), Ail_the_Elder (127020), Rumbleroot (127019), Fayl Everstrong (127018)
	-- Guardian of Tunare (127007), Grahl Strongback (127022), Ordro (127040), Farstride Unicorn (127093)
	-- Galiel Spirithoof (127023), Sarik the Fang (127017)
	local include_npc_list = Set {127096, 127016, 127015, 127007, 127022, 127040, 127093, 127023, 127017};
	-- create empty table to track the NPCID that have had signals sent already
	local signal_sent_to = {};
	-- grab the entity list
	local entity_list = eq.get_entity_list();
	-- get the list of npcs currently spawned in the zone
	local npc_list = entity_list:GetNPCList();
	-- do not do anything if there are no NPC's spawned. should be an impossible check because this is in an NPC script
	if(npc_list ~= nil) then
		for npc in npc_list.entries do
			if (include_npc_list[npc:GetNPCTypeID()] ~= nil and signal_sent_to[npc:GetNPCTypeID()] == nil) then
				-- make sure the npc is valid (again, should never fail, but better to be certain.
				if (npc.valid) then
					if (show_debug) then eq.zone_emote(4,"NPCID: " .. npc:GetNPCTypeID() .. " is being sent signal " .. tostring(signal_to_send) .. "."); end
					-- send signal to this NPCID
					eq.signal(npc:GetNPCTypeID(),signal_to_send);
					-- add this NPCID to the list of NPCID that we have already signalled
					signal_sent_to[npc:GetNPCTypeID()] = true;
				end
			elseif(signal_sent_to[npc:GetNPCTypeID()] == true) then
				if (show_debug) then eq.zone_emote(4,"NPCID: " .. npc:GetNPCTypeID() .. " has already been sent signal " .. tostring(signal_to_send) .. "."); end
			elseif(include_npc_list[npc:GetNPCTypeID()] ~= true) then
				if (show_debug) then eq.zone_emote(4,"NPCID: " .. npc:GetNPCTypeID() .. " is excluded and will not be sent signal " .. tostring(signal_to_send) .. "."); end
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
