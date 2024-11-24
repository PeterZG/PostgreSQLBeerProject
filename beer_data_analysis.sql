
-- Q1: amount of alcohol in the best beers

-- put any Q1 helper views/functions here

CREATE OR REPLACE VIEW Q1(beer, "sold in", alcohol) AS
SELECT
  name AS beer,
  volume || 'ml ' || sold_in AS "sold in",
  ROUND((volume * abv / 100.0)::numeric, 1) || 'ml' AS alcohol
FROM beers
WHERE rating > 9;



-- Q2: beers that don't fit the ABV style guidelines

-- put any Q2 helper views/functions here

CREATE OR REPLACE VIEW Q2(beer, style, abv, reason) AS
SELECT b.name AS beer, s.name AS style, b.abv,
CASE
WHEN b.abv < s.min_abv THEN 'too weak by ' || round((s.min_abv - b.abv) :: numeric,1) || '%'
WHEN b.abv > s.max_abv THEN 'too strong by ' || round((b.abv - s.max_abv) :: numeric,1) || '%'
END AS reason
FROM beers b
JOIN styles s ON b.style = s.id
AND (b.abv < s.min_abv OR b.abv > s.max_abv)
ORDER BY beer, abv, reason;



-- Q3: Number of beers brewed in each country

-- put any Q3 helper views/functions here

CREATE OR REPLACE VIEW Q3(country, "#beers") AS
SELECT c.name AS country, COUNT(b.name) AS "#beers"
FROM Countries c
LEFT JOIN Locations l ON c.id = l.within
LEFT JOIN Breweries br ON l.id = br.located_in
LEFT JOIN Brewed_by bb ON br.id = bb.brewery
LEFT JOIN Beers b ON bb.beer = b.id
GROUP BY c.name;



-- Q4: Countries where the worst beers are brewed

-- put any Q4 helper views/functions here

CREATE OR REPLACE VIEW Q4(beer, brewery, country)
AS
SELECT beers.name AS beer, breweries.name AS brewery, countries.name AS country
FROM beers
JOIN brewed_by ON beers.id = brewed_by.beer
JOIN breweries ON brewed_by.brewery = breweries.id
JOIN locations ON breweries.located_in = locations.id
JOIN countries ON locations.within = countries.id
WHERE beers.rating < 3;



-- Q5: Beers that use ingredients from the Czech Republic

-- put any Q5 helper views/functions here

CREATE OR REPLACE VIEW Q5(beer, ingredient, "type")
AS
SELECT b.name AS beer, i.name as ingredient, i.itype AS "type"
FROM beers b
JOIN contains c ON b.id = c.beer
JOIN ingredients i ON i.id = c.ingredient
WHERE i.origin = (select id from countries WHERE name = 'Czech Republic');



-- Q6: Beers containing the most used hop and the most used grain

-- Put any Q6 helper views/functions here

-- Helper view for most popular hop
CREATE OR REPLACE VIEW most_popular_hop AS
SELECT i.name AS hop
FROM contains c
JOIN ingredients i ON c.ingredient = i.id
WHERE i.itype = 'hop'
GROUP BY i.name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Helper view for most popular grain
CREATE OR REPLACE VIEW most_popular_grain AS
SELECT i.name AS grain
FROM contains c
JOIN ingredients i ON c.ingredient = i.id
WHERE i.itype = 'grain'
GROUP BY i.name
ORDER BY COUNT(*) DESC
LIMIT 1;

CREATE OR REPLACE VIEW Q6(beer) AS
SELECT b.name AS beer
FROM contains c
JOIN ingredients i ON c.ingredient = i.id
JOIN beers b ON c.beer = b.id
WHERE LOWER(i.name) LIKE LOWER((SELECT grain FROM most_popular_grain) || '%')
AND EXISTS (
SELECT *
FROM contains c2
JOIN ingredients i2 ON c2.ingredient = i2.id
WHERE c2.beer = b.id
AND LOWER(i2.name) LIKE LOWER((SELECT hop FROM most_popular_hop) || '%')
);



-- Q7: Breweries that make no beer

-- put any Q7 helper views/functions here
CREATE OR REPLACE VIEW Q7(brewery)
AS
SELECT b.name AS "brewery"
FROM breweries b
WHERE NOT EXISTS (
    SELECT 1
    FROM brewed_by bb
    WHERE bb.brewery = b.id
)
ORDER BY b.name;



-- Q8: Function to give "full name" of beer

-- helper function to get the shortened form of a brewery name
CREATE OR REPLACE FUNCTION Q8(beer_id INTEGER) RETURNS TEXT AS $$
DECLARE
	brewery_names TEXT[];
	beer_name TEXT;
	full_name TEXT := '';
BEGIN
	SELECT array_agg(breweries.name) INTO brewery_names
	FROM beers
	JOIN brewed_by ON beers.id = brewed_by.beer
	JOIN breweries ON brewed_by.brewery = breweries.id
	WHERE beers.id = beer_id
	GROUP BY beers.id;

	SELECT beers.name INTO beer_name
	FROM beers
	WHERE beers.id = beer_id;

	IF brewery_names IS NULL THEN
		RETURN 'No such beer';
	ELSE
		FOR i IN 1 .. array_upper(brewery_names, 1) LOOP
			full_name := full_name || regexp_replace(brewery_names[i], ' (Beer|Brew).*$','') || ' + ';
		END LOOP;
		full_name := rtrim(full_name, ' + ') || ' ' || beer_name;
		RETURN full_name;
	END IF;
END;
$$ LANGUAGE plpgsql;



-- Q9: Beer data based on partial match of beer name

DROP TYPE IF EXISTS BeerData CASCADE;
CREATE TYPE BeerData AS (beer TEXT, brewer TEXT, info TEXT);

CREATE OR REPLACE FUNCTION Q9(partial_name TEXT) RETURNS SETOF BeerData AS $$
BEGIN
  RETURN QUERY
    WITH beer_data AS (
      SELECT
        beers.name AS beer,
        string_agg(DISTINCT breweries.name, ' + ') AS brewer,
        string_agg(
          CASE ingredients.itype
            WHEN 'hop' THEN 'Hops: ' || ingredients.name
            WHEN 'grain' THEN 'Grain: ' || ingredients.name
            WHEN 'adjunct' THEN 'Extras: ' || ingredients.name
          END,
          E'\n'
          ORDER BY CASE ingredients.itype
            WHEN 'hop' THEN 1
            WHEN 'grain' THEN 2
            WHEN 'adjunct' THEN 3
          END
        ) AS info
      FROM beers
      JOIN brewed_by ON beers.id = brewed_by.beer
      JOIN breweries ON brewed_by.brewery = breweries.id
      JOIN contains ON beers.id = contains.beer
      JOIN ingredients ON contains.ingredient = ingredients.id
      WHERE LOWER(beers.name) LIKE '%' || LOWER(partial_name) || '%'
      GROUP BY beers.id
    )
    SELECT * FROM beer_data;

  -- If no beer data found, return an empty set
  IF NOT FOUND THEN
    RETURN;
  END IF;

  RETURN;
END;
$$ LANGUAGE plpgsql;







