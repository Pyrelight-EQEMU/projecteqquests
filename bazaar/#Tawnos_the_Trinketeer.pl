sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();
   my $link_epic = "[".quest::saylink("link_epic", true, "relic")."]";
   my $link_custom = "[".quest::saylink("link_custom", true, "custom work")."]";
   my $link_voucher = "[".quest::saylink("link_voucher", true, "one of my calling cards")."]";
   if($text=~/hail/i) {
      if (!$client->GetBucket("Tawnos")) {
         $response = "Hail, $clientName. I am Tawnos, master artificer and enchanter! I am still setting up my facilities here in the Bazaar, but I can already offer some services. ";
      } else {
         $response = "Welcome back, $clientName. What can I do for you today? ";
      }
      $response = $response . "If you have acquired a $link_epic, I can offer you an corresponding ornament for it. If you are interested in $link_custom, we should talk!";            
   }

   elsif ($text eq "link_epic") {
      $class = $client->GetClass();
      $ornament = 0;
      
      # Use a hash to map the class and item id to the ornament id
      my %class_item_to_ornament = (
            '2_5532' => 127916,
            '3_10099' => 127923,
            '4_20488' => 127924,
            '5_14383' => 127927,
            '6_20490' => 127917,
            '10_10651' => 127926,
            '11_20544' => 127921,
            '13_28034' => 127919,
            '14_10650' => 127918,
            '15_8495' => 127914,
      );

      # Check each item in the player's equipment
      foreach my $class_item (keys %class_item_to_ornament) {
            my ($class_key, $item_id) = split("_", $class_item);
            quest::debug("checking $class_key for $item_id");
            if ($class_key == $class && $client->HasItemEquippedByID($item_id)) {
                  $ornament = $class_item_to_ornament{$class_item};
                  last;  # Exit the loop once we find a match
            }
      }

      if ($ornament > 0) {
         $response = "Amazing! I recognize that one. I know just the trick for this one; take this trinket. If you apply it as an augment to one
                      of your weapons or other held equipment, it will take on the illusion of your relic. This won't give you any improvement to 
                      the augmented item, but we can work on that later.";
         $client->SummonItem($ornament);
      } else {
          $response = "I don't see a relic among your equipment, please don't waste my time. Come back when you have one.";
      }
   }  

   plugin::NPCTell($response);
}

sub EVENT_ITEM {
  plugin::return_items(\%itemcount);
}


