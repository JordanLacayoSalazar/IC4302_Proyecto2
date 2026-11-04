import { useEffect, useState } from "react";
import {
  Box,
  Button,
  IconButton,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
} from "@mui/material";

import SearchIcon from "@mui/icons-material/Search";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import RestartAltIcon from "@mui/icons-material/RestartAlt";
import InventoryIcon from "@mui/icons-material/Inventory";
import Inventory2OutlinedIcon from "@mui/icons-material/Inventory2Outlined";

import ModalDetallesProducto from "./ModalDetallesProducto";
import ModalFormularioProducto from "./ModalFormularioProducto";
import ControlesPaginacionTabla from "../../components/ControlesPaginacionTabla";
import AutocompletePaginado from "../../components/AutocompletePaginado";
import ModuloInterfazBase from "../../components/ModuloInterfazBase";
import ModalConfirmacion from "../../components/ModalConfirmacion";
import { mostrarError } from "../../components/ModuloHerramientas";
import {
  construirQuery,
  esDecimalNoNegativo,
  esEnteroNoNegativo,
  solicitarJson,
} from "../../components/apiHerramientas";

const FORMULARIO_INICIAL = {
  ProductoID: "",
  NombreProducto: "",
  NombreGrupo: "",
  Proveedor: "",
  Color: "",
  UnidadEmpaque: "",
  EmpaqueExterior: "",
  CantidadEmpaque: 1,
  Marca: "",
  Talla: "",
  Impuesto: 0,
  PrecioUnitario: 0,
  PrecioVenta: 0,
  Peso: 0,
  CantidadInventario: 0,
  NivelReorden: 10,
  NivelObjetivo: 50,
  PalabrasClaves: "",
};

