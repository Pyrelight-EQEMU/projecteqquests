sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "A";

  # Static data
  plugin::add_zone_entry($characterID, "The Northern Plains of Karana (Great Combine Spires)", ["northkarana", 1215, -3690, -9, 0], $suffix);
  
  # Fetch the zone data using our abstracted function
  my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);
  
  # Dark Elf
  if ($client->GetRace() == 6) {
      $teleport_zones{"Neriak - Foreign Quarter (The Smuggler's Inn)"} = ["neriaka", -91, 75, 16, 6];
  }

  # Barbarian
  if ($client->GetRace() == 2) {
      $teleport_zones{"Halas (McDaniel's Smokes and Spirits)"} = ["halas", -319, 327, 3, 85];
  }

  # Humans
  if ($client->GetRace() == 1) {
      $teleport_zones{"East Freeport (Freeport Inn)"} = ["freporte", -652, -49, -38, 388];
      $teleport_zones{"South Qeynos (Lion's Mane Inn)"} = ["qeynos", -64, 235, 3, 385];
  }

  # Druids & Rangers
  if ($client->GetClass() == 6 or $client->GetClass() == 4) {
      $teleport_zones{"Surefall Glade (The Grove)"} = ["qrg", -230, -170, 2, 377];
  }

  # Trolls
  if ($client->GetRace() == 9) {
      $teleport_zones{"Grobb (Gunthak's Belch)"} = ["grobb", -394, 53, 7, 70];
  }

  # Ogres
  if ($client->GetRace() == 10) {  # Corrected the race code for Ogres
      $teleport_zones{"Oggok (Oggok's Keep)"} = ["oggok", -245, 10, -8, 173];
  }

  # Frogloks
  if ($client->GetRace() == 330) {
      $teleport_zones{"Rathe Mountains (Gukta Refugees)"} = ["rathemtn", 103, -1793, 3, 448];
  }

  # Halflings
  if ($client->GetRace() == 11) {
      $teleport_zones{"Rivervale (Weary Foot Rest)"} = ["rivervale", -93, 187, 2, 128];
  }

  if ($text =~ /hail/i) {
      if (scalar(keys %{$teleport_zones}) > 0) {
          plugin::NPCTell("Hail, traveler. I can transport you to various locations that you've become attuned to.");
          $client->Message(257, " ------- Select a Destination ------- ");      
          
          foreach my $t (sort keys %{$teleport_zones}) {            
              $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
          }
      } else {
          plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations on Antonica yet.");
      }
  } elsif (exists($teleport_zones->{$text})) {
      $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
  }
}