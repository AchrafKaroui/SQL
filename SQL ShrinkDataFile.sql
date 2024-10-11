DECLARE @FileName sysname = N'DBName_Data'
DECLARE @TargetSize INT = (SELECT 1 + size*8./1024 FROM sys.database_files WHERE name = @FileName)
DECLARE @Factor FLOAT = .99
WHILE @TargetSize > 0
BEGIN
SET @TargetSize *= @Factor
DBCC SHRINKFILE(@FileName, @TargetSize);
DECLARE @msg VARCHAR(200) = CONCAT('Shrink file completed. Target Size: ',
@TargetSize, ' MB. Timestamp: ', CURRENT_TIMESTAMP)
RAISERROR(@msg, 1, 1) WITH NOWAIT
WAITFOR DELAY '00:00:01'
END