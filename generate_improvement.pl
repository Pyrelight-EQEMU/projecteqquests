#!/usr/bin/perl
use warnings;
use DBI;
use POSIX;
use List::Util qw(max);

sub LoadMysql {
        use DBI;
        use DBD::mysql;
        use JSON;

        my $json = new JSON();

        #::: Load Config
        my $content;
        open(my $fh, '<', "../eqemu_config.json") or die; {
                local $/;
                $content = <$fh>;
        }
        close($fh);

        #::: Decode
        $config = $json->decode($content);

        #::: Set MySQL Connection vars
        $db   = $config->{"server"}{"database"}{"db"};
        $host = "10.10.20.220";
        $user = $config->{"server"}{"database"}{"username"};
        $pass = $config->{"server"}{"database"}{"password"};

        #::: Map DSN
        $dsn = "dbi:mysql:$db:$host:3306";

        #::: Connect and return
        $connect = DBI->connect($dsn, $user, $pass);

        return $connect;
}

# Use the LoadMysql function to get the database handle
my $dbh = LoadMysql();

# Check if successfully connected
unless ($dbh) {
    die "Failed to connect to database.";
}

sub slots {
    my ($bitmask, @slots) = @_;
    my %slot_to_bitmask = (
        'Secondary' => 16384,
        'Head' => 4,
        'Face' => 8,
        'Shoulder' => 64,
        'Arms' => 128,
        'Back' => 256,
        'Bracer 1' => 512,
        'Bracer 2' => 1024,
        'Hands' => 4096,
        'Chest' => 131072,
        'Legs' => 262144,
        'Feet' => 524288,
        'Ear 1' => 2,
        'Ear 2' => 16,
        'Neck' => 32,
        'Primary' => 8192,
        'Ring 1' => 32768,
        'Ring 2' => 65536,
        'Waist' => 1048576
    );
    foreach my $slot (@slots) {
        return 1 if ($bitmask & $slot_to_bitmask{$slot});
    }
    return 0;
}

sub get_rank_name {
    my ($rank) = @_;
    
    my @rank_names = (
        "Enhanced",
        "Superior",
        "Elite",
        "Masterwork",
        "Exquisite",
        "Legendary",
        "Mythical",
        "Ascendant",
        "Divine",
        "Transcendent"
    );

    return $rank_names[$rank - 1] if ($rank >= 1 && $rank <= 10);

    return undef; # Return undefined if rank is outside the valid range
}

my $max_id = 900000;
my $chunk_size = 100;

