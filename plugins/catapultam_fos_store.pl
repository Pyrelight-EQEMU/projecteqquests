use List::Util qw(max);
use List::Util qw(min);
use POSIX;
use DBI;
use DBD::mysql;
use JSON;

sub get_equipment_index {umbral = (
        '33407' => '5',
        '33408' => '5',
        '33409' => '5',
        '33410' => '5',
        '33411' => '5',  
        '33418' => '5',
        '33428' => '5',
        '33429' => '5',
        '33430' => '5',
        '33434' => '5'
    );

    my %equipment_index = (
        'Umbral Seals' => \%umbral_seals
    );

    return \%equipment_index;
}

sub RejectBuy {
    my $client      = plugin::val('client');
    my $charname    = $client->GetCleanName(); 

    plugin::NPCTell("I'm sorry, $charname. You don't have enough [". quest::saylink("task", 1, "Tokens") ."] to afford that.");
}

sub ApplyExpPenalty {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0) * 0.75;

    $client->SetEXPModifier(0, $expRate);
    $client->SetAAEXPModifier(0, $expRate);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your experience rate has decreased to $percentage_expRate%%.");
}

sub ApplyExpBonus {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0) / 0.75;

    $client->SetEXPModifier(0, $expRate);
    $client->SetAAEXPModifier(0, $expRate);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your experience rate has increased to $percentage_expRate%%.");
}

sub DisplayExpRate {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your current experience rate is $percentage_expRate%%.");
}

sub find_item_details {
    my ($client, $item_id) = @_;
    my %result;

    # Get equipment index reference from the plugin
    my $equipment_ref = plugin::get_equipment_index();

    # Loop through the main equipment categories
    for my $category (keys %{$equipment_ref}) {
        my $subhash = $equipment_ref->{$category};

        # If the item_id exists in the subhash
        if (exists $subhash->{$item_id}) {
            $result{'equipment'} = $category;
            $result{'value'} = $subhash->{$item_id};           
            return \%result;  # Return a reference to the hash
        }
    }

    # Return undef if item not found
    return undef;
}

# Function to Add FoS Tokens
sub Add_FoS_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    $client->SetBucket("FoS-points", $curr + $amount);
    plugin::YellowText("You have earned $amount Feat of Strength Tokens.");
    return $curr + $amount;
}

sub Get_FoS_Tokens {
    my $client  = shift or plugin::val('client');
    return $client->GetBucket("FoS-points") || 0;
}

sub Display_FoS_Tokens {
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    plugin::YellowText("You currently have $curr Feat of Strength Tokens.");
}

sub Spend_FoS_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-points") || 0;

    my $new_total = $curr - $amount;

    plugin::YellowText("You have SPENT $amount Feat of Strength tokens. You have $new_total remaining.");    
    $client->SetBucket("FoS-points", $new_total);
    return $new_total;
}

# Function to Add FoS-Heroic Tokens
sub Add_FoS_Heroic_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    $client->SetBucket("FoS-Heroic-points", $curr + $amount);
    plugin::YellowText("You have earned $amount Heroic Feat of Strength Tokens.");
    return $curr + $amount;
}

# Function to Spend FoS-Heroic Tokens
sub Spend_FoS_Heroic_Tokens {
    my $amount  = shift or return 0;
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    my $new_total = $curr - $amount;

    plugin::YellowText("You have SPENT $amount Heroic Feat of Strength tokens. You have $new_total remaining.");    
    $client->SetBucket("FoS-Heroic-points", $new_total);
    return $new_total;
}

# Function to Display FoS-Heroic Tokens
sub Display_FoS_Heroic_Tokens {
    my $client  = shift or plugin::val('client');
    my $curr    = $client->GetBucket("FoS-Heroic-points") || 0;

    plugin::YellowText("You currently have $curr Heroic Feat of Strength Tokens.");
}

# Function to Get the current amount of FoS-Heroic Tokens
sub Get_FoS_Heroic_Tokens {
    my $client = shift or plugin::val('client');
    return $client->GetBucket("FoS-Heroic-points") || 0;
}

sub Add_Tokens {
    my $token_type  = shift;
    my $amount      = shift;
    my $client      = shift or plugin::val('client');
    
    return ($token_type) 
        ? Add_FoS_Heroic_Tokens($amount, $client) 
        : Add_FoS_Tokens($amount, $client);
}

sub Get_Tokens {
    my $token_type  = shift;
    my $client      = shift or plugin::val('client');
    
    return ($token_type) 
        ? Get_FoS_Heroic_Tokens($client) 
        : Get_FoS_Tokens($client);
}

sub Spend_Tokens {
    my $token_type  = shift;
    my $amount      = shift;
    my $client      = shift or plugin::val('client');
    
    return ($token_type) 
        ? Spend_FoS_Heroic_Tokens($amount, $client) 
        : Spend_FoS_Tokens($amount, $client);
}

sub Display_Tokens {
    my $client  = shift or plugin::val('client');
    Display_FoS_Tokens($client);
    Display_FoS_Heroic_Tokens($client);
}

sub calc_upgrade_cost {
    my ($item_id, $target_tier) = @_;
    return 0 unless $item_id;

    # Ensure the target tier is greater than the current tier
    my $current_tier = get_upgrade_tier($item_id);
    return 0 if $target_tier <= $current_tier;

    my $total_cost = 0;
    for (my $tier = $current_tier + 1; $tier <= $target_tier; $tier++) {
        my $stat_sum = calculate_heroic_stat_sum($item_id);
        $total_cost += int(0.25 * ($stat_sum * $tier) + $tier);
    }

    return $total_cost;
}

sub calculate_heroic_stat_sum {
    my $item_id = get_base_id(shift);
    my $clinet = plugin::val('client');

    # Define the primary stats we want to sum up
    my @primary_stats = qw(
        heroicstr heroicsta heroicdex heroicagi 
        heroicint heroicwis heroiccha
    );

    # Define the resistance stats we want to sum up and then halve
    my @resistance_stats = qw(
        heroicfr heroicmr heroic_r heroicpr heroicdr
    );

    # Fetch and sum the primary stats
    my $primary_stat_total = 0;
    foreach my $stat (@primary_stats) {
        $primary_stat_total += $client->GetItemStat($item_id, $stat);
    }

    # Fetch the resistance stats, sum them up, and then halve the total
    my $resistance_stat_total = 0;
    foreach my $stat (@resistance_stats) {
        $resistance_stat_total += $client->GetItemStat($item_id, $stat);
    }
    $resistance_stat_total /= 2;

    # Return the total sum of primary and halved resistance stats
    return $primary_stat_total + $resistance_stat_total;
}

sub get_inventory_DB {
    my $item_id = shift or return;
    my $client = shift or return;

    my $dbh = plugin::LoadMysql();
    my $sth = $dbh->prepare("SELECT count(*) 
                               FROM inventory 
                              WHERE (itemid % 1000000 = ? OR augslot1 % 1000000 = ? OR augslot2 % 1000000 = ? 
                                  OR augslot3 % 1000000 = ? OR augslot4 % 1000000 = ? OR augslot5 % 1000000 = ? 
                                  OR augslot6 % 1000000 = ?)
                                AND charid = ?");
    
    $sth->execute($item_id, $item_id, $item_id, $item_id, $item_id, $item_id, $item_id, $client->CharacterID());

    my $result = $sth->fetchrow_array() > 0 ? 1 : 0;

    $sth->finish();
    $dbh->disconnect();

    return $result;
}