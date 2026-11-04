import { Box } from "@mui/material";

/** Convierte una coordenada a número y rechaza valores no numéricos.
 * @param {string|number|null|undefined} valor Coordenada original.
 * @returns {number|null} Coordenada válida o `null`.
 * @throws {TypeError} Si la conversión del valor no es posible.
 */
const obtenerCoordenada = (valor) => {
  if (valor === null || valor === undefined || String(valor).trim() === "") {
    return null;
  }

  const coordenada = Number(valor);
  if (!Number.isFinite(coordenada)) {
    return null;
  }

  return coordenada;
};

/** Construye la URL de OpenStreetMap para un punto y su margen visible.
 * @param {number} latitud Latitud del punto.
 * @param {number} longitud Longitud del punto.
 * @param {number} margen Distancia alrededor del punto.
 * @returns {string} URL del mapa incrustado.
 * @throws {RangeError} Si los argumentos no pueden representarse en la URL.
 */
const obtenerEnlaceMapa = (latitud, longitud, margen) => {
  const minLongitud = Math.max(-180, longitud - margen);
  const minLatitud = Math.max(-90, latitud - margen);
  const maxLongitud = Math.min(180, longitud + margen);
  const maxLatitud = Math.min(90, latitud + margen);
  const limites = [minLongitud, minLatitud, maxLongitud, maxLatitud].join(
    "%2C",
  );

  return `https://www.openstreetmap.org/export/embed.html?bbox=${limites}&layer=mapnik&marker=${latitud}%2C${longitud}`;
};

/** Presenta un mapa incrustado cuando las coordenadas están dentro del rango.
 * @param {object} props Coordenadas, título, altura y estilos del mapa.
 * @returns {JSX.Element|null} Mapa o `null` si las coordenadas no son válidas.
 * @throws {Error} Si ocurre un error al crear el elemento del mapa.
 */
export default function MapaUbicacion({
  latitud,
  longitud,
  titulo = "Mapa de ubicación",
  alto = 300,
  sx = {},
}) {
  const latitudNumerica = obtenerCoordenada(latitud);
  const longitudNumerica = obtenerCoordenada(longitud);

  if (
    latitudNumerica === null ||
    longitudNumerica === null ||
    latitudNumerica < -90 ||
    latitudNumerica > 90 ||
    longitudNumerica < -180 ||
    longitudNumerica > 180
  ) {
    return null;
  }

  return (
    // Mapa integrado. Se ubica en las coordenadas seleccionadas.
    <Box
      component="iframe"
      title={titulo}
      src={obtenerEnlaceMapa(latitudNumerica, longitudNumerica, 0.005)}
      loading="lazy"
      sx={{
        width: "100%",
        height: alto,
        border: 0,
        borderRadius: 2,
        ...sx,
      }}
    />
  );
}
