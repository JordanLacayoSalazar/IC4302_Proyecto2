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

import SearchIcon from "@mui/icons-material/Search";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import BusinessIcon from "@mui/icons-material/Business";
import AddBusinessIcon from "@mui/icons-material/AddBusiness";
import BusinessOutlinedIcon from "@mui/icons-material/BusinessOutlined";

import ModalDetallesProveedor from "./ModalDetallesProveedor";
import ModalFormularioProveedor from "./ModalFormularioProveedor";
import ControlesPaginacionTabla from "../../components/ControlesPaginacionTabla";
import AutocompletePaginado from "../../components/AutocompletePaginado";
import ModuloInterfazBase from "../../components/ModuloInterfazBase";
import ModalConfirmacion from "../../components/ModalConfirmacion";
import { mostrarError } from "../../components/ModuloHerramientas";
import {
  construirQuery,
  esEnteroNoNegativo,
  solicitarJson,
} from "../../components/apiHerramientas";

const FORMULARIO_INICIAL = {
  SupplierID: "",
  SupplierName: "",
  SupplierCategoryName: "",
  PrimaryContactPersonName: "",
  AlternateContactPersonName: "",
  DeliveryMethodName: "",
  DeliveryCityName: "",
  SupplierReference: "",
  DeliveryAddressLine1: "",
  DeliveryAddressLine2: "",
  DeliveryPostalCode: "",
  PostalAddressLine1: "",
  PostalAddressLine2: "",
  PostalPostalCode: "",
  PhoneNumber: "",
  FaxNumber: "",
  WebsiteURL: "",
  BankAccountName: "",
  BankAccountNumber: "",
  PaymentDays: 30,
  Latitud: null,
  Longitud: null,
};

