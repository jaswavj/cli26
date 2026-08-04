/*
SQLyog Community v13.3.1 (64 bit)
MySQL - 8.4.7 : Database - saiexchange
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`saiexchange` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `saiexchange`;

/*Table structure for table `ce_bill_ledger` */

DROP TABLE IF EXISTS `ce_bill_ledger`;

CREATE TABLE `ce_bill_ledger` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int DEFAULT NULL,
  `bill_type` int NOT NULL,
  `bill_id` int NOT NULL,
  `advance` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `final_advance` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `due` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `final_due` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `is_cash` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `is_bank` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `payment_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_bill_ledger_payment` (`payment_id`),
  KEY `fk_ce_bill_ledger_customer` (`customer_id`),
  CONSTRAINT `fk_ce_bill_ledger_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_bill_ledger` */

insert  into `ce_bill_ledger`(`id`,`customer_id`,`bill_type`,`bill_id`,`advance`,`final_advance`,`due`,`final_due`,`is_cash`,`is_bank`,`payment_id`,`created_at`) values 
(1,1,2,1,0.0000,0.0000,0.0000,100.0000,100.0000,0.0000,1,'2026-08-03 15:38:51'),
(2,1,1,1,0.0000,100.0000,100.0000,100.0000,100.0000,0.0000,1,'2026-08-03 15:38:58'),
(3,1,6,4,100.0000,0.0000,100.0000,100.0000,100.0000,0.0000,1,'2026-08-03 15:39:44'),
(4,1,3,1,0.0000,0.0000,100.0000,0.0000,100.0000,0.0000,1,'2026-08-03 15:39:50'),
(5,2,2,2,0.0000,0.0000,0.0000,50000.0000,50000.0000,0.0000,1,'2026-08-04 12:45:21'),
(6,2,4,4,0.0000,0.0000,50000.0000,50550.0000,0.0000,0.0000,1,'2026-08-04 12:45:53'),
(7,2,4,5,0.0000,0.0000,50550.0000,50550.0000,545.0000,0.0000,1,'2026-08-04 12:47:13'),
(8,2,4,6,0.0000,0.0000,50550.0000,50330.0000,0.0000,0.0000,1,'2026-08-04 16:48:16'),
(9,2,1,2,0.0000,100.0000,50330.0000,50330.0000,100.0000,0.0000,1,'2026-08-04 16:49:06'),
(10,2,4,7,100.0000,0.0000,50330.0000,50830.0000,500.0000,0.0000,1,'2026-08-04 16:49:38');

/*Table structure for table `ce_bill_type` */

DROP TABLE IF EXISTS `ce_bill_type`;

CREATE TABLE `ce_bill_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_bill_type` */

insert  into `ce_bill_type`(`id`,`name`) values 
(1,'add advance(opening)'),
(2,'add due(opening)'),
(3,'due collection'),
(4,'exchange bill'),
(5,'Expense'),
(6,'Purchase due payment');

/*Table structure for table `ce_currency` */

DROP TABLE IF EXISTS `ce_currency`;

