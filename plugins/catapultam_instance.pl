use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

my $modifier        = 0.25;
my $zone_duration   = 604800;
my $zone_version    = 10;

sub HandleTaskAccept
{
    my $task_id             = shift || plugin::val('task_id');
    my $task_name           = quest::gettaskname($task_id);
    my $type                = 0;
    my $target_difficulty   = 0;
    my $client              = shift || plugin::val('client');
    my $zone_name           = $client->GetBucket("temp-zone-cache");
    my $menu_string;
    my @difficulties;
    

    if ($task_name =~ /\(Escalation\)$/ ) {
        $type = 1;
        $target_difficulty  = $client->GetBucket("$zone_name-solo-escalation") || 0;
        $target_difficulty++;

        plugin::YellowText("You have started an Escalation task. You will recieve [Tokens of Strength] and permanently increase your Difficulty Rank for this zone upon completion.");
        
    } elsif ($task_name =~ /\(Heroic\)$/ ) {
        $type = 2;
        $target_difficulty  = $client->GetBucket("$zone_name-group-escalation") || 0;
        $target_difficulty++;

        plugin::YellowText("You have started a Heroic task. You will recieve [Heroic Tokens of Strength] and permanently increase your Heroic Difficulty Rank for this zone upon completion.");        
    } else {
        plugin::YellowText("You have started an Instance task. You will recieve no additional rewards upon completion.");
    }

    if ($type > 0) {
        @difficulties       = grep { $_ > 0 } ($target_difficulty .. $target_difficulty + 4);

        plugin::YellowText("Would you like to adjust your difficulty? You must select an option below before any further action.");
    } else {
        @difficulties       = grep { $_ > 0 } ($target_difficulty - 4 .. $target_difficulty);
    }

    foreach my $difficulty (@difficulties) {
        $menu_string .= "[ ".quest::saylink("select_diff_$difficulty", 1, "$difficulty")." ]";
    }

    plugin::YellowText("Select: " . $menu_string);
}

