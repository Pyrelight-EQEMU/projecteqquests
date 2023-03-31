#Lyriala the Wood Elf Ranger who has a wolf pet for some reason

sub EVENT_SAY {
  my $charKey = $client->CharacterID() . "-pet-name";
  my $storedPetName = quest::get_data($charKey);

  if ($storedPetName ~= 0) {
    plugin::NPCTell("Hello again, ". $client->GetCleanName() .". I hope that you and " $storedPetName ." are enjoying your journey.");
  } else {
    if ($text=~/hail/i) {
      quest::emote("looks up as you approach, her hand resting on the head of a beautiful wolfhound by her side.");
      plugin::NPCTell("Greetings, adventurer. I see you have a faithful companion by your side as well. It's always nice to have a [".
                      quest.saylink("pn1a",1,"companion")."] to share the journey with, isn't it?");
    } elsif ($text=~"pn1a") { #companion
      quest::emote("She smiles warmly before continuing.");
      plugin::NPCTell("I've always believed that a companion's name is important. It can say so much about them and their ".
                      "bond with their master. If you'd like, I can help you give your companion a name that truly reflects ".
                      "who they are. I can also offer a permanent naming service for a fee of 10,000 platinum. Would you be [".
                      quest.saylink("pn1b",1,"interested?")."]");
    } elsif ($text=~"pn1b") { #interested
      plugin::NPCTell("Excellent! And what would you like to name your pet? You can let me know by saying something like ".
                      "this: 'I would like to name my pet Fido'.");
    } elsif ($text=~/I would like to name my pet /i) { #I would like to name my pet*
      my $petName = substr($text,28);
      if ($petName=~/[^a-ZA-Z/i) {
        plugin::NPCTell("I don't think that name really fits. Let me know if you come up with a better idea.");
      } else {
        quest::emote("listens intently as you describe your companion, nodding thoughtfully. After a moment of ".
                    "contemplation, she nods her head.");
        plugin::NPCTell("I think you have the perfect name for your companion. It suits them so well, and I hope ".
                        "it brings you both joy on your journey together. And if you've decided to take me up on ".
                        "my offer, simply [". quest.saylink("pn1c",1,"confirm") ."] and I'll ".
                        "make sure the name is set in stone.");
      }
    } elsif ($text=~"pn1c") { #confirmed
      if ($client->GetGM() or $client->TakeMoneyFromPP(10000000, 1)) { #10,000pp
        quest::set_data($charKey, $petName);
        quest::emote("gives a satisfied nod.");
        plugin::NPCTell("Your companion's name is now set in stone, adventurer. May it always be a reflection of your bond with them.");
      } else {
        plugin::NPCTell("This is a bit awkawrd. You don't have enough money to pay my fee. Please return when ".
                        "you have 10000 platinum pieces.");
      }
    }
  }
}