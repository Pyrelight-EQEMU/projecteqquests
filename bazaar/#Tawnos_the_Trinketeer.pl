sub EVENT_SAY {
   if($text=~/hail/i) {
      plugin::NPCTell("Hello!");
   }
}

sub EVENT_ITEM {
  plugin::return_items(\%itemcount);
}