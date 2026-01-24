CREATE TABLE IF NOT EXISTS `devolutions_products` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image` varchar(512) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `model` varchar(100) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `icon` varchar(100) DEFAULT 'fas fa-box',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `devolutions_user_purchases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL,
  `discord_id` varchar(100) DEFAULT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 1,
  `purchased_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `discord_id` (`discord_id`),
  KEY `product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `user_identifiers` (
  `license` varchar(50) NOT NULL,
  `steam` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `xbl` varchar(50) DEFAULT NULL,
  `live` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `steam_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
