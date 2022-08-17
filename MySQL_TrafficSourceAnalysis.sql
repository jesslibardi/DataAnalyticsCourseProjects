-- -- ECOMMERCE - Advanced SQL Course -- --
USE mavenfuzzyfactory;

-- The major traffic source.
SELECT
utm_source,
utm_campaign,
http_referer,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-04-12'
GROUP BY 1, 2, 3 -- or the column number
ORDER BY sessions DESC;

-- gsearch nonbrand is the major traffic source
-- we need a CVR of at least 4% to make the numbers work
-- date: created_at < '2012-04-14' (day of request)

SELECT
website_sessions.utm_source,
website_sessions.utm_campaign,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
ROUND(COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS CVR
FROM website_sessions
LEFT JOIN orders
ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
AND website_sessions.utm_campaign = 'nonbrand'
AND website_sessions.created_at < '2012-04-14'
GROUP BY 1, 2; -- or the column number

-- It didn't make it.
-- Looks like it is below the 4% threshold needed to make the economics work.
-- Based on this analysis, it will be necessary to dial down the search bids a bit. We're over spending based on the current conversion rate.

SELECT
-- YEAR(created_at),
-- WEEK(created_at),
MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-12'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at)
ORDER BY 1

-- Based on this, it does look like gsearch nonbrand is fairly sensitive to bid changes
-- We want maximum volume, but don’t want to spend more on ads than we can afford

-- -- CVR BY DEVICE -- --
SELECT
website_sessions.device_type,
COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
COUNT(DISTINCT orders.order_id) AS orders,
ROUND(COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) * 100, 2) AS CVR
FROM website_sessions
LEFT JOIN orders
	ON orders.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-05-11'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 1;

-- increased bids on desktop from '2012-05-19'
-- PIVOT
SELECT
MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop,
COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-08'
	AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);

-- It looks like mobile has been pretty flat or a little down
-- Continue to monitor device level volume and be aware of the impact bid levels has
-- Continue to monitor conversion performance at the device level to optimize spend


