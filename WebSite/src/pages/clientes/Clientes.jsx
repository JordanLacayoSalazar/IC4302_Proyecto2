import { useCallback, useEffect, useState } from "react";
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
import GroupsOutlinedIcon from "@mui/icons-material/GroupsOutlined";
import SearchIcon from "@mui/icons-material/Search";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import ControlesPaginacionTabla from "../../components/ControlesPaginacionTabla";
import AutocompletePaginado from "../../components/AutocompletePaginado";
import ModuloInterfazBase from "../../components/ModuloInterfazBase";
import { mostrarError } from "../../components/ModuloHerramientas";
import {
  construirQuery,
  normalizarRespuestaPaginada,
  solicitarJson,
} from "../../components/apiHerramientas";
import ModalFormularioCliente from "./ModalFormularioCliente";
import ModalDetallesCliente from "./ModalDetallesCliente";
import ModalConfirmacion from "../../components/ModalConfirmacion";

/**
 * Renderiza el módulo de clientes, su tabla y sus formularios.
 * @param {object} props Manejadores de notificaciones y control del módulo.
 * @param {Function} props.onErrorNotificacion Notifica errores al usuario.
 * @param {Function} props.onErrorOcultarModulo Oculta el módulo si el error lo requiere.
 * @returns {JSX.Element} Interfaz de gestión de clientes.
 */
