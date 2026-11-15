-- ======================= Nodo Corporativo ===============================
-- ejecutar conectado a nodo_corporativo (master)
IF DB_ID(N'WWI_Corporativo') IS NULL CREATE DATABASE WWI_Corporativo COLLATE Latin1_General_100_CI_AS;
GO

-- ======================= Nodo San Jose ===============================
-- ejecutar conectado a nodo_sucursal_sj (master)
IF DB_ID(N'WWI_SanJose') IS NULL CREATE DATABASE WWI_SanJose COLLATE Latin1_General_100_CI_AS;
GO

-- ======================= Nodo Limon ==================================
-- ejecutar conectado a nodo_sucursal_limon (master)
IF DB_ID(N'WWI_Limon') IS NULL CREATE DATABASE WWI_Limon COLLATE Latin1_General_100_CI_AS;
GO
