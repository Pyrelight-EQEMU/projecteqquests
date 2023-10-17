sub EVENT_SCALE_CALC {
    my $attunements = plugin::get_total_attunements($client);    
    quest::debug("Scaling AdvSoul: $attunements");

    $questitem->SetScale($attunements/5);
}