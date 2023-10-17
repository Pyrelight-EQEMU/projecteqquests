#BEGIN File: ssratemple\#Emperor_Ssraeshza_.pl (Real)

my $engaged;

sub EVENT_SPAWN {
  $engaged = 0;
  quest::settimer("EmpDepop", 1800);
  quest::setnexthpevent(90);
}

sub EVENT_TIMER {
  quest::stoptimer("EmpDepop");
  quest::signalwith(162260,3,0); #EmpCycle
  quest::depop();
}

sub EVENT_COMBAT {
  if (($combat_state == 1) && ($engaged == 0)) {
    quest::settimer("EmpDepop", 2400);
    $engaged = 1;
  }
}

sub EVENT_HP {
  my @npc_ids = (162123, 162124, 162125, 162126, 162127, 162128, 162129, 162130);
  quest::debug("HP EVENT!");
  my $selected_mob;
  for my $id (@npc_ids) {
    my $potential_mob = $entity_list->GetMobByNpcTypeID($id);
    
    # Skip if the mob doesn't exist
    next unless $potential_mob;
    
    # Get the hate list of the potential mob
    my $hate_list = $potential_mob->GetHateList();
    
    # Skip if the mob is engaged in combat (assuming GetHateList returns a non-empty array in this case)
    next if ref $hate_list eq 'ARRAY' && @$hate_list;
    
    $selected_mob = $potential_mob;
    last;
  }
  
  if ($selected_mob) {
    quest::debug("trying to wake up $selected_mob");
    # Get the list of mobs that have generated hate and are within a certain distance
    my @hate_list = $selected_mob->GetHateListByDistance();

    # Attack the first mob in the hate list (the closest one), assuming it's a player
    # (In actual code, you should check if the mob is a player before attempting to attack)    
    $selected_mob->SetBodyType(7, 1);
    $selected_mob->SetSpecialAbility(24,0);
    $selected_mob->SetSpecialAbility(25,0);
    $selected_mob->SetSpecialAbility(35,0);
    $selected_mob->Attack($hate_list[0]) if @hate_list;
  }

  quest::setnexthpevent($npc->GetHP() - 10);
}

  
sub EVENT_DEATH_COMPLETE {
  quest::emote("'s corpse says 'How...did...ugh...'");
  quest::spawn2(162210,0,0,877, -326, 408,385); # NPC: A_shissar_wraith
  quest::spawn2(162210,0,0,953, -293, 404,385); # NPC: A_shissar_wraith
  quest::spawn2(162210,0,0,953, -356, 404,385); # NPC: A_shissar_wraith
  quest::spawn2(162210,0,0,773, -360, 403,128); # NPC: A_shissar_wraith
  quest::spawn2(162210,0,0,770, -289, 403,128); # NPC: A_shissar_wraith
  quest::signalwith(162260,2,0); #EmpCycle
}

sub EVENT_SLAY {
  quest::say("Your god has found you lacking.");
}

# EOF zone: ssratemple ID: 162227 NPC: #Emperor_Ssraeshza_ (Real)
