sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();

   my $link_dispel = "[".quest::saylink("link_dispel", 1, "dispel")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("Artificer_Apprentice")) {
         $response = "Hey there, $clientName! I'm here to help out Master Cedric, but I can help you too. I'm still learning how to enhance items, but I can definitely $link_dispel existing enhancements if you need the original version.";
      } else {
         $response = "Welcome back, $clientName. Do you need me to $link_dispel something for you? ";
      }    
   }

   elsif ($text eq "link_dispel") {
      $response = "I'd be happy to help you! Just hand me the item, and I'll make it happen for you.";
      $client->SetBucket("Artificer_Apprentice", 1);
   }

    if ($response ne "") {
        plugin::NPCTell($response);
    }
}

sub EVENT_ITEM {
    my $clientName = $client->GetCleanName();
    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;

    if (exists $itemcount{'0'} && $itemcount{'0'} < 4) {
        if ($total_money > 0) {
            plugin::NPCTell("I really don't need any money, $clientName.");
        } elsif ($itemcount{'0'} < 3) {             
            plugin::NPCTell("I can only dispel one item at a time, $clientName.");
        } else {
            foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
                my $item_link = quest::varlink($item_id);

                if ($item_id >= 1000000) {
                    my $base_id = get_base_id($item_id);
                    $client->SummonItem($base_id);
                    plugin::NPCTell("Easy-Peasy. Here you go.");
                    return;
                } else {
                    plugin::NPCTell("I'm afraid that I can't dispel that [$item_link], $clientName.");
                }
            }
        }

    }
    plugin::return_items_silent(\%itemcount);
}

# Returns the base ID of an item
sub get_base_id {
    my $item_id = shift;
    return $item_id % 1000000; # Assuming item IDs increment by 1000000 per tier
}