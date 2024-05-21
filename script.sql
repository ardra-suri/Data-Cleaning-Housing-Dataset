COPY nashvillehousing FROM 
'C:\Program Files\PostgreSQL\16\bin\csv_file\housing-nashville-dataset\Nashville Housing Data for Data Cleaning.csv' 
WITH CSV HEADER;

CREATE TABLE nashvillehousing (
    UniqueID INT,
    ParcelID TEXT,
    LandUse TEXT,
    PropertyAddress TEXT,
    SaleDate DATE,
    SalePrice TEXT,
    LegalReference TEXT,
    SoldAsVacant VARCHAR(3),
    OwnerName TEXT,
    OwnerAddress TEXT,
    Average FLOAT,
    TaxDistrict TEXT,
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

-- If SaleDate is not in DATE format, first update or create a new column with converted dates
ALTER TABLE nashvillehousing
ADD COLUMN SaleDateConverted DATE;

UPDATE nashvillehousing
SET SaleDateConverted = TO_DATE(SaleDate, 'MM/DD/YYYY') 
WHERE SaleDateConverted IS NULL;

-- View converted sale date
SELECT SaleDateConverted, SaleDate
FROM nashvillehousing;


-- View all records ordered by ParcelID
SELECT *
FROM nashvillehousing
ORDER BY ParcelID;

-- Select and update property address where null
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
       COALESCE(a.PropertyAddress, b.PropertyAddress) AS ResolvedAddress
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Update property address using COALESCE
UPDATE nashvillehousing a
SET PropertyAddress = COALESCE(a.PropertyAddress, b.PropertyAddress)
FROM nashvillehousing b
WHERE a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
AND a.PropertyAddress IS NULL;


-- Split property address into components
SELECT 
  SPLIT_PART(PropertyAddress, ',', 1) AS Address,
  SPLIT_PART(PropertyAddress, ',', 2) AS City,
  SPLIT_PART(PropertyAddress, ',', 3) AS State
FROM nashvillehousing;

-- Add and update split address columns
ALTER TABLE nashvillehousing
ADD COLUMN PropertySplitAddress VARCHAR(255),
ADD COLUMN PropertySplitCity VARCHAR(255),
ADD COLUMN PropertySplitState VARCHAR(255);

UPDATE nashvillehousing
SET PropertySplitAddress = SPLIT_PART(PropertyAddress, ',', 1),
    PropertySplitCity = SPLIT_PART(PropertyAddress, ',', 2),
    PropertySplitState = SPLIT_PART(PropertyAddress, ',', 3);

-- View all records
SELECT *
FROM nashvillehousing;

-- Split owner address into components
SELECT 
  SPLIT_PART(OwnerAddress, ',', 1) AS OwnerAddress,
  SPLIT_PART(OwnerAddress, ',', 2) AS OwnerCity,
  SPLIT_PART(OwnerAddress, ',', 3) AS OwnerState
FROM nashvillehousing;

-- Add and update split owner address columns
ALTER TABLE nashvillehousing
ADD COLUMN OwnerSplitAddress VARCHAR(255),
ADD COLUMN OwnerSplitCity VARCHAR(255),
ADD COLUMN OwnerSplitState VARCHAR(255);

UPDATE nashvillehousing
SET OwnerSplitAddress = SPLIT_PART(OwnerAddress, ',', 1),
    OwnerSplitCity = SPLIT_PART(OwnerAddress, ',', 2),
    OwnerSplitState = SPLIT_PART(OwnerAddress, ',', 3);

-- View all records
SELECT *
FROM nashvillehousing;

-- View distinct values and counts for SoldAsVacant
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM nashvillehousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- Select and convert SoldAsVacant values
SELECT SoldAsVacant,
       CASE 
         WHEN SoldAsVacant = 'Y' THEN 'Yes'
         WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
       END AS ConvertedSoldAsVacant
FROM nashvillehousing;

-- Update SoldAsVacant values
UPDATE nashvillehousing
SET SoldAsVacant = CASE 
                       WHEN SoldAsVacant = 'Y' THEN 'Yes'
                       WHEN SoldAsVacant = 'N' THEN 'No'
                       ELSE SoldAsVacant
                   END;

-- Remove duplicates using CTE
WITH RowNumCTE AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
           ORDER BY UniqueID
         ) AS row_num
  FROM nashvillehousing
)
DELETE FROM nashvillehousing
WHERE UniqueID IN (
  SELECT UniqueID
  FROM RowNumCTE
  WHERE row_num > 1
);

-- View all records
SELECT *
FROM nashvillehousing;


-- View all columns
SELECT *
FROM nashvillehousing;

-- Drop unused columns
ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
