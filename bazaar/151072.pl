my %class_abilities = (2  => 20002,
                       3  => 20003,
                       4  => 20004,
                       5  => 20005,
                       6  => 20006,
                       10 => 20010,
                       11 => 20011,
                       12 => 20012,
                       13 => 20013,
                       14 => 20014,
                       15 => 20015,
                       16 => 20016);

sub EVENT_SAY
{
    if ($client->GetGM()) {
        if ($text=~/hail/i) {
            if (!$client->GetBucket("FoSMet") && $client->GetLevel() >= 20) {
                plugin::NPCTell("Greetings, young adventurer. I am Seshethkunaaz, Monarch of Dragons from a realm far beyond this meager existence. I desire to establish a dominion in this world and seek minions of exceptional skill and prowess. As I observe you, I cannot help but be intrigued by your potential, for I sense a [". quest::saylink("fos1a",1,"latent strength") ."] yearning to be awakened.");
            } else {
                plugin::NPCTell("Greetings, young adventurer. I am Seshethkunaaz, Monarch of Dragons from a realm far beyond this meager existence. I desire to establish a dominion in this world and seek minions of exceptional skill and prowess. You are yet too weak to serve me. Return when you have gained some small measure of power.");
                plugin::YellowText("Seshethkunaaz the Displaced will begin have use of you when you reach level 20.");
            }
        } elsif ($text=~/fos1a/i) {
            plugin::NPCTell("I offer you a unique opportunity for a mutually beneficial alliance. Demonstrate your mastery through [". quest::saylink("fos1b",1,"feats of strength") ."] and cunning, and in return, I shall grant you access to secrets long lost in the annals of time: hidden paths to extraordinary abilities, arcane spells shrouded in mystery, and combat techniques that defy mortal comprehension. My knowledge is vast, but I shall share it only with those who prove themselves worthy.");
        } elsif ($text=~/fos1b/i) {
            plugin::NPCTell("Ah, you inquire about the nature of these feats of strength. Very well, I shall enlighten you. Across this vast world, I have positioned my loyal minions in close proximity to beings of formidable power. These minions stand ready to assist you in identifying and challenging these beings and their retinues to single combat. For each victory you achieve, I shall [". quest::saylink("fos1c",1,"reward you") ."] accordingly. The powers I bestow upon you will be commensurate with your success, ranging from the arcane to the martial, expanding your repertoire and deepening your understanding of the mystical arts. The more you prove yourself, the greater the gifts you shall receive.");
        } elsif ($text=~/fos1c/i) {
            plugin::NPCTell("I understand your desire for clarity, and so I shall reveal the nature of my rewards further. As you triumph in these trials and prove your worth, I shall assign to you merits [". quest::saylink("fos_reward_menu_1",1,"that can be spent") ."] to acquire the exceptional abilities and powers I offer. In this way, you are granted the freedom to choose the abilities that best align with your aspirations and combat style. Whether you seek to unlock alternate classes, acquire potent melee skills, or master the arcane spells of the lost wizards, the choice lies in your capable hands.");
            plugin::NPCTell("You've done well to heed my message, though, young adventurer. I will grant you a boon - a single merit to gain access to an alternate class. ");
            plugin::YellowText("Through your heroic actions, you have gained 1 Merit Point.");
            quest::ding();
        }

        #Breaking this out seperately from that logic flow so its easier to work on.
        if ($text=~/fos_reward_menu_1/i) {
            plugin::NPCTell("The rewards I offer are broadly divided into three types; [". quest::saylink("fos_reward_menu_2",1,"alternate classes") ."], [". quest::saylink("fos_reward_menu_3",1,"spells and disciplines") ."], and [". quest::saylink("fos_reward_menu_4",1,"other abilities") ."]");
        } elsif ($text=~/fos_reward_menu_2/i) {            
    my $player_class = $client->GetClassName();

    my %classes = (
        'Cleric' => 'healing and protecting your allies with divine power',
        'Paladin' => 'being a beacon of justice and valor',
        'Shadowknight' => 'harnessing the powers of fear and decay',
        'Druid' => 'embracing the harmony of nature',
        'Shaman' => 'channeling spirits',
        'Necromancer' => 'mastering the undead',
        'Magician' => 'wielding elemental forces',
        'Wizard' => 'unleashing arcane power',
        'Enchanter' => 'manipulating minds',
        'Beastlord' => 'blending beast mastery and physical prowess',
        'Ranger' => 'mastering wilderness and archery'
    );

    my @intro = (
        "You may choose to walk the path of the",
        "Or perhaps you are drawn to the",
        "The path of the",
        "If the harmony of nature calls to you, the",
        "While the",
        "The",
        "While the",
        "The",
        "And the",
        "Perhaps the wild calls to you, drawing you to the",
        "Or the"
    );

    my $output = "Picture the possibilities, " . $client->GetCleanName() . ". ";
    my $i = 0;
    foreach my $class (keys %classes) {
        if ($class ne $player_class) {
            $output .= $intro[$i % @intro] . " [" . quest::saylink("unlock_" . $class, 1, $class) ."], " . $classes{$class} . ". ";
            $i++;
        }
    }
    
    plugin::NPCTell($output);
}
 elsif ($text=~/fos_reward_menu_3/i) {
            plugin::YellowText("This category is not implemented yet");
        } elsif ($text=~/fos_reward_menu_4/i) {
            plugin::YellowText("This category is not implemented yet.");
        }
    }
}