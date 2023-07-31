use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

my $dz_duration     = 604800; # 7 Days
my $modifier        = 1.25;

sub EVENT_TICK 
{
    CHECK_CHARM_STATUS();
    if ($npc->IsPet() and $npc->GetOwner()->IsClient()) { 
        UPDATE_PET($npc);
    }
}

sub EVENT_SPAWN {
    #Pet Scaling
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->Charmed()) {
        SAVE_PET_STATS(); 
        UPDATE_PET();
        $npc->Heal();
    }

    # Check for FoS Instance
    if ($instanceversion == 10) {
        EVENT_FOS_SPAWN();        
    }
}

sub EVENT_KILLED_MERIT {
    # Check for FoS Instance
    if ($instanceversion == 10) {
        EVENT_FOS_KILL();
    }  

    #Potions
    if ($client && $client->GetLevelCon($npc->GetLevel()) != 6 && rand() <= 0.20) {
        my $dbh = plugin::LoadMysql();

        my $potion = "Distillate of " . plugin::GetPotName() . " " . plugin::GetRoman($client->GetLevel());
        my $query = $dbh->prepare("SELECT id FROM items WHERE name LIKE '$potion';");
        $query->execute();
        my ($potion_id) = $query->fetchrow_array();

        if ($potion_id) {
            $npc->AddItem($potion_id);
        } else {
            quest::debug("Invalid Potion Query: $query");
        }

        $dbh->disconnect();
    } elsif ($client && $client->GetLevelCon($npc->GetLevel()) != 6 && rand() <= 0.01 && !($client->GetBucket("ExpPotionDrop"))) {
        $npc->AddItem(40605); # Exp Pot
        $client->SetBucket("ExpPotionDrop", 1, 24 * 60 * 60);
    }
}

sub EVENT_DAMAGE_GIVEN 
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->IsTaunting()) {
        $entity_list->GetMobByID($entity_id)->AddToHateList($npc->GetOwner());
    }        
}

sub EVENT_COMBAT 
{
    CHECK_CHARM_STATUS();
    if ($combat_state == 0 && $npc->GetCleanName() =~ /^The Fabled/) {
        quest::respawn($npc->GetNPCTypeID(), $npc->GetGrid());
    }
}

sub EVENT_DEATH_COMPLETE
{
    CHECK_CHARM_STATUS();
}

sub EVENT_FOS_SPAWN
{
    # Get the packed data for the instance
    my %info_bucket = plugin::DeserializeHash(quest::get_data("instance-$zonesn-$instanceid"));
    my @targetlist  = plugin::DeserializeList($info_bucket{'targets'});
    my $group_mode  = $info_bucket{'group_mode'};
    my $difficulty  = $info_bucket{'difficulty'} + ($group_mode ? 5 : 0) - 1;
    my $reward      = $info_bucket{'reward'};    
    my $min_level   = $info_bucket{'min_level'} + min(floor($difficulty / 5), 10);

    # Get initial mob stat values
    my @stat_names = qw(max_hp min_hit max_hit atk mr cr fr pr dr spellscale healscale accuracy avoidance heroic_strikethrough);  # Add more stat names here if needed
    my %npc_stats;
    my $npc_stats_perlevel;

    # Cull over-populated instances
    if ($zonesn = 'vexthal' and not any { $_ == $npc->GetID() } @targetlist) {
         if (rand() < 0.33) {
            $npc->Kill();
         }
    }

    foreach my $stat (@stat_names) {
        $npc_stats{$stat} = $npc->GetNPCStat($stat);
    }

    $npc_stats{'spellscale'} = 100 * ($difficulty * $modifier);
    $npc_stats{'healscale'}  = 100 + ($difficulty * $modifier);

    foreach my $stat (@stat_names) {
        $npc_stats_perlevel{$stat} = ($npc_stats{$stat} / $npc->GetLevel());
    }

    #Rescale Levels
    if ($npc->GetLevel() < ($min_level - 6)) {
        my $level_diff = $min_level - 6 - $npc->GetLevel();

        $npc->SetLevel($npc->GetLevel() + $level_diff);
        foreach my $stat (@stat_names) {
            $npc->ModifyNPCStat($stat, $npc->GetNPCStat($stat) + ceil($npc_stats_perlevel{$stat} * $level_diff));
        }        
    }

    #Recale stats
    if ($difficulty > 0) {
        foreach my $stat (@stat_names) {
            $npc->ModifyNPCStat($stat, ceil($npc->GetNPCStat($stat) * $difficulty * $modifier));
        }
    }

    $npc->Heal();
}

