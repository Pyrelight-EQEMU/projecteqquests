my $expedition_name = "Feat of Strength: Vex Thal";
my $dz_zone         = "vexthal";
my $reward          = 3;
my $dz = undef;
my $min_players     = 1;
my $max_players     = 1;
my $dz_version      = 10;
my $dz_duration     = 604800; # 7 Days
my $dz_lockout      = 3600; # 1 Hour
my $explain_message = "Ahead lies Vex Thal, the last city of the Akheva. The Master requires the magical essence of Aten Ha Ra, 
                       the last High Priestess of Luclin, in order to complete the ritual to restore his true power. In order to
                       reach her, however, you will need to first weaken her absolute power within her demenes by defeating 
                       each of her lieutenants in turn.";

#Array of npc_type IDs that we need to kill. Add multiple times for quantity.
my @target_list     = (158016,  #Thall_Va_Xakra
                       158016,  #Thall_Va_Xakra
                       158013,  #Kaas_Thox_Xi_Ans_Dyek
                       158014,  #Diabo_Xi_Va
                       158015,  #Diabo_Xi_Xin
                       158012,  #Diabo_Xi_Xin_Thall
                       158008,  #Thall_Va_Kelun
                       158010,  #Diabo_Xi_Va_Temariel
                       158011,  #Thall_Xundraux_Diabo
                       158009,  #Va_Xi_Aten_Ha_Ra
                       158007,  #Kaas_Thox_Xi_Aten_Ha_Ra
                       158007,  #Kaas_Thox_Xi_Aten_Ha_Ra
                       158006); #Aten_Ha_Ra                    
my $target_level    = 60;
my $key_required    = 22198;

sub EVENT_SAY {
    if ($text =~ /hail/i ) {
        $dz = $client->GetExpedition();
        if ($key_required == 0 or $client->KeyRingCheck($key_required) or plugin::check_hasitem($client, $key_required)) {
            if ($dz && ($dz->GetName() eq $expedition_name || $dz->GetName() eq $expedition_name . ' (Heroic)')) {
                plugin::NPCTell("Adventurer, your [".quest::saylink("fs_2", 1, "task")."] remains unfulfilled. Do you wish to [".quest::saylink("fs_enter", 1, "continue")."] it?");
            } else {
                plugin::NPCTell("Greetings, adventurer! I am a servant of Master Theralon, sent here to set you upon your [".quest::saylink("fs_explain", 1, "task")."].");
            }
        }      
    }

    elsif ($text =~ /fs_2/i) {
        plugin::NPCTell($explain_message . " Are you [".quest::saylink("fs_enter", 1, "ready to begin")."]?");
    }

    elsif (($text =~ /\bfs_explain\b/i)) {        
        if (!(keys %{$client->GetExpeditionLockouts($expedition_name)})) {
            plugin::NPCTell($explain_message);
            if (my $bucket = $client->GetBucket("FoS-$dz_zone")) {
                my $solo_link = "[".quest::saylink("fs_ESCALATE_${bucket}_0", 1, "current difficulty")."]";
                my $group_link = "[".quest::saylink("fs_ESCALATE_${bucket}_1", 1, "group")."]";
                my $challenge_link = "[".quest::saylink("fs_ESCALATE_" . ($bucket + 1) . "_0", 1, "challenge")."]";

                plugin::YellowText("You have previously completed this challenge. You may choose to $challenge_link it once again, 
                                    remain at your $solo_link level, or attempt it as $group_link.");
            } else {  
                plugin::YellowText("You have not previously completed this challenge. Are you ready to [".quest::saylink("fs_ESCALATE_1_0", 1, "Attempt it")."]?")
            }
        } else {
            plugin::NPCTell("I must muster my strength in order to open the portal.");
            #TODO - Print Lockout with plugin::YellowText here.
        }
    }

    elsif ($text =~ /^fs_ESCALATE_(\d+)_(0|1)$/i) {
        my $level = $1;
        my $group_mode = $2;

        my $bucket = $client->GetBucket("FoS-$dz_zone");
        my $exp_name = $group_mode ? "$expedition_name (Heroic)" : $expedition_name;
        my $exp_min = $group_mode ? 2 : 1;
        my $exp_max = $group_mode ? 6 : 1;
        if ($group_mode && !$client->IsGrouped()) {
            plugin::YellowText("ERROR: You are not in a group.");
        } else {
            if ($level <= ($bucket + 1)) {
                $escalation_level = $level || 1;

                my $reward_ineligible = ($escalation_level <= $client->GetBucket("FoS-$dz_zone")) || $group_mode;

                if ($reward_ineligible) {
                    plugin::YellowText("NOTICE: You are not challenging this zone, and will not recieve Feat of Strength rewards.");
                }
                                               
                CREATE_EXPEDITION($exp_name, $exp_min, $exp_max);

                my %payload = ( difficulty => $escalation_level, 
                                group_mode => $group_mode, 
                                targets => plugin::SerializeList(@target_list), 
                                reward => $reward_ineligible ? 0 : $reward * scalar @target_list,
                                min_level => $client->GetLevel(), 
                                target_level => $target_level );

                quest::set_data("instance-$dz_zone-" . $dz->GetInstanceID(), plugin::SerializeHash(%payload), $dz_duration);
                plugin::NPCTell("Are you [".quest::saylink("fs_enter", 1, "ready to begin")."]?");
            }
        }
    } 
    
    elsif (($text =~ /\bfs_enter\b/i)) {
        $dz = $client->GetExpedition();
        if ($dz && ($dz->GetName() eq $expedition_name || $dz->GetName() eq $expedition_name . ' (Heroic)')) {
            $dz->AddReplayLockout(plugin::GetLockoutTime());
            $client->MovePCDynamicZone($dz_zone);
        }
    }
}

sub CREATE_EXPEDITION {    
    my $client = $entity_list->GetClientByID($userid);
    $dz = $client->CreateExpedition($dz_zone, $dz_version, $dz_duration, shift,shift,shift);
    $dz->SetCompass(quest::GetZoneShortName($zoneid), $x, $y, $z);
    $dz->SetSafeReturn(quest::GetZoneShortName($zoneid), $client->GetX(), $client->GetY(), $client->GetZ(), $client->GetHeading()); 
}