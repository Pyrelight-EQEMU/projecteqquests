sub EVENT_SAY {  
  my $progress = $client->GetBucket("MAO-Progress") || 0;
  my $clientName = $client->GetCleanName();
  my $classCount = my $count = keys %{ { plugin::GetUnlockedClasses($client) } } || 1;
  my $unlocksAvailable = $client->GetBucket("ClassUnlocksAvailable") || 0;

  if ($text=~/hail/i) {     
      if ($progress <= 0) {
        my $adventurers_soul = quest::varlink(200000);
        plugin::NPCTell("Hail, $clientName. I sense the [$adventurers_soul] growing within you. Welcome to the Nexus, the best place in all the realms to start
                        your journey to [nurture] it.");
      } elsif ($client->GetLevel() >= 20 and $classCount < 2) {
        if ($unlocksAvailable < 1) {
          plugin::NPCTell("I'm happy that you've returned, $clientName. I sense that you've gained quite a bit of experience, enough for me to trust you with 
                          [additional power] and responsibility. Are you ready for your soul to properly grow?");
        } else {
          plugin::NPCTell("I've already unlocked your potential, $clientName. You only need to seize it and [choose your class].");
        }
      }      
      else {
        plugin::NPCTell("It is good to see you again, $clientName. I don't have anything for you right now, but return to me when you've gained 
                         more experience. I will have work for you.");
      }

  } elsif ($text=~/nurture/i) { 
    plugin::NPCTell("That tiny kernel within you will not sustain you yet, much less bring you the wealth and power you undoubtedly chase. You may first cause it to 
                    grow by simple exploration. There are other benefits, namely your access to the [Nexus Teleportation Network] will expand as your Soul does.");
  }
  
  elsif ($text=~/Nexus Teleportation Network/i) { #teleportation network
    plugin::NPCTell("There are wizards of the brotherhood located near each of the minor spires within the Nexus complex, they can assist you with traveling to the ".
                    "continents to which they are attuned. Only the existing Combine spires, or locations that you are already strongly familiar with, will allow a 
                    blind transit, however. There are other sites with weak dimensional barriers to which you can personally be attuned, though - you'll simply need 
                    to reach them on your own first." );
    
    my $acctMoneyFlagKey = $client->AccountID() . "-InitMoneyFlag";
    my $acctMoneyFlagValue = quest::get_data($acctMoneyFlagKey) || 0;

    if ($acctMoneyFlagValue <= 10 && $progress <= 0) {
      plugin::NPCTell("Also, take these coins. You'll need them to get started, and you can pay me back sometime if your pride demands it.");
      quest::givecash(0, 0, 0, 100);
      quest::set_data($acctMoneyFlagKey, ++$acctMoneyFlagValue);
    }
    
    $client->SetBucket("MAO-Progress",1) if $progress == 0;
    quest::message(15,"You have gained the ability to use the Nexus teleportation network.");   
  }

  elsif ($text=~/additional power/i) { 
    if ($classCount < 2) {
      plugin::NPCTell("I think that you have the potential to go far, $clientName, perhaps far enough to help me accomplish some goals that I have not yet succeeded at alone.
                      I am willing to invest in you a portion of my arcane power. This will enable you to expand your abilities and learn an [additional Class]. This will not
                      be without sacrifice, however, as you will need to start over in many respects.");
    } else {
      plugin::NPCTell("I've already assisted you with your first soul expansion, $clientName. Return when you have grown enough to serve my purposes.");
    }
  }

  elsif ($text=~/additional Class/i and $classCount < 2 and $unlocksAvailable < 1) {
    $client->Message(263, "The Grand Arcanist closes his eyes in meditation before suddenly striking your forehead with the heel of his open palm.");
    plugin::NPCTell("It is done. Let me know when you are ready to [choose your class], and I will assist you.");
    plugin::YellowText("You have gained a Class Unlock point.");
    $client->SetBucket("ClassUnlocksAvailable", 1);    
  }

  elsif ($text =~ /choose your class/i and $unlocksAvailable >= 1) {
      my @locked_classes = plugin::GetLockedClasses($client);
      my @formatted_classes;

      # Format class names
      foreach my $class (@locked_classes) {
          my $class_name = quest::getclassname($class);
          push @formatted_classes, "[$class_name]";
      }

      # Convert the array into a comma-separated string with 'and' before the last class
      my $out_string;
      if (@formatted_classes > 1) {
          $out_string = join(", ", @formatted_classes[0..$#formatted_classes-1]) . ", or " . $formatted_classes[-1];
      } else {
          $out_string = $formatted_classes[0];
      }

      quest::debug($out_string);
  }
}