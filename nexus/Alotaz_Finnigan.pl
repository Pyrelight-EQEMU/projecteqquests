sub EVENT_SAY {
  my $characterID = $client->CharacterID();
  my $suffix = "K";

  # Fix old style data
  # Deserialize the data  
  my $charKey = $characterID . "-TL-" . $suffix;
  my $charDataString = quest::get_data($charKey);
  my $data_hash = plugin::deserialize_zone_data($charDataString);

  # Modify the data (for example, let's add "_modified" to the end of each first element)
  foreach my $key (keys %$data_hash) {
      if (quest::GetZoneLongName($key) ne "UNKNOWN") {
          my $zone_sn = $key;
          my $zone_desc = $data_hash->{$key}[0];  # Access the elements using ->

          # Create a new entry in the hash with the zone_desc as the key
          $data_hash->{$zone_desc} = [$key, @{$data_hash->{$key}}[1..4]];

          # Delete the original key from the hash
          delete $data_hash->{$key};
      }
  }

# Serialize the modified data with the key and the first element reversed
my $new_serialized_data = plugin::serialize_zone_data($data_hash);

  quest::debug($new_serialized_data);  # Output the reserialized data

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