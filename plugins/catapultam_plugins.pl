sub NPCTell {	
	my $npc = plugin::val('npc');
    my $client = plugin::val('client');
	my $message = shift;

	my $NPCName = $npc->GetCleanName();
    my $tellColor = 257;
	
    $client->Message($tellColor, "$NPCName tells you, '" . $message . "'");
}

sub YellowText {
	my $message     = shift;
    my $client      = shift || plugin::val('client');
    my $tellColor   = 15;
	
    $client->Message($tellColor, $message);
}

sub RedText {
	my $message     = shift;
    my $client      = shift || plugin::val('client');
    my $tellColor   = 13;
	
    $client->Message($tellColor, $message);
}

sub PurpleText {
	my $message     = shift;
    my $client      = shift || plugin::val('client');
    my $tellColor   = 257;
	
    $client->Message($tellColor, $message);
}

sub WorldAnnounce {
	my $message = shift;
	quest::discordsend("ooc", $message);
	quest::we(15, $message);
}

# Usage: WorldAnnounceItem($message, $item_id)
# Sends a world announcement and a Discord message for a given item.
# 
# Parameters:
#   $message  - The text that will be included in the announcement.
#               It can contain a placeholder "{item}" that will be replaced
#               with an in-game link in the world announcement, and with
#               a Discord link in the Discord announcement.
#   $item_id  - The ID of the item.
#
# The function constructs in-game and Discord links using quest::varlink and quest::getitemname.
# It then sends the world announcement using quest::we, and the Discord announcement using quest::discordsend.
#
# Example:
#   WorldAnnounceItem("{item} has been claimed!", 12345);
#   # World announcement: "[ItemLink] has been claimed!"
#   # Discord announcement: "[[ItemName](https://www.pyrelight.net/allaclone/?a=item&id=12345)] has been claimed!"
sub WorldAnnounceItem {
    my ($message, $item_id) = @_;
    my $itemname = quest::getitemname($item_id);

    my $eqgitem_link = quest::varlink($item_id);
    my $discord_link = "[[$itemname](https://www.pyrelight.net/allaclone/?a=item&id=$item_id)]";

    # Replace a placeholder in the message with the EQ game link
    $message =~ s/\{item\}/$eqgitem_link/g;

    # Send the message with the game link to the EQ world
    quest::we(15, $message);

    # Replace the game link with the Discord link
    $message =~ s/\Q$eqgitem_link\E/$discord_link/g;

    # Send the message with the Discord link to Discord
    quest::discordsend("ooc", $message);
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
        0  => " I",
        10 => " II",
        20 => " III",
        30 => " IV",
        40 => " V",
        50 => " VI",
        60 => " VII",
        70 => " VIII",
        80 => " IX",
        90 => " X",
    );

    my ($roman) = map { $level_to_roman{$_} } reverse sort grep { $level >= $_ } keys %level_to_roman;
    return $roman;
}

sub GetPotName {
    my @strings = (
        "Divine Healing", "Divine Healing", "Divine Healing",
        "Celestial Healing", "Celestial Healing", "Celestial Healing",
        "Mana Restoration", "Mana Restoration", "Mana Restoration",
        "Skinspikes",
        "Replenishment",
        "Alacrity",
        "Immunization", "Immunization", "Immunization", "Immunization", "Immunization",
        "Antidote", "Antidote", "Antidote", "Antidote", "Antidote"
    );
    return $strings[int(rand(@strings))];
}

sub GetUnlockedClasses {
    my $client = shift;
    my $dbh    = plugin::LoadMysql();
    my $sth    = $dbh->prepare("SELECT class, level FROM multiclass_data WHERE id = ?");

    $sth->execute($client->CharacterID());

    my %unlocked_classes;
    while (my $row = $sth->fetchrow_hashref()) {
        my $class_id = $row->{'class'};
        my $class_level = $row->{'level'};
        $unlocked_classes{$class_id} = $class_level;
    }

    my $current_class = $client->GetClass();
    my $current_level = $client->GetLevel();

    $unlocked_classes{$current_class} = $current_level;

    return %unlocked_classes;
}

