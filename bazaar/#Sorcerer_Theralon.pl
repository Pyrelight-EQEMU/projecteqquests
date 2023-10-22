use DBI;
use DBD::mysql;

sub EVENT_SAY
{
    my $charname = $client->GetCleanName();
    my $progress = $client->GetBucket("MAO-Progress") || 0;
    my $met_befo = $client->GetBucket("TheralonIntro") || 0;
          
    if ($text=~/hail/i) {
        if ($progress < 3) {
            quest::say("Ah! Apologies, apologies! So much to do, so little...well, 
                            you understand. Now's not the time, I'm afraid.");
        } elsif(!$met_befo)  {
            plugin::NPCTell("Aha! $charname! The winds whispered of your coming. 
                            Spoken with Master Eithan, have you? 
                            Here to give an old wizard a [hand]?");
        } else {
            plugin::NPCTell("Ah, $charname, good, good! Time is fleeting, you see. 
                            Here for my grand [venture] or to exchange some shiny [tokens]?");
        }
    }

    elsif ($text=~/assist|hand|venture/i && $progress >= 3) {
        plugin::NPCTell("Splendid! Envision with me: A liberated Taelosia, my dear homeland! 
                        But oh, the challenges! The Queen of Thorns, our flagship, 
                        needs shielding from that treacherous magical storm. 
                        And monsters, oh the monsters! Running amok in Norrath, 
                        distractions abound. Fancy a [task]?");
        $client->SetBucket("TheralonIntro", 1) unless $met_befo;
        $client->SetBucket("MAO-Progress", 4)  unless $progress >= 4;
    }

    elsif ($text=~/gathering materials|task/i && $progress > 3 && $met_befo) {
        plugin::NPCTell("Multitasking, my friend! Efficiency! I've dispatched my trusty golems
                        remarkable creations, if I do say so myself to guide you. 
                        Find them, heed their words, and they shall bestow upon you [tokens]. 
                        And I? I can make those tokens work wonders for you.");
    }

    elsif ($text=~/tokens/i && $progress > 3 && $met_befo) {
        plugin::NPCTell("Ah, tokens! The universal language of favors. 
                        Let me show you the marvels they can bring forth.");
        plugin::PurpleText("- [Class Unlocks] - [Special Abilities] - [Equipment] -");
    }

    elsif ($text=~/Class Unlocks/i && $progress > 3 && $met_befo) {
        my @locked_classes      = plugin::GetLockedClasses($client);
        my %unlocked_class      = plugin::GetUnlockedClasses($client);
        my $total_classes       = scalar(keys %unlocked_class);
        my $unlocksAvailable    = $client->GetBucket("ClassUnlocksAvailable") || 0;
        my @costs = (0, 0, 50, 200, 500, 1000, 2000, 3000, 4000, 5000);

        my $expRate             = $client->GetEXPModifier(0);
        my $percentage_expRate  = int($expRate * 100);
        if (!$unlocksAvailable) {
            my $link_confirm_unlock = "- [".quest::saylink("link_confirm_unlock", 1, "UNLOCK")."] - I confirm that I understand that I will recieve a permanent XP/AAXP Penalty.";

            plugin::PurpleText("WARNING: You will receive a permanent 25%% multiplicative XP/AAXP penalty for each additional unlock that you purchase.");            
            plugin::PurpleText("You are currently earning $percentage_expRate%% of normal XP, and have $total_classes unlocked.");
            plugin::PurpleText("$link_confirm_unlock");
        } else {
            # Other code or conditions can go here.
        }


        # Build the Menu
        #foreach my $class (@locked_classes) {
        #    my $class_cost = $costs[$total_classes];
        #    my $class_name = quest::getclassname($class);
        #    my $unlock_menu_item = "- [". quest::saylink("unlock_$class", 1, "UNLOCK") ."] ($class_cost) - $class_name";
        #    plugin::PurpleText($unlock_menu_item); 
        #}        
    }
}