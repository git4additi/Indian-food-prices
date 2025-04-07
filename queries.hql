-- Q1) What is the average price of each commodity across different states, and how does it vary by season?

SELECT 
    commodity, state, season, AVG(price) AS avg_price
FROM 
    food_prices
GROUP BY 
    commodity, state, season
ORDER BY 
    commodity, state, season;


-- Q2) Which city has the highest average price for each commodity, and how does it compare to the national average price for that commodity?

WITH national_avg AS (
    SELECT 
        commodity, 
        AVG(price) AS national_avg_price
    FROM 
        food_prices
    GROUP BY 
        commodity
)
SELECT 
    a.city, 
    a.commodity, 
    AVG(a.price) AS city_avg_price, 
    b.national_avg_price
FROM 
    food_prices a
JOIN 
    national_avg b ON a.commodity = b.commodity
GROUP BY 
    a.city, a.commodity, b.national_avg_price
ORDER BY 
    a.commodity, city_avg_price DESC;


-- Q3) Identify the top 5 commodities with the highest price volatility across different markets and states.

SELECT 
    commodity, STDDEV(price) AS price_volatility
FROM 
    food_prices
GROUP BY 
    commodity
ORDER BY 
    price_volatility DESC
LIMIT 5;


-- Q4) Which state has the most significant price difference between the highest and lowest priced commodities?

WITH state_price_range AS (
    SELECT 
        state, MAX(price) AS max_price, MIN(price) AS min_price
    FROM 
        food_prices
    GROUP BY 
        state
)
SELECT 
    state, 
    (max_price - min_price) AS price_difference
FROM 
    state_price_range
ORDER BY 
    price_difference DESC
LIMIT 1;


-- Q5) Which markets have the highest average price for each category, and how does it compare to the overall average price for that category?

WITH category_avg AS (
    SELECT 
        category, AVG(price) AS overall_avg_price
    FROM 
        food_prices
    GROUP BY 
        category
)
SELECT 
    a.market, a.category, AVG(a.price) AS market_avg_price, 
    b.overall_avg_price
FROM 
    food_prices a
JOIN 
    category_avg b ON a.category = b.category
GROUP BY 
    a.market, a.category, b.overall_avg_price
ORDER BY 
    a.category, market_avg_price DESC;


-- Q6) Show only the Top 10 commodities with the highest price increase over the past year.

WITH yearly_avg AS (
    SELECT 
        commodity, year, AVG(price) AS avg_price
    FROM 
        food_prices
    GROUP BY 
        commodity, year
),
price_increase AS (
    SELECT 
        a.commodity, 
        (a.avg_price - b.avg_price) AS price_diff
    FROM 
        yearly_avg a
    JOIN 
        yearly_avg b ON a.commodity = b.commodity AND a.year = b.year + 1
)
SELECT 
    commodity, price_diff
FROM 
    price_increase
ORDER BY 
    price_diff DESC
LIMIT 10;


-- Q7) If a market has high prices for vegetables and fruits, does it also have high prices for cereals and tubers?

WITH category_avg AS (
    SELECT market, category, AVG(price) AS avg_price
    FROM food_prices
    WHERE category IN ('vegetables and fruits', 'cereals and tubers')
    GROUP BY market, category
)
SELECT market, 
    MAX(CASE WHEN category IN ('vegetables and fruits') THEN avg_price ELSE 0 END) AS veg_fruit_price,
    MAX(CASE WHEN category IN ('cereals and tubers') THEN avg_price ELSE 0 END) AS cereal_tuber_price
FROM category_avg
GROUP BY market
HAVING veg_fruit_price > 0 AND cereal_tuber_price > 0
ORDER BY veg_fruit_price DESC, cereal_tuber_price DESC;


-- Q8) Rank commodities within each state based on their average price, and identify the top 3 most expensive commodities per state.

WITH ranked_prices AS (
  SELECT 
    state, commodity, AVG(price) AS avg_price,
    RANK() OVER (PARTITION BY state ORDER BY AVG(price) DESC) AS price_rank
  FROM food_prices 
  GROUP BY state, commodity
)
SELECT 
  state, commodity, avg_price, price_rank
FROM ranked_prices
WHERE price_rank <= 3
ORDER BY state, price_rank;


-- Q9) How do food prices in metropolitan cities compare to other markets during different seasons of the year?

SELECT 
  CASE 
    WHEN city IN ('Delhi', 'Mumbai', 'Kolkata', 'Chennai', 'Bangalore', 'Hyderabad') THEN 'Metropolitan'
    ELSE 'Other'
  END AS city_type,
  season, category, AVG(price) AS avg_price
FROM food_prices
GROUP BY 
  CASE 
    WHEN city IN ('Delhi', 'Mumbai', 'Kolkata', 'Chennai', 'Bangalore', 'Hyderabad') THEN 'Metropolitan'
    ELSE 'Other'
  END,
  season, category
ORDER BY 
  category,
  season,
  city_type;


-- Q10) Analyse the evolution of commodity prices over time, revealing year-to-year price dynamics and identifying significant market trends.

SELECT 
    commodity, year, AVG(price) AS avg_price,
    LAG(AVG(price), 1) OVER (PARTITION BY commodity ORDER BY year) AS prev_year_price,
    ((AVG(price) - LAG(AVG(price), 1) OVER (PARTITION BY commodity ORDER BY year)) / LAG(AVG(price), 1) OVER (PARTITION BY commodity ORDER BY year)) * 100 AS pct_change
