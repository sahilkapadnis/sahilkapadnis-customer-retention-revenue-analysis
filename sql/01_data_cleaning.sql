-- Remove cancelled invoices
DELETE FROM transactions 
WHERE InvoiceNo LIKE 'C%';

-- Remove negative quantity
DELETE FROM transactions 
WHERE Quantity < 0;

-- Remove zero/negative price
DELETE FROM transactions 
WHERE UnitPrice <= 0;

-- Add revenue column (DECIMAL - correct)
ALTER TABLE transactions 
ADD COLUMN revenue DECIMAL(12,2);

-- Populate revenue
UPDATE transactions 
SET revenue = Quantity * UnitPrice;

-- Identify duplicate rows
SELECT COUNT(*) 
FROM (
    SELECT 
        InvoiceNo,
        StockCode,
        Quantity,
        InvoiceDate_clean,
        UnitPrice,
        CustomerID,
        COUNT(*) as cnt
    FROM transactions
    GROUP BY 
        InvoiceNo,
        StockCode,
        Quantity,
        InvoiceDate_clean,
        UnitPrice,
        CustomerID
    HAVING COUNT(*) > 1
) t;

-- Remove duplicates using ROW_NUMBER
WITH ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY InvoiceNo, StockCode, Quantity, InvoiceDate_clean, UnitPrice, CustomerID
            ORDER BY InvoiceNo
        ) AS rn
    FROM transactions
)
DELETE FROM transactions
WHERE (InvoiceNo, StockCode, Quantity, InvoiceDate_clean, UnitPrice, CustomerID) IN (
    SELECT InvoiceNo, StockCode, Quantity, InvoiceDate_clean, UnitPrice, CustomerID
    FROM ranked
    WHERE rn > 1
);
