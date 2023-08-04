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
    plugin::ProcessInstanceDialog(%args);

    if ($client->GetGM()) {        
        if($text=~/hail/i) {    
            $client->AssignTask(39);
        } else {
            quest::debug("Ok then");
            my %dz = (
                "instance"    => {
                    "zone" => 58,
                    "version" => 1,
                },
                "compass"    => {
                    "zone" => 58,
                    "x"    => 28,
                    "y" => 2553,
                    "z" => 20,
                    "h"    => 252
                }
            );

            $client->CreateTaskDynamicZone(39, \%dz);
            $client->MovePCDynamicZone(58);
        }    
    }
}