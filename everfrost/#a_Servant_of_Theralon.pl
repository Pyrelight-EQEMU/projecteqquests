# This script should be copy-pasted and reconfigured for each instance master

my $explain_details = "WIthin the caverns ahead is the lair of the legendary White Dragon of Antonica - Lady Vox. Prove your strength to Master Theralon by slaying her and her minions."

my $zone_name       = 'permafrost';
my $reward          = 1;
my @task_id = (41, 42, 43);

sub EVENT_SAY {
    plugin::Instance_Hail($client, $npc, $zone_name, $explain_details, $reward, @task_id);
}