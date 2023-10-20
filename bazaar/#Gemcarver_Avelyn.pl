use List::Util 'max';

my @epics    = (20542, 8495, 8496, 68299, 5532, 20490, 10650, 28034, 10652, 36224, 
                20544, 10099, 20488, 20487, 11057, 14383, 10651, 14341, 66175, 
                66177, 66176);

sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();
   my $work_order = $client->GetBucket("Gemcarver-WorkOrder") || 0;
   my $CMC_Available = $client->GetBucket("Artificer_CMC") || 0;

   my $link_spellstones_glyphs_bindings = "[".quest::saylink("link_spellstones_glyphs_bindings", 1, "Spellstones, Glyphs, and Bindings")."]";
   my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
   my $link_aa_points = "[".quest::saylink("link_aa_points", 1, "temporal energy (AA Points)")."]";
   my $link_platinum = "[".quest::saylink("link_platinum", 1, "platinum")."]";
   my $link_siphon_10 = "[".quest::saylink("link_siphon_10", 1, "siphon 10 points")."]";
   my $link_siphon_100 = "[".quest::saylink("link_siphon_100", 1, "siphon 100 points")."]";
   my $link_siphon_all = "[".quest::saylink("link_siphon_all", 1, "siphon all remaining points")."]";
   my $link_proceed = "[".quest::saylink("link_proceed", 1, "proceed")."]";
   my $link_cancel = "[".quest::saylink("link_cancel", 1, "cancel")."]";

   if($text=~/hail/i) {
      if ($work_order) {
         my $item_link = quest::varlink($work_order);
         plugin::NPCTell("You have an open work order with me, to strip a [$item_link]. Would you like me to $link_proceed or $link_cancel?");
      } else {
         if (!$client->GetBucket("Avelyn")) {
            plugin::NPCTell("Hail, $clientName. I ply my trade here in the bazaar, extracting the magical essence of artifacts. I can create a variety of 
            $link_spellstones_glyphs_bindings, each allowing you to augment the abilities of a different item.");
         } else {
            plugin::YellowText("You currently have $CMC_Available Concentrated Mana Crystals available.");
            plugin::NPCTell("Welcome back, $clientName. Do you need $link_spellstones_glyphs_bindings?");
         }
      } 
   }

   elsif ($text eq "link_spellstones_glyphs_bindings") {
      plugin::NPCTell("They are magical augments, each containing one type of active effect from an artifact. Spellstones allow you to cast a spell, Glyphs enhance
                     your existing spells, and Bindings produce an effect when you strike your enemy. There is, however, a cost in $link_concentrated_mana_crystals 
                     for my services. If you'd like me to evaluate an item, simply hand it to me.");
         $client->SetBucket("Avelyn", 1);
   }

   elsif ($text eq "link_concentrated_mana_crystals") {
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
      my $item_id = $client->GetBucket("Gemcarver-WorkOrder");
      if (plugin::item_exists_in_db($item_id)) {
         $client->SummonItem($item_id);
         $client->DeleteBucket("Gemcarver-WorkOrder");
         plugin::NPCTell("No problem! Here, have this back.");
      } else {
         plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
      }
   }

   elsif ($text eq "link_proceed") {
      my $item_id = $client->GetBucket("Gemcarver-WorkOrder");
      if (plugin::item_exists_in_db($item_id)) {
         
         my $base_id = plugin::get_base_id($item_id);
         
         # Fetch the items to be summoned
         my @items_to_summon;
         push @items_to_summon, get_binding($base_id) if get_binding($base_id);
         push @items_to_summon, get_glyph($base_id) if get_glyph($base_id);
         push @items_to_summon, get_spellstone($base_id) if get_spellstone($base_id);

         # Determine the total runes
         my $total_runes = scalar @items_to_summon;

         # Calculate cost
         my $cost = get_cost($item_id, $total_runes);
         
         # Inform the user of the cost (or take any other necessary action)
         plugin::NPCTell("The cost for your items will be $cost.");
         
         # Plurality check for the NPC's message
         my $npc_message;
         if (@items_to_summon == 1) {
               $npc_message = "Here you go, $clientName. I hope it serves you well.";
         } else {
               $npc_message = "Here you go, $clientName. I hope they serve you well.";
         }
         plugin::NPCTell($npc_message);

         # Loop through the items and summon them
         for my $item (@items_to_summon) {
               $client->SummonItem($item);
         }

         $client->DeleteBucket("Gemcarver-WorkOrder");
      } else {
         plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
      }
   }
}

sub EVENT_ITEM { 
   my $copper = plugin::val('copper');
   my $silver = plugin::val('silver');
   my $gold = plugin::val('gold');
   my $platinum = plugin::val('platinum');
   my $clientName = $client->GetCleanName();
   my $work_order = $client->GetBucket("Gemcarver-WorkOrder") || 0;

   my $link_proceed = "[".quest::saylink("link_proceed", 1, "proceed")."]";
   my $link_cancel = "[".quest::saylink("link_cancel", 1, "cancel")."]";
   my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";

   my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;

   if ($work_order == 0) {
      if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
         if ($total_money > 0) {
               plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
         } elsif ($itemcount{'0'} < 3) {             
               plugin::NPCTell("I'm only interested in considering one item at a time, $clientName.");
         } else {
            foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
               if ($item_id != 0) {
                  my $item_name = quest::varlink($item_id);
                  my $found_work = 0;
                  my $base_id = plugin::get_base_id($item_id); 

                  my @found_items = get_found_items($base_id);

                  if (@found_items) {
                     my $cost = get_cost($base_id, scalar @found_items);
                     my $last_item = pop(@found_items);
                     my $response = "Alright then, let's take a look at this [$item_name]. I think that I can extract ";
                     
                     if (@found_items) {
                        $response .= join(", ", @found_items) . ", and " . $last_item . " ";
                     } else {
                        $response .= $last_item . ".";
                     }
                     
                     $client->SetBucket("Gemcarver-WorkOrder", $item_id);
                     $found_work = 1;                     
                     plugin::NPCTell($response . " from this. It will cost $cost $link_concentrated_mana_crystals. Do you want to $link_proceed or $link_cancel?");
                     return;
                  }

                  unless ($found_work) {
                     my $response = "I'm sorry, $clientName. I don't see anything that I can extract from [$item_name] for you.";
                     plugin::NPCTell($response);
                  }
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
      }
   } else {
      plugin::NPCTell("I'm sorry, $clientName, but I already have a work order in progress for you. Please $link_proceed or $link_cancel it before giving me another item.");
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

sub is_global_aug {
   my $item_id = shift;
   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 AND lootdrop_entries.item_id = ?");
   $sth->execute($item_id);
   
   $dbh->disconnect();
   
   if ($sth->fetchrow_array) {
       return 1; # Item ID is present
   } else {
       return 0; # Item ID is not present
   }
}

sub get_global_aug {
    my $dbh = plugin::LoadMysql();

    my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 ORDER BY RAND() LIMIT 1");
    $sth->execute();
    
    my ($random_item_id) = $sth->fetchrow_array;

    $dbh->disconnect();
    return $random_item_id;
}

sub get_binding() {
   my $item_id = shift;
   my $item_name = quest::getitemname($item_id);

   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT id FROM items WHERE lore = ? AND id >= 930000 AND id < 999999 AND proceffect > 0 AND itemtype = 54");
   $sth->execute($item_name);

   my $retval = $sth->fetchrow_array || 0;
   $sth->finish();
   $dbh->disconnect();
   return $retval;
}

sub get_found_items {
    my ($base_id) = @_;

    my $binding    = get_binding($base_id);
    my $glyph      = get_glyph($base_id);
    my $spellstone = get_spellstone($base_id);

    my @found_items;                  
    push(@found_items, "a [" . quest::varlink($binding) . "]"    ) if $binding;
    push(@found_items, "a [" . quest::varlink($glyph) . "]"      ) if $glyph;
    push(@found_items, "a [" . quest::varlink($spellstone) . "]" ) if $spellstone;

    return @found_items;
}

sub get_spellstone() {
   my $item_id = shift;
   my $item_name = quest::getitemname($item_id);

   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT id FROM items WHERE lore = ? AND id >= 910000 AND id < 999999 AND focuseffect > 0 AND itemtype = 54");
   $sth->execute($item_name);

   my $retval = $sth->fetchrow_array || 0;
   $sth->finish();
   $dbh->disconnect();
   return $retval;
}

sub get_glyph() {
   my $item_id = shift;
   my $item_name = quest::getitemname($item_id);

   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT id FROM items WHERE lore = ? AND id >= 920000 AND id < 999999 AND clickeffect > 0 AND itemtype = 54");
   $sth->execute($item_name);

   my $retval = $sth->fetchrow_array || 0;
   $sth->finish();
   $dbh->disconnect();
   return $retval;
}

sub get_cost {
    my ($item_id, $total_runes) = @_;
    my $client = plugin::val('client');
    my $stat_sum = calculate_heroic_stat_sum($item_id);
    my %unlocked_classes = plugin::GetUnlockedClasses($client);

    quest::debug("$stat_sum, $total_runes") ; 

    my $cost = int(($stat_sum * $total_runes) * (keys %unlocked_classes));
    return $cost;
}


sub calculate_heroic_stat_sum {
    my $item_id = plugin::get_base_id(shift);

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

sub GetHighestLevelOfUnlockedClasses {
    my $client = shift;

    my %unlocked_classes = GetUnlockedClasses($client);

    # Start with a really low value
    my $highest_level = 0;
    
    foreach my $level (values %unlocked_classes) {
        if ($level > $highest_level) {
            $highest_level = $level;
        }
    }

    return max($highest_level, $client->GetLevel());
}