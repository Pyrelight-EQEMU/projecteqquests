sub EVENT_SAY {

  my $charKey = $client->CharacterID() . "-TL";
  my $MAOcharKey = $client->CharacterID() . "-MAO-Progress";
  my $charTargetsString = quest::get_data($charKey . "-O");
  my %teleport_zones = ();
  
  my @zones = split /:/, $charTargetsString;
  foreach $z (@zones) {      
    my @tokens = split /,/, $z;
    if ($tokens[1] ne '') {
      $teleport_zones{$tokens[1]} = [ @tokens ];
    }
  }

  $teleport_zones{"Toxxulia Forest (Great Combine Spires [Default])"} = [ "tox", "Toxxulia Forest (Great Combine Spires [Default])", -910,-1522,-38,8 ];

  # Erudite
  if ($client->GetRace() == 3) {
    $teleport_zones{"Erudin (The Vasty Deep Inn [Racial])"} = [ "erudnext", "Erudin (The Vasty Deep Inn [Racial])", -76, -1098, 67, 176];
    $teleport_zones{"Paineel (Darkglow Palace [Racial])"} = [ "paineel", "Paineel (Darkglow Palace [Racial])", 768, 1218, -38, 313];
  }

  if ($text=~/hail/i) {
    plugin::NPCTell("Hail, traveler. I am Scion Dravis. I can transport you to the Great Spires of Toxxulia Forest, or any other location on Odus that you've discovered and become attuned to.");
    $client->Message(257, " ------- Select a Destination ------- ");    
    foreach my $t (sort keys %teleport_zones) {
      $client->Message(257, "-> ".quest::saylink($teleport_zones{$t}[1],0,$t));
    }    
  } elsif (exists($teleport_zones{$text}[1])) {
    $client->MovePC(quest::GetZoneID($teleport_zones{$text}[0]),$teleport_zones{$text}[2],$teleport_zones{$text}[3],$teleport_zones{$text}[4],$teleport_zones{$text}[5]);
  }
}
