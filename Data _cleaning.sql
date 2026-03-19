-- SQL Data Cleaning Project
-- Author: Fowsiya Haji

-- ========================================
-- 1. Initial Data Exploration
-- ========================================

SELECT * 
FROM layoffs;

-- ========================================
-- 2. Creating Staging Table
-- ========================================

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- ========================================
-- 3. Removing Duplicates
-- ========================================

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
) AS row_num
FROM layoffs_staging;

CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT,
  row_num INT
);

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions
) AS row_num
FROM layoffs_staging;

SET SQL_SAFE_UPDATES = 0;

DELETE FROM layoffs_staging2
WHERE row_num > 1;

SET SQL_SAFE_UPDATES = 1;

-- ========================================
-- 4. Standardising Data
-- ========================================

-- Remove whitespace
UPDATE layoffs_staging2
SET company = TRIM(company);

-- Standardise industry names
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Clean country formatting
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Convert date format
UPDATE layoffs_staging2
SET date = STR_TO_DATE(date,'%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;

-- ========================================
-- 5. Handling Missing Values
-- ========================================

-- Fill missing industry values using self join
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Remove empty industry values
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- ========================================
-- 6. Removing Unnecessary Data
-- ========================================

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- ========================================
-- 7. Final Cleanup
-- ========================================

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final cleaned dataset
SELECT *
FROM layoffs_staging2;
