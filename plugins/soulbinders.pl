#!/usr/bin/perl

sub soulbinder_say {
	my $text = shift;
	my $client     = plugin::val('client');
	my $clientname = $client->GetCleanName();
	if($text=~/hail/i){
		quest::say("Greetings $clientname. When a hero of our world is slain their soul returns to the place it was last bound and the body is reincarnated. As a member of the Order of Eternity  it is my duty to [bind your soul] to this location if that is your wish. I can also [attune] you to this place for the purposes of teleportation from The Nexus.");
	} elsif($text=~/bind my soul/i) {
	    quest::say("Binding your soul. You will return here when you die.");
	    quest::selfcast(2049);
	} elsif($text=~/attune/i) {
		my $client     = plugin::val('client');
		my $npc        = plugin::val('npc');
		my $npcName    = $npc->GetCleanName();

		my $descData = quest::GetZoneLongNameByID($npc->GetZoneID()) . " ($npcName)";
		my $locData = [quest::GetZoneShortName($npc->GetZoneID()), $client->GetX(), $client->GetY(), $client->GetZ(), $client->GetHeading()];
		my $suffix = get_continent_fix(quest::GetZoneShortName($npc->GetZoneID()));


		quest::message(15, "You feel a tug on your soul. Your have become attuned to this location.");
		plugin::add_zone_entry($client->CharacterID(), $descData, $locData, $suffix);
		quest::say("I have attuned you. You may now teleport here from the nexus.");
	}
}  
