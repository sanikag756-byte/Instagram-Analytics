-- =====================================================================
-- Instagram Analytics — Business Analysis Queries
-- =====================================================================
-- Run schema.sql, then bulk_data.sql, before running these.
-- Queries are organized from foundational to advanced, each framed
-- around a real business question a social-media analytics team
-- would actually ask.
-- =====================================================================

USE instagram_analytics;


-- ---------------------------------------------------------------------
-- 1. Most engaged users — who generates the most likes and comments?
--    Business use: identify accounts worth featuring or studying for
--    what makes their content succeed.
-- ---------------------------------------------------------------------
SELECT u.user_id, u.username,
       COUNT(DISTINCT p.post_id) AS total_posts,
       COUNT(DISTINCT l.like_id) AS likes_received,
       COUNT(DISTINCT c.comment_id) AS comments_received
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
LEFT JOIN comments c ON p.post_id = c.post_id
GROUP BY u.user_id, u.username
ORDER BY likes_received DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 2. Engagement rate per post — a fairer metric than raw totals
--    Business use: raw like counts favor prolific posters; average
--    likes-per-post reveals who creates the strongest content,
--    regardless of how often they post.
-- ---------------------------------------------------------------------
SELECT u.user_id, u.username,
       COUNT(DISTINCT p.post_id) AS total_posts,
       COUNT(DISTINCT l.like_id) AS total_likes,
       ROUND(COUNT(DISTINCT l.like_id) / COUNT(DISTINCT p.post_id), 2) AS avg_likes_per_post
FROM users u
JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
GROUP BY u.user_id, u.username
HAVING total_posts >= 2
ORDER BY avg_likes_per_post DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 3. Monthly user growth trend, with a running total
--    Business use: the classic "user growth over time" chart used in
--    reporting and investor updates. Uses a CTE plus a window function.
-- ---------------------------------------------------------------------
WITH monthly_signups AS (
    SELECT DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
           COUNT(*) AS new_users
    FROM users
    GROUP BY signup_month
)
SELECT signup_month,
       new_users,
       SUM(new_users) OVER (ORDER BY signup_month) AS total_users_so_far
FROM monthly_signups
ORDER BY signup_month;


-- ---------------------------------------------------------------------
-- 4. Top 10 best-performing posts overall (likes + comments combined)
--    Business use: understand what content resonates most, across
--    the whole platform.
-- ---------------------------------------------------------------------
SELECT p.post_id, p.caption, u.username,
       COUNT(DISTINCT l.like_id) AS total_likes,
       COUNT(DISTINCT c.comment_id) AS total_comments,
       (COUNT(DISTINCT l.like_id) + COUNT(DISTINCT c.comment_id)) AS total_engagement
FROM posts p
JOIN users u ON p.user_id = u.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
LEFT JOIN comments c ON p.post_id = c.post_id
GROUP BY p.post_id, p.caption, u.username
ORDER BY total_engagement DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 5. Follower vs. following ratio per user
--    Business use: separates genuine influencers (high followers, low
--    following) from highly active networkers (high following).
--    Uses correlated subqueries.
-- ---------------------------------------------------------------------
SELECT u.user_id, u.username,
       (SELECT COUNT(*) FROM followers f WHERE f.followed_user_id = u.user_id) AS follower_count,
       (SELECT COUNT(*) FROM followers f WHERE f.follower_user_id = u.user_id) AS following_count
FROM users u
ORDER BY follower_count DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 6. Each user's single best-performing post ("Top N per group")
--    Business use: a content/marketing team question — "what is each
--    creator's strongest post?" Uses a CTE plus RANK() partitioned by
--    user, a common analyst interview pattern.
-- ---------------------------------------------------------------------
WITH post_engagement AS (
    SELECT p.post_id, p.user_id, u.username, p.caption,
           COUNT(DISTINCT l.like_id) + COUNT(DISTINCT c.comment_id) AS engagement_score
    FROM posts p
    JOIN users u ON p.user_id = u.user_id
    LEFT JOIN likes l ON p.post_id = l.post_id
    LEFT JOIN comments c ON p.post_id = c.post_id
    GROUP BY p.post_id, p.user_id, u.username, p.caption
),
ranked_posts AS (
    SELECT *,
           RANK() OVER (PARTITION BY user_id ORDER BY engagement_score DESC) AS rank_within_user
    FROM post_engagement
)
SELECT username, caption, engagement_score
FROM ranked_posts
WHERE rank_within_user = 1
ORDER BY engagement_score DESC
LIMIT 15;


-- ---------------------------------------------------------------------
-- 7. Month-over-month signup growth rate (%)
--    Business use: the standard "MoM growth %" metric reported to
--    stakeholders. Uses LAG() to compare each month to the previous one.
-- ---------------------------------------------------------------------
WITH monthly_signups AS (
    SELECT DATE_FORMAT(signup_date, '%Y-%m') AS signup_month,
           COUNT(*) AS new_users
    FROM users
    GROUP BY signup_month
)
SELECT signup_month,
       new_users,
       LAG(new_users) OVER (ORDER BY signup_month) AS prev_month_users,
       ROUND(
           (new_users - LAG(new_users) OVER (ORDER BY signup_month))
           / LAG(new_users) OVER (ORDER BY signup_month) * 100, 1
       ) AS growth_pct
FROM monthly_signups
ORDER BY signup_month;


-- ---------------------------------------------------------------------
-- 8. Reusable reporting view — post engagement summary
--    Business use: saves query #4's logic as a permanent view so
--    anyone (or any dashboard tool) can query it directly without
--    retyping the joins, e.g.: SELECT * FROM post_engagement_summary;
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW post_engagement_summary AS
SELECT p.post_id, p.caption, u.username,
       COUNT(DISTINCT l.like_id) AS total_likes,
       COUNT(DISTINCT c.comment_id) AS total_comments,
       (COUNT(DISTINCT l.like_id) + COUNT(DISTINCT c.comment_id)) AS total_engagement
FROM posts p
JOIN users u ON p.user_id = u.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
LEFT JOIN comments c ON p.post_id = c.post_id
GROUP BY p.post_id, p.caption, u.username;

-- Example usage of the view:
SELECT * FROM post_engagement_summary ORDER BY total_engagement DESC LIMIT 5;
