use List::Util qw(max);
use POSIX;

sub EVENT_SPAWN
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->Charmed()) {  
       SAVE_PET_STATS($npc);
       UPDATE_PET_STATS($npc);
       $npc->Heal();
    }
}

sub EVENT_TICK 
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->Charmed()) {  
        UPDATE_PET_STATS($npc);
    }
}

sub EVENT_DAMAGE_GIVEN 
{
    if ($npc->IsPet() and $npc->GetOwner()->IsClient() and not $npc->IsTaunting()) {
        $entity_list->GetMobByID($entity_id)->AddToHateList($npc->GetOwner());
    }        
}

sub SAVE_PET_STATS
{
    my $pet = shift;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {     
        $owner->SetBucket("hp_regen", $pet->GetNPCStat("hp_regen"));        
        $owner->SetBucket("min_hit", $pet->GetNPCStat("min_hit"));
        $owner->SetBucket("max_hit", $pet->GetNPCStat("max_hit"));
        $owner->SetBucket("max_hp", $pet->GetNPCStat("max_hp"));
        $owner->SetBucket("atk", $pet->GetNPCStat("atk"));
        $owner->SetBucket("str", $pet->GetNPCStat("str"));
        $owner->SetBucket("sta", $pet->GetNPCStat("sta"));
        $owner->SetBucket("dex", $pet->GetNPCStat("dex"));
        $owner->SetBucket("agi", $pet->GetNPCStat("agi"));
        $owner->SetBucket("ac", $pet->GetNPCStat("ac"));
        $owner->SetBucket("mr", $pet->GetNPCStat("mr"));
        $owner->SetBucket("fr", $pet->GetNPCStat("fr"));
        $owner->SetBucket("cr", $pet->GetNPCStat("cr"));
        $owner->SetBucket("dr", $pet->GetNPCStat("dr"));
        $owner->SetBucket("pr", $pet->GetNPCStat("pr"));

        # We only arrive here on initial summoning.
        $owner->DeleteBucket("epic_proc");
    }
}

sub UPDATE_PET_STATS
{
    my $pet = shift;
    my $owner = $pet->GetOwner()->CastToClient();

    if ($owner) {
        # Create Scalar. The max() probably isn't needed but just to be safe
        my $pet_scalar = APPLY_FOCI($pet) * max(($owner->GetSpellDamage() / 100) + 1, 1);

        # Do max HP adjustment
        my $max_hp = ceil($owner->GetBucket("max_hp") * $pet_scalar); 
        $pet->ModifyNPCStat("max_hp", $max_hp);

        # Set spellscale and healscale for the pet
        $pet->ModifyNPCStat("spellscale", ($owner->GetSpellDamage()) + 100 . "");
        $pet->ModifyNPCStat("healscale", ($owner->GetHealAmount()) + 100 . "");

        # Set Resists
        my $mr = ceil($owner->GetBucket("mr") * $pet_scalar) . "";
        my $fr = ceil($owner->GetBucket("fr") * $pet_scalar) . "";
        my $cr = ceil($owner->GetBucket("cr") * $pet_scalar) . "";
        my $dr = ceil($owner->GetBucket("dr") * $pet_scalar) . "";
        my $pr = ceil($owner->GetBucket("pr") * $pet_scalar) . "";

        $pet->ModifyNPCStat("mr", $mr);
        $pet->ModifyNPCStat("fr", $fr);
        $pet->ModifyNPCStat("cr", $cr);
        $pet->ModifyNPCStat("dr", $dr);
        $pet->ModifyNPCStat("pr", $pr);

        # Set Primary Stats
        my $str = ceil($owner->GetBucket("str") * $pet_scalar) . "";
        my $sta = ceil($owner->GetBucket("sta") * $pet_scalar) . "";
        my $dex = ceil($owner->GetBucket("dex") * $pet_scalar) . "";
        my $agi = ceil($owner->GetBucket("agi") * $pet_scalar) . "";
        my $atk = ceil($owner->GetBucket("atk") * $pet_scalar) . "";

        $pet->ModifyNPCStat("str", $str);
        $pet->ModifyNPCStat("sta", $sta);
        $pet->ModifyNPCStat("dex", $dex);
        $pet->ModifyNPCStat("agi", $agi);
        $pet->ModifyNPCStat("atk", $atk);

        $min_hit = ceil($owner->GetBucket("min_hit") * $pet_scalar) . "";
        $max_hit = ceil($owner->GetBucket("max_hit") * $pet_scalar) . "";

        $pet->ModifyNPCStat("min_hit", $min_hit);
        $pet->ModifyNPCStat("max_hit", $max_hit);
        $pet->ModifyNPCStat("hp_regen", $hp_regen);

        # Set Runspeed
        my $runspeed = $owner->GetRunspeed() / 17 . "";
        $pet->ModifyNPCStat("runspeed", $runspeed);
    }
}

