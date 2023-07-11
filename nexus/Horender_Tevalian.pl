sub EVENT_SAY {

  my $charKey = $client->CharacterID() . "-TL";
  my $MAOcharKey = $client->CharacterID() . "-MAO-Progress";
  my $charTargetsString = quest::get_data($charKey . "-A");
  my %teleport_zones = ();
  
  my @zones = split /:/, $charTargetsString;
  foreach $z (@zones) {      
    my @tokens = split /,/, $z;
    if ($tokens[1] ne '') {
      $teleport_zones{$tokens[1]} = [ @tokens ];
    }
  }

  $teleport_zones{"The Northern Plains of Karana (Great Combine Spires [Default])"} = ["northkarana", "The Northern Plains of Karana (Great Combine Spires [Default])", 1215, -3690, -9, 0];

  # Dark Elf
  if ($client->GetRace() == 6) {
    $teleport_zones{"Neriak - Foreign Quarter (The Smuggler's Inn [Racial])"} = ["neriaka", "Neriak - Foreign Quarter (The Smuggler's Inn [Racial])", -91, 75, 16, 6];
  }

  # Barbarian
  if ($client->GetRace() == 2) {
    $teleport_zones{"Halas (McDaniel's Smokes and Spirits [Racial])"} = ["halas", "Halas (McDaniel's Smokes and Spirits [Racial])", -319, 327, 3, 85];
  }

  # Humans
  if ($client->GetRace() == 1) {
    $teleport_zones{"East Freeport (Freeport Inn [Racial])"} = ["freporte", "East Freeport (Freeport Inn [Racial])", -652, -49, -38, 388];
  }

  if ($client->GetRace() == 1 or $client->GetRace() == 330) {
    $teleport_zones{"South Qeynos (Lion's Mane Inn [Racial])"} = ["qeynos", "South Qeynos (Lion's Mane Inn [Racial])", -64, 235, 3, 385];
  }

  # Druids & Rangers
  if ($client->GetClass() == 6 or $client->GetClass() == 4) {
    $teleport_zones{"Surefall Glade (The Grove [Class])"} = ["qrg", "Surefall Glade (The Grove [Class])", -230, -170, 2, 377];
  }

  # Trolls
  if ($client->GetRace() == 9) {
    $teleport_zones{"Grobb (Gunthak's Belch [Racial])"} = ["grobb", "Grobb (Gunthak's Belch [Racial])", -394, 53, 7, 70];
  }

  # Ogres
  if ($client->GetRace() == 9) {
    $teleport_zones{"Oggok (Oggok's Keep [Racial])"} = ["oggok", "Oggok (Oggok's Keep [Racial])", -245, 10, -8, 173];
  }

  # Frogloks
  if ($client->GetRace() == 330) {
    $teleport_zones{"Rathe Mountains (Gukta Refugees [Racial])"} = ["rathemtn", "Rathe Mountains (Gukta Refugees [Racial])", 103, -1793, 3, 448];
  }

  # Halflings
  if ($client->GetRace() == 11) {
    $teleport_zones{"Rivervale (Weary Foot Rest [Racial])"} = ["rivervale", "Rivervale (Weary Foot Rest [Racial])", -93, 187, 2, 128];
  }


  if ($text=~/hail/i) {
    plugin::NPCTell("Hail, traveler. I can transport you to the Great Spires on Antonica, or to any other location on the continent that you've become attuned to.");
    $client->Message(257, " ------- Select a Destination ------- ");
    foreach my $t (sort keys %teleport_zones) {
      $client->Message(257, "-> ".quest::saylink($teleport_zones{$t}[1],0,$t));
    }
  } elsif (exists($teleport_zones{$text}[1])) {
    $client->MovePC(quest::GetZoneID($teleport_zones{$text}[0]),$teleport_zones{$text}[2],$teleport_zones{$text}[3],$teleport_zones{$text}[4],$teleport_zones{$text}[5]);
  }
}
