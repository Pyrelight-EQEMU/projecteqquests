use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

my $modifier        = 0.10;
my $zone_duration   = 604800;
my $zone_version    = 10;

sub HandleSay {
    my ($client, $npc, $zone_name, $explain_details, $reward, @task_id) = @_;
    my $text   = plugin::val('text');

    my $details             = quest::saylink("instance_details", 1, "details");
    my $tokens_of_strength  = quest::saylink("tokens_of_strength", 1, "Tokens of Strength");
    my $decrease            = quest::saylink("decrease_info", 1, "decrease");
    my $Proceed             = quest::saylink("instance_proceed", 1, "Proceed");

    my $solo_escalation_level  = $client->GetBucket("$zone_name-solo-escalation")  || 0;
    my $group_escalation_level = $client->GetBucket("$zone_name-group-escalation") || 0;

    # TO-DO Handle this differently based on introductory flag from Theralon.
    if ($text =~ /hail/i && $npc->GetLevel() <= 70) {
        foreach my $task (@task_id) {
            if ($client->IsTaskActive($task)) {
                my $task_name       = quest::gettaskname($task);
                my $task_leader_id  = plugin::GetSharedTaskLeader($client);
                my $heroic          = 0;
                my $difficulty_rank = quest::get_data("character-$task_leader_id-$zone_name-solo-escalation") || 0;
                my $challenge       = 0; 

                if (not plugin::HasDynamicZoneAssigned($client)) {
                    if ($task_name =~ /\(Escalation\)$/ ) {
                        $difficulty_rank++;
                    } 
                    
                    if ($task_name =~ /\(Heroic\)$/ ) {                        
                        $difficulty_rank = quest::get_data("character-$task_leader_id-$zone_name-group-escalation") || 0;
                        $difficulty_rank++;
                        $heroic++;
                    }
                    
                    my %zone_info = ( "difficulty" => $difficulty_rank, "heroic" => $heroic, "minimum_level" => $npc->GetLevel());
                    quest::set_data("character-$task_leader_id-$zone_name", plugin::SerializeHash(%zone_info), $zone_duration);

                    my %dz = (
                        "instance"      => { "zone" => $zone_name, "version" => $zone_version, "duration" => $zone_duration },
                        "compass"       => { "zone" => plugin::val('zonesn'), "x" => $npc->GetX(), "y" => $npc->GetY(), "z" => $npc->GetZ() },
                        "safereturn"    => { "zone" => plugin::val('zonesn'), "x" => $client->GetX(), "y" => $client->GetY(), "z" => $client->GetZ(), "h" => $client->GetHeading() }
                    );
                    
                    $client->CreateTaskDynamicZone($task, \%dz);
                }

                my %instance_data = ("reward" => $reward, 
                                     "zone_name" => $zone_name, 
                                     "difficulty_rank" => $difficulty_rank, 
                                     "task_id" => $task, 
                                     "leader_id" => $task_leader_id);                

                my $group = $client->GetGroup();
                if($group) {
                    for ($count = 0; $count < $group->GroupCount(); $count++) {
                        $player = $group->GetMember($count);
                        if($player) {
                            $player->SetBucket("instance-data", plugin::SerializeHash(%instance_data), $zone_duration);
                        }
                    }
                } else {
                    $client->SetBucket("instance-data", plugin::SerializeHash(%instance_data), $zone_duration);
                }

                plugin::NPCTell("The way before you is clear. [$Proceed] when you are ready.");                
                return;
            }
        }

        plugin::NPCTell("Adventurer. Master Theralon has provided me with a task for you to accomplish. Do you wish to hear the [$details] about it?");

        return;
    }

    elsif ($text eq 'debug') {
       $npc->Say("Shared Task Leader ID is: " . plugin::GetSharedTaskLeader($client));
       $npc->Say("HasDynamicZoneAssigned: "   . plugin::HasDynamicZoneAssigned($client));
    }

    # From [details]
    elsif ($text eq 'instance_details') {
        plugin::NPCTell($explain_details);
        $client->TaskSelector(@task_id);

        plugin::YellowText("Feat of Strength instances are scaled up by completing either Escalation (Solo) or Heroic (Group) versions. You will recieve [$tokens_of_strength] 
                            only once per difficulty rank. You may also journey into this dungeon without challenging it, at your highest previously completed difficulty level.");
        plugin::YellowText("Difficulty Rank: $solo_escalation_level, Heroic Difficulty Rank: $group_escalation_level");
    }

    # From [Proceed]
    elsif ($text eq 'instance_proceed') {
        $client->MovePCDynamicZone($zone_name);
    }

    elsif ($text eq 'tokens_of_strength') {
        plugin::YellowText("These tokens may be exchanged with others among the Brotherhood for a variety of services. They are a scarce commodity and should be carefully guarded.");
        plugin::Display_FoS_Tokens($client);
        plugin::Display_FoS_Heroic_Tokens($client);
    }

    return; # Return value if needed
}

sub HandleTaskComplete
{
    my ($client, $task_id)        = @_;
    my %instance_data   = plugin::DeserializeHash($client->GetBucket("instance-data"));
    my $difficulty_rank = $instance_data{'difficulty_rank'};   
    my $reward          = $instance_data{'reward'};
    my $zone_name       = $instance_data{'zone_name'};
    my $task_id_stored  = $instance_data{'task_id'};
    my $leader_id       = $instance_data{'leader_id'};
    my $task_name       = quest::gettaskname($task_id);  
    my $heroic          = ($task_name =~ /\(Heroic\)$/) ? 1 : 0;
    my $escalation      = ($task_name =~ /\(Escalation\)$/) ? 1 : 0;

    my $charname = $client->GetCleanName();

    if ($task_id == $task_id_stored) {
        if ($client->CharacterID() == $leader_id) {            
            if ($heroic) {                        
                my $old_diff = $client->GetBucket("$zone_name-group-escalation") || 0;
                if ($old_diff < $difficulty_rank) {
                    plugin::WorldAnnounce("$charname has successfully challenged the $task_name (Difficulty: $difficulty_rank).");                
                    plugin::YellowText("Your Heroic Difficulty Rank has increased to $difficulty_rank.", $client);
                    plugin::Add_FoS_Heroic_Tokens($reward, $client);
                    my $group = $client->GetGroup();
                    if($group) {
                        for ($count = 0; $count < $group->GroupCount(); $count++) {
                            $player = $group->GetMember($count);
                            if($player) {
                                plugin::Add_FoS_Heroic_Tokens($reward, $client);
                            }
                        }
                    }
                        $client->SetBucket("$zone_name-group-escalation", $difficulty_rank);
                    }
                } 
            if ($escalation) {            
                my $old_diff = $client->GetBucket("$zone_name-solo-escalation") || 0;
                if ($old_diff < $difficulty_rank) {
                    plugin::WorldAnnounce("$charname has successfully challenged the $task_name (Difficulty: $difficulty_rank).");
                    plugin::YellowText("Your Difficulty Rank has increased to $difficulty_rank.", $client);
                    plugin::Add_FoS_Tokens($reward, $client);
                    $client->SetBucket("$zone_name-solo-escalation", $difficulty_rank);
                }
            }
        }
        
        $client->DeleteBucket("instance-data");
        $client->EndSharedTask();
    }
}

# Function to Add FoS Tokens
sub Add_FoS_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    $client->SetBucket("FoS-points", $curr + $amount);
    plugin::YellowText("You have earned $amount FoS Tokens. You now have a total of " . ($curr + $amount) . " FoS Tokens.");
    return $curr + $amount;
}

