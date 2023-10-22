use DBI;
use DBD::mysql;

sub EVENT_SAY
{
    my $charname = $client->GetCleanName();
    my $progress = $client->GetBucket("MAO-Progress") || 0;
    if ($client->GetGM()) {        
        if ($text=~/hail/i) {
            plugin::NPCTell("Greetings, $charname")
        }
    }
}