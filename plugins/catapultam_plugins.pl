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
    my $tellColor   = 335;
	
    $client->Message($tellColor, $message);
}

sub RedText {
	my $message     = shift;
    my $client      = shift || plugin::val('client');
    my $tellColor   = 287;
	
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
	quest::we(335, $message);
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
    quest::we(335, $message);

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
        "Instant Healing", "Instant Healing", "Instant Healing",
        "Gradual Healing", "Gradual Healing", "Gradual Healing",
        "Mana Restoration", "Mana Restoration", "Mana Restoration",
        "Skinspikes",
        "Replenishment",
        "Alacrity",
        "Immunization", "Immunization", "Immunization", "Immunization", "Immunization",
        "Antidote", "Antidote", "Antidote", "Antidote", "Antidote"
    );
    return $strings[int(rand(@strings))];
}

sub UnlockClass {
    my ($client, $class_id) = @_;
    my $class_name          = quest::getclassname($class_id);
    my $class_ability_base  = 20000;
    my $character_id        = $client->CharacterID();
    my $unlocksAvailable    = $client->GetBucket("ClassUnlocksAvailable") || 0;

    if ($unlocksAvailable >= 1) {

        # Load database handler
        my $dbh = plugin::LoadMysql();

        # Check if the class is already unlocked
        my $sth = $dbh->prepare("SELECT * FROM multiclass_data WHERE id = ? AND class = ?");
        $sth->execute($character_id, $class_id);
        
        if ($sth->fetchrow_hashref()) {
            plugin::NPCTell("This class is already unlocked for you.");
            $sth->finish();
            $dbh->disconnect(); # disconnect from the database
            return 0;
        } else { 
            $client->SetBucket("ClassUnlocksAvailable", --$unlocksAvailable);
            plugin::YellowText("You have spent a Class Unlock point.");            
            plugin::YellowText("You are now " . ( (grep { $_ eq lc(substr($class_name, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $class_name.");
            quest::ding();

            # Insert data into multiclass_data table for the new class
            $sth = $dbh->prepare("INSERT INTO multiclass_data (id, class) VALUES (?, ?)");
            $sth->execute($character_id, $class_id);

            # Grant class abilities
            $client->GrantAlternateAdvancementAbility($client->GetClass + $class_ability_base, 1, 1);
            $client->GrantAlternateAdvancementAbility($class_id + $class_ability_base, 1, 1);
        }

        $sth->finish();
        $dbh->disconnect(); # disconnect from the database
        return 1;
    } else {
        plugin::NPCTell("Sorry, you don't have any available class unlocks.");
        return 0;
    }
}

sub GetUnlockedClasses {
    my $client = shift;
    my $dbh    = plugin::LoadMysql();
    my $sth    = $dbh->prepare("SELECT class, level FROM multiclass_data WHERE id = ? AND class NOT IN (1, 7, 8, 9, 12, 16)");

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

sub GetTotalLevels {
    my $client  = shift or plugin::val('client');
    my $dbh     = plugin::LoadMysql();
    
    # Generate placeholders for the IN clause
    my @classes_to_exclude = (1, 7, 8, 9, 12, 16);
    push @classes_to_exclude, $client->GetClass(); # Add the character's class to the exclude list
    my $placeholders = join(", ", ("?") x @classes_to_exclude);

    my $sth = $dbh->prepare("SELECT level FROM multiclass_data WHERE id = ? AND class NOT IN ($placeholders)");

    # Execute the statement with the character ID and the classes to exclude
    $sth->execute($client->CharacterID(), @classes_to_exclude);

    my $level_total = $client->GetLevel();
    while (my $row = $sth->fetchrow_hashref()) {
        $level_total += $row->{'level'};
    }

    return $level_total;
}


sub GetLockedClasses {
    my $client = shift;
    my %unlocked_classes = GetUnlockedClasses($client);

    # All the class IDs excluding the ones you've specified
    my @all_classes = (2, 3, 4, 5, 6, 10, 11, 13, 14, 15);

    # Filtering out the unlocked class IDs
    my @locked_classes = grep { not exists $unlocked_classes{$_} } @all_classes;

    return @locked_classes;
}

sub GetClassID {
    my $class_name = shift;

    # Mapping from the provided table
    my %class_name_to_id = (
        'Warrior'       => 1,
        'Cleric'        => 2,
        'Paladin'       => 3,
        'Ranger'        => 4,
        'Shadow Knight' => 5,
        'Druid'         => 6,
        'Monk'          => 7,
        'Bard'          => 8,
        'Rogue'         => 9,
        'Shaman'        => 10,
        'Necromancer'   => 11,
        'Wizard'        => 12,
        'Magician'      => 13,
        'Enchanter'     => 14,
        'Beastlord'     => 15,
        'Berserker'     => 16,
    );

    return $class_name_to_id{$class_name};
}

sub IsClassUnlocked {
    my ($client, $class_name) = @_;
    
    # Convert class name to class ID
    my $class_id = GetClassID($class_name);
    
    # Return undef if we can't find the class ID
    return unless defined $class_id;

    # Fetch all unlocked classes
    my %unlocked_classes = GetUnlockedClasses($client);

    # Check if the class_id exists in unlocked_classes
    return exists $unlocked_classes{$class_id};
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

sub CheckClassAA {
    my $client = shift;
    my $class_ability_base = 20000;
    
    # Use the GetUnlockedClasses method to get the unlocked classes
    my %unlocked_classes = GetUnlockedClasses($client);
    
    foreach my $class_id (keys %unlocked_classes) {
        $client->GrantAlternateAdvancementAbility($class_ability_base + $class_id, 1, 1);
    }    
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

    return $result > 0 ? 1 : 0;
}

sub get_total_attunements {
    my $client = shift;
    my @suffixes = ('A', 'O', 'F', 'K', 'V', 'L'); # Add more suffixes as needed
    my $total = 0;

    foreach my $suffix (@suffixes) {
        my $zone_data = get_zone_data_for_account($client->AccountID(), $suffix);
        $total += scalar(keys %$zone_data);
    }

    return $total;
}

sub is_item_upgradable {
    my $item_id = shift or die;

    if ($item_id > 10000000) {
        return 0;
    }    

    # Calculate the next-tier item ID
    $item_id += 1000000;

    # Check if the next-tier item exists in the database
    return item_exists_in_db($item_id);
}

# Returns the base ID of an item
sub get_base_id {
    my $item_id = shift;
    return $item_id % 1000000; # Assuming item IDs increment by 1000000 per tier
}

# Returns the upgrade tier of an item
sub get_upgrade_tier {
    my $item_id = shift;
    return int($item_id / 1000000); # Assuming item IDs increment by 1000000 per tier
}

# Wrapper function to return both base ID and upgrade tier
sub get_base_id_and_tier {
    my $item_id = shift;
    return (get_base_id($item_id), get_upgrade_tier($item_id));
}

sub get_continent_fix {
    my %zone_to_continent = (

        # Faydwer
        'akanon'     => 'F',
        'butcher'    => 'F',
        'cauldron'   => 'F',
        'crushbone'  => 'F',
        'felwithea'  => 'F',
        'felwitheb'  => 'F',
        'gfaydark'   => 'F',
        'kedge'      => 'F',
        'kaladima'   => 'F',
        'kaladimb'   => 'F',
        'lfaydark'   => 'F',
        'mistmoore'  => 'F',
        'steamfont'  => 'F',
        'unrest'     => 'F',

        # Antonica
        'arena'         => 'A',
        'befallen'      => 'A',
        'beholder'      => 'A',
        'blackburrow'   => 'A',
        'cazicthule'    => 'A',
        'commons'       => 'A',
        'ecommons'      => 'A',
        'eastkarana'    => 'A',
        'erudsxing'     => 'A',
        'everfrost'     => 'A',
        'feerrott'      => 'A',
        'freporte'      => 'A',
        'freportn'      => 'A',
        'freportw'      => 'A',
        'grobb'         => 'A',
        'gukbottom'     => 'A',
        'guktop'        => 'A',
        'halas'         => 'A',
        'highkeep'      => 'A',
        'highpasshold'  => 'A',
        'innothule'     => 'A',
        'kithicor'      => 'A',
        'lakerathe'     => 'A',
        'lavastorm'     => 'A',
        'misty'         => 'A',
        'najena'        => 'A',
        'neriaka'       => 'A',
        'neriakb'       => 'A',
        'neriakc'       => 'A',
        'neriakd'       => 'A',
        'nektulos'      => 'A',
        'northkarana'   => 'A',
        'nro'           => 'A',
        'oasis'         => 'A',
        'oggok'         => 'A',
        'oot'           => 'A',
        'paw'           => 'A',
        'permafrost'    => 'A',
        'qcat'          => 'A',
        'qey2hh1'       => 'A',
        'qeynos'        => 'A',
        'qeynos2'       => 'A',
        'qeytoqrg'      => 'A',
        'qrg'           => 'A',
        'rathemtn'      => 'A',
        'rivervale'     => 'A',
        'runnyeye'      => 'A',
        'soldunga'      => 'A',
        'soldungb'      => 'A',
        'soltemple'     => 'A',
        'southkarana'   => 'A',
        'sro'           => 'A',
        'gunthak'       => 'A',
        'dulak'         => 'A',
        'nadox'         => 'A',
        'torgiran'      => 'A',
        'hatesfury'     => 'A',
        'jaggedpine'    => 'A',
        
        # Odus
        'hole'          => 'O',
        'kerraridge'    => 'O',
        'paineel'       => 'O',
        'tox'           => 'O',
        'warrens'       => 'O',
        'stonebrunt'    => 'O',

        # Kunark
        'burningwood'   => 'K',
        'cabeast'       => 'K',
        'cabwest'       => 'K',
        'chardok'       => 'K',
        'charasis'      => 'K',
        'citymist'      => 'K',
        'dalnir'        => 'K',
        'dreadlands'    => 'K',
        'droga'         => 'K',
        'emeraldjungle' => 'K',
        'fieldofbone'   => 'K',
        'firiona'       => 'K',
        'frontiermtns'  => 'K',
        'kaesora'       => 'K',
        'karnor'        => 'K',
        'kurn'          => 'K',
        'lakeofillomen' => 'K',
        'nurga'         => 'K',
        'overthere'     => 'K',
        'sebilis'       => 'K',
        'skyfire'       => 'K',
        'swampofnohope' => 'K',
        'timorous'      => 'K',
        'trakanon'      => 'K',
        'veeshan'       => 'K',
        'warslikswood'  => 'K',
        
        # Velious
        'cobaltscar'    => 'V',
        'crystal'       => 'V',
        'eastwastes'    => 'V',
        'frozenshadow'  => 'V',
        'greatdivide'   => 'V',
        'iceclad'       => 'V',
        'kael'          => 'V',
        'necropolis'    => 'V',
        'sirens'        => 'V',
        'sleepers'      => 'V',
        'skyshrine'     => 'V',
        'templeveeshan' => 'V',
        'thurgadina'    => 'V',
        'thurgadinb'    => 'V',
        'velketor'      => 'V',
        'wakening'      => 'V',
        'westwastes'    => 'V',

        # Luclin
        'acrylia'      => 'L',
        'akheva'       => 'L',
        'bazaar'       => 'L',
        'dawnshroud'   => 'L',
        'echo'         => 'L',
        'fungusgrove'  => 'L',
        'griegsend'    => 'L',
        'grimling'     => 'L',
        'hollowshade'  => 'L',
        'katta'        => 'L',
        'letalis'      => 'L',
        'maiden'       => 'L',
        'mseru'        => 'L',
        'netherbian'   => 'L',
        'nexus'        => 'L',
        'paludal'      => 'L',
        'scarlet'      => 'L',
        'shadeweaver'  => 'L',
        'shadowhaven'  => 'L',
        'sharvahl'     => 'L',
        'sseru'        => 'L',
        'ssratemple'   => 'L',
        'tenebrous'    => 'L',
        'thedeep'      => 'L',
        'thegrey'      => 'L',
        'umbral'       => 'L',
        'vexthal'      => 'L',

        # Planes of Power
        'poknowledge'         => 'P',
        'potranquility'       => 'P',        
        'pojustice'           => 'P', # Plane of Justice
        'podisease'           => 'P', # Plane of Disease
        'poinnovation'        => 'P', # Plane of Innovation
        'ponightmare'         => 'P', # Plane of Nightmare
        'nightmareb'          => 'P', # The Lair of Terris Thule
        'povalor'             => 'P', # Plane of Valor
        'postorms'            => 'P', # Plane of Storms
        'potorment'           => 'P', # Plane of Torment
        'codecay'             => 'P',
        'hohonora'            => 'P',
        'hohonorb'            => 'P',
        'bothunder'           => 'P',
        'potactics'           => 'P',
        'solrotower'          => 'P',
        'pofire'              => 'P',
        'poair'               => 'P',
        'powater'             => 'P',
        'poeartha'            => 'P',
        'poearthb'            => 'P',
        'potimea'             => 'P',
        'potimeb'             => 'P',
        'hateplaneb'          => 'P',
        'mischiefplane'       => 'P',
        'airplane'            => 'P',
        'fearplane'           => 'P',

        # Gates of Discord
        'abysmal'      => 'G',
        'barindu'      => 'G',
        'ferubi'       => 'G',
        'ikkinz'       => 'G',
        'inktuta'      => 'G',
        'kodtaz'       => 'G',
        'natimbi'      => 'G',
        'qinimi'       => 'G',
        'qvic'         => 'G',
        'riwwi'        => 'G',
        'snlair'       => 'G',
        'snplant'      => 'G',
        'snpool'       => 'G',
        'sncrematory'  => 'G',
        'tacvi'        => 'G',
        'tipt'         => 'G',
        'txevu'        => 'G',
        'uqua'         => 'G',
        'vxed'         => 'G',
        'yxtta'        => 'G',

        # Omens of Discord
        'anguish'           => 'O',
        'bloodfields'       => 'O',
        'causeway'          => 'O',
        'chambersa'         => 'O',
        'chambersb'         => 'O',
        'chambersc'         => 'O',
        'chambersd'         => 'O',
        'chamberse'         => 'O',
        'chambersf'         => 'O',
        'dranik'            => 'O',
        'dranikcatacombsa'  => 'O',
        'dranikcatacombsb'  => 'O',
        'dranikcatacombsc'  => 'O',
        'dranikhollowsa'    => 'O',
        'dranikhollowsb'    => 'O',
        'dranikhollowsc'    => 'O',
        'dranikscar'        => 'O',
        'drainksewersa'     => 'O',
        'drainksewersb'     => 'O',
        'drainksewersc'     => 'O',
        'harbingers'        => 'O',
        'provinggrounds'    => 'O',
        'riftseekers'       => 'O',
        'wallofslaughter'   => 'O',

    );

    my $zonesn = shift;

    if (exists $zone_to_continent{$zonesn}) {
        return $zone_to_continent{$zonesn};
    } else {
        return undef;
    }
}

# Get character's saved zone data
sub get_zone_data_for_character {
    my ($characterID, $suffix) = @_;
    my $charKey = $characterID . "-TL-" . $suffix;

    fix_zone_data($characterID, $suffix);

    my $charDataString = quest::get_data($charKey);

    # Debug: Print the raw string data
    #quest::debug("characterID: $characterID suffix: $suffix Raw Data: $charDataString");

    my %teleport_zones;
    my @zone_entries = split /:/, $charDataString;

    foreach my $entry (@zone_entries) {
        my @tokens = split /,/, $entry;
        $teleport_zones{$tokens[0]} = [@tokens[1..$#tokens]];
    }

    return \%teleport_zones;
}

sub set_zone_data_for_character {
    my ($characterID, $zone_data_hash_ref, $suffix) = @_;
    my $charKey = $characterID . "-TL-" . $suffix;

    # Debug: Print the key used to store data
    #quest::debug("Setting data with key: $charKey");

    my @data_entries;

    while (my ($desc, $zone_data) = each %{$zone_data_hash_ref}) {
        my $entry = join(",", $desc, @{$zone_data});
        push @data_entries, $entry;
    }

    my $charDataString = join(":", @data_entries);

    # Debug: Print the data string being set
    #quest::debug("Setting Raw Data: $charDataString");

    quest::set_data($charKey, $charDataString);
}

# Get character's saved zone data
sub get_zone_data_for_account {
    my ($accountID, $suffix) = @_;
    my $charKey = $accountID . "-TL-Account-" . $suffix;

    my $charDataString = quest::get_data($charKey);

    # Debug: Print the raw string data
    #quest::debug("characterID: $characterID suffix: $suffix Raw Data: $charDataString");

    my %teleport_zones;
    my @zone_entries = split /:/, $charDataString;

    foreach my $entry (@zone_entries) {
        my @tokens = split /,/, $entry;
        $teleport_zones{$tokens[0]} = [@tokens[1..$#tokens]];
    }

    return \%teleport_zones;
}

sub set_zone_data_for_account {
    my ($accountID, $zone_data_hash_ref, $suffix) = @_;
    my $charKey = $accountID . "-TL-Account-" . $suffix;

    # Debug: Print the key used to store data
    #quest::debug("Setting data with key: $charKey");

    my @data_entries;

    while (my ($desc, $zone_data) = each %{$zone_data_hash_ref}) {
        my $entry = join(",", $desc, @{$zone_data});
        push @data_entries, $entry;
    }

    my $charDataString = join(":", @data_entries);

    # Debug: Print the data string being set
    #quest::debug("Setting Raw Data: $charDataString");

    quest::set_data($charKey, $charDataString);
}

sub add_char_zone_data_to_account {
    my ($characterID, $accountID, $suffix) = @_;

    # Get the character's zone data
    my $char_zone_data = get_zone_data_for_character($characterID, $suffix);

    # Get the account's current zone data
    my $account_zone_data = get_zone_data_for_account($accountID, $suffix);

    # Add the character's zone data to the account's zone data
    while (my ($zone, $data) = each %{$char_zone_data}) {
        if (exists $account_zone_data->{$zone}) {
            # If the zone already exists in the account's data, you can choose how to merge the data.
            # For example, you could skip, replace, or merge the data. Here, we simply replace.
            $account_zone_data->{$zone} = $data;
        } else {
            # If the zone does not exist in the account's data, add it.
            $account_zone_data->{$zone} = $data;
        }
    }

    # Save the updated zone data back to the account
    set_zone_data_for_account($accountID, $account_zone_data, $suffix);
}

# Serializes the data structure for storage
# Usage:
#    my %zone_data = ('Zone1' => ['data1', 'data2'], 'Zone2' => ['data3', 'data4']);
#    my $serialized_data = serialize_zone_data(\%zone_data);
#    print $serialized_data;
sub serialize_zone_data {
    my ($data) = @_;
    my @entries = ();
    foreach my $key (keys %{$data}) {
        push @entries, join(',', $key, @{$data->{$key}});
    }
    return join(':', @entries);
}

# Deserializes the data structure from the stored string
# Usage:
#    my $data_string = "Zone1,data1,data2:Zone2,data3,data4";
#    my $zone_data = deserialize_zone_data($data_string);
#    foreach my $zone (keys %{$zone_data}) {
#        print "Zone: $zone\n";
#    }
sub deserialize_zone_data {
    my ($string) = @_;
    my %data = ();
    foreach my $entry (split /:/, $string) {
        my @tokens = split /,/, $entry;
        $data{$tokens[0]} = [ @tokens[1..5] ];
    }
    return \%data;
}

# Check if a particular piece of data (by zone description) is present
sub has_zone_entry {
    my ($accountID, $zone_desc, $suffix) = @_;
    my $teleport_zones = plugin::get_zone_data_for_account($accountID, $suffix);

    #quest::debug("Checking for description: $zone_desc");
    #quest::debug("Current Data: " . join(", ", keys %{$teleport_zones}));

    return exists($teleport_zones->{$zone_desc});
}

# Add (or overwrite) data to teleport_zones
# Usage:
#    add_zone_entry(12345, "Zone4", ['data7', 'data8'], '-K');
sub add_zone_entry {
    my ($accountID, $zone_name, $zone_data, $suffix) = @_;
    my $teleport_zones = get_zone_data_for_account($accountID, $suffix);
    $teleport_zones->{$zone_name} = $zone_data;
    set_zone_data_for_account($accountID, $teleport_zones, $suffix);
}

sub fix_zone_data {
    my ($characterID, $suffix) = @_;
    my $charKey = $characterID . "-TL-" . $suffix;
    my $charDataString = quest::get_data($charKey);
    my $data_hash = plugin::deserialize_zone_data($charDataString);  

    delete $data_hash->{''};
    
    foreach my $key (keys %$data_hash) {        
        if (quest::GetZoneLongName($key) ne "UNKNOWN") {
            quest::debug("Fixed an element");  
            my $zone_sn = $key;
            my $zone_desc = $data_hash->{$key}[0];  # Access the elements using ->

            # Create a new entry in the hash with the zone_desc as the key
            $data_hash->{$zone_desc} = [$key, @{$data_hash->{$key}}[1..4]];

            # Delete the original key from the hash
            delete $data_hash->{$key};
        }
    }

    quest::set_data($charKey, plugin::serialize_zone_data($data_hash));
}

sub is_global_aug {
    my $item_id = shift;
    my $dbh = plugin::LoadMysql();

    my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 AND lootdrop_entries.item_id = ?");
    $sth->execute($item_id);

    $dbh->disconnect();
   
    if ($sth->fetchrow_array) {
        $sth->finish();
        return 1; # Item ID is present
    } else {
        $sth->finish();
        return 0; # Item ID is not present
    }
}

sub get_global_aug {
   my $dbh = plugin::LoadMysql();

   my $sth = $dbh->prepare("SELECT lootdrop_entries.item_id FROM peq.lootdrop_entries WHERE lootdrop_entries.lootdrop_id = 1200224 ORDER BY RAND() LIMIT 1");
   $sth->execute();
   
   my ($random_item_id) = $sth->fetchrow_array;

   $sth->finish();
   $dbh->disconnect();
   return $random_item_id;   
}

sub get_cmc {
    my $client  = plugin::val('client');
    return $client->GetBucket("Artificer_CMC") || 0;
}

sub display_cmc {
    my $cmc     = get_cmc();
    plugin::YellowText("You currently have $cmc Concentrated Mana Crystals available.");
}

sub set_cmc {
    my $val     = shift;
    my $client  = plugin::val('client');
    
    $client->SetBucket("Artificer_CMC", $val);
}

sub add_cmc {
    my $val     = shift;
    my $cmc     = get_cmc();
    set_cmc($cmc + $val);

    plugin::YellowText("You have gained $val Concentrated Mana Crystals. You now have " . ($cmc + $val) . " available.");
}

sub spend_cmc {
    my $val = shift;
    my $cmc = get_cmc();    
    set_cmc($cmc - $val);

    plugin::YellowText("You have lost $val Concentrated Mana Crystals. You now have " . ($cmc - $val) . " available.");
}

sub is_focus_equipped {
    my ($client, $desired_focus_id) = @_;

    # Return immediately if necessary parameters aren't provided
    return unless ($client && defined $desired_focus_id);

    # Check if any of the equipped augments in the items have the desired focus effect
    for my $slot_index (0..22) {
        my $item_id    = $client->GetItemIDAt($slot_index);
        my $item_focus = $client->GetItemStat($item_id, 'focuseffect');
        return 1 if ($item_focus == $desired_focus_id);
        for my $aug_index (0..6) {
            my $augment_id      = $client->GetAugmentIDAt($slot_index, $aug_index);
            my $augment_focus   = $client->GetItemStat($augment_id, 'focuseffect');
            return 1 if ($augment_focus == $desired_focus_id);
        }
    }

    # If neither items nor augments have the focus, return 0
    return 0;
}

sub get_fabled_id {
    my ($item_id)   = @_;
    my $base_id     = plugin::get_base_id($item_id);
    my $item_name   = quest::getitemname($base_id);
    my $fabled_name = "Fabled " . $item_name;

    my $dbh         = plugin::LoadMysql();
    my $sth         = $dbh->prepare("SELECT id FROM items WHERE items.name LIKE ? AND id <= 999999");

    $sth->execute($fabled_name) or die;

    my $fabled_id = $sth->fetchrow() or 0;

    $sth->finish();
    $dbh->disconnect();

    return $fabled_id;
}

sub upgrade_item_to_fabled {
    my ($item_id, $npc)     = @_;
    my $fabled_id           = plugin::get_fabled_id($item_id);

    if ($npc && $npc->CountItem($item_id)) {
        $npc->RemoveItem($item_id);
        $npc->AddItem($fabled_id);
    } else { quest::debug("The npc didn't exist?"); } 
}

sub build_spellpool {
    my $client = shift;

    my %spellbook = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook"));
    
    # Step 1: Create an array of all spell IDs.
    my @spell_ids;
    for my $slot (0..720) {
        my $spell_id = $client->GetSpellIDByBookSlot($slot);
        if ($spell_id > 0 && $spell_id <= 44000) {
            push @spell_ids, $spell_id;
        }
    }

    # Step 2 and 3: Fetch results from database
    my %spell_levels = GetSpellLevelsByClass(\@spell_ids, $client->GetClass());

    # Step 4: Update the %spellbook hash based on fetched results
    while (my ($spell_id, $spell_level) = each %spell_levels) {
        if ($spell_level > -1 && (!exists $spellbook{$spell_id} || $spell_level < $spellbook{$spell_id})) {
            $spellbook{$spell_id} = $spell_level;
        }
    }

    $client->SetBucket("unlocked-spellbook", plugin::SerializeHash(%spellbook));
}

sub GetSpellLevelsByClass {
    my ($spellids_ref, $class_id) = @_;
    
    # Load database handler
    my $dbh = plugin::LoadMysql();
    
    # Define bitmask based on class_id
    my %id_to_bitmask = (
        1  => 1,
        2  => 2,
        3  => 4,
        4  => 8,
        5  => 16,
        6  => 32,
        7  => 64,
        8  => 128,
        9  => 256,
        10 => 512,
        11 => 1024,
        12 => 2048,
        13 => 4096,
        14 => 8192,
        15 => 16384,
        16 => 32768,
    );    

    # Prepare SQL statement
    my $placeholders = join(',', ('?') x @$spellids_ref);
    my $sth = $dbh->prepare("SELECT items.scrolleffect, items.reqlevel FROM items WHERE items.scrolleffect IN ($placeholders) AND (items.classes & ?) = ?");
    $sth->execute(@$spellids_ref, $id_to_bitmask{$class_id}, $id_to_bitmask{$class_id});
    
    # Fetch the results and build a hash
    my %spell_levels;
    while (my ($spell_id, $level) = $sth->fetchrow_array()) {
        $spell_levels{$spell_id} = $level;
    }

    return %spell_levels;
}

sub autopopulate_spellbook {
    my ($client) = @_;

    # Deserialize the unlocked-spellbook bucket to get the spellbook hash
    my %spellbook = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook"));

    # Loop through each spell_id in the spellbook hash
    foreach my $spell_id (keys %spellbook) {
        # Check if the character already knows the spell
        my $known_slot = $client->GetSpellBookSlotBySpellID($spell_id);

        # If the spell isn't known (assuming a return value outside the 0-720 range indicates this)
        if ($known_slot < 0 || $known_slot > 720) {
            # Get a free spellbook slot
            my $free_slot = $client->GetFreeSpellBookSlot();

            # If a free slot is available, scribe the spell into that slot
            if ($free_slot >= 0 && $free_slot <= 720 && $spellbook{$spell_id} <= $client->GetLevel()) {
                $client->ScribeSpell($spell_id, $free_slot, 1);
            } else {
                # No more free slots available, can't scribe further spells
                plugin::RedText("No additional free spellbook slots available for this class.");
                last;
            }
        }
    }
}

sub scribe_specific_spell {
    my ($client, $specific_spell_id) = @_;

    # Deserialize the unlocked-spellbook bucket to get the spellbook hash
    my %spellbook = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook"));

    # Check if the specific spell ID exists in the spellbook hash
    if (exists $spellbook{$specific_spell_id}) {
        # Check if the character already knows the spell
        my $known_slot = $client->GetSpellBookSlotBySpellID($specific_spell_id);

        # If the spell isn't known (assuming a return value outside the 0-720 range indicates this)
        if ($known_slot < 0 || $known_slot > 720) {
            # Get a free spellbook slot
            my $free_slot = $client->GetFreeSpellBookSlot();

            # If a free slot is available, scribe the spell into that slot
            if ($free_slot >= 0 && $free_slot <= 720) {
                $client->ScribeSpell($specific_spell_id, $free_slot, 1);
                quest::debug("Successfully scribed spell ID $specific_spell_id.");
            } else {
                # No free slots available
                plugin::RedText("No additional free spellbook slots available for this class.");
            }
        } else {
            quest::debug("Character already knows spell ID $specific_spell_id.");
        }
    } else {
        quest::debug("Spell ID $specific_spell_id not found in unlocked-spellbook hash.");
    }
}

sub get_spells_in_level_range {
    my ($client, $min_level, $max_level) = @_;

    # Deserialize the unlocked-spellbook bucket to get the spellbook hash
    my %spellbook = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook"));

    # Filter the spells that fall within the given level range
    my @filtered_spells = grep { $spellbook{$_} >= $min_level && $spellbook{$_} <= $max_level } keys %spellbook;

    # Return the filtered spell IDs
    return @filtered_spells;
}

sub spellbook_difference {
    my ($client) = @_;

    # just in case, flush current book into stored hash
    plugin::populate_spellbook($client);

    # Deserialize the unlocked-spellbook bucket to get the stored spellbook hash
    my %stored_spellbook = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook"));

    # Get the total number of spells in the stored hash
    my $stored_spell_count = keys %stored_spellbook;

    # Count the number of spells in the active spellbook
    my $active_spell_count = 0;
    for my $slot (0..720) {
        my $spell_id = $client->GetSpellIDByBookSlot($slot);
        if ($spell_id > 0 && $spell_id <= 44000) {  # Assuming 0xFFFFFFFF indicates an empty slot
            $active_spell_count++;
        }
    }

    # Calculate the difference
    my $difference = abs($stored_spell_count - $active_spell_count);

    return $difference;
}

sub active_spellbook_count {
    my ($client) = @_;

    # Count the number of spells in the active spellbook
    my $active_spell_count = 0;
    for my $slot (0..720) {
        my $spell_id = $client->GetSpellIDByBookSlot($slot);
        if ($spell_id > 0 && $spell_id <= 44000) {
            $active_spell_count++;
        }
    }

    return $active_spell_count;
}

return 1;