sub GetClassListString {
    my $client = shift;

    # Get active class and level
    my $active_class_id = $client->GetClass();
    my $active_level    = $client->GetLevel();
    my $active_class    = quest::getclassname($active_class_id, $active_level);

    # Get other unlocked classes
    my %unlocked_classes = GetUnlockedClasses($client);
    my @class_strings;
    while (my ($class_id, $level) = each %unlocked_classes) {
        # Skip the active class since it's already included
        next if $class_id == $active_class_id;

        my $class_name = quest::getclassname($class_id, $level);
        push @class_strings, "$level $class_name";
    }

    # Construct the final string
    my $name        = $client->GetCleanName();
    my $class_list  = join(', ', @class_strings);
    my $info_string = "$name (Level $active_level $active_class [$class_list])";

    return $info_string;
}

sub GetInactiveClasses {
    my $client = shift;
    my %unlocked_classes = GetUnlockedClasses($client);

    # Remove the active class from the list
    delete $unlocked_classes{$client->GetClass()};

    # Convert to a formatted string, sorted by level (descending), then by class ID (ascending)
    my @inactive_classes;
    foreach my $class_id (
        sort {
            $unlocked_classes{$b} <=> $unlocked_classes{$a}
                or $a <=> $b
        } keys %unlocked_classes
    ) {
        my $class_name = quest::getclassname($class_id, $unlocked_classes{$class_id});
        push @inactive_classes, "$unlocked_classes{$class_id} $class_name";
    }

    return join(', ', @inactive_classes);
}

sub GetLockoutTime {
    return 3600;
}

#function check_level_flag(e)
#	local key = e.self:CharacterID() .. "-CharMaxLevel"
#	
#	if eq.get_data(key) == "" then
#		eq.set_data(key, "60")
#		e.self:Message(15, "Your Level Cap has been set to 60.")
#	end
#end

sub CheckLevelFlags {
    my $client = plugin::val('client');
    my $key    = $client->CharacterID() . "-CharMaxLevel";

    if (not quest::get_data($key)) {
        quest::set_data($key, 60);
        YellowText("Your Level Cap has been set to 60");
    }
}

#function check_class_switch_aa(e)
#	accum = 0
#	for i=16,1,-1
#	do
#		eq.debug("Checking class: " .. i);
#		if (e.self:GetBucket("class-"..i.."-unlocked") == '1') then
#			eq.debug("Unlocked Class: " .. i);
#			e.self:GrantAlternateAdvancementAbility(20000 + i, 1, true)			
#			accum = accum + 1			
#		end		 
#	end
#	eq.debug("Unlocked Classes: " .. accum);
#	expPenalty = calculate_modifier(accum)
#	e.self:SetEXPModifier(0, expPenalty)
#	eq.debug("Setting your Exp Modifier to: " .. expPenalty)
#end

sub CheckClassAA {
    my $client = shift;
    my $accum  = 0;

    foreach my $i (reverse 1..16) {
        quest::debug("Checking Class ID: $i");
        if ($client->GetBucket("class-$i-unlocked")) {
            quest::debug("ClassID $i is unlocked");
            $client->GrantAlternateAdvancementAbility(20000+$i, 1, 1);
            $accum++;
        }
    }

    if ($accum == 0) {
        $accum++;
    }

    my $expPenalty = CalculateExpPenalty($accum);
    $client->SetEXPModifier(0, $expPenalty);
    
    quest::debug("Unlocked Class Count: $accum");
    quest::debug("Set Exp Penalty to: $expPenalty");
}

#function calculate_modifier(count)
#    if count == 1 then
#        return 1
#    end
#
#    modifier = 1
#    for i=count,2,-1 do
#        modifier = modifier * .90
#    end
#	modifier = 1
#    return modifier
#end

sub CalculateExpPenalty {
    #This is currently no-oped
    return 1;
}

