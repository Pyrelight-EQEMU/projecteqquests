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

sub calculate_heroic_stat_sum {
    my $item_id = get_base_id(shift);
    my $client = plugin:val('client');

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

sub get_virt_inventory {
    my ($item_id, $mod) = @_;
    my %item_counts;    
    my $client = plugin:val('client');

    $item_counts{$item_id} = $mod;
    $item_counts{plugin::get_next_upgrade_id($item_id)} = 0;

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

    $client = plugin::val('client');

    my $target_item_id  = plugin::get_next_upgrade_id($current_item_id);
    my $prev_item_id    = plugin::get_prev_upgrade_id($current_item_id);

    my $original_target_count = 0;

    if (plugin::is_item_upgradable($current_item_id) && $target_item_id) {
        if (!$is_recursive) {
            $virtual_inventory  = plugin::get_virt_inventory($current_item_id, 1);
            my $total_cmc_cost  = 0;
            $total_cmc_cost_ref = \$total_cmc_cost;
        }
        
        $original_target_count  = $virtual_inventory->{$target_item_id};
        my $count               = $client->CountItem($current_item_id);        

        my $loop_limit = 2; # A limit to prevent infinite loops
        my $loop_count = 0;

        while ($virtual_inventory->{$current_item_id} < 2 && $prev_item_id && $loop_count++ < $loop_limit) {
            test_upgrade($prev_item_id, 1, $virtual_inventory, $total_cmc_cost_ref);
        }

        if ($virtual_inventory->{$current_item_id} >= 2) {
            $virtual_inventory->{$current_item_id} -= 2;
            $virtual_inventory->{$target_item_id}++;

            $$total_cmc_cost_ref += plugin::get_upgrade_cost($target_item_id);
        }
    }

    my $result = {
        success => 0,
        total_cost => $$total_cmc_cost_ref
    };

    if ($virtual_inventory->{$target_item_id} > $original_target_count) {
        $result->{success} = 1;
    }

    return $result; 
}

sub execute_upgrade {
    my ($current_item_id, $is_recursive, $virtual_inventory, $ledger) = @_;

    my $client = plugin::val('client');
    
    my $test_result = plugin::test_upgrade($current_item_id) unless $is_recursive;

    if ($is_recursive or ($test_result->{success} && $test_result->{total_cost} <= plugin::get_cmc())) {

        my $target_item_id = plugin::get_next_upgrade_id($current_item_id);
        my $prev_item_id = plugin::get_prev_upgrade_id($current_item_id);

        if (plugin::is_item_upgradable($current_item_id) && $target_item_id) {
            if (!$is_recursive) {
                $virtual_inventory = plugin::get_virt_inventory($current_item_id, 1);
                $ledger = {};
            }

            my $count = $client->CountItem($current_item_id);       

            my $loop_limit = 2; # A limit to prevent infinite loops
            my $loop_count = 0;

            while ($virtual_inventory->{$current_item_id} < 2 && $prev_item_id && $loop_count++ < $loop_limit) {
                plugin::execute_upgrade($prev_item_id, 1, $virtual_inventory, $ledger);
            }

            if ($virtual_inventory->{$current_item_id} >= 2) {
                $virtual_inventory->{$current_item_id} -= 2;
                $virtual_inventory->{$target_item_id}++;                

                $ledger->{$current_item_id}-- if $is_recursive;
                $ledger->{$current_item_id}--;
                $ledger->{$target_item_id}++;

                plugin::subtract_cmc(plugin::get_upgrade_cost($target_item_id));
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
    } 
}