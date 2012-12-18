CREATE TABLE `account_entries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  `deal_id` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `balance` int(11) DEFAULT NULL,
  `settlement_id` int(11) DEFAULT NULL,
  `result_settlement_id` int(11) DEFAULT NULL,
  `initial_balance` tinyint(1) NOT NULL DEFAULT '0',
  `date` date NOT NULL,
  `daily_seq` int(11) NOT NULL,
  `linked_ex_entry_id` int(11) DEFAULT NULL,
  `linked_ex_deal_id` int(11) DEFAULT NULL,
  `linked_user_id` int(11) DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `linked_ex_entry_confirmed` tinyint(1) NOT NULL DEFAULT '0',
  `summary` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `creditor` tinyint(1) NOT NULL DEFAULT '0',
  `line_number` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_account_entries_on_deal_id_and_creditor_and_line_number` (`deal_id`,`creditor`,`line_number`),
  KEY `index_account_entries_on_account_id` (`account_id`),
  KEY `index_account_entries_on_deal_id` (`deal_id`),
  KEY `index_account_entries_on_user_id` (`user_id`),
  KEY `index_account_entries_on_settlement_id` (`settlement_id`),
  KEY `index_account_entries_on_result_settlement_id` (`result_settlement_id`)
) ENGINE=InnoDB AUTO_INCREMENT=214 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `account_link_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `account_id` int(11) DEFAULT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `sender_ex_account_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `account_links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  `target_user_id` int(11) DEFAULT NULL,
  `target_ex_account_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_account_links_on_account_id` (`account_id`),
  KEY `index_account_links_on_target_ex_account_id` (`target_ex_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `sort_key` int(11) DEFAULT NULL,
  `partner_account_id` int(11) DEFAULT NULL,
  `type` text COLLATE utf8_unicode_ci,
  `asset_kind` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_accounts_on_user_id` (`user_id`),
  KEY `index_accounts_on_partner_account_id` (`partner_account_id`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `deal_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `code` varchar(10) CHARACTER SET utf8 COLLATE utf8_bin DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_deal_patterns_on_user_id_and_code` (`user_id`,`code`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `deals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `user_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `daily_seq` int(11) NOT NULL,
  `old_summary` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `confirmed` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_deals_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=82 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `entry_patterns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `deal_pattern_id` int(11) NOT NULL,
  `creditor` tinyint(1) NOT NULL DEFAULT '0',
  `line_number` int(11) NOT NULL,
  `summary` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `account_id` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `creditor_line_number` (`deal_pattern_id`,`creditor`,`line_number`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `friend_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `friend_requests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `sender_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `preferences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `deals_scroll_height` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `color` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `business_use` tinyint(1) NOT NULL DEFAULT '0',
  `use_daily_booking` tinyint(1) NOT NULL DEFAULT '1',
  `bookkeeping_style` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=91 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `settlements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `account_id` int(11) DEFAULT NULL,
  `name` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `submitted_settlement_id` int(11) DEFAULT NULL,
  `type` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `single_logins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `crypted_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(80) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `email` varchar(60) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `salt` varchar(40) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `role` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `activation_code` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `logged_in_at` datetime DEFAULT NULL,
  `crypted_password` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `remember_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `remember_token_expires_at` datetime DEFAULT NULL,
  `activated_at` datetime DEFAULT NULL,
  `type` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_token` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  `password_token_expires_at` datetime DEFAULT NULL,
  `mobile_identity` varchar(40) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('1');

INSERT INTO schema_migrations (version) VALUES ('10');

INSERT INTO schema_migrations (version) VALUES ('11');

INSERT INTO schema_migrations (version) VALUES ('12');

INSERT INTO schema_migrations (version) VALUES ('13');

INSERT INTO schema_migrations (version) VALUES ('14');

INSERT INTO schema_migrations (version) VALUES ('15');

INSERT INTO schema_migrations (version) VALUES ('16');

INSERT INTO schema_migrations (version) VALUES ('17');

INSERT INTO schema_migrations (version) VALUES ('2');

INSERT INTO schema_migrations (version) VALUES ('20090103053930');

INSERT INTO schema_migrations (version) VALUES ('20090103053943');

INSERT INTO schema_migrations (version) VALUES ('20090103152113');

INSERT INTO schema_migrations (version) VALUES ('20090103211631');

INSERT INTO schema_migrations (version) VALUES ('20090103235236');

INSERT INTO schema_migrations (version) VALUES ('20090126145440');

INSERT INTO schema_migrations (version) VALUES ('20090214192337');

INSERT INTO schema_migrations (version) VALUES ('20090214200718');

INSERT INTO schema_migrations (version) VALUES ('20090215063358');

INSERT INTO schema_migrations (version) VALUES ('20090215064620');

INSERT INTO schema_migrations (version) VALUES ('20090222024854');

INSERT INTO schema_migrations (version) VALUES ('20090314151301');

INSERT INTO schema_migrations (version) VALUES ('20090315043430');

INSERT INTO schema_migrations (version) VALUES ('20090507005028');

INSERT INTO schema_migrations (version) VALUES ('20090521044900');

INSERT INTO schema_migrations (version) VALUES ('20090521071751');

INSERT INTO schema_migrations (version) VALUES ('20090523142041');

INSERT INTO schema_migrations (version) VALUES ('20090611043338');

INSERT INTO schema_migrations (version) VALUES ('20091123010819');

INSERT INTO schema_migrations (version) VALUES ('20091123034257');

INSERT INTO schema_migrations (version) VALUES ('20091230031445');

INSERT INTO schema_migrations (version) VALUES ('20100124233242');

INSERT INTO schema_migrations (version) VALUES ('20100212084008');

INSERT INTO schema_migrations (version) VALUES ('20100219053047');

INSERT INTO schema_migrations (version) VALUES ('20100505211320');

INSERT INTO schema_migrations (version) VALUES ('20100528072406');

INSERT INTO schema_migrations (version) VALUES ('20121124204521');

INSERT INTO schema_migrations (version) VALUES ('20121128171301');

INSERT INTO schema_migrations (version) VALUES ('20121129053811');

INSERT INTO schema_migrations (version) VALUES ('20121129061334');

INSERT INTO schema_migrations (version) VALUES ('20121217174344');

INSERT INTO schema_migrations (version) VALUES ('20121217233646');

INSERT INTO schema_migrations (version) VALUES ('3');

INSERT INTO schema_migrations (version) VALUES ('4');

INSERT INTO schema_migrations (version) VALUES ('5');

INSERT INTO schema_migrations (version) VALUES ('6');

INSERT INTO schema_migrations (version) VALUES ('7');

INSERT INTO schema_migrations (version) VALUES ('8');

INSERT INTO schema_migrations (version) VALUES ('9');