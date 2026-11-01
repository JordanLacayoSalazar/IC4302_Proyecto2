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
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import TrendingUpIcon from "@mui/icons-material/TrendingUp";
import InventoryIcon from "@mui/icons-material/Inventory";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import PersonSearchIcon from '@mui/icons-material/PersonSearch';
import LeaderboardIcon from '@mui/icons-material/Leaderboard';
import ReceiptLongIcon from '@mui/icons-material/ReceiptLong';
import HandshakeIcon from '@mui/icons-material/Handshake';
import SendIcon from '@mui/icons-material/Send';

import ControlesPaginacionTabla from "../../components/ControlesPaginacionTabla";
import AutocompletePaginado from "../../components/AutocompletePaginado";
import ModuloInterfazBase from "../../components/ModuloInterfazBase";
import { mostrarError } from "../../components/ModuloHerramientas";
import {
  construirQuery,
  esEnteroNoNegativo,
  solicitarJson,
} from "../../components/apiHerramientas";

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
    inputs: [],
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

const formatearEncabezado = (nombre) =>
  nombre
    .replace(/_/g, " ")
    .replace(/([a-z])([A-Z])/g, "$1 $2")
    .replace(/^./, (letra) => letra.toUpperCase());

const formatearValor = (columna, valor) => {
  if (valor === null || valor === undefined || valor === "") {
    return (
      // Marcador visual para valores ausentes en los resultados.
      <Typography
        variant="body2"
        sx={{
          color: "#94a3b8",
          fontStyle: "italic",
        }}
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
    ["monto", "precio", "ganancia", "ventas", "facturado", "total"].some(
      (termino) => nombreColumna.includes(termino),
    );

  if (esMoneda) {
    return (
      // Valor monetario del resultado con formato de moneda.
      <Typography
        variant="body2"
        sx={{
          fontWeight: 700,
          color: "#047857",
        }}
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

function TablaReporteDinamica({
  datos,
  numPaginaActual,
  cantidadFilasPorPagina,
  hayMas,
  onCambiarPagina,
  onCambiarFilasPorPagina,
}) {
  if (!datos?.length) {
    return (
      // Estado vacío cuando el reporte no devuelve filas.
      <Paper
        elevation={0}
        sx={{
          py: 8,
          mt: 2,
          textAlign: "center",
          backgroundColor: "#f8fafc",
          borderRadius: 3,
          border: "1px dashed #cbd5e1",
        }}
      >
        <BarChartIcon
          sx={{
            fontSize: 64,
            color: "#cbd5e1",
            mb: 2,
          }}
        />

        <Typography
          variant="h6"
          sx={{
            color: "#475569",
            fontWeight: 700,
          }}
        >
          No se encontraron datos
        </Typography>

        <Typography
          variant="body2"
          sx={{
            color: "#94a3b8",
            mt: 0.5,
          }}
        >
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
        sx={{
          border: "1px solid #e2e8f0",
          borderRadius: 3,
          overflow: "auto",
          mt: 3,
        }}
      >
        <Table
          size="medium"
          sx={{
            minWidth: 760,
          }}
        >
          <TableHead>
            <TableRow
              sx={{
                backgroundColor: "#f1f5f9",
              }}
            >
              {columnas.map((columna) => (
                <TableCell
                  key={columna}
                  sx={{
                    fontWeight: 700,
                    color: "#334155",
                    py: 1.8,
                    whiteSpace: "nowrap",
                    textTransform: "uppercase",
                    fontSize: "0.75rem",
                    letterSpacing: "0.45px",
                  }}
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
                sx={{
                  "&:last-child td": {
                    borderBottom: 0,
                  },
                  "&:nth-of-type(even)": {
                    backgroundColor: "#fafafa",
                  },
                }}
              >
                {columnas.map((columna) => (
                  <TableCell
                    key={columna}
                    sx={{
                      color: "#1e293b",
                      py: 1.7,
                    }}
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
      <Box sx={{ mt: 2 }}>
        <ControlesPaginacionTabla
          pagina={numPaginaActual}
          filasPorPagina={cantidadFilasPorPagina}
          hayMas={hayMas}
          onCambiarPagina={onCambiarPagina}
          onCambiarFilasPorPagina={onCambiarFilasPorPagina}
        />
      </Box>
    </Box>
  );
}

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
          sx={{
            backgroundColor: "white",
          }}
        />
      )}
    />
  );
}

export default function Reportes({
  onErrorNotificacion,
  onErrorOcultarModulo,
}) {
  const [reporteSeleccionadoId, setReporteSeleccionadoId] = useState(null);

  const [datosReporte, setDatosReporte] = useState([]);
  const [hayMas, setHayMas] = useState(false);

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

  const seleccionarReporte = (id) => {
    setReporteSeleccionadoId(id);

    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMas(false);

    setNumPaginaActual(0);
  };

  const regresarAReportes = () => {
    setReporteSeleccionadoId(null);

    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMas(false);

    setNumPaginaActual(0);
  };

  const actualizarFiltro = (campo, valor) => {
    setFiltros((prev) => ({
      ...prev,
      [campo]: valor,
    }));
  };

  /**
   * Ejecuta el reporte seleccionado.
   *
   * El frontend únicamente arma los parámetros.
   * Los cálculos y transformaciones se mantienen
   * en SQL Server.
   * @param {number} paginaSolicitada Número base cero de la página.
   * @param {number} filasSolicitadas Cantidad de filas que se solicitarán.
   * @returns {Promise<void>} Actualiza los resultados del reporte.
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
        !opcionesAnios.some((opcion) => String(opcion.value) === String(valor))
      );
    });

    if (anioInvalido) {
      const error = new Error(
        "Selecciona años válidos presentes en los datos del reporte.",
      );

      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
      );

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

      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
      );

      return;
    }

    if (filtros.mes) {
      const mes = Number(filtros.mes);

      if (!Number.isInteger(mes) || mes < 1 || mes > 12) {
        const error = new Error(
          "El mes debe ser un número entero entre 1 y 12.",
        );

        mostrarError(
          error,
          onErrorNotificacion,
          onErrorOcultarModulo,
        );

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
      setHayMas(data.hayMas);
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

  const restaurarFiltros = () => {
    setFiltros({
      ...FILTROS_INICIALES,
    });

    setDatosReporte([]);
    setHayMas(false);

    setNumPaginaActual(0);
  };

  const obtenerOpciones = (source) => {
    const fuentes = {
      anios,
      aniosFacturas,
      aniosOrdenesCompra,
      meses: MESES,
    };

    return fuentes[source] || [];
  };

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
          sx={{ backgroundColor: "white" }}
          onChange={(nuevoValor) =>
            actualizarFiltro(
              input.campo,
              input.tipo === "opciones" ? String(nuevoValor?.id ?? "") : nuevoValor,
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
    <ModuloInterfazBase
      titulo="Reportes y datos estadísticos"
      descripcion="Consulta los indicadores directamente calculados por SQL Server"
      Icono={QueryStatsOutlinedIcon}
      ocultarBotonNuevo
    >
      <Box
        sx={{
          fontFamily: '"Roboto", "Helvetica", "Arial", sans-serif',
          p: {
            xs: 2.5,
            md: 3,
          },
        }}
      >
        {!reporteActual ? (
          <>
            {/* Presentación y descripción del centro de reportes. */}
            <Paper
              elevation={0}
              sx={{
                p: {
                  xs: 2.5,
                  md: 3,
                },
                mb: 3,
                borderRadius: 3,
                border: "1px solid #e2e8f0",
                background: "linear-gradient(135deg, #edf2ef 0%, #ffffff 65%)",
              }}
            >
              <Stack
                direction="row"
                spacing={1.5}
                sx={{
                  alignItems: "center",
                  mb: 1,
                }}
              >
                <Box className="icono-centro-reportes">
                  <AssessmentIcon />
                </Box>

                <Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: "#0f172a",
                    }}
                  >
                    Centro de reportes
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: "#64748b",
                    }}
                  >
                    Selecciona el análisis que deseas ejecutar y después aplica
                    sus filtros.
                  </Typography>
                </Box>
              </Stack>
            </Paper>

            {/* Tarjetas disponibles para abrir cada reporte. */}
            <Box
              sx={{
                display: "grid",
                gridTemplateColumns: {
                  xs: "1fr",
                  sm: "1fr 1fr",
                  lg: "repeat(3, 1fr)",
                },
                gap: 2,
              }}
            >
              {CONFIG_REPORTES.map((reporte) => {
                const Icono = reporte.Icono;

                return (
                  <Card
                    key={reporte.num}
                    elevation={0}
                    sx={{
                      borderRadius: 3,
                      border: "1px solid #e2e8f0",
                      transition: "all 0.2s ease",
                      "&:hover": {
                        transform: "translateY(-2px)",
                        borderColor: "#284272",
                        boxShadow: "0 8px 24px rgba(15, 23, 42, 0.08)",
                      },
                    }}
                  >
                    <CardActionArea
                      onClick={() => seleccionarReporte(reporte.num)}
                      sx={{
                        height: "100%",
                        p: 2.3,
                        textAlign: "left",
                      }}
                    >
                      <Stack
                        direction="row"
                        spacing={1.5}
                        sx={{
                          alignItems: "flex-start",
                        }}
                      >
                        <Box className="icono-tarjeta-reporte">
                          <Icono />
                        </Box>

                        <Box>
                          <Typography
                            variant="caption"
                            sx={{
                              color: "#284272",
                              fontWeight: 700,
                            }}
                          >
                            REPORTE {reporte.num}
                          </Typography>

                          <Typography
                            variant="subtitle1"
                            sx={{
                              mt: 0.35,
                              fontWeight: 700,
                              color: "#0f172a",
                            }}
                          >
                            {reporte.label}
                          </Typography>

                          <Typography
                            variant="body2"
                            sx={{
                              color: "#64748b",
                              mt: 0.5,
                              lineHeight: 1.55,
                            }}
                          >
                            {reporte.desc}
                          </Typography>
                        </Box>
                      </Stack>

                      <Stack
                        direction="row"
                        spacing={1}
                        sx={{
                          alignItems: "center",
                          mt: 2,
                          justifyContent: "space-between",
                        }}
                      >
                        <Chip
                          size="small"
                          label={reporte.etiqueta}
                          sx={{
                            backgroundColor: "#f8fafc",
                            color: "#475569",
                            fontWeight: 700,
                          }}
                        />
                        <Stack
                          direction="row"
                          spacing={1}
                          sx={{
                            alignItems: "center",
                            color: "#284272",
                            fontSize: 13,
                            fontWeight: 700,
                            whiteSpace: "nowrap",
                          }}
                        >
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
            sx={{
              borderRadius: 3,
              border: "1px solid #e2e8f0",
              overflow: "hidden",
            }}
          >
            <Box
              sx={{
                p: {
                  xs: 2.5,
                  md: 3,
                },
                backgroundColor: "#f8fafc",
              }}
            >
              {/* Navegación de regreso y título del reporte activo. */}
              <Stack
                direction="row"
                spacing={1.5}
                sx={{
                  alignItems: "center",
                  mb: 2,
                }}
              >
                <Button
                  className="boton-volver-reportes"
                  startIcon={<ArrowBackIcon />}
                  onClick={regresarAReportes}
                >
                  Reportes
                </Button>

                <Chip
                  label={`Reporte ${reporteActual.num}`}
                  size="small"
                  sx={{
                    fontWeight: 700,
                  }}
                />
              </Stack>

              <Stack
                direction="row"
                spacing={1.5}
                sx={{
                  alignItems: "flex-start",
                }}
              >
                <Box
                  sx={{
                    width: 46,
                    height: 46,
                    borderRadius: 2,
                    flexShrink: 0,
                    display: "grid",
                    placeItems: "center",
                    backgroundColor: "#284272",
                    color: "#ffffff",
                  }}
                >
                  <reporteActual.Icono />
                </Box>

                <Box>
                  <Typography
                    variant="h5"
                    sx={{
                      fontWeight: 700,
                      color: "#0f172a",
                    }}
                  >
                    {reporteActual.label}
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: "#64748b",
                      mt: 0.5,
                    }}
                  >
                    {reporteActual.desc} Los filtros se resuelven en el
                    procedimiento almacenado correspondiente.
                  </Typography>
                </Box>
              </Stack>
            </Box>

            <Divider />

            <Box
              sx={{
                p: {
                  xs: 2.5,
                  md: 3,
                },
              }}
            >
              {/* Filtros y acciones para generar el reporte. */}
              {reporteActual.inputs.length > 0 ? (
                <Box
                  sx={{
                    p: 2.2,
                    borderRadius: 3,
                    backgroundColor: "#f8fafc",
                    border: "1px solid #e2e8f0",
                  }}
                >
                  <Typography
                    variant="subtitle1"
                    sx={{
                      fontWeight: 700,
                      color: "#1e293b",
                      mb: 2,
                    }}
                  >
                    Filtros del reporte
                  </Typography>

                  <Box
                    sx={{
                      display: "grid",
                      gridTemplateColumns: {
                        xs: "1fr",
                        md: `repeat(${Math.min(
                          reporteActual.inputs.length,
                          4,
                        )}, minmax(0, 1fr))`,
                      },
                      gap: 1.5,
                    }}
                  >
                    {reporteActual.inputs.map(renderFiltro)}
                  </Box>

                  <Stack
                    direction={{
                      xs: "column",
                      sm: "row",
                    }}
                    spacing={1.2}
                    sx={{
                      justifyContent: "flex-end",
                      mt: 2,
                    }}
                  >
                    <Button
                      variant="outlined"
                      startIcon={<RestartAltIcon />}
                      onClick={restaurarFiltros}
                      disabled={generando}
                      sx={{
                        textTransform: "none",
                        borderRadius: 2,
                        fontWeight: 700,
                        borderColor: "#284272",
                        color: "#284272",
                      }}
                    >
                      Limpiar
                    </Button>

                    <Button
                      variant="contained"
                      startIcon={<SearchIcon />}
                      onClick={() => cargarReporte()}
                      disabled={generando}
                      sx={{
                        textTransform: "none",
                        borderRadius: 2,
                        fontWeight: 600,
                        px: 3,
                        boxShadow: "none",
                        backgroundColor: "#284272",
                        "&:hover": { backgroundColor: "#1d3158", boxShadow: "none" },
                      }}
                    >
                      {generando ? "Generando…" : "Generar reporte"}
                    </Button>
                  </Stack>
                </Box>
              ) : (
                <Stack
                  direction="row"
                  spacing={1.2}
                  sx={{
                    justifyContent: "flex-end",
                  }}
                >
                  <Button
                    variant="contained"
                    startIcon={<SearchIcon />}
                    onClick={() => cargarReporte()}
                    disabled={generando}
                    sx={{
                      textTransform: "none",
                      borderRadius: 2,
                      fontWeight: 600,
                      boxShadow: "none",
                      backgroundColor: "#284272",
                      "&:hover": { backgroundColor: "#1d3158", boxShadow: "none" },
                    }}
                  >
                    {generando ? "Generando…" : "Generar reporte"}
                  </Button>
                </Stack>
              )}
            </Box>

            <Divider />

            <Box
              sx={{
                p: {
                  xs: 2.5,
                  md: 3,
                },
              }}
            >
              {/* Cantidad de resultados y tabla de datos devueltos. */}
              <Stack
                direction={{
                  xs: "column",
                  sm: "row",
                }}
                spacing={1}
                sx={{
                  alignItems: {
                    xs: "flex-start",
                    sm: "center",
                  },
                  justifyContent: "space-between",
                }}
              >
                <Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: "#0f172a",
                    }}
                  >
                    Resultados
                  </Typography>

                  <Typography
                    variant="body2"
                    sx={{
                      color: "#64748b",
                      mt: 0.3,
                    }}
                  >
                    Información devuelta directamente por la base de datos.
                  </Typography>
                </Box>

              </Stack>

              <TablaReporteDinamica
                datos={datosReporte}
                numPaginaActual={numPaginaActual}
                cantidadFilasPorPagina={cantidadFilasPorPagina}
                hayMas={hayMas}
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
