 sub EVENT_SAY {
  my $charKey = $client->CharacterID() . "-MAO-Progress";
  my $progress = quest::get_data($charKey);
  if ($text=~/hail/i && !$client->GetGM()) {
    POPUP_DISPLAY();
  } elsif ($client->GetGM()) {
    use Scalar::Util qw(looks_like_number);
    use JSON::MaybeXS qw(is_bool);

    my $dbh = plugin::LoadMysql();
    my $query = $dbh->prepare('SELECT * FROM items WHERE items.id < 999999;');
    $query->execute();

    my $column_names = $query->{NAME};
    my @rows;

    while (my $row = $query->fetchrow_hashref()) {
        my %new_row = %$row;

        $new_row{'id'} = $new_row{'id'} + 1000000;
        $new_row{'Name'} = $new_row{'Name'} . ' +1';

        push @rows, \%new_row;
    }

    $query->finish();

    foreach my $row (@rows) {
        my @columns = keys %$row;
        my $placeholders = join ", ", ("?") x @columns;
        my $column_list = join ", ", @columns;
        my $sql = "REPLACE INTO items ($column_list) VALUES ($placeholders)";
        my $sth = $dbh->prepare($sql);

        my $i = 1;
        for my $value (values %$row) {
            my $type = DBI::SQL_VARCHAR;
            if (looks_like_number($value)) {
                $type = DBI::SQL_INTEGER;
            }
            elsif (is_bool($value)) {
                $type = DBI::SQL_BOOLEAN;
            }
            $sth->bind_param($i++, $value, $type);
        }
        $sth->execute();
    }

    $dbh->disconnect();

  }
 }

sub POPUP_DISPLAY {

  my $yellow = plugin::PWColor("Yellow");
  my $green = plugin::PWColor("Green"); 

  my $discord = "Server Discord: " . plugin::PWHyperLink("https://discord.com/invite/5cFCA7TVgA","5cFCA7TVgA") . "<br><br>";
  my $header = $yellow . plugin::PWAutoCenter("Welcome to Pyrelight!") . "</c><br><br>";

  my $desc = "Pyrelight is a solo-balanced server, meant to offer a challenging experience for veteran players and an alternative take on the 'solo progression' mold.<br><br>
              For more information, please join the server discord and read the " . $green . "#server-info</c> channel.";

  my $text = $header .
             $discord .
             $desc;  
  quest::popup('', $text);
}