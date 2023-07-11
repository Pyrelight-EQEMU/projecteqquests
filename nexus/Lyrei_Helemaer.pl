, sub EVENT_SAY {

  my $charKey = $client->CharacterID() . "-TL";
  my $MAOcharKey = $client->CharacterID() . "-MAO-Progress";
  my $charTargetsString = quest::get_data($charKey . "-F");
  my %teleport_zones = ();
  
  my @zones = split /:/, $charTargetsString;
  foreach $z (@zones) {      
    my @tokens = split /,/, $z;
    if ($tokens[1] ne '') {
      $teleport_zones{$tokens[1]} = [ @tokens ];
    }
  }

  $teleport_zones{"The Greater Faydark (Great Combine Spires [Default])"} = [ "gfaydark", "The Greater Faydark (Great Combine Spires [Default])", -440, -2020, 0, 0 ];

  # High Elf
  if ($client->GetRace() == 5) {
    $teleport_zones{"Northern Felwithe (Traveler's Home [Racial])"} = [ "felwithea", "Northern Felwithe (Traveler's Home [Racial])", -370, 214. 3, 259];
  }

  # Wood Elf
  if ($client->GetRace() == 3) {
    $teleport_zones{"Kelethin (Sleepy Willow Inn [Racial])"} = [ "gfaydark", "Kelethin (Sleepy Willow Inn [Racial])", 489, 730, 76, 422];
  }

  # Dwarf
  if ($client->GetRace() == 8) {
    $teleport_zones{"Kaladim (Pub Kal [Racial])"} = [ "kaladima", "Kaladim (Pub Kal [Racial])", 214, 76, 3, 52];
  }

  # Gnome
  if ($client->GetRace() == 12) {
    $teleport_zones{"Ak`Anon (The Market [Racial])"} = [ "akanon", "Ak`Anon (The Market [Racial])", -912, 1304, -28, 215];
  }
  

  if ($text=~/hail/i) {
    plugin::NPCTell("Hail, traveler. I am Scion Lyrei Helemaer, and I can transport you to the Great Spires of Faydwer, as well as any other locations on Faydwer that you've become attuned to.");    
    $client->Message(257, " ------- Select a Destination ------- ");      
    foreach my $t (sort keys %teleport_zones) {
      $client->Message(257, "-> ".quest::saylink($teleport_zones{$t}[1],0,$t));
    }        
  } elsif (exists($teleport_zones{$text}[1])) {
    $client->MovePC(quest::GetZoneID($teleport_zones{$text}[0]),$teleport_zones{$text}[2],$teleport_zones{$text}[3],$teleport_zones{$text}[4],$teleport_zones{$text}[5]);
  }
}
