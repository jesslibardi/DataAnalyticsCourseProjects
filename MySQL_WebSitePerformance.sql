-- -- ECOMMERCE - Advanced SQL Course -- --
USE mavenfuzzyfactory;

-- -- WEBSITE PERFORMANCE -- --
-- Pulling the most viewed website pages, ranked by session volume
SELECT
pageview_url,
COUNT(DISTINCT(website_session_id)) AS sessions
FROM website_pageviews
WHERE created_at < '2012-06-09'
-- WHERE website_pageview_id < 1000 -- arbitrary
GROUP BY 1
ORDER BY 2 DESC;

-- the homepage, the products page, and the Mr. Fuzzy page get the bulk of the traffic
-- look at entry pages

CREATE TEMPORARY TABLE first_pageview
SELECT
website_session_id,
MIN(website_pageview_id) AS min_pv_id
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT
website_pageviews.pageview_url AS landing_page,
COUNT(DISTINCT(first_pageview.website_session_id)) AS pvs
FROM first_pageview
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_pageview.min_pv_id
-- WHERE website_pageviews.website_pageview_id < 1000 -- arbitrary
GROUP BY 1;

-- ALSO....
SELECT
pageview_url,
COUNT(website_session_id)
FROM (SELECT website_session_id,
MIN(website_pageview_id) AS min_pv_id,
pageview_url
FROM website_pageviews
-- WHERE website_pageview_id < 1000
GROUP BY 1) AS temp_first_pageview
GROUP BY 1;


-- Think about whether or not the homepage is the best initial experience for all customers

-- BOUNCED SESSIONS
-- STEP 1: we are going to find the first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE first_pageview
SELECT
website_sessions.website_session_id,
MIN(website_pageviews.website_pageview_id) AS min_pv_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_pageviews.website_session_id = website_sessions.website_session_id
WHERE website_sessions.created_at < '2012-06-14' -- resquest day
GROUP BY website_sessions.website_session_id
;

-- STEP 2: identify the landing page of each session
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT
first_pageview.website_session_id,
website_pageviews.pageview_url as landing_page
FROM first_pageview
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id = first_pageview.min_pv_id
;

-- STEP 3: counting pageview for each session, to identify "bounces"


CREATE TEMPORARY TABLE bounced_sessions_only
SELECT
sessions_w_landing_page.website_session_id,
sessions_w_landing_page.landing_page,
COUNT(website_pageviews.website_pageview_id)
FROM sessions_w_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = sessions_w_landing_page.website_session_id
GROUP BY 1, 2
HAVING COUNT(website_pageviews.website_pageview_id) = 1
;

-- STEP 4: summarizing total sessions and bounced sessions, by Landing Page

-- VERIFY BOUNCED PAGES
SELECT
sessions_w_landing_page.website_session_id,
sessions_w_landing_page.landing_page,
bounced_sessions_only.website_session_id
FROM sessions_w_landing_page
LEFT JOIN bounced_sessions_only
	ON bounced_sessions_only.website_session_id = sessions_w_landing_page.website_session_id
ORDER BY 1
;

-- Final output: We will use the same query we ran before, and run a count of records

SELECT
sessions_w_landing_page.landing_page,
COUNT(DISTINCT sessions_w_landing_page.website_session_id) AS sessions,
COUNT(DISTINCT bounced_sessions_only.website_session_id) AS bounced_sessions,
ROUND(COUNT(DISTINCT bounced_sessions_only.website_session_id) / COUNT(DISTINCT sessions_w_landing_page.website_session_id) * 100, 2) AS bounce_rate
FROM sessions_w_landing_page
LEFT JOIN bounced_sessions_only
	ON bounced_sessions_only.website_session_id = sessions_w_landing_page.website_session_id
GROUP BY 1
ORDER BY 1
;

-- almost a 60% bounce rate for home page
-- Based on the bounce rate analysis, it was run a new custom landing page (/lander-1 ) in a 50/50 test against the homepage (/home) for our gsearch nonbrand traffic.
-- we should pull bounce rates for the two groups so we can evaluate the new page.
-- Make sure to just look at the time period where /lander-1 was getting traffic, so that it is a fair comparison.

