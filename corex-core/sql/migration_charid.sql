-- Run this ONCE if your `players` table was created before the multicharacter update
-- and does not have a `charid` column yet. Safe to skip on fresh installs, since
-- sql/corex_framework.sql already creates the column.
--
-- corex-multicharacter itself checks/adds this at startup too, so running this by
-- hand is optional even for multicharacter servers -- it's here mainly for people who
-- update corex-core but do NOT install corex-multicharacter, and want every row to
-- have a charid going forward without waiting for a save.

ALTER TABLE `players` ADD COLUMN `charid` VARCHAR(20) NULL AFTER `identifier`;

UPDATE `players`
SET `charid` = CONCAT('CHR', UPPER(SUBSTRING(MD5(RAND()), 1, 12)))
WHERE `charid` IS NULL;

ALTER TABLE `players` MODIFY `charid` VARCHAR(20) NOT NULL;
ALTER TABLE `players` ADD UNIQUE KEY `charid` (`charid`);
