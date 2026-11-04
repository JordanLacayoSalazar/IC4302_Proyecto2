const sql = require("mssql");

/**
 * Convierte un parámetro entero opcional en un número seguro.
 *
 * @param {*} valor Valor recibido
 * @param {string} nombre Nombre del parámetro.
 * @param {{min?: number, max?: number}} opciones Límites opcionales.
 * @returns {number|null} Entero validado o null cuando está vacío.
 * @throws {Error} Cuando el valor no es entero o está fuera de rango.
 */
const leerEnteroOpcional = (valor, nombre, opciones = {}) => {
  if (valor === undefined || valor === null || String(valor).trim() === "") {
    return null;
  }

  const texto = String(valor).trim();

  if (!/^\d+$/.test(texto)) {
    const error = new Error(`${nombre} debe ser un número entero válido.`);

    error.statusCode = 400;

    throw error;
  }

  const numero = Number(texto);

  const { min = Number.MIN_SAFE_INTEGER, max = Number.MAX_SAFE_INTEGER } =
    opciones;

  if (!Number.isSafeInteger(numero) || numero < min || numero > max) {
    const error = new Error(`${nombre} está fuera del rango permitido.`);

    error.statusCode = 400;

    throw error;
  }

  return numero;
};

/**
 * Convierte un parámetro numérico opcional en un número.
 *
 * @param {*} valor Valor recibido.
 * @param {string} nombre Nombre del parámetro.
 * @param {{min?: number, max?: number}} opciones Límites opcionales.
 * @returns {number|null} Número validado o null cuando está vacío.
 * @throws {Error} Cuando el valor no es numérico o está fuera de rango.
 */
const leerNumeroOpcional = (valor, nombre, opciones = {}) => {
  if (valor === undefined || valor === null || String(valor).trim() === "") {
    return null;
  }

  const numero = Number(String(valor).trim().replace(",", "."));

  const { min = Number.NEGATIVE_INFINITY, max = Number.POSITIVE_INFINITY } =
    opciones;

  if (!Number.isFinite(numero) || numero < min || numero > max) {
    const error = new Error(
      `${nombre} debe ser un número válido dentro del rango permitido.`,
    );

    error.statusCode = 400;

    throw error;
  }

  return numero;
};

/**
 * Lee la página base cero y el tamaño permitido para resultados tabulares.
 * @param {object} query Parámetros de paginación recibidos en la URL.
 * @returns {{pagina: number, filasPorPagina: number}} Valores validados.
 */
const leerParametrosPaginacion = (query = {}) => {
  const pagina =
    leerEnteroOpcional(query.pagina, "pagina", { min: 0, max: 1_000_000 }) ?? 0;
  const filasPorPagina =
    leerEnteroOpcional(query.filasPorPagina, "filasPorPagina", {
      min: 5,
      max: 20,
    }) ?? 5;

  if (![5, 10, 20].includes(filasPorPagina)) {
    const error = new Error("filasPorPagina debe ser 5, 10 o 20.");
    error.statusCode = 400;
    throw error;
  }

  return { pagina, filasPorPagina };
};

/**
 * Agrega los parámetros de paginación validados a una solicitud SQL.
 * @param {import('mssql').Request} request Solicitud SQL que se va a ejecutar.
 * @param {object} query Parámetros de paginación recibidos en la URL.
 * @returns {import('mssql').Request} Solicitud con página y tamaño enlazados.
 */
const agregarPaginacion = (request, query = {}) => {
  const { pagina, filasPorPagina } = leerParametrosPaginacion(query);
  return request
    .input("Pagina", sql.Int, pagina)
    .input("FilasPorPagina", sql.Int, filasPorPagina);
};

/**
 * Recorta la fila extra y la usa para indicar si existe otra página.
 * @param {Array<object[]>} resultados Conjuntos devueltos por el procedimiento.
 * @param {object} query Parámetros de paginación usados en la consulta.
 * @returns {{datos: object[], hayMasFilas: boolean}} Página y estado de continuación.
 */
const crearRespuestaPaginada = (resultados = [], query = {}) => {
  const { filasPorPagina } = leerParametrosPaginacion(query);
  const filas = resultados[resultados.length - 1] || [];

  return {
    datos: filas.slice(0, filasPorPagina),
    hayMasFilas: filas.length > filasPorPagina,
  };
};

/**
 * Ejecuta un procedimiento de opciones con búsqueda por texto, ID y paginación.
 * @param {string} procedimiento Nombre fijo del procedimiento almacenado.
 * @param {object} query Parámetros de búsqueda y paginación recibidos por HTTP.
 * @returns {Promise<{datos: object[], hayMasFilas: boolean}>} Página normalizada.
 */
const consultarOpcionesPaginadas = async (procedimiento, query = {}) => {
  const { pagina, filasPorPagina } = leerParametrosPaginacion(query);
  const id = leerEnteroOpcional(query.id, "id", { min: 1 });
  const busqueda = query.buscar?.trim() || null;
  const pool = await conectarBaseDatos();
  const resultado = await agregarPaginacion(pool.request(), {
    pagina,
    filasPorPagina,
  })
    .input("Busqueda", sql.NVarChar(100), busqueda)
    .input("ID", sql.Int, id)
    .execute(procedimiento);

  return crearRespuestaPaginada(resultado.recordsets, {
    pagina,
    filasPorPagina,
  });
};

/**
 * Abre una conexión con la base de datos.
 *
 * @returns {Promise<import('mssql').ConnectionPool>}
 */
const conectarBaseDatos = async () => {
  try {
    return await sql.connect(process.env.DB_CONFIG);
  } catch (error) {
    error.envIncorrecto = true;
    throw error;
  }
};

/**
 * Envía una respuesta HTTP de error.
 *
 * @param {import('express').Response} res
 * @param {Error} err
 * @returns {void}
 */
const manejarError = (res, err) => {
  const procedimientoNoEncontrado =
    err.number === 2812 || err.originalError?.info?.number === 2812;

  const tablaNoEncontrada =
    err.number === 208 || err.originalError?.info?.number === 208;

  const baseDeDatosInaccesible =
    err.number === 4060 || err.originalError?.info?.number === 4060;

  const esErrorCriticoBD =
    Boolean(err.envIncorrecto) ||
    procedimientoNoEncontrado ||
    tablaNoEncontrada ||
    baseDeDatosInaccesible;

  let statusCode;
  if (Number.isInteger(err.statusCode) && err.statusCode >= 400 && err.statusCode < 600) {
      statusCode = err.statusCode;
  } else {
      statusCode = 500;
  }

  res.status(statusCode).json({
    errorMsg: err.message || "Ocurrió un error inesperado.",

    esErrorCriticoBD,
  });
};

module.exports = {
  sql,
  conectarBaseDatos,
  manejarError,
  leerEnteroOpcional,
  leerParametrosPaginacion,
  leerNumeroOpcional,
  agregarPaginacion,
  crearRespuestaPaginada,
  consultarOpcionesPaginadas,
};