sub EVENT_FOS_KILL
{
    # Get the packed data for the instance
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("instance-$zonesn-$instanceid"));
    my @targetlist   = plugin::DeserializeList($info_bucket{'targets'});
    my $group_mode   = $info_bucket{'group_mode'};
    my $difficulty   = $info_bucket{'difficulty'} - 1;
    my $reward       = $info_bucket{'reward'};    
    my $min_level    = $info_bucket{'min_level'} + min(floor($difficulty / 5), 10);

    if ($reward > 0) {
        my $npc_name = $npc->GetCleanName();
        my $removed = 0;
        @targetlist = grep { 
            if ($_ == $npc->GetNPCTypeID() && !$removed) { 
                $removed = 1; 
                0;
            } else { 
                1;
            } 
        } @targetlist;

        if ($removed) {
            #repack the info bucket
            $info_bucket{'targets'} = plugin::SerializeList(@targetlist);
            quest::set_data("instance-$zonesn-$instanceid", plugin::SerializeHash(%info_bucket), $client->GetExpedition->GetSecondsRemaining());
            
            my $remaining_targets = scalar @targetlist;
            if ($remaining_targets) {                
                plugin::YellowText("You've slain $npc_name! Your Feat of Strength is closer to completion. There are $remaining_targets targets left.");
            } else {
                my $FoS_points = $client->GetBucket("FoS-points") + $info_bucket{'reward'};
                my $itm_link = quest::itemlink(40903);
                $client->SetBucket("FoS-points",$FoS_points);
                $client->SetBucket("FoS-$zonesn", $difficulty);
                plugin::YellowText("You've slain $npc_name! Your Feat of Strength has been completed! You have earned $reward [$itm_link]. You may leave the expedition to be ejected from the zone after a short time.");
                $client->AddCrystals($reward, 0);
                my $itm_link = quest::itemlink(40903);
                plugin::WorldAnnounce($client->GetCleanName() . " (Level ". $client->GetLevel() . " ". $client->GetClassName() . ") has completed the Feat of Strength: $zoneln (Difficulty: $difficulty).");
            }
            quest::debug("Updated Targets: " . join(", ", @targetlist));
        }
    }
}

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
        
        my $data = plugin::REV($npc, "is_charmed");
        my @inventory = split(",", $data);

        my @lootlist = $npc->GetLootList();
        while (@lootlist) { # While lootlist has elements
            foreach my $item_id (@lootlist) {
                $npc->RemoveItem($item_id);
            }
            @lootlist = $npc->GetLootList(); # Update the lootlist after removing items
        }

        foreach my $item (@inventory) {
            my ($item_id, $quantity) = split(":", $item);
            quest::debug("Adding: $item_id x $quantity");
            $npc->AddItem($item_id, $quantity);
        }

        plugin::SEV($npc, "is_charmed", "");
    }
}

