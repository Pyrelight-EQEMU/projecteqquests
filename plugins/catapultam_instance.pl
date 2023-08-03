use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

my $modifier        = 1.25;

sub ProcessInstanceDialog {
    my $text   = plugin::val('text');
    my $client = plugin::val('client');
    my $npc    = plugin::val('npc');
    my $dz = undef;

    my (%args) = @_;

    # Required arguments
    my $expedition_name = $args{expedition_name};
    my $dz_zone         = $args{dz_zone};
    my $explain_message = $args{explain_message};
    my @target_list     = @{ $args{target_list} };

    quest::debug(join(", ", @target_list));

    # Optional arguments with default values
    my $reward          = $args{reward} // 1;
    my $key_required    = $args{key_required} // 0;
    my $target_level    = $args{target_level} // $npc->GetLevel();
    
    my $min_players     = $args{min_players} // 1;
    my $max_players     = $args{max_players} // 1;
    my $dz_version      = $args{dz_version} // 10;
    my $dz_duration     = $args{dz_duration} // 604800;
    my $dz_lockout      = $args{dz_lockout} // 3600;

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
                my $challenge_link = "[".quest::saylink("fs_ESCALATE_${bucket}_0", 1, "challenge")."]";

                plugin::YellowText("You have previously completed this challenge. You may choose to $challenge_link (Difficulty: $bucket) it once again, 
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

                my $reward_ineligible = ($escalation_level < $client->GetBucket("FoS-$dz_zone")) || $group_mode;

                if ($client->GetExpedition()->GetZoneID()) {
                    if ($reward_ineligible) {
                        plugin::YellowText("NOTICE: You are not challenging this zone, and will not recieve Feat of Strength rewards.");
                    } else {
                        $client->AssignTask(1000 + quest::GetZoneID($dz_zone));
                    }
                } else {
                    plugin::YellowText("NOTICE: You are currently assigned to an instance. Please leave that expedition in order to continue.");
                }                                            
                                
                if ($reward_ineligible or $client->IsTaskActive(1000 + quest::GetZoneID($dz_zone))) {
                    my %payload = ( difficulty => $escalation_level, 
                                    group_mode => $group_mode, 
                                    targets => plugin::SerializeList(@target_list), 
                                    reward => $reward_ineligible ? 0 : $reward * scalar @target_list,
                                    min_level => $target_level, 
                                    target_level => $target_level );

                    my $instance_id = CREATE_EXPEDITION($dz_zone, $dz_version, $dz_duration, $exp_name, $exp_min, $exp_max);
                    quest::set_data("instance-$dz_zone-$instance_id", plugin::SerializeHash(%payload), $dz_duration);                

                    plugin::NPCTell("Are you [".quest::saylink("fs_enter", 1, "ready to begin")."]?");
                } else {
                    plugin::YellowText("NOTICE: Unable to add task. End your current task before attempting this activity.");
                }
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
    my ($dz_zone, $dz_version, $dz_duration, $exp_name, $exp_min, $exp_max) = @_;
    
    my $client = plugin::val('client');
    my $x      = plugin::val('x');
    my $y      = plugin::val('y');
    my $z      = plugin::val('z');
    my $zoneid = plugin::val('zoneid');
    
    $dz = $client->CreateExpedition($dz_zone, $dz_version, $dz_duration, $exp_name, $exp_min, $exp_max);
    #$client->CreateTaskDynamicZone(int task_id, reference table_ref);
    $dz->SetCompass(quest::GetZoneShortName($zoneid), $x, $y, $z);
    $dz->SetSafeReturn(quest::GetZoneShortName($zoneid), $client->GetX(), $client->GetY(), $client->GetZ(), $client->GetHeading());

    return $dz->GetInstanceID();
}

sub GetInstanceLoot {
    my ($item_id, $difficulty) = @_;
    my $max_points = ceil(3 * ($difficulty - 1)) + 1;
    my $points = ceil($difficulty + rand($max_points - $difficulty + 1));
    
    my $rank = int(log($points) / log(2));

    # 50% chance to downgrade by 1 rank, but not lower than 0
    if (rand() < 0.25 && $rank > 1) {
        $rank--;
    }
    
    # 5% chance to upgrade by 1 rank, but not higher than 50
    elsif (rand() < 0.05 && $rank < 50) {
        $rank++;
    }

    if ($rank <= 0) {
        return $item_id;
    }

    return GetScaledLoot($item_id, $rank);
}

sub GetScaledLoot {
    my ($item_id, $rank) = @_;
    
    my $new_item_id = $item_id + (1000000 * $rank);

    my $new_item_name = quest::getitemname($new_item_id);

    # Check if $new_item_name is 'INVALID ITEM ID IN GETITEMNAME'
    if ($new_item_name eq 'INVALID ITEM ID IN GETITEMNAME') {
        return $item_id;
    }

    return $new_item_id;
}

sub ModifyInstanceLoot {
    my $client     = plugin::val('client');
    my $npc        = plugin::val('npc');
    my $zonesn     = plugin::val('zonesn');
    my $instanceid = plugin::val('instanceid');

    # Get the packed data for the instance
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("instance-$zonesn-$instanceid"));
    my $difficulty   = $info_bucket{'difficulty'} + ($group_mode ? 5 : 0) - 1;
    my $reward       = $info_bucket{'reward'};

    my @lootlist = $npc->GetLootList();
    my @inventory;
    foreach my $item_id (@lootlist) {
        my $quantity = $npc->CountItem($item_id);
        # do this once per $quantity
        for (my $i = 0; $i < $quantity; $i++) {
            my $scaled_item = GetInstanceLoot($item_id, $difficulty);
            if ($scaled_item != $item_id) {
                $npc->RemoveItem($item_id, 1);
                $npc->AddItem($scaled_item);
            }
        }
    }
}

