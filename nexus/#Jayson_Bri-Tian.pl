sub EVENT_SAY {
    my $suffix = "L"; 
    my $accountID   = $client->AccountID();
    my $characterID = $client->CharacterID();   

    plugin::fix_zone_data($characterID, $suffix);
    plugin::add_char_zone_data_to_account($characterID, $accountID, $suffix);
    
    my $teleport_zones = plugin::get_zone_data_for_account($accountID, $suffix);

    if ($client->GetRace() == 128) {
        $teleport_zones->{"Shar Vahl (The Tavern)"} = ["sharvahl", -254, -281, -188, 46];
    }

    if ($text =~ /hail/i) {
        if (scalar(keys %{$teleport_zones}) > 0) {
            plugin::NPCTell("Hail, traveler. I can coax the network to transport you to other locations upon Luclin that you have become attuned to.");
            $client->Message(257, " ------- Select a Destination ------- ");
            
            foreach my $t (sort keys %{$teleport_zones}) {            
                $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
            }
        } else {
            plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations on Luclin yet.");
        }
    } elsif (exists($teleport_zones->{$text})) {
        $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
    }
}