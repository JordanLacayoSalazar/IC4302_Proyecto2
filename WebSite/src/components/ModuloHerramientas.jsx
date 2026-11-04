export const API_URL = "http://localhost:3000";

/** Verifica que la API pueda conectarse con la base de datos.
 * @returns {Promise<void>} Se resuelve si la conexión está disponible.
 * @throws {Error} Si falla la solicitud o la base de datos no está conectada.
 */
export const verificarConexionBD = async () => {
  const response = await fetch(`${API_URL}/api/verificar-conexion`);
  const data = await response.json();

  if (!response.ok) {
    const error = new Error(
      data.errorMsg || "No se pudo verificar la conexión con la base de datos.",
    );
    error.ocultarModulo = data.esErrorCriticoBD;
    throw error;
  }

  if (!data.conectado) {
    throw new Error("No se pudo verificar la conexión con la base de datos.");
  }
};

/** Clasifica el error y lo presenta como notificación u ocultamiento del módulo.
 * @param {Error} error Error que se desea informar.
 * @param {Function} onErrorNotificacion Manejador de notificaciones visibles.
 * @param {Function} onErrorOcultarModulo Manejador de errores críticos.
 * @param {string} contexto Descripción de la operación que falló.
 * @returns {void} Informa el error al manejador correspondiente.
 * @throws {TypeError} Si los manejadores requeridos no son funciones.
 */
export const mostrarError = (
  error,
  onErrorNotificacion,
  onErrorOcultarModulo,
  contexto = "",
) => {
  const mensajeError = error.message || String(error);
  const etiquetaContexto = contexto.trim();
  const mensaje = etiquetaContexto
    ? `${etiquetaContexto}: ${mensajeError}`
    : mensajeError;
  if (etiquetaContexto) console.error(`${etiquetaContexto}:`, error);
  if (
    error.ocultarModulo ||
    error.esErrorCriticoBD ||
    error instanceof TypeError
  ) {
    onErrorOcultarModulo(mensaje);
  } else {
    onErrorNotificacion(mensaje);
  }
};
