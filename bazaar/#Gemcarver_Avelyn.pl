sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();

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

   elsif ($text eq "link_glamour_stone") {
      $response = "If you are interested in a $link_glamour_stone, simply hand me the item or items which you'd like me to duplic asking me to duplicate.";
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

    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
    my $dbh = plugin::LoadMysql();

   foreach my $item_id (keys %itemcount) {
      if ($item_id != 0) {
         quest::debug("I was handed: $item_id with a count of $itemcount{$item_id}");
         my $item_name = quest::varlink($item_id);
         my $response = "Alright then, let's take a look at this [$item_name].";

         my $proc_id = quest::getitemstat($item_id, 'proceffect');
         if ($proc_id > 0) {
            my $binding_id = get_binding($item_id);
            my $binding_name = quest::varlink($binding_id);
            $response .= " I see an [$binding_name] that I can extract."
         }

         plugin::NPCTell($response);
      }
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

   my $sth = $dbh->prepare("SELECT id FROM items WHERE lore = ? AND id >= 920000 AND id < 999999 AND proceffect > 0 AND itemtype = 54");
   $sth->execute($item_name);

   $dbh->disconnect();
   return $sth->fetchrow_array || 0;
}