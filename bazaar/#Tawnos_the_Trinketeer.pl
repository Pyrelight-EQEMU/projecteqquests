sub EVENT_SAY {
   my $response = "";
   my $clientName = $client->GetCleanName();

   my $link_services = "[".quest::saylink("link_services", true, "services")."]";
   my $link_services_2 = "[".quest::saylink("link_services", true, "do for you")."]";
   my $link_glamour_stone = "[".quest::saylink("link_glamour_stone", true, "Glamour-Stone")."]";
   my $link_custom_work = "[".quest::saylink("link_custom_work", true, "custom enchantments")."]";

   if($text=~/hail/i) {
      if (!$client->GetBucket("Tawnos")) {
         $response = "Hail, $clientName. I am Tawnos, master artificer and enchanter! I am still setting up my facilities here in the Bazaar, but I can already offer some $link_services to my eager customers.";
      } else {
         $response = "Welcome back, $clientName. What can I $link_services_2 today? ";
      }    
   }

   elsif ($text eq "link_services") {
      $response = "Primarily, I can enchant a $link_glamour_stone for you. A speciality of my own invention, these augments can change the appearance of your equipment to mimic another item that you posess. I do charge a nominal fee, a mere 5000 platinum coins, for this service. I aim to offer $link_custom_work for my most discerning customers soon, too.";
      $client->SetBucket("Tawnos");
   }

   elsif ($text eq "link_services") {
      $response = "If you are interested in a $link_glamour_stone, simply hand me the item which you'd like me to duplicate. Do not bother me with coins, I will handle the money seperately.";
   }

   elsif ($text eq "link_custom_work") {
      $response = "I do not have all of my equipment prepared yet, so we will discuss that at a later time";
   }

   plugin::NPCTell($response);
}

sub EVENT_ITEM {

   if (scalar(keys %itemcount) == 1) {
      my ($item_id) = keys %itemcount;
      quest::debug("I was handed: $item_id");
   } else {
      # The hash does not contain exactly one item.
   }

  plugin::return_items(\%itemcount);
}


