-- Query: Find Agreements/Rentals under tmmOwnershipType 'WEMT 2026' and 'WEMT ACC 2026' with money owing
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT 
    oa.mmoaID AS OwnershipAgreementID,
    ot.mmotDescription AS OwnershipTypeDescription,
    c.mmcuID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    b.mmbeName AS BerthCode,
    c.mmcuAccountBalance AS AccountBalance,
    c.mmcuOverdue AS OverdueAmount,
    oa.mmoaStartDate AS ContractStartDate,
    oa.mmoaEndDate AS ContractEndDate,
    oa.mmoaActive AS IsAgreementActive
FROM dbo.tmmOwnershipAgreement oa
INNER JOIN dbo.tmmOwnershipType ot ON oa.mmoaOwnershipTypePtr = ot.mmotID
INNER JOIN dbo.tmmCustomer c ON oa.mmoaCustomerPtr = c.mmcuID
LEFT JOIN dbo.tmmBerth b ON oa.mmoaBerthPtr = b.mmbeID
WHERE ot.mmotDescription IN ('WEMT 2026', 'WEMT ACC 2026')
  AND c.mmcuAccountBalance > 0
ORDER BY ot.mmotDescription, c.mmcuAccountBalance DESC;
