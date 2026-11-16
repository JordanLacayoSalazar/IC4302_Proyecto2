const sql = require("mssql");
const {
  CODIGOS_NODO_NO_DISPONIBLE,
  FORMATO_DB_CONFIG,
  NODOS_LOGIN,
} = require("./constants");
const poolsPorNodo = new Map();

/**
 * Construye la configuración de conexión para el nodo solicitado, conservando
 * las credenciales de DB_CONFIG. Solo acepta el formato indicado para
 * WWI_Corporativo.
 *
 * @param {number} branchId Identificador de la sucursal/nodo.
 * @return {object} Configuración para crear un pool de SQL Server.
 * @throws {Error} Si el nodo o DB_CONFIG no están configurados correctamente.
 */
const obtenerConfiguracionNodo = (branchId) => {
  const nodo = NODOS_LOGIN.find((config) => config.branchId === branchId);

  if (!nodo) {
    throw new Error(`No hay configuración para BranchID ${branchId}.`);
  }

  const configBaseRaw = process.env.DB_CONFIG?.trim();
  if (!configBaseRaw || !FORMATO_DB_CONFIG.test(configBaseRaw)) {
    const error = new Error(
      'DB_CONFIG debe tener el formato "Server=localhost,1433;Database=WWI_Corporativo;User Id=sa;Password=...;TrustServerCertificate=true;".',
    );
    error.envIncorrecto = true;
    throw error;
  }

  let configBase;
  try {
    configBase = sql.ConnectionPool.parseConnectionString(configBaseRaw);
  } catch (cause) {
    const error = new Error("DB_CONFIG no contiene una configuración SQL válida.");
    error.envIncorrecto = true;
    error.cause = cause;
    throw error;
  }

  if (!configBase || typeof configBase !== "object") {
    const error = new Error("DB_CONFIG debe definir una configuración SQL.");
    error.envIncorrecto = true;
    throw error;
  }

  return {
    ...configBase,
    server: nodo.hostServer,
    port: nodo.port,
    database: nodo.database,
  };
};

/**
 * Obtiene o crea un pool persistente para el nodo indicado.
 *
 * @param {number} branchId Identificador de la sucursal/nodo.
 * @return {Promise<import('mssql').ConnectionPool>} Pool conectado.
 * @throws {Error} Si SQL Server no está disponible o rechaza la conexión.
 */
const conectarNodo = async (branchId) => {
  const entradaExistente = poolsPorNodo.get(branchId);
  if (entradaExistente?.pool?.connected) return entradaExistente.pool;
  if (entradaExistente?.conectando) return entradaExistente.promesa;
  if (entradaExistente) poolsPorNodo.delete(branchId);

  const pool = new sql.ConnectionPool(obtenerConfiguracionNodo(branchId));
  const entrada = { pool, promesa: null, conectando: true };

  entrada.promesa = pool
    .connect()
    .then(() => {
      entrada.conectando = false;
      return pool;
    })
    .catch(async (error) => {
      entrada.conectando = false;
      if (poolsPorNodo.get(branchId) === entrada) {
        poolsPorNodo.delete(branchId);
      }

      try {
        await pool.close();
      } catch (closeError) {
        console.error(`No se pudo cerrar el pool del nodo ${branchId}.`, closeError);
      }

      throw error;
    });

  poolsPorNodo.set(branchId, entrada);

  return entrada.promesa;
};


/**
 * Cierra y olvida el pool fallido del nodo, si todavía es el pool registrado.
 *
 * @param {number} branchId Identificador de la sucursal/nodo.
 * @param {import('mssql').ConnectionPool} [pool] Pool que falló.
 * @return {void} No devuelve un valor.
 */
const descartarPool = (branchId, pool) => {
  const entrada = poolsPorNodo.get(branchId);
  if (!entrada || (pool && entrada.pool !== pool)) return;

  poolsPorNodo.delete(branchId);
  void entrada.pool.close().catch((error) => {
    console.error(`No se pudo cerrar el pool del nodo ${branchId}.`, error);
  });
};

/**
 * Determina si el error indica que el nodo SQL no está disponible.
 *
 * @param {Error} error Error devuelto al conectar o ejecutar una consulta.
 * @return {boolean} True cuando se puede intentar otro nodo.
 */
const esErrorDeConexion = (error) =>
  CODIGOS_NODO_NO_DISPONIBLE.includes(
    error.code || error.originalError?.code || "",
  );

module.exports = {
  conectarNodo,
  descartarPool,
  esErrorDeConexion,
};
