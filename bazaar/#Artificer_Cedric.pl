sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();

   my $link_enhance = "[".quest::saylink("link_enhance", 1, "enhancement of items")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("CedricVisit")) {
         $response = "Greetings, $clientName, I Cedric Sparkswall. I specialize in the $link_enhance, and have come to this grand center of commerce in order to ply my trade.";
      } else {
         $response = "Ah, it's you again, $clientName. How may I assist you with my $link_enhance today?";
      }    
   }

   elsif ($text eq "link_enhance") {
      $response = "I specialize in enhancing items, granting them newfound powers and capabilities. The enhancement process requires a special component, which I can procure for a fee of 5000 platinum coins. Soon, I'll be expanding my services to include custom enhancements for those seeking unique powers.";
      $client->SetBucket("CedricVisit", 1);
   }

   if ($response ne "") {
      plugin::NPCTell($response);
   }

   my %inventory_list = %{ get_all_items_in_inventory($client) };

   # Iterating over the inventory_list hash and send each element with plugin::NPCTell
   while (my ($key, $value) = each %inventory_list) {
      plugin::NPCTell("$key: $value");
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
        }
    }
    
    return \%items_in_inventory;
}