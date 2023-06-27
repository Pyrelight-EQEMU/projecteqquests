-- Do initial stat seeding
USE peq;

SET @SCALE_FACTOR = 0.5;
SET @MOD2_THRESHOLD = 5;
SET @HEROIC_T = 2;

-- Apply Augment Schema
UPDATE db_str SET value = "1 (General)" 			  WHERE id = 1  AND type = 16;
UPDATE db_str SET value = "2 (Activated Effect)" 	  WHERE id = 2  AND type = 16;
UPDATE db_str SET value = "3 (Worn Effect)" 		  WHERE id = 3  AND type = 16;
UPDATE db_str SET value = "4 (Combat Effect)"		  WHERE id = 4  AND type = 16;
UPDATE db_str SET value = "20 (Weapon Ornamentation)" WHERE id = 20 AND type = 16;
UPDATE db_str SET value = "21 (Armor Ornamentation)"  WHERE id = 21 AND type = 16;

-- Remove Models from non-ornaments
UPDATE items SET idfile = "IT63" WHERE itemtype = 54 AND NOT augtype & (524288|1048576);

-- Configure Item Slots
-- Remove All Aug Slots

UPDATE items
   SET augslot1type = 0, 
	   augslot2type = 0, 
	   augslot3type = 0, 
	   augslot4type = 0, 
	   augslot5type = 0,
	   augslot6type = 0, 	   
	   augslot1visible = 0,
	   augslot2visible = 0,
	   augslot3visible = 0,
	   augslot4visible = 0,
	   augslot5visible = 0,
	   augslot6visible = 0
	WHERE items.id > 0;

-- Type 21 on Vis Slots
UPDATE items
   SET augslot6type = 21,
       augslot6visible = 1
 WHERE itemtype != 54
   AND slots & 923268 > 0
   AND races > 0;
   
-- Type 20 on Primary\Secondary\Ranged slots
UPDATE items
   SET augslot6type = 20,
       augslot6visible = 1
 WHERE itemtype != 54
   AND slots & 26624 > 0
   AND races > 0;   

-- All Items
UPDATE items
   SET augslot1type = 1, -- Type 1
	   augslot2type = 2, -- Type 2
	   augslot3type = 3, -- Type 3
	   augslot1visible = 1,
	   augslot2visible = 1,
	   augslot3visible = 1
 WHERE itemtype != 54
   AND slots BETWEEN 2 AND 4194303
   AND races > 0
   AND classes > 0
	AND (astr > 0 OR asta > 0 OR adex > 0 OR aagi > 0 OR aint > 0 OR awis > 0 OR hp > 0 OR mana > 0
	  OR fr > 0 OR cr > 0 OR dr > 0 OR mr > 0 OR pr > 0 OR clickeffect > 0 OR proceffect > 0 OR focuseffect > 0);
   
-- Pri\Sec\Ranged Weapons
UPDATE items
   SET augslot4type = 4,
	   augslot4visible = 1
 WHERE itemtype != 54
   AND slots & (8192|16384|2048) 
   AND races > 0
   AND classes > 0
   AND ( itemtype <= 5 OR itemtype = 35 OR itemtype = 45 );
   
-- Remove Type 2 from items with Click effects
UPDATE items
   SET augslot2type = 0,
       augslot2visible = 0
 WHERE itemtype != 54
   AND clickeffect > 0;
   
-- Remove First Type 3 from items with Focus or Worn effects
UPDATE items
   SET augslot3type = 0,
       augslot3visible = 0
 WHERE itemtype != 54
   AND ( focuseffect > 0
    OR   worneffect  > 0 );

-- Remove first type 4 from items with proc effects
UPDATE items
   SET augslot4type = 0,
       augslot4visible = 0
 WHERE itemtype != 54
   AND proceffect > 0;
   
-- Disable Type 2 on Non-Visible Armor
UPDATE items
SET augslot2type = 0,
    augslot2visible = 0
WHERE itemtype != 54
AND slots & (4|128|512|1024|4096|131072|262144|524288) = 0;
   
-- All Augments Become Type 1
UPDATE items
   SET augtype = 1
 WHERE itemtype = 54 AND NOT augtype & (524288|1048576);
 
-- Augments with Procs Become Type 4
UPDATE items
   SET augtype = 8
 WHERE itemtype = 54
   AND proceffect > 0;

-- Augments with a Focus or a Worn Effect becomes a Type 3
UPDATE items
   SET augtype = 4
 WHERE itemtype = 54
   AND ( worneffect > 0 OR focuseffect > 0 );
   
