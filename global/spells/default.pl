sub EVENT_SPELL_EFFECT_NPC {
    my $client = $entity_list->GetClientByID($caster_id);
    if (quest::IsCharmSpell($spell_id) && $client) {
        my $name = $npc->GetCleanName();
        quest::debug("I am: $name, and this is my life now. - SCALED");
        $npc->ScaleNPC($client->GetLevel());
    }
}

sub EVENT_SPELL_FADE {    
    if ($npc && quest::IsCharmSpell($spell_id)) {
        my $name = $npc->GetCleanName();
        my $hp   = $npc->GetHP();
        quest::debug("I am: $name, and I am a recovering charm pet. I have $hp left");
        if ($hp > 0) {
            plugin::SpawnInPlaceByEnt($npc);
        }      
    }
}