export default function Clientes({
  onErrorNotificacion,
  onErrorOcultarModulo,
}) {
  const [clientes, setClientes] = useState([]);
  const [filtroNombre, setFiltroNombre] = useState("");
  const [filtroCategoria, setFiltroCategoria] = useState("");
  const [filtroMetodoEntrega, setFiltroMetodoEntrega] = useState("");
  const [clienteSeleccionado, setClienteSeleccionado] = useState(null);
  const [detalleAbierto, setDetalleAbierto] = useState(false);
  const [modalFormularioAbierto, setModalFormularioAbierto] = useState(false);
  const [modoEdicion, setModoEdicion] = useState(false);
  const [clienteIdEdicion, setClienteIdEdicion] = useState(null);
  const [formData, setFormData] = useState({});
  const [opcionesFormulario, setOpcionesFormulario] = useState({});
  const [clienteAEliminar, setClienteAEliminar] = useState(null);
  const [modalEliminarAbierto, setModalEliminarAbierto] = useState(false);
  const [pagina, setPagina] = useState(0);
  const [cantidadFilasPorPagina, setCantidadFilasPorPagina] = useState(5);
  const [hayMas, setHayMas] = useState(false);

  /**
   * Consulta clientes con los filtros seleccionados y vuelve a la primera página.
   * @param {string} [nombre=""] Texto opcional para filtrar clientes.
   * @param {string} [categoria=""] Categoría seleccionada.
   * @param {string} [metodoEntrega=""] Método de entrega seleccionado.
   * @returns {Promise<void>} Completa la solicitud y actualiza el estado.
   */
  const fetchClientes = useCallback(
    async (
      nombre = "",
      categoria = "",
      metodoEntrega = "",
      paginaSolicitada = 0,
      filasSolicitadas = cantidadFilasPorPagina,
    ) => {
      try {
        const resultado = await solicitarJson(
          `/api/clientes${construirQuery({
            nombre,
            categoria,
            metodoEntrega,
            pagina: paginaSolicitada,
            filasPorPagina: filasSolicitadas,
          })}`,
        );

        const pagina = normalizarRespuestaPaginada(resultado);
        setClientes(pagina.datos);
        setHayMas(pagina.hayMas);
        setPagina(paginaSolicitada);
      } catch (error) {
        mostrarError(
          error,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar clientes",
        );
      }
    },
    [cantidadFilasPorPagina, onErrorNotificacion, onErrorOcultarModulo],
  );

  /**
   * Carga categorías y métodos de entrega para los filtros de la tabla.
   * @returns {Promise<void>} Actualiza las opciones de los filtros.
   */
  const fetchOpcionesFormulario = useCallback(async () => {
    try {
      const resultado = await solicitarJson("/api/opciones-clientes");
      setOpcionesFormulario(resultado);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar opciones del formulario",
      );
    }
  }, [onErrorNotificacion, onErrorOcultarModulo]);

  /**
   * Abre el formulario vacío para registrar un cliente nuevo.
   * @returns {void} Reinicia el formulario y muestra el modal.
   */
  const abrirFormularioNuevo = () => {
    setModoEdicion(false);
    setClienteIdEdicion(null);
    setFormData({ CustomerName: "", Latitud: null, Longitud: null });
    setModalFormularioAbierto(true);
  };

  /**
   * Obtiene los datos del cliente y abre el formulario en modo edición.
   * @param {object} cliente Fila del cliente, con CustomerID.
   * @returns {Promise<void>} Carga el formulario o notifica el error.
   */
  const abrirFormularioEdicion = async (cliente) => {
    try {
      const detalle = await solicitarJson(`/api/clientes/${cliente.CustomerID}`);

      setModoEdicion(true);
      setClienteIdEdicion(cliente.CustomerID);
      setFormData({
        CustomerName: detalle.NombreCliente || "",
        PhoneNumber: detalle.PhoneNumber,
        FaxNumber: detalle.FaxNumber,
        PaymentDays: detalle.PaymentDays,
        WebsiteURL: detalle.WebsiteURL,
        DireccionEntrega: [
          detalle.DeliveryAddressLine1,
          detalle.DeliveryAddressLine2,
        ]
          .filter(Boolean)
          .join("\n"),
        DeliveryPostalCode: detalle.DeliveryPostalCode,
        DireccionPostal: [
          detalle.PostalAddressLine1,
          detalle.PostalAddressLine2,
        ]
          .filter(Boolean)
          .join("\n"),
        BillToCustomerID: detalle.BillToCustomerID,
        CustomerCategoryID: detalle.CustomerCategoryID,
        BuyingGroupID: detalle.BuyingGroupID,
        PrimaryContactPersonID: detalle.PrimaryContactPersonID,
        AlternateContactPersonID: detalle.AlternateContactPersonID,
        DeliveryMethodID: detalle.DeliveryMethodID,
        DeliveryCityID: detalle.DeliveryCityID,
        Latitud: detalle.Latitud,
        Longitud: detalle.Longitud,
      });
      setModalFormularioAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el cliente para editar",
      );
    }
  };

  /**
   * Actualiza un campo del formulario y convierte IDs y valores numéricos.
   * @param {import('react').ChangeEvent<HTMLInputElement | HTMLTextAreaElement>} evento
   *   Evento de cambio del campo.
   * @returns {void} Actualiza el formulario y normaliza sus valores.
   */
  const manejarCambioFormulario = (evento) => {
    let valor = evento.target.value;
    const camposId = [
      "CustomerCategoryID",
      "BillToCustomerID",
      "PrimaryContactPersonID",
      "AlternateContactPersonID",
      "BuyingGroupID",
      "DeliveryMethodID",
      "DeliveryCityID",
    ];
    if (
      evento.target.type === "number" ||
      camposId.includes(evento.target.name)
    ) {
      if (valor === "") {
        valor = null;
      } else {
        valor = Number(valor);
      }
    } else if (valor === "") {
      valor = null;
    }

    setFormData((datosAnteriores) => ({
      ...datosAnteriores,
      [evento.target.name]: valor,
    }));
  };

  /**
   * Guarda las coordenadas capturadas para la ubicación de entrega.
   * @param {number|null} latitud Latitud seleccionada.
   * @param {number|null} longitud Longitud seleccionada.
   * @returns {void} Guarda las coordenadas en el estado del formulario.
   */
  const manejarUbicacionCapturada = (latitud, longitud) => {
    setFormData((datosAnteriores) => ({
      ...datosAnteriores,
      Latitud: latitud,
      Longitud: longitud,
    }));
  };

  /**
   * Crea o actualiza el cliente y vuelve a cargar la lista.
   * @returns {Promise<void>} Completa el guardado y actualiza la interfaz.
   */
  const guardarCliente = async () => {
    const url = modoEdicion
      ? `/api/clientes/${clienteIdEdicion}`
      : "/api/clientes";
    /**
     * Separa una dirección multilínea en sus dos campos de almacenamiento.
     * @param {string|null|undefined} direccion Dirección escrita en el formulario.
     * @returns {{linea1: string|null, linea2: string|null}} Líneas de dirección.
     */
    const separarDireccion = (direccion) => {
      const lineas = String(direccion ?? "").split(/\r?\n/);
      const direccionVacia = lineas.every((linea) => !linea.trim());

      return {
        linea1: direccionVacia ? null : lineas[0],
        linea2: direccionVacia ? null : lineas.slice(1).join("\n"),
      };
    };
    const direccionEntrega = separarDireccion(formData.DireccionEntrega);
    const direccionPostal = separarDireccion(formData.DireccionPostal);
    const datosCliente = {
      ...formData,
      DeliveryAddressLine1: direccionEntrega.linea1,
      DeliveryAddressLine2: direccionEntrega.linea2,
      PostalAddressLine1: direccionPostal.linea1,
      PostalAddressLine2: direccionPostal.linea2,
    };
    delete datosCliente.DireccionEntrega;
    delete datosCliente.DireccionPostal;

    try {
      await solicitarJson(url, {
        method: modoEdicion ? "PUT" : "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datosCliente),
      });
      setModalFormularioAbierto(false);
      await fetchClientes(filtroNombre, filtroCategoria, filtroMetodoEntrega);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al guardar cliente",
      );
    }
  };

  /**
   * Solicita confirmación y elimina el cliente seleccionado.
   * @param {number|string} id Identificador del cliente.
   * @returns {Promise<void>} Completa la eliminación y recarga la lista.
   */
  const ejecutarEliminacion = async () => {
    if (!clienteAEliminar) return;
    try {
      await solicitarJson(`/api/clientes/${clienteAEliminar.CustomerID}`, {
        method: "DELETE",
      });

      await fetchClientes(filtroNombre, filtroCategoria, filtroMetodoEntrega);
      setModalEliminarAbierto(false);
      setClienteAEliminar(null);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al eliminar cliente",
      );
    }
  };

  useEffect(() => {
    const temporizador = window.setTimeout(() => {
      fetchClientes("");
      fetchOpcionesFormulario();
    }, 0);

    return () => window.clearTimeout(temporizador);
  }, [fetchClientes, fetchOpcionesFormulario]);

  /**
   * Limpia los tres filtros y vuelve a cargar todos los clientes.
   * @returns {void} Restablece los filtros y consulta la primera página.
   */
  const restaurarFiltros = () => {
    setFiltroNombre("");
    setFiltroCategoria("");
    setFiltroMetodoEntrega("");
    fetchClientes("", "", "");
  };

  /**
   * Carga y abre el modal con el detalle del cliente indicado.
   * @param {number|string} id Identificador del cliente.
   * @returns {Promise<void>} Abre el detalle o muestra un error.
   */
  const abrirDetalle = async (id) => {
    try {
      const detalle = await solicitarJson(`/api/clientes/${id}`);

      setClienteSeleccionado(detalle);
      setDetalleAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al obtener detalle del cliente",
      );
    }
  };

  let filasClientes;
  if (clientes.length > 0) {
    filasClientes = clientes.map((cliente) => (
      <TableRow key={cliente.CustomerID} hover>
        <TableCell>
          <Stack direction="row" spacing={1.5} sx={{ alignItems: "center" }}>
            <Box
              sx={{
                width: 38,
                height: 38,
                flexShrink: 0,
                borderRadius: 2,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                backgroundColor: "#dbeafe",
                color: "#2563eb",
                fontWeight: 700,
              }}
            >
              {cliente.NombreCliente?.charAt(0)?.toUpperCase() || "C"}
            </Box>
            <Box>
              <Typography variant="body2" sx={{ fontWeight: 700, color: "#1e293b" }}>
                {cliente.NombreCliente}
              </Typography>
              <Typography variant="caption" sx={{ color: "#94a3b8" }}>
                ID: {cliente.CustomerID}
              </Typography>
            </Box>
          </Stack>
        </TableCell>
        <TableCell>{cliente.Categoria || "N/A"}</TableCell>
        <TableCell>{cliente.MetodoEntrega || "N/A"}</TableCell>
        <TableCell align="center">
          <IconButton
            size="small"
            title="Ver detalles"
            onClick={() => abrirDetalle(cliente.CustomerID)}
            sx={{ color: "#2563eb", backgroundColor: "#eff6ff" }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            title="Editar cliente"
            onClick={() => abrirFormularioEdicion(cliente)}
            sx={{ color: "#d97706", backgroundColor: "#fffbeb", ml: 1 }}
          >
            <EditIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            title="Eliminar cliente"
            onClick={() => {
              setClienteAEliminar(cliente);
              setModalEliminarAbierto(true);
            }}
            sx={{ color: "#dc2626", backgroundColor: "#fef2f2", ml: 1 }}
          >
            <DeleteIcon fontSize="small" />
          </IconButton>
        </TableCell>
      </TableRow>
    ));
  } else {
    filasClientes = (
      <TableRow>
        <TableCell colSpan={4} align="center" sx={{ py: 7 }}>
          <GroupsOutlinedIcon sx={{ fontSize: 50, color: "#cbd5e1" }} />
          <Typography variant="h6" sx={{ color: "#475569", fontWeight: 600 }}>
            No hay clientes
          </Typography>
          <Typography variant="body2" sx={{ color: "#94a3b8" }}>
            No se encontraron clientes con los filtros actuales.
          </Typography>
        </TableCell>
      </TableRow>
    );
  }

  return (
    <ModuloInterfazBase
      titulo="Gestión de Clientes"
      descripcion="Consulta y administra los clientes registrados"
      Icono={GroupsOutlinedIcon}
      IconoBoton={PersonAddIcon}
      textoBoton="Nuevo cliente"
      onCrear={abrirFormularioNuevo}
    >
      {/* Filtros para buscar clientes por nombre, categoría y método de entrega. */}
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
          <Stack
            direction="row"
            spacing={1}
            sx={{ alignItems: "center", mb: 2 }}
          >
            <SearchIcon sx={{ color: "#283972", fontSize: 21 }} />
            <Typography
              variant="subtitle1"
              sx={{ fontWeight: 700, color: "#1e293b" }}
            >
              Buscar clientes
            </Typography>
          </Stack>
          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "2fr 1fr 1fr auto auto" },
              gap: 1.5,
              alignItems: "center",
            }}
          >
            <AutocompletePaginado
              catalogo="clientes"
              modoTexto
              etiqueta="Nombre del cliente"
              size="small"
              fullWidth
              valor={filtroNombre}
              onChange={setFiltroNombre}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  fetchClientes(
                    filtroNombre,
                    filtroCategoria,
                    filtroMetodoEntrega,
                  );
                }
              }}
              sx={{ backgroundColor: "white" }}
            />
            <TextField
              select
              label="Categoría del cliente"
              size="small"
              value={filtroCategoria}
              onChange={(event) => setFiltroCategoria(event.target.value)}
              sx={{ backgroundColor: "white", textAlign: "left" }}
            >
              <MenuItem value="">Todas las categorías</MenuItem>
              {(opcionesFormulario.categorias || []).map((categoria) => (
                <MenuItem
                  key={categoria.CustomerCategoryID}
                  value={categoria.CustomerCategoryName}
                >
                  {categoria.CustomerCategoryName}
                </MenuItem>
              ))}
            </TextField>
            <TextField
              select
              label="Método de entrega"
              size="small"
              value={filtroMetodoEntrega}
              onChange={(event) => setFiltroMetodoEntrega(event.target.value)}
              sx={{ backgroundColor: "white", textAlign: "left" }}
            >
              <MenuItem value="">Todos los métodos</MenuItem>
              {(opcionesFormulario.metodosEntrega || []).map((metodo) => (
                <MenuItem
                  key={metodo.DeliveryMethodID}
                  value={metodo.DeliveryMethodName}
                >
                  {metodo.DeliveryMethodName}
                </MenuItem>
              ))}
            </TextField>
            <Button
              variant="contained"
              startIcon={<SearchIcon />}
              onClick={() =>
                fetchClientes(
                  filtroNombre,
                  filtroCategoria,
                  filtroMetodoEntrega,
                )
              }
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
              variant="outlined"
              startIcon={<RestartAltIcon />}
              onClick={restaurarFiltros}
              sx={{
                height: 40,
                px: 2,
                borderRadius: 2,
                textTransform: "none",
                fontWeight: 600,
                borderColor: "#cbd5e1",
                color: "#475569",
              }}
            >
              Restaurar
            </Button>
          </Box>
        </Paper>

        {/* Tabla de clientes encontrados y controles de paginación. */}
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f172a" }}>
            Clientes registrados
          </Typography>
          <TableContainer
            component={Paper}
            elevation={0}
            sx={{
              border: "1px solid #e2e8f0",
              borderRadius: 3,
              overflow: "hidden",
            }}
          >
            <Table>
              <TableHead>
                <TableRow sx={{ backgroundColor: "#f8fafc" }}>
                  <TableCell sx={{ fontWeight: 700, color: "#475569" }}>
                    CLIENTE
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: "#475569" }}>
                    CATEGORÍA
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: "#475569" }}>
                    MÉTODO DE ENTREGA
                  </TableCell>
                  <TableCell
                    align="center"
                    sx={{ fontWeight: 700, color: "#475569" }}
                  >
                    ACCIONES
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>{filasClientes}</TableBody>
            </Table>
          </TableContainer>
          <ControlesPaginacionTabla
            pagina={pagina}
            filasPorPagina={cantidadFilasPorPagina}
            hayMas={hayMas}
            onCambiarPagina={(_, nuevaPagina) => fetchClientes(
              filtroNombre, filtroCategoria, filtroMetodoEntrega,
              nuevaPagina, cantidadFilasPorPagina,
            )}
            onCambiarFilasPorPagina={(nuevoTamano) => {
              setCantidadFilasPorPagina(nuevoTamano);
              fetchClientes(filtroNombre, filtroCategoria, filtroMetodoEntrega, 0, nuevoTamano);
            }}
          />
        </Box>
      </Box>

      {/* Ventana con los datos completos del cliente seleccionado. */}
      <ModalDetallesCliente
        abierto={detalleAbierto}
        onClose={() => setDetalleAbierto(false)}
        cliente={clienteSeleccionado}
      />
      {/* Formulario de creación o edición de un cliente. */}
      <ModalFormularioCliente
        abierto={modalFormularioAbierto}
        onClose={() => setModalFormularioAbierto(false)}
        modoEdicion={modoEdicion}
        formData={formData}
        manejarCambio={manejarCambioFormulario}
        manejarUbicacionCapturada={manejarUbicacionCapturada}
        guardarCliente={guardarCliente}
      />
      {/* Confirmación antes de eliminar el cliente seleccionado. */}
      <ModalConfirmacion
        abierto={modalEliminarAbierto}
        onClose={() => {
          setModalEliminarAbierto(false);
          setClienteAEliminar(null);
        }}
        onConfirmar={ejecutarEliminacion}
        titulo="Eliminar cliente"
        mensaje={<>¿Está seguro de que desea eliminar al cliente <b>{clienteAEliminar?.NombreCliente}</b>?</>}
      />
    </ModuloInterfazBase>
  );
}
