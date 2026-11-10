/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Script 07: metadatos de la implementación (verificación del diccionario)
   ---------------------------------------------------------------------
   Lee el catálogo de SQL Server (sys.*) y muestra, para cada columna,
   tipo, longitud/precisión, nulabilidad, DEFAULT, PK, FK, UNIQUE y CHECK.
   documentacion/diccionario_datos.md se construyó a partir de esta salida;
   ejecutarlo permite comprobar que el diccionario coincide con la base.
   ===================================================================== */
USE GestionDeportiva;
GO
SET NOCOUNT ON;
GO

-- 1. Columnas
SELECT t.name                                         AS tabla,
       c.column_id                                    AS orden,
       c.name                                         AS columna,
       ty.name                                        AS tipo,
       CASE WHEN ty.name IN ('varchar', 'char') THEN CAST(c.max_length AS VARCHAR(10))
            WHEN ty.name IN ('nvarchar', 'nchar') THEN CAST(c.max_length / 2 AS VARCHAR(10))
            WHEN ty.name = 'decimal' THEN CONCAT(c.precision, ',', c.scale)
            WHEN ty.name = 'datetime2' THEN CAST(c.scale AS VARCHAR(10))
            ELSE '' END                               AS longitud,
       CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END AS nulabilidad,
       CASE WHEN c.is_identity = 1 THEN 'IDENTITY(1,1)' ELSE '' END AS identidad,
       ISNULL(dc.definition, '')                      AS valor_default,
       CASE WHEN EXISTS (SELECT 1 FROM sys.index_columns ic JOIN sys.indexes i ON i.object_id = ic.object_id AND i.index_id = ic.index_id
                         WHERE i.is_primary_key = 1 AND ic.object_id = t.object_id AND ic.column_id = c.column_id)
            THEN 'PK' ELSE '' END                     AS pk,
       ISNULL((SELECT TOP 1 'FK -> ' + OBJECT_NAME(fkc.referenced_object_id) + '.' + COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id)
               FROM sys.foreign_key_columns fkc
               WHERE fkc.parent_object_id = t.object_id AND fkc.parent_column_id = c.column_id), '') AS fk
FROM sys.tables t
JOIN sys.columns c        ON c.object_id = t.object_id
JOIN sys.types ty         ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc ON dc.parent_object_id = t.object_id AND dc.parent_column_id = c.column_id
WHERE t.is_ms_shipped = 0
ORDER BY t.name, c.column_id;

-- 2. Restricciones UNIQUE y CHECK
SELECT OBJECT_NAME(kc.parent_object_id) AS tabla, kc.name AS restriccion, 'UNIQUE' AS tipo,
       STUFF((SELECT ', ' + COL_NAME(ic.object_id, ic.column_id)
              FROM sys.index_columns ic
              WHERE ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
              ORDER BY ic.key_ordinal FOR XML PATH('')), 1, 2, '') AS definicion
FROM sys.key_constraints kc
WHERE kc.type = 'UQ'
UNION ALL
SELECT OBJECT_NAME(cc.parent_object_id), cc.name, 'CHECK', cc.definition
FROM sys.check_constraints cc
ORDER BY tabla, tipo, restriccion;

-- 3. Triggers
SELECT OBJECT_NAME(parent_id) AS tabla, name AS trigger_nombre
FROM sys.triggers
ORDER BY tabla;
GO
