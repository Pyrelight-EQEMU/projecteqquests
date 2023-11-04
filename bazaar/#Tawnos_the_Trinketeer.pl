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
    my @epics      = (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034);

   foreach my $item_id (keys %itemcount) {
      if ($item_id != 0 && $item_id <= 110000000) {        
         
         my $base_id    = plugin::get_base_id($item_id);
         my $item_name  = quest::getitemname($item_id);
         my $special    = grep { $_ == $base_id } @epics ? 1 : 0;

         quest::debug("I was handed: $item_id with a count of $itemcount{$item_id}, $base_id:$special");

         my @ornament;

         if ($special) {
            @ornament = GetOrnamentsForEpic($base_id);
            plugin::NPCTell("Oh my! This is an absolute relic. I believe that I can create a Glamour-Stone without destroying this item, if I try hard enough... Let's see..");
         } elsif (plugin::item_exists_in_db($base_id + 200000000)) {            
            push @ornament, ($base_id + 200000000)
         } else {
            plugin::NPCTell("I don't know how to convert $item_name into a Glamour-Stone, $clientName");
         }

         if (@ornament) {
            if ($total_money >= (5000 * 1000)) { # 5000 platinum
               for my $item (@ornament) {
                  $client->SummonItem($item);
               }
               $total_money -= (5000 * 1000);
               plugin::NPCTell("Here you, go, $clientName!"); 
               delete $itemcount{$item_id};
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

sub GetOrnamentsForEpic {
   my ($item_id) = @_;  # Get the input item_id

   my %ornaments_map = (
      5532  => [127916],         # Cleric
      8495  => [127964, 127914], # Beastlord
      10099 => [127923],         # Paladin
      10650 => [127918],         # Enchanter
      10651 => [127926],         # Shaman
      14383 => [127927],         # Shadowknight
      20488 => [127924, 127963], # Ranger
      20490 => [127917],         # Druid
      20544 => [127921],         # Necromancer
      28034 => [127919],         # Magician
   );

   # Check if the item_id exists in the map
   if (exists $ornaments_map{$item_id}) {
      # Return the array reference directly
      return @{ $ornaments_map{$item_id} };
   } else {
      # If the item_id does not exist, return an empty array or handle the error as desired
      return ();  # or die "Item ID not found";
   }
}