/**
 * Presenta el listado, los filtros y los formularios de proveedores.
 * @param {object} props Propiedades de notificación y control del módulo.
 * @param {Function} props.onErrorNotificacion Muestra errores recuperables.
 * @param {Function} props.onErrorOcultarModulo Oculta el módulo ante errores críticos.
 * @param {Function} props.onVolverCentroGestion Regresa al centro de gestión.
 * @returns {JSX.Element} Interfaz de gestión de proveedores.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
export default function Proveedores({
  onErrorNotificacion,
  onErrorOcultarModulo,
  onVolverCentroGestion,
}) {
  const [proveedores, setProveedores] = useState([]);
  const [filtroNombre, setFiltroNombre] = useState("");
  const [filtroCategoria, setFiltroCategoria] = useState("");
  const [filtroMetodoEntrega, setFiltroMetodoEntrega] = useState("");
  const [categorias, setCategorias] = useState([]);
  const [opcionesFormulario, setOpcionesFormulario] = useState({
    categorias: [],
    contactos: [],
    metodosEntrega: [],
    ciudades: [],
  });

  const [modalDetallesAbierto, setModalDetallesAbierto] = useState(false);
  const [proveedorSeleccionado, setProveedorSeleccionado] = useState(null);
  const [modalFormAbierto, setModalFormAbierto] = useState(false);
  const [modoEdicion, setModoEdicion] = useState(false);
  const [numPaginaActual, setNumPaginaActual] = useState(0);
  const [cantidadFilasPorPagina, setCantidadFilasPorPagina] = useState(5);
  const [hayMasFilas, setHayMasFilas] = useState(false);
  const [modalEliminarAbierto, setModalEliminarAbierto] = useState(false);
  const [proveedorAEliminar, setProveedorAEliminar] = useState(null);
  const [formData, setFormData] = useState(FORMULARIO_INICIAL);

  /**
   * Carga catálogos del módulo desde la API.
   * @returns {Promise<void>} Actualiza los estados de opciones.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const cargarOpciones = async () => {
    try {
      const [categoriasData, opcionesData] = await Promise.all([
        solicitarJson("/api/categorias-proveedores"),
        solicitarJson("/api/proveedores/opciones"),
      ]);

      setCategorias(categoriasData);
      setOpcionesFormulario(opcionesData);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar opciones de proveedores",
      );
    }
  };

  /**
   * Consulta proveedores usando los filtros.
   * @param {{nombre?: string, categoriaId?: string, metodoEntregaId?: string}} filtros
   *   Filtros a enviar.
   * @param {number} [pagina=0] Número base cero de página.
   * @param {number} [filasPorPagina=cantidadFilasPorPagina] Filas solicitadas.
   * @returns {Promise<void>} Actualiza la tabla y reinicia su paginación.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const fetchProveedores = async ({
    nombre = filtroNombre,
    categoriaId = filtroCategoria,
    metodoEntregaId = filtroMetodoEntrega,
    pagina = 0,
    filasPorPagina = cantidadFilasPorPagina,
  } = {}) => {
    try {
      const datos = await solicitarJson(
        `/api/proveedores${construirQuery({
          nombre,
          categoriaId,
          metodoEntregaId,
          pagina,
          filasPorPagina,
        })}`,
      );
      setProveedores(datos.datos);
      setHayMasFilas(datos.hayMasFilas);
      setNumPaginaActual(pagina);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar proveedores",
      );
    }
  };

  useEffect(() => {
    let activo = true;

    /**
     * Carga proveedores, categorías y opciones al montar el módulo.
     * @returns {Promise<void>} Carga los datos iniciales del módulo.
     * @throws {Error} Si ocurre un error no controlado durante la ejecución.
     */
    const cargarInicial = async () => {
      const resultados = await Promise.allSettled([
        solicitarJson("/api/proveedores"),
        solicitarJson("/api/categorias-proveedores"),
        solicitarJson("/api/proveedores/opciones"),
      ]);

      if (!activo) return;

      const [resultadoProveedores, resultadoCategorias, resultadoOpciones] =
        resultados;

      if (resultadoProveedores.status === "fulfilled") {
        setProveedores(resultadoProveedores.value.datos);
        setHayMasFilas(resultadoProveedores.value.hayMasFilas);
        setNumPaginaActual(0);
      } else {
        mostrarError(
          resultadoProveedores.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar proveedores",
        );
      }

      if (resultadoCategorias.status === "fulfilled") {
        setCategorias(resultadoCategorias.value);
      } else {
        mostrarError(
          resultadoCategorias.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar categorías de proveedores",
        );
      }

      if (resultadoOpciones.status === "fulfilled") {
        setOpcionesFormulario(resultadoOpciones.value);
      } else {
        mostrarError(
          resultadoOpciones.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar opciones del formulario de proveedores",
        );
      }

      const erroresCatalogo = resultados
        .slice(1)
        .filter((resultado) => resultado.status === "rejected");

      if (
        erroresCatalogo.length > 0 &&
        resultadoProveedores.status === "fulfilled"
      ) {
        onErrorNotificacion(
          "Se cargaron los proveedores, pero uno o más catálogos del formulario no están disponibles.",
        );
      }
    };

    cargarInicial();
    return () => {
      activo = false;
    };
  }, [onErrorNotificacion, onErrorOcultarModulo]);


  /**
   * Restablece los filtros y vuelve a cargar la primera página.
   * @returns {Promise<void>} Tabla completa de proveedores.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const restaurarFiltros = async () => {
    setFiltroNombre("");
    setFiltroCategoria("");
    setFiltroMetodoEntrega("");
    await fetchProveedores({
      nombre: "",
      categoriaId: "",
      metodoEntregaId: "",
    });
  };

  /**
   * Obtiene el detalle de un proveedor.
   * @param {number} id Identificador del proveedor.
   * @returns {Promise<void>} Abre el modal con los datos recibidos.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const abrirDetalles = async (id) => {
    try {
      const data = await solicitarJson(`/api/proveedores/${id}`);
      setProveedorSeleccionado(data);
      setModalDetallesAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el detalle del proveedor",
      );
    }
  };

  /**
   * Abre el formulario para crear un proveedor.
   * @returns {void} Reinicia el formulario y muestra el modal.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirFormularioNuevo = () => {
    setModoEdicion(false);
    setFormData({ ...FORMULARIO_INICIAL });
    setModalFormAbierto(true);
  };

  /**
   * Carga un proveedor para edición.
   * @param {object} proveedorRow Fila seleccionada.
   * @returns {Promise<void>} Abre el formulario con los datos actuales.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirFormularioEdicion = async (proveedorRow) => {
    try {
      const data = await solicitarJson(
        `/api/proveedores/${proveedorRow.SupplierID}`,
      );

      setModoEdicion(true);
      setFormData({
        ...FORMULARIO_INICIAL,
        SupplierID: data.SupplierID ?? proveedorRow.SupplierID,
        SupplierName: data.NombreProveedor || "",
        SupplierCategoryName: data.Categoria || "",
        PrimaryContactPersonName: data.ContactoPrimario || "",
        AlternateContactPersonName: data.ContactoAlternativo || "",
        DeliveryMethodName: data.MetodoEntrega || "",
        DeliveryCityName: data.CiudadEntrega || "",
        SupplierReference: data.CodigoProveedor || "",
        DeliveryAddressLine1: data.DeliveryAddressLine1 || "",
        DeliveryAddressLine2: data.DeliveryAddressLine2 || "",
        DeliveryPostalCode:
          data.CodigoPostal === "N/A" ? "" : data.CodigoPostal || "",
        PostalAddressLine1: data.PostalAddressLine1 || "",
        PostalAddressLine2: data.PostalAddressLine2 || "",
        PostalPostalCode:
          data.CodigoPostalPostal === "N/A"
            ? ""
            : data.CodigoPostalPostal || "",
        PhoneNumber: data.Telefono === "N/A" ? "" : data.Telefono || "",
        FaxNumber: data.Fax === "N/A" ? "" : data.Fax || "",
        WebsiteURL: data.SitioWeb || "",
        BankAccountName:
          data.NombreBanco === "N/A" ? "" : data.NombreBanco || "",
        BankAccountNumber:
          data.CuentaCorriente === "N/A" ? "" : data.CuentaCorriente || "",
        PaymentDays: data.DiasGracia ?? 30,
        Latitud: data.Latitud ?? null,
        Longitud: data.Longitud ?? null,
      });
      setModalFormAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el proveedor para editar",
      );
    }
  };

  /**
   * Actualiza un campo del formulario del proveedor.
   * @param {import('react').ChangeEvent<HTMLInputElement>} e Evento de cambio.
   * @returns {void} Actualiza el estado del formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarCambioFormulario = (e) => {
    const { name, value } = e.target;
    if (name === "PaymentDays" && !esEnteroNoNegativo(value)) return;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  /**
   * Actualiza el campo elegido en un autocompletado.
   * @param {string} nombreCampo Nombre de la propiedad del formulario.
   * @param {string|number|null} valor Opción seleccionada.
   * @returns {void} Actualiza el estado del formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarCambioAutocomplete = (nombreCampo, valor) => {
    setFormData((prev) => ({ ...prev, [nombreCampo]: valor }));
  };

  /**
   * Guarda las coordenadas capturadas para el proveedor.
   * @param {number|null} lat Latitud elegida.
   * @param {number|null} lng Longitud elegida.
   * @returns {void} Actualiza las coordenadas del formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarUbicacionCapturada = (lat, lng) => {
    setFormData((prev) => ({ ...prev, Latitud: lat, Longitud: lng }));
  };

  /**
   * Crea o modifica el proveedor y actualiza la lista.
   * @param {object} datosFormulario Datos editados del proveedor.
   * @returns {Promise<void>} Guarda el registro y refresca la interfaz.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const guardarProveedor = async (datosFormulario) => {
    const id = datosFormulario.SupplierID;
    const ruta = id ? `/api/proveedores/${id}` : "/api/proveedores";
    const method = id ? "PUT" : "POST";

    try {
      await solicitarJson(ruta, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datosFormulario),
      });
      setModalFormAbierto(false);
      await Promise.all([fetchProveedores(), cargarOpciones()]);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al guardar el proveedor",
      );
    }
  };

  /**
   * Abre la confirmación para eliminar el proveedor indicado.
   * @param {object} proveedor Proveedor que se desea eliminar.
   * @returns {void} Guarda el proveedor pendiente y muestra el diálogo.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const confirmarEliminacion = (proveedor) => {
    setProveedorAEliminar(proveedor);
    setModalEliminarAbierto(true);
  };

  /**
   * Elimina el proveedor seleccionado.
   * @returns {Promise<void>} Elimina el registro y actualiza la tabla.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const ejecutarEliminacion = async () => {
    if (!proveedorAEliminar) return;

    try {
      await solicitarJson(`/api/proveedores/${proveedorAEliminar.SupplierID}`, {
        method: "DELETE",
      });
      setModalEliminarAbierto(false);
      setProveedorAEliminar(null);
      await fetchProveedores();
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al eliminar el proveedor",
      );
    }
  };

  const opcionesCategoria = categorias.length
    ? categorias
    : opcionesFormulario.categorias;

  return (
    <ModuloInterfazBase
      titulo="Gestión de Proveedores"
      descripcion="Consulta, administra y controla los proveedores registrados"
      Icono={BusinessIcon}
      onVolver={onVolverCentroGestion}
      textoBotonVolver="Volver al centro de gestión"
      IconoBotonCrear={AddBusinessIcon}
      textoBotonCrear="Nuevo Proveedor"
      onCrear={abrirFormularioNuevo}
    >
      {/* Filtros para buscar proveedores por nombre, categoría y entrega. */}
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
            <Box>
              <Typography
                variant="subtitle1"
                sx={{ fontWeight: 700, color: "#1e293b" }}
              >
                Buscar proveedores
              </Typography>
            </Box>
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
              catalogo="proveedores"
              modoTexto
              valor={filtroNombre}
              etiqueta="Nombre del proveedor"
              sx={{ backgroundColor: "white" }}
              onChange={setFiltroNombre}
            />

            <TextField
              select
              label="Categoría del proveedor"
              size="small"
              value={filtroCategoria}
              onChange={(e) => setFiltroCategoria(e.target.value)}
              sx={{ backgroundColor: "white", textAlign: "left" }}
            >
              <MenuItem value="">Todas las categorías</MenuItem>
              {opcionesCategoria.map((cat) => (
                <MenuItem
                  key={cat.SupplierCategoryID}
                  value={cat.SupplierCategoryID}
                >
                  {cat.SupplierCategoryName}
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
              {opcionesFormulario.metodosEntrega.map((metodo) => (
                <MenuItem
                  key={metodo.DeliveryMethodID}
                  value={metodo.DeliveryMethodID}
                >
                  {metodo.DeliveryMethodName}
                </MenuItem>
              ))}
            </TextField>

            <Button
              variant="contained"
              startIcon={<SearchIcon />}
              onClick={() => fetchProveedores()}
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

        {/* Tabla de proveedores encontrados y controles de paginación. */}
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f172a" }}>
            Proveedores registrados
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
                    PROVEEDOR
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
              <TableBody>
                {proveedores.length > 0 ? (
                  proveedores.map((row) => (
                    <TableRow key={row.SupplierID} hover>
                      <TableCell>
                        <Stack
                          direction="row"
                          spacing={1.5}
                          sx={{ alignItems: "center" }}
                        >
                          <Box
                            sx={{
                              width: 38,
                              height: 38,
                              borderRadius: 2,
                              display: "flex",
                              alignItems: "center",
                              justifyContent: "center",
                              backgroundColor: "#dbeafe",
                              color: "#2563eb",
                              fontWeight: 700,
                            }}
                          >
                            {row.NombreProveedor?.charAt(0)?.toUpperCase() ||
                              "P"}
                          </Box>
                          <Box>
                            <Typography
                              variant="body2"
                              sx={{ fontWeight: 700, color: "#1e293b" }}
                            >
                              {row.NombreProveedor}
                            </Typography>
                            <Typography
                              variant="caption"
                              sx={{ color: "#94a3b8" }}
                            >
                              ID: {row.SupplierID}
                            </Typography>
                          </Box>
                        </Stack>
                      </TableCell>
                      <TableCell>{row.Categoria || "N/A"}</TableCell>
                      <TableCell>{row.MetodoEntrega || "N/A"}</TableCell>
                      <TableCell align="center">
                        <IconButton
                          size="small"
                          onClick={() => abrirDetalles(row.SupplierID)}
                          sx={{ color: "#2563eb", backgroundColor: "#eff6ff" }}
                        >
                          <VisibilityIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => abrirFormularioEdicion(row)}
                          sx={{
                            color: "#d97706",
                            backgroundColor: "#fffbeb",
                            ml: 1,
                          }}
                        >
                          <EditIcon fontSize="small" />
                        </IconButton>
                        <IconButton
                          size="small"
                          onClick={() => confirmarEliminacion(row)}
                          sx={{
                            color: "#dc2626",
                            backgroundColor: "#fef2f2",
                            ml: 1,
                          }}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))
                ) : (
                  <TableRow>
                    <TableCell colSpan={4} align="center" sx={{ py: 7 }}>
                      <BusinessOutlinedIcon
                        sx={{ fontSize: 50, color: "#cbd5e1" }}
                      />
                      <Typography
                        variant="h6"
                        sx={{ color: "#475569", fontWeight: 600 }}
                      >
                        No hay proveedores
                      </Typography>
                      <Typography variant="body2" sx={{ color: "#94a3b8" }}>
                        Prueba con otros filtros o restaura la consulta.
                      </Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>

          <ControlesPaginacionTabla
            pagina={numPaginaActual}
            filasPorPagina={cantidadFilasPorPagina}
            hayMasFilas={hayMasFilas}
            onCambiarPagina={(_, nuevaPagina) => fetchProveedores({
              nombre: filtroNombre,
              categoriaId: filtroCategoria,
              metodoEntregaId: filtroMetodoEntrega,
              pagina: nuevaPagina,
            })}
            onCambiarFilasPorPagina={(nuevoTamano) => {
              setCantidadFilasPorPagina(nuevoTamano);
              fetchProveedores({
                nombre: filtroNombre,
                categoriaId: filtroCategoria,
                metodoEntregaId: filtroMetodoEntrega,
                pagina: 0,
                filasPorPagina: nuevoTamano,
              });
            }}
          />
        </Box>
      </Box>

      {/* Ventana con los datos completos del proveedor seleccionado. */}
      <ModalDetallesProveedor
        abierto={modalDetallesAbierto}
        onClose={() => setModalDetallesAbierto(false)}
        proveedor={proveedorSeleccionado}
      />

      {/* Formulario de creación o edición de un proveedor. */}
      <ModalFormularioProveedor
        abierto={modalFormAbierto}
        onClose={() => setModalFormAbierto(false)}
        modoEdicion={modoEdicion}
        IconoCrear={AddBusinessIcon}
        IconoEditar={EditIcon}
        IconoModulo={BusinessIcon}
        formData={formData}
        manejarCambioFormulario={manejarCambioFormulario}
        manejarCambioAutocomplete={manejarCambioAutocomplete}
        manejarUbicacionCapturada={manejarUbicacionCapturada}
        guardarProveedor={guardarProveedor}

      />

      {/* Confirmación antes de eliminar el proveedor seleccionado. */}
      <ModalConfirmacion
        abierto={modalEliminarAbierto}
        onClose={() => setModalEliminarAbierto(false)}
        onConfirmar={ejecutarEliminacion}
        titulo="Eliminar proveedor"
        mensaje={
          <>
            ¿Estás seguro de que deseas eliminar al proveedor{" "}
            <b>{proveedorAEliminar?.NombreProveedor}</b>?
          </>
        }
      />
    </ModuloInterfazBase>
  );
}
