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
)
SELECT
    a.shCustomerID AS CustomerID,
    c.mmcuAccountCode AS AccountCode,
    ISNULL(c.mmcuLongName, ISNULL(c.mmcuFirstName + ' ' + c.mmcuSurname, c.mmcuSurname)) AS CustomerName,
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
LEFT JOIN LastInvoice li
    ON a.shCustomerID = li.CustomerID
ORDER BY a.shCustomerID;
