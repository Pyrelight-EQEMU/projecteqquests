sub EVENT_SPELL_EFFECT_NPC {
    if (quest::IsCharmSpell($spell_id) && $entity_list->GetClientByID($caster_id)) {
        my $name = $npc->GetCleanName();
        quest::debug("I am: $name, and this is my life now.");
        $npc->ScaleNPC($npc->GetLevel(), 1);
    }
}

sub EVENT_SPELL_FADE {    
    if ($npc && quest::IsCharmSpell($spell_id)) {
        my $name = $npc->GetCleanName();
        my $hp   = $npc->GetHP();
        quest::debug("I am: $name, and I am a recovering charm pet. I have $hp");
        plugin::SpawnInPlaceByEnt($npc);        
    }
}