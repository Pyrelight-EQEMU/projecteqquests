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

    # Loop through the main equipment categories
    for my $category (keys %equipment_index) {
        my $subhash = $equipment_index{$category};

        # If the item_id exists in the subhash
        if (exists $subhash->{$item_id}) {
            $result{'equipment'} = $category;
            $result{'value'} = $subhash->{$item_id};
            $result{'num_purchased'} = $client->GetBucket("equip-category-$category-quantity") || 0;
            return \%result;  # Return a reference to the hash
        }
    }

    # Return undef if item not found
    return undef;
}