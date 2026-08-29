-- Query: Find Berth Owners and Private Renters (Sub-Leases) under WEMT, WEXT, and Westhaven Ownership Types
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

--------------------------------------------------------------------------------
-- SECTION 1: Active Berth Owners & Current Active Private Renters / Sub-Tenants
--------------------------------------------------------------------------------
SELECT 
    ot.mmotDescription AS OwnershipTypeDescription,
    oa.mmoaID AS OwnershipAgreementID,
    b.mmbeID AS BerthID,
    b.mmbeName AS BerthCode,
    b.mmbePier AS Pier,
    
    -- Owner Details
    cOwner.mmcuID AS OwnerCustomerID,
    cOwner.mmcuAccountCode AS OwnerAccountCode,
    ISNULL(cOwner.mmcuLongName, ISNULL(cOwner.mmcuFirstName + ' ' + cOwner.mmcuSurname, cOwner.mmcuSurname)) AS OwnerName,
    cOwner.mmcuEmail AS OwnerEmail,
    cOwner.mmcuBusPhoneNo AS OwnerBusPhone,
    cOwner.mmcuMobileNo AS OwnerMobilePhone,
    cOwner.mmcuAccountBalance AS OwnerAccountBalance,
    
    -- Private Renter / Sub-Tenant Details (if berth is sub-leased)
    cRenter.mmcuID AS PrivateRenterCustomerID,
    ISNULL(cRenter.mmcuAccountCode, 'N/A') AS PrivateRenterAccountCode,
    ISNULL(ISNULL(cRenter.mmcuLongName, ISNULL(cRenter.mmcuFirstName + ' ' + cRenter.mmcuSurname, cRenter.mmcuSurname)), 'No Private Renter') AS PrivateRenterName,
    cRenter.mmcuEmail AS PrivateRenterEmail,
    cRenter.mmcuMobileNo AS PrivateRenterMobilePhone,
    ra.mmraID AS SubLeaseRentalAgreementID,
    ra.mmraRentalPeriodFrom AS SubLeasePeriodFrom,
    ra.mmraRentalPeriodTo AS SubLeasePeriodTo,
    CASE 
        WHEN ra.mmraID IS NOT NULL AND ra.mmraActive = 1 THEN 'Active Sub-Lease'
        WHEN ra.mmraID IS NOT NULL THEN 'Expired Sub-Lease'
        ELSE 'Owner Occupied / No Sub-Lease'
    END AS SubLeaseStatus,
    oa.mmoaStartDate AS OwnerContractStartDate,
    oa.mmoaEndDate AS OwnerContractEndDate
FROM dbo.tmmOwnershipAgreement oa
INNER JOIN dbo.tmmOwnershipType ot ON oa.mmoaOwnershipTypePtr = ot.mmotID
INNER JOIN dbo.tmmCustomer cOwner ON oa.mmoaCustomerPtr = cOwner.mmcuID
LEFT JOIN dbo.tmmBerth b ON oa.mmoaBerthPtr = b.mmbeID
LEFT JOIN dbo.tmmRentalManagement rm ON rm.mmrmOwnershipAgreementPtr = oa.mmoaID AND rm.mmrmActive = 1
LEFT JOIN dbo.tmmRentalLink rl ON rl.mmrlRentalManagementPtr = rm.mmrmID
LEFT JOIN dbo.tmmRentalAgreement ra ON rl.mmrlRentalAgreementPtr = ra.mmraID AND ra.mmraActive = 1
LEFT JOIN dbo.tmmCustomer cRenter ON ra.mmraCustomerPtr = cRenter.mmcuID
WHERE oa.mmoaActive = 1
  AND (
      ot.mmotDescription LIKE '%WEMT%' 
   OR ot.mmotDescription LIKE '%WEXT%' 
   OR ot.mmotDescription LIKE '%westhaven%'
  )
ORDER BY ot.mmotDescription, b.mmbeName, cOwner.mmcuAccountCode;
