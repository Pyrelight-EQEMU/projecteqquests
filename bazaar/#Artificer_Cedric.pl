use Data::Dumper;
sub EVENT_ITEM {
    my $clientName = $client->GetCleanName();
    my $CMC_Available = $client->GetBucket("Artificer_CMC");
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;

    if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
        if ($total_money > 0) {
            plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
        } else {             
             foreach my $item_id (grep { $_ != 0 } keys %itemcount) {

                $Data::Dumper::Terse   = 1;   # avoids $VAR1 = ...
                $Data::Dumper::Indent  = 0;   # no whitespace or line breaks
                $Data::Dumper::Useqq   = 1;   # use double quotes always
                $Data::Dumper::Purity  = 1;   # attempts to produce valid perl code

                quest::debug(Dumper(plugin::val('$item1_inst')));
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

    my $link_equipment = "[".quest::saylink("link_equipment", 1, "equipment")."]";
    my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
    my $link_show_me_your_equipment = "[".quest::saylink("link_show_me_your_equipment", 1, "show me your equipment")."]";
    my $link_aa_points = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
    my $link_platinum = "[".quest::saylink("link_platinum", 1, "platinum")."]";
    my $link_siphon_10 = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
    my $link_siphon_100 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
    my $link_siphon_all = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";

    if($text=~/hail/i) {

        $client->RemoveItem(29439, 2);


        if (!$client->GetBucket("CedricVisit")) {
            plugin::NPCTell("Greetings, $clientName, I Cedric Sparkswall, an Artificer of some renown. I have developed a process to intensify the properties of certain $link_equipment, and I have come to this center of commerce in order to offer my services to intrepid adventurers!");
        } else {
            plugin::YellowText("You currently have $CMC_Points Concentrated Mana Crystals available.");
            plugin::NPCTell("Ah, it's you again, $clientName. Do you have $link_equipment that needs to be enhanced? Do you need extra $link_concentrated_mana_crystals?");
        }    
    }

    elsif ($text eq "link_equipment") {
                plugin::NPCTell("I can intensify the magic of certain equipment and weapons through the use of $link_concentrated_mana_crystals as well as an identical item to donate its aura. If you'd like me to appraise an item, simply hand it to me. Please be careful to remove any augmentations which you have added, though! They can interfere with the appraisal process.");
        $client->SetBucket("CedricVisit", 1);
    }

    elsif ($text eq "link_concentrated_mana_crystals") {
        plugin::YellowText("You currently have $CMC_Points Concentrated Mana Crystals available.");
        plugin::NPCTell("These mana crystals can be somewhat hard to locate. If you have trouble finding enough, I have a reasonable supply that I am willing to trade for your $link_aa_points or even mere $link_platinum.");        
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