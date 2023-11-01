sub CHECK_CHARM_STATUS
{
    if ($npc->Charmed() and not plugin::REV($npc, "is_charmed")) {     
        my @lootlist = $npc->GetLootList();
        my @inventory;
        foreach my $item_id (@lootlist) {
            my $quantity = $npc->CountItem($item_id);
            push @inventory, "$item_id:$quantity";
        }

        my $data = @inventory ? join(",", @inventory) : "EMPTY";
        plugin::SEV($npc, "is_charmed", $data);

    } elsif (not $npc->Charmed() and plugin::REV($npc, "is_charmed")) {        
        plugin::SpawnInPlaceByEnt($npc);
    }
}

sub EVENT_SPELL_FADE {
	# Spell-EVENT_SPELL_FADE
	# Exported event variables

    my $name = $npc->GetCleanName();

    if (quest::IsCharmSpell($spell_id)) {
        quest::Debug("I am: $name, and I am a recovering charm pet.");
    }
}