sub HandleSay {
    my ($client, $npc, $zone_name, $explain_details, $reward, @task_id) = @_;
    my $text   = plugin::val('text');

    my $details             = quest::saylink("instance_details", 1, "details");
    my $tokens_of_strength  = quest::saylink("tokens_of_strength", 1, "Tokens of Strength");
    my $decrease            = quest::saylink("decrease_info", 1, "decrease");
    my $Proceed             = quest::saylink("instance_proceed", 1, "Proceed");

    my $solo_escalation_level  = $client->GetBucket("$zone_name-solo-escalation")  || 0;
    my $group_escalation_level = $client->GetBucket("$zone_name-group-escalation") || 0;

    my $escalation_target      = $client->GetBucket("Escalation-Target") || 0;

    my $selected_difficulty;

    # TO-DO Handle this differently based on introductory flag from Theralon.
    if ($text =~ /hail/i || $text =~ /^select_diff_(\d+)$/) {
        if ($text =~ /^select_diff_(\d+)$/) {
            $selected_difficulty = $1;
            plugin::YellowText("You have selected Difficulty: $selected_difficulty");
        }
        foreach my $task (@task_id) {
            if ($client->IsTaskActive($task)) {
                if (!plugin::HasDynamicZoneAssigned($client)) {
                    my $task_name       = quest::gettaskname($task);
                    my $task_leader_id  = plugin::GetSharedTaskLeader($client);
                    my $heroic          = 0;
                    my $difficulty_rank = quest::get_data("character-$task_leader_id-$zone_name-solo-escalation") || 0;
                    my $challenge       = 0; 

                    if (not plugin::HasDynamicZoneAssigned($client)) {
                        if ($task_name =~ /\(Escalation\)$/ ) {
                            $difficulty_rank++;

                            if ($selected_difficulty > $difficulty_rank) {
                                $difficulty_rank = $selected_difficulty;
                            }
                        } 
                        
                        elsif ($task_name =~ /\(Heroic\)$/ ) {                        
                            $difficulty_rank = quest::get_data("character-$task_leader_id-$zone_name-group-escalation") || 0;
                            $difficulty_rank++;
                            $heroic++;

                            if ($selected_difficulty > $difficulty_rank) {
                                $difficulty_rank = $selected_difficulty;
                            }
                        }

                        else {
                            if ($selected_difficulty < $difficulty_rank) {
                                $difficulty_rank = $selected_difficulty;
                            }
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

                    my %instance_data = ("reward"           => $reward, 
                                        "zone_name"         => $zone_name, 
                                        "difficulty_rank"   => $difficulty_rank, 
                                        "task_id"           => $task, 
                                        "leader_id"         => $task_leader_id,
                                        "entered"           => 0);                

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
        $client->SetBucket("temp-zone-cache", $zone_name);
        $client->DeleteBucket("$zone_name-override-escalation");
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

sub HandleEnterZone
{
    my $client     = plugin::val('client');
    my $npc        = plugin::val('npc');
    my $zonesn     = plugin::val('zonesn');
    my $instanceid = plugin::val('instanceid');

    my $owner_id   = GetSharedTaskLeaderByInstance($instanceid);

    # Get the packed data for the instance
    my %info_bucket = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));

    #omg this is ugly.
    if (!$info_bucket{'entered'}) {        
        quest::repopzone();
        $info_bucket{'entered'} = 1;
        $client->SetBucket("instance-data", plugin::SerializeHash(%info_bucket), 604800);
    }
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
    quest::debug("checkpoint 0; $difficulty_rank $reward $zone_name $task_id_stored $leader_id $task_name $heroic $escalation");

    if ($task_id == $task_id_stored) {
        quest::debug("checkpoint 1");
        if ($client->CharacterID() == $leader_id) {
             quest::debug("checkpoint 2");            
            if ($heroic) {                        
                my $old_diff = $client->GetBucket("$zone_name-group-escalation") || 0;
                if ($old_diff < $difficulty_rank) {
                    plugin::WorldAnnounce("$charname has successfully challenged the $task_name (Difficulty: $difficulty_rank).");                
                    plugin::YellowText("Your Heroic Difficulty Rank has increased to $difficulty_rank.", $client);
                    plugin::Add_FoS_Heroic_Tokens($reward, $client);
                    $client->SetBucket("$zone_name-group-escalation", $difficulty_rank);
                    my $group = $client->GetGroup();
                    if($group) {
                        for ($count = 0; $count < $group->GroupCount(); $count++) {
                            $player = $group->GetMember($count);
                            if($player) {
                                plugin::Add_FoS_Heroic_Tokens($reward, $client);
                            }
                        }
                    }                    
                }
            } 
            if ($escalation) { 
                quest::debug("checkpoint 3");           
                my $old_diff = $client->GetBucket("$zone_name-solo-escalation") || 0;
                if ($old_diff < $difficulty_rank) {
                    quest::debug("checkpoint 4");
                    plugin::WorldAnnounce("$charname has successfully challenged the $task_name (Difficulty: $difficulty_rank).");
                    plugin::TrySetLeaderForZone($task_name, $charname, $difficulty_rank);
                    plugin::YellowText("Your Difficulty Rank has increased to $difficulty_rank.", $client);
                    plugin::Add_FoS_Tokens($reward, $client);
                    $client->SetBucket("$zone_name-solo-escalation", $difficulty_rank);
                }
            }
        }
        
        $client->DeleteBucket("instance-data");
        #$client->EndSharedTask();
    }
}

sub GetLeaderForZone {
    my $zone        = shift or return;
    my $leader      = quest::get_data("$zone-TopDiff");    

    if (!$leader || $leader eq '') {
        return ("None", 0);
    } 

    my %leader_data = plugin::DeserializeHash($leader);

    return ($leader_data{'player'}, $leader_data{'score'});    
}

sub SetLeaderForZone {
    my ($zone, $player, $score) = @_;
        
    my %leader_data = (
        'player' => $player,
        'score'  => $score
    );
    
    my $data = plugin::SerializeHash(%leader_data);
    
    quest::set_data("$zone-TopDiff", $data);
}

sub TrySetLeaderForZone {
    my ($zone, $player, $score) = @_;

    # Get the current top score and player for the zone.
    my ($current_leader, $current_score) = GetLeaderForZone($zone);

    # Check if the new score is higher than the current top score.
    if ($score > $current_score) {
        # If so, set the new player and score as the top score.
        SetLeaderForZone($zone, $player, $score);
        if ($current_leader ne 'None' and $current_leader ne $player) {
            plugin::WorldAnnounce("$player surpassed $current_leader as the undisputed champion of $zone.");
        } elsif ($current_leader eq $player) {
            plugin::WorldAnnounce("$player has solidified their lead as the undisputed champion of $zone.");
        } else {
            plugin::WorldAnnounce("$player has become the undisputed champion of $zone.");
        }
        return 1;  # Return true indicating the top score was updated.
    } elsif ($score == $current_score) {
        plugin::WorldAnnounce("$player has tied with $current_leader to be the champion of $zone.");
    }

    return 0;  # Return false indicating the top score was not updated.
}

sub Add_AA_Reward {
    my $amount = shift or return;
    my $client = shift or plugin::val('client');

    $client->AddAAPoints($amount);
    $client->Message(334, "You have gained $amount Alternate Experience points as a bonus reward!");    
}

sub upgrade_item_corpse {
    my ($item_id, $tier, $corpse)  = @_;
    if (plugin::is_item_upgradable($item_id)) {
        my $base_id    = plugin::get_base_id($item_id);
        my $curtier    = plugin::get_upgrade_tier($item_id);

        my $target_tier = min(10, $tier + $curtier);
        my $target_item = $base_id + (1000000 * $target_tier);
        quest::debug("base: $base_id, target: $target_item, tier: $tier, curtier: $curtier");
        if (plugin::item_exists_in_db($target_item)) {
            if ($corpse && $corpse->CountItem($item_id)) {            
                $corpse->RemoveItemByID($item_id,);
            } else {quest::debug("The corpse didn't exist?");} 
            quest::debug("adding $target_item to $corpse");           
            $corpse->AddItem($target_item, 1);
        } 
    } else {
        quest::debug("item: $item_id was not upgradable");
    }
}

sub upgrade_item_npc {
    my ($item_id, $tier, $npc)  = @_;
    if (plugin::is_item_upgradable($item_id)) {
        my $base_id    = plugin::get_base_id($item_id);
        my $curtier    = plugin::get_upgrade_tier($item_id);

        my $target_tier = min(10, $tier + $curtier);
        my $target_item = $base_id + (1000000 * $target_tier);
        quest::debug("base: $base_id, target: $target_item, tier: $tier, curtier: $curtier");
        if (plugin::item_exists_in_db($target_item)) {
            if ($npc && $npc->CountItem($item_id)) {            
                $npc->RemoveItem($item_id,);
            } else {quest::debug("The npc didn't exist?");} 
            quest::debug("adding $target_item to $npc");           
            $npc->AddItem($target_item);
        } 
    } else {
        quest::debug("item: $item_id was not upgradable");
    }
}

sub ModifyInstanceLoot {
    my $npc         = shift or return;
    my $client      = plugin::val('client');
    my $zonesn      = plugin::val('zonesn');
    my $instanceid  = plugin::val('instanceid');

    # Get the packed data for the instance
    my $owner_id     = GetSharedTaskLeaderByInstance($instanceid);    
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));
    my $difficulty   = $info_bucket{'difficulty'};

    if ($npc) {
        my @lootlist = $npc->GetLootList();
        my $upgrade_base = floor($difficulty/3);

        foreach my $item_id (@lootlist) {
            # Get the count of this item ID in the loot
            my $item_count = $npc->CountItem($item_id);
            my $item_type  = quest::getitemstat($item_id, 'itemtype') == 54;

            quest::debug("item:$item_id, count:$item_count, difficulty:$difficulty");

            for (my $i = 0; $i < $item_count; $i++) {
                $upgrade_base = ($item_type) ? int(rand($upgrade_base + 1)) : $upgrade_base;
                plugin::upgrade_item_npc($item_id, $upgrade_base, $npc);
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

    my $owner_id   = GetSharedTaskLeaderByInstance($instanceid);

    # Get the packed data for the instance
    my %info_bucket = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));
    my $group_mode  = $info_bucket{'heroic'};
    my $difficulty  = $info_bucket{'difficulty'} + ($group_mode ? 4 : 0);    
    my $min_level   = $info_bucket{'minimum_level'} + floor($difficulty / 3);
    my $reward      = $info_bucket{'reward'};

    

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
            my $difficulty_modifier = 1 + ($modifier * $difficulty);
            if      (grep { $_ eq $stat } ('hp')) {
                $difficulty_modifier *= 1.5;
            } elsif (grep { $_ eq $stat } ('fr', 'cr', 'mr', 'dr', 'pr')) {
                $difficulty_modifier /= 2;
            }

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