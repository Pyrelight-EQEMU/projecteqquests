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

sub ceil_to_nearest_5 {
    my ($value) = @_;
    return ceil($value / 5) * 5;
}

my $max_id = 199999;
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
                my $modifier_minor = ($tier * 0.25);
				
				# Name & ID
				$row->{id} = $row->{id} + (1000000 * $tier);
                $row->{Name} = $row->{Name} . " +$tier";
				if ($row->{charmfile} =~ /^(\d+)#/) {
					$row->{charmfile} =~ s/^\d+#/$row->{id}#/;
				}

                $row->{attuneable} = 1;
                $row->{attuneable} = 1;
				
				# Basic Stats                                
                if ($row->{damage} > 0) {
                    if ($row->{itemtype} != 54) {
                        $row->{damage} = $row->{damage} + max($tier,floor($row->{damage} * $modifier_minor / 2));
                    } else {
                        $row->{damage} = $row->{damage} + $tier;
                    }
                }

                if ($row->{proceffect} > 0) {
                    if ($row->{proceffect} > 0 && $row->{procrate} == 0) {
                        $row->{procrate} = $row->{procrate} + 5;
                    }
                    $row->{procrate} = $row->{proceffect} + ($row->{proceffect} * $modifier);
                }


                $row->{hp} = ceil_to_nearest_5($row->{hp} + ($modifier * $row->{hp}));
                $row->{ac} = $row->{ac} + $tier + ceil($row->{ac} * $modifier_minor);
				
                # Adjusting Heroic Stats
                $row->{heroic_str} = $row->{heroic_str} + ceil(($row->{heroic_str} * $modifier));
                $row->{heroic_sta} = $row->{heroic_sta} + ceil(($row->{heroic_sta} * $modifier));
                $row->{heroic_dex} = $row->{heroic_dex} + ceil(($row->{heroic_dex} * $modifier));
                $row->{heroic_agi} = $row->{heroic_agi} + ceil(($row->{heroic_agi} * $modifier));
                $row->{heroic_int} = $row->{heroic_int} + ceil(($row->{heroic_int} * $modifier));
                $row->{heroic_wis} = $row->{heroic_wis} + ceil(($row->{heroic_wis} * $modifier));
                $row->{heroic_cha} = $row->{heroic_cha} + ceil(($row->{heroic_cha} * $modifier));

                # Adjusting Heroic Resists   
                $row->{heroic_mr} = $row->{heroic_mr} + ceil($row->{heroic_mr} * $modifier);
                $row->{heroic_fr} = $row->{heroic_fr} + ceil($row->{heroic_fr} * $modifier);
                $row->{heroic_cr} = $row->{heroic_cr} + ceil($row->{heroic_cr} * $modifier);
                $row->{heroic_dr} = $row->{heroic_dr} + ceil($row->{heroic_dr} * $modifier);
                $row->{heroic_pr} = $row->{heroic_pr} + ceil($row->{heroic_pr} * $modifier);

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