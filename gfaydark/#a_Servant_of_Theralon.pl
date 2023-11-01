# This script should be copy-pasted and reconfigured for each instance master

my $explain_details = "The Orcs of Clan Crushbone threaten travelers in the area. Subjugate them in order to earn the favor of the Brotherhood.";

my $zone_name       = 'crushbone';
my $reward          = 1;
my @task_id         = (53, 54);

sub EVENT_SAY {
    plugin::HandleSay($client, $npc, $zone_name, $explain_details, $reward, @task_id);
}