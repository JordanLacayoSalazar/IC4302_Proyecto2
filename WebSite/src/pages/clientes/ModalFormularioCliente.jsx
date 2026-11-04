import { useEffect, useState } from "react";
import {
  Alert,
  Box,
  Button,
  TextField,
} from "@mui/material";
import GroupsOutlinedIcon from "@mui/icons-material/GroupsOutlined";
import PhoneOutlinedIcon from "@mui/icons-material/PhoneOutlined";
import LocationOnOutlinedIcon from "@mui/icons-material/LocationOnOutlined";
import CapturadorUbicacion from "../../components/CapturadorUbicacion";
import MapaUbicacion from "../../components/MapaUbicacion";
import ModalInterfazBase from "../../components/ModalInterfazBase";
import PestanasInterfazBase from "../../components/PestanasInterfazBase";
import AutocompletePaginado from "../../components/AutocompletePaginado";

const camposRelacionados = [
  {
    nombre: "CustomerCategoryID",
    etiqueta: "Categoría",
    opciones: "categoriasCliente",
    id: "CustomerCategoryID",
    texto: "CustomerCategoryName",
    requerido: true,
  },
  {
    nombre: "BuyingGroupID",
    etiqueta: "Grupo de compra",
    opciones: "gruposCompra",
    id: "BuyingGroupID",
    texto: "BuyingGroupName",
  },
  {
    nombre: "PrimaryContactPersonID",
    etiqueta: "Contacto primario",
    opciones: "contactos",
    id: "PersonID",
    texto: "FullName",
    requerido: true,
  },
  {
    nombre: "AlternateContactPersonID",
    etiqueta: "Contacto alternativo",
    opciones: "contactos",
    id: "PersonID",
    texto: "FullName",
  },
  {
    nombre: "BillToCustomerID",
    etiqueta: "Cliente por facturar",
    opciones: "clientesFacturacion",
    id: "CustomerID",
    texto: "CustomerName",
    requerido: true,
  },
  {
    nombre: "DeliveryMethodID",
    etiqueta: "Método de entrega",
    opciones: "metodosEntrega",
    id: "DeliveryMethodID",
    texto: "DeliveryMethodName",
    requerido: true,
  },
  {
    nombre: "DeliveryCityID",
    etiqueta: "Ciudad de entrega",
    opciones: "ciudades",
    id: "CityID",
    texto: "CityName",
    requerido: true,
  },
];

const camposContacto = [
  { nombre: "PhoneNumber", etiqueta: "Teléfono" },
  { nombre: "FaxNumber", etiqueta: "Fax" },
  {
    nombre: "PaymentDays",
    etiqueta: "Días de gracia para pagar",
    tipo: "number",
  },
  { nombre: "WebsiteURL", etiqueta: "Sitio web", tipo: "url" },
];

const camposDireccion = [
  {
    nombre: "DireccionEntrega",
    etiqueta: "Dirección de entrega",
    multiline: true,
  },
  { nombre: "DeliveryPostalCode", etiqueta: "Código postal" },
  {
    nombre: "DireccionPostal",
    etiqueta: "Dirección postal",
    multiline: true,
  },
];

/**
 * Renderiza el formulario para crear o editar clientes.
 * @param {object} props Estado del formulario y manejadores.
 * @param {boolean} props.abierto Indica si el modal está abierto.
 * @param {Function} props.onClose Cierra el modal.
 * @param {boolean} props.modoEdicion Indica si se están editando datos existentes.
 * @param {object} props.formData Valores actuales del formulario.
 * @param {Function} props.manejarCambio Actualiza el campo que cambió.
 * @param {Function} props.manejarUbicacionCapturada Guarda las coordenadas.
 * @param {Function} props.guardarCliente Ejecuta el guardado del cliente.
 * @returns {JSX.Element} Modal con campos y acciones del formulario.
 * @throws {Error} Si ocurre un error no controlado durante la ejecución.
 */
