-- Query: Find all Rental Agreements ending on September 29, 2026
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT 
    ra.mmraID AS RentalAgreementID,
    ra.mmraMarinaPtr AS MarinaID,
    m.mmmaMarinaName AS MarinaName,
    c.mmcuID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    p.mmprDescription AS RentalProduct,
    ra.mmraRentalPeriodFrom AS PeriodFrom,
    ra.mmraRentalPeriodTo AS PeriodTo,
    ra.mmraEndDate AS ContractEndDate,
    ra.mmraTerminationDate AS TerminationDate,
    ra.mmraActive AS IsActive
FROM dbo.tmmRentalAgreement ra
LEFT JOIN dbo.tmmCustomer c ON ra.mmraCustomerPtr = c.mmcuID
LEFT JOIN dbo.tmmMarina m ON ra.mmraMarinaPtr = m.mmmaID
LEFT JOIN dbo.tmmProduct p ON ra.mmraRentalProductPtr = p.mmprID
WHERE CAST(ra.mmraRentalPeriodTo AS DATE) = '2026-09-29'
   OR CAST(ra.mmraEndDate AS DATE) = '2026-09-29'
   OR CAST(ra.mmraTerminationDate AS DATE) = '2026-09-29'
ORDER BY ra.mmraID;
