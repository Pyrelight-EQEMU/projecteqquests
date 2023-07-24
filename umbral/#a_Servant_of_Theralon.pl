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
                       reach her, however, you will need to first weaken the wards within by defeating each of her lieutenants
                       in turn.";

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
                       158013,  #Kaas_Thox_Xi_Ans_Dyek
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
                plugin::YellowText("You have previously completed this challenge. You may choose to challenge it once again, or remain at your current difficulty level.");
                my $start = ($bucket > 5) ? $bucket - 4 : 1;  # If there are more than 5 levels, start from the 5th highest level
                for my $i ($start..$bucket) {
                    plugin::YellowText("[".quest::saylink("fs_ESCALATE_${i}_0", 1, "SOLO")."]"."[".quest::saylink("fs_ESCALATE_${i}_1", 1, "GROUP")."]" . "Escalation tier $i");
                }
                plugin::YellowText("[".quest::saylink("fs_ESCALATE_" . ($bucket + 1) . "_0", 1, "ESCALATE")."]");
            } else {  
                plugin::YellowText("You have not previously completed this challenge. Are you ready to [".quest::saylink("fs_ESCALATE_1_0", 1, "Attempt it")."]?")
            }
        } else {
            plugin::NPCTell("Stronger not ready yet! Come back later.");
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
                        
                if ($escalation_level <= $client->GetBucket("FoS-$dz_zone")) {
                    plugin::YellowText("NOTICE: This escalation tier is below your maximum achievement level, and will not result in Feat of Strength rewards.");
                }

                if ($group_mode) {
                    plugin::YellowText("NOTICE: This group instance will not yield Feat of Strength rewards.")
                }
                                               
                CREATE_EXPEDITION($exp_name, $exp_min, $exp_max);

                my %payload = ( level => $escalation_level, 
                                groupmode => $group_mode, 
                                targets => plugin::SerializeList(@target_list), 
                                reward => $reward, 
                                min_level => $client->GetLevel(), 
                                target_level => $target_level );

                quest::set_data("instance-$dz_zone-" . $dz->GetInstanceID(), plugin::SerializeHash(%payload), $dz_duration);
                plugin::NPCTell("Now you know what to do! [".quest::saylink("fs_enter", 1, "Ready to go")."]!?");
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