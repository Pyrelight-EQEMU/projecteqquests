sub EVENT_SCALE_CALC {    
    quest::debug("Scaling AdvSoul");

    my $attunements = plugin::get_total_attunements();

    $questitem->SetScale($client, $attunements/5);
}