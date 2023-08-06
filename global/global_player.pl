#function event_connect(e)
#   don.fix_invalid_faction_state(e.self)
#
#	check_level_flag(e)
#	e.self:GrantAlternateAdvancementAbility(938, 8, true)
#
#	check_class_switch_aa(e)
#
#	local bucket = e.self:GetBucket("FirstLoginAnnounce")
#	if (not bucket or bucket == "") and e.self:GetLevel() == 1 then
#	  e.self:SetBucket("FirstLoginAnnounce", "1")
#	  eq.world_emote(15, e.self:GetCleanName() .. " has logged in for the first time!")
#	  eq.discord_send("ooc", e.self:GetCleanName() .. " has logged in for the first time!")
#	end
#end

sub EVENT_CONNECT {
    # Grant Max Eyes Wide Open AA
    $client->GrantAlternateAdvancementAbility(938, 8, true);    

    plugin::CheckLevelFlags();
    plugin::CheckClassAA($client);

    my $bucket_value = $client->GetBucket("FirstLoginAnnounce");
    quest::debug("BucketVal:$bucket_value");

    if (not $client->GetBucket("FirstLoginAnnounce")) {
        my $name  = $client->GetCleanName();
        my $level = $client->GetLevel();
        my $class = quest::getclassname($client->GetClass(), $level);

        plugin::WorldAnnounce("$name (Level $level $class) has logged in for the first time!");
        
        $client->SetBucket("FirstLoginAnnounce", "Yup");
    }

    quest::debug("test");
}

#function event_level_up(e)
#  local free_skills =  {0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76};
#
#  for k,v in ipairs(free_skills) do
#    if ( e.self:MaxSkill(v) > 0 and e.self:GetRawSkill(v) < 1 and e.self:CanHaveSkill(v) ) then 
#      e.self:SetSkill(v, 1);
#    end      
#  end
#
#  if (e.self:GetLevel() % 5 == 0) then
#	eq.world_emote(15,e.self:GetCleanName() .. " has reached level " .. e.self:GetLevel() .. "!")
#	eq.discord_send("ooc", e.self:GetCleanName() .. " has reached level " .. e.self:GetLevel() .. "!")
#  end
#end

sub EVENT_LEVEL_UP {
    my $free_skills = [0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76];

    foreach my $skill (@$free_skills) {
        if ($client->MaxSkill($skill) > 0 && $client->GetRawSkill($skill) < 1 && $client->CanHaveSkill($skill)) {
            $client->SetSkill($skill, 1);
        }
    }

    if ($client->GetLevel() % 5 == 0) {
        my $name  = $client->GetCleanName();
        my $level = $client->GetLevel();

        my $announceString = "$name has reached level $level!";

        plugin::WorldAnnounce($announceString);
    }
}
