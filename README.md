# Proyecto #2: Bases de datos distribuidas

### Integrantes del grupo: 

| Nombre | Carné |
| ------ | ----- |
| **Jordan Javier Lacayo Salazar** | 2025092130 |
| **Antony Roberto Campbell Ortega** | 2024174749 |

### Estado del proyecto: **Excelente**

<br>

---

**Importante:** La API requiere el archivo .env para funcionar correctamente. Para no exponer información sensible, este archivo no se incluye en este repositorio. Antes de ejecutar la aplicación, se debe crear el archivo .env en la raíz de la carpeta Api y colocar las credenciales. Para más información, vaya a la sección **Configuración de variables de entorno (.env).**

---

<br>

## Objetivos alcanzados
- Se diseñó e implementó una arquitectura de bases de datos distribuidas para la empresa **Wide World Importers**, utilizando tres instancias de SQL Server ejecutadas en contenedores Docker.
- Se configuraron tres nodos independientes correspondientes a las sucursales de **San José**, **Limón** y la oficina **Corporativa**.
- Se desarrolló una aplicación web que permite gestionar y consultar la información de las diferentes sucursales.
- Se implementó un sistema de autenticación de usuarios mediante una interfaz de inicio de sesión.
- Se establecieron dos roles de usuario: **Administrador** y **Corporativo**, con los permisos y funcionalidades requeridas.
- Se implementó la gestión de usuarios, incluyendo el almacenamiento seguro de contraseñas mediante mecanismos de seguridad de SQL Server.
- Se diseñó la fragmentación y distribución de los datos, separando la información compartida de los datos propios de cada sucursal.
- Se centralizó la información sensible de clientes y proveedores en la base de datos Corporativa, garantizando una mejor gestión de la privacidad.
- Se estableció un catálogo compartido de productos, clientes y proveedores entre las sucursales.
- Se implementó la replicación de datos para mantener sincronizada la información de los productos entre las tres bases de datos.
- Se permitió que cada sucursal administre de manera independiente su inventario y facturación.
- Se desarrollaron funcionalidades para consultar clientes, proveedores, productos y facturas según los permisos del usuario.
- Se implementaron operaciones de creación, modificación y eliminación de productos para los usuarios administradores.
- Se incorporó un módulo de estadísticas para el usuario Corporativo, permitiendo consultar información individual por sucursal o de manera general.
- Se contemplaron estrategias de manejo de fallos y recuperación ante problemas de comunicación o indisponibilidad de alguno de los nodos.
- Se utilizó **Docker** para simular un entorno distribuido mediante tres contenedores independientes ejecutados en una misma computadora.
- Se mantuvieron las funcionalidades principales del sistema original, adaptándolas a la nueva arquitectura distribuida.
- Se implementó una estrategia de generación de identificadores únicos mediante secuencias (`SEQUENCE`) de SQL Server, asignando rangos de IDs diferentes a cada nodo (Corporativo, San José y Limón). Esto permite realizar inserciones simultáneas desde distintas sucursales, reduciendo el riesgo de conflictos por duplicidad de claves primarias durante la replicación de datos.

## Objetivos no alcanzados
No se identificaron objetivos no alcanzados. Todos los objetivos establecidos en el enunciado del proyecto fueron implementados.

<br>

## Configuración de variables de entorno (.env)

Para ejecutar la aplicación, es necesario configurar las variables de entorno que permiten establecer la conexión con SQL Server y gestionar las sesiones de usuario.

### 1. Crear el archivo `.env`

En la carpeta Api, en su raíz, crear un archivo llamado `.env`.

### 2. Configurar las variables de entorno

Agregar el siguiente contenido al archivo:

```env
DB_CONFIG="Server=localhost,1433;Database=WWI_Corporativo;User Id=sa;Password=CONTRASEÑA;TrustServerCertificate=true;"
PORT=3000
SESSION_SECRET=CLAVE_SECRETA_DE_AL_MENOS_32_CARACTERES_123456
```

### 3. Descripción de las variables

| Variable | Descripción |
|---|---|
| `DB_CONFIG` | Cadena de conexión a la base de datos SQL Server del nodo Corporativo. |
| `PORT` | Puerto en el que se ejecutará la aplicación web. |
| `SESSION_SECRET` | Clave secreta utilizada para proteger las sesiones de los usuarios. Debe ser aleatoria y contener al menos 32 caracteres. |

### 4. Personalizar la configuración

- **CONTRASEÑA:** Reemplazar por la contraseña del usuario `sa` de SQL Server.
- **SESSION_SECRET:** Reemplazar por una clave secreta segura y aleatoria de al menos 32 caracteres.
