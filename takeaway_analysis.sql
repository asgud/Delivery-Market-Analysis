-- ============================================================================
-- TAKEAWAY DATABASE ANALYSIS
-- ============================================================================
-- Project:     Food Delivery Platform Analysis
-- Database:    Takeaway.com (Netherlands)
-- Description: SQL analysis exploring restaurant distribution, pricing trends,
--              and delivery patterns across Dutch cities using Takeaway data.
-- ===========================================================================


-- ############################################################################
-- 1. DATABASE SCHEMA OVERVIEW
-- ############################################################################
-- 
-- The Takeaway database consists of 6 tables:
--
-- RESTAURANTS (Primary table)
--   - primarySlug (PK): Unique restaurant identifier
--   - Contains: name, address, city, ratings, delivery info, coordinates
--
-- MENUITEMS
--   - ID (PK): Unique menu item identifier  
--   - primarySlug (FK): Links to restaurants
--   - Contains: name, description, price, alcohol/caffeine content
--
-- LOCATIONS
--   - ID (PK): Unique location identifier
--   - Contains: name, postalCode, city, coordinates
--
-- LOCATIONS_TO_RESTAURANTS 
--   - Maps many-to-many relationship between locations and restaurants
--
-- CATEGORIES
--   - id (PK): Category identifier
--   - Contains: restaurant_id, name, item_id
--
-- CATEGORIES_RESTAURANTS
--   - Maps categories to restaurants
--
-- ############################################################################


-- ============================================================================
-- 2. DATA QUALITY CHECKS
-- ============================================================================
-- Purpose: Validate data integrity before analysis

-- 2.1 Check table structure and column properties
-- Returns: column names, types, nullable status, default values
PRAGMA table_info(restaurants);
PRAGMA table_info(menuItems);
PRAGMA table_info(locations);
PRAGMA table_info(locations_to_restaurants);
PRAGMA table_info(categories);
PRAGMA table_info(categories_restaurants);

-- 2.2 Count total records in each table
SELECT 'restaurants' AS table_name, COUNT(*) AS row_count FROM restaurants
UNION ALL
SELECT 'menuItems', COUNT(*) FROM menuItems
UNION ALL
SELECT 'locations', COUNT(*) FROM locations
UNION ALL
SELECT 'locations_to_restaurants', COUNT(*) FROM locations_to_restaurants
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'categories_restaurants', COUNT(*) FROM categories_restaurants;

-- 2.3 Count unique restaurants
SELECT COUNT(DISTINCT primarySlug) AS unique_restaurants
FROM restaurants;

-- 2.4 Identify missing or empty values in restaurants table
-- Note: Critical for ensuring data quality in downstream analysis
SELECT 
    SUM(CASE WHEN primarySlug IS NULL OR primarySlug = '' THEN 1 ELSE 0 END) AS missing_primarySlug,
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS missing_name,
    SUM(CASE WHEN city IS NULL OR city = '' THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN ratings IS NULL THEN 1 ELSE 0 END) AS missing_ratings,
    SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS missing_latitude,
    SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS missing_longitude
FROM restaurants;


-- ############################################################################
-- 3. BUSINESS QUESTIONS
-- ############################################################################

-- ============================================================================
-- 3.1 PRICE DISTRIBUTION OF MENU ITEMS
-- ============================================================================
-- Question: What is the price distribution of menu items?
-- Insight:  Understanding price ranges helps identify market positioning
--           and pricing strategies across the platform.

SELECT
    CASE
        WHEN price < 5 THEN '€0 - €5'
        WHEN price >= 5 AND price < 10 THEN '€5 - €10'
        WHEN price >= 10 AND price < 15 THEN '€10 - €15'
        WHEN price >= 15 AND price < 20 THEN '€15 - €20'
        ELSE '€20+'
    END AS price_range,
    COUNT(*) AS item_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM menuItems
WHERE price IS NOT NULL 
  AND price > 0  -- Exclude free items or data errors
GROUP BY 
    CASE
        WHEN price < 5 THEN '€0 - €5'
        WHEN price >= 5 AND price < 10 THEN '€5 - €10'
        WHEN price >= 10 AND price < 15 THEN '€10 - €15'
        WHEN price >= 15 AND price < 20 THEN '€15 - €20'
        ELSE '€20+'
    END
ORDER BY 
    MIN(price);


-- ============================================================================
-- 3.2 DISTRIBUTION OF RESTAURANTS PER LOCATION
-- ============================================================================
-- Question: What is the distribution of restaurants per location/city?
-- Insight:  Identifies market saturation and potential expansion opportunities.

SELECT
    l.city,
    COUNT(DISTINCT ltr.restaurant_id) AS restaurant_count,
    ROUND(COUNT(DISTINCT ltr.restaurant_id) * 100.0 / 
          SUM(COUNT(DISTINCT ltr.restaurant_id)) OVER(), 2) AS market_share_pct
FROM locations l
INNER JOIN locations_to_restaurants ltr
    ON l.ID = ltr.location_id
WHERE l.city IS NOT NULL
GROUP BY l.city
ORDER BY restaurant_count DESC;


-- ============================================================================
-- 3.3 TOP 10 PIZZA RESTAURANTS BY RATING
-- ============================================================================
-- Question: Which are the top 10 pizza restaurants by rating?
-- Method:   Weighted scoring combining rating value with review volume
--           to balance quality perception with statistical significance.

SELECT 
    r.primarySlug AS restaurant_name,
    r.name AS display_name,
    r.city,
    r.ratings AS rating,
    r.ratingsNumber AS review_count,
    ROUND(r.ratings * LOG(r.ratingsNumber + 1), 2) AS weighted_score
