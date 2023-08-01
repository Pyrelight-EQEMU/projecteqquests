my $expedition_name = "Feat of Strength: Permafrost Keep";
my $dz_zone         = "permafrost";
my $reward          = 3;
my $dz = undef;
my $min_players     = 1;
my $max_players     = 1;
my $dz_version      = 10;
my $dz_duration     = 604800; # 7 Days
my $dz_lockout      = 3600; # 1 Hour
my $explain_message = "This is the lair of the White Dragon, Vox. The Master requires three of her scales for his purposes. Proceed, slay the dragon and her minions, and be rewarded.";

#Array of npc_type IDs that we need to kill. Add multiple times for quantity.
my @target_list     = (
                        73057, #Lady Vox
                        73058
                      );                 
my $target_level    = 52;
my $key_required    = 0;

sub EVENT_SAY {
    plugin::ProcessInstanceDialog();
}