# This event fires when the player connects to the world.
sub EVENT_CONNECT {
    # Grant Max Eyes Wide Open AA
    $client->GrantAlternateAdvancementAbility(938, 8, true);

    plugin::CheckLevelFlags();
    plugin::CheckClassAA($client);

    my $bucket_value = $client->GetBucket("FirstLoginAnnounce");

    if (not $client->GetBucket("FirstLoginAnnounce")) {
        my $name  = $client->GetCleanName();
        my $level = $client->GetLevel();
        my $class = quest::getclassname($client->GetClass(), $level);

        plugin::WorldAnnounce("$name (Level $level $class) has logged in for the first time!");
        
        $client->SetBucket("FirstLoginAnnounce", "Yup");
    }
    quest::debug($client->CharacterID());
    quest::debug(plugin::GetClassListString($client));
}

sub EVENT_TASKACCEPTED {
    my $task_name = quest::gettaskname($task_id);
    if ($task_name && $task_name =~ /^Feat of Strength:/) {
        plugin::Instance_Accept();
    }
}


# This event fires when the player levels up.
sub EVENT_LEVEL_UP {
    my $free_skills = [0,1,2,3,4,5,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,28,29,30,31,32,33,34,36,37,38,39,41,42,43,44,45,46,47,49,51,52,54,67,70,71,72,73,74,76];

    foreach my $skill (@$free_skills) {
        if ($client->MaxSkill($skill) > 0 && $client->GetRawSkill($skill) < 1 && $client->CanHaveSkill($skill)) {
            $client->SetSkill($skill, 1);
        }
    }

    if ($client->GetLevel() % 5 == 0) {
        my $name             = $client->GetCleanName();
        my $level            = $client->GetLevel();
        my $active_class     = quest::getclassname($client->GetClass(), $level);
        my $inactive_classes = plugin::GetInactiveClasses($client);

        my $announceString = "$name has achived level $level $active_class!"
                           . ($inactive_classes ? " ($inactive_classes)" : "");

        plugin::WorldAnnounce($announceString);
    }
}

sub EVENT_DISCOVER_ITEM {
    quest::debug("itemid " . $itemid);
    quest::debug("item " . $item);

    my $name = $client->GetCleanName();

    plugin::WorldAnnounceItem("$name has discovered: {item}.",$itemid);    
}

sub EVENT_COMBINE_VALIDATE {
	# $validate_type values = { "check_zone", "check_tradeskill" }
	# criteria exports:
	#       "check_zone"            => zone_id
	#       "check_tradeskill"      => tradeskill_id (not active)
	if ($recipe_id == 10344) {
			if ($validate_type =~/check_zone/i) {
					if ($zone_id != 289 && $zone_id != 290) {
							return 1;
					}
			}
	}

	return 0;
}