/**
 * Presenta la tabla, filtros y formularios de productos e inventario.
 * @param {object} props Manejadores de errores y control del módulo.
 * @param {Function} props.onVolverCentroGestion Regresa al centro de gestión.
 * @returns {JSX.Element} Interfaz de gestión de inventario.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
export default function Inventario({
  onErrorNotificacion,
  onErrorOcultarModulo,
  onVolverCentroGestion,
}) {
  const [productos, setProductos] = useState([]);
  const [filtroNombre, setFiltroNombre] = useState("");
  const [filtroGrupo, setFiltroGrupo] = useState("");

  const [modalDetallesAbierto, setModalDetallesAbierto] = useState(false);
  const [productoSeleccionado, setProductoSeleccionado] = useState(null);
  const [modalFormAbierto, setModalFormAbierto] = useState(false);
  const [modoEdicion, setModoEdicion] = useState(false);
  const [numPaginaActual, setNumPaginaActual] = useState(0);
  const [cantidadFilasPorPagina, setCantidadFilasPorPagina] = useState(5);
  const [hayMasFilas, setHayMasFilas] = useState(false);
  const [modalEliminarAbierto, setModalEliminarAbierto] = useState(false);
  const [productoAEliminar, setProductoAEliminar] = useState(null);
  const [formData, setFormData] = useState(FORMULARIO_INICIAL);

  /** Consulta productos con filtros y actualiza la tabla paginada.
   * @param {object} [filtros] Texto, grupo, página y cantidad de filas.
   * @returns {Promise<void>} Actualiza productos y estado de paginación.
   * @throws {Error} Los errores de solicitud se capturan y notifican.
   */
  const fetchProductos = async ({
    nombre = filtroNombre,
    grupoId = filtroGrupo,
    pagina = 0,
    filasPorPagina = cantidadFilasPorPagina,
  } = {}) => {
    try {
      const data = await solicitarJson(
        `/api/inventario${construirQuery({ nombre, grupoId, pagina, filasPorPagina })}`,
      );
      setProductos(data.datos);
      setHayMasFilas(data.hayMasFilas);
      setNumPaginaActual(pagina);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar productos del inventario",
      );
    }
  };

  useEffect(() => {
    let activo = true;

    /**
     * Carga la primera página de productos y presenta errores de consulta.
     * @returns {Promise<void>} Carga la primera página de productos.
     * @throws {Error} Si ocurre un error no controlado durante la ejecución.
     */
    const cargarInicial = async () => {
      const resultados = await Promise.allSettled([
        solicitarJson("/api/inventario"),
      ]);

      if (!activo) return;

      const [resultadoProductos] = resultados;

      if (resultadoProductos.status === "fulfilled") {
        setProductos(resultadoProductos.value.datos);
        setHayMasFilas(resultadoProductos.value.hayMasFilas);
        setNumPaginaActual(0);
      } else {
        mostrarError(
          resultadoProductos.reason,
          onErrorNotificacion,
          onErrorOcultarModulo,
          "Error al cargar productos del inventario",
        );
      }


    };

    cargarInicial();
    return () => {
      activo = false;
    };
  }, [onErrorNotificacion, onErrorOcultarModulo]);



  /**
   * Restaura todos los filtros y consulta todos los productos.
   * @returns {Promise<void>} Restablece los filtros y carga la primera página.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const restaurarFiltros = async () => {
    setFiltroNombre("");
    setFiltroGrupo("");
    await fetchProductos({ nombre: "", grupoId: "" });
  };

  /**
   * Abre los detalles del producto seleccionado.
   * @param {number|string} id Identificador del producto.
   * @returns {Promise<void>} Carga el detalle y muestra el modal.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirDetalles = async (id) => {
    try {
      const data = await solicitarJson(`/api/inventario/${id}`);
      setProductoSeleccionado(data);
      setModalDetallesAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el detalle del producto",
      );
    }
  };

  /**
   * Abre el formulario vacío para un nuevo producto.
   * @returns {void} Reinicia el formulario y muestra el modal.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirFormularioNuevo = () => {
    setModoEdicion(false);
    setFormData({ ...FORMULARIO_INICIAL });
    setModalFormAbierto(true);
  };

  /**
   * Carga los datos del producto seleccionado en el formulario.
   * @param {object} productoRow Fila del producto seleccionado.
   * @returns {Promise<void>} Abre el formulario con los datos actuales.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const abrirFormularioEdicion = async (productoRow) => {
    try {
      const data = await solicitarJson(
        `/api/inventario/${productoRow.ProductoID}`,
      );
      setModoEdicion(true);
      setFormData({
        ...FORMULARIO_INICIAL,
        ProductoID: productoRow.ProductoID,
        NombreProducto: data.NombreProducto || "",
        NombreGrupo: data.NombreGrupo || productoRow.Grupo || "",
        Proveedor: data.Proveedor || "",
        Color: data.Color === "N/A" ? "" : data.Color || "",
        UnidadEmpaque: data.UnidadEmpaque || "",
        EmpaqueExterior: data.EmpaqueExterior || "",
        CantidadEmpaque: data.CantidadEmpaque ?? 1,
        Marca: data.Marca === "N/A" ? "" : data.Marca || "",
        Talla: data.Talla === "N/A" ? "" : data.Talla || "",
        Impuesto: data.Impuesto ?? 0,
        PrecioUnitario: data.PrecioUnitario ?? 0,
        PrecioVenta: data.PrecioVenta ?? 0,
        Peso: data.Peso ?? 0,
        CantidadInventario: data.CantidadDisponible ?? 0,
        NivelReorden: data.NivelReorden ?? 10,
        NivelObjetivo: data.NivelObjetivo ?? 50,
        PalabrasClaves:
          data.PalabrasClaves === "N/A" ? "" : data.PalabrasClaves || "",
      });
      setModalFormAbierto(true);
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al cargar el producto para editar",
      );
    }
  };

  /**
   * Valida el formato y actualiza el campo editado del producto.
   * @param {import('react').ChangeEvent<HTMLInputElement>} e Evento de cambio.
   * @returns {void} Actualiza el estado del formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarCambioFormulario = (e) => {
    const { name, value } = e.target;
    const camposEnteros = new Set([
      "CantidadEmpaque",
      "CantidadInventario",
      "NivelReorden",
      "NivelObjetivo",
    ]);
    const camposDecimales = new Set([
      "Impuesto",
      "PrecioUnitario",
      "PrecioVenta",
      "Peso",
    ]);

    if (camposEnteros.has(name) && !esEnteroNoNegativo(value)) return;
    if (camposDecimales.has(name) && !esDecimalNoNegativo(value)) return;

    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  /**
   * Actualiza el campo seleccionado en un autocompletado.
   * @param {string} nombreCampo Propiedad del formulario.
   * @param {string|number|null} valor Opción elegida.
   * @returns {void} Actualiza el estado del formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarCambioAutocomplete = (nombreCampo, valor) => {
    setFormData((prev) => ({ ...prev, [nombreCampo]: valor }));
  };

  /**
   * Crea o modifica el producto y recarga la tabla.
   * @param {object} datos Valores del producto.
   * @returns {Promise<void>} Guarda el registro y refresca la interfaz.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const guardarProducto = async (datos) => {
    const ruta = datos.ProductoID
      ? `/api/inventario/${datos.ProductoID}`
      : "/api/inventario";
    const method = datos.ProductoID ? "PUT" : "POST";

    try {
      await solicitarJson(ruta, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datos),
      });
      setModalFormAbierto(false);
      await fetchProductos();
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al guardar el producto",
      );
    }
  };

  /**
   * Abre el diálogo de confirmación para el producto seleccionado.
   * @param {object} producto Producto que se desea eliminar.
   * @returns {void} Guarda el producto pendiente y muestra el diálogo.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const confirmarEliminacion = (producto) => {
    setProductoAEliminar(producto);
    setModalEliminarAbierto(true);
  };

  /**
   * Elimina el producto confirmado y recarga la tabla.
   * @returns {Promise<void>} Actualiza la lista después de eliminar.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const ejecutarEliminacion = async () => {
    if (!productoAEliminar) return;

    try {
      await solicitarJson(`/api/inventario/${productoAEliminar.ProductoID}`, {
        method: "DELETE",
      });
      setModalEliminarAbierto(false);
      setProductoAEliminar(null);
      await fetchProductos();
    } catch (error) {
      mostrarError(
        error,
        onErrorNotificacion,
        onErrorOcultarModulo,
        "Error al eliminar el producto",
      );
    }
  };

  return (
    <ModuloInterfazBase
      titulo="Control de Inventarios"
      descripcion="Gestiona y administra los productos, stock y detalles logísticos"
      Icono={InventoryIcon}
      onVolver={onVolverCentroGestion}
      textoBotonVolver="Volver al centro de gestión"
      IconoBotonCrear={AddIcon}
      textoBotonCrear="Nuevo Producto"
      onCrear={abrirFormularioNuevo}
    >
      {/* Filtros para buscar productos por nombre y grupo. */}
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
                Buscar en inventario
              </Typography>
            </Box>
          </Stack>

          <Box
            sx={{
              display: "grid",
              gridTemplateColumns: { xs: "1fr", md: "2fr 1fr auto auto" },
              gap: 1.5,
              alignItems: "center",
            }}
          >
            <AutocompletePaginado
              catalogo="productos"
              modoTexto
              valor={filtroNombre}
              etiqueta="Nombre del producto"
              sx={{ backgroundColor: "white" }}
              onChange={setFiltroNombre}
            />

            <AutocompletePaginado
              catalogo="gruposProducto"
              valor={filtroGrupo}
              etiqueta="Grupo de producto"
              sx={{ backgroundColor: "white" }}
              onChange={(opcion) => setFiltroGrupo(opcion?.id || "")}
            />

            <Button
              variant="contained"
              startIcon={<SearchIcon />}
              onClick={() => fetchProductos()}
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

        {/* Tabla de productos, existencias y acciones disponibles. */}
        <Box sx={{ mt: 3 }}>
          <Typography variant="h6" sx={{ fontWeight: 700, color: "#0f172a" }}>
            Productos registrados
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
                    PRODUCTO
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: "#475569" }}>
                    GRUPO
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, color: "#475569" }}>
                    EXISTENCIAS
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
                {productos.length > 0 ? (
                  productos.map((row) => (
                    <TableRow key={row.ProductoID} hover>
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
                              backgroundColor: "#dcfce7",
                              color: "#16a34a",
                              fontWeight: 700,
                            }}
                          >
                            {row.NombreProducto?.charAt(0)?.toUpperCase() ||
                              "P"}
                          </Box>
                          <Box>
                            <Typography
                              variant="body2"
                              sx={{ fontWeight: 700, color: "#1e293b" }}
                            >
                              {row.NombreProducto}
                            </Typography>
                            <Typography
                              variant="caption"
                              sx={{ color: "#94a3b8" }}
                            >
                              ID: {row.ProductoID}
                            </Typography>
                          </Box>
                        </Stack>
                      </TableCell>
                      <TableCell>{row.Grupo || "N/A"}</TableCell>
                      <TableCell>
                        <Typography
                          sx={{
                            fontWeight: 700,
                            color:
                              row.CantidadInventario > 0
                                ? "#15803d"
                                : "#b45309",
                          }}
                        >
                          {row.CantidadInventario ?? 0}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        <IconButton
                          size="small"
                          onClick={() => abrirDetalles(row.ProductoID)}
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
                      <Inventory2OutlinedIcon
                        sx={{ fontSize: 50, color: "#cbd5e1" }}
                      />
                      <Typography
                        variant="h6"
                        sx={{ color: "#475569", fontWeight: 600 }}
                      >
                        No hay productos
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
            onCambiarPagina={(_, pagina) => fetchProductos({
              nombre: filtroNombre,
              grupoId: filtroGrupo,
              pagina,
            })}
            onCambiarFilasPorPagina={(nuevoTamano) => {
              setCantidadFilasPorPagina(nuevoTamano);
              fetchProductos({
                nombre: filtroNombre,
                grupoId: filtroGrupo,
                pagina: 0,
                filasPorPagina: nuevoTamano,
              });
            }}
          />
        </Box>
      </Box>

      {/* Ventana con los detalles del producto seleccionado. */}
      <ModalDetallesProducto
        abierto={modalDetallesAbierto}
        onClose={() => setModalDetallesAbierto(false)}
        producto={productoSeleccionado}
      />

      {/* Formulario para crear o editar productos del inventario. */}
      <ModalFormularioProducto
        abierto={modalFormAbierto}
        onClose={() => setModalFormAbierto(false)}
        modoEdicion={modoEdicion}
        IconoCrear={AddIcon}
        IconoEditar={EditIcon}
        IconoModulo={InventoryIcon}
        formData={formData}
        manejarCambioFormulario={manejarCambioFormulario}
        manejarCambioAutocomplete={manejarCambioAutocomplete}
        guardarProducto={guardarProducto}
      />

      {/* Confirmación antes de eliminar el producto seleccionado. */}
      <ModalConfirmacion
        abierto={modalEliminarAbierto}
        onClose={() => setModalEliminarAbierto(false)}
        onConfirmar={ejecutarEliminacion}
        titulo="Eliminar producto"
        mensaje={
          <>
            ¿Estás seguro de que deseas eliminar el producto{" "}
            <b>{productoAEliminar?.NombreProducto}</b>? Esta acción no se puede
            deshacer.
          </>
        }
      />
    </ModuloInterfazBase>
  );
}
