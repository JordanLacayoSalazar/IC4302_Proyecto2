import GroupsOutlinedIcon from "@mui/icons-material/GroupsOutlined";
import LocalShippingOutlinedIcon from "@mui/icons-material/LocalShippingOutlined";
import Inventory2OutlinedIcon from "@mui/icons-material/Inventory2Outlined";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import SettingsIcon from '@mui/icons-material/Settings';
import SettingsApplicationsIcon from '@mui/icons-material/SettingsApplications';
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import { Box, Paper, Typography } from "@mui/material";
import ModuloInterfazBase from "../components/ModuloInterfazBase";

const modulos = [
  {
    id: "clientes",
    numero: "01",
    nombre: "Clientes",
    descripcion:
      "Gestiona la información de clientes, contactos, direcciones y facturación.",
    Icono: GroupsOutlinedIcon,
  },
  {
    id: "proveedores",
    numero: "02",
    nombre: "Proveedores",
    descripcion:
      "Administra proveedores, contactos, direcciones e información bancaria.",
    Icono: LocalShippingOutlinedIcon,
  },
  {
    id: "inventarios",
    numero: "03",
    nombre: "Inventarios",
    descripcion:
      "Consulta productos, precios, existencias, proveedores y ubicaciones.",
    Icono: Inventory2OutlinedIcon,
  },
  {
    id: "ventas",
    numero: "04",
    nombre: "Ventas",
    descripcion:
      "Consulta y gestiona ventas, facturas, clientes, productos y totales.",
    Icono: AttachMoneyIcon,
  },
];

/** Presenta los módulos de gestión disponibles en una caja.
 * @param {{onSeleccionarModulo: Function}} props Acción para abrir el módulo elegido.
 * @returns {JSX.Element} Interfaz de módulos de gestión.
 * @throws {Error} Si ocurre un error al renderizar los módulos.
 */
export default function CentroGestion({ onSeleccionarModulo }) {
  return (
    // Presentación y descripción del centro de gestión.
    <ModuloInterfazBase
      titulo="Módulos de Gestión"
      descripcion="Administra clientes, proveedores, inventarios y ventas desde sus módulos correspondientes."
      Icono={SettingsIcon}
    >
      {/* Tarjeta introductoria del centro de gestión. */}
      <Paper className="tarjeta-centro-gestion" elevation={0}>
        <Box className="icono-centro-gestion">
          <SettingsApplicationsIcon aria-hidden="true" />
        </Box>
        <Box>
          <Typography className="titulo-centro-gestion" variant="h6">
            Centro de gestión
          </Typography>
          <Typography className="descripcion-centro-gestion" variant="body2">
            Selecciona el módulo que deseas administrar.
          </Typography>
        </Box>
      </Paper>

      {/* Botones para abrir cada módulo. */}
      <div aria-label="Módulos disponibles" className="cuadricula-gestion">
        {modulos.map(({ id, numero, nombre, descripcion, Icono }) => (
          <button
            className="tarjeta-gestion"
            key={id}
            onClick={() => onSeleccionarModulo(id)}
            type="button"
          >
            <span className="fila-superior-tarjeta">
              <span className="icono-modulo">
                <Icono aria-hidden="true" />
              </span>
              <span className="numero-modulo">{numero}</span>
            </span>
            <span className="titulo-modulo">{nombre}</span>
            <span className="descripcion-modulo">{descripcion}</span>
            <span aria-hidden="true" className="accion-tarjeta">
              Abrir módulo <OpenInNewIcon className="icono-abrir" />
            </span>
          </button>
        ))}
      </div>
    </ModuloInterfazBase>
  );
}
