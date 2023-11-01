sub EVENT_SPELL_FADE {    
    if ($npc && quest::IsCharmSpell($spell_id)) {
        my $name = $npc->GetCleanName();
        quest::debug("I am: $name, and I am a recovering charm pet.");
        plugin::SpawnInPlaceByEnt($npc);
        if ($npc) {
            $npc->Kill();
        }
    }
}