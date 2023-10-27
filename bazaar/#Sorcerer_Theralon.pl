use DBI;
use DBD::mysql;
use List::Util qw(max);
use List::Util qw(min);

sub EVENT_ITEM { 
    my $copper = plugin::val('copper');
    my $silver = plugin::val('silver');
    my $gold = plugin::val('gold');
    my $platinum = plugin::val('platinum');
    my $clientName = $client->GetCleanName();

    my $total_money = ($platinum * 1000) + ($gold * 100) + ($silver * 10) + $copper;
    my $dbh = plugin::LoadMysql();

    if ($total_money > 0) {
        plugin::NPCTell("You gave me both an item to look at and money at the same time. I'm confused about what you want me to do.");
    } elsif ($itemcount{'0'} < 3) {             
        plugin::NPCTell("I'm only interested in considering one item at a time, $clientName.");
    } else {
        foreach my $item_id (grep { $_ != 0 } keys %itemcount) {
            my $base_id = plugin::get_base_id($item_id) || 0;

            # Use plugin::find_item_details to retrieve item details
            my $item_details = plugin::find_item_details($client, $base_id);

            # Check if the details are valid
            if ($item_details) {
                my $item_cost   = $item_details->{value};
                my $equipment   = $item_details->{equipment};                
                my $tier        = plugin::get_upgrade_tier($item_id);
                my $qty         = $item_cost ** ($tier + 1);
                my $entitlement = $client->GetBucket("equip-category-$equipment") || 0;
                
                if (plugin::get_base_id($entitlement) == $base_id) {
                    $client->SetBucket("Theralon-Upgrade-Queue", $item_id);
                    plugin::NPCTell("This looks like one of mine. Would you like to [Upgrade], [Refund] or [Return] this?");
                    delete %itemcount{$item_id};
                } else {
                    plugin::NPCTell("I'm not sure how you have this, and I don't think that you should... but please, just get it away from me.");
                    $client->SummonItem($item_id);
                }
            }
        }
    }

    # After processing all items, return any remaining money
    my $platinum_remainder = int($total_money / 1000);
    $total_money %= 1000;

    my $gold_remainder = int($total_money / 100);
    $total_money %= 100;

    my $silver_remainder = int($total_money / 10);
    $total_money %= 10;

    my $copper_remainder = $total_money;

    $client->AddMoneyToPP($copper_remainder, $silver_remainder, $gold_remainder, $platinum_remainder, 1);

    if (keys %itemcount) {
        plugin::return_items(\%itemcount);
    }
}


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

    if ($text eq 'debug' && $client->GetGM()) {
        plugin::Add_Tokens(0, 1000, $client);
        plugin::Add_Tokens(1, 1000, $client);
        my $class_name = Enchanter;
        plugin::YellowText("You are now " . ( (grep { $_ eq lc(substr($class_name, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $class_name.");
        $class_name = Druid;
        plugin::YellowText("You are now " . ( (grep { $_ eq lc(substr($class_name, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $class_name.");

        $client->SetTitleSuffix("fooogadoo", 1);
        quest::debug(quest::GetZoneLongName('permafrost'));
    } 
                    
    if ($text=~/hail/i) {
        if ($client->GetBucket("Theralon-Upgrade-Queue")) {
            plugin::NPCTell("I'm holding an item for you. Do you want to [Upgrade], [Refund] or [Return] it?");
        } else {
            if ($progress < 3) {
                quest::say("Ah! Apologies, apologies! So much to do, so little...well, you understand. Now's not the time, I'm afraid.");
            } elsif(!$met_befo)  {
                plugin::NPCTell("Aha! $charname! The winds whispered of your coming. Spoken with Master Eithan, have you? Here to give an old wizard a [hand]?");
            } else {
                plugin::NPCTell("Ah, $charname, good, good! Time is fleeting, you see. Here for my grand [venture] or to exchange some shiny [tokens]?");
            }
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
        plugin::DisplayExpRate($client);
        plugin::YellowText("You currently have $unlocksAvailable Class Unlock Point available.");
        plugin::PurpleText("- [".quest::saylink("Class Unlocks", 1)."]") if @locked_classes;
        plugin::PurpleText("- [".quest::saylink("Class Epics", 1)."]") if $total_classes > 1;
        plugin::PurpleText("- [Special Abilities] (Not yet implemented)");
        plugin::PurpleText("- [Equipment]");
        plugin::PurpleText("- [Passive Boosts]");
        plugin::PurpleText("- [Consumables] (Not yet implemented)");
    }

    elsif ($text=~/Class Epics/i && $progress > 3 && $met_befo) {
        my @epic_list = plugin::BuildEpicList($client);

        plugin::YellowText("You may choose to obtain additional copies of Epics or Class Emblems. These are not refundable.");


        foreach my $epic (@epic_list) {
            my $epic_link = quest::varlink($epic);
            my $epic_cost = $client->GetBucket("Extra-$epic-Purchased") ? 0 : 5;
            plugin::PurpleText("- [".quest::saylink("link_epicbuy_\'$epic\'", 1, "BUY")."] - (Cost: $epic_cost FoS Tokens) - [$epic_link]");
        }
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
            plugin::PurpleText(sprintf("- (UNLOCK] - (Cost: %04d FoS Tokens) - Permanent Bonus: Faction Gain (Not yet implemented)", min($costs[$fac_bonus_index] * 2, 9999)));
        }
        if($cur_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Standard Currency Drop Rate (Not yet implemented)", min($costs[$cur_bonus_index] * 2, 9999)));
        }
        if($pot_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Potion Drop Rate (Not yet implemented)", min($costs[$pot_bonus_index] * 2, 9999)));
        }
        if($aug_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: World Augments Drop Rate (Not yet implemented)", min($costs[$aug_bonus_index] * 2, 9999)));
        }
        if($cmc_bonus_index <= $#costs) {
            plugin::PurpleText(sprintf("- (UNLOCK) - (Cost: %04d FoS Tokens) - Permanent Bonus: Converted Mana Crystal Drop Rate (Not yet implemented)", min($costs[$cmc_bonus_index] * 2, 9999)));         
        }
    }

    elsif ($text=~/Class Unlocks/i && $progress > 3 && $met_befo && @locked_classes) {
        if (!$unlocksAvailable && $total_classes <= $#costs) {
            plugin::YellowText("You have no Class Unlock Points available.");
            plugin::YellowText("WARNING: You will receive a permanent 25%% multiplicative XP penalty for each additional unlock that you purchase. You are currently earning $percentage_expRate%% of normal XP, and have $total_classes classes unlocked.");            
            plugin::PurpleText(sprintf("- [".quest::saylink("link_confirm_unlock", 1, "UNLOCK")."] (Cost: %0d Feat of Strength Tokens) - Additional Class Slot", min($costs[$total_classes], 9999)));
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

    elsif ($text=~/Equipment/i && $progress > 3 && $met_befo) {
        my $equipment_ref = plugin::get_equipment_index();

        plugin::PurpleText("- Available Equipment Categories");
        for my $equipment (sort keys %{$equipment_ref}) {
            my $equip_mask = $client->GetBucket("equip-category-$equipment") || 0;
            my $item_found = plugin::get_inventory_DB(plugin::get_base_id($equip_mask), $client) || 0;
            
            quest::debug("$equipment, $equip_mask, $item_found");

            if ($equip_mask && !$item_found) {
                $client->SummonItem($equip_mask);
                plugin::RedText("ERROR: Lost item detected. Restoring...");
            }

            plugin::PurpleText("- [".quest::saylink("link_equi_'$equipment'", 1, "$equipment")."]") unless $equip_mask;
        }
    }

    elsif ($text=~/Upgrade/i) {
        my $item_id         = $client->GetBucket("Theralon-Upgrade-Queue") || 0;
        my $base_id         = plugin::get_base_id($item_id);
        my $item_tier       = plugin::get_upgrade_tier($item_id);
        my $item_details    = plugin::find_item_details($client, $base_id);
        my $equipment       = $item_details->{equipment};
        my $equip_entitl    = $client->GetBucket("equip-category-$equipment") || 0;
        
        if ($item_id && $base_id == plugin::get_base_id($equip_entitl)) {
            my $eff_qty = (2**$item_tier) || 1;
                        
            # Calculating max tier
            my $potential_id = $item_id + 1000000;  # Start by adding 1 million to the base_id
            my $max_tier     = $item_tier;  # Initialize max_tier to the current tier
            while (plugin::item_exists_in_db($potential_id)) {
                $max_tier++;
                $potential_id += 1000000;  # Add 1 million for the next potential tier
            }

            if ($max_tier > $item_tier) {
                plugin::PurpleText("- Select Upgrade Target");
                $max_tier = max($max_tier, $item_tier + 9);
                for my $tier (($item_tier+1)..$max_tier) {
                    my $item_link = quest::varlink($base_id + ($tier * 1000000));

                    # Calculate the difference in quantity required for upgrade
                    my $required_qty = 2**$tier;
                    my $diff_qty = $required_qty - $eff_qty;

                    # Calculate the cost
                    my $base_cost = $item_details->{value};                    
                    my $total_cost = $diff_qty * int($base_cost / 2);

                    plugin::PurpleText(sprintf("- [".quest::saylink("link_upg_\'$base_id\'_\'$tier\'", 1, "UPGRADE")."] - (%04d FoS Tokens) - [$item_link]", min($total_cost, 9999)));
                }
            } else {
                plugin::NPCTell("I'm afraid that item cannot be upgraded any further.");
                $client->SummonItem($item_id);                
                $client->DeleteBucket("Theralon-Upgrade-Queue");
            }
        }
    }

    elsif ($text=~/Refund/i) {
        my $item_id = $client->GetBucket("Theralon-Upgrade-Queue") || 0;
        if ($item_id) {
            # Fetch details for the item
            my $base_id      = plugin::get_base_id($item_id);
            my $item_tier    = plugin::get_upgrade_tier($item_id);
            my $item_details = plugin::find_item_details($client, $base_id);
            my $base_cost    = $item_details->{value};
            my $equipment    = $item_details->{equipment};

            # Calculate the refund amount
            my $eff_qty         = 2**$item_tier;
            my $refund_amount   = $base_cost + int($base_cost / 2) * ($eff_qty - 1);

            # Refund the player
            plugin::Add_FoS_Tokens($refund_amount, $client);
            plugin::NPCTell("Your refund of $refund_amount FoS Tokens has been processed.");

            # Clear the upgrade queue bucket and equipment category
            $client->DeleteBucket("Theralon-Upgrade-Queue");
            $client->DeleteBucket("equip-category-$equipment");
        } else {
            plugin::NPCTell("You don't have any items in the upgrade queue to refund.");
        }
    }

    elsif ($text=~/Return/i) {
        my $item_id = $client->GetBucket("Theralon-Upgrade-Queue") || 0;
        
        if ($item_id) {
            # Return the item to the player
            $client->SummonItem($item_id);
            plugin::NPCTell("Here's your item back.");

            # Clear the upgrade queue bucket
            $client->DeleteBucket("Theralon-Upgrade-Queue");
        } else {
            plugin::NPCTell("You don't have any items in the upgrade queue.");
        }
    }

    elsif ($text=~/link_upg_'(\d+)'_'(\d+)'/i) {
        my $target_tier = $2;
        my $item_id = $client->GetBucket("Theralon-Upgrade-Queue") || 0;

        # Validate item ID and tier
        if ($item_id && $target_tier) {
            # Retrieve item details
            my $base_id         = plugin::get_base_id($item_id);
            my $item_details    = plugin::find_item_details($client, $base_id);
            my $base_cost       = $item_details->{value};
            my $equipment       = $item_details->{equipment};
            my $equip_entitl    = $client->GetBucket("equip-category-$equipment") || 0;
            my $target_item     = $base_id + (1000000 * $target_tier);

            # Need to make sure we are allowed to upgrade this item and have enough data to do it
            if ($item_details && $base_id == plugin::get_base_id($equip_entitl) && plugin::item_exists_in_db($target_item)) {
                # Calculate the difference in quantity required for upgrade
                my $eff_qty         = 2**plugin::get_upgrade_tier($item_id);
                my $required_qty    = 2**$target_tier;
                my $diff_qty        = $required_qty - $eff_qty;

                # Calculate the cost
                my $base_cost = $item_details->{value};                    
                my $total_cost = $diff_qty * int($base_cost / 2);

                if (plugin::Get_FoS_Tokens($client) >= $total_cost) {
                    plugin::NPCTell("Excellent! Here you go!");
                    plugin::Spend_FoS_Tokens($total_cost, $client);  # Assuming you pass the client and cost to this function
                    $client->SummonItem($target_item);
                    $client->DeleteBucket("Theralon-Upgrade-Queue");
                    $client->SetBucket("equip-category-$equipment", $target_item);
                } else {
                    plugin::RejectBuy();
                }
            }
        } else {
            # Invalid Link or player shenanigans
        }
    }

    elsif ($text =~ /^link_equi_'(.+)'$/ && $progress > 3 && $met_befo) {
        my $selected_equipment = $1;
        my $equipment_ref = plugin::get_equipment_index();

        if (exists $equipment_ref->{$selected_equipment}) {
            my $equip_prebuy = $client->GetBucket("equip-category-$selected_equipment");
            plugin::PurpleText("- Equipment Category: $selected_equipment");
            if ($equip_prebuy) {                
                plugin::YellowText("WARNING: You have an outstanding purchase in this category. Nice try.");
            } else {
                plugin::YellowText("WARNING: You will only be allowed to buy one unique item from this category. After you have selected your item, additional copies will be discounted.");                
                for my $item (sort keys %{ $equipment_ref->{$selected_equipment} }) {
                    my $item_link = quest::varlink($item);
                    plugin::PurpleText(sprintf("- [".quest::saylink("link_equipbuy_\'$item\'", 1, "BUY")."] - (Cost: %0d FoS Tokens) - [$item_link] ", min($equipment_ref->{$selected_equipment}{$item}, 9999)));
                }
            }
        } else {
            plugin::RedText("Invalid equipment selection!");
        }
    }

    elsif ($text =~ /^link_equipbuy_'(.+)'$/) {
        my $item_id     = $1;
        my $item_details = plugin::find_item_details($client, $item_id);
        quest::debug($item_details);
        if ($item_details) {
            my $item_cost   = $item_details->{value};
            my $equipment   = $item_details->{equipment};
            if (plugin::Get_FoS_Tokens($client) >= $item_cost) {
                if (!$client->GetBucket("equip-category-$equipment")) {
                    $client->SummonItem($item_id);
                    $client->SetBucket("equip-category-$equipment", $item_id);
                    plugin::Spend_FoS_Tokens($item_cost, $client);
                    plugin::NPCTell("Absolutely, I can give that to you. If you decide that you want that upgraded or you want to return it for your tokens back, just hand it to me.");
                } else {
                    plugin::YellowText("WARNING: You have an outstanding purchase in this category. Nice try.");
                }
            } else {
                plugin::RejectBuy();
            }
        }
    }

    elsif ($text =~ /^link_epicbuy_'(\d+)'$/) { # Ensure the captured group is a number
        my $item_id = $1; # Extract the captured item ID
        my $base_item_id = $item_id % 1000000; # Mod it by 1 million to get the base ID

        # Fetch the class associated with this epic item ID
        my $class_name = GetClassForEpic($base_item_id);

        # Check if this class is unlocked
        if (IsClassUnlocked($client, $class_name)) {
            # The class associated with this epic is unlocked
            # You can proceed with your buy logic or any other actions here
            quest::debug("Enabled");

        } else {
            # The class associated with this epic is NOT unlocked
            # Handle accordingly, maybe send a message to the client or simply ignore
            quest::debug("Disabled");

        }
    }

    elsif ($text eq 'link_confirm_unlock' && $progress > 3 && $met_befo && ($total_classes + $unlocksAvailable) <= $#costs) {
        if ($FoS_Token >= min($costs[$total_classes],9999)) {
            plugin::Spend_FoS_Tokens(min($costs[$total_classes],9999), $client);
            plugin::ApplyExpPenalty($client);
            $unlocksAvailable++;

            $client->SetBucket("ClassUnlocksAvailable", $unlocksAvailable);
            plugin::YellowText("You have gained a Class Unlock point.");            
            plugin::PurpleText("Would you like to [" . quest::saylink("Class Unlocks", 1, "Unlock a class") . "] now?");
        } else {
            plugin::RejectBuy();
        }        
    }

    elsif (exists $class{$text} and $unlocksAvailable >= 1 && $progress > 3 && $met_befo) {
        if (plugin::IsClassUnlocked($client, $text)) {
            plugin::YellowText("You are already " . ( (grep { $_ eq lc(substr($text, 0, 1)) } ('a', 'e', 'i', 'o', 'u')) ? "an" : "a") . " $text.");
        } else {
            if (plugin::UnlockClass($client, $class{$text})) {
                $client->Message(263, "The Sorcerer closes his eyes in meditation before suddenly striking your forehead with the heel of his open palm.");
                plugin::NPCTell("Ah, marvelous! The arcane energies stir within you, revealing a newfound prowess. Embrace this identity and, as your might expands, return to me. The cosmos has much more in store for you.");
            }
        }
    }

    elsif ($text eq 'link_unlock_expBonus' && $progress > 3 && $met_befo) {
        my $exp_bonus_index     = $client->GetBucket("exp_bonus_index") || 3;
        my $exp_bonus_cost      = min($costs[$exp_bonus_index]*2,9999);
        if ($exp_bonus_index <= $#costs) {
            if ($FoS_Token >= $exp_bonus_cost) {
                plugin::Spend_FoS_Tokens($exp_bonus_cost, $client);

                plugin::ApplyExpBonus($client);

                $client->SetBucket("exp_bonus_index", $exp_bonus_index + 1);
            } else {
                plugin::RejectBuy();
            }
        }        
    }
}