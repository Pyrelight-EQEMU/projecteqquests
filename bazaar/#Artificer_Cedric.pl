sub EVENT_SAY {
   my $clientName = $client->GetCleanName();

   my $link_enhance = "[".quest::saylink("link_enhance", 1, "enhancement of items")."]";
   my $link_concentrated_mana_crystals = "[".quest::saylink("link_concentrated_mana_crystals", 1, "Concentrated Mana Crystals")."]";
   my $link_show_me_your_equipment = "[".quest::saylink("link_show_me_your_equipment", 1, "show me your equipment")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("CedricVisit")) {
         plugin::NPCTell("Greetings, $clientName, I Cedric Sparkswall. I specialize in the $link_enhance, and have come to this grand center of commerce in order to ply my trade.");
      } else {
         plugin::NPCTell("Ah, it's you again, $clientName. How may I assist you with my $link_enhance today?");
      }    
   }

   elsif ($text eq "link_enhance") {
      plugin::NPCTell("I can intensify the magic of certain equipment and weapons through the use of $link_concentrated_mana_crystals as well as an identical item to donate its aura. If you'd like to $link_show_me_your_equipment, can I tell you if you have equipment that is eligible for my services.");
      $client->SetBucket("CedricVisit", 1);
   }
}


sub EVENT_ITEM { 
    plugin::return_items(\%itemcount); 
}

sub get_all_items_in_inventory {
    my $client = shift;
    
    my @augment_slots = (
        quest::getinventoryslotid("augsocket.begin")..quest::getinventoryslotid("augsocket.end")
    );

    my @inventory_slots = (
        quest::getinventoryslotid("possessions.begin")..quest::getinventoryslotid("possessions.end"),
        quest::getinventoryslotid("generalbags.begin")..quest::getinventoryslotid("generalbags.end"),
        quest::getinventoryslotid("bank.begin")..quest::getinventoryslotid("bank.end"),
        quest::getinventoryslotid("bankbags.begin")..quest::getinventoryslotid("bankbags.end"),
        quest::getinventoryslotid("sharedbank.begin")..quest::getinventoryslotid("sharedbank.end"),
        quest::getinventoryslotid("sharedbankbags.begin")..quest::getinventoryslotid("sharedbankbags.end"),
    );
    
    my %items_in_inventory;

    foreach my $slot_id (@inventory_slots) {
        if ($client->GetItemAt($slot_id)) {
            my $item_id_at_slot = $client->GetItemIDAt($slot_id);
            $items_in_inventory{$item_id_at_slot}++ if defined $item_id_at_slot;

            foreach my $augment_slot (@augment_slots) {
                if ($client->GetAugmentAt($slot_id, $augment_slot)) {
                    my $augment_id_at_slot = $client->GetAugmentIDAt($slot_id, $augment_slot);
                    $items_in_inventory{$augment_id_at_slot}++ if defined $augment_id_at_slot;
                }
            }  # <-- Closing brace for inner foreach
        }
    }  # <-- Closing brace for outer foreach
    
    return \%items_in_inventory;
}

