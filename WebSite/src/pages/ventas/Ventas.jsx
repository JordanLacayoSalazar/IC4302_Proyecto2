import { useEffect, useState } from "react";
import {
  Box,
  Button,
  IconButton,
  MenuItem,
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
import PointOfSaleIcon from "@mui/icons-material/PointOfSale";
import SearchIcon from "@mui/icons-material/Search";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import AddIcon from "@mui/icons-material/Add";
import ReceiptLongIcon from "@mui/icons-material/ReceiptLong";
import ControlesPaginacionTabla from "../../components/ControlesPaginacionTabla";
import ModuloInterfazBase from "../../components/ModuloInterfazBase";
import { mostrarError } from "../../components/ModuloHerramientas";
import {
  construirQuery,
  solicitarJson,
} from "../../components/apiHerramientas";
import ModalDetallesVenta from "./ModalDetallesVenta";
import ModalFormularioVentas from "./ModalFormularioVentas";
import ModalDetallesCliente from "../clientes/ModalDetallesCliente";
import ModalDetallesProducto from "../inventario/ModalDetallesProducto";

const FILTROS_INICIALES = {
  numeroFactura: "",
  nombreCliente: "",
  metodoEntregaId: "",
  fechaInicio: "",
  fechaFin: "",
  montoMinimo: "",
  montoMaximo: "",
};

/**
 * Formatea fechas SQL YYYY-MM-DD sin desplazarlas por zona horaria.
 * @param {string|Date|null|undefined} fecha Fecha recibida de la API.
 * @returns {string} Fecha local legible o N/A.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
const formatearFecha = (fecha) => {
  if (!fecha) return "N/A";
  const texto = String(fecha);
  const partes = /^(\d{4})-(\d{2})-(\d{2})/.exec(texto);
  const fechaLocal = partes
    ? new Date(Number(partes[1]), Number(partes[2]) - 1, Number(partes[3]))
    : new Date(fecha);
  return fechaLocal.toLocaleDateString();
};

/**
 * Presenta el listado, filtros y formularios del módulo de ventas.
 * @param {object} props Manejadores globales de errores.
 * @param {Function} props.onErrorNotificacion Notifica errores al usuario.
 * @param {Function} props.onErrorOcultarModulo Oculta el módulo ante errores críticos.
 * @param {Function} props.onVolverCentroGestion Regresa al centro de gestión.
 * @returns {JSX.Element} Interfaz de administración de ventas.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
export default function Ventas({
  onErrorNotificacion,
  onErrorOcultarModulo,
  onVolverCentroGestion,
}) {
  const [ventas, setVentas] = useState([]);
  const [opciones, setOpciones] = useState({
    metodosEntrega: [],
  });
  const [filtros, setFiltros] = useState(FILTROS_INICIALES);
  const [pagina, setPagina] = useState(0);
  const [filasPorPagina, setFilasPorPagina] = useState(5);
  const [hayMasFilas, setHayMasFilas] = useState(false);
  const [ventaSeleccionada, setVentaSeleccionada] = useState(null);
  const [detalleAbierto, setDetalleAbierto] = useState(false);
  const [clienteRelacionado, setClienteRelacionado] = useState(null);
  const [productoRelacionado, setProductoRelacionado] = useState(null);
  const [formularioAbierto, setFormularioAbierto] = useState(false);
  const [ventaEnEdicion, setVentaEnEdicion] = useState(null);
  const [versionFormulario, setVersionFormulario] = useState(0);

  /**
   * Solicita las ventas según filtros y actualiza la tabla.
   * @param {object} criterios Valores de filtro para la consulta.
   * @param {number} [paginaSolicitada=0] Índice base cero de la página.
   * @param {number} [filasSolicitadas=filasPorPagina] Cantidad de filas.
   * @returns {Promise<void>} Actualiza los resultados y la paginación.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const fetchVentas = async (
    criterios = FILTROS_INICIALES,
    paginaSolicitada = 0,
    filasSolicitadas = filasPorPagina,
  ) => {
    try {
      const resultado = await solicitarJson(
        `/api/ventas${construirQuery({
          ...criterios,
          pagina: paginaSolicitada,
          filasPorPagina: filasSolicitadas,
        })}`,
      );
      setVentas(resultado.datos);
      setHayMasFilas(resultado.hayMasFilas);
      setPagina(paginaSolicitada);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar ventas",
      );
    }
  };

  useEffect(() => {
    let activo = true;
    /**
     * Cargar Datos.
     * @returns {Promise<void>} Carga la primera página de ventas.
     * @throws {Error} Si ocurre un error no controlado durante la ejecución.
     */
    const cargarDatos = async () => {
      const [resultadoVentas, resultadoOpciones] = await Promise.allSettled([
        solicitarJson("/api/ventas"),
        solicitarJson("/api/ventas/opciones"),
      ]);
      if (!activo) return;

      if (resultadoVentas.status === "fulfilled") {
        setVentas(resultadoVentas.value.datos);
        setHayMasFilas(resultadoVentas.value.hayMasFilas);
      } else {
        mostrarError(
          resultadoVentas.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar ventas",
        );
      }

      if (resultadoOpciones.status === "fulfilled") {
        setOpciones(resultadoOpciones.value);
      } else {
        mostrarError(
          resultadoOpciones.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar opciones de ventas",
        );
      }
    };
    cargarDatos();
    return () => {
      activo = false;
    };
  }, [onErrorNotificacion, onErrorOcultarModulo]);

  /**
   * Limpia todos los filtros y vuelve a cargar la lista completa.
   * @returns {void} Restablece los valores y consulta la primera página.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const restaurarFiltros = () => {
    setFiltros(FILTROS_INICIALES);
    fetchVentas(FILTROS_INICIALES);
  };

  /**
   * Carga el encabezado y las líneas para mostrar el detalle de una venta.
   * @param {number} invoiceId Identificador de la factura.
   * @returns {Promise<void>} Abre el detalle o notifica el error.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirDetalle = async (invoiceId) => {
    try {
      setVentaSeleccionada(await solicitarJson(`/api/ventas/${invoiceId}`));
      setDetalleAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el detalle de la venta",
      );
    }
  };

  /**
   * Abre el detalle del cliente relacionado con la venta.
   * @param {number} customerId Identificador del cliente.
   * @returns {Promise<void>} Carga y muestra el detalle del cliente.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirClienteRelacionado = async (customerId) => {
    try {
      setClienteRelacionado(
        await solicitarJson(`/api/clientes/${customerId}`),
      );
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el detalle del cliente de la venta",
      );
    }
  };

  /**
   * Abre el detalle del producto relacionado con una línea.
   * @param {number} stockItemId Identificador del producto.
   * @returns {Promise<void>} Carga y muestra el detalle del producto.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirProductoRelacionado = async (stockItemId) => {
    try {
      setProductoRelacionado(
        await solicitarJson(`/api/inventario/${stockItemId}`),
      );
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el detalle del producto de la venta",
      );
    }
  };

  /**
   * Abre el formulario para crear una factura.
   * @returns {void} Reinicia el formulario y muestra el modal.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirVentaNueva = () => {
    setVentaEnEdicion(null);
    setVersionFormulario((actual) => actual + 1);
    setFormularioAbierto(true);
  };

  /**
   * Carga el detalle completo antes de abrir una venta para edición.
   * @param {number} invoiceId Identificador de la factura.
   * @returns {Promise<void>} Abre el formulario de edición.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirEdicion = async (invoiceId) => {
    try {
      setVentaEnEdicion(await solicitarJson(`/api/ventas/${invoiceId}`));
      setVersionFormulario((actual) => actual + 1);
      setFormularioAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar la venta para editar",
      );
    }
  };

  /**
   * Guarda encabezado y líneas, dejando identificadas las líneas ya persistidas
   * para que un guardado parcial pueda reintentarse sin duplicarlas.
   * @param {object} borrador Encabezado, ID existente opcional y líneas.
   * @returns {Promise<object>} Resultado y filas de línea con IDs actualizados.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const guardarVenta = async (borrador) => {
    let invoiceId = borrador.invoiceId;
    const lineasGuardadas = borrador.lineas.map((linea) => ({ ...linea }));

    try {
      if (invoiceId) {
        await solicitarJson(`/api/ventas/${invoiceId}`, {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(borrador.encabezado),
        });
      } else {
        const resultado = await solicitarJson("/api/ventas", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(borrador.encabezado),
        });
        invoiceId = resultado.NumeroFactura;
      }

      for (let indice = 0; indice < lineasGuardadas.length; indice += 1) {
        const linea = lineasGuardadas[indice];
        const ruta = linea.InvoiceLineID
          ? `/api/ventas/${invoiceId}/lineas/${linea.InvoiceLineID}`
          : `/api/ventas/${invoiceId}/lineas`;
        const resultado = await solicitarJson(ruta, {
          method: linea.InvoiceLineID ? "PUT" : "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(linea),
        });
        if (!linea.InvoiceLineID) {
          lineasGuardadas[indice].InvoiceLineID = resultado.InvoiceLineID;
        }
      }

      await fetchVentas(filtros);
      return { completo: true, invoiceId, lineas: lineasGuardadas };
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al guardar la venta",
      );
      if (invoiceId) {
        await fetchVentas(filtros);
      }
      return { completo: false, invoiceId, lineas: lineasGuardadas };
    }
  };

  let filas;
  if (ventas.length) {
    filas = ventas.map((venta) => (
      <TableRow
        key={venta.NumeroFactura}
        hover
        onClick={() => abrirDetalle(venta.NumeroFactura)}
        onKeyDown={(event) => {
          if (
            event.target === event.currentTarget &&
            (event.key === "Enter" || event.key === " ")
          ) {
            event.preventDefault();
            abrirDetalle(venta.NumeroFactura);
          }
        }}
        tabIndex={0}
        role="button"
        aria-label={`Ver detalles de la factura ${venta.NumeroFactura}`}
        sx={{ cursor: "pointer" }}
      >
        <TableCell>
          <Typography sx={{ fontWeight: 700, color: "#1e293b" }}>
            {venta.NumeroFactura}
          </Typography>
        </TableCell>
        <TableCell>
          {formatearFecha(venta.FechaFactura)}
        </TableCell>
        <TableCell>{venta.Cliente || "N/A"}</TableCell>
        <TableCell>{venta.MetodoEntrega || "N/A"}</TableCell>
        <TableCell align="left" sx={{ color: "#047857", fontWeight: 700 }}>
          {`$${Number(venta.Monto || 0).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
          })}`}
        </TableCell>
        <TableCell align="center">
          <IconButton
            size="small"
            title="Ver detalles de la factura"
            aria-label={`Ver detalles de la factura ${venta.NumeroFactura}`}
            onClick={(event) => {
              event.stopPropagation();
              abrirDetalle(venta.NumeroFactura);
            }}
            sx={{ color: "#2563eb", backgroundColor: "#eff6ff" }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            title="Editar venta"
            onClick={(event) => {
              event.stopPropagation();
              abrirEdicion(venta.NumeroFactura);
            }}
            sx={{ color: "#d97706", backgroundColor: "#fffbeb", ml: 1 }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
        </TableCell>
      </TableRow>
    ));
  } else {
    filas = (
      <TableRow>
        <TableCell colSpan={6} align="center" sx={{ py: 7 }}>
          <PointOfSaleIcon sx={{ fontSize: 50, color: "#cbd5e1" }} />
          <Typography variant="h6" sx={{ color: "#475569", fontWeight: 600 }}>
            No hay ventas
          </Typography>
          <Typography variant="body2" sx={{ color: "#94a3b8" }}>
            No se encontraron ventas con los filtros actuales.
          </Typography>
        </TableCell>
      </TableRow>
    );
  }

  return (
    <ModuloInterfazBase
      titulo="Gestión de Ventas"
      descripcion="Consulta facturas y administra sus encabezados y líneas"
      Icono={PointOfSaleIcon}
      onVolver={onVolverCentroGestion}
      textoBotonVolver="Volver al centro de gestión"
      IconoBotonCrear={AddIcon}
      textoBotonCrear="Nueva venta"
      onCrear={abrirVentaNueva}
    >
      {/* Filtros para consultar facturas por cliente, fecha, entrega y monto. */}
      <Box sx={{ p: { xs: 2.5, md: 3 } }}>
        <Paper
          elevation={0}
          sx={{
            p: 2.5,
            borderRadius: 3,
            border: "1px solid #e2e8f0",
            backgroundColor: "#f8fafc",
          }}
        >
          <Stack direction="row" spacing={1} sx={{ alignItems: "center", mb: 2 }}>
            <SearchIcon sx={{ color: "#283972", fontSize: 21 }} />
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
              Buscar ventas
            </Typography>
          </Stack>
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: {
                xs: "1fr",
                md: "repeat(4, minmax(140px, 1fr))",
              },
              gap: 1.5,
            }}
          >
            <TextField
              label="Número de factura"
              size="small"
              type="number"
              value={filtros.numeroFactura}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  numeroFactura: event.target.value,
                }))
              }
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              label="Nombre del cliente"
              size="small"
              value={filtros.nombreCliente}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  nombreCliente: event.target.value,
                }))
              }
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              select
              label="Método de entrega"
              size="small"
              value={filtros.metodoEntregaId}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  metodoEntregaId: event.target.value,
                }))
              }
              sx={{ backgroundColor: "white" }}
            >
              <MenuItem value="">Todos los métodos</MenuItem>
              {opciones.metodosEntrega.map((metodo) => (
                <MenuItem key={metodo.DeliveryMethodID} value={metodo.DeliveryMethodID}>
                  {metodo.DeliveryMethodName}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              label="Monto mínimo"
              size="small"
              type="number"
              value={filtros.montoMinimo}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  montoMinimo: event.target.value,
                }))
              }
              slotProps={{ htmlInput: { min: 0, step: "0.01" } }}
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              label="Monto máximo"
              size="small"
              type="number"
              value={filtros.montoMaximo}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  montoMaximo: event.target.value,
                }))
              }
              slotProps={{ htmlInput: { min: 0, step: "0.01" } }}
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              label="Fecha desde"
              size="small"
              type="date"
              value={filtros.fechaInicio}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  fechaInicio: event.target.value,
                }))
              }
              slotProps={{ inputLabel: { shrink: true } }}
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              label="Fecha hasta"
              size="small"
              type="date"
              value={filtros.fechaFin}
              onChange={(event) =>
                setFiltros((anterior) => ({
                  ...anterior,
                  fechaFin: event.target.value,
                }))
              }
              slotProps={{ inputLabel: { shrink: true } }}
              sx={{ backgroundColor: "white" }}
            />
            <Stack direction="row" spacing={1}>
              <Button
                fullWidth
                variant="contained"
                startIcon={<SearchIcon />}
                onClick={() => fetchVentas(filtros)}
                sx={{
                  height: 40,
                  px: 2,
                  borderRadius: 2,
                  textTransform: "none",
                  fontWeight: 600,
                  boxShadow: "none",
                  backgroundColor: "#284472",
                }}
              >
                Buscar
              </Button>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<RestartAltIcon />}
                onClick={restaurarFiltros}
                sx={{
                  height: 40,
                  px: 2,
                  borderRadius: 2,
                  textTransform: "none",
                  fontWeight: 600,
                  whiteSpace: "nowrap",
                  borderColor: "#cbd5e1",
                  color: "#475569",
                }}
              >
                Restaurar
              </Button>
            </Stack>
          </Box>
        </Paper>

        {/* Tabla de facturas encontradas y controles de paginación. */}
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f172a" }}>
            Ventas registradas
          </Typography>
          <TableContainer
            component={Paper}
            elevation={0}
            sx={{ border: "1px solid #e2e8f0", borderRadius: 3, overflow: "hidden" }}
          >
            <Table>
              <TableHead>
                <TableRow sx={{ backgroundColor: "#f1f5f9" }}>
                  {["Factura", "Fecha", "Cliente", "Método de entrega", "Monto", "Acciones"].map(
                    (titulo) => (
                      <TableCell key={titulo} sx={{ fontWeight: 700 }}>
                        {titulo}
                      </TableCell>
                    ),
                  )}
                </TableRow>
              </TableHead>
              <TableBody>{filas}</TableBody>
            </Table>
          </TableContainer>
          <ControlesPaginacionTabla
            pagina={pagina}
            filasPorPagina={filasPorPagina}
            hayMasFilas={hayMasFilas}
            onCambiarPagina={(_, numeroPagina) => fetchVentas(filtros, numeroPagina)}
            onCambiarFilasPorPagina={(nuevoTamano) => {
              setFilasPorPagina(nuevoTamano);
              fetchVentas(filtros, 0, nuevoTamano);
            }}
          />
        </Box>
      </Box>
      {/* Ventana con los datos y líneas de la factura seleccionada. */}
      <ModalDetallesVenta
        abierto={detalleAbierto}
        onClose={() => setDetalleAbierto(false)}
        venta={ventaSeleccionada}
        onAbrirCliente={abrirClienteRelacionado}
        onAbrirProducto={abrirProductoRelacionado}
      />
      {/* Ventana con los datos del cliente relacionado con la venta. */}
      <ModalDetallesCliente
        abierto={Boolean(clienteRelacionado)}
        onClose={() => setClienteRelacionado(null)}
        cliente={clienteRelacionado}
      />
      {/* Ventana con los datos del producto relacionado con la venta. */}
      <ModalDetallesProducto
        abierto={Boolean(productoRelacionado)}
        onClose={() => setProductoRelacionado(null)}
        producto={productoRelacionado}
      />
      {/* Formulario para crear o editar una factura y sus líneas. */}
      <ModalFormularioVentas
        key={versionFormulario}
        abierto={formularioAbierto}
        onClose={() => setFormularioAbierto(false)}
        venta={ventaEnEdicion}
        onGuardar={guardarVenta}
        IconoCrear={ReceiptLongIcon}
        IconoEditar={EditIcon}
        IconoModulo={PointOfSaleIcon}
      />
    </ModuloInterfazBase>
  );
}
