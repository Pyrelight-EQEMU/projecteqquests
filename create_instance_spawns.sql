INSERT INTO spawn2 (
    spawngroupID, zone, version, x, y, z, heading, respawntime, variance, 
    pathgrid, path_when_zone_idle, _condition, cond_value, enabled, animation, 
    min_expansion, max_expansion, content_flags, content_flags_disabled
)
SELECT 
    s.spawngroupID, s.zone, 10, s.x, s.y, s.z, s.heading, s.respawntime, s.variance, 
    s.pathgrid, s.path_when_zone_idle, s._condition, s.cond_value, s.enabled, s.animation, 
    s.min_expansion, s.max_expansion, s.content_flags, s.content_flags_disabled
FROM spawn2 s
LEFT JOIN spawn2 s2 
ON s.x = s2.x AND s.y = s2.y AND s.z = s2.z AND s2.version = 10
WHERE s.zone = 'kedge' AND s.`version` = 0 AND s2.id IS NULL;

INSERT INTO doors (
    doorid, zone, version, name, pos_y, pos_x, pos_z, heading, opentype, guild, 
    lockpick, keyitem, nokeyring, triggerdoor, triggertype, disable_timer, 
    doorisopen, door_param, dest_zone, dest_instance, dest_x, dest_y, dest_z, 
    dest_heading, invert_state, incline, size, buffer, client_version_mask, 
    is_ldon_door, dz_switch_id, min_expansion, max_expansion, content_flags, content_flags_disabled
)
SELECT 
    d.doorid, d.zone, 10, d.name, d.pos_y, d.pos_x, d.pos_z, d.heading, d.opentype, d.guild, 
    d.lockpick, d.keyitem, d.nokeyring, d.triggerdoor, d.triggertype, d.disable_timer, 
    d.doorisopen, d.door_param, d.dest_zone, d.dest_instance, d.dest_x, d.dest_y, d.dest_z, 
    d.dest_heading, d.invert_state, d.incline, d.size, d.buffer, d.client_version_mask, 
    d.is_ldon_door, d.dz_switch_id, d.min_expansion, d.max_expansion, d.content_flags, d.content_flags_disabled
FROM doors d
LEFT JOIN doors d2 
ON d.pos_x = d2.pos_x AND d.pos_y = d2.pos_y AND d.pos_z = d2.pos_z AND d2.version = 10
WHERE d.zone = 'kedge' AND d.`version` = 0 AND d2.id IS NULL;
