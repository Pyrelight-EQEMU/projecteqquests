sub EVENT_ITEM {
    my $clientName = $client->GetCleanName();
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;

    if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
        if ($total_money > 0) {
            plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
        } else {             
             foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                my $item_name = quest::varlink($item_id);
                if (is_item_upgradable($item_id)) {
                    my $points = get_total_points_for_item($item_id, $client) + get_point_value_for_item($item_id);

                    # Get current item's tier
                    my $current_tier = get_upgrade_tier($item_id);
                    
                    # List the upgrade tiers the player can afford which are higher than the current item's tier
                    my $tier = $current_tier + 1;
                    my @affordable_tiers;
                    while ($points >= 2**$tier) {
                        push @affordable_tiers, $tier;
                        $tier++;
                    }

                    if (@affordable_tiers) {
                        my $tier_list = join(", ", @affordable_tiers);
                        plugin::NPCTell("$clientName, with your available points, you can afford the following upgrade tiers for your [$item_name]: $tier_list.");

                        my $testval = calculate_heroic_stat_sum(get_base_id($item_id));

                        plugin::NPCTell("$testval");
                    } else {
                        plugin::NPCTell("$clientName, unfortunately, you do not have enough points to upgrade your [$item_name] to a higher tier.");
                    }

                } else {
                    plugin::NPCTell("I'm sorry, $clientName, I do not have the skills to improve your [$item_name].");
                }
             }
             plugin::return_items(\%itemcount);
        }
    } else {
        plugin::return_items(\%itemcount);        
        my $earned_points = 0;

        while ($total_money >= (500 * 1000)) {
            $total_money = $total_money - (500 * 1000);
            $earned_points++;
        }

        if ($earned_points > 0) {
            if ($total_money > 0) {
                plugin::NPCTell("Ahh. Excellent. I've added $earned_points crystals under your name to my ledger. Here is your change!");
            } else {
                plugin::NPCTell("Ahh. Excellent. I've added $earned_points crystals under your name to my ledger.");
            }
            $client->SetBucket("Artificer_CMC", ($client->GetBucket("Artificer_CMC") || 0) + $earned_points);
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
}

sub EVENT_SAY {
    my $clientName = $client->GetCleanName();

    my $CMC_Points = $client->GetBucket("Artificer_CMC") || 0;

    my $link_enhance = "[".quest::saylink("link_enhance", 1, "enhancement of items")."]";
    my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
    my $link_show_me_your_equipment = "[".quest::saylink("link_show_me_your_equipment", 1, "show me your equipment")."]";
    my $link_aa_points = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
    my $link_platinum = "[".quest::saylink("link_platinum", 1, "platinum")."]";
    my $link_siphon_10 = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
    my $link_siphon_100 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
    my $link_siphon_all = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";

    if($text=~/hail/i) {
        if (!$client->GetBucket("CedricVisit")) {
            plugin::NPCTell("Greetings, $clientName, I Cedric Sparkswall. I specialize in the $link_enhance, and have come to this grand center of commerce in order to ply my trade.");
        } else {
            plugin::NPCTell("Ah, it's you again, $clientName. How may I assist you with my $link_enhance today?");
        }    
    }

    elsif ($text eq "link_enhance") {
        plugin::NPCTell("I can intensify the magic of certain equipment and weapons through the use of $link_concentrated_mana_crystals as well as an identical item to donate its aura. If you'd like to $link_show_me_your_equipment, can I tell you if you have equipment that is eligible for my services.");
        $client->SetBucket("CedricVisit", 1);
    }

    elsif ($text eq "link_concentrated_mana_crystals") {
        plugin::NPCTell("These mana crystals can be somewhat hard to locate. If you have trouble finding enough, I have a reasonable supply that I am willing to trade for your $link_aa_points or even mere $link_platinum.");
        plugin::YellowText("You currently have $CMC_Points Concentrated Mana Crystals available.");
    }

    elsif ($text eq "link_platinum") {
        plugin::NPCTell("If you want to buy $link_concentrated_mana_crystals with platinum, simply hand the coins to me. I will credit you with one crystal for each 500 coins.");
    }

    elsif ($text eq "link_aa_points") {
        plugin::NPCTell("If you want to buy $link_concentrated_mana_crystals with temporal energy, simply say the word. I can $link_siphon_10, $link_siphon_100, or $link_siphon_all and credit you with one crystal for each point removed.");
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

    elsif ($text eq "link_show_me_your_equipment") {
    }
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
    return (
        base_id => get_base_id($item_id),
        tier => get_upgrade_tier($item_id)
    );
}

sub is_item_upgradable {
    my $item_id = shift;

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

    return $result > 0 ? 1 : 0;
}

sub get_all_items_in_inventory {
    my $client = shift;
    
    my @augment_slots = (
        quest::getinventoryslotid("augsocket.begin")..quest::getinventoryslotid("augsocket.end")
    );

    my @inventory_slots = (
        quest::getinventoryslotid("possessions.begin")..quest::getinventoryslotid("possessions.end"),
        quest::getinventoryslotid("generalbags.begin")..quest::getinventoryslotid("generalbags.end"),
        quest::getinventoryslotid("bank.begin")..quest::getinventoryslotid("bank.end"),
        quest::getinventoryslotid("bankbags.begin")..quest::getinventoryslotid("bankbags.end"),
        quest::getinventoryslotid("sharedbank.begin")..quest::getinventoryslotid("sharedbank.end"),
        quest::getinventoryslotid("sharedbankbags.begin")..quest::getinventoryslotid("sharedbankbags.end"),
    );
    
    my %items_in_inventory;

    foreach my $slot_id (@inventory_slots) {
        if ($client->GetItemAt($slot_id)) {
            my $item_id_at_slot = $client->GetItemIDAt($slot_id);
            $items_in_inventory{$item_id_at_slot}++ if defined $item_id_at_slot;

            foreach my $augment_slot (@augment_slots) {
                if ($client->GetAugmentAt($slot_id, $augment_slot)) {
                    my $augment_id_at_slot = $client->GetAugmentIDAt($slot_id, $augment_slot);
                    $items_in_inventory{$augment_id_at_slot}++ if defined $augment_id_at_slot;
                }
            }
        }
    }
    
    return \%items_in_inventory;
}

sub get_total_points_for_item {
    my ($item_id, $client) = @_;

    # Obtain base item ID for comparison
    my $base_item_id = get_base_id($item_id);

    # Fetch all items in the client's inventory
    my %items_in_inventory = %{ get_all_items_in_inventory($client) };

    # Calculate the total points
    my $total_points = 0;

    # Iterate over all items in the inventory
    foreach my $inv_item_id (keys %items_in_inventory) {
        if (get_base_id($inv_item_id) == $base_item_id) {
            $total_points += get_point_value_for_item($inv_item_id) * $items_in_inventory{$inv_item_id};
        }
    }

    return $total_points;
}

sub get_point_value_for_item {
    my $item_id = shift;

    # Determine the tier of the item
    my $tier = get_upgrade_tier($item_id);

    # Calculate the point value based on the tier
    my $point_value = 2 ** $tier;  # Tier 0 = 1 point, Tier 1 = 2 points, Tier 2 = 4 points, ...

    return $point_value;
}

sub calculate_heroic_stat_sum {
    my ($item_id) = @_;

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

sub calculate_upgrade_cmc {

}
