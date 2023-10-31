# This script should be copy-pasted and reconfigured for each instance master

my $explain_details = "Within the caverns ahead is the lair of the legendary Red Dragon of Antonica - Lord Nagafen. Prove your strength to Master Theralon by slaying her and her minions.";

my $zone_name       = 'soldungb';
my $reward          = 1;
my @task_id         = (45);

sub EVENT_SAY {
    plugin::HandleSay($client, $npc, $zone_name, $explain_details, $reward, @task_id);
}