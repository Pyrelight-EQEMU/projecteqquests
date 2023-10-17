sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "A";

  # Static data
  plugin::add_zone_entry($characterID, "The Northern Plains of Karana (Great Combine Spires)", ["northkarana", 1215, -3690, -9, 0], $suffix);
  
  # Dark Elf
  if ($client->GetRace() == 6) {
      plugin::add_zone_entry($characterID, "Neriak - Foreign Quarter (The Smuggler's Inn)", ["neriaka", -91, 75, 16, 6], $suffix);
  }

  # Barbarian
  if ($client->GetRace() == 2) {
      plugin::add_zone_entry($characterID, "Halas (McDaniel's Smokes and Spirits)", ["halas", -319, 327, 3, 85], $suffix);
  }

  # Humans
  if ($client->GetRace() == 1) {
      plugin::add_zone_entry($characterID, "East Freeport (Freeport Inn)", ["freporte", -652, -49, -38, 388], $suffix);
      plugin::add_zone_entry($characterID, "South Qeynos (Lion's Mane Inn)", ["qeynos", -64, 235, 3, 385], $suffix);
  }

  # Druids & Rangers
  if ($client->GetClass() == 6 or $client->GetClass() == 4) {
      plugin::add_zone_entry($characterID, "Surefall Glade (The Grove)", ["qrg", -230, -170, 2, 377], $suffix);
  }

  # Trolls
  if ($client->GetRace() == 9) {
      plugin::add_zone_entry($characterID, "Grobb (Gunthak's Belch)", ["grobb", -394, 53, 7, 70], $suffix);
  }

  # Ogres
  if ($client->GetRace() == 10) {  # Corrected the race code for Ogres
      plugin::add_zone_entry($characterID, "Oggok (Oggok's Keep)", ["oggok", -245, 10, -8, 173], $suffix);
  }

  # Frogloks
  if ($client->GetRace() == 330) {
      plugin::add_zone_entry($characterID, "Rathe Mountains (Gukta Refugees)", ["rathemtn", 103, -1793, 3, 448], $suffix);
  }

  # Halflings
  if ($client->GetRace() == 11) {
      plugin::add_zone_entry($characterID, "Rivervale (Weary Foot Rest)", ["rivervale", -93, 187, 2, 128], $suffix);
  }

  # Fetch the zone data using our abstracted function
  my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

  if ($text =~ /hail/i) {
      if (scalar(keys %{$teleport_zones}) > 0) {
          plugin::NPCTell("Hail, traveler. I can transport you to various locations that you've become attuned to.");
          $client->Message(257, " ------- Select a Destination ------- ");      
          
          foreach my $t (sort keys %{$teleport_zones}) {            
              $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
          }
      } else {
          plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations yet.");
      }
  } elsif (exists($teleport_zones->{$text})) {
      $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
  }
}