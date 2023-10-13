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
        my %inventory_list = %{ get_all_items_in_inventory($client) };

        my %base_items_and_points; # This will store base item as the key and total points as the value

        # Transform the raw inventory list into a list of upgradeable items 
        # represented by their base versions and point values
        while (my ($key, $value) = each %inventory_list) {
            my $base_id = $key % 1000000;
            
            if (is_upgradeable($base_id)) {
                my $points = int($key / 1000000) + 1;  # +1 to make base versions 1 point
                $base_items_and_points{$base_id} += $points * $value;
            }
        }

        # Determine the highest-tier version achievable for the total points available
        while (my ($base_id, $points) = each %base_items_and_points) {
            my $upgrade_potential = int($points / 2); # because 2 of the previous tier required for the next tier
            my $highest_possible_upgrade_id = $base_id + ($upgrade_potential * 1000000);
            
            if (!$inventory_list{$highest_possible_upgrade_id} && $upgrade_potential > 0) { 
                my $name = quest::getitemname($base_id);
                plugin::NPCTell("You can upgrade $name to tier $upgrade_potential.");
            }
        }
    }
}

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
            }  # <-- Closing brace for inner foreach
        }
    }  # <-- Closing brace for outer foreach
    
    return \%items_in_inventory;
}

sub get_point_value {
    my $tier = shift;
    return 2**($tier - 1);
}

sub decompose_item {
    my $item_id = shift;

    my $base_item_id = $item_id % 1000000;
    my $tier = int($item_id / 1000000);
    my $points = get_point_value($tier);

    return ($base_item_id, $points);
}

sub is_upgradeable {
    my $base_id = shift;
    my $dbh = plugin::LoadMysql();

    # Shortcut if the base_id is already above 1 million
    if ($base_id >= 1000000) {
        return 1;
    }

    # Check for the existence of an item with base_id + 1 million in the 'items' table
    my $upgrade_id = $base_id + 1000000;
    my $query = $dbh->prepare("SELECT count(*) FROM items WHERE id = ?");
    $query->execute($upgrade_id);
    my ($count) = $query->fetchrow_array();

    # If the count is greater than 0, the item is upgradeable
    if ($count > 0) {
        return 1;
    }

    return 0;
}

sub transform_inventory_list {
    my $inventory_ref = shift;
    my %raw_inventory = %{$inventory_ref};
    my %transformed_inventory;

    foreach my $item_id (keys %raw_inventory) {
        my $base_id = $item_id % 1000000;
        next unless is_upgradeable($base_id);

        my $tier = int($item_id / 1000000);

        # Calculate points based on the tier
        my $points = 2**$tier;

        $transformed_inventory{$base_id} += $points * $raw_inventory{$item_id};
    }

    return \%transformed_inventory;
}