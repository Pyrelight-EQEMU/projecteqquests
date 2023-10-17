sub EVENT_SAY {
    my $characterID = $client->CharacterID();
    my $suffix = "K";

    # Add static data
    plugin::add_zone_entry($characterID, "The Dreadlands (Great Combine Spires [Default])", ["dreadlands", "The Dreadlands (Great Combine Spires [Default])", 9651, 3052, 1048, 489], $suffix);

    # Iksar
    if ($client->GetRace() == 128) {
        plugin::add_zone_entry($characterID, "Cabilis (The Block [Racial])", ["cabeast", "Cabilis (The Block [Racial])", 63, 679, -10, 285], $suffix);
    }

    # Fetch the zone data using our abstracted function
    my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

    if ($text =~ /hail/i) {
        plugin::NPCTell("Hail, traveler. I can transport you to the Great Spires of Kunark, or any other location on that continent that you've become attuned to.");
        $client->Message(257, " ------- Select a Destination ------- ");
        
        foreach my $t (sort keys %{$teleport_zones}) {            
            $client->Message(257, "-> " . quest::saylink($t, 0, $t));
        }
    } elsif (exists($teleport_zones->{$text})) {
        $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
    }
}
