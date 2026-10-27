-- =====================================================================
-- Instagram Analytics — Database Schema
-- =====================================================================
-- A relational database modeling a simplified social-media platform:
-- users, posts, likes, comments, and the follower graph between users.
-- Run this file first (before bulk_data.sql) to create the database
-- and all tables.
-- =====================================================================

DROP DATABASE IF EXISTS instagram_analytics;
CREATE DATABASE instagram_analytics;
USE instagram_analytics;

-- ---------------------------------------------------------------------
-- Table: users
-- ---------------------------------------------------------------------
CREATE TABLE users (
    user_id      INT PRIMARY KEY,
    username     VARCHAR(50)  NOT NULL,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(100) NOT NULL,
    signup_date  DATE         NOT NULL
);

-- ---------------------------------------------------------------------
-- Table: posts
-- ---------------------------------------------------------------------
CREATE TABLE posts (
    post_id    INT PRIMARY KEY,
    user_id    INT NOT NULL,
    caption    VARCHAR(255),
    post_date  DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ---------------------------------------------------------------------
-- Table: likes
-- ---------------------------------------------------------------------
CREATE TABLE likes (
    like_id    INT PRIMARY KEY,
    post_id    INT NOT NULL,
    user_id    INT NOT NULL,
    like_date  DATE NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ---------------------------------------------------------------------
-- Table: comments
-- ---------------------------------------------------------------------
CREATE TABLE comments (
    comment_id    INT PRIMARY KEY,
    post_id       INT NOT NULL,
    user_id       INT NOT NULL,
    comment_text  VARCHAR(255),
    comment_date  DATE NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- ---------------------------------------------------------------------
-- Table: followers  (who follows whom — both sides reference users)
-- ---------------------------------------------------------------------
CREATE TABLE followers (
    follower_id        INT PRIMARY KEY,
    follower_user_id   INT NOT NULL,   -- the person doing the following
    followed_user_id   INT NOT NULL,   -- the person being followed
    follow_date        DATE NOT NULL,
    FOREIGN KEY (follower_user_id) REFERENCES users(user_id),
    FOREIGN KEY (followed_user_id) REFERENCES users(user_id)
);

-- Helpful indexes for common query patterns
CREATE INDEX idx_posts_user       ON posts(user_id);
CREATE INDEX idx_likes_post       ON likes(post_id);
CREATE INDEX idx_likes_user       ON likes(user_id);
CREATE INDEX idx_comments_post    ON comments(post_id);
CREATE INDEX idx_comments_user    ON comments(user_id);
CREATE INDEX idx_followers_from   ON followers(follower_user_id);
CREATE INDEX idx_followers_to     ON followers(followed_user_id);
