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

const mapearOpciones = (respuesta) => {
  const filas = Array.isArray(respuesta) ? respuesta : respuesta?.datos;
  if (!Array.isArray(filas)) {
    throw new Error("La respuesta del catálogo no contiene una lista de opciones.");
  }

  return {
    datos: filas.slice(0, 10).map((item) => ({
      id: item.OpcionID ?? item.id,
      etiqueta: item.Etiqueta ?? item.etiqueta ?? item.label ?? "",
      precio: item.Precio ?? item.precio,
      impuesto: item.Impuesto ?? item.impuesto,
    })),
    hayMas: typeof respuesta?.hayMas === "boolean"
      ? respuesta.hayMas
      : filas.length > 10,
  };
};

/**
 * Busca opciones en el servidor y permite recorrer el catálogo por páginas.
 * @param {object} props Catálogo, selección, etiquetas y manejadores del campo.
 * @returns {JSX.Element} Autocompletado paginado.
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
  const [hayMas, setHayMas] = useState(false);
  const [cargando, setCargando] = useState(false);
  const [errorConsulta, setErrorConsulta] = useState("");
  const solicitudActual = useRef(0);
  const etiquetaVisible = modoTexto ? String(valor || "") : seleccionada?.etiqueta || "";
  const seleccionadaVigente =
    valor !== null && valor !== undefined && valor !== "" &&
    String(seleccionada?.id) === String(valor)
      ? seleccionada
      : null;

  const consultar = useCallback(async ({ texto = "", paginaSolicitada = 0, id } = {}) => {
    const numeroSolicitud = ++solicitudActual.current;
    setCargando(true);
    try {
      const respuesta = mapearOpciones(await solicitarJson(
        `/api/opciones/${catalogo}${construirQuery({
          buscar: texto,
          pagina: paginaSolicitada,
          filasPorPagina: 10,
          id,
        })}`,
      ));
      const datos = respuesta.datos;
      if (numeroSolicitud === solicitudActual.current) {
        setErrorConsulta("");
        setOpciones(datos);
        setHayMas(respuesta.hayMas);
      }
      return datos;
    } catch (error) {
      if (numeroSolicitud === solicitudActual.current) {
        setOpciones([]);
        setHayMas(false);
        setErrorConsulta(error.message || "Error desconocido al consultar el catálogo.");
      }
      console.error(`No se pudieron cargar opciones de ${catalogo}:`, error);
      return [];
    } finally {
      if (numeroSolicitud === solicitudActual.current) setCargando(false);
    }
  }, [catalogo]);

  useEffect(() => {
    if (!precargar) return undefined;
    const temporizador = setTimeout(() => {
      consultar({ texto: "", paginaSolicitada: 0 });
    }, 0);
    return () => clearTimeout(temporizador);
  }, [catalogo, precargar, consultar]);

  useEffect(() => {
    if (!abierto) return undefined;
    const temporizador = setTimeout(() => {
      consultar({ texto: busqueda, paginaSolicitada: pagina });
    }, 220);
    return () => clearTimeout(temporizador);
  }, [abierto, busqueda, pagina, catalogo, consultar]);

  useEffect(() => {
    if (!precargar || modoTexto) return;
    if (valor === null || valor === undefined || valor === "") return;
    if (seleccionadaVigente) return;
    let activo = true;
    const temporizador = setTimeout(() => {
      consultar({ texto: "", paginaSolicitada: 0, id: valor }).then((datos) => {
        if (activo) setSeleccionada(datos[0] || null);
      });
    }, 0);
    return () => {
      activo = false;
      clearTimeout(temporizador);
    };
  }, [valor, modoTexto, catalogo, precargar, seleccionadaVigente, consultar]);

  const opcionesVisibles =
    seleccionadaVigente &&
    !modoTexto &&
    !opciones.some((item) => String(item.id) === String(seleccionadaVigente.id))
      ? [
          seleccionadaVigente,
          ...(catalogo === "ciudades"
            ? opciones.filter(
                (item) => item.etiqueta !== seleccionadaVigente.etiqueta,
              )
            : opciones),
        ]
      : opciones;
  const valorControlado = modoTexto ? etiquetaVisible : seleccionadaVigente;

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
          disabled={!hayMas || cargando}
          onClick={() => setPagina((paginaActual) => paginaActual + 1)}
        >
          <KeyboardArrowRightIcon />
        </IconButton>
      </Box>
    </Paper>
  );

  return (
    <Autocomplete
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
      getOptionLabel={(opcion) =>
        typeof opcion === "string" ? opcion : opcion?.etiqueta || ""
      }
      getOptionKey={(opcion) => String(opcion?.id ?? opcion?.etiqueta ?? opcion)}
      isOptionEqualToValue={(opcion, actual) =>
        String(opcion?.id) === String(actual?.id)
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
          const texto = typeof opcion === "string" ? opcion : opcion?.etiqueta || "";
          setSeleccionada(typeof opcion === "object" ? opcion : null);
          onChange(texto);
        } else {
          setSeleccionada(opcion);
          onChange(opcion || null);
        }
      }}
      slots={{ paper: PaperConPaginacion }}
      noOptionsText={errorConsulta ? `Error al cargar: ${errorConsulta}` : "Sin resultados"}
      loadingText={<CircularProgress size={20} />}
      renderInput={(params) => (
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
              ...params.slotProps?.input,
              endAdornment: (
                <>
                  {cargando && <CircularProgress color="inherit" size={18} />}
                  {params.slotProps?.input?.endAdornment}
                </>
              ),
            },
          }}
        />
      )}
    />
  );
}
