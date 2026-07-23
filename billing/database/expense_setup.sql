-- Expense Management Feature Setup
-- Run these queries to set up the expense management system

-- 1. Create expense_type table (if not exists)
CREATE TABLE IF NOT EXISTS `expense_type` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `is_active` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Create expense_entry table (if not exists)
CREATE TABLE IF NOT EXISTS `expense_entry` (
  `id` int(12) NOT NULL AUTO_INCREMENT,
  `exp_type` int(12) NOT NULL,
  `content` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `exc_date_time` datetime NOT NULL,
  `entry_date_time` datetime NOT NULL,
  `is_active` int(11) NOT NULL DEFAULT 1,
  `uid` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_expense_type` (`exp_type`),
  KEY `fk_expense_user` (`uid`),
  CONSTRAINT `fk_expense_type` FOREIGN KEY (`exp_type`) REFERENCES `expense_type` (`id`),
  CONSTRAINT `fk_expense_user` FOREIGN KEY (`uid`) REFERENCES `user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. If expense_entry table already exists without amount column, add it:
-- Uncomment the following line if you need to add the amount column to existing table
-- ALTER TABLE `expense_entry` ADD COLUMN `amount` decimal(10,2) NOT NULL DEFAULT 0.00 AFTER `description`;

-- 4. Sample data for expense_type (optional)
-- INSERT INTO `expense_type` (`type`, `is_active`) VALUES
-- ('Office Supplies', 1),
-- ('Utilities', 1),
-- ('Rent', 1),
-- ('Salaries', 1),
-- ('Transportation', 1),
-- ('Maintenance', 1),
-- ('Marketing', 1),
-- ('Other', 1);
