USE [master];
GO

/****************************************/
/* Set variables needed by setup script */
DECLARE	@auditName varchar(25), @auditPath varchar(260), @auditGuid uniqueidentifier, @auditFileSize varchar(4), @auditFileCount varchar(4)

-- Define the name of the audit
SET @auditName = '--AUDITNAME--'

-- Define the directory in which audit log files reside
SET @auditPath = '--AUDITLOCATION--'

-- Define the unique identifier for the audit
SET @auditGuid = NEWID()

-- Define the maximum size for a single audit file (MB)
SET @auditFileSize = '--AUDITMAXSIZE--'

-- Define the number of files that should be kept online
-- Use -1 for unlimited
SET @auditFileCount = '--AUDITMAXFILES--'

/****************************************/

/* Insert the variables into a temp table so they survive for the duration of the script */
CREATE TABLE #SetupVars
(
	Variable	varchar(50),
	Value		varchar(260)
)
INSERT	INTO #SetupVars (Variable, Value)
		VALUES	('auditName', @auditName),
				('auditPath', @auditPath),
				('auditGuid', convert(varchar(40), @auditGuid)),
				('auditFileSize', @auditFileSize),
				('auditFileCount', @auditFileCount)

/****************************************/
/* Delete the audit if is currently exists */
/****************************************/

USE [master];
GO

-- Disable the Server Audit Specification
DECLARE	@auditName varchar(25), @disableSpecification nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@disableSpecification = '
IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N''' + @auditName + '_SERVER_SPECIFICATION'')
ALTER SERVER AUDIT SPECIFICATION [' + @auditName + '_SERVER_SPECIFICATION] WITH (STATE = OFF);'
EXEC(@disableSpecification)
GO

-- Drop the Server Audit Specification
DECLARE	@auditName varchar(25), @dropSpecification nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@dropSpecification = '
IF EXISTS (SELECT 1 FROM sys.server_audit_specifications WHERE name = N''' + @auditName + '_SERVER_SPECIFICATION'')
DROP SERVER AUDIT SPECIFICATION [' + @auditName + '_SERVER_SPECIFICATION];'
EXEC(@dropSpecification)
GO

-- Disable the Server Audit
DECLARE	@auditName varchar(25), @disableAudit nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@disableAudit = '
IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N''' + @auditName + ''')
ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = OFF);'
EXEC(@disableAudit)
GO

-- Drop the Server Audit
DECLARE	@auditName varchar(25), @dropAudit nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@dropAudit = '
IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N''' + @auditName + ''')
DROP SERVER AUDIT [' + @auditName + '];'
EXEC(@dropAudit)
GO

/****************************************/
/* Set up the SQL Server Audit          */
/****************************************/

USE [master];
GO

/* Create the Server Audit */
DECLARE	@auditName varchar(25), @auditPath varchar(260), @auditGuid varchar(40), @auditFileSize varchar(4), @auditFileCount varchar(5)

SELECT @auditName = Value FROM #SetupVars WHERE Variable = 'auditName'
SELECT @auditPath = Value FROM #SetupVars WHERE Variable = 'auditPath'
SELECT @auditGuid = Value FROM #SetupVars WHERE Variable = 'auditGuid'
SELECT @auditFileSize = Value FROM #SetupVars WHERE Variable = 'auditFileSize'
SELECT @auditFileCount = Value FROM #SetupVars WHERE Variable = 'auditFileCount'

DECLARE @createStatement	nvarchar(max)
SET		@createStatement = '
CREATE SERVER AUDIT [' + @auditName + ']
TO FILE
(
	FILEPATH = ''' + @auditPath + '''
	, MAXSIZE = --AUDITMAXSIZE-- MB
	, MAX_ROLLOVER_FILES = ' + CASE WHEN @auditFileCount = -1 THEN 'UNLIMITED' ELSE @auditFileCount END + '
	, RESERVE_DISK_SPACE = --AUDITRESERVE--
)
WITH
(
	QUEUE_DELAY = --AUDITQUEUEDELAY--
	, ON_FAILURE = --AUDITONFAILURE--
	, AUDIT_GUID = ''' + @auditGuid + '''
)
'

EXEC(@createStatement)
GO

/* Turn on the Audit */
DECLARE	@auditName varchar(25), @enableAudit nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@enableAudit = '
IF EXISTS (SELECT 1 FROM sys.server_audits WHERE name = N''' + @auditName + ''')
ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = ON);'
EXEC(@enableAudit)
GO

/* Create the server audit specifications */
DECLARE	@auditName varchar(25), @createSpecification nvarchar(max)
SET		@auditName = (SELECT Value FROM #SetupVars WHERE Variable = 'auditName')
SET		@createSpecification = '
CREATE SERVER AUDIT SPECIFICATION [' + @auditName + '_SERVER_SPECIFICATION]
FOR SERVER AUDIT [' + @auditName + ']
	ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP),     -- V-79239, V-79291, V-79293, V-79295
	ADD (AUDIT_CHANGE_GROUP),                         -- V-79239, V-79291, V-79293, V-79295
	ADD (BACKUP_RESTORE_GROUP),                       -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_CHANGE_GROUP),                      -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_OBJECT_ACCESS_GROUP),               -- V-79239
	ADD (DATABASE_OBJECT_CHANGE_GROUP),               -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),     -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),    -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (DATABASE_OPERATION_GROUP),                   -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),            -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (DATABASE_PERMISSION_CHANGE_GROUP),           -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),            -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP),     -- V-79239, V-79291, V-79293, V-79295
	ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),          -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (DBCC_GROUP),                                 -- V-79239, V-79291, V-79293, V-79295
	ADD (FAILED_LOGIN_GROUP),                         -- V-79289
	ADD (LOGIN_CHANGE_PASSWORD_GROUP),                -- V-79239, V-79291, V-79293, V-79295
	ADD (LOGOUT_GROUP),                               -- V-79295

	-- The SCHEMA_OBJECT_ACCESS_GROUP is intentionally commented out. Refer to the findings listed to the right before including this event.
	-- ADD (SCHEMA_OBJECT_ACCESS_GROUP),              -- V-79137, V-79139, V-79251, V-79253, V-79255, V-79257, V-79271, V-79273, V-79283, V-79285, V-79299, V-79301

	ADD (SCHEMA_OBJECT_CHANGE_GROUP),                 -- V-79239, V-79267, V-79269, V-79279, V-79281, V-79291, V-79293, V-79295
	ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),       -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),      -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SERVER_OBJECT_CHANGE_GROUP),                 -- V-79239, V-79291, V-79293, V-79295
	ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP),       -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),      -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SERVER_OPERATION_GROUP),                     -- V-79239, V-79291, V-79293, V-79295
	ADD (SERVER_PERMISSION_CHANGE_GROUP),             -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SERVER_PRINCIPAL_CHANGE_GROUP),              -- V-79291, V-79293, V-79295
	ADD (SERVER_PRINCIPAL_IMPERSONATION_GROUP),       -- V-79239, V-79291, V-79293, V-79295
	ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),            -- V-58071, V-58073
	ADD (SERVER_STATE_CHANGE_GROUP),                  -- V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
	ADD (SUCCESSFUL_LOGIN_GROUP),                     -- V-79287, V-79297
	ADD (TRACE_CHANGE_GROUP),                         -- V-79239, V-79291, V-79293, V-79295
	ADD (USER_CHANGE_PASSWORD_GROUP)                  -- V-79291, V-79293, V-79295
WITH (STATE = ON);'
EXEC(@createSpecification)
GO

/* Clean up */
DROP TABLE #SetupVars