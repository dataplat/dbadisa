function Get-DbsDbExecuteAs {
    <#
    .SYNOPSIS
        Gets a list of stored procedures and functions that utilize impersonation (EXECUTE AS)

    .DESCRIPTION
        Gets a list of stored procedures and functions that utilize impersonation (EXECUTE AS)

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79107
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbExecuteAs -SqlInstance sql2017, sql2016, sql2012

        Gets a list of stored procedures and functions that utilize impersonation (EXECUTE AS) for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbExecuteAs -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\contained.csv -NoTypeInformation

        Exports a list of stored procedures and functions that utilize impersonation for all databases on sql2017, sql2016 and sql2012 to D:\disa\contained.csv
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $databases = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential -MinimumVersion 12 | Get-DbaDatabase
        foreach ($db in $databases) {
            try {
                $results = $db.Query("SELECT S.name AS schema_name, O.name AS module_name,
                USER_NAME(
                CASE M.execute_as_principal_id
                WHEN -2 THEN COALESCE(O.principal_id, S.principal_id)
                ELSE M.execute_as_principal_id
                END
                ) AS execute_as
                FROM sys.sql_modules M
                JOIN sys.objects O ON M.object_id = O.object_id
                JOIN sys.schemas S ON O.schema_id = S.schema_id
                WHERE execute_as_principal_id IS NOT NULL
                and o.name not in
                (
                'fn_sysdac_get_username',
                'fn_sysutility_ucp_get_instance_is_mi',
                'sp_send_dbmail',
                'sp_SendMailMessage',
                'sp_syscollector_create_collection_set',
                'sp_syscollector_delete_collection_set',
                'sp_syscollector_disable_collector',
                'sp_syscollector_enable_collector',
                'sp_syscollector_get_collection_set_execution_status',
                'sp_syscollector_run_collection_set',
                'sp_syscollector_start_collection_set',
                'sp_syscollector_update_collection_set',
                'sp_syscollector_upload_collection_set',
                'sp_syscollector_verify_collector_state',
                'sp_syspolicy_add_policy',
                'sp_syspolicy_add_policy_category_subscription',
                'sp_syspolicy_delete_policy',
                'sp_syspolicy_delete_policy_category_subscription',
                'sp_syspolicy_update_policy',
                'sp_sysutility_mi_add_ucp_registration',
                'sp_sysutility_mi_disable_collection',
                'sp_sysutility_mi_enroll',
                'sp_sysutility_mi_initialize_collection',
                'sp_sysutility_mi_remove',
                'sp_sysutility_mi_remove_ucp_registration',
                'sp_sysutility_mi_upload',
                'sp_sysutility_mi_validate_enrollment_preconditions',
                'sp_sysutility_ucp_add_mi',
                'sp_sysutility_ucp_add_policy',
                'sp_sysutility_ucp_calculate_aggregated_dac_health',
                'sp_sysutility_ucp_calculate_aggregated_mi_health',
                'sp_sysutility_ucp_calculate_computer_health',
                'sp_sysutility_ucp_calculate_dac_file_space_health',
                'sp_sysutility_ucp_calculate_dac_health',
                'sp_sysutility_ucp_calculate_filegroups_with_policy_violations',
                'sp_sysutility_ucp_calculate_health',
                'sp_sysutility_ucp_calculate_mi_file_space_health',
                'sp_sysutility_ucp_calculate_mi_health',
                'sp_sysutility_ucp_configure_policies',
                'sp_sysutility_ucp_create',
                'sp_sysutility_ucp_delete_policy',
                'sp_sysutility_ucp_delete_policy_history',
                'sp_sysutility_ucp_get_policy_violations',
                'sp_sysutility_ucp_initialize',
                'sp_sysutility_ucp_initialize_mdw',
                'sp_sysutility_ucp_remove_mi',
                'sp_sysutility_ucp_update_policy',
                'sp_sysutility_ucp_update_utility_configuration',
                'sp_sysutility_ucp_validate_prerequisites',
                'sp_validate_user',
                'syscollector_collection_set_is_running_update_trigger',
                'sysmail_help_status_sp'
                )
                ORDER BY schema_name, module_name")
            } catch {
                Stop-Function -Message "Failure for $($db.Name) on $($db.Parent.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
            }
            foreach ($result in $results) {
                [pscustomobject]@{
                    SqlInstance = $db.Parent.Name
                    Database    = $db.Name
                    Name        = $results.module_name
                    SchemaName  = $results.schema_name
                    UserName    = $results.execute_as
                }
            }
        }
    }
}