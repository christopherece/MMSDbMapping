-- Query: Check which customers had activity this month and whether they were invoiced
-- Database: Pacsoft NG (MMS_WH_P)
-- Environment: READ-ONLY

WITH Activity AS (
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
CustomerBerth AS (
    SELECT
        oa.mmoaCustomerPtr AS CustomerID,
        b.mmbeName AS BerthNumber,
        ROW_NUMBER() OVER (
            PARTITION BY oa.mmoaCustomerPtr
            ORDER BY oa.mmoaStartDate DESC, oa.mmoaID DESC
        ) AS rn
    FROM dbo.tmmOwnershipAgreement oa
    LEFT JOIN dbo.tmmBerth b
        ON oa.mmoaBerthPtr = b.mmbeID
    WHERE oa.mmoaActive = 1
)
SELECT
    a.shCustomerID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
    cb.BerthNumber,
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
    END AS InvoiceFlag
FROM Activity a
LEFT JOIN dbo.tmmCustomer c
    ON a.shCustomerID = c.mmcuID
LEFT JOIN CustomerBerth cb
    ON cb.CustomerID = a.shCustomerID
   AND cb.rn = 1
LEFT JOIN LastInvoice li
    ON a.shCustomerID = li.CustomerID
ORDER BY a.shCustomerID;
