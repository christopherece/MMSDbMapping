-- Query: Find WEMT Rental and OPEX agreements with money owing
-- Business rule:
--   RR = Rental
--   AC = OPEX
--   OPEX is billed by Trust, but utilities are billed by Council - check billing agent
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

-- Query: Check actual WEMT account-code prefixes and balances
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT
    ot.mmotDescription AS OwnershipTypeDescription,
    c.mmcuID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    CASE
        WHEN UPPER(REPLACE(LTRIM(RTRIM(COALESCE(CAST(c.mmcuAccountCode AS nvarchar(50)), ''))), ' ', '')) LIKE 'RR%' THEN 'Rental'
        WHEN UPPER(REPLACE(LTRIM(RTRIM(COALESCE(CAST(c.mmcuAccountCode AS nvarchar(50)), ''))), ' ', '')) LIKE 'AC%' THEN 'OPEX'
        ELSE 'Not RR/AC'
    END AS AccountType,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    b.mmbeName AS BerthNumber,
    sh.shBillingAgentID,
    ba.mmbaDescription AS BillingAgentName,
    c.mmcuAccountBalance AS AccountBalance,
    c.mmcuOverdue AS OverdueAmount,
    oa.mmoaStartDate AS ContractStartDate,
    oa.mmoaEndDate AS ContractEndDate,
    oa.mmoaActive AS IsAgreementActive
FROM dbo.tmmOwnershipAgreement oa
INNER JOIN dbo.tmmOwnershipType ot ON oa.mmoaOwnershipTypePtr = ot.mmotID
INNER JOIN dbo.tmmCustomer c ON oa.mmoaCustomerPtr = c.mmcuID
LEFT JOIN dbo.tmmBerth b ON oa.mmoaBerthPtr = b.mmbeID
LEFT JOIN (
    SELECT
        shCustomerID,
        MAX(shBillingAgentID) AS shBillingAgentID
    FROM dbo.ngServiceHeader
    GROUP BY shCustomerID
) sh ON sh.shCustomerID = c.mmcuID
LEFT JOIN dbo.tmmBillingAgent ba ON sh.shBillingAgentID = ba.mmbaID
WHERE ot.mmotDescription IN ('WEMT 2026', 'WEMT ACC 2026')
  AND c.mmcuAccountBalance > 0
ORDER BY
    AccountType,
    ba.mmbaDescription,
    c.mmcuAccountBalance DESC;
