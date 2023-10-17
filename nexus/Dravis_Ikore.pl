sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "O";

  # Static data
  plugin::add_zone_entry($characterID, "Toxxulia Forest (Great Combine Spires [Default])", ["tox", "Toxxulia Forest (Great Combine Spires [Default])", -910,-1522,-38,8], $suffix);
  
  # Erudite
  if ($client->GetRace() == 3) {
      plugin::add_zone_entry($characterID, "Erudin (The Vasty Deep Inn [Racial])", ["erudnext", "Erudin (The Vasty Deep Inn [Racial])", -76, -1098, 67, 176], $suffix);
      plugin::add_zone_entry($characterID, "Paineel (Darkglow Palace [Racial])", ["paineel", "Paineel (Darkglow Palace [Racial])", 768, 1218, -38, 313], $suffix);
  }

  # Fetch the zone data using our abstracted function
  my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

  if ($text =~ /hail/i) {
      if (scalar(keys %{$teleport_zones}) > 0) {
          plugin::NPCTell("Hail, traveler. I am Scion Dravis. I can transport you to the Great Spires of Toxxulia Forest, or any other location on Odus that you've discovered and become attuned to.");
          $client->Message(257, " ------- Select a Destination ------- ");      
          
          foreach my $t (sort keys %{$teleport_zones}) {            
              $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
          }
      } else {
          plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations on Odus yet.");
      }
  } elsif (exists($teleport_zones->{$text})) {
      $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
  }
}