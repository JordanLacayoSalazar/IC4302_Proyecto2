import { API_URL } from "./ModuloHerramientas";

/**
 * Añade filtros a una URL, por ejemplo `{ nombre: "Ana", pagina: 2 }`
 * se convierte en `?nombre=Ana&pagina=2`. Omite valores vacíos o nulos.
 *
 * @param {Record<string, string|number|boolean|null|undefined>} parametros
 *   Objeto con nombres de parámetros y sus valores.
 * @returns {string} Texto para añadir a la URL, o una cadena vacía si no hay valores.
 * @throws {TypeError} Si un valor no se puede convertir a texto.
 */
export const construirQuery = (parametros = {}) => {
  const query = new URLSearchParams();

  Object.entries(parametros).forEach(([nombre, valor]) => {
    if (valor !== undefined && valor !== null && String(valor).trim() !== "") {
      query.set(nombre, String(valor).trim());
    }
  });

  const resultado = query.toString();

  return resultado ? `?${resultado}` : "";
};

/**
 * Ejecuta una solicitud JSON
 * el manejo de errores HTTP.
 *
 * @param {string} ruta
 * @param {RequestInit} opciones
 * @returns {Promise<any>}
 * @throws {Error} Si falla la red o la respuesta HTTP indica un error.
 */
export const solicitarJson = async (ruta, opciones = {}) => {
  const url = ruta.startsWith("http") ? ruta : `${API_URL}${ruta}`;
  const encabezados = new Headers(opciones.headers || {});
  const token =
    typeof window !== "undefined"
      ? window.sessionStorage.getItem("tokenSesion")
      : null;

  if (
    token &&
    url.startsWith(`${API_URL}/api/`) &&
    !encabezados.has("Authorization")
  ) {
    encabezados.set("Authorization", `Bearer ${token}`);
  }

  const respuesta = await fetch(url, { ...opciones, headers: encabezados });
  const datos = await respuesta.json().catch(() => ({}));

  if (!respuesta.ok) {
    const error = new Error(
      datos.errorMsg || datos.error || `Error HTTP ${respuesta.status}.`,
    );

    error.esErrorCriticoBD = datos.esErrorCriticoBD;
    throw error;
  }

  return datos;
};

export const guardarTokenSesion = (token) => {
  window.sessionStorage.setItem("tokenSesion", token);
};

export const borrarTokenSesion = () => {
  window.sessionStorage.removeItem("tokenSesion");
};

/**
 * Determina si un valor representa
 * un entero no negativo.
 *
 * Permite cadena vacía mientras el usuario escribe.
 *
 * @param {string|number} valor
 * @returns {boolean}
 * @throws {TypeError} Si el valor no se puede convertir a texto.
 */
export const esEnteroNoNegativo = (valor) => /^\d*$/.test(String(valor));

/**
 * Determina si un valor representa
 * un decimal no negativo.
 *
 * @param {string|number} valor
 * @returns {boolean}
 * @throws {TypeError} Si el valor no se puede convertir a texto.
 */
export const esDecimalNoNegativo = (valor) =>
  /^\d*(?:[.,]\d*)?$/.test(String(valor));
