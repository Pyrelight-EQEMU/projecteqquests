function event_say(e)
	if(e.message:findi("falchion")) then
		e.self:Say("Koada'Dal Falchions are highly enchanted weapons crafted in our unique forges. The technique of folding the mithril produces as you might imagine an exceptionally light and strong blade when quenched in morning dew. An emerald blessed and imbued by a priest of Tunare lends enchantments to strengthen the wielder. To do this, I will need your Falchion of the Koada'Vie, two skins of Morning Dew and an Imbued Emerald.");
	elseif(e.message:findi("hail")) then --General Jyleel's dialogue has been altered to instruct the player to find Opal Leganyn to further consecrate their (mostly ceremonial) falchion
		e.self:Say("Hail, " .. e.other:GetName() .. ". Are you here to inquire about consecration of your ceremonial falchion?");
	end
end
function event_trade(e)
	local item_lib = require("items");
--the Falchion to turn in is awarded by General Jyleel for a quest that is doable around level 20, though on P99 they might be dropped by two guards in Firiona Via in Kunark, the Morning Dew can be Foraged and Imbued Emeralds are summoned by clerics of Tunare
	if(item_lib.check_turn_in(e.trade, {item1 = 5379,item2 = 16594,item3 = 16594,item4 = 22507})) then --Falchion of the Koada'Vie, Morning Dew, Morning Dew, Imbued Emerald
		e.self:Say("Very well! Here, then, is your falchion, consecrated and newly born of the Mother, that it may defend all which is good and right in the world.");
		e.other:SummonItem(21548); -- Koada`Dal Falchion of Tunare, it's a tradeskill product introduced somewhere along the way and forgotten due to obsolescence, this reward is an improvement over the original falchion but probably not worth near the cost of the components, need to create a suitable reward later
		e.other:Ding();
		e.other:Faction(226,4,0);  --Clerics of Tunare
		e.other:Faction(279,4,0);  --King Tearis Thex
		e.other:Faction(5001,2,0); --Anti-mage
		e.other:AddEXP(3250);
	end
	item_lib.return_items(e.self, e.other, e.trade);
end
-- END of FILE Zone:felwithea  ID:61048 -- Opal_Leganyn
