use DBI;
use DBD::mysql;
use List::Util qw(max);
use List::Util qw(min);

sub EVENT_SAY
{
    my $charname            = $client->GetCleanName();
    my $progress            = $client->GetBucket("MAO-Progress") || 0;
    my $met_befo            = $client->GetBucket("TheralonIntro") || 0;
    my @locked_classes      = plugin::GetLockedClasses($client);
    my %unlocked_class      = plugin::GetUnlockedClasses($client);
    my $total_classes       = scalar(keys %unlocked_class);
    my $unlocksAvailable    = $client->GetBucket("ClassUnlocksAvailable") || 0;
    my @costs         = (0, 0, 50, 200, 500, 1000, 2000, 3000, 4000, 5000);
    my $expRate             = $client->GetEXPModifier(0);
    my $percentage_expRate  = int($expRate * 100);
    my $FoS_Token           = plugin::Get_FoS_Tokens($client);
    my $FoS_Heroic_Token    = plugin::Get_FoS_Heroic_Tokens($client);
          
    if ($text=~/hail/i) {
        if ($progress < 3) {
            quest::say("Ah! Apologies, apologies! So much to do, so little...well, you understand. Now's not the time, I'm afraid.");
        } elsif(!$met_befo)  {
            plugin::NPCTell("Aha! $charname! The winds whispered of your coming. Spoken with Master Eithan, have you? Here to give an old wizard a [hand]?");
        } else {
            plugin::NPCTell("Ah, $charname, good, good! Time is fleeting, you see. Here for my grand [venture] or to exchange some shiny [tokens]?");
        }
    }

    elsif ($text=~/assist|hand|venture/i && $progress >= 3) {
        plugin::NPCTell("Splendid! Envision with me: A liberated Taelosia, my dear homeland! But oh, the challenges! The Queen of Thorns, our flagship, needs shielding from that treacherous magical storm. 
                        And monsters, oh the monsters! Running amok in Norrath, distractions abound. Fancy a [task]?");
        $client->SetBucket("TheralonIntro", 1) unless $met_befo;
        $client->SetBucket("MAO-Progress", 4)  unless $progress >= 4;
    }

    elsif ($text=~/gathering materials|task/i && $progress > 3 && $met_befo) {
        plugin::NPCTell("Multitasking, my friend! Efficiency! I've dispatched my trusty golems remarkable creations, if I do say so myself to guide you. Find them, heed their words, and they shall bestow 
                        upon you [tokens]. And I? I can make those tokens work wonders for you.");
    }

    elsif ($text=~/tokens/i && $progress > 3 && $met_befo) {
        plugin::NPCTell("Ah, tokens! The universal language of favors. Let me show you the marvels they can bring forth.");
        plugin::Display_FoS_Tokens($client);
        plugin::Display_FoS_Heroic_Tokens($client);
        plugin::PurpleText("- [Class Unlocks] - Unlock Additional Classes! XP Penalties Apply.");
        plugin::PurpleText("- [Special Abilities] - Abilities available nowhere else!");
        plugin::PurpleText("- [Equipment] - Unique Gear and Augments");
        plugin::PurpleText("- [Passive Boosts] - Permanent hidden, passive boosts");
        plugin::PurpleText("- [Consumables] - If you want to spend a finite resource on consumable items, I guess.");

    }

    elsif ($text=~/Class Unlocks/i && $progress > 3 && $met_befo) {
        if (!$unlocksAvailable) {
            plugin::PurpleText("You have no Class Unlock Points available.");
            plugin::PurpleText("WARNING: You will receive a permanent 25%% multiplicative XP penalty for each additional unlock that you purchase. You are currently earning $percentage_expRate%% of normal XP, and have $total_classes classes unlocked.");            
            plugin::PurpleText(sprintf("- [".quest::saylink("link_confirm_unlock", 1, "UNLOCK")."] (Cost: %04d Feat of Strength Tokens) - I confirm that I understand that I will receive an additional permanent XP/AAXP Penalty.", min($costs[$total_classes], 9999)));
        } else {
            plugin::PurpleText("You have $unlocksAvailable Class Unlock Point available.");
            # Build the Menu
            foreach my $class (@locked_classes) {
                my $class_name = quest::getclassname($class);
                my $unlock_menu_item = "- [". quest::saylink("unlock_$class", 1, "UNLOCK") ."] - $class_name";
                plugin::PurpleText($unlock_menu_item); 
            }  
        }      
    }

    elsif ($text=~/Passive Boosts/i && $progress > 3 && $met_befo) {
        my $exp_bonus_index     = $client->GetBucket("exp-bonus-count") || 2;
        my $fac_bonus_index     = $client->GetBucket("fac_bonus_index") || 2;
        my $cur_bonus_index     = $client->GetBucket("cur_bonus_index") || 2;
        my $pot_bonus_index     = $client->GetBucket("pot_bonus_index") || 2;
        my $aug_bonus_index     = $client->GetBucket("aug_bonus_index") || 2;
        my $cmc_bonus_index     = $client->GetBucket("cmc_bonus_index") || 2;

        #Pyrelight TO-DO: implement these other options.

        plugin::PurpleText(sprintf("- [". quest::saylink("link_unlock_expBonus", 1, "UNLOCK") . "] - (Cost: %04d FoS Tokens) - Permanent Bonus: Experience", min($costs[$exp_bonus_index] * 2, 9999)));
        plugin::PurpleText(sprintf("- [UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Faction Gain", min($costs[$fac_bonus_index] * 2, 9999)));
        plugin::PurpleText(sprintf("- [UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Standard Currency Drop Rate", min($costs[$cur_bonus_index] * 2, 9999)));
        plugin::PurpleText(sprintf("- [UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Potions", min($costs[$pot_bonus_index] * 2, 9999)));
        plugin::PurpleText(sprintf("- [UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: World Augments", min($costs[$aug_bonus_index] * 2, 9999)));
        plugin::PurpleText(sprintf("- [UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Converted Mana Crystal drop rate", min($costs[$cmc_bonus_index] * 2, 9999)));         
    }

    elsif ($text eq 'link_confirm_unlock' && $progress > 3 && $met_befo) {
        if ($FoS_Token >= min($costs[$total_classes],9999)) {
            plugin::Spend_FoS_Tokens(min($costs[$total_classes],9999), $client);

            plugin::ApplyExpPenalty($client);

            $client->SetBucket("ClassUnlocksAvailable", 1);
            plugin::YellowText("You have gained a Class Unlock point.");            
            plugin::PurpleText("Would you like to [" . quest::saylink("Class Unlocks", 1, "Unlock a class") . "] now?");
        } else {
            plugin::NPCTell("I'm sorry, $charname. You don't have enough [tokens] to afford that.");
        }        
    }

    elsif ($text eq 'link_unlock_expBonus' && $progress > 3 && $met_befo) {
        my $exp_bonus_index     = $client->GetBucket("exp-bonus-count") || 3;
        if ($FoS_Token >= min($costs[$exp_bonus_index],9999)) {
            plugin::Spend_FoS_Tokens(min($costs[$exp_bonus_index],9999), $client);
            plugin::ApplyExpBonus($client);

            $client->SetBucket("exp-bonus-count", $exp_bonus_index + 1);
        } else {
            plugin::NPCTell("I'm sorry, $charname. You don't have enough [tokens] to afford that.");
        }        
    }
}

sub ApplyExpPenalty {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0) * 0.75;

    $client->SetEXPModifier(0, $expRate);
    $client->SetAAEXPModifier(0, $expRate);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your experience rate has decreased to $percentage_expRate%%.");
}

sub ApplyExpBonus {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0) / 0.75;

    $client->SetEXPModifier(0, $expRate);
    $client->SetAAEXPModifier(0, $expRate);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your experience rate has increased to $percentage_expRate%%.");
}

sub DisplayExpRate {
    my $client  = shift or plugin::val('client');
    my $expRate = $client->GetEXPModifier(0);

    my $percentage_expRate  = int($expRate * 100);
    plugin::YellowText("Your current experience rate is $percentage_expRate%%.");
}

