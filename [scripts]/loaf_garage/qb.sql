-- if this sql file gives you an error, please update your Maria DB to 10.219 or higher.
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `damages` LONGTEXT;
ALTER TABLE `player_vehicles` ADD COLUMN IF NOT EXISTS `garage` VARCHAR(50) NOT NULL DEFAULT "square";

UPDATE `player_vehicles` SET `damages`=NULL WHERE `damages` IS NOT NULL;