import { API_URL } from "./ModuloHerramientas";

/**
 * Construye una query string omitiendo valores vacíos o nulos.
 *
 * @param {Record<string, unknown>} parametros
 * @returns {string}
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
 */
export const solicitarJson = async (ruta, opciones = {}) => {
  const url = ruta.startsWith("http") ? ruta : `${API_URL}${ruta}`;

  const respuesta = await fetch(url, opciones);
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

/**
 * Normaliza una lista paginada, aceptando también una respuesta antigua en arreglo.
 * @param {unknown} respuesta Respuesta recibida de un endpoint de listado.
 * @returns {{datos: object[], hayMas: boolean}} Filas de la página y disponibilidad de la siguiente.
 */
export const normalizarRespuestaPaginada = (respuesta) => {
  if (Array.isArray(respuesta)) {
    return { datos: respuesta, hayMas: false };
  }

  return {
    datos: Array.isArray(respuesta?.datos) ? respuesta.datos : [],
    hayMas: respuesta?.hayMas === true,
  };
};

/**
 * Determina si un valor representa
 * un entero no negativo.
 *
 * Permite cadena vacía mientras el usuario escribe.
 *
 * @param {string|number} valor
 * @returns {boolean}
 */
export const esEnteroNoNegativo = (valor) => /^\d*$/.test(String(valor));

/**
 * Determina si un valor representa
 * un decimal no negativo.
 *
 * @param {string|number} valor
 * @returns {boolean}
 */
export const esDecimalNoNegativo = (valor) =>
  /^\d*(?:[.,]\d*)?$/.test(String(valor));
