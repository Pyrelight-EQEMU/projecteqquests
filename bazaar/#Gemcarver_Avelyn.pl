use Data::Dumper;
use POSIX;

my @epics      = (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034);
my $trade_cost = 1;

sub EVENT_ITEM {
    my $clientName = $client->GetCleanName();
    my $CMC_Available = plugin::get_cmc();
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
    my $work_order = $client->GetBucket("Gemcarver-WorkOrder") || 0;

    my $link_proceed                      = "[".quest::saylink("link_proceed", 1, "proceed")."]";
    my $link_cancel                       = "[".quest::saylink("link_cancel", 1, "cancel")."]";
    my $link_obtain_more                  = "[".quest::saylink("link_obtain_more", 1, "obtain more")."]";
    my $link_concentrated_mana_crystals   = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
      my $link_bindings_glyphs_and_spells = "[".quest::saylink("link_bindings_glyphs_and_spells", 1, "Bindings, Glyphs, and Spells")."]";
    my $link_trade                        = "[".quest::saylink("link_trade", 1, "trade")."]";

    if ($work_order == 0) {
        if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
            if ($total_money > 0) {
                plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
            } elsif ($itemcount{'0'} < 3) {             
                plugin::NPCTell("I'm only interested in considering one item at a time, $clientName.");
            } else {
               foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                  my $base_id = get_base_id($item_id);
                  my $itemlink = quest::varlink($item_id);
                  if (grep { $_ == $base_id } @epics) {
                     plugin::NPCTell("I'm sorry, $clientName. This item is far too precious, I'm not going to touch it.");
                  } elsif (is_global_aug($item_id)) {
                     if ($CMC_Available > $trade_cost) {
                        plugin::NPCTell("I'd be happy to take this in trade. Here, try this one on for size!");
                        plugin::spend_cmc($trade_cost);
                        $client->SummonItem(get_global_aug(), 1, 1);
                        return;
                     } else {
                         plugin::NPCTell("I'd be happy to take this in trade, but I do require $trade_cost $link_converted_mana_crystals.");
                     }
                  } else {
                     my @augs = @{ get_augs($base_id) };
                     my $aug_count = scalar @augs;
                     my $cost = calculate_heroic_stat_sum($base_id) * (scalar @augs) + plugin::GetTotalLevels($client);
                     if (scalar @augs) {
                           my $response = "We have some interesting components here. ";                           
                           if (@augs == 1) {
                              $response .= "I see a " . quest::varlink($augs[0]) . ".";
                           } elsif (@augs == 2) {
                              $response .= "I see a " . quest::varlink($augs[0]) . " and " . quest::varlink($augs[1]) . ".";
                           } else {
                              $response .= "I see a ";
                              for my $i (0 .. $#augs - 1) {
                                 $response .= quest::varlink($augs[$i]) . ", ";
                              }
                              $response .= "and " . quest::varlink($augs[-1]) . ".";
                           }
                     
                           $response .= " It will cost you $cost Concentrated Mana Crystals";
                           if ($CMC_Available >= $cost) {
                              plugin::NPCTell($response . ". Would you like to $link_proceed, or $link_cancel?");
                              $client->SetBucket("Gemcarver-WorkOrder", $item_id);
                              return;                              
                           } else {
                              plugin::NPCTell($response . ", but you only have $CMC_Available. Do you need to $link_obtain_more?");
                           }

                     } else {
                           plugin::NPCTell("Unfortunately, I don't think that I can extract anything from that $itemlink, $clientName. 
                                          Bring me something more interesting next time.");
                     }
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
                plugin::NPCTell("Ahh. Excellent. I've added $earned_points crystals under your name to my ledger.");
                plugin::add_cmc($earned_points);                        
            } else {
                plugin::NPCTell("That isn't enough to pay for any crystals, unfortunately. Here, have it back.");
            }
        }
    } else {
        plugin::NPCTell("I'm sorry, $clientName, but I already have a work order in progress for you. Please $link_proceed or $link_cancel it before giving me another item.");
        plugin::YellowText("WARNING: Any augments in items consumed by this process will be DESTROYED without confirmation and 
                            any possibility of retrieval. Any eligible item of a lower enhancement tier may be consumed. Proceed with caution.");
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
    my $clientName = $client->GetCleanName();
    my $CMC_Points = plugin::get_cmc();    
    my $item_id = $client->GetBucket("Gemcarver-WorkOrder");  

    my $link_equipment                  = "[".quest::saylink("link_equipment", 1, "equipment")."]";
    my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
    my $link_aa_points                  = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
    my $link_platinum                   = "[".quest::saylink("link_platinum", 1, "platinum")."]";
    my $link_siphon_10                  = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
    my $link_siphon_100                 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
    my $link_siphon_all                 = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";
    my $link_proceed                    = "[".quest::saylink("link_proceed", 1, "proceed")."]";
    my $link_cancel                     = "[".quest::saylink("link_cancel", 1, "cancel")."]";
    my $link_bindings_glyphs_and_spells = "[".quest::saylink("link_bindings_glyphs_and_spells", 1, "Bindings, Glyphs, and Spells")."]";
    my $link_trade                      = "[".quest::saylink("link_trade", 1, "trade")."]";

    if($text=~/hail/i) {
        if ($item_id) {
            my $itemlink = quest::varlink($item_id);
            plugin::NPCTell("Greetings, $clientName, would you like to $link_proceed or $link_cancel your work order to strip the enchantments from your [$itemlink]?");
        } elsif (!$client->GetBucket("AvelynVisit")) {
            plugin::NPCTell("Hello there, $clientName. The name's Avelyn. Magic? It's everywhere, in every artifact and trinket. I've simply learned how to harness 
                           it a bit differently. By carefully extracting the $link_bindings_glyphs_and_spells, I can transform those artifacts into Augments. 
                           They can be merged with almost any equipment, letting you carry a piece of that original power with you. And if by chance, 
                           you have some rare augments you're not putting to use, I might be interested in a $link_trade. Everything has its value, after all.");

        } else {            
            plugin::NPCTell("Back again, $clientName? Ready to transform that $link_equipment into potent augments? Or perhaps you're here to $link_trade? Should you 
                           require $link_concentrated_mana_crystals, you know I'm your source.");
            plugin::display_cmc();
        }    
    }

   elsif ($text eq "link_equipment") {
      plugin::NPCTell("Hand over that piece of equipment and I'll expertly unravel its essence, distilling it into $link_bindings_glyphs_and_spells. There will be a cost in 
                     $link_concentrated_mana_crystals, both to pay me and to fuel the process. Just remember, once it's done, there's no going back.");
      $client->SetBucket("AvelynVisit", 1);
   }

   elsif ($text eq "link_trade") {
      plugin::NPCTell("If you stumble upon augments out in the world, they may be ones that I want to add to my collection. Bring me an augment, and spend one whole
                     $link_concentrated_mana_crystal and I'll give you a new, random one in return.");
      $client->SetBucket("AvelynVisit", 1);
   }

   elsif ($text eq "link_bindings_glyphs_and_spells") {
      plugin::NPCTell("It's a dance of magic and essence. Combat effects transform into the Eldritch Bindings, while Focus effects take the form of Glyphs. And the 
                     Activated ones? They become Spellstones. Would you like me to look at your $link_equipment?");
      $client->SetBucket("AvelynVisit", 1);
   }

    elsif ($text eq "link_obtain_more" or $text eq "link_concentrated_mana_crystals") {
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
            $client->SetAAPoints(0);
            plugin::YellowText("You have LOST $aa_drained Alternate Advancement points!");
            plugin::add_cmc($aa_drained);
            plugin::NPCTell("Ahh. Excellent. I've added $aa_drained crystals under your name to my ledger.");
        } else {
            plugin::NPCTell("You do not have any accumulated temporal energy for me to siphon that much from you!");
        }
    }

    elsif ($text eq "link_cancel") {
        my $item_id = $client->GetBucket("Gemcarver-WorkOrder");
        if (item_exists_in_db($item_id)) {
            $client->SummonItem($item_id, 1, 1);
            $client->DeleteBucket("Gemcarver-WorkOrder");
            plugin::NPCTell("No problem! Here, have this back.");
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
    }

    elsif ($text eq "link_proceed") {      
        if ($item_id) {
            my $base_id = get_base_id($item_id);            
            my @augs = @{ get_augs($base_id) };
            my $cost = get_upgrade_cost($base_id) * (scalar @augs) + plugin::GetTotalLevels($client);
            my $cmc  = plugin::get_cmc();
            if (scalar @augs && $cmc >= $cost) {
               plugin::NPCTell("Excellent, lets do it.");
               plugin::spend_cmc($cost);
               foreach my $aug (@augs) {
                  quest::debug("$aug");
                  $client->SummonItem($aug, 1, 1);
               }
            } elsif ($cmc < $cost) {
               plugin::NPCTell("You don't have enough $link_concentrated_mana_crystals.");
               plugin::display_cmc();
               return;
            } else {
               plugin::RedText("This is impossible. Report to GM that you got this message.");
               $client->SummonItem($item_id, 1, 1);               
            }
        } else {
            plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
        }
        $client->DeleteBucket("Gemcarver-WorkOrder");
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

sub get_upgrade_cost {
   my $item_id = shift or return 0;
   my $item_tier = get_upgrade_tier($item_id);
   my $stat_sum = calculate_heroic_stat_sum($item_id);
   my $cost = int(0.25 * ($stat_sum * $item_tier) + $item_tier);

   return $cost;
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

sub get_effects {
    my $client = plugin::val('client');
    my $item_id = shift or return {};

    # Define the types of effects you want to retrieve
    my @effect_types = qw(proceffect clickeffect worneffect focuseffect);

    # Define an empty hash to store our results
    my %effects;

    # Loop over each effect type, retrieve the effect from the client, and store it in our hash
    foreach my $effect_type (@effect_types) {
        $effects{$effect_type} = $client->GetItemStat($effect_type, $item_id) // 0; # Use default of 0 if no effect is found
    }

    $effects{'name'} = quest::getitemname($item_id);

    return \%effects; # Return a reference to the hash
}

sub get_augs {
    my $item_id = shift or return [];
    
    # Get the database handle
    my $dbh = plugin::LoadMysql();

    # Prepare the SQL statement
    my $sth = $dbh->prepare("
        SELECT id 
        FROM items 
        WHERE id > 900000 
        AND id < 999999 
        AND (name LIKE 'Eldritch Binding:%' OR name LIKE 'Spellstone:%' OR name LIKE 'Arcane Glyph:%')
        AND lore LIKE ?");
    
    # Execute the statement with the desired parameter
    $sth->execute(quest::getitemname($item_id));

    # Fetch the results
    my @item_ids;
    while (my $row = $sth->fetchrow_hashref()) {
        push @item_ids, $row->{id};
        my $id = $row->{id};
    }

    # Cleanup
    $sth->finish();
    $dbh->disconnect();

    return \@item_ids; # Return a reference to the list of item ids
}

sub is_global_aug {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();

    my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 AND lootdrop_entries.item_id = ?");
    $sth->execute($item_id);

    $dbh->disconnect();
   
    if ($sth->fetchrow_array) {
        $sth->finish();
        return 1; # Item ID is present
    } else {
        $sth->finish();
        return 0; # Item ID is not present
    }
}

sub get_global_aug {
   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 ORDER BY RAND() LIMIT 1");
   $sth->execute();
   
   my ($random_item_id) = $sth->fetchrow_array;

   $sth->finish();
   $dbh->disconnect();
   return $random_item_id;   
}