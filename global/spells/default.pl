sub EVENT_SPELL_EFFECT_NPC {
    if (quest::IsCharmSpell($spell_id) && $entity_list->GetClientByID($caster_id)) {
        my $name = $npc->GetCleanName();
        quest::debug("I am: $name, and this is my life now.");

        my @stat_names = qw(max_hp min_hit max_hit atk mr cr fr pr dr spellscale healscale accuracy avoidance heroic_strikethrough);

        foreach my $stat (@stat_names) {
            if ($npc->EntityVariableExists($stat)) {
                $npc->ModifyNPCStat($stat, $npc->GetEntityVariable($stat));
            }
        }
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