1. Standardize Date Format

-- Add a new column for standardized dates
ALTER TABLE SanFranciscoHousing
ADD COLUMN UpdatedSaleDate DATE;

-- Update the new column with converted dates
UPDATE SanFranciscoHousing
SET UpdatedSaleDate = TO_DATE(SaleDate, 'YYYY-MM-DD');

-- Validate the changes
SELECT UpdatedSaleDate, SaleDate
FROM SanFranciscoHousing;


2. Populate Missing Property Address Data
Using ISNULL or COALESCE to fill missing property addresses:

-- Identify missing Property Addresses by joining on ParcelID
SELECT a.ParcelID, a.PropertyAddress, 
       b.ParcelID AS SourceParcelID, b.PropertyAddress AS SourcePropertyAddress,
       COALESCE(a.PropertyAddress, b.PropertyAddress) AS ResolvedAddress
FROM SanFranciscoHousing a
LEFT JOIN SanFranciscoHousing b
  ON a.ParcelID = b.ParcelID
 AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update missing Property Addresses
UPDATE SanFranciscoHousing a
SET PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM SanFranciscoHousing b
WHERE a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID
  AND a.PropertyAddress IS NULL;

-- Check for remaining null Property Addresses
SELECT PropertyAddress
FROM SanFranciscoHousing
WHERE PropertyAddress IS NULL;


3. Break Out Full Address into Individual Columns
Property Address

-- Add columns for Street and City
ALTER TABLE SanFranciscoHousing
ADD COLUMN PropertyAddressStreet VARCHAR(255);

ALTER TABLE SanFranciscoHousing
ADD COLUMN PropertyAddressCity VARCHAR(255);

-- Populate the new columns
UPDATE SanFranciscoHousing
SET PropertyAddressStreet = SPLIT_PART(PropertyAddress, ',', 1);

UPDATE SanFranciscoHousing
SET PropertyAddressCity = TRIM(SPLIT_PART(PropertyAddress, ',', 2));

-- Validate the changes
SELECT PropertyAddressStreet, PropertyAddressCity
FROM SanFranciscoHousing;

4. Change "Y" to "Yes" and "N" to "No" in the "Sold As Vacant" Field

-- Standardize the SoldAsVacant column values
UPDATE SanFranciscoHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

-- Validate unique values
SELECT DISTINCT SoldAsVacant
FROM SanFranciscoHousing;


5. Remove Duplicates

Snowflake doesn’t allow direct row-number-based DELETE, so we use a QUALIFY clause to isolate duplicates and retain only one row:

-- Identify duplicates using ROW_NUMBER()
CREATE OR REPLACE TABLE SanFranciscoHousing_Cleaned AS
SELECT *
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM SanFranciscoHousing
)
QUALIFY row_num = 1; -- Keep only the first row

-- Verify the cleaned dataset
SELECT *
FROM SanFranciscoHousing_Cleaned;