sub Get_FoS_Tokens {
    my $client  = shift or plugin::val('client');
    return $client->GetBucket("FoS-points") || 0;
}

sub Display_FoS_Tokens {
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    plugin::YellowText("You currently have $curr FoS Tokens.");
}

sub Spend_FoS_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    my $new_total = $curr - $amount;

    $client->SetBucket("FoS-points", $new_total);
    return $new_total;
}

# Function to Add FoS-Heroic Tokens
sub Add_FoS_Heroic_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    $client->SetBucket("FoS-Heroic-points", $curr + $amount);
    plugin::YellowText("You have earned $amount FoS-Heroic Tokens. You now have a total of " . ($curr + $amount) . " FoS-Heroic Tokens.");
    return $curr + $amount;
}

# Function to Spend FoS-Heroic Tokens
sub Spend_FoS_Heroic_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    my $new_total = $curr - $amount;

    $client->SetBucket("FoS-Heroic-points", $new_total);
    return $new_total;
}

# Function to Display FoS-Heroic Tokens
sub Display_FoS_Heroic_Tokens {
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    plugin::YellowText("You currently have $curr FoS-Heroic Tokens.");
}

# Function to Get the current amount of FoS-Heroic Tokens
sub Get_FoS_Heroic_Tokens {
    my $client = shift or plugin::val('client');
    return $client->GetBucket("FoS-Heroic-points") || 0;
}

