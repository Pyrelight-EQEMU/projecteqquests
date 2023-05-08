sub EVENT_SAY
{
    if ($client->GetGM()) {
        if ($text=~/hail/i) {
            quest::whisper("Hello!");
        }
    }
}