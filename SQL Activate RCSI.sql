SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

DECLARE @dbName sysname;
DECLARE @cmd NVARCHAR(MAX)
DECLARE @id INT =
        (
            SELECT MIN(database_id)
            FROM sys.databases
            WHERE database_id > 4
                  AND is_read_committed_snapshot_on = 0
                  AND state = 0 -- Database is online
                  AND is_read_only = 0 -- Database is not read-only
        )

PRINT '--- Starting RCSI Enabling Process ---'

WHILE @id IS NOT NULL
BEGIN
    SET @dbName =
    (
        SELECT name FROM sys.databases WHERE database_id = @id
    )

    SET @cmd = N'ALTER DATABASE [' + @dbName + N'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;'
    SET @cmd += N'ALTER DATABASE [' + @dbName + N'] SET READ_COMMITTED_SNAPSHOT ON;'
    SET @cmd += N'ALTER DATABASE [' + @dbName + N'] SET MULTI_USER;'
    BEGIN TRY
        EXEC sp_executesql @cmd
        PRINT 'RCSI enabled for database: ' + @dbName
    END TRY
    BEGIN CATCH
        PRINT 'Failed to enable RCSI for database: ' + @dbName
        PRINT 'Error: ' + ERROR_MESSAGE();
        PRINT 'Setting MULTI_USER mode for database: ' + @dbName
        SET @cmd = N'ALTER DATABASE [' + @dbName + N'] SET MULTI_USER WITH ROLLBACK IMMEDIATE;'
        EXEC sp_executesql @cmd
        PRINT 'MULTI_USER mode set for database: ' + @dbName
    END CATCH

    -- Move to the next database
    SET @id =
    (
        SELECT MIN(database_id)
        FROM sys.databases
        WHERE database_id > @id
              AND database_id > 4
              AND is_read_committed_snapshot_on = 0
              AND state = 0 -- Database is online
              AND is_read_only = 0 -- Database is not read-only
    )
END

PRINT '--- RCSI Enabling Process Completed ---'
PRINT '--- RUN VERIFY SCRIPT TO CHECK DBS ARE MULTI_USER ---'