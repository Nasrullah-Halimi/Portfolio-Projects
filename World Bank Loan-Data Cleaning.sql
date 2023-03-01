USE WB
SELECT * FROM WB..IBRD

--Rename columns.
EXEC sp_rename 'IBRD.[Effective Date (Most Recent)]', 'Effective Date', 'COLUMN'
EXEC sp_rename 'IBRD.[Closed Date (Most Recent)]', 'Closed Date', 'COLUMN'

--Standardize date format - Change datetime to date.
SELECT [End of Period], CONVERT(date, [End of Period]) FROM WB..IBRD
UPDATE IBRD
SET [End of Period] = CONVERT(date, [End of Period])

--Change the datetime to date datatype - When there is no date data set it to null.
UPDATE IBRD SET 
[First Repayment Date] = CASE WHEN ISDATE([First Repayment Date]) = 1 THEN CONVERT(date,[First Repayment Date]) ELSE NULL END,
[Last Repayment Date] = CASE WHEN ISDATE([Last Repayment Date]) = 1 THEN CONVERT(date,[Last Repayment Date]) ELSE NULL END,
[Agreement Signing Date] = CASE WHEN ISDATE([Agreement Signing Date]) = 1 THEN CONVERT(date, [Agreement Signing Date]) ELSE NULL END,
[Board Approval Date] = CASE WHEN ISDATE([Board Approval Date]) = 1 THEN CONVERT(date, [Board Approval Date]) ELSE NULL END,
[Effective Date] = CASE WHEN ISDATE([Effective Date]) = 1 THEN CONVERT(date, [Effective Date]) ELSE NULL END,
[Closed Date] = CASE WHEN ISDATE([Closed Date]) = 1 THEN CONVERT(date, [Closed Date]) ELSE NULL END,
[Last Disbursement Date] = CASE WHEN ISDATE([Last Disbursement Date]) = 1 THEN CONVERT(date, [Last Disbursement Date]) ELSE NULL END

--Find @ sign and replace it with comma.
SELECT SUBSTRING(Borrower, 1, CHARINDEX('@', Borrower)) as Borrower FROM WB..IBRD
GROUP BY Borrower

UPDATE IBRD SET 
Borrower = REPLACE(Borrower,'@',','),
[Project Name ] = REPLACE([Project Name ],'@',',')

--Fill in the missing data in column Guarantor where it is null. 
SELECT a.[Loan Number], a.Country, a.Guarantor, b.[Loan Number], b.Country, ISNULL(a.Guarantor, b.Country)
FROM WB..IBRD a
JOIN WB..IBRD b
  ON a.[Country Code] = b.[Country Code]
WHERE a.Guarantor is null

UPDATE a 
SET Guarantor = ISNULL(a.Guarantor, b.Country)
FROM WB..IBRD a
JOIN WB..IBRD b
  ON a.[Country Code] = b.[Country Code]
WHERE a.Guarantor is null

--Splitting the column “Original Principal Amount” into two columns of “Original Amount” and “Currency of Commitment”. 
SELECT
PARSENAME(REPLACE([Original Principal Amount], ',','.'),2)
,PARSENAME(REPLACE([Original Principal Amount], ',','.'),1) 
FROM WB..IBRD

ALTER TABLE WB..IBRD
ADD [Original Amount] NVARCHAR(255)
UPDATE WB..IBRD
SET [Original Amount] = PARSENAME(REPLACE([Original Principal Amount],',','.'),2)

ALTER TABLE WB..IBRD 
ADD [Currency of Commitment] NVARCHAR(50)
UPDATE WB..IBRD
SET [Currency of Commitment] = PARSENAME(REPLACE([Original Principal Amount],',','.'),1)

--Shows distinct Borrowers and their count.
SELECT distinct(Borrower), count(Borrower)
FROM WB..IBRD
GROUP by Borrower
ORDER BY 2

--Update column Borrower with correct data.
UPDATE WB..IBRD 
SET Borrower = CASE 
      WHEN Borrower = 'MinistÃ¨re de lâ€™Economie et de la Relance' THEN 'Ministere de la Economie et de la Relance'
      WHEN Borrower = 'MinistÃ¨re de l Economie et de la Relance' THEN 'Ministere de la Economie et de la Relance'
      WHEN Borrower = 'Ministerio de Econom????y Finanzas' THEN 'Ministerio de Economia y Finanzas'
      WHEN Borrower = 'Ministerio de EconomÂ¡a y Finanzas' THEN 'Ministerio de Economia y Finanzas'
      WHEN Borrower = 'Ministerio de Econom??a y Finanzas' THEN 'Ministerio de Economia y Finanzas'
      WHEN Borrower = 'Ministerio de EconomÃ­a y Finanzas' THEN 'Ministerio de Economia y Finanzas'
      WHEN Borrower = 'Ministerio de Econom?y Finanzas' THEN 'Ministerio de Economia y Finanzas'
      WHEN Borrower = 'Ministerio de Finanzas P?Â§blicas' THEN 'Ministerio de Finanzas Publicas'
      WHEN Borrower = 'Ministerio de Finanzas PÂ£blicas' THEN 'Ministerio de Finanzas Publicas'
      WHEN Borrower = 'Ministerio de Finanzas PÃºblicas' THEN 'Ministerio de Finanzas Publicas'
      WHEN Borrower = 'Ministerio de Econom????y Finanzas P????blic' THEN 'Ministerio de Economia y Finanzas Publicas'
      WHEN Borrower = 'Ministerio de Econom?y Finanzas P?blic' THEN 'Ministerio de Economia y Finanzas Publicas'
      WHEN Borrower = 'Ministerio de Econom?y Finanzas Public' THEN 'Ministry of Treasury'
      WHEN Borrower = 'MinistÃ©rio da Fazenda' THEN 'Ministério da Fazenda'
  ELSE [Borrower]
END 

--Remove duplicates.
WITH CTE_Dup as
(
SELECT *,
    ROW_NUMBER() OVER (Partition by 
    [End of Period],
    [loan Number],
    [Project ID],
    [loan Type],
    [Country],
    [Borrower],
    [loan status],
    [Board Approval Date],
    [Agreement Signing Date],
    [Original Principal amount],
    [First Repayment Date],
    [Last Repayment Date],
    [Closed Date],
    [Last Disbursement Date]
    ORDER BY [End of Period]
    )rownum
 FROM WB..IBRD
)
--SELECT * FROM CTE_Dup WHERE rownum > 1
DELETE FROM CTE_Dup WHERE rownum > 1

--Capitalize the first letter of each word in columns “Project Name”, “Borrower” and “Region”. 
SELECT dbo.InitCap ([Project Name ]) as NewPname FROM WB..IBRD
UPDATE WB..IBRD SET
[Project Name ] = dbo.InitCap ([Project Name ]),
[Borrower] = dbo.InitCap ([Borrower]),
[Region] = dbo.InitCap ([Region])

--Drop the columns not needed. 
ALTER TABLE WB..IBRD
DROP COLUMN [Sold 3rd Party], [Repaid 3rd Party], [Due 3rd Party], [Interest Rate], [Original Principal amount], [Guarantor Country Code]