FROM 
    food_prices
GROUP BY 
    commodity, year
ORDER BY 
    commodity, year;


-- Identify the top 5 markets with the highest average price for each commodity, considering only the latest year.

WITH latest_year AS (
    SELECT MAX(year) AS max_year FROM food_prices
),
ranked_data AS (
    SELECT 
        fp.year, fp.state, fp.market, fp.commodity, 
        AVG(fp.price) AS avg_price, 
        RANK() OVER (PARTITION BY fp.commodity ORDER BY AVG(fp.price) DESC) AS market_rank
    FROM food_prices fp
    JOIN latest_year ly ON fp.year = ly.max_year
    GROUP BY fp.year, fp.state, fp.market, fp.commodity
)
SELECT 
    year, state, market, commodity, avg_price, market_rank
FROM ranked_data WHERE market_rank <= 5
ORDER BY commodity, market_rank, state, year;


-- Q12) Analyze the impact of seasonality on price volatility to calculate the coefficient of variation for each commodity.

SELECT 
    commodity, season, AVG(price) AS avg_price, 
    STDDEV(price) AS stddev_price,
    (STDDEV(price) / AVG(price)) * 100 AS coeff_variation
FROM 
    food_prices
GROUP BY 
    commodity, season
ORDER BY 
    commodity, season;


-- Q13) Identify the cheapest and costliest state for each commodity for a given year? Take the year 2024 for example.

WITH price_extremes AS (
    SELECT
        commodity,
        state,
        MIN(price) AS min_price,
        MAX(price) AS max_price
    FROM food_prices
    WHERE year = 2024
    GROUP BY commodity, state
),
ranked_extremes AS (
    SELECT
        commodity,
        state AS cheapest_state,
        min_price AS cheapest_price,
        NULL AS costliest_state,
        NULL AS costliest_price,
        RANK() OVER (PARTITION BY commodity ORDER BY min_price ASC) AS cheapest_rank,
        RANK() OVER (PARTITION BY commodity ORDER BY max_price DESC) AS costliest_rank
    FROM price_extremes
    UNION ALL
    SELECT
        commodity,
        NULL AS cheapest_state,
        NULL AS cheapest_price,
        state AS costliest_state,
        max_price AS costliest_price,
        RANK() OVER (PARTITION BY commodity ORDER BY min_price ASC) AS cheapest_rank,
        RANK() OVER (PARTITION BY commodity ORDER BY max_price DESC) AS costliest_rank
    FROM price_extremes
)
SELECT
    commodity,
    MAX(CASE WHEN cheapest_rank = 1 THEN cheapest_state END) AS cheapest_state,
    MAX(CASE WHEN cheapest_rank = 1 THEN cheapest_price END) AS cheapest_state_price,
    MAX(CASE WHEN costliest_rank = 1 THEN costliest_state END) AS costliest_state,
    MAX(CASE WHEN costliest_rank = 1 THEN costliest_price END) AS costliest_state_price
FROM ranked_extremes
GROUP BY commodity
ORDER BY commodity;


-- Q14) Which cities experienced consistent food price inflation over the years?

SELECT 
    city, COUNT(DISTINCT year) AS years_with_inflation
FROM (
    SELECT 
        city, year, AVG(price) AS avg_yearly_price,
        LAG(AVG(price)) OVER (PARTITION BY city ORDER BY year) AS prev_year_price
    FROM food_prices
    GROUP BY city, year
) t
WHERE t.avg_yearly_price > t.prev_year_price
GROUP BY city
ORDER BY years_with_inflation DESC;


-- Q15) Identify the top 10 regions in India where food prices are the most volatile, by calculating the average price variance across nearby markets (within a 100 km radius).

WITH markets AS (
  SELECT
    state, city, market,
    AVG(price) AS avg_price,
    MAX(latitude) AS latitude,
    MAX(longitude) AS longitude,
    ROW_NUMBER() OVER (PARTITION BY state, city, market) AS rn
  FROM food_prices
  GROUP BY state, city, market
),
nearby_markets AS (
    SELECT 
    m1.state, m1.city, m1.market, m1.avg_price AS price1, m2.market AS nearby_market,
    m2.avg_price AS price2,
    111.045 * DEGREES(ACOS(
      LEAST(1.0, COS(RADIANS(m1.latitude)) * COS(RADIANS(m2.latitude)) *
      COS(RADIANS(m2.longitude) - RADIANS(m1.longitude)) +
      SIN(RADIANS(m1.latitude)) * SIN(RADIANS(m2.latitude)))
    )) AS distance_km
  FROM markets m1 JOIN markets m2 ON m1.market != m2.market
  WHERE
  111.045 * DEGREES(ACOS(
      LEAST(1.0, COS(RADIANS(m1.latitude)) * COS(RADIANS(m2.latitude)) *
      COS(RADIANS(m2.longitude) - RADIANS(m1.longitude)) +
      SIN(RADIANS(m1.latitude)) * SIN(RADIANS(m2.latitude)))
    )) <= 100
)
SELECT 
  state, city, market, 
  AVG(ABS(price1 - price2)) AS avg_price_volatility,
  COUNT(DISTINCT nearby_market) AS nearby_market_count
FROM nearby_markets
GROUP BY state, city, market
HAVING COUNT(DISTINCT nearby_market) > 2
ORDER BY avg_price_volatility DESC LIMIT 10;
