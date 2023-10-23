use DBI;
use DBD::mysql;
use List::Util qw(max);
use List::Util qw(min);

sub EVENT_SAY
{
    my $charname            = $client->GetCleanName();
    my $expRate             = $client->GetEXPModifier(0);
    my $progress            = $client->GetBucket("MAO-Progress") || 0;
    my $met_befo            = $client->GetBucket("TheralonIntro") || 0;
    my $unlocksAvailable    = $client->GetBucket("ClassUnlocksAvailable") || 0;
    my @locked_classes      = plugin::GetLockedClasses($client);
    my %class               = map { quest::getclassname($_) => $_ } @locked_classes;
    my %unlocked_class      = plugin::GetUnlockedClasses($client);
    my $total_classes       = scalar(keys %unlocked_class);        
    my $percentage_expRate  = int($expRate * 100);
    my $FoS_Token           = plugin::Get_FoS_Tokens($client);
    my $FoS_Heroic_Token    = plugin::Get_FoS_Heroic_Tokens($client);
    my @costs               = (0, 0, 50, 200, 500, 1000, 2000, 3000, 4000, 5000);    

    my %chronal_seals =   ( '33407' => '5',
                            '33408' => '5',
                            '33409' => '5',
                            '33410' => '5',
                            '33411' => '5',
                            '33416' => '5',
                            '33417' => '5',
                            '33418' => '5',
                            '33419' => '5',
                            '33420' => '5',
                            '33421' => '5',
                            '33424' => '5',
                            '33425' => '5',
                            '33428' => '5',
                            '33429' => '5',
                            '33430' => '5',
                            '33431' => '5',
                            '33432' => '5',
                            '33434' => '5'
                           ); 

    my %equipment_index = ( 'Class Emblems' => '',
                            'Chronal Seals' => \%chronal_seals,
                          );

    if ($text eq 'debug' && $client->GetGM()) {
        plugin::Add_Tokens(0, 1000, $client);
        plugin::Add_Tokens(1, 1000, $client);
        my $class_name = Enchanter;
        plugin::YellowText("You are now " . ( (grep { $_ eq lc(substr($class_name, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $class_name.");
        $class_name = Druid;
        plugin::YellowText("You are now " . ( (grep { $_ eq lc(substr($class_name, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $class_name.");
    } 
                    
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
        plugin::display_cmc();
        plugin::YellowText("You currently have $unlocksAvailable Class Unlock Point available.");
        plugin::PurpleText("- [".quest::saylink("Class Unlocks", 1)."]") if @locked_classes;
        plugin::PurpleText("- [Special Abilities]");
        plugin::PurpleText("- [Equipment]");
        plugin::PurpleText("- [Passive Boosts]");
        plugin::PurpleText("- [Consumables]");
    }

    elsif ($text=~/Passive Boosts/i && $progress > 3 && $met_befo) {
        my $exp_bonus_index     = $client->GetBucket("exp_bonus_index") || 2;
        my $fac_bonus_index     = $client->GetBucket("fac_bonus_index") || 2;
        my $cur_bonus_index     = $client->GetBucket("cur_bonus_index") || 2;
        my $pot_bonus_index     = $client->GetBucket("pot_bonus_index") || 2;
        my $aug_bonus_index     = $client->GetBucket("aug_bonus_index") || 2;
        my $cmc_bonus_index     = $client->GetBucket("cmc_bonus_index") || 2;

        #Pyrelight TO-DO: implement these other options.

        plugin::PurpleText("- Passive Abilities and Enhancements");

        if($exp_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- [". quest::saylink("link_unlock_expBonus", 1, "UNLOCK") . "] - (Cost: %04d FoS Tokens) - Permanent Bonus: Experience", min($costs[$exp_bonus_index] * 2, 9999)));
        }
        if($fac_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Faction Gain", min($costs[$fac_bonus_index] * 2, 9999)));
        }
        if($cur_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Standard Currency Drop Rate", min($costs[$cur_bonus_index] * 2, 9999)));
        }
        if($pot_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Potion Drop Rate", min($costs[$pot_bonus_index] * 2, 9999)));
        }
        if($aug_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: World Augments Drop Rate", min($costs[$aug_bonus_index] * 2, 9999)));
        }
        if($cmc_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Converted Mana Crystal Drop Rate", min($costs[$cmc_bonus_index] * 2, 9999)));         
        }
    }

    elsif ($text=~/Equipment/i && $progress > 3 && $met_befo) {
        plugin::PurpleText("- Available Equipment Categories");
        for my $equipment (sort keys %equipment_index) {
            plugin::PurpleText("- [".quest::saylink("link_equi_'$equipment'", 1, "$equipment")."]");
        }
    }

    elsif ($text=~/Class Unlocks/i && $progress > 3 && $met_befo && @locked_classes) {
        if (!$unlocksAvailable && $total_classes <= $#costs) {
            plugin::YellowText("You have no Class Unlock Points available.");
            plugin::YellowText("WARNING: You will receive a permanent 25%% multiplicative XP penalty for each additional unlock that you purchase. You are currently earning $percentage_expRate%% of normal XP, and have $total_classes classes unlocked.");            
            plugin::PurpleText(sprintf("- [".quest::saylink("link_confirm_unlock", 1, "UNLOCK")."] (Cost: %04d Feat of Strength Tokens) - Additional Class Slot", min($costs[$total_classes], 9999)));
        } elsif ($unlocksAvailable && @locked_classes) {
            plugin::YellowText("You currently have $unlocksAvailable Class Unlock Point available.");            
            my @formatted_classes;
            foreach my $class (@locked_classes) {
                my $class_name = quest::getclassname($class);
                plugin::PurpleText("- [". quest::saylink("$class_name", 1, "UNLOCK") ."] - $class_name");
            }            
        } else {
            plugin::NPCTell("Unlocked all classes, you have!");
        }
    }

    elsif ($text =~ /^link_equi_'(.+)'$/ && $progress > 3 && $met_befo) {
        my $selected_equipment = $1;
        if (exists $equipment_index{$selected_equipment}) {
            plugin::PurpleText("- Equipment Category: $selected_equipment");
            for my $item (sort keys %{ $equipment_index{$selected_equipment} }) {
                my $item_link = quest::varlink($item);
                plugin::PurpleText(sprintf("- [".quest::saylink("link_equipbuy_'$item'", 1, "BUY")."] - (Cost: %04d Tokens) - [$item_link] ", min($equipment_index{$selected_equipment}{$item}, 9999)));
            }
        } else {
            plugin::RedText("Invalid equipment selection!");
        }
    }

    elsif ($text =~ /^link_equipbuy_'(.+)'$/) {
        my $item_id     = $1;

        # Loop through all equipment categories
        for my $equipment (keys %equipment_index) {
            if (exists $equipment_index{$equipment}{$item_id}) {
                my $item_link  = quest::varlink($item_id);
                my $item_cost  = $equipment_index{$equipment}{$item_id};

                my $link_FoS_points     = quest::saylink("link_equipbuyconfirm_fos_'$item_id'", 1, "FoS Points");
                my $link_hFoS_points    = quest::saylink("link_equipbuyconfirm_hfos_'$item_id'", 1, "Heroic FoS Points");

                plugin::Display_FoS_Tokens($client);
                plugin::Display_FoS_Heroic_Tokens($client);
                plugin::PurpleText("Would you like to purchase [$item_link] using $item_cost [$link_FoS_points] or [$link_hFoS_points]?");
                return;
            }
        }

        # If the item wasn't found in any category
        if (!$item_found) {
            plugin::RedText("Invalid item selection!");
        }
    }

    elsif ($text =~ /^link_equipbuyconfirm_(hfos|fos)_'(.+)'$/) {
        my $token_type = $1;  # This will capture either "hfos" or "fos"
        my $item_id    = $2;  # This will capture the item ID

        # Sanity check to make sure the item_id is in our equipment lists
        my $item_found = 0;
        my $item_cost;
        
        for my $equipment (keys %equipment_index) {
            if (exists $equipment_index{$equipment}{$item_id}) {
                $item_found = 1;
                $item_cost = $equipment_index{$equipment}{$item_id};
                last;  # Exit the loop once the item is found
            }
        }

        if (!$item_found) {
            plugin::RedText("Invalid item selection!");
            return;  # Exit early if the item isn't found
        }

        # Continue with the purchase logic based on the token type
        $token_type = $token_type eq "hfos" ? 1 : 0;
        if (plugin::Get_Tokens($token_type, $client) > $item_cost) {
            plugin::Spend_Tokens($token_type, $item_cost, $client);
        } else {
            RejectBuy();
            return;
        }
        
        $client->SummonItem($item_id);
        plugin::NPCTell("Absolutely, I can give that to you. If you ever decide that you don't need it anymore, feel free to return it to me for a portion of your tokens back, even if you have it upgraded in the meantime.");
    }

    elsif ($text eq 'link_confirm_unlock' && $progress > 3 && $met_befo && ($total_classes + $unlocksAvailable) <= $#costs) {
        if ($FoS_Token >= min($costs[$total_classes],9999)) {
            plugin::Spend_FoS_Tokens(min($costs[$total_classes],9999), $client);
            ApplyExpPenalty($client);
            $unlocksAvailable++;

            $client->SetBucket("ClassUnlocksAvailable", $unlocksAvailable);
            plugin::YellowText("You have gained a Class Unlock point.");            
            plugin::PurpleText("Would you like to [" . quest::saylink("Class Unlocks", 1, "Unlock a class") . "] now?");
        } else {
            RejectBuy();
        }        
    }

    elsif (exists $class{$text} and $unlocksAvailable >= 1 && $progress > 3 && $met_befo) { #invalid-state rejection is handled inside UnlockClass
        if (plugin::UnlockClass($client, $class{$text})) {
            $client->Message(263, "The Sorcerer closes his eyes in meditation before suddenly striking your forehead with the heel of his open palm.");
            plugin::NPCTell("Ah, marvelous! The arcane energies stir within you, revealing a newfound prowess. Embrace this identity and, as your might expands, return to me. The cosmos has much more in store for you.");
        }
    }

    elsif ($text eq 'link_unlock_expBonus' && $progress > 3 && $met_befo) {
        my $exp_bonus_index     = $client->GetBucket("exp_bonus_index") || 3;
        my $exp_bonus_cost      = min($costs[$exp_bonus_index]*2,9999);
        if ($exp_bonus_index <= $#costs) {
            if ($FoS_Token >= $exp_bonus_cost) {
                plugin::Spend_FoS_Tokens($exp_bonus_cost, $client);

                ApplyExpBonus($client);

                $client->SetBucket("exp_bonus_index", $exp_bonus_index + 1);
            } else {
                RejectBuy();
            }
        }        
    }
}

sub RejectBuy {
    my $client      = plugin::val('client');
    my $charname    = $client->GetCleanName(); 

    plugin::NPCTell("I'm sorry, $charname. You don't have enough [". quest::saylink("task", 1, "Tokens") ."] to afford that.");
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

sub find_item_in_equipment {
    my ($item_id) = @_;

    # Search through the equipment_index for the item_id
    for my $equipment (keys %equipment_index) {
        if (exists $equipment_index{$equipment}{$item_id}) {
            # Return the cost of the item if found
            return $equipment_index{$equipment}{$item_id};
        }
    }

    # Return undef if item not found
    return undef;
}
