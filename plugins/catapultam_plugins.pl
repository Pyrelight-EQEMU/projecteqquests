sub NPCTell {	
	my $npc = plugin::val('npc');
    my $client = plugin::val('client');
	my $message = shift;

	my $NPCName = $npc->GetCleanName();
    my $tellColor = 257;
	
    $client->Message($tellColor, "$NPCName tells you, '" . $message . "'");
}

sub YellowText {	
	my $npc = plugin::val('npc');
    my $client = plugin::val('client');
	my $message = shift;
    my $tellColor = 335;
	
    $client->Message($tellColor, $message);
}

sub WorldAnnounce {
	my $message = shift;
	quest::discordsend("ooc", $message);
	quest::we(335, $message);
}

# Serializer
sub SerializeList {
    my @list = @_;
    return join(',', @list);
}

# Deserializer
sub DeserializeList {
    my $string = shift;
    return split(',', $string);
}

# Serializer
sub SerializeHash {
    my %hash = @_;
    return join(';', map { "$_=$hash{$_}" } keys %hash);
}

# Deserializer
sub DeserializeHash {
    my $string = shift;
    my %hash = map { split('=', $_, 2) } split(';', $string);
    return %hash;
}

sub GetRoman {
    my ($level) = @_;

    my %level_to_roman = (
        0 => "I",
        10 => "II",
        20 => "III",
        30 => "IV",
        40 => "V",
        50 => "VI",
        60 => "VII",
        70 => "VIII",
        80 => "IX",
        90 => "X",
    );

    my ($roman) = map { $level_to_roman{$_} } reverse sort grep { $level >= $_ } keys %level_to_roman;
    return $roman;
}

sub GetPotName {
    my @strings = (
        "Divine Healing", "Divine Healing", "Divine Healing", "Divine Healing", "Divine Healing", "Divine Healing",
        "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing", "Celestial Healing",
        "Mana Restoration",
        "Skinspikes",
        "Replenishment", "Replenishment", "Replenishment",
        "Alacrity", "Alacrity",
        "Immunization", "Immunization", "Immunization", "Immunization", "Immunization",
        "Antidote", "Antidote", "Antidote", "Antidote", "Antidote"
    );
    return $strings[int(rand(@strings))];
}

sub FabledName {
    my $mob_name = shift;
    
    my $leading_character = "";

    if ($mob_name =~ s/^#//) {
        $leading_character = "#";
    }

    my @words = split('_', $mob_name);
    my @new_words;

    foreach my $index (0 .. $#words) {
        my $word = $words[$index];
        
        # Skip leading article
        if ($index == 0 && $word =~ /^(a|an|the)$/i) {
            next;
        }
        
        # Leave articles in the middle of the name uncapitalized
        if ($word =~ /^(a|an|the)$/i) {
            push @new_words, $word;
        } else {
            $word =~ s/(\w+)/\u\L$1/g;  # Capitalize first letter, lowercase the rest
            push @new_words, $word;
        }
    }

    my $new_name = join('_', @new_words);
    $new_name = $leading_character . $new_name;
    $new_name = ("The_Fabled_$new_name");

    return $new_name;
}

sub GetLockoutTime {
    return 3600;
}


return 1;