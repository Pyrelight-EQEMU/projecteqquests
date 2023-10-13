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
      $response = "Primarily, I can enchant a $link_glamour_stone for you. A speciality of my own invention, these augments can change the appearance of your equipment to mimic another item that you posess. I do charge a nominal fee, a mere 5000 platinum coins, for this service. I aim to offer $link_custom_work for my most discerning customers soon, too.";
      $client->SetBucket("Tawnos", 1);
   }

   elsif ($text eq "link_glamour_stone") {
      $response = "If you are interested in a $link_glamour_stone, simply hand me the item which you'd like me to duplicate, along with my fee.";
   }

   elsif ($text eq "link_custom_work") {
      $response = "I do not have all of my equipment prepared yet, so we will discuss that at a later time";
   }

   if ($response not eq "") {
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

            my $item_name = quest::getitemname($item_id);

            # Strip prefix
            $item_name =~ s/^(Rose Colored|Apocryphal|Fabled)\s*//;

            # Strip suffix
            $item_name =~ s/\+\d{1,2}$//;

            quest::debug("looking for: '" . $item_name . "' Glamour-Stone");

            # Use a prepared statement to prevent SQL injection
            my $sth = $dbh->prepare('SELECT id FROM items WHERE name LIKE ?');
            $sth->execute("'" . $item_name . "' Glamour-Stone");
            if (my $row = $sth->fetchrow_hashref()) {                
                if ($total_money >= (5000 * 1000)) {
                    $total_money -= (5000 * 1000);
                    plugin::NPCTell("Perfect! Here, I had a Glamour-Stone almost ready for your $item_name, I just needed to add the attunement. This should be what you want!");
                    $client->SummonItem($row->{id});
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

