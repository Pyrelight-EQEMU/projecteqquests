#!/usr/bin/perl
use warnings;
use DBI;
use POSIX;
use JSON;

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
        $host = '10.10.20.220'; #$config->{"server"}{"database"}{"host"};
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
    SELECT *
    FROM items
    WHERE (slots & 2048 OR slots & 8192 OR slots & 16384)
    AND (itemtype IN (0,1,2,3,4,5,7,8,10,35,36,45,23,24,25,26))
    AND NOT (name LIKE 'Apocryphal %' OR name LIKE 'Rose-Colored %' OR name LIKE 'Fabled %')
    AND NOT clicktype = 3    
    AND id < 999999 
    OR (id IN (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034))
    ORDER BY id;
SQL

$select_query->execute();

my $id_offset = 200000000;

while (my $row = $select_query->fetchrow_hashref()) {
    # Set data for id, name, and idfile from current row

    my $suffix = " Glamour-Stone";
    my $ellipsis = '...';
    my $max_original_length = 64 - length($suffix) - length($ellipsis);

    if (length($row->{Name}) > $max_original_length) {
        $new_name = substr($row->{Name}, 0, $max_original_length) . $ellipsis . $suffix;
    } else {
        $new_name = $row->{Name} . $suffix;
    }

    print "Creating item with Name: $new_name\n";

    $base_data->{id}            = $row->{id} + $id_offset;
    $base_data->{Name}          = $new_name;    
    $base_data->{icon}          = $row->{icon};
    
    # Set augrestrict based on $row->{itemtype}
    if (grep { $_ == $row->{itemtype} } (0, 2, 3, 4, 45, 35)) {
        $base_data->{augrestrict} = 2;
    } elsif ($row->{itemtype} == 8) {
        $base_data->{augrestrict} = 13;
    } elsif ($row->{itemtype} == 5) {
        $base_data->{augrestrict} = 12;
    } else {
        $base_data->{augrestrict} = 0;
    }
    
    $base_data->{slots}         = 26624;

    if (grep { $_ == $row->{id} } (5532, 8495, 10099, 10650, 10651, 14383, 20488, 20490, 20544, 28034)) {
        if ($row->{id} == 5532) { # water sprinkler of nem ankh
            $base_data->{idfile} = 'IT156';
        } elsif ($row->{id} == 8495) { # claw of the savage spirit
            $base_data->{idfile} = 'IT10029';
        } elsif ($row->{id} == 10099) { # fiery defender
            $base_data->{idfile} = 'IT160';
        } elsif ($row->{id} == 10650) { 
            $base_data->{idfile} = 'IT157';
        } elsif ($row->{id} == 10651) { 
            $base_data->{idfile} = 'IT154';
        } elsif ($row->{id} == 14383) { 
            $base_data->{idfile} = 'IT145';
        } elsif ($row->{id} == 20488) { 
            $base_data->{idfile} = 'IT149';
        } elsif ($row->{id} == 20490) { 
            $base_data->{idfile} = 'IT150';
        } elsif ($row->{id} == 20544) {
            $base_data->{idfile} = 'IT153';
        } elsif ($row->{id} == 28034) {
            $base_data->{idfile} = 'IT151';
        }
    } else {
        $base_data->{idfile}        = $row->{idfile};
    }


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
        print "Failed to insert Name: $new_name\n";  # <-- Add this line to output the problematic name
    }
    $insert->finish();
}

$select_query->finish();
$dbh->disconnect();