#generic soulbinder quest
sub EVENT_SAY {
	if($text=~/hail/i or $text=~/bind my soul/i or $text=~/attune/i){
		plugin::soulbinder_say($text);
	} elsif ($client->GetGlobal("druid_epic") == 3) {
		if ($text=~/identify this mangled head/i) {
			quest::say("We soulbinders do not deal in such foul magic, we purged that [one] from our ranks long ago.");
		}
		if ($text=~/one/i) {
			quest::say("I will not talk about him and I assure you that none of our membership will. If you must know more, talk to a man named Caskin about his friend. I don't remember his last name. Now please go away and don't mention this again.");
		}
	}
}