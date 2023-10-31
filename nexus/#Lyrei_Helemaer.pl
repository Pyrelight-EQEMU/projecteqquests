sub EVENT_SAY {
    my $suffix = "F";
    my $accountID   = $client->AccountID();
    my $characterID = $client->CharacterID();   

    plugin::fix_zone_data($characterID, $suffix);
    plugin::add_char_zone_data_to_account($accountID, $accountID, $suffix);
    plugin::add_zone_entry($accountID, "The Greater Faydark (Great Combine Spires)", ["gfaydark", -440, -2020, 0, 0 ], $suffix);

    # Fetch the zone data using our abstracted function
    my $accountID   = $client->AccountID();
    my $teleport_zones = plugin::get_zone_data_for_account($accountID, $suffix);



    # High Elf
    if ($client->GetRace() == 5) {
        $teleport_zones->{"Northern Felwithe (Traveler's Home)"} = ["felwithea", -370, 214, 3, 259];
    }

    # Wood Elf
    if ($client->GetRace() == 4) {
        $teleport_zones->{"Kelethin (Sleepy Willow Inn)"} = ["gfaydark", 489, 730, 76, 422];
    }

    # Dwarf
    if ($client->GetRace() == 8) {
        $teleport_zones->{"Kaladim (Pub Kal)"} = ["kaladima", 214, 76, 3, 52];
    }

    # Gnome
    if ($client->GetRace() == 12) {
        $teleport_zones->{"Ak`Anon (The Market)"} = ["akanon", -912, 1304, -28, 215];
    }

    if ($text =~ /hail/i) {
        if (scalar(keys %{$teleport_zones}) > 0) {
            plugin::NPCTell("Hail, traveler. I am Scion Lyrei Helemaer, and I can transport you to the Great Spires of Faydwer, as well as any other locations on Faydwer that you've become attuned to.");
            $client->Message(257, " ------- Select a Destination ------- ");      
            
            foreach my $t (sort keys %{$teleport_zones}) {            
                $client->Message(257, "-[" . quest::saylink($t, 1, 'ZONE') . "]- $t");
            }
        } else {
            plugin::NPCTell("Hail, traveler. Unfortunately, you haven't been attuned to any locations on Faydwer yet.");
        }
    } elsif (exists($teleport_zones->{$text})) {
        $client->MovePC(quest::GetZoneID($teleport_zones->{$text}[0]), $teleport_zones->{$text}[1], $teleport_zones->{$text}[2], $teleport_zones->{$text}[3], $teleport_zones->{$text}[4]);
    }
}
