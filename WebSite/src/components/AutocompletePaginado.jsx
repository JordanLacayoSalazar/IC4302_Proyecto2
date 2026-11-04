import { useCallback, useEffect, useRef, useState } from "react";
import {
  Autocomplete,
  CircularProgress,
  Box,
  IconButton,
  Paper,
  TextField,
  Typography,
} from "@mui/material";
import { construirQuery, solicitarJson } from "./apiHerramientas";
import KeyboardArrowLeftIcon from "@mui/icons-material/KeyboardArrowLeft";
import KeyboardArrowRightIcon from "@mui/icons-material/KeyboardArrowRight";

/** Convierte la respuesta del catálogo al formato de opciones del autocompletado.
 * @param {{datos: object[], hayMasFilas: boolean}} respuesta Objeto JSON donde `datos` contiene las opciones de la página y `hayMasFilas` indica si existe otra página.
 * @returns {{datos: object[], hayMasFilas: boolean}} Opciones y estado de continuación.
 * @throws {Error} Si la respuesta no contiene una lista de opciones.
 */
const mapearOpciones = (respuesta) => {
  let filas;
  if (Array.isArray(respuesta)) {
    filas = respuesta;
  } else if (respuesta && Array.isArray(respuesta.datos)) {
    filas = respuesta.datos;
  }

  if (!Array.isArray(filas)) {
    throw new Error("La respuesta del catálogo no contiene una lista de opciones.");
  }

  let hayMasFilas;
  if (respuesta && typeof respuesta.hayMasFilas === "boolean") {
    hayMasFilas = respuesta.hayMasFilas;
  } else {
    hayMasFilas = filas.length > 10;
  }

  return {
    datos: filas.slice(0, 10).map((item) => {
      let id = item.OpcionID;
      if (id === null || id === undefined) id = item.id;

      let etiqueta = item.Etiqueta;
      if (etiqueta === null || etiqueta === undefined) etiqueta = item.etiqueta;
      if (etiqueta === null || etiqueta === undefined) etiqueta = item.label;
      if (etiqueta === null || etiqueta === undefined) etiqueta = "";

      let precio = item.Precio;
      if (precio === null || precio === undefined) precio = item.precio;

      let impuesto = item.Impuesto;
      if (impuesto === null || impuesto === undefined) impuesto = item.impuesto;

      return { id, etiqueta, precio, impuesto };
    }),
    hayMasFilas,
  };
};

/**
 * Busca opciones en el servidor y permite recorrer el catálogo por páginas.
 * @param {object} props Catálogo, selección, etiquetas y manejadores del campo.
 * @returns {JSX.Element} Autocompletado paginado.
 * @throws {Error} Si el componente no puede renderizar las propiedades recibidas.
 */
