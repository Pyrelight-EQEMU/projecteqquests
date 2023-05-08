sub EVENT_SAY
{
    if ($client->GetGM()) {
        if ($text=~/hail/i) {
            if (!$client->GetBucket("FoSMet")) {
                plugin::NPCTell("Greetings, young adventurer. I am Seshethkunaaz, Monarch of Dragons from a realm far beyond this meager existence. I desire to establish a dominion in this world and seek minions of exceptional skill and prowess. As I observe you, I cannot help but be intrigued by your potential, for I sense a [". quest::saylink("fos1a",1,"latent strength") ."] yearning to be awakened.");
            }
        }
    }
}