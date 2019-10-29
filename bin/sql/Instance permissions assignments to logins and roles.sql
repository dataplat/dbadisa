-- Associated Findings
--     V-79125

/* Get all permission assignments to logins and roles */
SELECT DISTINCT
    CASE
        WHEN SP.class_desc IS NOT NULL THEN 
            CASE
                WHEN SP.class_desc = 'SERVER' AND S.is_linked = 0 THEN 'SERVER'
                WHEN SP.class_desc = 'SERVER' AND S.is_linked = 1 THEN 'SERVER (linked)'
                ELSE SP.class_desc
            END
        WHEN E.name IS NOT NULL THEN 'ENDPOINT'
        WHEN S.name IS NOT NULL AND S.is_linked = 0 THEN 'SERVER'
        WHEN S.name IS NOT NULL AND S.is_linked = 1 THEN 'SERVER (linked)'
        WHEN P.name IS NOT NULL THEN 'SERVER_PRINCIPAL'
        ELSE '???' 
    END                    AS [Securable Class],
    CASE
        WHEN E.name IS NOT NULL THEN E.name
        WHEN S.name IS NOT NULL THEN S.name 
        WHEN P.name IS NOT NULL THEN P.name
        ELSE '???' 
    END                    AS [Securable],
    P1.name                AS [Grantee],
    P1.type_desc           AS [Grantee Type],
    sp.permission_name     AS [Permission],
    sp.state_desc          AS [State],
    P2.name                AS [Grantor],
    P2.type_desc           AS [Grantor Type]
FROM
    sys.server_permissions SP
    INNER JOIN sys.server_principals P1
        ON P1.principal_id = SP.grantee_principal_id
    INNER JOIN sys.server_principals P2
        ON P2.principal_id = SP.grantor_principal_id

    FULL OUTER JOIN sys.servers S
        ON  SP.class_desc = 'SERVER'
        AND S.server_id = SP.major_id

    FULL OUTER JOIN sys.endpoints E
        ON  SP.class_desc = 'ENDPOINT'
        AND E.endpoint_id = SP.major_id

    FULL OUTER JOIN sys.server_principals P
        ON  SP.class_desc = 'SERVER_PRINCIPAL'        
        AND P.principal_id = SP.major_id
/* End Get all permission assignments to logins and roles */

/* Get all server role memberships */
SELECT
    R.name    AS [Role],
    M.name    AS [Member]
FROM
    sys.server_role_members X
    INNER JOIN sys.server_principals R ON R.principal_id = X.role_principal_id
    INNER JOIN sys.server_principals M ON M.principal_id = X.member_principal_id
/* EndGet all server role memberships */