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

    #plugin::CheckLevelFlags();
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
}