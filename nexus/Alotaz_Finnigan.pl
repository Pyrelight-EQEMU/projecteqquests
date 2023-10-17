sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "K";

  # Fix old style data
  # Call the deserialize_zone_data function to parse the serialized data
  my $serialized_data = ":dreadlands,The Dreadlands (Near Karnor's Castle),-1870,600,24.0625,120:frontiermtns,Frontier Mountains (Giant Fort),-1620,35,-128.140045166016,180";
  my $data_hash = plugin::deserialize_zone_data($serialized_data);

  # Access the 1st and 2nd elements of each sub-element within the hash
  foreach my $key (keys %$data_hash) {
      my $first_element = $data_hash->{$key}[0];
      my $second_element = $data_hash->{$key}[1];

      quest::debug(quest::GetZoneLongName($first_element));
      quest::debug(quest::GetZoneLongName($second_element));
  }

  # Add static data
  plugin::add_zone_entry($characterID, "The Dreadlands (Great Combine Spires)", ["dreadlands", 9651, 3052, 1048, 489], $suffix);

  # Iksar
  if ($client->GetRace() == 128) {
      plugin::add_zone_entry($characterID, "Cabilis (The Block)", ["cabeast", 63, 679, -10, 285], $suffix);
  }

  # Fetch the zone data using our abstracted function
  my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

  if ($text =~ /hail/i) {
      if (scalar(keys %{$teleport_zones}) > 0) {
          plugin::NPCTell("Hail, traveler. I can transport you to the Great Spires of Kunark, or any other location on that continent that you've become attuned to.");
          $client->Message(257, " ------- Select a Destination ------- ");
          
          foreach my $t (sort keys %{$teleport_zones}) {            
              $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
          }
      } else {
          plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations on Kunark yet.");
      }
  } elsif (exists($teleport_zones->{$text})) {
      $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
  }
}