sub HandleTaskAccept
{
    my $task_id             = shift || plugin::val('task_id');
    my $task_name           = quest::gettaskname($task_id);

    if ($task_name =~ /\(Escalation\)$/ ) {
        plugin::YellowText("You have started an Escalation task. You will recieve [Tokens of Strength] and permanently increase your Difficulty Rank for this zone upon completion.");
    } elsif ($task_name =~ /\(Heroic\)$/ ) {
        plugin::YellowText("You have started a Heroic task. You will recieve [Heroic Tokens of Strength] and permanently increase your Heroic Difficulty Rank for this zone upon completion.");
    } else {
        plugin::YellowText("You have started an Instance task. You will recieve no additional rewards upon completion.");
    }
}

sub GetInstanceLoot {
    my ($item_id, $difficulty) = @_;
    if ($difficulty > 0) {
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
    } else {
        return $item_id;
    }
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

    my $owner_id   = GetSharedTaskLeaderByInstance($instanceid);

    # Get the packed data for the instance
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));
    my $difficulty   = $info_bucket{'difficulty'} + ($group_mode ? 5 : 0) - 1;

    my @lootlist = $npc->GetLootList();
    my %changes;  # This hash will store net changes (how many of each item to add or remove)

    foreach my $item_id (@lootlist) {
        my $quantity = $npc->CountItem($item_id);
        # do this once per $quantity
        for (my $i = 0; $i < $quantity; $i++) {
            my $scaled_item = GetInstanceLoot($item_id, ($difficulty/3));
            if ($scaled_item != $item_id) {
                $changes{$item_id} = (defined $changes{$item_id} ? $changes{$item_id} - 1 : -1);
                $changes{$scaled_item} = (defined $changes{$scaled_item} ? $changes{$scaled_item} + 1 : 1);
            }
        }
    }

    # Execute changes
    for my $item (keys %changes) {
        if ($changes{$item} > 0) {
            $npc->AddItem($item, $changes{$item});
        } elsif ($changes{$item} < 0) {
            $npc->RemoveItem($item, abs($changes{$item}));
        }
    }
}

