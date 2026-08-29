-- Query: Berth Occupancy and Rental Agreements from 2025 up to Today (2026-08-29)
-- Database: Pacsoft NG (MMS_WH_P)
-- Mode: READ-ONLY

--------------------------------------------------------------------------------
-- SECTION 1: Monthly Berth Occupancy Summary (ngOccupancyBase)
--------------------------------------------------------------------------------
SELECT 
    FORMAT(ob.[Date], 'yyyy-MM') AS YearMonth,
    COUNT(DISTINCT ob.BerthID) AS TotalBerthsTracked,
    SUM(CASE WHEN ob.Avaliable = 0 OR ob.Status IN ('Rented', 'Booked') THEN 1 ELSE 0 END) AS OccupiedDays,
    SUM(CASE WHEN ob.Avaliable = 1 OR ob.Status IS NULL THEN 1 ELSE 0 END) AS AvailableDays,
    COUNT(*) AS TotalDaysTracked,
    ROUND(100.0 * SUM(CASE WHEN ob.Avaliable = 0 OR ob.Status IN ('Rented', 'Booked') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS OccupancyRatePercentage
FROM dbo.ngOccupancyBase ob
WHERE ob.[Date] >= '2025-01-01' AND ob.[Date] <= '2026-08-29'
GROUP BY FORMAT(ob.[Date], 'yyyy-MM')
ORDER BY YearMonth;

--------------------------------------------------------------------------------
-- SECTION 2: Active & Overlapping Rental Lease Agreements (2025 - Present)
--------------------------------------------------------------------------------
SELECT 
    ra.mmraID AS RentalAgreementID,
    ra.mmraMarinaPtr AS MarinaID,
    m.mmmaMarinaName AS MarinaName,
    c.mmcuID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    ra.mmraRentalProductPtr AS RentalProductCode,
    ra.mmraRentalPeriodFrom AS PeriodFrom,
    ra.mmraRentalPeriodTo AS PeriodTo,
    ra.mmraStartDate AS ContractStartDate,
    ra.mmraEndDate AS ContractEndDate,
    ra.mmraActive AS IsActive
FROM dbo.tmmRentalAgreement ra
LEFT JOIN dbo.tmmCustomer c ON ra.mmraCustomerPtr = c.mmcuID
LEFT JOIN dbo.tmmMarina m ON ra.mmraMarinaPtr = m.mmmaID
WHERE (ra.mmraRentalPeriodFrom <= '2026-08-29' OR ra.mmraStartDate <= '2026-08-29')
  AND (ra.mmraRentalPeriodTo >= '2025-01-01' OR ra.mmraEndDate >= '2025-01-01' OR ra.mmraRentalPeriodTo IS NULL)
ORDER BY ra.mmraRentalPeriodFrom DESC;
