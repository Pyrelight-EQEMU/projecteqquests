 sub EVENT_SAY {
  my $charKey = $client->CharacterID() . "-MAO-Progress";
  my $progress = quest::get_data($charKey);
  if ($text=~/hail/i && !$client->GetGM()) {
    POPUP_DISPLAY();
  } elsif ($client->GetGM()) {
    my $dbh = plugin::LoadMysql();
    # Fetch data from the table
    my $sth = $dbh->prepare("SELECT * FROM items WHERE items.id < 999999");
    $sth->execute() or die $DBI::errstr;

    while (my $row = $sth->fetchrow_hashref()) {
        # Modify the values as per the requirements
        $row->{id} = $row->{id} + 1000000;
        $row->{Name} = $row->{Name} , " +1"; 

        # Create an INSERT statement dynamically
        my $columns = join(",", map { $dbh->quote_identifier($_) } keys %$row);
        my $values  = join(",", map { $dbh->quote($_) } values %$row);
        my $sql = "INSERT INTO items ($columns) VALUES ($values)";

        # Insert the new row into the table
        my $isth = $dbh->prepare($sql);
        $isth->execute() or die $DBI::errstr;
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