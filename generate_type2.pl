#!/usr/bin/perl
use warnings;
use DBI;
use POSIX;
use JSON;
use List::Util 'min';
use List::Util 'max';
use Digest::MD5 qw(md5_hex);

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

# Fetch all data from row with id 66953
my $base_data_query = $dbh->prepare("SELECT * FROM items WHERE id = 66953");
$base_data_query->execute();
my $base_data = $base_data_query->fetchrow_hashref();
$base_data_query->finish();

# Prepare statement to select rows based on your criteria
my $select_query = $dbh->prepare(<<SQL);
    SELECT items.*, spells_new.Name as spell_name
    FROM items 
    INNER JOIN spells_new ON items.clickeffect = spells_new.id
    WHERE items.clickeffect > 0 
      AND items.slots > 0 
      AND items.slots < 4194304 
      AND items.classes > 0 
      AND items.races > 0 
      AND items.maxcharges = -1
      AND items.itemtype != 54
      AND items.id <= 999999
      ORDER BY items.id;
SQL

$select_query->execute() or die;

# Create an array of the possible icon values based on the ranges
my @possible_icons = (1940..2002, 6464..6473, 944..965, 1429..1443);

# Start inserting with ID 901000
my $new_id = 910000;

while (my $row = $select_query->fetchrow_hashref()) {
    # Set data for id, name, and idfile from current row
    my $hash = md5_hex($row->{id});
    my $index = hex(substr($hash, 0, 8)) % scalar(@possible_icons);

    # Set New Attributes
    $base_data->{id} = $new_id;
    $base_data->{Name} = "Spellstone: " . $row->{spell_name};
    $base_data->{clickeffect} = $row->{clickeffect};
    $base_data->{casttime} = $row->{casttime};
    $base_data->{casttime_} = $row->{casttime_};
    $base_data->{recastdelay} = max(60, ($row->{recastdelay} || 0));
    $base_data->{recasttype} = $row->{recasttype};    
    $base_data->{slots} = $row->{slots};
    $base_data->{classes} = $row->{classes};
    $base_data->{deity} = $row->{deity};
    $base_data->{augtype} = 2;
    $base_data->{augrestrict} = 0;
    $base_data->{idfile} = 'IT63';
    $base_data->{icon} = $possible_icons[$index];
    $base_data->{lore} = $row->{Name};


    # Construct dynamic SQL for insertion
    my $columns = join(", ", map { "`$_`" } keys %$base_data);  # Add backticks around column names
    my $placeholders = join(", ", map { "?" } keys %$base_data);
    my $values = [values %$base_data];

    my $insert_sql = "REPLACE INTO items ($columns) VALUES ($placeholders)";

    # Prepare the dynamic SQL statement and execute
    my $insert = $dbh->prepare($insert_sql);
    eval {
        $insert->execute(@$values);
    };
    if ($@) {
        die "Error inserting for new ID $new_id. Perhaps it already exists? Error message: $@";
    }

    $new_id++;
    $insert->finish();
}


$select_query->finish();
$dbh->disconnect();

