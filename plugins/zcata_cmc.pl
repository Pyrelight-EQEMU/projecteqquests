sub get_cmc {
    my $client  = plugin::val('client');
    return $client->GetBucket("Artificer_CMC") || 0;
}

sub display_cmc {
    my $cmc     = get_cmc();
    plugin::YellowText("You currently have $cmc Concentrated Mana Crystals available.");
}

sub set_cmc {
    my $val     = shift;
    my $client  = plugin::val('client');
    
    $client->SetBucket("Artificer_CMC", $val);
}

sub add_cmc {
    my $val     = shift;
    my $cmc     = get_cmc();
    set_cmc($cmc + $val);

    plugin::YellowText("You have gained $val Concentrated Mana Crystals. You now have " . ($cmc + $val) . " available.");
}

sub spend_cmc {
    my $val = shift;
    my $cmc = get_cmc();    
    set_cmc($cmc - $val);

    plugin::YellowText("You have lost $val Concentrated Mana Crystals. You now have " . ($cmc - $val) . " available.");
}