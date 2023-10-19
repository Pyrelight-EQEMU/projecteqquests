sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();

   my $link_services = "[".quest::saylink("link_services", 1, "services")."]";
   my $link_services_2 = "[".quest::saylink("link_services", 1, "do for you")."]";
   my $link_glamour_stone = "[".quest::saylink("link_glamour_stone", 1, "Glamour-Stone")."]";
   my $link_custom_work = "[".quest::saylink("link_custom_work", 1, "custom enchantments")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("Tawnos")) {
         $response = "Hail, $clientName. I am Tawnos, master artificer and enchanter! I am still setting up my facilities here in the Bazaar, but I can already offer some $link_services to my eager customers.";
      } else {
         $response = "Welcome back, $clientName. What can I $link_services_2 today? ";
      }    
   }

   elsif ($text eq "link_services") {
      $response = "Primarily, I can enchant a $link_glamour_stone for you. A speciality of my own invention, these augments can change the appearance of your equipment to mimic another item that you posess. I do charge a nominal fee, a mere 5000 platinum coins, for this service.";
      $client->SetBucket("Tawnos", 1);
   }

   elsif ($text eq "link_glamour_stone") {
      $response = "If you are interested in a $link_glamour_stone, simply hand me the item or items which you'd like me to duplicate, along with my fee. Be warned, this process will irrevocably consume the item that you are asking me to duplicate.";
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

    my @epics  = (20542, 8495, 8496, 68299, 5532, 20490, 10650, 28034, 10652, 36224, 
                  20544, 10099, 20488, 20487, 11057, 14383, 10651, 14341, 66175, 
                  66177, 66176);


   foreach my $item_id (keys %itemcount) {
      if ($item_id != 0) {
         quest::debug("I was handed: $item_id with a count of $itemcount{$item_id}");

         my $item_name = quest::getitemname($item_id);

         # Strip prefix with possible whitespace
         $item_name =~ s/^\s*(Rose Colored|Apocryphal|Fabled)\s*//;

         # Strip suffix with possible whitespace
         $item_name =~ s/\s*\+\d{1,2}\s*$//;

         #quest::debug("looking for: '" . $item_name . "' Glamour-Stone");

         # Use a prepared statement to prevent SQL injection
         my $sth = $dbh->prepare('SELECT id FROM items WHERE name LIKE ?');
         $sth->execute("'" . $item_name . "' Glamour-Stone");
         if (my $row = $sth->fetchrow_hashref()) {                
               if ($total_money >= (5000 * 1000)) {
                  if (grep { $_ == $item_id } @epics) {
                     plugin::NPCTell("Oh my! This is an absolute relic. I believe that I can create a Glamour-Stone without destroying this item, if I try hard enough... Let's see..");
                  } else {
                     # Remove the $item_id from the hash %itemcount
                     delete $itemcount{$item_id}; 
                  }

                  $total_money -= (5000 * 1000);
                  plugin::NPCTell("Perfect! Here, I had a Glamour-Stone almost ready. I'll just need to attune it to your $item_name! Enjoy!");
                  $client->SummonItem($row->{id});
                  $client->SummonItem(902386) if ($row->{id} == 902385); #Special Case of handle offhand beastlord epic         
                 
               } else {
                  plugin::NPCTell("I must insist upon my fee $clientName for the $item_name, I do have to pay my bills. Please ensure you have enough for all your items.");
               }
         } else {
               plugin::NPCTell("I don't think that I can create a Glamour-Stone for that item, $clientName. It must be something that you hold in your hand, such as a weapon or shield.");
         }
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