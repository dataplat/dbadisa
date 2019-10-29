-- Associated Findings
--     V-79065

 /* Get all permission assignments to users and roles */
SELECT DISTINCT
    CASE
        WHEN DP.class_desc = 'OBJECT_OR_COLUMN'             THEN CASE WHEN DP.minor_id > 0 THEN 'COLUMN' ELSE OB.type_desc END
        WHEN DP.class_desc IS NOT NULL                      THEN DP.class_desc
        WHEN DP.class_desc IS NULL AND DB.name IS NOT NULL  THEN 'DATABASE'
        WHEN DP.class_desc IS NULL AND OB.name IS NOT NULL  THEN 'OBJECT_OR_COLUMN'
        WHEN DP.class_desc IS NULL AND SC.name IS NOT NULL  THEN 'SCHEMA'
        WHEN DP.class_desc IS NULL AND PR.name IS NOT NULL  THEN 'DATABASE_PRINCIPAL'
        WHEN DP.class_desc IS NULL AND AY.name IS NOT NULL  THEN 'ASSEMBLY'
        WHEN DP.class_desc IS NULL AND TP.name IS NOT NULL  THEN 'TYPE'
        WHEN DP.class_desc IS NULL AND XS.name IS NOT NULL  THEN 'XML_SCHEMA_COLLECTION'
        WHEN DP.class_desc IS NULL AND MT.name IS NOT NULL  THEN 'MESSAGE_TYPE'
        WHEN DP.class_desc IS NULL AND VC.name IS NOT NULL  THEN 'SERVICE_CONTRACT'
        WHEN DP.class_desc IS NULL AND SV.name IS NOT NULL  THEN 'SERVICE'
        WHEN DP.class_desc IS NULL AND RS.name IS NOT NULL  THEN 'REMOTE_SERVICE_BINDING'
        WHEN DP.class_desc IS NULL AND RT.name IS NOT NULL  THEN 'ROUTE'
        WHEN DP.class_desc IS NULL AND FT.name IS NOT NULL  THEN 'FULLTEXT_CATALOG'
        WHEN DP.class_desc IS NULL AND SK.name IS NOT NULL  THEN 'SYMMETRIC_KEY'
        WHEN DP.class_desc IS NULL AND AK.name IS NOT NULL  THEN 'ASYMMETRIC_KEY'
        WHEN DP.class_desc IS NULL AND CT.name IS NOT NULL  THEN 'CERTIFICATE'
        ELSE NULL 
    END                 AS [Securable Type or Class],
    CASE
        WHEN DP.class_desc = 'DATABASE'                     THEN PS.name
        WHEN DP.class_desc = 'OBJECT_OR_COLUMN'             THEN schema_name(OB.schema_id)
        WHEN DP.class_desc = 'SCHEMA'                       THEN P3.name
        WHEN DP.class_desc = 'DATABASE_PRINCIPAL'           THEN coalesce(PR.default_schema_name, PE.name)
        WHEN DP.class_desc = 'ASSEMBLY'                     THEN P4.name
        WHEN DP.class_desc = 'TYPE'                         THEN schema_name(TP.schema_id)
        WHEN DP.class_desc = 'XML_SCHEMA_COLLECTION'        THEN schema_name(XS.schema_id)
        WHEN DP.class_desc = 'MESSAGE_TYPE'                 THEN P5.name 
        WHEN DP.class_desc = 'SERVICE_CONTRACT'             THEN P6.name 
        WHEN DP.class_desc = 'SERVICE'                      THEN P7.name 
        WHEN DP.class_desc = 'REMOTE_SERVICE_BINDING'       THEN P8.name 
        WHEN DP.class_desc = 'ROUTE'                        THEN P9.name
        WHEN DP.class_desc = 'FULLTEXT_CATALOG'             THEN PA.name
        WHEN DP.class_desc = 'SYMMETRIC_KEY'                THEN PB.name
        WHEN DP.class_desc = 'ASYMMETRIC_KEY'               THEN PC.name
        WHEN DP.class_desc = 'CERTIFICATE'                  THEN PD.name
        WHEN DP.class_desc IS NULL AND DB.name IS NOT NULL  THEN PS.name
        WHEN DP.class_desc IS NULL AND OB.name IS NOT NULL  THEN schema_name(OB.schema_id)
        WHEN DP.class_desc IS NULL AND SC.name IS NOT NULL  THEN P3.name
        WHEN DP.class_desc IS NULL AND PR.name IS NOT NULL  THEN PR.default_schema_name
        WHEN DP.class_desc IS NULL AND AY.name IS NOT NULL  THEN P4.name
        WHEN DP.class_desc IS NULL AND TP.name IS NOT NULL  THEN schema_name(TP.schema_id)
        WHEN DP.class_desc IS NULL AND XS.name IS NOT NULL  THEN schema_name(XS.schema_id)
        WHEN DP.class_desc IS NULL AND MT.name IS NOT NULL  THEN P5.name
        WHEN DP.class_desc IS NULL AND VC.name IS NOT NULL  THEN P6.name
        WHEN DP.class_desc IS NULL AND SV.name IS NOT NULL  THEN P7.name
        WHEN DP.class_desc IS NULL AND RS.name IS NOT NULL  THEN P8.name
        WHEN DP.class_desc IS NULL AND RT.name IS NOT NULL  THEN P9.name
        WHEN DP.class_desc IS NULL AND FT.name IS NOT NULL  THEN PA.name
        WHEN DP.class_desc IS NULL AND SK.name IS NOT NULL  THEN PB.name
        WHEN DP.class_desc IS NULL AND AK.name IS NOT NULL  THEN PC.name
        WHEN DP.class_desc IS NULL AND CT.name IS NOT NULL  THEN PD.name
        ELSE NULL 
    END                 AS [Schema/Owner],
    CASE
        WHEN DP.class_desc = 'DATABASE'                     THEN DB.name
        WHEN DP.class_desc = 'OBJECT_OR_COLUMN'             THEN OB.name
        WHEN DP.class_desc = 'SCHEMA'                       THEN SC.name
        WHEN DP.class_desc = 'DATABASE_PRINCIPAL'           THEN PR.name
        WHEN DP.class_desc = 'ASSEMBLY'                     THEN AY.name
        WHEN DP.class_desc = 'TYPE'                         THEN TP.name
        WHEN DP.class_desc = 'XML_SCHEMA_COLLECTION'        THEN XS.name
        WHEN DP.class_desc = 'MESSAGE_TYPE'                 THEN cast(MT.name as sql_variant)
        WHEN DP.class_desc = 'SERVICE_CONTRACT'             THEN cast(VC.name as sql_variant)
        WHEN DP.class_desc = 'SERVICE'                      THEN cast(SV.name as sql_variant)
        WHEN DP.class_desc = 'REMOTE_SERVICE_BINDING'       THEN RS.name
        WHEN DP.class_desc = 'ROUTE'                        THEN RT.name
        WHEN DP.class_desc = 'FULLTEXT_CATALOG'             THEN FT.name
        WHEN DP.class_desc = 'SYMMETRIC_KEY'                THEN SK.name
        WHEN DP.class_desc = 'ASYMMETRIC_KEY'               THEN AK.name
        WHEN DP.class_desc = 'CERTIFICATE'                  THEN CT.name
        WHEN DP.class_desc IS NULL AND DB.name IS NOT NULL  THEN DB.name 
        WHEN DP.class_desc IS NULL AND OB.name IS NOT NULL  THEN OB.name
        WHEN DP.class_desc IS NULL AND SC.name IS NOT NULL  THEN SC.name
        WHEN DP.class_desc IS NULL AND PR.name IS NOT NULL  THEN PR.name
        WHEN DP.class_desc IS NULL AND AY.name IS NOT NULL  THEN AY.name
        WHEN DP.class_desc IS NULL AND TP.name IS NOT NULL  THEN TP.name
        WHEN DP.class_desc IS NULL AND XS.name IS NOT NULL  THEN XS.name
        WHEN DP.class_desc IS NULL AND MT.name IS NOT NULL  THEN cast(MT.name as sql_variant)
        WHEN DP.class_desc IS NULL AND VC.name IS NOT NULL  THEN cast(VC.name as sql_variant)
        WHEN DP.class_desc IS NULL AND SV.name IS NOT NULL  THEN cast(SV.name as sql_variant)
        WHEN DP.class_desc IS NULL AND RS.name IS NOT NULL  THEN RS.name
        WHEN DP.class_desc IS NULL AND RT.name IS NOT NULL  THEN RT.name
        WHEN DP.class_desc IS NULL AND FT.name IS NOT NULL  THEN FT.name
        WHEN DP.class_desc IS NULL AND SK.name IS NOT NULL  THEN SK.name
        WHEN DP.class_desc IS NULL AND AK.name IS NOT NULL  THEN AK.name
        WHEN DP.class_desc IS NULL AND CT.name IS NOT NULL  THEN CT.name
        ELSE NULL 
    END                 AS [Securable],
    CM.name             AS [Column],
    P1.type_desc        AS [Grantee Type],
    P1.name             AS [Grantee],
    DP.permission_name  AS [Permission],    
    DP.state_desc       AS [State],
    P2.name             AS [Grantor],
    P2.type_desc        AS [Grantor Type]
