USE [master]
GO

SELECT  *
FROM 
(
    SELECT
        CAST(SERVERPROPERTY('InstanceDefaultDataPath') AS nvarchar(260)) AS DirectoryName,
        'Data' AS DirectoryType
    UNION ALL
    SELECT
        CAST(SERVERPROPERTY('InstanceDefaultLogPath') AS nvarchar(260)),
        'Log' AS DirectoryType
    UNION ALL
    SELECT DISTINCT
        LEFT(physical_name, (LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name)))),
        CASE type
            WHEN 0 THEN 'Data'
            WHEN 1 THEN 'Log'
            ELSE 'Other'
        END
    FROM sys.master_files
    UNION ALL
    SELECT DISTINCT
        LEFT(physical_device_name, (LEN(physical_device_name) - CHARINDEX('\', REVERSE(physical_device_name)))),
        'Backup'
    FROM msdb.dbo.backupmediafamily
    WHERE device_type IN (2, 9, NULL)
) A
ORDER BY
    DirectoryType,
    DirectoryName
    