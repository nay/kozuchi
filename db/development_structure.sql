CREATE TABLE `account_entries` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `deal_id` int(11) NOT NULL,
  `amount` int(11) NOT NULL,
  `balance` int(11) default NULL,
  `friend_link_id` int(11) default NULL,
  `settlement_id` int(11) default NULL,
  `result_settlement_id` int(11) default NULL,
  PRIMARY KEY  (`id`),
  KEY `account_entries_account_id_index` (`account_id`),
  KEY `account_entries_deal_id_index` (`deal_id`),
  KEY `account_entries_user_id_index` (`user_id`),
  KEY `account_entries_friend_link_id_index` (`friend_link_id`),
  KEY `account_entries_settlement_id_index` (`settlement_id`),
  KEY `account_entries_result_settlement_id_index` (`result_settlement_id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8;

CREATE TABLE `account_links` (
  `account_id` int(11) NOT NULL,
  `connected_account_id` int(11) NOT NULL,
  KEY `account_links_account_id_index` (`account_id`),
  KEY `account_links_connected_account_id_index` (`connected_account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `account_rules` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `associated_account_id` int(11) NOT NULL,
  `closing_day` int(11) NOT NULL default '0',
  `payment_term_months` int(11) NOT NULL default '1',
  `payment_day` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `name` varchar(32) NOT NULL,
  `account_type_code` int(11) default NULL,
  `asset_type_code` int(11) default NULL,
  `sort_key` int(11) default NULL,
  `partner_account_id` int(11) default NULL,
  `type` text,
  PRIMARY KEY  (`id`),
  KEY `accounts_user_id_index` (`user_id`),
  KEY `accounts_partner_account_id_index` (`partner_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=310 DEFAULT CHARSET=utf8;

CREATE TABLE `admin_users` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `hashed_password` varchar(40) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `deal_links` (
  `id` int(11) NOT NULL auto_increment,
  `created_user_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `deals` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `daily_seq` int(11) NOT NULL,
  `summary` varchar(64) NOT NULL,
  `confirmed` tinyint(1) NOT NULL default '1',
  `parent_deal_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `deals_user_id_index` (`user_id`),
  KEY `deals_parent_deal_id_index` (`parent_deal_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

CREATE TABLE `engine_schema_info` (
  `engine_name` varchar(255) default NULL,
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `friends` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `friend_user_id` int(11) NOT NULL,
  `friend_level` int(11) NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `preferences` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `deals_scroll_height` varchar(20) default NULL,
  `color` varchar(32) default NULL,
  `business_use` tinyint(1) NOT NULL default '0',
  `use_daily_booking` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `settlements` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `account_id` int(11) default NULL,
  `name` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `description` text,
  `submitted_settlement_id` int(11) default NULL,
  `type` varchar(40) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `login` varchar(80) NOT NULL default '',
  `salted_password` varchar(40) NOT NULL default '',
  `email` varchar(60) NOT NULL default '',
  `firstname` varchar(40) default NULL,
  `lastname` varchar(40) default NULL,
  `salt` varchar(40) NOT NULL default '',
  `role` varchar(40) default NULL,
  `activation_code` varchar(40) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `logged_in_at` datetime default NULL,
  `crypted_password` varchar(40) default NULL,
  `remember_token` varchar(255) default NULL,
  `remember_token_expires_at` datetime default NULL,
  `activated_at` datetime default NULL,
  `type` varchar(40) default NULL,
  `password_token` varchar(40) default NULL,
  `password_token_expires_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8;

INSERT INTO `schema_info` (version) VALUES (13)