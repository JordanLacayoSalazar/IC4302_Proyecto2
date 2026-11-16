const { createHmac, timingSafeEqual } = require("node:crypto");
const { AsyncLocalStorage } = require("node:async_hooks");
const {
  BRANCH_ID_PREDETERMINADO,
  BRANCH_IDS_VALIDOS,
  CODIGOS_HTTP,
  ROLES_USUARIO_VALIDOS,
} = require("./constants");

const contextoSesion = new AsyncLocalStorage();

/**
 * Lee la clave de firma configurada para la API.
 *
 * Configure SESSION_SECRET en Api/.env con el resultado de
 * `node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"`.
 * Esto genera 32 bytes aleatorios codificados como 64 caracteres hexadecimales.
 * La clave debe mantenerse privada y no debe enviarse al navegador.
 *
 * @return {string} Clave usada para firmar y verificar tokens de sesión.
 * @throws {Error} Si SESSION_SECRET falta o tiene menos de 32 bytes.
 */
const obtenerClaveSecreta = () => {
  const claveSecreta = process.env.SESSION_SECRET;

  if (!claveSecreta || Buffer.byteLength(claveSecreta) < 32) {
    const error = new Error(
      "Configure SESSION_SECRET con al menos 32 bytes en Api/.env.",
    );
    error.statusCode = CODIGOS_HTTP.ERR_INTERNAL_SERVER_ERROR;
    throw error;
  }

  return claveSecreta;
};

/**
 * Crea un token firmado con los datos del usuario y su nodo. No incluye
 * vencimiento; el token deja de ser válido al cerrar sesión o cambiar la clave.
 *
 * @param {object} usuario Fila autenticada devuelta por SQL Server.
 * @return {string} Token firmado que el cliente enviará en sus solicitudes.
 * @throws {Error} Si SESSION_SECRET no está configurada correctamente.
 */
const crearTokenSesion = (usuario) => {
  const contenido = Buffer.from(
    JSON.stringify({
      userId: usuario.UserID,
      branchId: usuario.BranchID,
      username: usuario.Username,
      fullName: usuario.FullName,
      role: usuario.Role,
    }),
  ).toString("base64url");
  const firma = createHmac("sha256", obtenerClaveSecreta())
    .update(contenido)
    .digest("base64url");

  return `${contenido}.${firma}`;
};

/**
 * Valida la firma del token y comprueba que contenga una identidad y un nodo
 * admitidos.
 *
 * @param {string} token Token recibido en el encabezado Authorization.
 * @return {object|null} Sesión verificada o null si el token no es válido.
 * @throws {Error} Si SESSION_SECRET falta o tiene un formato insuficiente.
 */
const verificarTokenSesion = (token) => {
  const [contenido, firma, extra] = token.split(".");

  if (!contenido || !firma || extra !== undefined) return null;

  const firmaEsperada = createHmac("sha256", obtenerClaveSecreta())
    .update(contenido)
    .digest();
  const firmaRecibida = Buffer.from(firma, "base64url");

  if (
    firmaEsperada.length !== firmaRecibida.length ||
    !timingSafeEqual(firmaEsperada, firmaRecibida)
  ) {
    return null;
  }

  let sesion;
  try {
    sesion = JSON.parse(Buffer.from(contenido, "base64url").toString("utf8"));
  } catch {
    return null;
  }

  if (
    !Number.isInteger(sesion.userId) ||
    !BRANCH_IDS_VALIDOS.includes(sesion.branchId) ||
    !ROLES_USUARIO_VALIDOS.includes(sesion.role)
  ) {
    return null;
  }

  return sesion;
};

/**
 * Valida el token Bearer de la solicitud y guarda su BranchID en el contexto
 * asíncrono para que las consultas usen el nodo asignado.
 *
 * @param {import('express').Request} req Solicitud HTTP entrante.
 * @param {import('express').Response} res Respuesta HTTP.
 * @param {import('express').NextFunction} next Siguiente middleware.
 * @return {void} Continúa la solicitud o responde con un error HTTP.
 * @throws {Error} Si el middleware siguiente lanza un error síncrono.
 */
const autenticarSesion = (req, res, next) => {
  const encabezado = req.get("authorization") || "";
  const coincidencia = /^Bearer ([^\s]+)$/i.exec(encabezado);

  if (!coincidencia) {
    return res
      .status(CODIGOS_HTTP.ERR_UNAUTHORIZED)
      .json({ errorMsg: "Inicia sesión para continuar." });
  }

  let sesion;
  try {
    sesion = verificarTokenSesion(coincidencia[1]);
  } catch (error) {
    return res
      .status(error.statusCode || CODIGOS_HTTP.ERR_INTERNAL_SERVER_ERROR)
      .json({ errorMsg: error.message });
  }

  if (!sesion) {
    return res.status(CODIGOS_HTTP.ERR_UNAUTHORIZED).json({
      errorMsg: "La sesión no es válida. Inicia sesión nuevamente.",
    });
  }

  req.usuario = sesion;
  return contextoSesion.run({ branchId: sesion.branchId }, next);
};

/**
 * Obtiene el BranchID de la solicitud actual.
 *
 * @return {number} BranchID de la sesión o 1 fuera de una solicitud autenticada.
 */
const obtenerBranchIdSesion = () =>
  contextoSesion.getStore()?.branchId ?? BRANCH_ID_PREDETERMINADO;

/** Restringe los reportes y sus filtros a sesiones del nodo Corporativo. */
const autorizarReportesCorporativos = (req, res, next) => {
  if (req.usuario?.branchId !== 1) {
    return res.status(403).json({
      errorMsg: "Los reportes solo están disponibles en el nodo Corporativo.",
    });
  }
  return next();
};

module.exports = {
  autorizarReportesCorporativos,
  autenticarSesion,
  crearTokenSesion,
  obtenerBranchIdSesion,
};
