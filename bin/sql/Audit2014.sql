
-------------------------------------------------------------------------------
--  Audit.sql
--  Script to define a SQL Server Audit and Server Audit Specification, to satisfy
--  the auditing requirements in the SQL Server 2014 STIG documents.
--
--  Throughout the file, change --AUDITNAME-- and <server audit spec name>
--  to values of your choice.
--
--  In the CREATE SERVER AUDIT statement, review all the parameters and
--  select values suited to your organization's needs.
--
--  In the ALTER SERVER AUDIT statement, which suppresses superfluous audit records,
--  be sure you understand what each condition is doing.  Modify the filtering
--  to suit your organization's needs.
--
--  In the CREATE SERVER AUDIT SPECIFICATION statement, adjust the specification
--  to meet your needs.
--
--  This script casts a wide net, using SQL Server's server-level audit groups.
--  You may find it helpful to use a database audit specification instead, to
--  give you more fine-grained control of the audit.  For example, if you
--  need Select-Insert-Update-Delete activity tracked only for a subset of tables,
--  or only for users in a certain role, a database audit can provide that.
--  You may also find that creating multiple audit definitions, rather than a
--  single, consolidated audit, provides more flexibility.
-------------------------------------------------------------------------------
--
--  This script is provided by DISA to assist administrators in ensuring SQL Server
--  deployments comply with STIG requirements.  As an administrator employing
--  this script, you are responsible for:
--  -  understanding its purpose and how it works;
--  -  determining its suitability for your situation;
--  -  verifying that it works as intended;
--  -  ensuring that there are no legal or contractual obstacles to your using it
--         (for example, if the database is acquired as part of an application
--         package, the vendor may restrict your right to modify the database).
--
--  DISA cannot accept responsibility for adverse outcomes resulting from the
--  use of this script.
--
--  Microsoft Corporation was not involved in the development of this script.
--
-------------------------------------------------------------------------------


USE [master];
GO

-------------------------------------------------------------------------------
--  IF THE AUDIT ALREADY EXISTS, DROP IT
-------------------------------------------------------------------------------

BEGIN TRY
    ALTER SERVER AUDIT --AUDITNAME--
    WITH (STATE = OFF);
END TRY BEGIN CATCH END CATCH;
GO

BEGIN TRY
    DROP SERVER AUDIT --AUDITNAME--;
END TRY BEGIN CATCH END CATCH;
GO


-------------------------------------------------------------------------------
--  DEFINE THE AUDIT
--
--  The following parameter values are examples only.
--  Assess your own situation and choose the settings accordingly.

--  If deploying this on a mirror server, include AUDIT_GUID = <guid value>
--  in the WITH clause, so that this audit has the same GUID as its equivalent
--  on the primary server.
-------------------------------------------------------------------------------

CREATE SERVER AUDIT --AUDITNAME--
TO FILE
(   FILEPATH = N'--AUDITLOCATION--',
    MAXSIZE = --AUDITMAXSIZE--, --10 MB
    MAX_FILES = --AUDITMAXFILES--, --100000
    RESERVE_DISK_SPACE = --AUDITRESERVE-- --OFF
)
WITH
(   QUEUE_DELAY = --AUDITQUEUEDELAY--, --1000
    ON_FAILURE = --AUDITONFAILURE-- --SHUTDOWN
	--  , AUDIT_GUID = '<guid value from primary server>'
)
;
GO

-------------------------------------------------------------------------------
--  ADD A FILTER TO SCREEN OUT UNNECESSARY AUDIT RECORDS
-------------------------------------------------------------------------------

ALTER SERVER AUDIT --AUDITNAME-- WITH (STATE = OFF)
GO

USE [master];
GO
ALTER SERVER AUDIT --AUDITNAME--
WHERE
--  The following line is used solely to ensure that the WHERE statement begins with a clause
--  that is guaranteed true.  This allows us to begin each subsequent line with AND, making
--  editing easier.  If you wish, you may remove this line (and the first AND).
([Statement] <> 'BBF5B619-D44A-4616-A259-CDD9D426D794')

--  The following filters out system-generated statements accessing SQL Server internal tables
--  that are not directly visible to or accessible by user processes, but which do appear among
--  log records if not suppressed.
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syspalnames')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'objects$')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syspalvalues')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'configurations$')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'system_columns$')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'server_audits$')
AND    NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'parameters$')


--  The following suppresses audit trail messages about the execution of statements within procedures
--  and functions.  This is done because it is generally not useful to trace internal operations
--  of a function or procedure, and this is a simple way to detect them.
--  However, this opens an opportunity for an adversary to obscure actions on the database,
--  so make sure that the creation and modification of functions and procedures is tracked.
--  Further, details of your application architecture may be incompatible with this technique.
--  Use with care.
AND NOT ([Additional_Information] LIKE '<tsql_stack>%')