-- Reset Stats on all items
UPDATE peq.items, ref.items
   SET peq.items.heroic_str = ref.items.heroic_str,
       peq.items.heroic_sta = ref.items.heroic_sta,
	   peq.items.heroic_dex = ref.items.heroic_dex,
	   peq.items.heroic_agi = ref.items.heroic_agi,
	   peq.items.heroic_int = ref.items.heroic_int,
	   peq.items.heroic_wis = ref.items.heroic_wis,
	   peq.items.heroic_cha = ref.items.heroic_cha,
	   peq.items.astr = ref.items.astr,
	   peq.items.asta = ref.items.asta,
	   peq.items.adex = ref.items.adex,
	   peq.items.aagi = ref.items.aagi,
	   peq.items.aint = ref.items.aint,
	   peq.items.awis = ref.items.awis,
	   peq.items.acha = ref.items.acha,
	   peq.items.hp = ref.items.hp,
	   peq.items.mana = ref.items.mana,
	   peq.items.regen = ref.items.regen,
	   peq.items.enduranceregen = ref.items.enduranceregen,
	   peq.items.fr = ref.items.fr,
	   peq.items.cr = ref.items.cr,
	   peq.items.mr = ref.items.mr,
	   peq.items.dr = ref.items.dr,
	   peq.items.pr = ref.items.pr,
	   peq.items.ac = ref.items.ac,
	   peq.items.damage = ref.items.damage,
	   peq.items.elemdmgamt = ref.items.elemdmgamt,
	   peq.items.banedmgamt = ref.items.banedmgamt,
	   peq.items.backstabdmg = ref.items.backstabdmg
 WHERE peq.items.id = ref.items.id AND peq.items.name = ref.items.name;  

-- Remove all aug slots from items which are no-rent or are summoned
UPDATE items
   SET augslot1type = 0, 
	    augslot2type = 0, 
	    augslot3type = 0, 
	    augslot4type = 0, 
	    augslot5type = 0,
	    augslot6type = 0, 	   
	    augslot1visible = 0,
	    augslot2visible = 0,
	    augslot3visible = 0,
	    augslot4visible = 0,
        augslot5visible = 0,
	    augslot6visible = 0
	WHERE items.id > 0 AND (items.norent = 0 OR items.Name LIKE 'Summoned: %');

-- Add hSTR based on STR, DEX, AGI
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_str = LEAST(99, refItems.heroic_str + CEIL(refItems.astr * 0.25) 
	                                                    + CEIL(refItems.adex * 0.1) 
														+ CEIL(refItems.aagi * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hSTA based on STA, AGI
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_sta = LEAST(99, refItems.heroic_sta + CEIL(refItems.asta * 0.25) 
	                                                    + CEIL(refItems.aagi * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hDEX based on DEX, AGI, INT
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_dex = LEAST(99, refItems.heroic_dex + CEIL(refItems.adex * 0.25) 
	                                                    + CEIL(refItems.aagi * 0.1)
														+ CEIL(refItems.aint * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hAGI based on AGI, WIS
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_agi = LEAST(99, refItems.heroic_agi + CEIL(refItems.adex * 0.25) 
	                                                    + CEIL(refItems.awis * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hINT based on INT, CHA
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_int = LEAST(99, refItems.heroic_int + CEIL(refItems.aint * 0.25)
														+ CEIL(refItems.acha * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hWIS based on WIS, STA
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_wis = LEAST(99, refItems.heroic_wis + CEIL(refItems.awis * 0.25)
														+ CEIL(refItems.asta * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;

-- Add hCHA based on CHA, WIS
UPDATE peq.items AS peqItems, ref.items AS refItems
SET 
    peqItems.heroic_cha = LEAST(99, refItems.heroic_cha + CEIL(refItems.acha * 0.25)
														+ CEIL(refItems.awis * 0.1))
WHERE 
    peqItems.id = refItems.id AND peqItems.name = refItems.name;
	
-- Increase STR,DEX for melees
UPDATE peq.items
   SET heroic_str = LEAST(99, CEIL(heroic_str * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100))))),
       heroic_dex = LEAST(99, CEIL(heroic_dex * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100)))))
 WHERE slots > 0 AND classes > 0 AND races > 0
   AND (classes & (4|8|16|16384)) > 0;
   
-- Increase AGI for dodgey classes
UPDATE peq.items
   SET heroic_agi = LEAST(99, CEIL(heroic_agi * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100)))))
 WHERE slots > 0 AND classes > 0 AND races > 0
   AND (classes & (8|1024|2048|4096|8192|16384)) > 0;
   
-- Increase CHA for casters
UPDATE peq.items
   SET heroic_cha = LEAST(99, CEIL(heroic_cha * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100)))))
 WHERE slots > 0 AND classes > 0 AND races > 0
   AND (classes & (2|32|512|1024|2048|4096|8192)) > 0;
   
-- Increase WIS for wis-casters
UPDATE peq.items
   SET heroic_wis = LEAST(99, CEIL(heroic_wis * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100)))))
 WHERE slots > 0 AND classes > 0 AND races > 0
   AND (classes & (2|32|512)) > 0;
   
-- Increase INT for int-casters
UPDATE peq.items
   SET heroic_int = LEAST(99, CEIL(heroic_int * (GREATEST(1.25, (.75 + GREATEST(reqlevel,reclevel) / 100)))))
 WHERE slots > 0 AND classes > 0 AND races > 0
   AND (classes & (1024|2048|4096|8192)) > 0;

-- Round up HP
UPDATE peq.items
   SET peq.items.hp = Abs(Ceil(peq.items.hp / 5) * 5)
 WHERE peq.items.hp > 0;
 
-- Round up Mana 
UPDATE peq.items
   SET peq.items.mana = Abs(Ceil(peq.items.mana / 5) * 5)
 WHERE peq.items.mana > 0;