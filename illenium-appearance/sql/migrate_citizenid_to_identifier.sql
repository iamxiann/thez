-- Jalankan hanya untuk database Illenium lama yang masih memakai kolom citizenid.
ALTER TABLE `playerskins`
    CHANGE COLUMN `citizenid` `identifier` varchar(255) NOT NULL;

ALTER TABLE `player_outfits`
    DROP INDEX `citizenid_outfitname_model`,
    DROP INDEX `citizenid`,
    CHANGE COLUMN `citizenid` `identifier` varchar(50) DEFAULT NULL,
    ADD UNIQUE KEY `identifier_outfitname_model` (`identifier`, `outfitname`, `model`),
    ADD KEY `idx_player_outfits_identifier` (`identifier`);
