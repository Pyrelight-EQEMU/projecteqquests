sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();
   my $work_order = $client->GetBucket("Gemcarver-WorkOrder") || 0;

   my $link_services = "[".quest::saylink("link_services", 1, "services")."]";
   my $link_services_2 = "[".quest::saylink("link_services", 1, "do for you")."]";
   my $link_glamour_stone = "[".quest::saylink("link_glamour_stone", 1, "Glamour-Stone")."]";
   my $link_custom_work = "[".quest::saylink("link_custom_work", 1, "custom enchantments")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("Avelyn")) {
         $response = "Hail, $clientName. I carve $link_spellstones, pretty simple. I can imbue ";
      } else {
         $response = "Welcome back, $clientName. Do you need a $link_spellstones? ";
      }    
   }

   elsif ($text eq "link_cancel") {
      my $item_id = $work_order;
      if ($work_order and plugin::item_exists_in_db($item_id)) {
         $client->SummonItem($item_id);
         $client->DeleteBucket("Gemcarver-WorkOrder");
         plugin::NPCTell("No problem! Here, have this back.");
      } else {
         plugin::NPCTell("I don't know what you are talking about. I don't have any work orders in progress for you.");
      }
   }

   if ($response ne "") {
      plugin::NPCTell($response);
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
      foreach my $item_id (keys %itemcount) {
         if ($item_id != 0) {
            quest::debug("I was handed: $item_id with a count of $itemcount{$item_id}");
            my $item_name = quest::varlink($item_id);
            my $response = "Alright then, let's take a look at this [$item_name]. ";
            my $found_work = 0;

            my $proc_id = quest::getitemstat($item_id, 'proceffect');
            if ($proc_id > 0) {
               my $binding_id = get_binding($item_id);
               my $binding_name = quest::varlink($binding_id);
               $response .= " I see an [$binding_name] ($binding_id) that I can extract.";
               $found_work = 1;
            }

            my $proc_id = quest::getitemstat($item_id, 'clickeffect');
            if ($proc_id > 0) {
               my $spellstone_id = get_spellstone($item_id);
               my $spellstone_name = quest::varlink($spellstone_id);
               $response .= " I see an [$spellstone_name] that I can extract.";
               $client->SetBucket("Gemcarver-WorkOrder", $item_id);
               $found_work = 1;
            }

            my $proc_id = quest::getitemstat($item_id, 'focuseffect');
            if ($proc_id > 0) {
               my $glyph_id = get_glyph($item_id);
               my $glyph_name = quest::varlink($spellstone_id);
               $response .= " I see an [$glyph_name] that I can extract.";
               $found_work = 1;
            }

            if ($found_work) {
               $client->SetBucket("Gemcarver-WorkOrder", $item_id);
            } else {
               $response = "I'm sorry, $clientName. I don't see anything that I can extract from [$item_name] for you.";
            }

            plugin::NPCTell($response);
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
    plugin::return_items(\%itemcount); 
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