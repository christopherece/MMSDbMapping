-- Query: Count total number of berths that are available and not decommissioned
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT
    COUNT(*) AS TotalAvailableBerths
FROM dbo.tmmBerth b
LEFT JOIN dbo.tmmBerthStatus bs ON b.mmbeStatusPtr = bs.mmbsID
WHERE b.mmbeActive = 1
  AND b.mmbeDecommissionedDate IS NULL
  AND (
        LOWER(COALESCE(b.mmbeStatus, '')) NOT LIKE '%decommission%'
        OR LOWER(COALESCE(bs.mmbsDescription, '')) NOT LIKE '%decommission%'
      );
