-- Query: Break down available, not-decommissioned berths by berth type
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

SELECT
    COALESCE(bt.mmbtBerthType, 'Unspecified') AS BerthType,
    COUNT(*) AS AvailableBerths
FROM dbo.tmmBerth b
LEFT JOIN dbo.tmmBerthType bt ON b.mmbeTypePtr = bt.mmbtID
LEFT JOIN dbo.tmmBerthStatus bs ON b.mmbeStatusPtr = bs.mmbsID
WHERE b.mmbeActive = 1
  AND b.mmbeDecommissionedDate IS NULL
  AND (
        LOWER(COALESCE(b.mmbeStatus, '')) NOT LIKE '%decommission%'
        OR LOWER(COALESCE(bs.mmbsDescription, '')) NOT LIKE '%decommission%'
      )
GROUP BY COALESCE(bt.mmbtBerthType, 'Unspecified')
ORDER BY AvailableBerths DESC, BerthType;
