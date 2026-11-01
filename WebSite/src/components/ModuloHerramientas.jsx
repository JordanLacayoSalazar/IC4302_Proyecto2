export const API_URL = "http://localhost:3000";

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
