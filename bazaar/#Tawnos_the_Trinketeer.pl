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

   }

   elsif ($text eq "link_custom") {
$response = "I can make magical trinkets which are imbued with the core enchantment of an existing artifact. 
             When applied to other artifacts as augments, these trinkets impart some degree of the original's power, 
             as well as allowing the augmented artifact to act as a focus or use the abilities of the original artifact. 
             Unfortunately, right now I am so backed up that I cannot possibly take on any extra work like this, 
             not unless you have $link_voucher.";
   }

   plugin::NPCTell($response);
}

sub EVENT_ITEM {
  plugin::return_items(\%itemcount);
}