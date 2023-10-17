sub EVENT_SAY {  
  my $progress = $client->GetBucket("MAO-Progress");
  my $clientName = $client->GetCleanName();

  if ($text=~/hail/i) {     
      if ($progress <= 0) {
        my $adventurers_soul = quest::varlink(200000);
        plugin::NPCTell("Hail, $clientName. I sense the [$adventurers_soul] growing within you. Welcome to the Nexus, the best place in all the realms to start
                        your journey to [nurture] it.");
      } else {
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
    
    $client->SetBucket("MAO-Progress",1);
    quest::message(15,"You have gained the ability to use the Nexus teleportation network.");   
  }
}