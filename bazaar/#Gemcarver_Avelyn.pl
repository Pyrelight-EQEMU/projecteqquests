sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();
   my $work_order = $client->GetBucket("Gemcarver-WorkOrder") || 0;s
   my $CMC_Available = $client->GetBucket("Artificer_CMC") || 0;

   my $link_spellstones_glyphs_bindings = "[".quest::saylink("link_spellstones_glyphs_bindings", 1, "Spellstones, Glyphs, and Bindings")."]";
   my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "obtain more")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("Avelyn")) {
         plugin::NPCTell("Hail, $clientName. I ply my trade here in the bazaar, extracting the magical essence of artifacts. I can create a variety of 
         $link_spellstones_glyphs_bindings, each allowing you to augment the abilities of a different item.");
      } else {
         plugin::YellowText("You currently have $CMC_Available Concentrated Mana Crystals available.");
         plugin::NPCTell("Welcome back, $clientName. Do you need $link_spellstones_glyphs_bindings?");
      }    
   }

   elseif ($text eq "link_spellstones_glyphs_bindings") {
      plugin::NPCTell("They are magical augments, each containing one type of active effect from an artifact. Spellstones allow you to cast a spell, Glyphs enhance
                     your existing spells, and Bindings produce an effect when you strike your enemy. There is, however, a cost in $link_concentrated_mana_crystals 
                     for my services. If you'd like me to evaluate an item, simply hand it to me.");
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
         $client->DeleteBucket("Gemcarver-WorkOrder");
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

    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;

    if ($work_order == 0) {
        if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
            if ($total_money > 0) {
                plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
            } elsif ($itemcount{'0'} < 3) {             
                plugin::NPCTell("I'm only interested in considering one item at a time, $clientName.");
            } else {
                foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                  # Handle items here
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