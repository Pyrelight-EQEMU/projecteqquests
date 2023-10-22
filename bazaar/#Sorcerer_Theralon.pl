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
        $client->SetBucket("TheralonIntro", 1);
        $client->SetBucket("MAO-Progress", 4);
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
    
}