sub EVENT_COMBINE_SUCCESS {
    if ($recipe_id =~ /^1090[4-7]$/) {
        $client->Message(1,
            "The gem resonates with power as the shards placed within glow unlocking some of the stone's power. ".
            "You were successful in assembling most of the stone but there are four slots left to fill, ".
            "where could those four pieces be?"
        );
    }
    elsif ($recipe_id =~ /^10(903|346|334)$/) {
        my %reward = (
            melee  => {
                10903 => 67665,
                10346 => 67660,
                10334 => 67653
            },
            hybrid => {
                10903 => 67666,
                10346 => 67661,
                10334 => 67654
            },
            priest => {
                10903 => 67667,
                10346 => 67662,
                10334 => 67655
            },
            caster => {
                10903 => 67668,
                10346 => 67663,
                10334 => 67656
            }
        );
        my $type = plugin::ClassType($class);
        quest::summonitem($reward{$type}{$recipe_id});
        quest::summonitem(67704); # Item: Vaifan's Clockwork Gemcutter Tools
        $client->Message(1,"Success");
    } elsif ($recipe_id == 19460) {
        $client->AddEXP(25000);
        $client->AddAAPoints(5);
        quest::ding();
        plugin::YellowText('You have gained 5 ability points!');
        quest::setglobal("cleric_epic", "7", 5, "F");
    } elsif($recipe_id == 13402 || $recipe_id == 13403 || $recipe_id == 13404 || $recipe_id == 13405) {
        plugin::YellowText("The piece of the metal orb fuses together with the blue diamonds under the intense heat of the forge. As it does, a flurry of images flash through your mind... A ranger and his bear side by side, stoic and unafraid, in a war-torn forest. A bitter tattooed woman with bluish skin wallowing in misery in a waterfront tavern. An endless barrage of crashing thunder and lightning illuminating a crimson brick ampitheater. Two halflings locked in a battle of wits using a checkered board. The images then fade from your mind.");
    } elsif($recipe_id == 13412) {
        quest::setglobal("ranger_epic", "3", 5, "F");
        if(quest::get_zone_short_name() eq "jaggedpine") {
            plugin::YellowText("The seed grows rapidly the moment you push it beneath the soil. It appears at first as a mere shoot, but within moments grows into a stout sapling and then into a gigantic tree. The tree is one you've never seen before. It is the coloration and thick bark of a redwood with the thick bole indicative of the species. The tree is, however, far too short and has spindly branches sprouting from it with beautiful flowers that you would expect on a dogwood. You take all of this in at a glance. It takes you a moment longer to realize that the tree is moving.");
            quest::spawn2(181222, 0, 0, $client->GetX()+3, $client->GetY()+3, $client->GetZ(), 0); # NPC: Red_Dogwood_Treant
        } else {
            plugin::YellowText("The soil conditions prohibit the seed from taking hold");
            $client->SummonItem(72091); # Item: Fertile Earth
            $client->SummonItem(62621); # Item: Senvial's Blessing
            $client->SummonItem(62622); # Item: Grinbik's Blessing
            $client->SummonItem(62844); # Item: Red Dogwood Seed
        }
    } elsif($recipe_id == 13413) {
        $client->AddEXP(25000);
        $client->AddAAPoints(5);
        quest::ding();
        plugin::YellowText('You have gained 5 ability points!');
        quest::setglobal("ranger_epic", "5", 5, "F");
    } elsif($recipe_id == 19914 || $recipe_id == 19915) {
        plugin::YellowText('Very Good. Now we must attune the cage to the specific element we wish to free. You will need two items, one must protect from the element and the other must be able to absorb an incredible amount of that element. This is not a simple task. You must first discover the nature of the spirit that you wish to free and then find such items that will allow you to redirect its power. You must know that each spirit represents a specific area within their element and that is what you must focus on, not their element specifically. For example, Grinbik was an earth spirit, but his area of power was fertility. Senvial was a spirit of Water, but his power was in mist and fog.');
        quest::setglobal("ranger_epic", "8", 5, "F");
    } elsif($recipe_id == 19916) {
        plugin::YellowText("The Red Dogwood Treant speaks to you from within your sword. 'Well done. This should allow me to free a spirit with power over cold and ice. Now you need to find the power that binds the spirit and unleash it where that spirit is bound.'");
    } elsif($recipe_id == 19917) {
        if(quest::get_zone_short_name() eq "anguish") {
            quest::spawn2(317113, 0, 0, $client->GetX(), $client->GetY(), $client->GetZ(), 0); # NPC: #Oshimai_Spirit_of_the_High_Air
        }
    } elsif($recipe_id == 19880) {
        $client->AddEXP(25000);
        $client->AddAAPoints(5);
        quest::ding();
        plugin::YellowText('You have gained 5 ability points!');
        quest::setglobal("paladin_epic", "8", 5, "F");
        plugin::YellowText("As the four soulstones come together, a soft blue light emanates around the dark sword. The soulstones find themselves at home within the sword. A flash occurs and four voices in unison speak in your mind, 'Thank you for saving us and giving us a purpose again. You are truly our savior and our redeemer, and we shall serve you from now on. Thank you, noble knight!");
    } elsif($recipe_id == 19882) {
        $client->AddEXP(25000);
        $client->AddAAPoints(5);
        quest::ding();
        plugin::YellowText('You have gained 5 ability points!');
        quest::setglobal("bard15", "6", 5, "F");
    } elsif($recipe_id == 19888) {
        if(quest::get_zone_short_name() eq "feerrott") {
            quest::spawn2(47209, 0, 0, $client->GetX() + 10, $client->GetY() + 10, $client->GetZ(), 0); # NPC: corrupted_spirit
           plugin::YellowText("The compelled spirit screams as his essence is forced back into the world of the living. 'What is this? Where am I? Who are you? What do you want from me?");
        } else {
            $client->SummonItem(62827); # Item: Mangled Head
            $client->SummonItem(62828); # Item: Animating Heads
            $client->SummonItem(62836); # Item: Soul Stone
        }
    } elsif($recipe_id == 19892) {
        $client->AddAAPoints(5);
        quest::ding();
        plugin::YellowText('You have gained 5 ability points!');
        quest::setglobal("druid_epic", "8", 5, "F");
        plugin::YellowText("You plant the Mind Crystal and the Seed of Living Brambles in the pot. The pot grows warm and immediately you see a vine sprouting from the soil. The vine continues to grow at a tremendous rate. Brambles grow into the heart of the crystal where the core impurity is and split it. They continue to grow at an astounding speed and soon burst the pot and form the Staff of Living Brambles");
    } elsif($recipe_id == 19908) {
        if(quest::get_zone_short_name() eq "anguish") {
            quest::spawn2(317115, 0, 0, $client->GetX() + 3, $client->GetY() + 3, $client->GetZ(), 0); # NPC: #Yuisaha
            $client->SummonItem(62883); # Item: Essence of Rainfall
            $client->SummonItem(62876); # Item: Insulated Container
        } else {
            plugin::YellowText("The rain spirit cannot be reached here");
            $client->SummonItem(47100); # Item: Globe of Discordant Energy
            $client->SummonItem(62876); # Item: Insulated Container
            $client->SummonItem(62878); # Item: Frozen Rain Spirit
            $client->SummonItem(62879); # Item: Everburning Jagged Tree Limb
        }
    } elsif($recipe_id == 19909) {
        $client->AddEXP(50000);
        $client->AddAAPoints(10);
        quest::ding();
        plugin::YellowText('You have gained 10 ability points!');
        quest::setglobal("druid_epic", "13", 5, "F");
    } elsif($recipe_id == 19902) {
        $client->AddEXP(50000);
        $client->AddAAPoints(10);
        quest::ding();
        plugin::YellowText('You have gained 10 ability points!');
        quest::setglobal("warrior_epic", "21", 5, "F");
    } elsif($recipe_id == 19893) {
        plugin::YellowText("Omat should probably see this.");
    } elsif($recipe_id == 19919) {
        quest::setglobal("ench_epic", "9", 5, "F");
        plugin::YellowText("Your Oculus of Persuasion gleams with a blinding light for a moment, dimming quickly to its previous understated beauty. The light has left an image burned into your mind, a strangely tattooed woman chanting by a waterfall.");
    } elsif($recipe_id == 19920) {
        plugin::YellowText("The discordant energy shoots through the staff, sending a shower of sparks through the air. The crystal shatters before you, and as the sparks fade away you notice the changes in your staff.");
        $client->AddEXP(50000);
        $client->AddAAPoints(10);
        quest::ding();
        plugin::YellowText('You have gained 10 ability points!');
        quest::setglobal("ench_epic", "10", 5, "F");
    } elsif($recipe_id == 19925) {
        plugin::YellowText("As you combine all six tokens in the scabbard with Redemption, you feel a tugging at your soul. An energy flows through you as you feel the virtues of your inner self being tugged and tempered into the weapon. For a second you feel drained, but now that feeling has subsided. A final flash of light occurs and a new sword is tempered; Nightbane, Sword of the Valiant");
        $client->AddEXP(50000);
        $client->AddAAPoints(10);
        quest::ding();
        plugin::YellowText('You have gained 10 ability points!');
        quest::setglobal("paladin_epic", "11", 5, "F");
        quest::delglobal("paladin_epic_mmcc");
        quest::delglobal("paladin_epic_hollowc");
    }
}