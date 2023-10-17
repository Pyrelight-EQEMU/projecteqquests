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

sub is_item_upgradable {
    my $item_id = shift;

    #shortcut if we are already an upgraded item
    if ($item_id >= 1000000) {
        return 1;
    }

    if ($item_id > 20000000) {
        return 0;
    }

    # Calculate the next-tier item ID
    my $next_tier_item_id = get_base_id($item_id) + (1000000 * (get_upgrade_tier($item_id) + 1));

    # Check if the next-tier item exists in the database
    return item_exists_in_db($next_tier_item_id);
}

sub get_continent_prefix {
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
    my ($characterID, $zone_desc, $suffix) = @_;
    my $teleport_zones = plugin::get_zone_data_for_character($characterID, $suffix);

    #quest::debug("Checking for description: $zone_desc");
    #quest::debug("Current Data: " . join(", ", keys %{$teleport_zones}));

    return exists($teleport_zones->{$zone_desc});
}

# Add (or overwrite) data to teleport_zones
# Usage:
#    add_zone_entry(12345, "Zone4", ['data7', 'data8'], '-K');
sub add_zone_entry {
    my ($characterID, $zone_name, $zone_data, $suffix) = @_;
    my $teleport_zones = get_zone_data_for_character($characterID, $suffix);
    $teleport_zones->{$zone_name} = $zone_data;
    set_zone_data_for_character($characterID, $teleport_zones, $suffix);
}

sub fix_zone_data {
    my ($characterID, $suffix) = @_;
    my $charKey = $characterID . "-TL-" . $suffix;
    my $charDataString = quest::get_data($charKey);
    my $data_hash = plugin::deserialize_zone_data($charDataString);  
    
    foreach my $key (keys %$data_hash) {
        delete $data_hash->{''};
        if (quest::GetZoneLongName($key) ne "UNKNOWN") {
            my $zone_sn = $key;
            my $zone_desc = $data_hash->{$key}[0];  # Access the elements using ->

            # Create a new entry in the hash with the zone_desc as the key
            $data_hash->{$zone_desc} = [$key, @{$data_hash->{$key}}[1..4]];

            # Delete the original key from the hash
            delete $data_hash->{$key};
        }
    }
    my $new_serialized_data = plugin::serialize_zone_data($data_hash);

    quest::debug("$charKey, $new_serialized_data");
    quest::set_data($charKey, $new_serialized_data);
}