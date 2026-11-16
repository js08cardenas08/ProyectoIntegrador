/* =====================================================================
   PROYECTO INTEGRADOR - CASO 5: GESTIÓN DEPORTIVA
   Integrantes: Juan Sebastián Cárdenas, Juan David Segura
   Script 00: REINICIO DEL ENTORNO

   ************************  ADVERTENCIA  ******************************
   ESTE SCRIPT BORRA DEFINITIVAMENTE LA BASE DE DATOS GestionDeportiva
   CON TODAS SUS TABLAS, DATOS, VISTAS Y TRIGGERS.
   No afecta otras bases de datos del servidor.
   Úselo solo para reconstruir el proyecto desde cero; después ejecute
   en orden los scripts 01, 02, 03, 04 y 05.
   *********************************************************************
   ===================================================================== */
USE master;
GO

IF DB_ID(N'GestionDeportiva') IS NOT NULL
BEGIN
    PRINT N'ADVERTENCIA: eliminando la base de datos GestionDeportiva...';
    -- Cierra las conexiones abiertas para poder eliminar la base
    ALTER DATABASE GestionDeportiva SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GestionDeportiva;
    PRINT N'Base de datos GestionDeportiva eliminada.';
END
ELSE
    PRINT N'La base de datos GestionDeportiva no existe; no hay nada que borrar.';
GO
