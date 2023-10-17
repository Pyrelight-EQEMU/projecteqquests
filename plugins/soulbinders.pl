#!/usr/bin/perl

sub soulbinder_say {
	my $text = shift;
	if($text=~/hail/i){
		quest::say("Greetings ${name} . When a hero of our world is slain their soul returns to the place it was last bound and the body is reincarnated. As a member of the Order of Eternity  it is my duty to [bind your soul] to this location if that is your wish. I can also [attune] you to this place for the purposes of teleportation from The Nexus.");
	} elsif($text=~/bind my soul/i) {
	    quest::say("Binding your soul. You will return here when you die.");
	    quest::selfcast(2049);
	} elsif($text=~/attune/i) {
		my $client     = plugin::val('client');
		my $npc        = plugin::val('npc');

		my $descData = quest::GetZoneLongNameByID($npc->GetZoneID()) . "(${name})"
		my $locData = [quest::GetZoneShortName($npc->GetZoneID()), $client->GetX(), $client->GetY(), $client->GetZ(), $client->GetHeading()];

		quest::debug("$descData + $locData");
	}
}  
