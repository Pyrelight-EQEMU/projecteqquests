sub EVENT_SAY
{
    if ($client->GetGM()) {
        if ($text=~/hail/i) {
            plugin:NPCTell("Hello!");
        }
    }
}