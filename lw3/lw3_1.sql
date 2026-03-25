CREATE DATABASE IF NOT EXISTS news_feed;
USE news_feed;

-- `block_content`
CREATE TABLE IF NOT EXISTS block_content (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    type ENUM('text', 'image', 'video', 'code') NOT NULL,
    data TEXT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE = InnoDB;

-- `news`
CREATE TABLE IF NOT EXISTS news (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    is_draft TINYINT(1) NOT NULL DEFAULT 1,
    priority INT NOT NULL DEFAULT 0,
    is_pinned TINYINT(1) NOT NULL DEFAULT 0,
    published_at DATETIME NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_news_title_draft (title ASC, is_draft ASC)
) ENGINE = InnoDB;

-- `news_draft`
CREATE TABLE IF NOT EXISTS news_draft (
    news_id INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    last_modified DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (news_id),
    CONSTRAINT fk_news_draft_news
        FOREIGN KEY (news_id)
        REFERENCES news (id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
    ) ENGINE = InnoDB;


-- `news_block`
CREATE TABLE IF NOT EXISTS news_block (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    news_id INT UNSIGNED NOT NULL,
    sort_order INT NOT NULL,
    content_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_news_block_news (news_id ASC),
    INDEX idx_news_block_content (content_id ASC),
    UNIQUE INDEX uq_news_block_sort (news_id ASC, sort_order ASC),
    CONSTRAINT fk_news_block_news
    FOREIGN KEY (news_id)
    REFERENCES news (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    CONSTRAINT fk_news_block_content
    FOREIGN KEY (content_id)
    REFERENCES block_content (id)
    ON DELETE RESTRICT
    ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Table `news_block_draft`
CREATE TABLE IF NOT EXISTS news_block_draft (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    news_id INT UNSIGNED NOT NULL,
    sort_order INT NOT NULL,
    content_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_news_block_draft_news (news_id ASC),
    INDEX idx_news_block_draft_content (content_id ASC),
    UNIQUE INDEX uq_news_block_draft_sort (news_id ASC, sort_order ASC),
    CONSTRAINT fk_news_block_draft_news
    FOREIGN KEY (news_id)
    REFERENCES news_draft (news_id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    CONSTRAINT fk_news_block_draft_content
    FOREIGN KEY (content_id)
    REFERENCES block_content (id)
    ON DELETE RESTRICT
    ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Table `comment`
CREATE TABLE IF NOT EXISTS comment (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    news_id INT UNSIGNED NOT NULL,
    parent_comment_id INT UNSIGNED NULL,
    content TEXT NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    is_deleted TINYINT(1) NOT NULL DEFAULT 0,
    edited_at DATETIME NULL,
    likes_count INT UNSIGNED NOT NULL DEFAULT 0,
    user_agent VARCHAR(255) NULL,
    PRIMARY KEY (id),
    INDEX idx_comment_news (news_id ASC),
    INDEX idx_comment_parent (parent_comment_id ASC),
    CONSTRAINT fk_comment_news
    FOREIGN KEY (news_id)
    REFERENCES news (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
    CONSTRAINT fk_comment_parent
    FOREIGN KEY (parent_comment_id)
    REFERENCES comment (id)
    ON DELETE SET NULL
    ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Table `news_view`
CREATE TABLE IF NOT EXISTS news_view (
    id CHAR(36) NOT NULL,
    news_id INT UNSIGNED NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    viewed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(64) NULL,
    PRIMARY KEY (id),
    INDEX idx_view_news (news_id ASC),
    UNIQUE INDEX uq_view_unique (news_id ASC, ip_address ASC, viewed_at ASC),
    CONSTRAINT fk_view_news
    FOREIGN KEY (news_id)
    REFERENCES news (id)
    ON DELETE CASCADE
    ON UPDATE NO ACTION
    ) ENGINE = InnoDB;

-- Table `author_profile`
CREATE TABLE IF NOT EXISTS author_profile (
    id CHAR(36) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    bio TEXT NULL,
    avatar_url VARCHAR(255) NULL,
    twitter_handle VARCHAR(50) NULL,
    joined_date DATE NOT NULL,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    email VARCHAR(255) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_author_email (email ASC)
    ) ENGINE = InnoDB;

-- Table `news_author_link`
CREATE TABLE IF NOT EXISTS news_author_link (
    news_id INT UNSIGNED NOT NULL,
    author_id CHAR(36) NOT NULL,
    role ENUM('main', 'co-author', 'editor') NOT NULL,
    contribution_percent INT UNSIGNED NULL,
    approved_at DATETIME NULL,
    order_index INT NOT NULL DEFAULT 0,
    PRIMARY KEY (news_id, author_id),
    INDEX idx_link_author (author_id ASC),
    UNIQUE INDEX uq_link_order (news_id ASC, order_index ASC),
    CONSTRAINT fk_link_news
    FOREIGN KEY (news_id)
    REFERENCES news (id)
    ON DELETE CASCADE,
    CONSTRAINT fk_link_author
    FOREIGN KEY (author_id)
    REFERENCES author_profile (id)
    ON DELETE CASCADE
    ) ENGINE = InnoDB;


-- Table `media_asset`
CREATE TABLE IF NOT EXISTS media_asset (
    id CHAR(36) NOT NULL,
    block_content_id INT UNSIGNED NULL, -- block_content link
    uploader_id CHAR(36) NULL, -- author_profile link
    file_name VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size_bytes BIGINT UNSIGNED NOT NULL,
    storage_path VARCHAR(500) NOT NULL,
    checksum_sha256 CHAR(64) NOT NULL, -- crypt hash(damaged/duplicates)
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_public TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE INDEX uq_media_checksum (checksum_sha256 ASC), -- гарант уникальности кортежа по checksum_sha256
    CONSTRAINT fk_media_block -- явно идентифицируем ограничение
        FOREIGN KEY (block_content_id) -- привязка к id в block_content
        REFERENCES block_content (id)
        ON DELETE SET NULL,
    CONSTRAINT fk_media_uploader
        FOREIGN KEY (uploader_id) -- привязка к id в author_profile
        REFERENCES author_profile (id)
        ON DELETE SET NULL
    ) ENGINE = InnoDB;