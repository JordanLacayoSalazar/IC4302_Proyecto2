import { useEffect, useMemo, useState } from "react";

import {
  Autocomplete,
  Box,
  Button,
  Card,
  CardActionArea,
  Chip,
  Divider,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";

import QueryStatsOutlinedIcon from "@mui/icons-material/QueryStatsOutlined";
import SearchIcon from "@mui/icons-material/Search";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import AssessmentIcon from "@mui/icons-material/Assessment";
import BarChartIcon from "@mui/icons-material/BarChart";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import InventoryIcon from "@mui/icons-material/Inventory";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import PersonSearchIcon from "@mui/icons-material/PersonSearch";
import LeaderboardIcon from "@mui/icons-material/Leaderboard";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import HandshakeIcon from "@mui/icons-material/Handshake";
import SendIcon from "@mui/icons-material/Send";

import ControlesPaginacionTabla from "../components/ControlesPaginacionTabla";
import AutocompletePaginado from "../components/AutocompletePaginado";
import ModuloInterfazBase from "../components/ModuloInterfazBase";
import { mostrarError } from "../components/ModuloHerramientas";
import {
  construirQuery,
  esEnteroNoNegativo,
  solicitarJson,
} from "../components/apiHerramientas";

const FILTROS_INICIALES = {
  proveedor: "",
  nombreCliente: "",
  categoria: "",
  subcategoria: "",
  anio: "",
  anioInicio: "",
  anioFin: "",
  mes: "",
  categoriaClienteId: "",
  categoriaProductoId: "",
  productoId: "",
};

const MESES = [
  { value: "1", label: "Enero" },
  { value: "2", label: "Febrero" },
  { value: "3", label: "Marzo" },
  { value: "4", label: "Abril" },
  { value: "5", label: "Mayo" },
  { value: "6", label: "Junio" },
  { value: "7", label: "Julio" },
  { value: "8", label: "Agosto" },
  { value: "9", label: "Septiembre" },
  { value: "10", label: "Octubre" },
  { value: "11", label: "Noviembre" },
  { value: "12", label: "Diciembre" },
];

const CONFIG_REPORTES = [
  {
    num: 1,
    label: "Compras a proveedores",
    desc: "Montos máximo, mínimo y promedio agrupados por proveedor y categoría.",
    Icono: HandshakeIcon,
    etiqueta: "Compras",
    inputs: [
      {
        campo: "proveedor",
        label: "Proveedor",
        source: "proveedores",
        catalogo: "proveedores",
        tipo: "texto",
      },
      {
        campo: "categoria",
        label: "Categoría de proveedor",
        source: "categoriasProveedores",
        catalogo: "categoriasProveedor",
        tipo: "texto",
      },
    ],
  },

  {
    num: 2,
    label: "Ventas por cliente",
    desc: "Montos máximo, mínimo y promedio agrupados por cliente y categoría.",
    Icono: ReceiptLongIcon,
    etiqueta: "Ventas",
    inputs: [
      {
        campo: "nombreCliente",
        label: "Nombre del cliente",
        catalogo: "clientes",
        tipo: "texto",
      },
      {
        campo: "categoria",
        label: "Categoría del cliente",
        catalogo: "categoriasCliente",
        tipo: "texto",
      },
    ],
  },

  {
    num: 3,
    label: "Top 5 ganancias por producto",
    desc: "Productos con mayor ganancia por año.",
    Icono: LeaderboardIcon,
    etiqueta: "Rentabilidad",
    inputs: [
      {
        campo: "anio",
        label: "Año",
        source: "anios",
        tipo: "entero",
      },
    ],
  },

  {
    num: 4,
    label: "Top 5 clientes por facturas",
    desc: "Clientes con más facturas emitidas por año y monto total facturado.",
    Icono: LeaderboardIcon,
    etiqueta: "Ventas",
    inputs: [
      {
        campo: "anioInicio",
        label: "Año inicial",
        source: "aniosFacturas",
        tipo: "opciones",
      },
      {
        campo: "anioFin",
        label: "Año final",
        source: "aniosFacturas",
        tipo: "opciones",
      },
    ],
  },

  {
    num: 5,
    label: "Top 5 proveedores por órdenes",
    desc: "Proveedores con más órdenes de compra por año y monto total.",
    Icono: LeaderboardIcon,
    etiqueta: "Compras",
    inputs: [
      {
        campo: "anioInicio",
        label: "Año inicial",
        source: "aniosOrdenesCompra",
        tipo: "opciones",
      },
      {
        campo: "anioFin",
        label: "Año final",
        source: "aniosOrdenesCompra",
        tipo: "opciones",
      },
    ],
  },

  {
    num: 6,
    label: "Matriz resumen de ventas",
    desc: "Resumen de ventas de categorías de productos por año.",
    Icono: TrendingUpIcon,
    etiqueta: "Resumen",
    inputs: [
      {
        campo: "anioInicio",
        label: "Año inicial",
        source: "aniosFacturas",
        tipo: "entero",
      },
      {
        campo: "anioFin",
        label: "Año final",
        source: "aniosFacturas",
        tipo: "entero",
      },
    ],
  },

  {
    num: 7,
    label: "Seguimiento de compras por cliente",
    desc: "Resumen mensual por cliente con facturas, cantidades y montos.",
    Icono: PersonSearchIcon,
    etiqueta: "Seguimiento",
    inputs: [
      {
        campo: "anio",
        label: "Año",
        source: "aniosFacturas",
        tipo: "opciones",
      },
      {
        campo: "mes",
        label: "Mes",
        source: "meses",
        tipo: "opciones",
      },
      {
        campo: "categoria",
        label: "Categoría de producto",
        source: "categoriasProductos",
        catalogo: "gruposProducto",
        tipo: "texto",
      },
      {
        campo: "subcategoria",
        label: "Subcategoría / producto",
        source: "subcategorias",
        catalogo: "productos",
        tipo: "texto",
      },
    ],
  },

  {
    num: 8,
    label: "Seguimiento de compras a proveedores",
    desc: "Resumen mensual por proveedor con cantidades y montos.",
    Icono: LocalShippingIcon,
    etiqueta: "Seguimiento",
    inputs: [
      {
        campo: "anio",
        label: "Año",
        source: "anios",
        tipo: "entero",
      },
      {
        campo: "mes",
        label: "Mes",
        source: "meses",
        tipo: "opciones",
      },
      {
        campo: "categoria",
        label: "Categoría de producto",
        source: "categoriasProductos",
        catalogo: "gruposProducto",
        tipo: "texto",
      },
      {
        campo: "subcategoria",
        label: "Subcategoría / producto",
        source: "subcategorias",
        catalogo: "productos",
        tipo: "texto",
      },
    ],
  },

  {
    num: 9,
    label: "Rotación de inventario",
    desc: "Días estimados de rotación por producto, año y proveedor.",
    Icono: InventoryIcon,
    etiqueta: "Inventario",
    inputs: [
      {
        campo: "anio",
        label: "Año",
        source: "anios",
        tipo: "entero",
      },
      {
        campo: "categoria",
        label: "Categoría de producto",
        source: "categoriasProductos",
        catalogo: "gruposProducto",
        tipo: "texto",
      },
      {
        campo: "proveedor",
        label: "Proveedor",
        source: "proveedores",
        catalogo: "proveedores",
        tipo: "texto",
      },
    ],
  },

  {
    num: 10,
    label: "Método de envío favorito por destino",
    desc: "Método de envío más utilizado por destino, según los filtros seleccionados.",
    Icono: SendIcon,
    etiqueta: "Envíos",
    inputs: [
      {
        campo: "anio",
        label: "Año",
        source: "aniosFacturas",
        tipo: "opciones",
      },
      {
        campo: "mes",
        label: "Mes",
        source: "meses",
        tipo: "opciones",
      },
      {
        campo: "categoriaClienteId",
        label: "Categoría de cliente",
        source: "categoriasClientes",
        catalogo: "categoriasCliente",
        tipo: "opciones",
      },
      {
        campo: "categoriaProductoId",
        label: "Categoría de producto",
        source: "categoriasProductosIds",
        catalogo: "gruposProducto",
        tipo: "opciones",
      },
      {
        campo: "productoId",
        label: "Producto",
        source: "productos",
        catalogo: "productos",
        tipo: "opciones",
      },
    ],
  },
];

/**
 * Convierte el nombre de una columna al formato legible del encabezado.
 * @param {string} nombre Nombre recibido desde los resultados.
 * @returns {string} Encabezado con espacios y mayúscula inicial.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
const formatearEncabezado = (nombre) =>
  nombre
    .replace(/_/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/^./, (letra) => letra.toUpperCase());

/**
 * Presenta un valor según su tipo y el nombre de su columna.
 * @param {string} columna Nombre de la columna del reporte.
 * @param {string|number|boolean|Date|null|undefined} valor Valor recibido desde la API.
 * @returns {JSX.Element|string} Valor formateado para la tabla.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
const formatearValor = (columna, valor) => {
  if (valor === null || valor === undefined || valor === "") {
    return (
      // Marcador visual para valores ausentes en los resultados.
      <Typography
        variant="body2"
        className="valor-ausente-reporte"
      >
        N/A
      </Typography>
    );
  }

  if (valor instanceof Date) {
    return valor.toLocaleDateString();
  }

  const nombreColumna = columna.toLowerCase();

  const esMoneda =
    typeof valor === "number" &&
    [
      "monto",
      "precio",
      "ganancia",
      "ventas",
      "facturado",
      "total",
      "comprapromedio",
      "ventapromedio",
    ].some((termino) => nombreColumna.includes(termino));

  if (esMoneda) {
    return (
      // Valor monetario del resultado con formato de moneda.
      <Typography
        variant="body2"
        className="valor-monetario-reporte"
      >
        $
        {Number(valor).toLocaleString(undefined, {
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        })}
      </Typography>
    );
  }

  if (typeof valor === "string" && /^\d{4}-\d{2}-\d{2}/.test(valor)) {
    return new Date(valor).toLocaleDateString();
  }

  return String(valor);
};

/**
 * Renderiza resultados tabulares y controles de paginación del reporte.
 * @param {object} props Filas, página, estado de continuación y manejadores.
 * @returns {JSX.Element} Tabla o estado vacío del reporte.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
function TablaReporteDinamica({
  datos,
  numPaginaActual,
  cantidadFilasPorPagina,
  hayMasFilas,
  onCambiarPagina,
  onCambiarFilasPorPagina,
}) {
  if (!datos?.length) {
    return (
      // Estado vacío cuando el reporte no devuelve filas.
      <Paper
        elevation={0}
        className="estado-vacio-reporte"
      >
        <BarChartIcon className="icono-estado-vacio-reporte" />

        <Typography variant="h6" className="titulo-estado-vacio-reporte">
          No se encontraron datos
        </Typography>

        <Typography variant="body2" className="descripcion-estado-vacio-reporte">
          Ajusta los filtros o genera nuevamente el reporte.
        </Typography>
      </Paper>
    );
  }

  const columnas = Object.keys(datos[0]);

  return (
    // Resultados tabulares del reporte seleccionado.
    <Box>
      {/* Tabla dinámica con las columnas recibidas desde la API. */}
      <TableContainer
        component={Paper}
        elevation={0}
        className="contenedor-tabla-reporte"
      >
        <Table size="medium" className="tabla-reporte">
          <TableHead>
            <TableRow className="encabezado-tabla-reporte">
              {columnas.map((columna) => (
                <TableCell
                  key={columna}
                  className="celda-encabezado-reporte"
                >
                  {formatearEncabezado(columna)}
                </TableCell>
              ))}
            </TableRow>
          </TableHead>

          <TableBody>
            {datos.map((fila, indice) => (
              <TableRow
                key={`${numPaginaActual}-${indice}`}
                hover
                className="fila-tabla-reporte"
              >
                {columnas.map((columna) => (
                  <TableCell
                    key={columna}
                    className="celda-tabla-reporte"
                  >
                    {formatearValor(columna, fila[columna])}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Paginación de las filas del reporte. */}
      <Box className="paginacion-reporte">
        <ControlesPaginacionTabla
          pagina={numPaginaActual}
          filasPorPagina={cantidadFilasPorPagina}
          hayMasFilas={hayMasFilas}
          onCambiarPagina={onCambiarPagina}
          onCambiarFilasPorPagina={onCambiarFilasPorPagina}
        />
      </Box>
    </Box>
  );
}

/**
 * Renderiza un filtro de reporte con búsqueda y opciones configurables.
 * @param {object} props Etiqueta, opciones, valor y manejadores del filtro.
 * @returns {JSX.Element} Campo de filtro.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
function FiltroAutocomplete({
  label,
  value,
  options,
  onChange,
  onInputChange,
  numeric = false,
  freeSolo = true,
}) {
  const opciones = options || [];

  const valorSeleccionado = freeSolo
    ? value || ""
    : (opciones.find(
        (opcion) => String(opcion?.value ?? opcion) === String(value ?? ""),
      ) ?? null);

  return (
    // Campo de filtro con búsqueda libre o selección de opciones sugeridas.
    <Autocomplete
      freeSolo={freeSolo}
      options={opciones}
      filterOptions={(items) => items}
      value={valorSeleccionado}
      onChange={(_, nuevaOpcion) => {
        if (nuevaOpcion === null || nuevaOpcion === undefined) {
          onChange("");
          return;
        }

        const nuevoValor =
          typeof nuevaOpcion === "string"
            ? nuevaOpcion
            : String(nuevaOpcion?.value ?? nuevaOpcion?.label ?? "");

        onChange(nuevoValor);
      }}
      onInputChange={(_, nuevoTexto, motivo) => {
        if (motivo === "clear") {
          if (freeSolo) {
            onInputChange("");
          } else {
            onChange("");
          }

          return;
        }

        if (!freeSolo) {
          return;
        }

        if (numeric && !esEnteroNoNegativo(nuevoTexto)) {
          return;
        }

        onInputChange(nuevoTexto);
      }}
      getOptionLabel={(opcion) =>
        typeof opcion === "string"
          ? opcion
          : (opcion?.label ?? String(opcion?.value ?? ""))
      }
      isOptionEqualToValue={(opcion, seleccion) =>
        String(opcion?.value ?? opcion) ===
        String(seleccion?.value ?? seleccion)
      }
      noOptionsText="Sin opciones"
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          size="small"
          slotProps={{
            ...params.slotProps,
            htmlInput: {
              ...params.slotProps?.htmlInput,
              inputMode: numeric ? "numeric" : "text",
            },
          }}
          className="campo-filtro-reporte"
        />
      )}
    />
  );
}

/**
 * Presenta el centro de reportes, filtros y resultados paginados.
 * @param {object} props Manejadores de notificaciones y control del módulo.
 * @returns {JSX.Element} Interfaz del centro de reportes.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
export default function CentroReportes({
  onErrorNotificacion,
  onErrorOcultarModulo,
}) {
  const [reporteSeleccionadoId, setReporteSeleccionadoId] = useState(null);

  const [datosReporte, setDatosReporte] = useState([]);
  const [hayMasFilas, setHayMasFilas] = useState(false);

  const [filtros, setFiltros] = useState({
    ...FILTROS_INICIALES,
  });

  const [anios, setAnios] = useState([]);

  const [aniosFacturas, setAniosFacturas] = useState([]);

  const [aniosOrdenesCompra, setAniosOrdenesCompra] = useState([]);

  const [numPaginaActual, setNumPaginaActual] = useState(0);

  const [cantidadFilasPorPagina, setCantidadFilasPorPagina] = useState(10);

  const [generando, setGenerando] = useState(false);

  const reporteActual = useMemo(
    () =>
      CONFIG_REPORTES.find((reporte) => reporte.num === reporteSeleccionadoId),
    [reporteSeleccionadoId],
  );

  useEffect(() => {
    /**
     * Carga los años y catálogos requeridos por los filtros de reporte.
     * @returns {Promise<void>} Carga los catálogos para los filtros.
     * @throws {Error} Si ocurre un error no controlado durante la ejecución.
     */
    const cargarCatalogos = async () => {
      try {
        const [aniosData, opcionesReportes] = await Promise.all([
          solicitarJson("/api/reportes/opciones/anios"),
          solicitarJson("/api/reportes/opciones"),
        ]);

        setAnios(
          aniosData.map((item) => ({
            value: String(item.Anio),
            label: String(item.Anio),
          })),
        );

        setAniosFacturas(
          opcionesReportes.aniosFacturas.map((item) => ({
            value: String(item.Anio),
            label: String(item.Anio),
          })),
        );

        setAniosOrdenesCompra(
          opcionesReportes.aniosOrdenesCompra.map((item) => ({
            value: String(item.Anio),
            label: String(item.Anio),
          })),
        );
      } catch (error) {
        mostrarError(
          error,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar opciones de reportes",
        );
      }
    };

    cargarCatalogos();
  }, [onErrorNotificacion, onErrorOcultarModulo]);

  /**
   * Selecciona un reporte y reinicia filtros, filas y paginación.
   * @param {number} id Número del reporte seleccionado.
   * @returns {void} Actualiza el estado del reporte activo.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const seleccionarReporte = (id) => {
    setReporteSeleccionadoId(id);

    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMasFilas(false);

    setNumPaginaActual(0);
  };

  /**
   * Regresa al listado del centro de reportes.
   * @returns {void} Limpia la selección actual del reporte.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const regresarAReportes = () => {
    setReporteSeleccionadoId(null);

    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMasFilas(false);

    setNumPaginaActual(0);
  };

  /**
   * Actualiza el valor de un filtro del reporte.
   * @param {string} campo Clave del filtro que cambia.
   * @param {string|number} valor Nuevo valor seleccionado o escrito.
   * @returns {void} Actualiza el estado de filtros.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const actualizarFiltro = (campo, valor) => {
    setFiltros((prev) => ({
      ...prev,
      [campo]: valor,
    }));
  };

  /**
   * Ejecuta el reporte seleccionado.
   *
   * @param {number} paginaSolicitada Número base cero de la página.
   * @param {number} filasSolicitadas Cantidad de filas que se solicitarán.
   * @returns {Promise<void>} Actualiza los resultados del reporte.
   * @throws {Error} Los errores de validación o solicitud se muestran en la interfaz.
   */
  const cargarReporte = async (
    paginaSolicitada = 0,
    filasSolicitadas = cantidadFilasPorPagina,
  ) => {
    if (!reporteActual) {
      return;
    }

    const filtrosAnio = reporteActual.inputs.filter((input) =>
      ["anio", "anioInicio", "anioFin"].includes(input.campo),
    );

    const anioInvalido = filtrosAnio.some((input) => {
      const valor = filtros[input.campo];
      const opcionesAnios = obtenerOpciones(input.source);
      return (
        valor &&
        input.tipo === "opciones" &&
        !opcionesAnios.some((opcion) => String(opcion.value) === String(valor))
      );
    });

    if (anioInvalido) {
      const error = new Error(
        "Seleccione años válidos presentes en los datos del reporte.",
      );

      mostrarError(error, onErrorNotificacion, onErrorOcultarModulo);

      return;
    }

    if (
      filtros.anioInicio &&
      filtros.anioFin &&
      Number(filtros.anioInicio) > Number(filtros.anioFin)
    ) {
      const error = new Error(
        "El año inicial no puede ser mayor que el año final.",
      );

      mostrarError(error, onErrorNotificacion, onErrorOcultarModulo);

      return;
    }

    if (filtros.mes) {
      const mes = Number(filtros.mes);

      if (!Number.isInteger(mes) || mes < 1 || mes > 12) {
        const error = new Error(
          "El mes debe ser un número entero entre 1 y 12.",
        );

        mostrarError(error, onErrorNotificacion, onErrorOcultarModulo);

        return;
      }
    }

    setGenerando(true);

    try {
      const parametros = {};

      reporteActual.inputs.forEach((input) => {
        parametros[input.campo] = filtros[input.campo];
      });
      parametros.pagina = paginaSolicitada;
      parametros.filasPorPagina = filasSolicitadas;

      const data = await solicitarJson(
        `/api/reportes/${reporteActual.num}${construirQuery(parametros)}`,
      );

      setDatosReporte(Array.isArray(data.datos) ? data.datos : []);
      setHayMasFilas(data.hayMasFilas);
      setNumPaginaActual(paginaSolicitada);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        `Error al generar el reporte ${reporteActual.num}`,
      );
    } finally {
      setGenerando(false);
    }
  };

  /**
   * Restablece los filtros y limpia los resultados del reporte.
   * @returns {void} Reinicia los valores del formulario y la paginación.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const restaurarFiltros = () => {
    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMasFilas(false);

    setNumPaginaActual(0);
  };

  /**
   * Devuelve el catálogo asociado al filtro indicado.
   * @param {string} source Nombre del catálogo configurado.
   * @returns {object[]} Opciones disponibles para el filtro.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const obtenerOpciones = (source) => {
    const fuentes = {
      anios,
      aniosFacturas,
      aniosOrdenesCompra,
      meses: MESES,
    };

    return fuentes[source] || [];
  };

  /**
   * Renderiza el control apropiado para un filtro configurado.
   * @param {object} input Configuración del campo de filtro.
   * @returns {JSX.Element} Control de filtro.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const renderFiltro = (input) => {
    if (input.catalogo) {
      const valor = filtros[input.campo];
      return (
        <AutocompletePaginado
          key={input.campo}
          catalogo={input.catalogo}
          etiqueta={input.label}
          valor={valor}
          modoTexto={input.tipo !== "opciones"}
          size="small"
          className="campo-filtro-reporte"
          onChange={(nuevoValor) =>
            actualizarFiltro(
              input.campo,
              input.tipo === "opciones"
                ? String(nuevoValor?.id ?? "")
                : nuevoValor,
            )
          }
        />
      );
    }

    const opciones = obtenerOpciones(input.source);

    return (
      <FiltroAutocomplete
        key={input.campo}
        label={input.label}
        value={filtros[input.campo]}
        options={opciones}
        numeric={input.tipo === "entero"}
        onChange={(valor) => actualizarFiltro(input.campo, valor)}
        onInputChange={(valor) => actualizarFiltro(input.campo, valor)}
        freeSolo={input.tipo !== "opciones"}
      />
    );
  };

  return (
    // Presentación y descripción del centro de reportes.
    <ModuloInterfazBase
      titulo="Reportes y datos estadísticos"
      descripcion="Consulta los indicadores directamente calculados por SQL Server"
      Icono={QueryStatsOutlinedIcon}
      onVolver={reporteActual ? regresarAReportes : undefined}
      textoBotonVolver="Volver al centro de reportes"
      ocultarBotonNuevo
    >
      <Box className="contenedor-centro-reportes">
        {!reporteActual ? (
          <>
            {/* Tarjeta introductoria del centro de reportes. */}
            <Paper elevation={0} className="tarjeta-presentacion-reportes">
              <Stack direction="row" spacing={1.5} sx={{alignItems: "center", mb: 1}}>
                <Box className="icono-centro-reportes">
                  <AssessmentIcon aria-hidden="true" />
                </Box>

                <Box>
                  <Typography variant="h6" className="titulo-presentacion-reportes">
                    Centro de reportes
                  </Typography>

                  <Typography variant="body2" className="descripcion-presentacion-reportes">
                    Selecciona el análisis que deseas ejecutar y después aplica
                    sus filtros.
                  </Typography>
                </Box>
              </Stack>
            </Paper>

            {/* Botones para abrir cada reporte. */}
            <Box className="cuadricula-tarjetas-reporte">
              {CONFIG_REPORTES.map((reporte) => {
                const Icono = reporte.Icono;

                return (
                  <Card
                    key={reporte.num}
                    elevation={0}
                    className="tarjeta-reporte"
                  >
                    <CardActionArea
                      onClick={() => seleccionarReporte(reporte.num)}
                      className="area-tarjeta-reporte"
                    >
                      <Stack className="fila-contenido-tarjeta-reporte">
                        <Box className="icono-tarjeta-reporte">
                          <Icono aria-hidden="true" />
                        </Box>

                        <Box>
                          <Typography variant="caption" className="numero-tarjeta-reporte">
                            REPORTE {reporte.num}
                          </Typography>

                          <Typography variant="subtitle1" className="titulo-tarjeta-reporte">
                            {reporte.label}
                          </Typography>

                          <Typography variant="body2" className="descripcion-tarjeta-reporte">
                            {reporte.desc}
                          </Typography>
                        </Box>
                      </Stack>

                      <Stack direction="row" className="pie-tarjeta-reporte">
                        <Chip
                          size="small"
                          label={reporte.etiqueta}
                          className="etiqueta-tarjeta-reporte"
                        />
                        <Stack direction="row" className="accion-tarjeta-reporte">
                          Ver reporte
                          <OpenInNewIcon className="icono-abrir" />
                        </Stack>
                      </Stack>
                    </CardActionArea>
                  </Card>
                );
              })}
            </Box>
          </>
        ) : (
          // Vista del reporte seleccionado, sus filtros y sus resultados.
          <Paper
            elevation={0}
            className="panel-detalle-reporte"
          >
            <Box className="encabezado-detalle-reporte">
              {/* Navegación de regreso y título del reporte activo. */}
              <Stack direction="row" spacing={1.5} className="boton-volver-numero-reporte">
                <Chip
                  label={`Reporte ${reporteActual.num}`}
                  size="small"
                  className="numero-detalle-reporte"
                />
              </Stack>

              <Stack direction="row" spacing={1.5} className="titulo-detalle-reporte">
                <Box className="icono-detalle-reporte">
                  <reporteActual.Icono aria-hidden="true" />
                </Box>

                <Box>
                  <Typography variant="h5" className="nombre-detalle-reporte">
                    {reporteActual.label}
                  </Typography>

                  <Typography variant="body2" className="descripcion-detalle-reporte">
                    {reporteActual.desc}
                  </Typography>
                </Box>
              </Stack>
            </Box>

            <Divider />

            <Box className="seccion-filtros-reporte">
              {/* Filtros y acciones para generar el reporte. */}
              {reporteActual.inputs.length > 0 ? (
                <Box className="panel-filtros-reporte">
                  <Typography variant="subtitle1" className="titulo-filtros-reporte">
                    Filtros del reporte
                  </Typography>

                  <Box
                    className={`cuadricula-filtros-reporte columnas-filtros-${Math.min(reporteActual.inputs.length, 4)}`}
                  >
                    {reporteActual.inputs.map(renderFiltro)}
                  </Box>

                  <Stack className="acciones-filtros-reporte">
                    <Button
                      variant="outlined"
                      startIcon={<RestartAltIcon />}
                      onClick={restaurarFiltros}
                      disabled={generando}
                      className="boton-limpiar-reporte"
                    >
                      Limpiar
                    </Button>

                    <Button
                      variant="contained"
                      startIcon={<SearchIcon />}
                      onClick={() => cargarReporte()}
                      disabled={generando}
                      className="boton-generar-reporte"
                    >
                      {generando ? "Generando…" : "Generar reporte"}
                    </Button>
                  </Stack>
                </Box>
              ) : (
                <Stack className="acciones-filtros-reporte acciones-sin-filtros-reporte">
                  <Button
                    variant="contained"
                    startIcon={<SearchIcon />}
                    onClick={() => cargarReporte()}
                    disabled={generando}
                    className="boton-generar-reporte"
                  >
                    {generando ? "Generando…" : "Generar reporte"}
                  </Button>
                </Stack>
              )}
            </Box>

            <Divider />

            <Box className="seccion-resultados-reporte">
              {/* Cantidad de resultados y tabla de datos devueltos. */}
              <Stack direction={{xs: "column", sm: "row"}} spacing={1}>
                <Box>
                  <Typography variant="h6" className="titulo-resultados-reporte">
                    Resultados
                  </Typography>

                  <Typography variant="body2" className="descripcion-resultados-reporte">
                    Información devuelta directamente por la base de datos.
                  </Typography>
                </Box>
              </Stack>

              <TablaReporteDinamica
                datos={datosReporte}
                numPaginaActual={numPaginaActual}
                cantidadFilasPorPagina={cantidadFilasPorPagina}
                hayMasFilas={hayMasFilas}
                onCambiarPagina={(_, pagina) => cargarReporte(pagina)}
                onCambiarFilasPorPagina={(nuevoTamano) => {
                  setCantidadFilasPorPagina(nuevoTamano);
                  cargarReporte(0, nuevoTamano);
                }}
              />
            </Box>
          </Paper>
        )}
      </Box>
    </ModuloInterfazBase>
  );
}
