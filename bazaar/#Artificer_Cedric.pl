use Data::Dumper;
use POSIX;

my $combo_count = 3;
my @epics    = (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034);

sub EVENT_ITEM {
    my $clientName = $client->GetCleanName();
    my $CMC_Available = get_cmc();
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
    my $work_order = $client->GetBucket("Artificer-WorkOrder") || 0;

    my $link_proceed = "[".quest::saylink("link_proceed", 1, "proceed")."]";
    my $link_cancel = "[".quest::saylink("link_cancel", 1, "cancel")."]";

    if ($work_order == 0) {
        if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
            if ($total_money > 0) {
                plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
            } elsif ($itemcount{'0'} < 3) {             
                plugin::NPCTell("I'm only interested in considering one item at a time, $clientName.");
            } else {
                foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                    my $item_link   = quest::varlink($item_id);
                    my $test_result = test_upgrade($item_id);
                    my $base_id     = get_base_id($item_id);

                    if ((grep { $_ == $base_id } @epics)) {
                        plugin::NPCTell("Incredible! This artifact is special, I won't need any duplicates to upgrade this at all, only a substantial investment in
                                        Concentrated Mana Crystals.");
                    } elsif (is_item_upgradable($item_id)) {                        
                        if ($test_result->{success}) {
                            my $next_item_link = quest::varlink(get_next_upgrade_id($item_id));
                            my $cmc_cost = $test_result->{total_cost};
                            my $cmc_avail = get_upgrade_points();

                            plugin::YellowText("You currently have $cmc_avail Concentrated Mana Crystals available.");
                            my $response = "This is an excellent piece, $clientName. I can upgrade your [$item_link] to a [$next_item_link], it will cost you $cmc_cost ";

                            if ( $cmc_avail >= $cmc_cost) {
                                plugin::NPCTell($response . "of your $cmc_avail Concentrated Mana Crystals. Would you like to $link_proceed or $link_cancel this upgrade?");
                                plugin::YellowText("WARNING: Any augments in items consumed by this process will be DESTROYED without confirmation and 
                                                    any possibility of retrieval. Any eligible item of a lower enhancement tier may be consumed. Proceed with caution.");
                                $client->SetBucket("Artificer-WorkOrder", $item_id);
                                return;
                            } else {
                                my $link_obtain_more = "[".quest::saylink("link_concentrated_mana_crystals", 1, "obtain more")."]";
                                plugin::NPCTell($response . "Concentrated Mana Crystals, but you only have $cmc_avail. Would you like to $link_obtain_more?");
                            }
                        } else {
                            plugin::NPCTell("You don't have enough similar items for me to concentrate the magic of your $item_link, $clientName. 
                                            Seek them out, and return to me.");
                        }
                    } else {
                        plugin::NPCTell("I'm afraid that I can't enhance that [$item_link], $clientName.");
                    }
                }
            }

        } else {               
            my $earned_points = 0;

            while ($total_money >= (500 * 1000)) {
                $total_money = $total_money - (500 * 1000);
                $earned_points++;
                $CMC_Available++;
            }

            if ($earned_points > 0) {
                plugin::YellowText("You currently have $CMC_Available Concentrated Mana Crystals available.");
                if ($total_money > 0) {
                    plugin::NPCTell("Ahh. Excellent. I've added $earned_points crystals under your name to my ledger. Here is your change!");
                } else {
                    plugin::NPCTell("Ahh. Excellent. I've added $earned_points crystals under your name to my ledger.");
                }
                $client->SetBucket("Artificer_CMC", $CMC_Available);
            } else {
                plugin::NPCTell("That isn't enough to pay for any crystals, unfortunately. Here, have it back.");
            }

            # After processing all items, return any remaining money
            my $platinum_remainder = int($total_money / 1000);
            $total_money %= 1000;

            my $gold_remainder = int($total_money / 100);
            $total_money %= 100;

            my $silver_remainder = int($total_money / 10);
            $total_money %= 10;

            my $copper_remainder = $total_money;

            $client->AddMoneyToPP($copper_remainder, $silver_remainder, $gold_remainder, $platinum_remainder, 1);
        }
    } else {
      plugin::NPCTell("I'm sorry, $clientName, but I already have a work order in progress for you. Please $link_proceed or $link_cancel it before giving me another item.");
    }
    plugin::return_items_silent(\%itemcount);
}

sub EVENT_SAY {
    my $clientName = $client->GetCleanName();

    my $CMC_Points = $client->GetBucket("Artificer_CMC") || 0;

    my $link_equipment = "[".quest::saylink("link_equipment", 1, "equipment")."]";
    my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
    my $link_show_me_your_equipment = "[".quest::saylink("link_show_me_your_equipment", 1, "show me your equipment")."]";
    my $link_aa_points = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
    my $link_platinum = "[".quest::saylink("link_platinum", 1, "platinum")."]";
    my $link_siphon_10 = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
    my $link_siphon_100 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
    my $link_siphon_all = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";

    if($text=~/hail/i) {
        if (!$client->GetBucket("CedricVisit")) {
            plugin::NPCTell("Greetings, $clientName, I Cedric Sparkswall, an Artificer of some renown. I have developed a process to intensify the 
                            properties of certain $link_equipment, and I have come to this center of commerce in order to offer my services to intrepid adventurers!");
        } else {
            plugin::YellowText("You currently have $CMC_Points Concentrated Mana Crystals available.");
            plugin::NPCTell("Ah, it's you again, $clientName. Do you have $link_equipment that needs to be enhanced? Do you need extra $link_concentrated_mana_crystals?");
        }    
    }

    elsif ($text eq "link_equipment") {
                plugin::NPCTell("I can intensify the magic of certain equipment and weapons through the use of $link_concentrated_mana_crystals as 
                                well as an identical item to donate its aura. If you'd like me to appraise an item, simply hand it to me. 
                                Please be careful to remove any augmentations which you have added, though! They can interfere with the appraisal process.");
        $client->SetBucket("CedricVisit", 1);
    }

    elsif ($text eq "link_concentrated_mana_crystals") {
        plugin::YellowText("You currently have $CMC_Points Concentrated Mana Crystals available.");
        plugin::NPCTell("These mana crystals can be somewhat hard to locate. If you have trouble finding enough, I have a reasonable supply that I am 
                        willing to trade for your $link_aa_points or even mere $link_platinum.");        
    }

    elsif ($text eq "link_platinum") {
        plugin::NPCTell("If you want to buy $link_concentrated_mana_crystals with platinum, simply hand the coins to me. I will credit you with one 
                        crystal for each 500 coins.");
    }

    elsif ($text eq "link_aa_points") {
        plugin::NPCTell("If you want to buy $link_concentrated_mana_crystals with temporal energy, simply say the word. 
                        I can $link_siphon_10, $link_siphon_100, or $link_siphon_all and credit you with one crystal for each point removed.");
    }

    elsif ($text eq "link_siphon_10") {
        if ($client->GetAAPoints() >= 10) {
            $client->SetAAPoints($client->GetAAPoints() - 10);
            $client->SetBucket("Artificer_CMC", $CMC_Points + 10);
            plugin::YellowText("You have LOST 10 Alternate Advancement points!");
            plugin::NPCTell("Ahh. Excellent. I've added ten crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have sufficient accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_siphon_100") {
        if ($client->GetAAPoints() >= 100) {
            $client->SetAAPoints($client->GetAAPoints() - 100);
            $client->SetBucket("Artificer_CMC", $CMC_Points + 100);
            plugin::YellowText("You have LOST 100 Alternate Advancement points!");
            plugin::NPCTell("Ahh. Excellent. I've added one hundred crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have sufficient accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_siphon_all") {
        if ($client->GetAAPoints() >= 1) {
            my $aa_drained = $client->GetAAPoints();
            $client->SetAAPoints(0);
            $client->SetBucket("Artificer_CMC", $CMC_Points + $aa_drained);
            plugin::YellowText("You have LOST $aa_drained Alternate Advancement points!");
            plugin::NPCTell("Ahh. Excellent. I've added $aa_drained crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have sufficient accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_cancel") {
        my $item_id = $client->GetBucket("Artificer-WorkOrder");
        if (item_exists_in_db($item_id)) {
            $client->SummonItem($item_id);
            $client->DeleteBucket("Artificer-WorkOrder");
            plugin::NPCTell("No problem! Here, have this back.");
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
    }

    elsif ($text eq "link_proceed") {
        my $item_id = $client->GetBucket("Artificer-WorkOrder");
        if (item_exists_in_db($item_id)) {            
            if ((grep { $_ == $item_id } @epics)) {
                $client->SummonItem($item_id + 1000000);
            } else {
                execute_upgrade($item_id);
            }
            $client->DeleteBucket("Artificer-WorkOrder");
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
    }
}

# add_limbo($value)
# Adds a new value to the "Artificer-Limbo" bucket.
# Parameters:
#   $value - The value to be added.
sub add_limbo {
    my ($value) = @_;

    # Fetch the current data
    my $data_string = $client->GetBucket("Artificer-Limbo");
    my $data_array = eval($data_string) || [];

    # Append the new value
    push @$data_array, $value;

    # Serialize and store the updated data
    $client->SetBucket("Artificer-Limbo", Dumper($data_array));
}

# remove_limbo($value)
# Removes a value from the "Artificer-Limbo" bucket.
# Parameters:
#   $value - The value to be removed.
# Note: Removes all instances of the value.
sub remove_limbo {
    my ($value) = @_;

    # Fetch the current data
    my $data_string = $client->GetBucket("Artificer-Limbo");
    my $data_array = eval($data_string) || [];

    # Remove the value
    @$data_array = grep { $_ ne $value } @$data_array;

    # Serialize and store the updated data
    $client->SetBucket("Artificer-Limbo", Dumper($data_array));
}

# get_limbo()
# Retrieves all values stored in the "Artificer-Limbo" bucket.
# Returns:
#   An array containing all the stored values.
sub get_limbo {
    # Fetch the current data
    my $data_string = $client->GetBucket("Artificer-Limbo");
    my $data_array = eval($data_string) || [];

    # Return the entire array
    return @$data_array;
}

# exists_limbo($value)
# Checks if a value exists in the "Artificer-Limbo" bucket.
# Parameters:
#   $value - The value to check for.
# Returns:
#   1 if the value exists, 0 otherwise.
sub exists_limbo {
    my ($value) = @_;

    # Fetch the current data
    my $data_string = $client->GetBucket("Artificer-Limbo");
    my $data_array = eval($data_string) || [];

    # Check and return if the value exists
    return grep { $_ eq $value } @$data_array ? 1 : 0;
}

# Returns the base ID of an item
sub get_base_id {
    my $item_id = shift;
    return $item_id % 1000000; # Assuming item IDs increment by 1000000 per tier
}

# Returns the upgrade tier of an item
sub get_upgrade_tier {
    my $item_id = shift;
    return int($item_id / 1000000); # Assuming item IDs increment by 1000000 per tier
}

# Wrapper function to return both base ID and upgrade tier
sub get_base_id_and_tier {
    my $item_id = shift;
    return (get_base_id($item_id), get_upgrade_tier($item_id));
}

sub is_item_upgradable {
    my $item_id = shift;

    #shortcut if we are already an upgraded item
    if ($item_id >= 1000000) {
        return 1;
    }

    if ($item_id > 20000000) {
        return 0;
    }

    # Calculate the next-tier item ID
    my $next_tier_item_id = get_base_id($item_id) + (1000000 * (get_upgrade_tier($item_id) + 1));

    # Check if the next-tier item exists in the database
    return item_exists_in_db($next_tier_item_id);
}

# Check if the specified item ID exists
sub item_exists_in_db {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();
    my $sth = $dbh->prepare("SELECT count(*) FROM items WHERE id = ?");
    $sth->execute($item_id);

    my $result = $sth->fetchrow_array();

    $sth->finish();
    $dbh->disconnect();

    return $result > 0 ? 1 : 0;
}

sub auto_upgrade_item {
    my ($item_id_to_upgrade, $target_upgrade) = @_;

    # Create a clone of the player's inventory for simulation purposes
    my %simulated_inventory = %{ get_all_items_in_inventory($client) };
    
    # Check if upgrade is possible in simulation
    if (simulate_upgrade(\%simulated_inventory, $item_id_to_upgrade, $target_upgrade)) {
        
        # Perform actual inventory operations since simulation succeeded
        execute_upgrade($client, $item_id_to_upgrade, $target_upgrade);
        
        return 1; # Upgrade successful
    }
    
    return 0; # Upgrade failed
}

sub get_next_upgrade_id {
    my $item_id = shift;

    if (is_item_upgradable($item_id) && $item_id < 20000000) {
        return ($item_id + 1000000);
    } else {
        return 0;
    }    
}

sub get_prev_upgrade_id {
    my $item_id = shift;

    if (is_item_upgradable($item_id) && $item_id > 1000000) {
        return ($item_id - 1000000);
    } else {
        return 0;
    }    
}

# Deep copy a hash
sub deep_copy_hash {
    my $hash_ref = shift;
    my %new_hash = %{$hash_ref};
    return \%new_hash;
}

sub get_upgrade_items {
    my ($item_id, $mod) = @_;
    my %item_counts;

    $item_counts{$item_id} = $mod;
    $item_counts{get_next_upgrade_id($item_id)} = 0;

    # Continue until the item_id is reduced to a value less than or equal to 999999
    while ($item_id > 999999) {
        # Count the current item
        $item_counts{$item_id} += $client->CountItem($item_id);
        # Subtract 1 million to get to the next 'tier' of item
        $item_id -= 1000000;
    }
    
    # Finally, count the base item
    $item_counts{$item_id} += $client->CountItem($item_id);

    return \%item_counts;
}

sub test_upgrade {
    my ($current_item_id, $is_recursive, $virtual_inventory, $total_cmc_cost_ref) = @_;

    my $target_item_id = get_next_upgrade_id($current_item_id);
    my $prev_item_id = get_prev_upgrade_id($current_item_id);

    my $original_target_count = 0;

    if (is_item_upgradable($current_item_id) && $target_item_id) {
        if (!$is_recursive) {
            $virtual_inventory = get_upgrade_items($current_item_id, 1);
            my $total_cmc_cost = 0;
            $total_cmc_cost_ref = \$total_cmc_cost;
        }
        
        $original_target_count = $virtual_inventory->{$target_item_id};
        my $count = $client->CountItem($current_item_id);

        #quest::debug("(Before) Current virtual inventory: " . join(", ", map { "$_ -> $virtual_inventory->{$_}" } keys %{$virtual_inventory}));
        #quest::debug("Trying to combine $current_item_id ($count), next: $target_item_id, prev: $prev_item_id");
        

        my $loop_limit = 2; # A limit to prevent infinite loops
        my $loop_count = 0;

        while ($virtual_inventory->{$current_item_id} < 2 && $prev_item_id && $loop_count++ < $loop_limit) {
            test_upgrade($prev_item_id, 1, $virtual_inventory, $total_cmc_cost_ref);
        }

        if ($virtual_inventory->{$current_item_id} >= 2) {
            $virtual_inventory->{$current_item_id} -= 2;
            $virtual_inventory->{$target_item_id}++;

            $$total_cmc_cost_ref += get_upgrade_cost($target_item_id);

            #quest::debug("(After) Current virtual inventory: " . join(", ", map { "$_ -> $virtual_inventory->{$_}" } keys %{$virtual_inventory}));
        }
    }

    my $result = {
        success => 0,
        total_cost => $$total_cmc_cost_ref
    };

    if ($virtual_inventory->{$target_item_id} > $original_target_count) {
        quest::debug("Successfully produced the $target_item_id");
        $result->{success} = 1;
    } else {
        quest::debug("Unable to upgrade $current_item_id to $target_item_id");
    }

    return $result; 
}

sub execute_upgrade {
    my ($current_item_id, $is_recursive, $virtual_inventory, $ledger) = @_;
    
    my $test_result = test_upgrade($current_item_id) unless $is_recursive;

    if ($is_recursive or ($test_result->{success} && $test_result->{total_cost} <= get_upgrade_points())) {

        my $target_item_id = get_next_upgrade_id($current_item_id);
        my $prev_item_id = get_prev_upgrade_id($current_item_id);

        if (is_item_upgradable($current_item_id) && $target_item_id) {
            if (!$is_recursive) {
                $virtual_inventory = get_upgrade_items($current_item_id, 1);
                $ledger = {};
            }

            my $count = $client->CountItem($current_item_id);

            #quest::debug("(Before) Current virtual inventory: " . join(", ", map { "$_ -> $virtual_inventory->{$_}" } keys %{$virtual_inventory}));
            quest::debug("Trying to combine $current_item_id ($count), next: $target_item_id, prev: $prev_item_id");        

            my $loop_limit = 2; # A limit to prevent infinite loops
            my $loop_count = 0;

            while ($virtual_inventory->{$current_item_id} < 2 && $prev_item_id && $loop_count++ < $loop_limit) {
                execute_upgrade($prev_item_id, 1, $virtual_inventory, $ledger);
            }

            if ($virtual_inventory->{$current_item_id} >= 2) {
                $virtual_inventory->{$current_item_id} -= 2;
                $virtual_inventory->{$target_item_id}++;                

                $ledger->{$current_item_id}-- if $is_recursive;
                $ledger->{$current_item_id}--;
                $ledger->{$target_item_id}++;

                subtract_upgrade_points(get_upgrade_cost($target_item_id));

                #quest::debug("(After) Current virtual inventory: " . join(", ", map { "$_ -> $virtual_inventory->{$_}" } keys %{$virtual_inventory}));
            }
        }

        if (not $is_recursive) {
            # Apply changes in ledger to actual inventory
            foreach my $item_id (keys %$ledger) {
                # If the value is negative, remove items
                while ($ledger->{$item_id} < 0) {

                    my $count_before = $client->CountItem($item_id);

                    $client->RemoveItem($item_id);

                    my $count_after = $client->CountItem($item_id);

                    if ($count_before == $count_after) {
                        plugin::RedText("WARNING: ITEM NOT DELETED: $item_id");
                    } else {
                        quest::debug("DELETED $item_id");
                    }

                    $ledger->{$item_id}++;
                }

                # If the value is positive, summon items
                while ($ledger->{$item_id} > 0) {
                    $client->SummonItem($item_id, 1, 1);
                    $ledger->{$item_id}--;
                }
            }
        }

    } else {
        quest::debug("Pre-Upgrade Test Failed!");
    }
}

sub get_upgrade_cost {
    my $item_id = shift;
    my $item_tier = get_upgrade_tier($item_id);
    my $stat_sum = calculate_heroic_stat_sum($item_id);
    my $cost = int(0.25 * ($stat_sum * $item_tier) + $item_tier);

    if ($stat_sum < 1) {
        return $item_tier - 1;
    }    

    return $cost;
}

sub get_upgrade_points {
    my $CMC_Available = $client->GetBucket("Artificer_CMC") || 0;
    return $CMC_Available;
}

sub subtract_upgrade_points {
    my $amount = shift;
    my $CMC_Available = $client->GetBucket("Artificer_CMC") || 0;
    quest::debug("Subtracting $amount from CMC");
    $client->SetBucket("Artificer_CMC", $CMC_Available - $amount);
}

sub calculate_heroic_stat_sum {
    my $item_id = get_base_id(shift);

    # Define the primary stats we want to sum up
    my @primary_stats = qw(
        heroicstr heroicsta heroicdex heroicagi 
        heroicint heroicwis heroiccha
    );

    # Define the resistance stats we want to sum up and then halve
    my @resistance_stats = qw(
        heroicfr heroicmr heroic_r heroicpr heroicdr
    );

    # Fetch and sum the primary stats
    my $primary_stat_total = 0;
    foreach my $stat (@primary_stats) {
        $primary_stat_total += $client->GetItemStat($item_id, $stat);
    }

    # Fetch the resistance stats, sum them up, and then halve the total
    my $resistance_stat_total = 0;
    foreach my $stat (@resistance_stats) {
        $resistance_stat_total += $client->GetItemStat($item_id, $stat);
    }
    $resistance_stat_total /= 2;

    # Return the total sum of primary and halved resistance stats
    return $primary_stat_total + $resistance_stat_total;
}