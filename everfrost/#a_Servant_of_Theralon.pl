my %args = (
    expedition_name => "Feat of Strength: The Permafrost Caverns",
    dz_zone         => "permafrost",
    explain_message => "This is the lair of the White Dragon, Vox. The Master requires three of her scales for his purposes. Proceed, slay the dragon and her minions, and be rewarded.",
    target_list     => [73057, 73058], 

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
    if ($client->GetGM()) {
        $client->AssignTask(1073);
        quest::debug("check");
        quest::debug($client->MovePCDynamicZone('permafrost'));
        quest::debug("check");
    } else {
        plugin::ProcessInstanceDialog(%args);
    }
}