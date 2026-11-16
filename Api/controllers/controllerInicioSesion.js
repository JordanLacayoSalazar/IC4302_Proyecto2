const sql = require("mssql");
const { manejarError } = require("../utilidades");
const {
  conectarNodo,
  descartarPool,
  esErrorDeConexion,
} = require("../nodos");
const { crearTokenSesion } = require("../autenticacion");
const { CODIGOS_HTTP, NODOS_LOGIN } = require("../constants");

/**
 * Valida las credenciales en orden Corporativo, San José y Limón.
 *
 * @param {import('express').Request} req Solicitud con username y password.
 * @param {import('express').Response} res Respuesta HTTP.
 * @return {Promise<void>} Devuelve el token y perfil, o un error HTTP.
 */
const iniciarSesion = async (req, res) => {
  const username =
    typeof req.body?.username === "string" ? req.body.username.trim() : "";
  const password =
    typeof req.body?.password === "string" ? req.body.password : "";

  if (!username || !password) {
    return res.status(CODIGOS_HTTP.ERR_BAD_REQUEST).json({
      errorMsg: "Ingresa un usuario y una contraseña válidos.",
    });
  }

  for (const nodo of NODOS_LOGIN) {
    let pool;

    try {
      pool = await conectarNodo(nodo.branchId);
      const resultado = await pool
        .request()
        .input("Username", sql.VarChar(50), username)
        .input("PasswordText", sql.VarChar(100), password)
        .execute("dbo.sp_AuthenticateUser");
      const usuario = resultado.recordset[0];

      if (!usuario) {
        return res.status(CODIGOS_HTTP.ERR_UNAUTHORIZED).json({
          errorMsg: "Nombre de usuario o contraseña incorrectos.",
        });
      }

      return res.json({
        token: crearTokenSesion(usuario),
        usuario: {
          userId: usuario.UserID,
          branchId: usuario.BranchID,
          username: usuario.Username,
          fullName: usuario.FullName,
          role: usuario.Role,
        },
      });
    } catch (error) {
      if (!esErrorDeConexion(error)) {
        return manejarError(res, error);
      }

      console.warn(
        `No se pudo autenticar en el nodo ${nodo.branchName}; se probará el siguiente.`,
        error,
      );
      descartarPool(nodo.branchId, pool);
    }
  }

  return res.status(CODIGOS_HTTP.ERR_SERVICE_UNAVAILABLE).json({
    errorMsg:
      "No se pudo conectar con los nodos Corporativo, Limón ni San José. Intenta nuevamente más tarde.",
  });
};

module.exports = { iniciarSesion };
