-- Apply Augment Schema
UPDATE db_str SET value = "1 (General)" 			        WHERE id = 1  AND type = 16;
UPDATE db_str SET value = "2 (Activated Effect)" 	        WHERE id = 2  AND type = 16;
UPDATE db_str SET value = "3 (Worn Effect)" 		        WHERE id = 3  AND type = 16;
UPDATE db_str SET value = "4 (Combat Effect)"		        WHERE id = 4  AND type = 16;
UPDATE db_str SET value = "10 (Deprecated Slot)"            WHERE id = 10 AND type = 16;
UPDATE db_str SET value = "20 (Weapon Ornamentation)"       WHERE id = 20 AND type = 16;
UPDATE db_str SET value = "21 (Armor Ornamentation)"        WHERE id = 21 AND type = 16;
UPDATE db_str SET VALUE = "30 (Relic)"  					WHERE id = 30 AND type = 16;

UPDATE items
   SET augslot1type     = 0, 
	    augslot2type    = 0, 
	    augslot3type    = 0, 
	    augslot4type    = 0, 
	    augslot5type    = 0,
	    augslot6type    = 0, 	   
	    augslot1visible = 0,
	    augslot2visible = 0,
	    augslot3visible = 0,
	    augslot4visible = 0,
	    augslot5visible = 0,
	    augslot6visible = 0
	WHERE items.id > 0;

-- Type 21 on Vis Slots
UPDATE items
   SET augslot6type     = 21,
       augslot6visible  = 1
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
SET     augslot1type    = 1, -- Type 1
	    augslot2type    = 2, -- Type 2
	    augslot3type    = 3, -- Type 3
	    augslot1visible = 1,
	    augslot2visible = 1,
	    augslot3visible = 1
 WHERE itemtype != 54
   AND slots > 0
   AND races > 0
   AND slots != 4194304
	AND (astr > 0 OR asta > 0 OR adex > 0 OR aagi > 0 OR aint > 0 OR awis > 0 OR hp > 0 OR mana > 0
	  OR fr > 0 OR cr > 0 OR dr > 0 OR mr > 0 OR pr > 0 OR clickeffect > 0 OR proceffect > 0 OR focuseffect > 0);
   
-- Pri\Sec\Ranged Weapons
UPDATE items
   SET  augslot4type    = 4,
        augslot5type    = 10,
        augslot4visible = 1,
	    augslot5visible = 1
 WHERE itemtype != 54
   AND slots & (8192|16384|2048) 
   AND races > 0
   AND ( itemtype <= 5 OR itemtype = 35 OR itemtype = 45 ); 

   
-- Remove Type 2 from items with Click effects
UPDATE items
   SET augslot2type = 0,
       augslot2visible = 0
 WHERE itemtype != 54
   AND clickeffect > 0;
   
-- Remove First Type 3 from items with Focus or Worn effects
UPDATE items
   SET augslot3type    = 0,
       augslot3visible = 0
 WHERE itemtype != 54
   AND ( focuseffect > 0
    OR   worneffect  > 0 );

-- Power Sources
UPDATE items
    SET     augslot1type = 3,
		    augslot2type = 3,
            augslot3type = 3,
            augslot4type = 0,
            augslot5type = 0,
            augslot6type = 0,
            augslot1visible = 1,
            augslot2visible = 1,
            augslot3visible = 1,
            augslot4visible = 1,
            augslot5visible = 1,
            augslot6visible = 1
WHERE slots = 2097152;



 
