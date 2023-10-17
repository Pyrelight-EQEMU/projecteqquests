sub EVENT_SAY {

  my $charKey = $client->CharacterID() . "-TL";
  my $MAOcharKey = $client->CharacterID() . "-MAO-Progress";
  my $charTargetsString = quest::get_data($charKey . "-L");
  my %teleport_zones = ();
  
  my @zones = split /:/, $charTargetsString;
  foreach $z (@zones) {      
    my @tokens = split /,/, $z;
    if ($tokens[1] ne '') {
      $teleport_zones{$tokens[1]} = [ @tokens ];
    }
  }

  # Vah Shir
  if ($client->GetRace() == 128) {
    $teleport_zones{"Shar Vahl (The Tavern [Racial])"} = [ "sharvahl", "Shar Vahl (The Tavern [Racial])", -254, -281, -188, 46];
  }
  
  if ($text=~/hail/i) {
    plugin::NPCTell("Hail, traveler. I can coax the network to transport you to other locations upon Luclin that you have become attuned to.");    
    $client->Message(257, " ------- Select a Destination ------- ");      
    foreach my $t (sort keys %teleport_zones) {
      $client->Message(257, "-> ".quest::saylink($teleport_zones{$t}[1],0,$t));
    }
  } elsif (exists($teleport_zones{$text}[1])) {
    $client->MovePC(quest::GetZoneID($teleport_zones{$text}[0]),$teleport_zones{$text}[2],$teleport_zones{$text}[3],$teleport_zones{$text}[4],$teleport_zones{$text}[5]);
  }
}