CREATE TABLE `ce_currency` (
  `id` int NOT NULL AUTO_INCREMENT,
  `currency_code` varchar(10) NOT NULL,
  `currency_name` varchar(100) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `is_base` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ce_currency_code` (`currency_code`),
  KEY `idx_ce_currency_active` (`is_active`),
  KEY `idx_ce_currency_base` (`is_base`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency` */

insert  into `ce_currency`(`id`,`currency_code`,`currency_name`,`is_active`,`is_base`,`created_at`,`updated_at`) values 
(1,'INR','INR',1,1,'2026-07-28 21:34:00','2026-07-28 21:34:00'),
(2,'USD','USD',1,0,'2026-07-28 21:34:36','2026-07-28 21:34:36'),
(3,'EUR','EURO',1,0,'2026-07-28 21:57:38','2026-07-28 21:57:38');

/*Table structure for table `ce_currency_exchange` */

DROP TABLE IF EXISTS `ce_currency_exchange`;

CREATE TABLE `ce_currency_exchange` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `exchange_type` tinyint NOT NULL COMMENT '1=Purchase, 2=Sale',
  `exchange_date` date NOT NULL,
  `currency_id` int NOT NULL,
  `amount` decimal(18,4) NOT NULL,
  `counter_currency_id` int NOT NULL,
  `counter_amount` decimal(18,4) NOT NULL,
  `paid` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `balance` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `due_adjusted` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `advance_adjusted` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `payment_id` int NOT NULL,
  `notes` text,
  `uid` int NOT NULL,
  `is_cancelled` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_currency_exchange_customer` (`customer_id`),
  KEY `idx_ce_currency_exchange_currency` (`currency_id`),
  KEY `idx_ce_currency_exchange_date` (`exchange_date`),
  KEY `idx_ce_currency_exchange_type` (`exchange_type`),
  KEY `idx_ce_currency_exchange_payment` (`payment_id`),
  KEY `idx_ce_currency_exchange_cancelled` (`is_cancelled`),
  KEY `idx_ce_currency_exchange_counter` (`counter_currency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_exchange` */

insert  into `ce_currency_exchange`(`id`,`customer_id`,`exchange_type`,`exchange_date`,`currency_id`,`amount`,`counter_currency_id`,`counter_amount`,`paid`,`balance`,`due_adjusted`,`advance_adjusted`,`payment_id`,`notes`,`uid`,`is_cancelled`,`created_at`) values 
(1,1,1,'2026-07-28',2,10.0000,1,1010.0000,500.0000,510.0000,0.0000,0.0000,1,'wwww',1,0,'2026-07-28 21:37:18'),
(2,1,2,'2026-07-28',2,1.0000,1,105.0000,50.0000,55.0000,0.0000,0.0000,1,'a',1,0,'2026-07-28 21:40:21'),
(3,2,1,'2026-07-28',3,15.0000,1,1665.0000,1665.0000,0.0000,0.0000,0.0000,2,NULL,1,0,'2026-07-28 21:58:13'),
(4,2,2,'2026-08-04',3,5.0000,1,550.0000,0.0000,550.0000,0.0000,0.0000,1,NULL,1,0,'2026-08-04 12:45:53'),
(5,2,2,'2026-08-04',2,5.0000,1,545.0000,545.0000,0.0000,0.0000,0.0000,1,NULL,1,0,'2026-08-04 12:47:13'),
(6,2,1,'2026-08-04',3,2.0000,1,220.0000,0.0000,0.0000,220.0000,0.0000,1,'qq',1,0,'2026-08-04 16:48:16'),
(7,2,2,'2026-08-04',3,10.0000,1,1100.0000,500.0000,500.0000,0.0000,100.0000,1,NULL,1,0,'2026-08-04 16:49:38');

/*Table structure for table `ce_currency_limit` */

DROP TABLE IF EXISTS `ce_currency_limit`;

CREATE TABLE `ce_currency_limit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `currency_id` int NOT NULL,
  `ref_currency_id` int NOT NULL,
  `min_value` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `max_value` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ce_currency_limit_pair` (`currency_id`,`ref_currency_id`),
  KEY `idx_ce_currency_limit_ref` (`ref_currency_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_limit` */

insert  into `ce_currency_limit`(`id`,`currency_id`,`ref_currency_id`,`min_value`,`max_value`,`created_at`,`updated_at`) values 
(1,2,1,100.0000,110.0000,'2026-07-28 21:34:36','2026-07-28 21:34:36'),
(2,1,2,0.0000,0.0000,'2026-07-28 21:34:36','2026-07-28 21:34:36'),
(3,3,1,110.0000,112.0000,'2026-07-28 21:57:38','2026-07-28 21:57:38');

/*Table structure for table `ce_currency_stock` */

DROP TABLE IF EXISTS `ce_currency_stock`;

CREATE TABLE `ce_currency_stock` (
  `id` int NOT NULL AUTO_INCREMENT,
  `currency_id` int NOT NULL,
  `quantity` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ce_currency_stock_currency` (`currency_id`),
  CONSTRAINT `fk_ce_currency_stock_currency` FOREIGN KEY (`currency_id`) REFERENCES `ce_currency` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_stock` */

insert  into `ce_currency_stock`(`id`,`currency_id`,`quantity`,`updated_at`) values 
(1,1,100560.0000,'2026-08-04 16:49:38'),
(2,2,4.0000,'2026-08-04 12:47:13'),
(8,3,2.0000,'2026-08-04 16:49:38');

/*Table structure for table `ce_currency_stock_adjustment` */

DROP TABLE IF EXISTS `ce_currency_stock_adjustment`;

CREATE TABLE `ce_currency_stock_adjustment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `currency_id` int NOT NULL,
  `adjustment_type` tinyint NOT NULL COMMENT '1=Add Stock, 2=Remove Stock',
  `quantity` decimal(18,4) NOT NULL,
  `reason` text NOT NULL,
  `uid` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_stock_adj_currency` (`currency_id`),
  KEY `idx_ce_stock_adj_type` (`adjustment_type`),
  CONSTRAINT `fk_ce_stock_adj_currency` FOREIGN KEY (`currency_id`) REFERENCES `ce_currency` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_stock_adjustment` */

insert  into `ce_currency_stock_adjustment`(`id`,`currency_id`,`adjustment_type`,`quantity`,`reason`,`uid`,`created_at`) values 
(1,1,1,100000.0000,'w',1,'2026-07-28 21:36:39');

/*Table structure for table `ce_currency_stock_transaction` */

DROP TABLE IF EXISTS `ce_currency_stock_transaction`;

CREATE TABLE `ce_currency_stock_transaction` (
  `id` int NOT NULL AUTO_INCREMENT,
  `exchange_id` int DEFAULT NULL,
  `adjustment_id` int DEFAULT NULL,
  `transfer_id` int DEFAULT NULL,
  `currency_id` int NOT NULL,
  `txn_type` tinyint NOT NULL COMMENT '1=Purchase In, 2=Sale Out',
  `quantity` decimal(18,4) NOT NULL,
  `before_qty` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `after_qty` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_stock_txn_exchange` (`exchange_id`),
  KEY `idx_ce_stock_txn_currency` (`currency_id`),
  KEY `idx_ce_stock_txn_type` (`txn_type`),
  KEY `idx_ce_stock_txn_adjustment` (`adjustment_id`),
  KEY `idx_ce_stock_txn_transfer` (`transfer_id`),
  CONSTRAINT `fk_ce_currency_stock_txn_currency` FOREIGN KEY (`currency_id`) REFERENCES `ce_currency` (`id`),
  CONSTRAINT `fk_ce_stock_txn_adjustment` FOREIGN KEY (`adjustment_id`) REFERENCES `ce_currency_stock_adjustment` (`id`),
  CONSTRAINT `fk_ce_stock_txn_exchange` FOREIGN KEY (`exchange_id`) REFERENCES `ce_currency_exchange` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_stock_transaction` */

insert  into `ce_currency_stock_transaction`(`id`,`exchange_id`,`adjustment_id`,`transfer_id`,`currency_id`,`txn_type`,`quantity`,`before_qty`,`after_qty`,`created_at`) values 
(1,NULL,1,NULL,1,3,100000.0000,0.0000,100000.0000,'2026-07-28 21:36:39'),
(2,1,NULL,NULL,2,1,10.0000,0.0000,10.0000,'2026-07-28 21:37:18'),
(3,1,NULL,NULL,1,2,500.0000,100000.0000,99500.0000,'2026-07-28 21:37:18'),
(4,2,NULL,NULL,2,2,1.0000,10.0000,9.0000,'2026-07-28 21:40:21'),
(5,2,NULL,NULL,1,1,50.0000,99500.0000,99550.0000,'2026-07-28 21:40:21'),
(6,NULL,NULL,NULL,1,2,50.0000,99550.0000,99500.0000,'2026-07-28 21:48:23'),
(7,NULL,NULL,NULL,1,1,15.0000,99500.0000,99515.0000,'2026-07-28 21:48:35'),
(8,3,NULL,NULL,3,1,15.0000,0.0000,15.0000,'2026-07-28 21:58:13'),
(9,NULL,NULL,1,3,2,5.0000,15.0000,10.0000,'2026-07-28 22:08:00'),
(10,NULL,NULL,2,2,1,5.0000,9.0000,14.0000,'2026-07-28 22:08:19'),
(11,NULL,NULL,1,3,1,5.0000,10.0000,15.0000,'2026-07-28 22:08:33'),
(12,NULL,NULL,2,2,2,5.0000,14.0000,9.0000,'2026-07-28 22:08:36'),
(13,NULL,NULL,NULL,1,2,100.0000,99515.0000,99415.0000,'2026-08-03 15:39:44'),
(14,NULL,NULL,NULL,1,1,100.0000,99415.0000,99515.0000,'2026-08-03 15:39:50'),
(15,4,NULL,NULL,3,2,5.0000,15.0000,10.0000,'2026-08-04 12:45:53'),
(16,5,NULL,NULL,2,2,5.0000,9.0000,4.0000,'2026-08-04 12:47:13'),
(17,5,NULL,NULL,1,1,545.0000,99515.0000,100060.0000,'2026-08-04 12:47:13'),
(18,6,NULL,NULL,3,1,2.0000,10.0000,12.0000,'2026-08-04 16:48:16'),
(19,7,NULL,NULL,3,2,10.0000,12.0000,2.0000,'2026-08-04 16:49:38'),
(20,7,NULL,NULL,1,1,500.0000,100060.0000,100560.0000,'2026-08-04 16:49:38');

/*Table structure for table `ce_currency_transfer` */

DROP TABLE IF EXISTS `ce_currency_transfer`;

CREATE TABLE `ce_currency_transfer` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `currency_id` int NOT NULL,
  `transfer_type` tinyint NOT NULL COMMENT '1=Give, 2=Get',
  `quantity` decimal(18,4) NOT NULL,
  `transfer_date` date NOT NULL,
  `notes` text,
  `status` tinyint NOT NULL DEFAULT '0' COMMENT '0=Open, 1=Returned',
  `return_date` date DEFAULT NULL,
  `uid` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_currency_transfer_customer` (`customer_id`),
  KEY `idx_ce_currency_transfer_currency` (`currency_id`),
  KEY `idx_ce_currency_transfer_date` (`transfer_date`),
  KEY `idx_ce_currency_transfer_type` (`transfer_type`),
  KEY `idx_ce_currency_transfer_status` (`status`),
  CONSTRAINT `fk_ce_currency_transfer_currency` FOREIGN KEY (`currency_id`) REFERENCES `ce_currency` (`id`),
  CONSTRAINT `fk_ce_currency_transfer_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_currency_transfer` */

insert  into `ce_currency_transfer`(`id`,`customer_id`,`currency_id`,`transfer_type`,`quantity`,`transfer_date`,`notes`,`status`,`return_date`,`uid`,`created_at`) values 
(1,1,3,1,5.0000,'2026-07-28','fd',1,'2026-07-28',1,'2026-07-28 22:08:00'),
(2,2,2,2,5.0000,'2026-07-28','d',1,'2026-07-28',1,'2026-07-28 22:08:19');

/*Table structure for table `ce_cus_advance` */

DROP TABLE IF EXISTS `ce_cus_advance`;

CREATE TABLE `ce_cus_advance` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `amount` decimal(18,4) NOT NULL,
  `notes` text,
  `payment_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_cus_advance_customer` (`customer_id`),
  KEY `idx_ce_cus_advance_payment` (`payment_id`),
  CONSTRAINT `fk_ce_cus_advance_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_cus_advance` */

insert  into `ce_cus_advance`(`id`,`customer_id`,`amount`,`notes`,`payment_id`,`created_at`) values 
(1,1,100.0000,NULL,1,'2026-08-03 15:38:58'),
(2,2,100.0000,NULL,1,'2026-08-04 16:49:06');

/*Table structure for table `ce_cus_advance_payment` */

DROP TABLE IF EXISTS `ce_cus_advance_payment`;

CREATE TABLE `ce_cus_advance_payment` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `amount` decimal(18,4) NOT NULL,
  `notes` text,
  `payment_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_cus_advance_payment_customer` (`customer_id`),
  KEY `idx_ce_cus_advance_payment_payment` (`payment_id`),
  CONSTRAINT `fk_ce_cus_advance_payment_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_cus_advance_payment` */

insert  into `ce_cus_advance_payment`(`id`,`customer_id`,`amount`,`notes`,`payment_id`,`created_at`) values 
(1,1,10.0000,'s',1,'2026-07-28 21:43:34'),
(2,1,250.0000,'q',1,'2026-07-28 21:44:37'),
(3,1,50.0000,NULL,1,'2026-07-28 21:48:23'),
(4,1,100.0000,NULL,1,'2026-08-03 15:39:44');

/*Table structure for table `ce_cus_due` */

DROP TABLE IF EXISTS `ce_cus_due`;

CREATE TABLE `ce_cus_due` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `amount` decimal(18,4) NOT NULL,
  `notes` text,
  `payment_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_cus_due_customer` (`customer_id`),
  KEY `idx_ce_cus_due_payment` (`payment_id`),
  CONSTRAINT `fk_ce_cus_due_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_cus_due` */

insert  into `ce_cus_due`(`id`,`customer_id`,`amount`,`notes`,`payment_id`,`created_at`) values 
(1,1,100.0000,NULL,1,'2026-08-03 15:38:51'),
(2,2,50000.0000,NULL,1,'2026-08-04 12:45:21');

/*Table structure for table `ce_cus_due_collection` */

DROP TABLE IF EXISTS `ce_cus_due_collection`;

CREATE TABLE `ce_cus_due_collection` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `amount` decimal(18,4) NOT NULL,
  `notes` text,
  `payment_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_cus_due_collection_customer` (`customer_id`),
  KEY `idx_ce_cus_due_collection_payment` (`payment_id`),
  CONSTRAINT `fk_ce_cus_due_collection_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_cus_due_collection` */

insert  into `ce_cus_due_collection`(`id`,`customer_id`,`amount`,`notes`,`payment_id`,`created_at`) values 
(1,1,100.0000,NULL,1,'2026-08-03 15:39:50');

/*Table structure for table `ce_customer` */

DROP TABLE IF EXISTS `ce_customer`;

CREATE TABLE `ce_customer` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` text,
  `notes` text,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ce_customer_name` (`name`),
  KEY `idx_ce_customer_phone` (`phone_number`),
  KEY `idx_ce_customer_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_customer` */

insert  into `ce_customer`(`id`,`name`,`phone_number`,`address`,`notes`,`is_active`,`created_at`,`updated_at`) values 
(1,'jaswa','9597451419',NULL,NULL,1,'2026-07-28 21:37:18','2026-07-28 21:37:18'),
(2,'jas','9898989898',NULL,NULL,1,'2026-07-28 21:58:13','2026-07-28 21:58:13');

/*Table structure for table `ce_customer_account` */

DROP TABLE IF EXISTS `ce_customer_account`;

CREATE TABLE `ce_customer_account` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `advance` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `due` decimal(18,4) NOT NULL DEFAULT '0.0000',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ce_customer_account` (`customer_id`),
  CONSTRAINT `fk_ce_customer_account_customer` FOREIGN KEY (`customer_id`) REFERENCES `ce_customer` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_customer_account` */

insert  into `ce_customer_account`(`id`,`customer_id`,`advance`,`due`,`created_at`,`updated_at`) values 
(1,1,0.0000,0.0000,'2026-07-28 21:37:18','2026-08-03 15:39:50'),
(4,2,0.0000,50830.0000,'2026-07-28 21:58:13','2026-08-04 16:49:38');

/*Table structure for table `ce_payment_method` */

DROP TABLE IF EXISTS `ce_payment_method`;

CREATE TABLE `ce_payment_method` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `is_cash` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ce_payment_method_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `ce_payment_method` */

insert  into `ce_payment_method`(`id`,`name`,`is_cash`,`is_active`) values 
(1,'Cash',1,1),
(2,'UPI',0,1),
(3,'Credit Card',0,1),
(4,'Debit Card',0,1),
(5,'Cheque',0,1),
(6,'NEFT',0,1),
(7,'IMPS',0,1);

/*Table structure for table `company_details` */

DROP TABLE IF EXISTS `company_details`;

CREATE TABLE `company_details` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `shop_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `address` text,
  `gstin` varchar(255) DEFAULT NULL,
  `print_type` int NOT NULL DEFAULT '0',
  `printer_name` varchar(255) DEFAULT NULL,
  `bank_details` varchar(255) DEFAULT NULL,
  `barcode_printer` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `company_details` */

insert  into `company_details`(`id`,`shop_name`,`address`,`gstin`,`print_type`,`printer_name`,`bank_details`,`barcode_printer`) values 
(2,'JASXBILL','Address','ASDFFD223SDDDDF',2,'','Bank Details','AP4909');

/*Table structure for table `expense_entry` */

DROP TABLE IF EXISTS `expense_entry`;

CREATE TABLE `expense_entry` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `exp_type` int NOT NULL,
  `content` varchar(255) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_id` int DEFAULT NULL,
  `description` text,
  `exc_date_time` datetime DEFAULT NULL,
  `entry_date_time` datetime DEFAULT NULL,
  `is_active` int DEFAULT '1',
  `uid` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `type` (`exp_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `expense_entry` */

/*Table structure for table `expense_type` */

DROP TABLE IF EXISTS `expense_type`;

CREATE TABLE `expense_type` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) NOT NULL,
  `is_active` int DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `expense_type` */

/*Table structure for table `gstin` */

DROP TABLE IF EXISTS `gstin`;

CREATE TABLE `gstin` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `gstin` varchar(255) NOT NULL,
  `shop_name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `gstin` */

/*Table structure for table `heading` */

DROP TABLE IF EXISTS `heading`;

CREATE TABLE `heading` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `head1` varchar(255) DEFAULT NULL,
  `head2` varchar(255) DEFAULT NULL,
  `head3` varchar(255) DEFAULT NULL,
  `active` int DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

/*Data for the table `heading` */

insert  into `heading`(`id`,`head1`,`head2`,`head3`,`active`) values 
(1,'Category','Brand','Product',600);

/*Table structure for table `user_modules` */

DROP TABLE IF EXISTS `user_modules`;

CREATE TABLE `user_modules` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `module_name` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=latin1;

/*Data for the table `user_modules` */

insert  into `user_modules`(`id`,`module_name`) values 
(1,'Currency Exchange'),
(2,'Exchange Report'),
(3,'Customer'),
(4,'Expense'),
(5,'Admin');

/*Table structure for table `user_permission` */

DROP TABLE IF EXISTS `user_permission`;

CREATE TABLE `user_permission` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `module_id` int NOT NULL,
  `uid` int NOT NULL,
  `date` date DEFAULT NULL,
  `time` time DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `mod` (`module_id`),
  KEY `uid` (`uid`)
) ENGINE=InnoDB AUTO_INCREMENT=122 DEFAULT CHARSET=latin1;

/*Data for the table `user_permission` */

insert  into `user_permission`(`id`,`module_id`,`uid`,`date`,`time`) values 
(70,1,1,'2025-09-19','11:43:23'),
(71,2,1,'2025-09-19','11:43:23'),
(72,3,1,'2025-09-19','11:43:23'),
(73,4,1,'2025-09-19','11:43:23'),
(74,5,1,'2025-09-19','11:43:23');

/*Table structure for table `user_special_permission` */

DROP TABLE IF EXISTS `user_special_permission`;

CREATE TABLE `user_special_permission` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `content_id` int NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `user_special_permission` */

insert  into `user_special_permission`(`id`,`content_id`,`user_id`) values 
(3,1,1);

/*Table structure for table `users` */

DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user_name` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `is_active` int DEFAULT '1',
  `fullName` varchar(255) DEFAULT NULL,
  `disc_per` int DEFAULT '100',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=latin1;

/*Data for the table `users` */

insert  into `users`(`id`,`user_name`,`password`,`is_active`,`fullName`,`disc_per`) values 
(1,'admin','aecbf9a63cec1e93327dfc212f31acdb31c4f5d10bedccf8fbb8b042a6f0f39155797bdd04517905ae5d98b69fdc452cdb61b018e10939740ec96f36e133d639',1,'admin',50);

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