sub ModifyInstanceNPC
{
    my $client     = plugin::val('client');
    my $npc        = plugin::val('npc');
    my $zonesn     = plugin::val('zonesn');
    my $instanceid = plugin::val('instanceid');

    my $owner_id   = GetSharedTaskLeaderByInstance($instanceid);

    # Get the packed data for the instance
    my %info_bucket = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));
    my $group_mode  = $info_bucket{'heroic'};
    my $difficulty  = $info_bucket{'difficulty'} + ($group_mode ? 4 : 0) - 1;    
    my $min_level   = $info_bucket{'minimum_level'} + floor($difficulty / 3);
    my $reward      = $info_bucket{'reward'};

    my $difficulty_modifier = 1 + ($modifier * $difficulty);

    quest::debug("difficulty_modifier: $difficulty_modifier");

    # Get initial mob stat values
    my @stat_names = qw(max_hp min_hit max_hit atk mr cr fr pr dr spellscale healscale accuracy avoidance heroic_strikethrough);  # Add more stat names here if needed
    my %npc_stats;
    my $npc_stats_perlevel;

    foreach my $stat (@stat_names) {
        if ($npc->EntityVariableExists($stat)) {
            $npc_stats{$stat} = $npc->GetEntityVariable($stat);
        } else {
            $npc_stats{$stat} = $npc->GetNPCStat($stat);
            $npc->SetEntityVariable($stat, $npc_stats{$stat});
        }
    }

    foreach my $stat (@stat_names) {
        $npc_stats_perlevel{$stat} = ($npc_stats{$stat} / $npc->GetLevel());
    }

    # Rescale Levels
    if ($npc->GetLevel() < ($min_level - 6)) {
        my $level_diff = $min_level - 6 - $npc->GetLevel();

        $npc->SetLevel($npc->GetLevel() + $level_diff);
        foreach my $stat (@stat_names) {
            # Skip processing for 'spellscale' and 'healscale'
            next if ($stat eq 'spellscale' or $stat eq 'healscale');

            $npc->ModifyNPCStat($stat, $npc->GetNPCStat($stat) + ceil($npc_stats_perlevel{$stat} * $level_diff));
        }      
    }

    #Recale stats
    if ($difficulty > 0) {
        foreach my $stat (@stat_names) {
            $npc->ModifyNPCStat($stat, ceil($npc->GetNPCStat($stat) * $difficulty_modifier));            
        }
    }

    $npc->Heal();
}

sub GetSharedTaskLeader 
{
    my $client  = shift || plugin::val('client');
    my $dbh     = plugin::LoadMysql();

    my $character_id = $client->CharacterID();

    my $query = "SELECT t2.character_id
                 FROM shared_task_members t1
                 JOIN shared_task_members t2 ON t1.shared_task_id = t2.shared_task_id
                 WHERE t1.character_id = ?
                 AND t2.is_leader = 1
                 LIMIT 1";

    my $sth = $dbh->prepare($query);
    $sth->execute($character_id);

    my $leader_id = $sth->fetchrow();
    $sth->finish();
    $dbh->disconnect();

    return $leader_id;
}

sub GetSharedTaskLeaderByInstance 
{
    my $instance_id = shift || plugin::val('instanceid');
    my $dbh = plugin::LoadMysql();

    my $query = "SELECT leader_id
                 FROM dynamic_zones
                 WHERE instance_id = ?
                 LIMIT 1";

    my $sth = $dbh->prepare($query);
    $sth->execute($instance_id);

    my $leader_id = $sth->fetchrow();
    $sth->finish();
    $dbh->disconnect();

    return $leader_id;
}

sub GetMinimumLevelForTask {
    my $task_id = shift || die "Task ID is required";
    my $dbh = plugin::LoadMysql();

    my $query = "SELECT min_level
                 FROM tasks
                 WHERE id = ?
                 LIMIT 1";

    my $sth = $dbh->prepare($query);
    $sth->execute($task_id);

    my $min_level = $sth->fetchrow();
    $sth->finish();
    $dbh->disconnect();

    return $min_level;
}

sub HasDynamicZoneAssigned {
    my $client  = shift || plugin::val('client');
    my $dbh     = plugin::LoadMysql();

    my $character_id = $client->CharacterID();

    my $query = "SELECT COUNT(*) FROM dynamic_zone_members WHERE character_id = ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($character_id);

    my $count = $sth->fetchrow();
    $sth->finish();
    $dbh->disconnect();

    return $count > 0 ? 1 : 0;
}

sub GetSharedTaskMemberCount {
    my ($client)        = @_;
    my $character_id    = $client->CharacterID();
    my $dbh             = plugin::LoadMysql();

    my $query = "SELECT COUNT(DISTINCT t2.character_id) AS member_count
                 FROM shared_task_members t1
                 JOIN shared_task_members t2 ON t1.shared_task_id = t2.shared_task_id
                 WHERE t1.character_id = ?";

    my $sth = $dbh->prepare($query);
    $sth->execute($character_id);

    my $member_count = $sth->fetchrow_hashref()->{'member_count'};
    $sth->finish();
    $dbh->disconnect();

    return $member_count;
}

return 1;