export default function ModalFormularioCliente({
  abierto,
  onClose,
  modoEdicion,
  IconoCrear,
  IconoEditar,
  IconoModulo,
  formData,
  manejarCambio,
  manejarUbicacionCapturada,
  guardarCliente,
}) {
  const [errorValidacion, setErrorValidacion] = useState("");
  const [tabActual, setTabActual] = useState(0);

  useEffect(() => {
    if (!abierto) return undefined;
    const temporizador = setTimeout(() => {
      setTabActual(0);
      setErrorValidacion("");
    }, 0);
    return () => clearTimeout(temporizador);
  }, [abierto, modoEdicion]);
  let titulo;
  let descripcion;
  let textoBotonCrear;

  if (modoEdicion) {
    titulo = "Editar cliente";
    descripcion = "Actualice la información del cliente";
    textoBotonCrear = "Guardar cambios";
  } else {
    titulo = "Crear cliente";
    descripcion = "Complete los datos para registrar un cliente";
    textoBotonCrear = "Crear cliente";
  }

  /**
   * Valida los campos requeridos antes de delegar el guardado.
   * @returns {void} Guarda el cliente o muestra un error de validación.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const guardarConValidacion = () => {
    const faltaNombre = !String(formData.CustomerName ?? "").trim();
    let faltaRelacionObligatoria = false;

    if (!modoEdicion) {
      faltaRelacionObligatoria = camposRelacionados.some(
        (campo) =>
          campo.requerido && !String(formData[campo.nombre] ?? "").trim(),
      );
    }

    if (faltaNombre || faltaRelacionObligatoria) {
      setErrorValidacion("Complete todos los campos obligatorios.");
      return;
    }

    setErrorValidacion("");
    guardarCliente();
  };

  /**
   * Limpia el error de validación y delega el cambio del campo.
   * @param {import('react').ChangeEvent<HTMLInputElement | HTMLTextAreaElement>} evento
   *   Evento de cambio del campo.
   * @returns {void} Limpia errores y actualiza el formulario.
   * @throws {Error} Si ocurre un error no controlado durante la ejecución.
   */
  const manejarCambioCampo = (evento) => {
    setErrorValidacion("");
    manejarCambio(evento);
  };

  const contenidoGeneral = (
    <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2 }}>
      {/* Campos generales y relaciones del cliente. */}
      <TextField
        label="Nombre del cliente"
        name="CustomerName"
        value={formData.CustomerName ?? ""}
        onChange={manejarCambioCampo}
        required
        fullWidth
        sx={{ backgroundColor: "white" }}
      />
      {camposRelacionados.map((campo) => (
        <AutocompletePaginado
          key={campo.nombre}
          catalogo={campo.opciones}
          precargar={abierto}
          etiqueta={campo.etiqueta}
          valor={formData[campo.nombre] ?? ""}
          requerido={!modoEdicion && Boolean(campo.requerido)}
          sx={{ backgroundColor: "white" }}
          onChange={(opcion) =>
            manejarCambioCampo({
              target: {
                name: campo.nombre,
                value: opcion?.id ?? "",
              },
            })
          }
        />
      ))}
    </Box>
  );

  const contenidoContacto = (
    <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2 }}>
      {/* Datos de contacto y condiciones de pago. */}
      {camposContacto.map((campo) => (
        <TextField
          key={campo.nombre}
          label={campo.etiqueta}
          name={campo.nombre}
          type={campo.tipo || "text"}
          value={formData[campo.nombre] ?? ""}
          onChange={manejarCambioCampo}
          fullWidth
          sx={{ backgroundColor: "white" }}
        />
      ))}
    </Box>
  );

  const contenidoDireccion = (
    <Box>
      {/* Direcciones del cliente y ubicación geográfica de entrega. */}
      <Box sx={{ display: "grid", gridTemplateColumns: { xs: "1fr", sm: "1fr 1fr" }, gap: 2, mb: 2 }}>
        {camposDireccion.map((campo) => (
          <TextField
            key={campo.nombre}
            label={campo.etiqueta}
            name={campo.nombre}
            value={formData[campo.nombre] ?? ""}
            onChange={manejarCambioCampo}
            multiline={campo.multiline}
            minRows={campo.multiline ? 2 : undefined}
            fullWidth
            sx={{ backgroundColor: "white" }}
          />
        ))}
      </Box>
      <CapturadorUbicacion
        onUbicacionCapturada={manejarUbicacionCapturada}
        latitudActual={formData.Latitud}
        longitudActual={formData.Longitud}
      />
      <MapaUbicacion
        latitud={formData.Latitud}
        longitud={formData.Longitud}
        titulo="Mapa de ubicación de entrega del cliente"
        alto={240}
        sx={{ mt: 2 }}
      />
    </Box>
  );

  const pestanas = [
    { etiqueta: "Información general", icono: <GroupsOutlinedIcon />, contenido: contenidoGeneral },
    { etiqueta: "Contacto y pago", icono: <PhoneOutlinedIcon />, contenido: contenidoContacto },
    { etiqueta: "Direcciones y ubicación", icono: <LocationOnOutlinedIcon />, contenido: contenidoDireccion },
  ];

  return (
    <ModalInterfazBase
      abierto={abierto}
      onClose={onClose}
      titulo={titulo}
      descripcion={descripcion}
      Icono={IconoModulo}
      maxWidth="md"
      contenidoSx={{ p: { xs: 2, md: 4 } }}
      acciones={
        <>
          <Button
            onClick={onClose}
            variant="outlined"
            sx={{
              textTransform: "none",
              borderRadius: 2,
              fontWeight: 600,
              borderColor: "#cbd5e1",
              color: "#475569",
            }}
          >
            Cancelar
          </Button>
          <Button
            onClick={guardarConValidacion}
            variant="contained"
            startIcon={modoEdicion ? <IconoEditar /> : <IconoCrear />}
            sx={{
              textTransform: "none",
              borderRadius: 2,
              fontWeight: 600,
              px: 2.5,
              boxShadow: "none",
            }}
          >
            {textoBotonCrear}
          </Button>
        </>
      }
    >
      <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {/* Errores de validación y secciones del formulario. */}
        {errorValidacion && <Alert severity="error">{errorValidacion}</Alert>}
        <PestanasInterfazBase
          pestanas={pestanas}
          tabActual={tabActual}
          onChangeTab={(_, value) => setTabActual(value)}
        />
      </Box>
    </ModalInterfazBase>
  );
}