sub UPDATE_PET {
    #quest::debug("--Syncronizing Pet Inventory--");
    my $owner = $npc->GetOwner()->CastToClient();
    my $bag_size = 200; # actual bag size limit in source
    my $bag_id = 199999; # Custom Item
    my $bag_slot = 0;

    if (not $npc->Charmed()) {
        UPDATE_PET_STATS();
    }

    if ($owner) {       
        my %new_pet_inventory;
        my %new_bag_inventory;
        my $updated = 0;

        my $inventory = $owner->GetInventory();
        #Determine if first instance of pet bag is in inventory or bank
        for (my $iter = quest::getinventoryslotid("general.begin"); $iter <= quest::getinventoryslotid("bank.end"); $iter++) {
            if ((($iter >= quest::getinventoryslotid("general.begin") && $iter <= quest::getinventoryslotid("general.end")) ||
                ($iter >= quest::getinventoryslotid("bank.begin") && $iter <= quest::getinventoryslotid("bank.end")))) {
                
                if ($owner->GetItemIDAt($iter) == $bag_id) {
                        $bag_slot = $iter;
                }
            }
        }
        # Determine contents
        if ($bag_slot >= quest::getinventoryslotid("general.begin") && $bag_slot <= quest::getinventoryslotid("general.end")) {
            %new_bag_inventory = GET_BAG_CONTENTS(\%new_bag_inventory, $owner, $bag_slot, quest::getinventoryslotid("general.begin"), quest::getinventoryslotid("generalbags.begin"), $bag_size);
        } elsif ($bag_slot >= quest::getinventoryslotid("bank.begin") && $bag_slot <= quest::getinventoryslotid("bank.end")) {
            %new_bag_inventory = GET_BAG_CONTENTS(\%new_bag_inventory, $owner, $bag_slot, quest::getinventoryslotid("bank.begin"), quest::getinventoryslotid("bankbags.begin"), $bag_size);
        } else {
            return;
        }

        my @lootlist = $npc->GetLootList();
        foreach my $item_id (@lootlist) {
            my $quantity = $npc->CountItem($item_id);
            $new_pet_inventory{$item_id} += $quantity;
        }

        $updated = 0; # initially set it to false
        foreach my $item_id (keys %new_pet_inventory) {
            # if the key doesn't exist in new_bag_inventory or the values don't match
            if (!exists $new_bag_inventory{$item_id} || $new_pet_inventory{$item_id} != $new_bag_inventory{$item_id}) {
                $updated = 1; # set updated to true
                last; # exit the loop as we have found a difference
            }
        }

        # if $updated is still false, it could be because new_bag_inventory has more items, check for that
        if (!$updated) {
            foreach my $item_id (keys %new_bag_inventory) {
                # if the key doesn't exist in new_pet_inventory
                if (!exists $new_pet_inventory{$item_id}) {                    
                    $updated = 1; # set updated to true
                    last; # exit the loop as we have found a difference
                }
            }
        }

        if ($updated) {
            #quest::debug("--Pet Inventory Reset Triggered--");
            my @lootlist = $npc->GetLootList();
            while (@lootlist) { # While lootlist has elements
                foreach my $item_id (@lootlist) {
                    $npc->RemoveItem($item_id);
                }
                @lootlist = $npc->GetLootList(); # Update the lootlist after removing items
            }   

            while (grep { $_->{quantity} > 0 } values %new_bag_inventory) { # While new_bag_inventory still has non-zero elements
                foreach my $item_id (keys %new_bag_inventory) {
                    if ($new_bag_inventory{$item_id}->{quantity} > 0) {
                        $npc->AddItem($item_id, 1, 1, @{$new_bag_inventory{$item_id}->{augments}});
                        $new_bag_inventory{$item_id}->{quantity}--;
                    }
                }
            }
        }
    } else {
        quest::debug("The owner is not defined");
        return;
    }
}