sub ModifyInstanceNPC
{
    my $client     = plugin::val('client');
    my $npc        = plugin::val('npc');
    my $zonesn     = plugin::val('zonesn');
    my $instanceid = plugin::val('instanceid');

    # Get the packed data for the instance
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("instance-$zonesn-$instanceid"));
    my @targetlist   = plugin::DeserializeList($info_bucket{'targets'});
    my $group_mode  = $info_bucket{'group_mode'};
    my $difficulty  = $info_bucket{'difficulty'} + ($group_mode ? 5 : 0) - 1;
    my $reward      = $info_bucket{'reward'};    
    my $min_level   = $info_bucket{'min_level'} + min(floor($difficulty / 4), 10);

    # Get initial mob stat values
    my @stat_names = qw(max_hp min_hit max_hit atk mr cr fr pr dr spellscale healscale accuracy avoidance heroic_strikethrough);  # Add more stat names here if needed
    my %npc_stats;
    my $npc_stats_perlevel;

    foreach my $stat (@stat_names) {
        $npc_stats{$stat} = $npc->GetNPCStat($stat);
    }

    $npc_stats{'spellscale'} = 100 + ($difficulty * $modifier);
    $npc_stats{'healscale'}  = 100 + ($difficulty * $modifier);

    foreach my $stat (@stat_names) {
        $npc_stats_perlevel{$stat} = ($npc_stats{$stat} / $npc->GetLevel());
    }

    #Rescale Levels
    if ($npc->GetLevel() < ($min_level - 6)) {
        my $level_diff = $min_level - 6 - $npc->GetLevel();

        $npc->SetLevel($npc->GetLevel() + $level_diff);
        foreach my $stat (@stat_names) {
            $npc->ModifyNPCStat($stat, $npc->GetNPCStat($stat) + ceil($npc_stats_perlevel{$stat} * $level_diff));
        }        
    }

    #Recale stats
    if ($difficulty > 0) {
        foreach my $stat (@stat_names) {
            $npc->ModifyNPCStat($stat, ceil($npc->GetNPCStat($stat) * $difficulty * $modifier));
        }
    }

    $npc->Heal();
}

sub CheckInstanceMerit
{
    my $client     = plugin::val('client');
    my $npc        = plugin::val('npc');
    my $zonesn     = plugin::val('zonesn');
    my $instanceid = plugin::val('instanceid');

    # Get the packed data for the instance
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("instance-$zonesn-$instanceid"));
    my @targetlist   = plugin::DeserializeList($info_bucket{'targets'});
    my $group_mode   = $info_bucket{'group_mode'};
    my $difficulty   = $info_bucket{'difficulty'} - 1;
    my $reward       = $info_bucket{'reward'};    
    my $min_level    = $info_bucket{'min_level'} + min(floor($difficulty / 5), 10);

    if ($reward > 0) {
        my $npc_name = $npc->GetCleanName();
        my $removed = 0;
        @targetlist = grep { 
            if ($_ == $npc->GetNPCTypeID() && !$removed) { 
                $removed = 1; 
                0;
            } else { 
                1;
            } 
        } @targetlist;

        if ($removed) {
            #repack the info bucket
            $info_bucket{'targets'} = plugin::SerializeList(@targetlist);
            quest::set_data("instance-$zonesn-$instanceid", plugin::SerializeHash(%info_bucket), $client->GetExpedition->GetSecondsRemaining());
            
            my $remaining_targets = scalar @targetlist;
            if ($remaining_targets) {                
                plugin::YellowText("You've slain $npc_name! Your Feat of Strength is closer to completion. There are $remaining_targets targets left.");
            } else {
                my $FoS_points = $client->GetBucket("FoS-points") + $info_bucket{'reward'};
                my $itm_link = quest::varlink(40903);
                $client->SetBucket("FoS-points",$FoS_points);
                $client->SetBucket("FoS-$zonesn", $difficulty + 2);
                plugin::YellowText("You've slain $npc_name! Your Feat of Strength has been completed! You have earned $reward [$itm_link]. You may leave the expedition to be ejected from the zone after a short time.");
                $client->AddCrystals($reward, 0);
                plugin::WorldAnnounce($client->GetCleanName() . " (Level ". $client->GetLevel() . " ". $client->GetClassName() . ") has completed the Feat of Strength: $zoneln (Difficulty: " . ($difficulty + 1) . ").");
            }
            #quest::debug("Updated Targets: " . join(", ", @targetlist));
        }
    }
}

sub RefreshTaskStatus
{
    my $client = plugin::val('client');

    my $dz     = $client->GetExpedition();
    my $dz_id  = undef;

    if ($dz) {
        $dz_id = $dz->GetDynamicZoneID();
    }

    for my $i (1..999) {
        if ($client->IsTaskActive(1000 + $i) and not $dz_id == $i) {
            $client->FailTask(1000 + $i);
        }        
    }
}

return 1;