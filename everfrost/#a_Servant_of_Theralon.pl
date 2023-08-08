my %args = (
    expedition_name => "FoS: Permafrost Caverns",
    dz_zone         => "permafrost",
    explain_message => "This is the lair of the White Dragon, Vox. The Master requires three of her scales for his purposes. Proceed, slay the dragon and her minions, and be rewarded.",

    # These are Optional, but you probably want to define them.
    reward          => 1,
    key_required    => 0, # ID of key item                
    target_level    => 52,

    # These are VERY optional (they have reasonable default values)
    min_players     => 1,
    max_players     => 1,
    dz_version      => 10,
    dz_duration     => 604800, # 7 Days
    dz_lockout      => 3600, # 1 Hour
);

sub EVENT_SAY {         


    if ($client->Admin() > 100) {        
        if($text=~/hail/i) {    
            quest::taskselector(39);
        } elsif($text=~/create/i) {
            quest::debug("Ok then");
            my %dz = (
                "instance"     => {
                    "zone"     => 73,
                    "version"  => 10,
                    "duration" => 604800
                }
            );

            $client->CreateTaskDynamicZone(41, \%dz);
            
        } elsif($text=~/enter/i) {
            $client->MovePCDynamicZone("permafrost");
        }
    }
}