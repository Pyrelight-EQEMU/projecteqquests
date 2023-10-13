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
}

sub EVENT_ITEM { 
    plugin::return_items(\%itemcount); 
}

