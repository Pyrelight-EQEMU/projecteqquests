sub EVENT_SCALE_CALC {    
    quest::debug("Scaling AdvSoul");

    my $attunements = plugin::get_total_attunements($client);

    $questitem->SetScale($client, $attunements/5);
}