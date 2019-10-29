
-------------------------------------------------------------------------------
--  DynamicExec.sql
--  Script to identify cases of dynamic code execution in sql.
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
SELECT sm.object_id, OBJECT_NAME(sm.object_id), o.type, o.type_desc, sm.definition
FROM sys.sql_modules sm
JOIN sys.objects o on sm.object_id = o.object_id
WHERE (UPPER(definition) like '%SP_EXECUTESQL%'
OR replace(UPPER(definition), ' ', '') like '%EXEC(%'
OR replace(UPPER(definition), ' ', '') like '%EXECUTE(%')
AND UPPER(definition) NOT like '%EXECUTE AS%';