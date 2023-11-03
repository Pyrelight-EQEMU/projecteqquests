-- Cross-Class Spell Facilitator
my $my_name = $npc->GetCleanName();

sub EVENT_SAY {
    plugin::build_spellpool($client);

    my $charname            = $client->GetCleanName();
    my %spellbook           = plugin::DeserializeHash($client->GetBucket("unlocked-spellbook")) || {};
    my @sorted_spellbook    = sort { $spellbook{$a} <=> $spellbook{$b} } keys %spellbook;
    my $spell_count         = keys %spellbook;
    my $active_count        = active_spellbook_count($client);
    my $remain_space        = 720 - $active_count;    
    
    if($text=~/hail/i) {
        plugin::NPCTell("Greetings, $charname. My role is to assist you in accessing the [magical abilities] of your other classes. How can I help you today?");
    }

    elsif ($text=~/magical abilities/i) {
        my $response_string;
        if ($remain_space <= 10) {
            $response_string = "You don't have many more spellbook slots, $charname.";
        }

        $response_string .= " The spellbook that you carry around is limited by both your level and in total size (720), so it isn't possible to simply know 
                            every concieveable spell simultaneously.";

        if (!$client->GetBucket("autoadd-unlocked-spells")) {
            $response_string .= " Would you like me to [list the spells] which you know, but don't currently have in your book? Alternatively, I can show you
                                how you can [automatically add spells] that you know to your active book.";           
        } else {
            $response_string .= " I see that you are already automatically adding spells. Do you want to [stop doing that], and add them manually going forward?";
        }
        plugin::NPCTell($response_string);
        plugin::YellowText("You know a total of $spell_count spells and have $active_count in your active spellbook. It can fit $remain_space additional spells.");
    }    

    elsif ($text=~/automatically adding spells/i || $text=~/automatically add spells/i) {
        if (!$client->GetBucket("autoadd-unlocked-spells")) {
            plugin::NPCTell("Consider it done, $charname. Going forward, whenever you level-up or enter the world, you'll gain all of the spells that you know into
                            your spellbook.");
            $client->SetBucket("autoadd-unlocked-spells", 1);
            plugin::autopopulate_spellbook($client);
        } else {
            plugin::NPCTell("You are already set up to do that, $charname.");
        }
    }

    elsif ($text=~/stop doing that/i) {
        if ($client->GetBucket("autoadd-unlocked-spells")) {
            plugin::NPCTell("Consider it done, $charname. Going forward, you'll need to come see me in order to add specific spells to your spellbook.");
            $client->SetBucket("autoadd-unlocked-spells", 1);
        } else {
            plugin::NPCTell("You are already set up to do that, $charname.");
        }
    }

    elsif ($text=~/list the spells/i) {
        if ($spell_count) {
            my @learnable_spellbook;  # Initialize as an empty array
            foreach my $spell_id (@sorted_spellbook) {
                my $active_slot = $client->GetSpellBookSlotBySpellID($spell_id);
                if (!($active_slot < 0 || $active_slot > 720)) {
                    push @learnable_spellbook, $spell_id;  # Add spell_id to the array
                }
            }
            if (@learnable_spellbook) {
                plugin::NPCTell("Here, take a look at this list!");
                foreach my $spell_id (@learnable_spellbook) {
                    plugin::PurpleText(sprintf("Level (%02d) - [".quest::saylink("scribe_$spell_id",1, quest::getspellname($spell_id))."]", $spellbook{$spell_id}));
                }
            } else {
                plugin::NPCTell("You have already scribed all of the spells that you know, $charname.");
            }
        } else {
            plugin::NPCTell("You don't seem to know any spells, $charname. Odd!");
        }
    }

}