sub EVENT_SPELL_EFFECT_NPC {
    my $client = $entity_list->GetClientByID($caster_id);
    if (quest::IsCharmSpell($spell_id) && $entity_list->GetClientByID($caster_id)) {
        my $name = $npc->GetCleanName();
        quest::debug("I am: $name, and this is my life now.");

        my @stat_names = qw(max_hp min_hit max_hit atk mr cr fr pr dr spellscale healscale accuracy avoidance heroic_strikethrough);
        my %npc_stats;
        my $npc_stats_perlevel;

        foreach my $stat (@stat_names) {
            if ($npc->EntityVariableExists($stat)) {
                $npc_stats{$stat} = $npc->GetEntityVariable($stat);
            } else {
                $npc_stats{$stat} = $npc->GetNPCStat($stat);
                $npc->SetEntityVariable($stat, $npc_stats{$stat});
            }
        }

        foreach my $stat (@stat_names) {
            $npc_stats_perlevel{$stat} = ($npc_stats{$stat} / $npc->GetLevel());
        }

        # Rescale Levels
        if ($npc->GetLevel() < ($min_level - 6)) { 
            $npc->SetLevel($client->GetLevel());
            foreach my $stat (@stat_names) {
                # Skip processing for 'spellscale' and 'healscale'
                next if ($stat eq 'spellscale' or $stat eq 'healscale');
                $npc->ModifyNPCStat($stat, $npc->GetNPCStat($stat) + ceil($npc_stats_perlevel{$stat} * $level_diff));
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