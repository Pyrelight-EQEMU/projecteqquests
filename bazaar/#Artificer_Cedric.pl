sub EVENT_ITEM { 
    plugin::return_items(\%itemcount);

    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
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
        my @upgradable_items = get_upgradable($client);
        
        # Debug or further processing here, for example:
        foreach my $item (@upgradable_items) {
            quest::debug("Upgradable item in inventory: $item");
        }
    }
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

# Return the point value of a specified raw item ID
sub get_point_value {
    my $item_id = shift;
    if ($item_id < 1000000) {
        return 1;
    }
    my $tier = int($item_id / 1000000);
    return 2 ** $tier;
}

# Check if the specified item ID exists
sub item_exists_in_db {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();
    my $sth = $dbh->prepare("SELECT count(*) FROM items WHERE id = ?");
    $sth->execute($item_id);

    my $result = $sth->fetchrow_array();

    quest::debug("Item with ID $item_id exists in DB: $result");

    return $result;
}

# Return a list of upgradable base items in the player's inventory
sub get_upgradable {
    my %inventory_list = %{ get_all_items_in_inventory($client) };
    my %upgradable_base_items;

    foreach my $item_id (keys %inventory_list) {
        # Calculate base item ID
        my $base_item_id = $item_id % 1000000;

        # Check if the base item can be upgraded
        if (item_exists_in_db($base_item_id + 1000000)) {
            if (exists $upgradable_base_items{$base_item_id}) {
                $upgradable_base_items{$base_item_id} += get_point_value($item_id) * $inventory_list{$item_id};
            } else {
                $upgradable_base_items{$base_item_id} = get_point_value($item_id) * $inventory_list{$item_id};
            }
        }
    }

    return %upgradable_base_items;
}

# Return the total points for a specified base item ID
sub get_total_points_for_base_item {
    my ($base_item_id, %inventory_list) = @_;
    my $total_points = 0;

    # Start with the base item itself
    if (exists $inventory_list{$base_item_id}) {
        $total_points += get_point_value($base_item_id) * $inventory_list{$base_item_id};
    }

    # Now check for its upgrades
    my $next_tier_item_id = $base_item_id + 1000000;
    while (exists $inventory_list{$next_tier_item_id}) {
        $total_points += get_point_value($next_tier_item_id) * $inventory_list{$next_tier_item_id};
        $next_tier_item_id += 1000000;
    }

    return $total_points;
}
