# Beer Data Analysis

This project provides tools for analyzing a beer database, including SQL queries and views to extract insights about beer characteristics, styles, and production.

## Files
- **`beer_database_setup.dump`**: PostgreSQL database dump that sets up the database schema, including domains, types, and constraints.
- **`beer_data_analysis.sql`**: SQL script containing views and queries to analyze beer data, focusing on alcohol content, style compliance, and production statistics.

## Features
1. **Alcohol Content Analysis**: Identify beers with the highest alcohol content.
2. **Style Compliance Check**: Detect beers that deviate from alcohol by volume (ABV) style guidelines.
3. **Production Statistics**: Count the number of beers brewed per country.

## Technology Stack
- **Database**: PostgreSQL 13
- **Languages**: SQL

## How to Use
1. Import the database schema:
   ```bash
   psql -U <username> -d <database_name> -f beer_database_setup.dump
   ```
2. Run the SQL queries:
   ```bash
   psql -U <username> -d <database_name> -f beer_data_analysis.sql
   ```

## Author
This project was created for academic purposes in the COMP3311 course.
