# This script should be copy-pasted and reconfigured for each instance master

my $explain_details = "The veil between planes is weak here. I can transport you to an aspect of the Plane of Hate in order to confront an Avatar of Innoruuk. Prove yourself.";

my $zone_name       = 'hateplaneb';
my $reward          = 2;
my @task_id         = (51, 52);

sub EVENT_SAY {
    plugin::HandleSay($client, $npc, $zone_name, $explain_details, $reward, @task_id);
}