--  The following statements filter out audit records for certain system-generated actions that
--  frequently occur, and which do not aid in tracking the activities of a user or process.
AND NOT([Schema_Name] = 'sys' AND [Statement] LIKE
        'SELECT%clmns.name%FROM%sys.all_views%sys.all_columns%sys.indexes%sys.index_columns%sys.computed_columns%sys.identity_columns%sys.objects%sys.types%sys.schemas%sys.types%'
        )
AND NOT ([Schema_Name] = 'sys' AND [Object_Name] <> 'databases' AND [Statement] LIKE
        'SELECT%dtb.name%AS%dtb.state%A%FROM%master.sys.databases%dtb'
        )
AND NOT ([Schema_Name] = 'sys' AND [Object_Name] <> 'databases' AND [Statement] LIKE
        '%SELECT%clmns.column_id%,%clmns.name%,%clmns.is_nullable%,%CAST%ISNULL%FROM%sys.all_views%AS%v%INNER%JOIN%sys.all_columns%AS%clmns%ON%clmns.object_id%v.object_id%LEFT%OUTER%JOIN%sys.indexes%AS%ik%ON%ik.object_id%clmns.object_id%and%1%ik.is_primary_key%'
        )


--  Numerous log records are generated when the SQL Server Management Studio Log Viewer itself is
--  populated or refreshed.  The following filters out the less useful of these, while not hiding the
--  fact that metadata about the log was accessed.
AND NOT ([Schema_Name] = 'sys' AND [Statement] LIKE
        'SELECT%dtb.name AS%,%dtb.database_id AS%,%CAST(has_dbaccess(dtb.name) AS bit) AS%FROM%master.sys.databases AS dtb%ORDER BY%ASC'
        )
AND NOT ([Schema_Name] = 'sys' AND [Statement] LIKE
        'SELECT%dtb.collation_name AS%,%dtb.name AS%FROM%master.sys.databases AS dtb%WHERE%'
        )


--  If activated, the following filters out system-generated statements, should they occur, accessing
--  additional SQL Server internal tables that are not directly visible to or accessible by user processes
--  (even by administrators).  Enable each line, as needed, to add it to the filter.
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysschobjs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysbinobjs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysclsobjs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysnsobjs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syscolpars')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'systypedsubobjs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysidxstats')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysiscols')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysscalartypes')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysdbreg')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxsrvs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysrmtlgns')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syslnklgns')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxlgns')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysdbfiles')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysusermsg')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysprivs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysowners')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysobjkeycrypts')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syscerts')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysasymkeys')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'ftinds')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxprops')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysallocunits')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysrowsets')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysrowsetrefs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syslogshippers')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysremsvcbinds')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysconvgroup')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxmitqueue')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysdesend')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysdercv')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysendpts')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syswebmethods')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysqnames')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxmlcomponent')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxmlfacet')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysxmlplacement')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'syssingleobjrefs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysmultiobjrefs')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysobjvalues')
--  AND NOT ([Schema_Name] = 'sys' AND [Object_Name] = 'sysguidrefs')
;
GO

-------------------------------------------------------------------------------
--  ENABLE THE AUDIT
-------------------------------------------------------------------------------

ALTER SERVER AUDIT --AUDITNAME-- WITH (STATE = ON);
GO



-------------------------------------------------------------------------------
--  IF THE SERVER AUDIT SPECIFICATION ALREADY EXISTS, DROP IT
-------------------------------------------------------------------------------

USE [master];
GO

BEGIN TRY
    ALTER SERVER AUDIT SPECIFICATION <server audit spec name>
    WITH (STATE = OFF);
END TRY BEGIN CATCH END CATCH;
GO

BEGIN TRY
    DROP SERVER AUDIT SPECIFICATION <server audit spec name>;
END TRY BEGIN CATCH END CATCH;
GO


-------------------------------------------------------------------------------
--  ESTABLISH THE SERVER AUDIT SPECIFICATION
--
--  This server audit specification casts a wide net, including most of the
--  available server-level audit action groups.
--  The action groups that are not included here are:
--  - broker_login_group,
--  - database_mirroring_login_group,
--  - fulltext_group
--  - user_defined_audit_group
--  - database_logout_group
--  - failed_database_authentication_group
--  - successful_database_authentication_group
--  - user_change_password_group
--  Adjust the specification to suit your circumstances.
-------------------------------------------------------------------------------

