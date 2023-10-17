sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "V";

  # Static data
  plugin::add_zone_entry($characterID, "The Great Divide (Great Combine Spires)", ["greatdivide", -2700, -1860, -44, 253], $suffix);

  # Fetch the zone data using our abstracted function
  my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

  if ($text =~ /hail/i) {
      if (scalar(keys %{$teleport_zones}) > 0) {
          plugin::NPCTell("Hail, traveler. I can transport you to the Great Spires of Velious, or any other location on that frozen wasteland that you've previously visited.");
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