export default function AutocompletePaginado({
  catalogo,
  valor,
  onChange,
  etiqueta,
  modoTexto = false,
  requerido = false,
  error = false,
  mensajeError = "",
  textoAyuda,
  onKeyDown,
  className,
  fullWidth = true,
  sx,
  size = "medium",
  precargar = true,
}) {
  const [abierto, setAbierto] = useState(false);
  const [busqueda, setBusqueda] = useState("");
  const [pagina, setPagina] = useState(0);
  const [opciones, setOpciones] = useState([]);
  const [seleccionada, setSeleccionada] = useState(null);
  const [hayMasFilas, setHayMasFilas] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [errorConsulta, setErrorConsulta] = useState("");
  const solicitudActual = useRef(0);

  let etiquetaVisible = "";
  if (modoTexto) {
    etiquetaVisible = String(valor || "");
  } else if (seleccionada && seleccionada.etiqueta) {
    etiquetaVisible = seleccionada.etiqueta;
  }

  let seleccionadaVigente = null;
  if (valor !== null && valor !== undefined && valor !== "" && seleccionada && String(seleccionada.id) === String(valor)) {
    seleccionadaVigente = seleccionada;
  }

  /** Consulta una página del catálogo con búsqueda opcional y actualización de estado.
   * @param {object} [consulta] Texto a buscar, número de página e identificador opcional.
   * @returns {Promise<object[]>} Opciones recibidas o lista vacía si falla la solicitud.
   * @throws {Error} Los errores de solicitud se capturan y reflejan en el campo.
   */
  const consultarOpciones = useCallback(async ({
    textoABuscar = "",
    numPaginaSolicitada = 0,
    id
  } = {}) => {

    const numeroSolicitud = ++solicitudActual.current;
    setCargando(true);

    try {
      // Construir parámetros
      const parametros = construirQuery({
        buscar: textoABuscar,
        pagina: numPaginaSolicitada,
        filasPorPagina: 10,
        id,
      });

      // Construir URL
      const url = `/api/opciones/${catalogo}${parametros}`;

      // ConsultarOpciones servidor
      const resultado = await solicitarJson(url);

      // Mapear respuesta
      const respuesta = mapearOpciones(resultado);

      // Obtener datos
      const datos = respuesta.datos;

      // Actualizar estados
      if (numeroSolicitud === solicitudActual.current) {
        setErrorConsulta("");
        setOpciones(datos);
        setHayMasFilas(respuesta.hayMasFilas);
      }

      return datos;

    } catch (error) {
      if (numeroSolicitud === solicitudActual.current) {
        setOpciones([]);
        setHayMasFilas(false);
        setErrorConsulta(error.message || "Error desconocido al consultarOpciones el catálogo.");
      }

      console.error(`No se pudieron cargar opciones de ${catalogo}:`, error);
      return [];

    } finally {
      if (numeroSolicitud === solicitudActual.current) {
        setCargando(false);
      }
    }
  }, [catalogo]);


  useEffect(() => {
    if (!precargar) return undefined;

    const temporizador = setTimeout(() => {
      consultarOpciones({ textoABuscar: "", numPaginaSolicitada: 0 });
    }, 0);
    return () => clearTimeout(temporizador);
  }, [catalogo, precargar, consultarOpciones]);


  useEffect(() => {
    if (!abierto) return undefined;

    const temporizador = setTimeout(() => {
      consultarOpciones({ textoABuscar: busqueda, numPaginaSolicitada: pagina });
    }, 220);
    return () => clearTimeout(temporizador);
  }, [abierto, busqueda, pagina, catalogo, consultarOpciones]);


  useEffect(() => {
    if (!precargar || modoTexto) return;
    if (valor === null || valor === undefined || valor === "") return;
    if (seleccionadaVigente) return;

    let activo = true;
    const temporizador = setTimeout(() => {
      consultarOpciones({ textoABuscar: "", numPaginaSolicitada: 0, id: valor }).then((datos) => {
        if (activo) setSeleccionada(datos[0] || null);
      });
    }, 0);
    return () => {
      activo = false;
      clearTimeout(temporizador);
    };
  }, [valor, modoTexto, catalogo, precargar, seleccionadaVigente, consultarOpciones]);


  let opcionesVisibles = opciones;
  if (
    seleccionadaVigente &&
    !modoTexto &&
    !opciones.some((item) => String(item.id) === String(seleccionadaVigente.id))
  ) {
    if (catalogo === "ciudades") {
      opcionesVisibles = [
        seleccionadaVigente,
        ...opciones.filter(
          (item) => item.etiqueta !== seleccionadaVigente.etiqueta
        ),
      ];
    } else {
      opcionesVisibles = [seleccionadaVigente, ...opciones];
    }
  }


  const valorControlado = modoTexto ? etiquetaVisible : seleccionadaVigente;

  /** Agrega los controles de paginación al menú desplegable de opciones.
   * @param {object} props Propiedades del componente Paper de MUI.
   * @returns {JSX.Element} Menú de opciones con controles de página.
   * @throws {Error} Si ocurre un error al renderizar las opciones.
   */
  const PaperConPaginacion = (props) => (
    <Paper
      {...props}
      className={`autocomplete-paginado-paper ${props.className || ""}`}
    >
      {props.children}
      <Box
        className="autocomplete-paginado-controles"
        onMouseDown={(evento) => evento.preventDefault()}
      >
        {/* Muestra el número de página. */}
        <Typography variant="caption" className="autocomplete-paginado-pagina">
          Página {pagina + 1}
        </Typography>
        <IconButton
          aria-label="Página anterior"
          size="small"
          disabled={pagina === 0 || cargando}
          onClick={() => setPagina((paginaActual) => Math.max(0, paginaActual - 1))}
        >
          <KeyboardArrowLeftIcon />
        </IconButton>
        <IconButton
          aria-label="Página siguiente"
          size="small"
          disabled={!hayMasFilas || cargando}
          onClick={() => setPagina((paginaActual) => paginaActual + 1)}
        >
          <KeyboardArrowRightIcon />
        </IconButton>
      </Box>
    </Paper>
  );

  return (
    // Autocomplete presenta el combobox y Paper muestra la lista y los controles.
    <Autocomplete
      className={className}
      size={size}
      fullWidth={fullWidth}
      freeSolo={modoTexto}
      open={abierto}
      onOpen={() => setAbierto(true)}
      onClose={() => setAbierto(false)}
      options={opcionesVisibles}
      value={valorControlado}
      inputValue={modoTexto ? etiquetaVisible : undefined}
      loading={cargando}
      filterOptions={(lista) => lista}

      getOptionLabel={(opcion) => {
        if (typeof opcion === "string") {
          return opcion;
        } else if (opcion && opcion.etiqueta) {
          return opcion.etiqueta;
        } else {
          return "";
        }
      }}

      getOptionKey={(opcion) => {
        if (opcion && opcion.id !== null && opcion.id !== undefined) {
          return String(opcion.id);
        }
        if (opcion && opcion.etiqueta !== null && opcion.etiqueta !== undefined) {
          return String(opcion.etiqueta);
        }
        return String(opcion);
      }}

      isOptionEqualToValue={(opcion, actual) =>
        String(opcion && opcion.id) === String(actual && actual.id)
      }

      onInputChange={(_, texto, razon) => {
        if (razon === "input" || razon === "clear") {
          setBusqueda(texto);
          setPagina(0);
          if (modoTexto) onChange(texto);
        }
      }}

      onChange={(_, opcion) => {
        if (modoTexto) {
          let texto;

          if (typeof opcion === "string") {
            texto = opcion;
          } else if (opcion && opcion.etiqueta) {
            texto = opcion.etiqueta;
          } else {
            texto = "";
          }

          if (typeof opcion === "object") {
            setSeleccionada(opcion);
          } else {
            setSeleccionada(null);
          }

          onChange(texto);

        } else {
          setSeleccionada(opcion);

          if (opcion) {
            onChange(opcion);
          } else {
            onChange(null);
          }
        }
      }}

      // Aquí se muestra la lista con paginación
      slots={{ paper: PaperConPaginacion }}

      noOptionsText={errorConsulta ? `Error al cargar: ${errorConsulta}` : "Sin resultados"}
      loadingText={<CircularProgress size={20} />}

      renderInput={(params) => {
        let inputParams = {};

        if (params.slotProps && params.slotProps.input) {
          inputParams = params.slotProps.input;
        }

        return (
          // Genera el campo de texto con etiqueta, errores, ayuda y el indicador de carga.
          <TextField
            {...params}
            label={etiqueta}
            required={requerido}
            error={error}
            helperText={mensajeError || textoAyuda}
            onKeyDown={onKeyDown}
            sx={sx}
            slotProps={{
              ...params.slotProps,
              input: {
                ...inputParams,
                endAdornment: (
                  <>
                    {cargando && <CircularProgress color="inherit" size={18} />}
                    {inputParams.endAdornment}
                  </>
                ),
              },
            }}
          />
        );
      }}
    />
  );
}
