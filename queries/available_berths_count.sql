-- Query: Customer activity with current berth, account details, and invoice status
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

WITH CustomerBase AS (
    SELECT
        c.mmcuID AS CustomerID,
        c.mmcuAccountCode AS AccountCode,
        COALESCE(
            c.mmcuLongName,
            TRIM(
                CONCAT(
                    COALESCE(c.mmcuFirstName, ''),
                    CASE WHEN COALESCE(c.mmcuFirstName, '') <> '' AND COALESCE(c.mmcuSurname, '') <> '' THEN ' ' ELSE '' END,
                    COALESCE(c.mmcuSurname, '')
                )
            ),
            'Unknown Customer'
        ) AS CustomerName,
        c.mmcuEmail AS CustomerEmail,
        c.mmcuBusPhoneNo AS BusinessPhone,
        c.mmcuMobileNo AS MobilePhone
    FROM dbo.tmmCustomer c
),
Activity AS (
    SELECT
        sh.shCustomerID,
        MIN(sh.shPeriodFrom) AS FirstActivityDate,
        MAX(sh.shPeriodTo) AS LastActivityDate,
        MAX(sh.shLastInvoiceDate) AS ServiceHeaderLastInvoiceDate,
        MAX(CASE WHEN sh.shDoNotInvoice = 1 THEN 1 ELSE 0 END) AS DoNotInvoice
    FROM dbo.ngServiceHeader sh
    WHERE sh.shPeriodTo >= DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0)
      AND sh.shPeriodFrom < DATEADD(day, 1, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))
    GROUP BY sh.shCustomerID
),
LastInvoice AS (
    SELECT
        th.mmthCustomerPtr AS CustomerID,
        MAX(th.mmthTransactionDate) AS LastInvoiceDate
    FROM dbo.tmmTransactionHeader th
    WHERE th.mmthTransactionDate >= DATEADD(month, DATEDIFF(month, 0, GETDATE()) - 1, 0)
      AND th.mmthTransactionDate < DATEADD(day, 1, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))
    GROUP BY th.mmthCustomerPtr
),
CurrentCustomerBerth AS (
    SELECT
        CustomerID,
        BerthNumber,
        BerthType,
        BerthStatus,
        AgreementType,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY IsOwnership DESC, StartDate DESC, AgreementID DESC
        ) AS rn
    FROM (
        SELECT
            oa.mmoaCustomerPtr AS CustomerID,
            b.mmbeName AS BerthNumber,
            COALESCE(bt.mmbtBerthType, 'Unspecified') AS BerthType,
            COALESCE(bs.mmbsDescription, b.mmbeStatus, 'Unknown') AS BerthStatus,
            'Ownership' AS AgreementType,
            1 AS IsOwnership,
            oa.mmoaStartDate AS StartDate,
            oa.mmoaID AS AgreementID
        FROM dbo.tmmOwnershipAgreement oa
        LEFT JOIN dbo.tmmBerth b
            ON oa.mmoaBerthPtr = b.mmbeID
        LEFT JOIN dbo.tmmBerthType bt
            ON b.mmbeTypePtr = bt.mmbtID
        LEFT JOIN dbo.tmmBerthStatus bs
            ON b.mmbeStatusPtr = bs.mmbsID
        WHERE oa.mmoaActive = 1

        UNION ALL

        SELECT
            b.mmbeOwnerPtr AS CustomerID,
            b.mmbeName AS BerthNumber,
            COALESCE(bt.mmbtBerthType, 'Unspecified') AS BerthType,
            COALESCE(bs.mmbsDescription, b.mmbeStatus, 'Unknown') AS BerthStatus,
            'Direct Owner' AS AgreementType,
            1 AS IsOwnership,
            NULL AS StartDate,
            NULL AS AgreementID
        FROM dbo.tmmBerth b
        LEFT JOIN dbo.tmmBerthType bt
            ON b.mmbeTypePtr = bt.mmbtID
        LEFT JOIN dbo.tmmBerthStatus bs
            ON b.mmbeStatusPtr = bs.mmbsID
        WHERE b.mmbeOwnerPtr IS NOT NULL
          AND b.mmbeActive = 1

        UNION ALL

        SELECT
            ra.mmraCustomerPtr AS CustomerID,
            b.mmbeName AS BerthNumber,
            COALESCE(bt.mmbtBerthType, 'Unspecified') AS BerthType,
            COALESCE(bs.mmbsDescription, b.mmbeStatus, 'Unknown') AS BerthStatus,
            'Rental' AS AgreementType,
            0 AS IsOwnership,
            ra.mmraRentalPeriodFrom AS StartDate,
            ra.mmraID AS AgreementID
        FROM dbo.tmmRentalAgreement ra
        LEFT JOIN dbo.tmmRentalLink rl
            ON rl.mmrlRentalAgreementPtr = ra.mmraID
        LEFT JOIN dbo.tmmRentalManagement rm
            ON rm.mmrmID = rl.mmrlRentalManagementPtr
           AND rm.mmrmActive = 1
        LEFT JOIN dbo.tmmBerth b
            ON rm.mmrmBerthPtr = b.mmbeID
        LEFT JOIN dbo.tmmBerthType bt
            ON b.mmbeTypePtr = bt.mmbtID
        LEFT JOIN dbo.tmmBerthStatus bs
            ON b.mmbeStatusPtr = bs.mmbsID
        WHERE ra.mmraActive = 1
    ) q
)
SELECT
    cb.CustomerID,
    cb.AccountCode,
    cb.CustomerName,
    cberth.BerthNumber,
    cberth.BerthType,
    cberth.BerthStatus,
    cberth.AgreementType,
    a.FirstActivityDate,
    a.LastActivityDate,
    a.ServiceHeaderLastInvoiceDate,
    li.LastInvoiceDate AS TransactionLastInvoiceDate,
    CASE
        WHEN li.LastInvoiceDate IS NULL THEN 'NOT INVOICED THIS MONTH'
        ELSE 'INVOICED'
    END AS InvoiceStatus,
    CASE
        WHEN a.DoNotInvoice = 1 THEN 'DO NOT INVOICE'
        ELSE 'OK TO INVOICE'
    END AS InvoiceFlag,
    cb.CustomerEmail,
    cb.BusinessPhone,
    cb.MobilePhone
FROM CustomerBase cb
LEFT JOIN Activity a
    ON a.shCustomerID = cb.CustomerID
LEFT JOIN CurrentCustomerBerth cberth
    ON cberth.CustomerID = cb.CustomerID
   AND cberth.rn = 1
LEFT JOIN LastInvoice li
    ON li.CustomerID = cb.CustomerID
ORDER BY cb.CustomerID;
