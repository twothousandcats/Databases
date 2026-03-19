CREATE DATABASE my_project;
use my_project;

CREATE TABLE news (
                      id INT AUTO_INCREMENT PRIMARY KEY,
                      title VARCHAR(255) NOT NULL,
                      is_draft TINYINT(1) NOT NULL DEFAULT 0,
                      slug VARCHAR(100) NOT NULL,
                      author_uuid CHAR(36) NOT NULL,
                      published_at DATETIME DEFAULT NULL,
                      UNIQUE KEY uk_news_slug (slug),
                      UNIQUE KEY uk_news_author_uuid (author_uuid)
)engine=InnoDB;

CREATE TABLE news_draft (
                            news_id INT PRIMARY KEY,
                            title VARCHAR(255) NOT NULL,
                            last_modified_by VARCHAR(50) NOT NULL,
                            revision_number INT NOT NULL DEFAULT 1,
                            edit_session_token VARCHAR(64) NOT NULL,
                            auto_save_interval INT NOT NULL DEFAULT 30,
                            is_locked TINYINT(1) NOT NULL DEFAULT 0
)engine=InnoDB;

CREATE TABLE block_content (
                               id INT AUTO_INCREMENT PRIMARY KEY,
                               type ENUM('image', 'text', 'video', 'code') NOT NULL,
                               data TEXT NOT NULL,
                               checksum_hash VARCHAR(64) NOT NULL,
                               mime_type VARCHAR(100) NOT NULL,
                               file_size_bytes BIGINT NOT NULL DEFAULT 0,
                               UNIQUE KEY uk_block_checksum (checksum_hash)
)engine=InnoDB;

CREATE TABLE news_block (
                            id INT AUTO_INCREMENT PRIMARY KEY,
                            news_id INT NOT NULL,
                            sort_order INT NOT NULL,
                            content_id INT NOT NULL,
                            visibility_status ENUM('public', 'private', 'members_only') NOT NULL DEFAULT 'public',
                            animation_effect VARCHAR(50) DEFAULT NULL,
                            load_priority INT NOT NULL DEFAULT 5
)engine=InnoDB;

CREATE TABLE news_block_draft (
                                  id INT AUTO_INCREMENT PRIMARY KEY,
                                  news_id INT NOT NULL,
                                  sort_order INT NOT NULL,
                                  content_id INT NOT NULL,
                                  temp_storage_path VARCHAR(255) NOT NULL,
                                  preview_generated TINYINT(1) NOT NULL DEFAULT 0,
                                  validation_errors JSON DEFAULT NULL
)engine=InnoDB;

CREATE TABLE comment (
                         id INT AUTO_INCREMENT PRIMARY KEY,
                         news_id INT NOT NULL,
                         parent_comment_id INT DEFAULT NULL,
                         content TEXT NOT NULL,
                         ip_address VARCHAR(45) NOT NULL,
                         is_deleted TINYINT(1) NOT NULL DEFAULT 0,
                         user_agent_string VARCHAR(255) NOT NULL,
                         sentiment_score DECIMAL(3,2) DEFAULT NULL,
                         edited_at DATETIME DEFAULT NULL
)engine=InnoDB;

CREATE TABLE news_view (
                           id INT AUTO_INCREMENT PRIMARY KEY,
                           news_id INT NOT NULL,
                           ip_address VARCHAR(45) NOT NULL,
                           viewed_at DATETIME NOT NULL,
                           session_identifier VARCHAR(128) NOT NULL,
                           referrer_url VARCHAR(512) DEFAULT NULL,
                           dwell_time_seconds INT NOT NULL DEFAULT 0,
                           UNIQUE KEY uk_news_view_session (news_id, session_identifier)
)engine=InnoDB;

CREATE TABLE news_tag_relation (
                                   id INT AUTO_INCREMENT PRIMARY KEY,
                                   news_id INT NOT NULL,
                                   tag_id INT NOT NULL,
                                   created_by_user_uuid CHAR(36) NOT NULL,
                                   relevance_score DECIMAL(3,2) NOT NULL DEFAULT 1.00,
                                   is_featured TINYINT(1) NOT NULL DEFAULT 0,
                                   added_at DATETIME NOT NULL,
                                   UNIQUE KEY uk_news_tag_unique (news_id, tag_id)
)engine=InnoDB;

CREATE TABLE user_subscription (
                                   id INT AUTO_INCREMENT PRIMARY KEY,
                                   subscriber_uuid CHAR(36) NOT NULL,
                                   target_news_id INT NOT NULL,
                                   notification_channel ENUM('email', 'push', 'sms') NOT NULL,
                                   subscription_date DATETIME NOT NULL,
                                   expiry_date DATETIME DEFAULT NULL,
                                   priority_level INT NOT NULL DEFAULT 1,
                                   UNIQUE KEY uk_subscriber_news (subscriber_uuid, target_news_id)
)engine=InnoDB;