CREATE SERVER AUDIT SPECIFICATION <server audit spec name>
    FOR SERVER AUDIT --AUDITNAME--
    WITH (STATE = OFF);
GO

ALTER SERVER AUDIT SPECIFICATION <server audit spec name>
    ADD (APPLICATION_ROLE_CHANGE_PASSWORD_GROUP),   --  Replaces Trace Event 112  Audit App Role Change Password Event
    ADD (AUDIT_CHANGE_GROUP),                       --  Replaces Trace Event 117: Audit Change Audit Event
    ADD (BACKUP_RESTORE_GROUP),                     --  Replaces Trace Event 115: Audit Backup/Restore Event
    ADD (DATABASE_CHANGE_GROUP),                    --  Replaces Trace Event 128: Audit Database Management Event
    ADD (DATABASE_OBJECT_ACCESS_GROUP),             --  Comparable to Trace Event 180
    ADD (DATABASE_OBJECT_CHANGE_GROUP),             --  Replaces Trace Event 129: Audit Database Object Management Event
    ADD (DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP),   --  Replaces Trace Event 135: Audit Database Object Take Ownership Event
    ADD (DATABASE_OBJECT_PERMISSION_CHANGE_GROUP),  --  Replaces Trace Event 172: Audit Database Object GDR Event
    ADD (DATABASE_OPERATION_GROUP),                 --  Replaces Trace Event 178: Audit Database Operation Event
    ADD (DATABASE_OWNERSHIP_CHANGE_GROUP),          --  Replaces Trace Event 152: Audit Change Database Owner
    ADD (DATABASE_PERMISSION_CHANGE_GROUP),         --  Replaces Trace Event 102: Audit Database Scope GDR Event
    ADD (DATABASE_PRINCIPAL_CHANGE_GROUP),          --  Replaces Trace Event 109: Audit Add DB User Event
                                                    --                       111: Audit Add Role Event
                                                    --                       130: Audit Database Principal Management Event
    ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP),   --  Replaces Trace Event 133: Audit Database Principal Impersonation Event
    ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP),        --  Replaces Trace Event 110: Audit Add Member to DB Role Event
    ADD (DBCC_GROUP),                               --  Replaces Trace Event 116: Audit DBCC Event
    ADD (FAILED_LOGIN_GROUP),                       --  Replaces Trace Event  20: Audit Login Failed
    ADD (LOGIN_CHANGE_PASSWORD_GROUP),              --  Replaces Trace Event 107: Audit Login Change Password Event
    ADD (LOGOUT_GROUP),                             --  Replaces Trace Event  15: Audit Logout
    ADD (SCHEMA_OBJECT_ACCESS_GROUP),               --  No direct equivalent in Trace
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),               --  Replaces Trace Event 118: Audit Object Derived Permission Event
                                                    --                       131: Audit Schema Object Management Event
                                                    --                       113: Audit Statement Permission Event
    ADD (SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP),     --  Replaces Trace Event 153: Audit Schema Object Take Ownership Event
    ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP),    --  Replaces Trace Event 103: Audit Schema Object GDR Event
    ADD (SERVER_OBJECT_CHANGE_GROUP),               --  Replaces Trace Event 176: Audit Server Object Management Event
    ADD (SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP),     --  Replaces Trace Event 134: Audit Server Object Take Ownership Event
    ADD (SERVER_OBJECT_PERMISSION_CHANGE_GROUP),    --  Replaces Trace Event 171: Audit Server Object GDR Event
    ADD (SERVER_OPERATION_GROUP),                   --  Replaces Trace Event 173: Audit Server Operation Event
    ADD (SERVER_PERMISSION_CHANGE_GROUP),           --  Replaces Trace Event 170: Audit Server Scope GDR Event
    ADD (SERVER_PRINCIPAL_CHANGE_GROUP),            --  Replaces Trace Event 104: Audit Addlogin Event
    ADD (SERVER_PRINCIPAL_IMPERSONATION_GROUP),     --  Replaces Trace Event 132: Audit Server Principal Impersonation Event
    ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),          --  Replaces Trace Event 108: Audit Add Login to Server Role Event
    ADD (SERVER_STATE_CHANGE_GROUP),                --  Replaces Trace Event  18: Audit Server Starts And Stops
    ADD (SUCCESSFUL_LOGIN_GROUP),                   --  Replaces Trace Event  14: Audit Login
    ADD (TRACE_CHANGE_GROUP)                        --  Replaces Trace Event 175: Audit Server Alter Trace Event
;
GO

-------------------------------------------------------------------------------
--  ENABLE THE SERVER AUDIT SPECIFICATION
-------------------------------------------------------------------------------

ALTER SERVER AUDIT SPECIFICATION <server audit spec name>
    WITH (STATE = ON)
;
GO