FROM
    sys.database_permissions DP
    LEFT OUTER JOIN sys.database_principals P1
        ON  P1.principal_id = DP.grantee_principal_id
    LEFT OUTER JOIN sys.database_principals P2
        ON  P2.principal_id = DP.grantor_principal_id

    FULL OUTER JOIN sys.databases DB
        ON  DB.database_id = db_id(db_name(DP.major_id))
        AND DP.class_desc = 'DATABASE'
    LEFT OUTER JOIN sys.server_principals PS
        ON  PS.sid = DB.owner_sid

    FULL OUTER JOIN sys.all_objects OB
        ON  DP.major_id   = OB.[object_id]
        AND DP.class_desc = 'OBJECT_OR_COLUMN'
    LEFT OUTER JOIN sys.all_columns CM
        ON  CM.[object_id] = DP.major_id
        AND CM.[column_id] = DP.minor_id

    FULL OUTER JOIN sys.schemas SC
        ON  DP.major_id   = SC.[schema_id]
        AND DP.class_desc = 'SCHEMA'
    LEFT OUTER JOIN sys.database_principals P3
        ON  P3.principal_id = SC.principal_id

    FULL OUTER JOIN sys.database_principals PR
        ON  DP.major_id   = PR.principal_id
        AND DP.class_desc = 'DATABASE_PRINCIPAL'
    LEFT OUTER JOIN sys.database_principals PE
        ON  PE.principal_id = PR.owning_principal_id

    FULL OUTER JOIN sys.assemblies AY
        ON  DP.major_id   = AY.assembly_id
        AND DP.class_desc = 'ASSEMBLY'
    LEFT OUTER JOIN sys.database_principals P4
        ON  P4.principal_id = AY.principal_id

    FULL OUTER JOIN sys.types TP
        ON  DP.major_id   = TP.user_type_id
        AND DP.class_desc = 'TYPE'

    FULL OUTER JOIN sys.xml_schema_collections XS
        ON  DP.major_id   = XS.xml_collection_id
        AND DP.class_desc = 'XML_SCHEMA_COLLECTION'

    FULL OUTER JOIN sys.service_message_types MT
        ON  DP.major_id   = MT.message_type_id
        AND DP.class_desc = 'MESSAGE_TYPE'
    LEFT OUTER JOIN sys.database_principals P5
        ON  P5.principal_id = MT.principal_id

    FULL OUTER JOIN sys.service_contracts VC
        ON  DP.major_id   = VC.service_contract_id
        AND DP.class_desc = 'SERVICE_CONTRACT'
    LEFT OUTER JOIN sys.database_principals P6
        ON  P6.principal_id = VC.principal_id

    FULL OUTER JOIN sys.services SV
        ON  DP.major_id   = SV.service_id
        AND DP.class_desc = 'SERVICE'
    LEFT OUTER JOIN sys.database_principals P7
        ON  P7.principal_id = SV.principal_id

    FULL OUTER JOIN sys.remote_service_bindings RS
        ON  DP.major_id   = RS.remote_service_binding_id
        AND DP.class_desc = 'REMOTE_SERVICE_BINDING'
    LEFT OUTER JOIN sys.database_principals P8
        ON  P8.principal_id = RS.principal_id

    FULL OUTER JOIN sys.routes RT
        ON  DP.major_id   = RT.route_id
        AND DP.class_desc = 'ROUTE'
    LEFT OUTER JOIN sys.database_principals P9
        ON  P9.principal_id = RT.principal_id

    FULL OUTER JOIN sys.fulltext_catalogs FT
        ON  DP.major_id   = FT.fulltext_catalog_id
        AND DP.class_desc = 'FULLTEXT_CATALOG'
    LEFT OUTER JOIN sys.database_principals PA
        ON  PA.principal_id = FT.principal_id

    FULL OUTER JOIN sys.symmetric_keys SK
        ON  DP.major_id   = SK.symmetric_key_id
        AND DP.class_desc = 'SYMMETRIC_KEY'
    LEFT OUTER JOIN sys.database_principals PB
        ON  PB.principal_id = SK.principal_id

    FULL OUTER JOIN sys.asymmetric_keys AK
        ON  DP.major_id   = AK.asymmetric_key_id
        AND DP.class_desc = 'ASYMMETRIC_KEY'
    LEFT OUTER JOIN sys.database_principals PC
        ON  PC.principal_id = AK.principal_id

    FULL OUTER JOIN sys.certificates CT
        ON  DP.major_id   = CT.certificate_id
        AND DP.class_desc = 'CERTIFICATE'
    LEFT OUTER JOIN sys.database_principals PD
        ON  PD.principal_id = CT.principal_id
/* End Get all permission assignments to users and roles */

/* Get all database role memberships */
SELECT
    R.name  AS [Role],
    M.name  AS [Member]
FROM
    sys.database_role_members X
    INNER JOIN sys.database_principals R ON R.principal_id = X.role_principal_id
    INNER JOIN sys.database_principals M ON M.principal_id = X.member_principal_id
/* End Get all database role memberships */