-- STEP 1: find out when the new page /lander-1 was lauched
SELECT
MIN(created_at),
MIN(website_pageview_id)
FROM website_pageviews
WHERE pageview_url = '/lander-1'
AND created_at IS NOT NULL;

-- STEP 2: find the first website_pageview_id for relevant sessions
CREATE TEMPORARY TABLE landing_page
SELECT
ws.website_session_id,
MIN(wp.website_pageview_id) AS min_pv
FROM website_pageviews AS wp
INNER JOIN website_sessions AS ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at < '2012-07-28'
AND wp.website_pageview_id >= 23504
AND ws.utm_source ='gsearch'
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

-- STEP 3: Identifying the landing page
CREATE TEMPORARY TABLE pg_url
SELECT
lp.website_session_id,
wp.pageview_url AS landing_pages
FROM landing_page lp
LEFT JOIN website_pageviews wp
	ON lp.website_session_id = wp.website_session_id
WHERE wp.pageview_url IN('/home', '/lander-1');

-- STEP 4: counting pageview for each session, to identify "bounces"
CREATE TEMPORARY TABLE bounce
SELECT
pu.website_session_id,
pu.landing_pages,
COUNT(pv.website_pageview_id) AS count_of_pv_per_session
FROM pg_url pu
LEFT JOIN website_pageviews pv
	ON pu.website_session_id = pv.website_session_id
GROUP BY pu.website_session_id
HAVING COUNT(pv.website_pageview_id) = 1;

-- STEP 4: summarizing total sessions and bounced sessions, by Landing Page
SELECT
lp.landing_pages,
COUNT(lp.website_session_id) sessions,
COUNT(bounce.website_session_id) bounced_sessions,
ROUND((COUNT(bounce.website_session_id) / COUNT(lp.website_session_id) * 100), 2) bounce_rate
FROM pg_url lp
LEFT JOIN bounce
	ON lp.website_session_id = bounce.website_session_id
GROUP BY 1;

-- the custom lander has a lower bounce rate…success


-- Pull the volume of paid search nonbrand traffic landing on /home and /lander 1, trended weekly since June 1st.
-- Pull our overall paid search bounce rate trended weekly.

-- STEP 1: first pageview and count per session
CREATE TEMPORARY TABLE minpv_and_countpv
SELECT
ws.website_session_id,
MIN(wp.website_pageview_id) AS min_pv,
COUNT(wp.website_pageview_id) AS count_pv_per_session
FROM website_pageviews AS wp
LEFT JOIN website_sessions AS ws
ON wp.website_session_id = ws.website_session_id
WHERE ws.created_at >'2012-06-01'
AND ws.created_at < '2012-08-31'
AND ws.utm_source ='gsearch' -- because we need to limit to the source
AND ws.utm_campaign = 'nonbrand'
GROUP BY 1;

-- STEP 2: identifying landing page
CREATE TEMPORARY TABLE pg_url_2
SELECT
lp.website_session_id,
lp.min_pv,
lp.count_pv_per_session,
wp.pageview_url AS landing_pages,
wp.created_at AS session_created_at
FROM minpv_and_countpv lp
LEFT JOIN website_pageviews wp
	ON lp.min_pv = wp.website_pageview_id
GROUP BY 1;

-- STEP 4: 
-- TRENDING ANALYSIS
SELECT
-- YEARWEEK(session_created_at),
MIN(DATE(session_created_at)) AS week_start_date,
-- COUNT(DISTINCT website_session_id) AS total_sessions,
-- COUNT(DISTINCT CASE WHEN count_pv_per_session = 1 THEN website_session_id) AS bounced_sessions,
ROUND(COUNT(CASE WHEN count_pv_per_session = 1 THEN website_session_id ELSE NULL END) / COUNT(website_session_id) *100,2) AS bounce_rate,
COUNT(CASE WHEN landing_pages = '/home' THEN website_session_id ELSE NULL END)  AS home_sessions,
COUNT(CASE WHEN landing_pages = '/lander-1' THEN website_session_id ELSE NULL END)  AS home_sessions
FROM pg_url_2
GROUP BY YEARWEEK(session_created_at);