for my $tier (1..10) {
    for (my $id = 0; $id < $max_id; $id += $chunk_size) {
        # Fetch data from the table
        my $sth = $dbh->prepare("SELECT * FROM items WHERE items.id BETWEEN ? AND ?");
        $sth->execute($id, $id + $chunk_size - 1) or die $DBI::errstr;

        while (my $row = $sth->fetchrow_hashref()) {
            if ($row->{slots} > 0 and $row->{classes} > 0 and $row->{Name} !~ /^Apocryphal/) {

                my @keys = qw(hp mana endur proceffect damage mr cr fr pr dr astr asta adex aagi aint awis heroic_str heroic_sta heroic_dex heroic_agi heroic_int heroic_wis heroic_cha heroic_mr heroic_cr heroic_fr heroic_dr heroic_pr);

                my $all_zero = 1;
                for my $key (@keys) {
                        if ($row->{$key} > 0) {
                                $all_zero = 0;
                                last;
                        }
                }

                next if $all_zero; # Skip to next iteration if all values are zero or less

                my $modifier 	   = ($tier * 0.33);
                my $modifier_minor = ($tier * 0.10);
				
				# Name & ID
				$row->{id} = $row->{id} + (1000000 * $tier);
                $row->{Name} = $row->{Name} . " +$tier";
				if ($row->{charmfile} =~ /^(\d+)#/) {
					$row->{charmfile} =~ s/^\d+#/$row->{id}#/;
				}

                $row->{attuneable} = 1;
				
				# Basic Stats                                
                if ($row->{damage} > 0) {
                    $row->{damage} = $row->{damage} + $tier;
                } elsif ($row->{ac} > 0 && slots($row->{slots}, 'Secondary', 'Head', 'Face', 'Shoulder', 'Arms', 'Back', 'Bracer 1', 'Bracer 2', 'Hands', 'Chest', 'Legs', 'Feet')) {
                    $row->{ac} = $row->{ac} + $tier;
                } elsif (slots($row->{slots}, 'Ear 1', 'Ear 2', 'Neck', 'Primary', 'Secondary', 'Ring 1', 'Ring 2', 'Waist')) {
                    $row->{hp}       = ceil($row->{hp} + ($tier * 5));
                    $row->{spelldmg} = $row->{spelldmg} + floor($tier * 0.10 * (max($row->{aint}, $row->{awis}, $row->{astr})));
                    $row->{healamt}  = $row->{healamt} + floor($tier * 0.10 * (max($row->{aint}, $row->{awis}, $row->{astr})));
                }
                
                if ($row->{itemtype} == 54) {
                    $row->{hp}   = $row->{hp} + ($tier * ($row->{ac} ? 0 : 5));
                    $row->{mana} = $row->{mana} + ($tier * ($row->{ac} ? 0 : 2));
                } else {
                    $row->{hp}   = $row->{hp} + ($tier * ($row->{ac} ? 5 : 10));
                    $row->{mana} = $row->{mana} + ($tier * ($row->{ac} ? 2 : 5));
                }
                
                $row->{procrate} = ($row->{proceffect} && $row->{procrate}) ? $row->{procrate} + ($tier * 10) : $row->{procrate};
				
                # Adjusting Heroic Stats
                $row->{heroic_str} = $row->{heroic_str} + (($row->{heroic_str} + $row->{astr}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_sta} = $row->{heroic_sta} + (($row->{heroic_sta} + $row->{asta}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_dex} = $row->{heroic_dex} + (($row->{heroic_dex} + $row->{adex}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_agi} = $row->{heroic_agi} + (($row->{heroic_agi} + $row->{aagi}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_int} = $row->{heroic_int} + (($row->{heroic_int} + $row->{aint}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_wis} = $row->{heroic_wis} + (($row->{heroic_wis} + $row->{awis}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));
                $row->{heroic_cha} = $row->{heroic_cha} + (($row->{heroic_cha} + $row->{acha}) * ($row->{itemtype} == 54 ? $modifier_minor : $modifier));

                # Adjusting Heroic Resists   
                $row->{heroic_mr} = $row->{heroic_mr} + ($row->{heroic_mr} * $modifier) if ($row->{heroic_mr} > 0);
                $row->{heroic_fr} = $row->{heroic_fr} + ($row->{heroic_fr} * $modifier) if ($row->{heroic_fr} > 0);
                $row->{heroic_cr} = $row->{heroic_cr} + ($row->{heroic_cr} * $modifier) if ($row->{heroic_cr} > 0);
                $row->{heroic_dr} = $row->{heroic_dr} + ($row->{heroic_dr} * $modifier) if ($row->{heroic_dr} > 0);
                $row->{heroic_pr} = $row->{heroic_pr} + ($row->{heroic_pr} * $modifier) if ($row->{heroic_pr} > 0);

                # Create an INSERT statement dynamically
                my $columns = join(",", map { $dbh->quote_identifier($_) } keys %$row);
                my $values  = join(",", map { $dbh->quote($_) } values %$row);
                my $sql = "REPLACE INTO items ($columns) VALUES ($values)";

                print "Creating: $row->{id} ($row->{Name})\n";
                # Insert the new row into the table
                                my $isth = $dbh->prepare($sql)
                                  or die "Failed to prepare insert: " . $dbh->errstr;
                                $isth->execute() or die $DBI::errstr;
            }
        }
    }
}

$dbh->disconnect();