sub GET_BAG_CONTENTS {
    my %blacklist = map { $_ => 1 } (5532, 10099, 20488, 14383, 20490, 10651, 20544, 28034, 10650, 8495);
    my ($new_bag_inventory_ref, $owner, $bag_slot, $ref_general, $ref_bags, $bag_size) = @_;
    my %new_bag_inventory = %{$new_bag_inventory_ref};

    my $rel_bag_slot = $bag_slot - $ref_general;
    my $bag_start = $ref_bags + ($rel_bag_slot * $bag_size);
    my $bag_end = $bag_start + $bag_size;

    for (my $iter = $bag_start; $iter < $bag_end; $iter++) {                
        my $item_slot = $iter - $bag_start;
        my $item_id   = $owner->GetItemIDAt($iter);

        if ($item_id > 0 && $owner->GetItemStat($item_id, "slots") && $owner->GetItemStat($item_id, "classes") && $owner->GetItemStat($item_id, "itemtype") != 54 && !exists($blacklist{$item_id})) {
            my @augments;
            for (my $aug_iter = 0; $aug_iter < 6; $aug_iter++) {
                if ($owner->GetAugmentAt($iter, $aug_iter)) {
                    push @augments, $owner->GetAugmentIDAt($iter, $aug_iter);
                } else {
                    push @augments, 0;
                }
            }
            $new_bag_inventory{$item_id} = { quantity => 1, augments => \@augments };
        }
    }
    return %new_bag_inventory;
}


sub APPLY_FOCUS {
    my $owner = $npc->GetOwner()->CastToClient();
    my $inventory = $owner->GetInventory();

    my $total_focus_scale = 1.0;
    my $true_race = $owner->GetBucket("pet_race");

    #Mage Epic 1.0 - Orb of Mastery
    if ($owner->GetClass() == 13 && $inventory->HasItemEquippedByID(28034)) {
        if (!$npc->FindBuff(847)) {
            $npc->CastSpell(847, $npc->GetID());       
        }
        $total_focus_scale += 0.30;
    } elsif ($npc->FindBuff(847)) {
        $npc->BuffFadeBySpellID(847);
        $owner->BuffFadeBySpellID(847);
    }
    
    #Necro Epic 1.0 - Scythe of the Shadowed Soul
    if ($owner->GetClass() == 11 && $inventory->HasItemEquippedByID(20544) && $npc->GetBodyType() == 8)  {              
        $total_focus_scale += 0.25;
        if ($npc->GetRace() == $true_race) {
            $npc->SetRace(491); # Bone Golem
            $owner->SetBucket("pet_max_hp", $owner->GetBucket("pet_max_hp") + 1000);
        }
    } elsif ($npc->GetRace() == 491) {
        $npc->SetRace($true_race);
        $owner->SetBucket("pet_max_hp", $owner->GetBucket("pet_max_hp") - 1000);
    }

    #Beastlord Epic 1.0 - Claw of the Savage Spirit
    if ($owner->GetClass() == 15 && $inventory->HasItemEquippedByID(8495) && $npc->GetBodyType() == 21)  {
        $total_focus_scale += 0.30;
    }

    return $total_focus_scale;
}

sub SAVE_PET_STATS
{
    my $pet = $npc;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {     
        my @stat_list = qw(atk accuracy hp_regen min_hit max_hit max_hp ac mr fr cr dr pr);
        foreach my $stat (@stat_list) {
            $owner->SetBucket("pet_$stat", $pet->GetNPCStat($stat));
            my $petstat = $pet->GetNPCStat($stat);
            quest::debug("Saving $stat as ... $petstat");
        }
        
        $owner->SetBucket("pet_race", $pet->GetBaseRace());
    }
}

sub UPDATE_PET_STATS
{
    my $pet = $npc;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {
        # Create Scalar.
        my $pet_scalar = APPLY_FOCUS();

        my @stat_list = qw(atk accuracy hp_regen min_hit max_hit max_hp ac mr fr cr dr pr);
        foreach my $stat (@stat_list) {
            my $bucket_value = $owner->GetBucket("pet_$stat");
            if ($stat eq 'atk') { 
                quest::debug("Adjusting $stat - base: $bucket_value");
            }
            $bucket_value *= $pet_scalar;
            if ($stat eq 'atk') { 
                quest::debug("scaling by $pet_scalar - Result: $bucket_value");
            }
            $pet->ModifyNPCStat($stat, ceil($bucket_value));
        }
    }
}
