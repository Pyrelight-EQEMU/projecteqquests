sub EVENT_SAY {
    my $suffix = "K";
    my $accountID   = $client->AccountID();
    my $characterID = $client->CharacterID();   

    plugin::fix_zone_data($characterID, $suffix);
    plugin::add_char_zone_data_to_account($characterID, $accountID, $suffix);
    plugin::add_zone_entry($accountID, "The Dreadlands (Great Combine Spires)", ["dreadlands", 9651, 3052, 1048, 489], $suffix);

    # Fetch the zone data using our abstracted function
    my $teleport_zones = plugin::get_zone_data_for_account($accountID, $suffix);

    # Iksar
    if ($client->GetRace() == 128) {
        $teleport_zones->{"Cabilis (The Block)"} = ["cabeast", 63, 679, -10, 285];
    }

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