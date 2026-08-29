-- Query: Find all Rental items/contracts with Override Rates, modification details, and Smart Notes
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT 
    sd.sdID AS ServiceDetailID,
    sh.shID AS ServiceHeaderID,
    sh.shContractRALinkID AS RentalAgreementID,
    c.mmcuID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    v.mmveVesselName AS VesselName,
    b.mmbeName AS BerthCode,
    sd.sdInvoiceDescription AS ChargeDescription,
    f.fSalesRate AS StandardRate,
    f.fOverrideRate AS OverrideRate,
    (f.fOverrideRate - f.fSalesRate) AS RateVariance,
    COALESCE(
        eModSD.mmemFirstName + ' ' + eModSD.mmemSurname,
        eModF.mmemFirstName + ' ' + eModF.mmemSurname,
        eEntSD.mmemFirstName + ' ' + eEntSD.mmemSurname,
        'System'
    ) AS ModifiedByEmployee,
    COALESCE(sd.sdModifiedDate, f.fModifiedDate, sd.sdEnteredDate, f.fCreatedDate) AS ModifiedDate,
    CASE WHEN sn.NotesCount > 0 THEN 'Yes (' + CAST(sn.NotesCount AS varchar) + ' note(s))' ELSE 'No' END AS HasSmartNoteAttached,
    sn.LatestNoteComment AS SmartNoteContent
FROM dbo.ngServiceDetail sd
INNER JOIN dbo.ngFinancials f ON sd.sdFinancialID = f.FinancialID
INNER JOIN dbo.ngServiceHeader sh ON sd.sdServiceHeaderID = sh.shID
LEFT JOIN dbo.tmmRentalAgreement ra ON sh.shContractRALinkID = ra.mmraID
LEFT JOIN dbo.tmmCustomer c ON sh.shCustomerID = c.mmcuID
LEFT JOIN dbo.tmmVessel v ON sh.shVesselID = v.mmveID
LEFT JOIN dbo.tmmBerth b ON sd.sdLocationID = b.mmbeID
LEFT JOIN dbo.tmmEmployee eModSD ON sd.sdModifiedByID = eModSD.mmemID
LEFT JOIN dbo.tmmEmployee eModF ON f.fModifiedBy = eModF.mmemID
LEFT JOIN dbo.tmmEmployee eEntSD ON sd.sdEnteredByID = eEntSD.mmemID
OUTER APPLY (
    SELECT TOP 1 
        COUNT(*) OVER() AS NotesCount,
        h.mmhyComment AS LatestNoteComment
    FROM dbo.tmmHistory h
    WHERE (h.mmhyReferenceType = 200 AND h.mmhyReferencePtr = ra.mmraID)
       OR (h.mmhyReferenceType = 400 AND h.mmhyReferencePtr = sh.shID)
       OR (h.mmhyReferenceType = 100 AND h.mmhyReferencePtr = c.mmcuID)
    ORDER BY h.mmhyEnteredDate DESC
) sn
WHERE f.fOverrideRate IS NOT NULL 
  AND f.fOverrideRate <> 0
ORDER BY COALESCE(sd.sdModifiedDate, f.fModifiedDate, sd.sdEnteredDate) DESC;
