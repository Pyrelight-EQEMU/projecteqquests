sub get_equipment_index {
    my %chronal_seals = (
        '33407' => '5',
        '33408' => '5',
        '33409' => '5',
        '33410' => '5',
        '33411' => '5',
        '33416' => '5',
        '33417' => '5',
        '33418' => '5',
        '33419' => '5',
        '33420' => '5',
        '33421' => '5',
        '33424' => '5',
        '33425' => '5',
        '33428' => '5',
        '33429' => '5',
        '33430' => '5',
        '33431' => '5',
        '33432' => '5',
        '33434' => '5'
    );

    my %equipment_index = (
        'Class Emblems' => '',
        'Chronal Seals' => \%chronal_seals
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