sub APPLY_FOCI 
{
    my $pet = shift;
    my $owner = $pet->GetOwner()->CastToClient();

    my $scale = 1;

    #General
    #Ritual Summoning
    if ($owner->HasAugEquippedbyID(68094) || $owner->HasItemEquippedByID(68918) || $owner->HasItemEquippedByID(68908) || $owner->HasItemEquippedByID(68923)) {
        $scale = 1.3
    }
    #Minion of Darkness
    elsif ($owner->HasItemEquippedByID(28144)) {
        $scale = 1.2;
    }
    #Summoner's Boon
    elsif ($owner->HasAugEquippedbyID(42134)) {
        $scale = 1.1;
    }

    #Magician
    if ($owner->GetClass() == 13) {
        my $mag_epic_scalar = $scale + .5;
        
        # Look for Epic 1.0\Augment
        my $epic1 = $owner->HasItemEquippedByID(28034);
        if ($epic1 > 0) {
            # Check if we applied the proc buff already
            if ($owner->GetBucket("epic_proc") ne "true") {                
                $owner->SetBucket("epic_proc", "true"); 
                $pet->AddMeleeProc(849, 115);
                $pet->AddMeleeProc(848, 25);                           
            }
            if (!($pet->FindBuff(847))) {
                $pet->CastSpell(847, $pet->GetID());
            }

        } elsif ($owner->GetBucket("epic_proc") eq "true") {
            $owner->DeleteBucket("epic_proc");
            $pet->RemoveMeleeProc(849);
            $pet->RemoveMeleeProc(848);
            $pet->BuffFadeBySpellID(847);            
        }
        return $mag_epic_scalar;
    }

    #Beastlord
    if ($owner->GetClass() == 15) {
        my $bst_epic_scalar = $scale + .25;
        
        # Look for Epic 1.0\Augment
        my $epic1 = ($owner->HasItemEquippedByID(8495) && $owner->HasItemEquippedByID(8496));
        if ($epic1 > 0) {
            # Check if we applied the proc buff already
            if ($owner->GetBucket("epic_proc") ne "true") {                
                $owner->SetBucket("epic_proc", "true");
                # TODO CUSTOM PROC            
            } elsif ($owner->GetBucket("epic_proc") eq "true") {
                $owner->DeleteBucket("epic_proc");          
            }
        return $bst_epic_scalar;
        }
    }

    #Necromancer
    if ($owner->GetClass() == 11) {
        my $nec_epic_scalar = $scale + .25;
        
        # Look for Epic 1.0\Augment
        my $epic1 = $owner->HasItemEquippedByID(20544);
        if ($epic1 > 0) {
            # Check if we applied the proc buff already
            if ($owner->GetBucket("epic_proc") ne "true") {                
                $owner->SetBucket("epic_proc", "true");
                # TODO CUSTOM PROC            
            } elsif ($owner->GetBucket("epic_proc") eq "true") {
                $owner->DeleteBucket("epic_proc");
            }
        return $nec_epic_scalar;
        }
    }
    return 1;
}
