use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

my $modifier        = 1.25;
my $zone_duration   = 604800;
my $zone_version    = 10;

sub HandleSay {
    my ($client, $npc, $zone_name, $explain_details, $reward, @task_id) = @_;
    my $text   = plugin::val('text');

    my $details       = quest::saylink("instance_details", 1, "details");
    my $mana_crystals = quest::saylink("mana_crystals", 1, "Mana Crystals");
    my $decrease      = quest::saylink("decrease_info", 1, "decrease");
    my $Proceed       = quest::saylink("instance_proceed", 1, "Proceed");

    my $mana_cystals_item       = quest::varlink(40903);
    my $dark_mana_cystals_item  = quest::varlink(40902);

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

                if (not plugin::HasDynamicZoneAssigned($client)) {
                    if ($task_name =~ /\(Escalation\)$/ ) {
                        $difficulty_rank++;
                    } elsif ($task_name =~ /\(Heroic\)$/ ) {
                        $heroic++;
                    }
                    
                    my %zone_info = ( "difficulty" => $difficulty_rank, "heroic" => $heroic, "minimum_level" => 100, "reward" => $reward);
                    quest::set_data("character-$task_leader_id-$zone_name", plugin::SerializeHash(%zone_info));

                    my %dz = (
                        "instance"      => { "zone" => $zone_name, "version" => $zone_version, "duration" => $zone_duration },
                        "compass"       => { "zone" => plugin::val('zonesn'), "x" => $npc->GetX(), "y" => $npc->GetY(), "z" => $npc->GetZ() },
                        "safereturn"    => { "zone" => plugin::val('zonesn'), "x" => $client->GetX(), "y" => $client->GetY(), "z" => $client->GetZ(), "h" => $client->GetHeading() }
                    );

                    $client->CreateTaskDynamicZone($task, \%dz);
                }

                plugin::NPCTell("The way before you is clear. [$Proceed] when you are ready."); 
                return;
            }
        }

        plugin::NPCTell("Adventurer. Master Theralon has provided me with a task for you to accomplish. Do you wish to hear the [$details] about it?");

        return;
    }

    if ($text eq 'debug') {
       $npc->Say("Shared Task Leader ID is: " . plugin::GetSharedTaskLeader($client));
       $npc->Say("HasDynamicZoneAssigned: " . plugin::HasDynamicZoneAssigned($client));
    }

    # From [details]
    if ($text eq 'instance_details') {
        plugin::NPCTell($explain_details);
        $client->TaskSelector(@task_id);

        plugin::YellowText("Feat of Strength instances are scaled up by completing either Escalation (Solo) or Heroic (Group) versions. You will recieve [$mana_crystals] only once per difficulty rank. You may [$decrease] your difficulty rank by spending mana crystals equal to the reward.");
        return;
    }

    # From [Proceed]
    if ($text eq 'instance_proceed') {
        $client->MovePCDynamicZone($zone_name);
    }  

    return; # Return value if needed
}

sub HandleTaskAccept
{
    my $task_id            = shift || plugin::val('task_id');
    my $task_name          = quest::gettaskname($task);
    my $mana_cystals       = quest::varlink(40903);
    my $dark_mana_cystals  = quest::varlink(40902);

    if ($task_name =~ /\(Escalation\)$/ ) {
        plugin::YellowText("You have started an Escalation task. You will recieve [$mana_crystals] and permanently increase your Difficulty Rank for this zone upon completion.");
    } elsif ($task_name =~ /\(Heroic\)$/ ) {
        plugin::YellowText("You have started a Heroic task. You will recieve [$dark_mana_cystals] and permanently increase your Heroic Difficulty Rank for this zone upon completion.");
    } else {
        plugin::YellowText("You have started an Instance task. You will recieve no additional rewards upon completion.");
    }
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

sub ModifyInstanceLoot 
{
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

    my $owner_id   = GetSharedTaskLeaderByInstance($instanceid);

    # Get the packed data for the instance
    quest::debug("Looking up character-$owner_id-$zonesn");
    my %info_bucket  = plugin::DeserializeHash(quest::get_data("character-$owner_id-$zonesn"));
    my @targetlist   = plugin::DeserializeList($info_bucket{'targets'});
    my $group_mode  = $info_bucket{'heroic'};
    my $difficulty  = $info_bucket{'difficulty'} + ($group_mode ? 5 : 0) - 1;    
    my $min_level   = $info_bucket{'minimum_level'} + min(floor($difficulty / 4), 10);
    my $reward      = $info_bucket{'reward'};    

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

    my $leader_id = $sth->fetchrow_array();
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

    my $leader_id = $sth->fetchrow_array();
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

    my $min_level = $sth->fetchrow_array();
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

    my $count = $sth->fetchrow_array();
    $sth->finish();
    $dbh->disconnect();

    return $count > 0 ? 1 : 0;
}

return 1;