sub EVENT_SPELL_EFFECT_CLIENT {
    quest::debug("started warrior class change");
    
    my $mclass = $client->GetClass();

    if ($mclass==1) {
        $client->BuffFadeAll();
        quest::permaclass(1);
    } else {
        $client->Message(13, "Ability Failed. You are already a Warrior.");
    }

    quest::debug("Completed warrior class change");
}