# This script should be copy-pasted and reconfigured for each instance master

my $explain_details = "The last of the Kedge, Phinigel Autropos, plots and schemes in the sunken Kedge Keep. Purge it.";

my $zone_name       = 'kedge';
my $reward          = 1;
my @task_id         = (48);

sub EVENT_SAY {
    plugin::HandleSay($client, $npc, $zone_name, $explain_details, $reward, @task_id);
}