FROM restaurants r
INNER JOIN menuItems m
    ON r.primarySlug = m.primarySlug
WHERE LOWER(m.name) LIKE '%pizza%'
  AND r.ratings > 0
  AND r.ratingsNumber >= 5  -- Minimum reviews for statistical relevance
GROUP BY r.primarySlug, r.name, r.city, r.ratings, r.ratingsNumber
ORDER BY weighted_score DESC
LIMIT 10;


-- ============================================================================
-- 3.4 KAPSALON LOCATIONS & AVERAGE PRICES
-- ============================================================================
-- Question: Map locations offering kapsalons and their average price.
-- Context:  Kapsalon is a popular Dutch fast food dish consisting of
--           fries, shawarma/döner, cheese, and salad with garlic sauce.

SELECT 
    l.city,
    COUNT(DISTINCT m.primarySlug) AS restaurant_count,
    ROUND(AVG(m.price), 2) AS avg_kapsalon_price,
    ROUND(MIN(m.price), 2) AS min_price,
    ROUND(MAX(m.price), 2) AS max_price
FROM locations l
INNER JOIN locations_to_restaurants ltr
    ON l.ID = ltr.location_id
INNER JOIN menuItems m 
    ON m.primarySlug = ltr.restaurant_id 
WHERE l.city IS NOT NULL 
  AND LOWER(m.name) LIKE '%kapsalon%'
  AND m.price > 1  -- Filter out likely data errors
GROUP BY l.city
ORDER BY avg_kapsalon_price ASC;


-- ============================================================================
-- 3.5 BEST PRICE-TO-RATING RATIO RESTAURANTS
-- ============================================================================
-- Question: Which restaurants offer the best value (high rating, low price)?
-- Method:   Weighted score = (rating × log(reviews + 1)) / price
--           - Log dampens the effect of extremely high review counts
--           - Division by price rewards affordable options
-- Example:  Using burgers as the test category

SELECT 
    r.primarySlug AS restaurant_name,
    r.city,
    r.ratings AS rating,
    r.ratingsNumber AS review_count,
    ROUND(MIN(m.price), 2) AS lowest_burger_price,
    ROUND((r.ratings * LOG(r.ratingsNumber + 1)) / MIN(m.price), 3) AS value_score
FROM restaurants r
INNER JOIN menuItems m
    ON r.primarySlug = m.primarySlug
WHERE LOWER(m.name) LIKE '%burger%'
  AND r.ratings > 0
  AND r.ratingsNumber >= 10  -- Ensure statistical significance
  AND m.price > 3            -- Filter unrealistic prices
GROUP BY r.primarySlug, r.city, r.ratings, r.ratingsNumber
ORDER BY value_score DESC
LIMIT 15;


-- ============================================================================
-- 3.6 DELIVERY DEAD ZONES
-- ============================================================================
-- Question: Where are the delivery 'dead zones' with minimal coverage?
-- Definition: Areas with 3 or fewer available restaurants
-- Insight:   Identifies underserved markets for potential expansion

SELECT
    l.city,
    l.postalCode,
    COUNT(DISTINCT ltr.restaurant_id) AS restaurant_count
FROM locations l
LEFT JOIN locations_to_restaurants ltr
    ON l.ID = ltr.location_id
WHERE l.city IS NOT NULL
GROUP BY l.city, l.postalCode
HAVING COUNT(DISTINCT ltr.restaurant_id) <= 3
ORDER BY restaurant_count ASC, l.city;


-- ============================================================================
-- 3.7 VEGETARIAN & VEGAN DISH AVAILABILITY BY AREA
-- ============================================================================
-- Question: How does plant-based dish availability vary by area?
-- Method:   Search menu items for vegetarian/vegan keywords

SELECT
    l.city,
    COUNT(*) AS veg_vegan_dish_count
FROM locations l
JOIN locations_to_restaurants ltr
    ON l.ID = ltr.location_id
JOIN menuItems m
    ON m.primarySlug = ltr.restaurant_id
WHERE l.city IS NOT NULL
  AND (
        LOWER(m.name) LIKE '%vegetarian%'
     OR LOWER(m.name) LIKE '%vegan%'
     OR LOWER(m.name) LIKE '%veg%'
     OR LOWER(m.name) LIKE '%plant%'
  )
GROUP BY l.city
ORDER BY veg_vegan_dish_count DESC;


-- ============================================================================
-- 3.8 WORLD HUMMUS ORDER (WHO) - TOP 3 HUMMUS RESTAURANTS
-- ============================================================================
-- Question: Identify the top 3 hummus-serving restaurants
-- Method:   Weighted "Hummus Score" combining rating quality with review volume
--           Formula: rating × log(reviews + 1)
-- Note:     Logarithmic weighting prevents restaurants with few reviews
--           from outranking consistently well-reviewed establishments

SELECT 
    r.primarySlug AS restaurant_name,
    r.name AS display_name,
    r.city,
    r.ratings AS rating,
    r.ratingsNumber AS review_count,
    ROUND(r.ratings * LOG(r.ratingsNumber + 1), 2) AS hummus_score
FROM restaurants r
INNER JOIN menuItems m
    ON m.primarySlug = r.primarySlug
WHERE LOWER(m.name) LIKE '%hummus%'
  AND r.ratings > 0
  AND r.ratingsNumber >= 10
GROUP BY r.primarySlug, r.name, r.city, r.ratings, r.ratingsNumber
ORDER BY hummus_score DESC
LIMIT 3;








