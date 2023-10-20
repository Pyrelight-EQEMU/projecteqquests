use Data::Dumper;
use POSIX;

my $combo_count = 3;
my @epics    = (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034);

sub EVENT_ITEM {
    my $charname    = $client->GetCleanName();
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
    my $work_order  = $client->GetBucket("Artificer-WorkOrder") || 0;
    my $cmc         = plugin::get_cmc();

    my $link_proceed    = "[".quest::saylink("link_proceed", 1, "proceed")."]";
    my $link_cancel     = "[".quest::saylink("link_cancel", 1, "cancel")."]";

    if ($work_order == 0) {
        if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
            if ($total_money > 0) {
                plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
            } elsif ($itemcount{'0'} < 3) {             
                plugin::NPCTell("I'm only interested in considering one item at a time, $charname.");
            } else {
                foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                    if ((grep { $_ == $item_id } @epics)) {
                                quest::debug("That was an epic aug!");
                                $cmc_cost *= 5;
                            }



                    my $item_link = quest::varlink($item_id);
                    my $test_result = plugin::test_upgrade($item_id);

                    if (plugin::is_item_upgradable($item_id)) {
                        if ((grep { $_ == $item_id } @array) or $test_result->{success}) {
                            my $next_item_link = quest::varlink(get_next_upgrade_id($item_id));
                            my $cmc_cost = $test_result->{total_cost};
                            
                            my $response = "This is an excellent piece, $charname. I can upgrade your [$item_link] to a [$next_item_link], it will cost you $cmc_cost ";

                            if ( $cmc >= $cmc_cost) {
                                plugin::NPCTell($response . "of your $cmc Concentrated Mana Crystals. Would you like to $link_proceed or $link_cancel this upgrade?");
                                plugin::YellowText("WARNING: Any augments in items consumed by this process will be DESTROYED without confirmation and 
                                                    any possibility of retrieval. Any eligible item of a lower enhancement tier may be consumed. Proceed with caution.");
                                $client->SetBucket("Artificer-WorkOrder", $item_id);
                                return;
                            } else {
                                my $link_obtain_more = "[".quest::saylink("link_concentrated_mana_crystals", 1, "obtain more")."]";
                                plugin::NPCTell($response . "Concentrated Mana Crystals, but you only have $cmc. Would you like to $link_obtain_more?");
                            }
                        } else {
                            plugin::NPCTell("You don't have enough similar items for me to concentrate the magic of your $item_link, $charname. 
                                            Seek them out, and return to me.");
                        }
                    } else {
                        plugin::NPCTell("I'm afraid that I can't enhance that [$item_link], $charname.");
                    }
                }
            }

        } else {               
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
                plugin::add_cmc($earned_points);
            } else {
                plugin::NPCTell("That isn't enough to pay for any crystals, unfortunately. Here, have it back.");
            }
        }
    } else {
      plugin::NPCTell("I'm sorry, $charname, but I already have a work order in progress for you. Please $link_proceed or $link_cancel it before giving me another item.");
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
    plugin::return_items_silent(\%itemcount);
}

sub EVENT_SAY {
    my $charname    = $client->GetCleanName();
    my $cmc         = plugin::get_cmc();
    my $work_order  = $client->GetBucket("Artificer-WorkOrder") || 0;

    my $link_equipment                  = "[".quest::saylink("link_equipment", 1, "equipment")."]";
    my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
    my $link_show_me_your_equipment     = "[".quest::saylink("link_show_me_your_equipment", 1, "show me your equipment")."]";
    my $link_aa_points                  = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
    my $link_platinum                   = "[".quest::saylink("link_platinum", 1, "platinum")."]";
    my $link_siphon_10                  = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
    my $link_siphon_100                 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
    my $link_siphon_all                 = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";

    if($text=~/hail/i) {
        if ($work_order) {
            my $item_link = quest::varlink($work_order);
            plugin::NPCTell("You have an open work order with me, to strip a [$item_link]. Would you like me to $link_proceed or $link_cancel?");
        } else {
            if (!$client->GetBucket("CedricVisit")) {
                plugin::NPCTell("Greetings, $charname, I Cedric Sparkswall, an Artificer of some renown. I have developed a process to intensify the 
                                properties of certain $link_equipment, and I have come to this center of commerce in order to offer my services to intrepid adventurers!");
            } else {
                plugin::YellowText("You currently have $cmc Concentrated Mana Crystals available.");
                plugin::NPCTell("Ah, it's you again, $charname. Do you have $link_equipment that needs to be enhanced? Do you need extra $link_concentrated_mana_crystals?");
            }
        }    
    }

    elsif ($text eq "link_equipment") {
                plugin::NPCTell("I can intensify the magic of certain equipment and weapons through the use of $link_concentrated_mana_crystals as 
                                well as an identical item to donate its aura. If you'd like me to appraise an item, simply hand it to me. 
                                Please be careful to remove any augmentations which you have added, though! They can interfere with the appraisal process.");
        $client->SetBucket("CedricVisit", 1);
    }

    elsif ($text eq "link_concentrated_mana_crystals") {
        plugin::YellowText("You currently have $cmc Concentrated Mana Crystals available.");
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
            plugin::YellowText("You have LOST 10 Alternate Advancement points!");
            plugin::add_cmc(10);
            plugin::NPCTell("Ahh. Excellent. I've added ten crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have sufficient accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_siphon_100") {
        if ($client->GetAAPoints() >= 100) {
            $client->SetAAPoints($client->GetAAPoints() - 100);
            plugin::YellowText("You have LOST 100 Alternate Advancement points!");
            plugin::add_cmc(100);
            plugin::NPCTell("Ahh. Excellent. I've added one hundred crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have sufficient accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_siphon_all") {
        if ($client->GetAAPoints() >= 1) {
            my $aa_drained = $client->GetAAPoints();
            plugin::YellowText("You have LOST $aa_drained Alternate Advancement points!");
            $client->SetAAPoints(0);
            plugin::add_cmc($aa_drained);
            plugin::NPCTell("Ahh. Excellent. I've added $aa_drained crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have any accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_cancel") {
        my $item_id = $client->GetBucket("Artificer-WorkOrder");
        if (item_exists_in_db($item_id)) {
            $client->SummonItem($item_id, 1, 1);
            $client->DeleteBucket("Artificer-WorkOrder");
            plugin::NPCTell("No problem! Here, have this back.");
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
    }

    elsif ($text eq "link_proceed") {
        my $item_id = $client->GetBucket("Artificer-WorkOrder");
        if (item_exists_in_db($item_id)) {    
            if (1) {
                $client->SummonItem($item_id + 1000000, 1, 1);
            } else {
                execute_upgrade($item_id);
            }
            $client->DeleteBucket("Artificer-WorkOrder");
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
    }
}