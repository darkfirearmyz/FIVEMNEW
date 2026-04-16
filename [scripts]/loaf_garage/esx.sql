-- if this sql file gives you an error, please update your Maria DB to 10.219 or higher.
ALTER TABLE `owned_vehicles` ADD COLUMN IF NOT EXISTS `damages` LONGTEXT;
ALTER TABLE `owned_vehicles` ADD COLUMN IF NOT EXISTS `garage` VARCHAR(50) NOT NULL DEFAULT "square";
ALTER TABLE `owned_vehicles` ADD COLUMN IF NOT EXISTS `job` VARCHAR(50) NOT NULL DEFAULT "";
ALTER TABLE `owned_vehicles` DROP COLUMN IF EXISTS `stored`; -- since some tables do not store it as a boolean
ALTER TABLE `owned_vehicles` ADD COLUMN IF NOT EXISTS `stored` BOOLEAN NOT NULL DEFAULT 1;
ALTER TABLE `owned_vehicles` ALTER `job` SET DEFAULT "";

UPDATE `owned_vehicles` SET `job`="" WHERE `job` IS NULL;
UPDATE `owned_vehicles` SET `damages`=NULL WHERE `damages` IS NOT NULL;