sub return_items_silent {
	my $hashref = plugin::var('$itemcount');
	my $client = plugin::val('$client');
	my $name = plugin::val('$name');
	my $items_returned = 0;

	my %item_data = (
		0 => [ plugin::val('$item1'), plugin::val('$item1_charges'), plugin::val('$item1_attuned'), plugin::val('$item1_inst') ],
		1 => [ plugin::val('$item2'), plugin::val('$item2_charges'), plugin::val('$item2_attuned'), plugin::val('$item2_inst') ],
		2 => [ plugin::val('$item3'), plugin::val('$item3_charges'), plugin::val('$item3_attuned'), plugin::val('$item3_inst') ],
		3 => [ plugin::val('$item4'), plugin::val('$item4_charges'), plugin::val('$item4_attuned'), plugin::val('$item4_inst') ],
	);

	my %return_data = ();	

	foreach my $k (keys(%{$hashref})) {
		next if ($k == 0);
		my $rcount = $hashref->{$k};
		my $r;
		for ($r = 0; $r < 4; $r++) {
			if ($rcount > 0 && $item_data{$r}[0] && $item_data{$r}[0] == $k) {
				if ($client) {
					my $inst = $item_data{$r}[3];
					my $return_count = $inst->RemoveTaskDeliveredItems();
					if ($return_count > 0) {
						$client->SummonItem($k, $inst->GetCharges(), $item_data{$r}[2]);
						$return_data{$r} = [$k, $item_data{$r}[1], $item_data{$r}[2]];
						$items_returned = 1;
						next;
					}
					$return_data{$r} = [$k, $item_data{$r}[1], $item_data{$r}[2]];
					$client->SummonItem($k, $item_data{$r}[1], $item_data{$r}[2]);
					$items_returned = 1;
				} else {
					$return_data{$r} = [$k, $item_data{$r}[1], $item_data{$r}[2]];
					quest::summonitem($k, 0);
					$items_returned = 1;
				}
				$rcount--;
			}
		}

		delete $hashref->{$k};
	}

	# check if we have any money to return
	my @money = ("platinum", "gold", "silver", "copper");
	my $returned_money = 0;
	foreach my $m (@money) {
		if ($hashref->{$m} && $hashref->{$m} > 0) {
			$returned_money = 1;
		}
	}

	if ($returned_money) {
		my ($cp, $sp, $gp, $pp) = ($hashref->{"copper"}, $hashref->{"silver"}, $hashref->{"gold"}, $hashref->{"platinum"});
		$client->AddMoneyToPP($cp, $sp, $gp, $pp, 1);
		$client->SetEntityVariable("RETURN_MONEY", "$cp|$sp|$gp|$pp");
	}

	$client->SetEntityVariable("RETURN_ITEMS", plugin::GetHandinItemsSerialized("Return", %return_data));

	if ($items_returned || $returned_money) {
		#quest::say("I have no need for this $name, you can have it back.");
	}

	quest::send_player_handin_event();

	# Return true if items were returned
	return ($items_returned || $returned_money);
}

# Check if the specified item ID exists
sub item_exists_in_db {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();
    my $sth = $dbh->prepare("SELECT count(*) FROM items WHERE id = ?");
    $sth->execute($item_id);

    my $result = $sth->fetchrow_array();

    $sth->finish();
    $dbh->disconnect();

    return $result > 0 ? 1 : 0;
}

sub get_total_attunements {
    my $client = shift;
    my @suffixes = ('A', 'O', 'F', 'K', 'V', 'L'); # Add more suffixes as needed
    my $total = 0;
    foreach my $suffix (@suffixes) {
        $total += count_teleport_zones($client, $suffix);
    }

    return $total;
}

sub count_teleport_zones {
    my ($client, $suffix) = @_;

    # Check for a provided suffix or default to 'A'
    $suffix //= 'A';

    my $charKey = $client->CharacterID() . "-TL";
    my $charTargetsString = quest::get_data($charKey . "-" . $suffix);

    my %teleport_zones = ();
    
    my @zones = split /:/, $charTargetsString;
    foreach my $z (@zones) {      
        my @tokens = split /,/, $z;
        if ($tokens[1]) {
            $teleport_zones{$tokens[1]} = [ @tokens ];
        }
    }
    
    return scalar(keys %teleport_zones);
}