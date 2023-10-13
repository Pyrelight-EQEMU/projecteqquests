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

        # Transform the raw inventory list into a list of upgradeable items, represented by their base versions and point values
        my %upgradeable_items;
        while (my ($key, $value) = each %inventory_list) {
            my $base_id = $key % 1000000;
            my $points = int($key / 1000000) + 0.5 * $value;

            if (item_exists_in_db($base_id + 1000000) || $key > 1000000) {
                $upgradeable_items{$base_id} += $points;
            }
        }

        # Debugging information
        while (my ($key, $value) = each %upgradeable_items) {
            quest::debug("Base ID: $key, Points: $value");
        }

        # For each upgradeable item, determine the highest tier upgrade we can achieve
        while (my ($key, $value) = each %upgradeable_items) {
            my $highest_tier = get_highest_tier_upgrade($key, $value, %inventory_list);
            plugin::NPCTell("For base item ID $key, you can upgrade to tier: $highest_tier");
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

sub get_highest_tier_upgrade {
    my ($base_id, $points, %inventory_list) = @_;
    my $tier = 1;
    my $needed_points = 2**$tier; # For the first tier, we need 2 points (2 items of base version).

    quest::debug("Starting get_highest_tier_upgrade for base_id: $base_id with points: $points");

    # Check if an item with base_id + 1 million exists and if we have enough points for that tier
    while (exists($inventory_list{$base_id + ($tier * 1000000)}) || 
           (item_exists_in_db($base_id + ($tier * 1000000)) && $points >= $needed_points)) {

        quest::debug("Tier: $tier, Needed Points: $needed_points");
        
        # If we find an item in inventory for this tier, deduct the needed points for this tier
        if (exists($inventory_list{$base_id + ($tier * 1000000)})) {
            quest::debug("Item for tier $tier found in inventory.");
            $points -= $needed_points;
        }

        $tier++;
        $needed_points = 2**$tier;
    }

    quest::debug("Ending get_highest_tier_upgrade. Highest possible tier: " . ($tier - 1));

    return $tier - 1;
}

sub item_exists_in_db {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();
    my $sth = $dbh->prepare("SELECT count(*) FROM items WHERE id = ?");
    $sth->execute($item_id);

    my $result = $sth->fetchrow_array();

    quest::debug("Item with ID $item_id exists in DB: $result");

    return $result;
}
