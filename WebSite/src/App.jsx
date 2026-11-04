import { useState } from "react";
import LogoutIcon from "@mui/icons-material/Logout";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import Alert from "@mui/material/Alert";
import Snackbar from "@mui/material/Snackbar";
import ModalConfirmacion from "./components/ModalConfirmacion";
import { Box, Button, CircularProgress, Typography } from "@mui/material";
import Proveedores from "./pages/proveedores/Proveedores";
import Clientes from "./pages/clientes/Clientes";
import Inventario from "./pages/inventario/Inventario";
import CentroReportes from "./pages/CentroReportes";
import Ventas from "./pages/ventas/Ventas";
import InicioSesion from "./pages/InicioSesion";
import CentroGestion from "./pages/CentroGestion";
import { verificarConexionBD } from "./components/ModuloHerramientas";
import "./App.css";

/** Coordina las interfaces de inicio, gestión, reportes y módulos seleccionados.
 * @returns {JSX.Element} Aplicación principal.
 * @throws {Error} Si ocurre un error no controlado al renderizar una interfaz.
 */
function App() {
  const [interfazActual, setInterfazActual] = useState("inicio");
  const [moduloActual, setModuloActual] = useState(null);
  const [errorNotificacion, setErrorNotificacion] = useState("");
  const [errorOcultarInterfaz, setErrorOcultarInterfaz] = useState("");
  const [verificandoConexion, setVerificandoConexion] = useState(false);
  const [confirmarCierreSesion, setConfirmarCierreSesion] = useState(false);

  /** Vuelve a la portada y limpia el estado de la interfaz activa.
   * @returns {void} Restablece la navegación y los errores.
   * @throws {Error} Si ocurre un error al actualizar el estado de React.
   */
  const cerrarSesion = () => {
    setErrorNotificacion("");
    setErrorOcultarInterfaz("");
    setModuloActual(null);
    setInterfazActual("inicio");
    setConfirmarCierreSesion(false);
  };

  /** Abre el diálogo antes de cerrar la sesión actual.
   * @returns {void} Muestra la confirmación de cierre de sesión.
   * @throws {Error} Si ocurre un error al actualizar el estado del diálogo.
   */
  const solicitarCierreSesion = () => {
    setConfirmarCierreSesion(true);
  };

  /** Regresa desde un módulo individual al centro de gestión.
   * @returns {void} Muestra nuevamente el listado de módulos.
   * @throws {Error} Si ocurre un error al actualizar el estado de navegación.
   */
  const volverCentroGestion = () => {
    setErrorNotificacion("");
    setErrorOcultarInterfaz("");
    setModuloActual(null);
  };

  /** Comprueba la conexión antes de abrir un módulo o el centro de reportes.
   * @param {string} destino Identificador de la pantalla o módulo que se abrirá.
   * @returns {Promise<void>} Actualiza la selección y el estado de conexión.
   * @throws {Error} Los errores de conexión se almacenan para mostrarlos en pantalla.
   */
  const abrirContenido = async (destino) => {
    setErrorNotificacion("");
    setErrorOcultarInterfaz("");
    if (destino === "reportes") {
      setInterfazActual("reportes");
      setModuloActual(null);
    } else {
      setInterfazActual("gestion");
      setModuloActual(destino);
    }
    setVerificandoConexion(true);

    try {
      await verificarConexionBD();
    } catch (error) {
      const mensaje = error.message || String(error);
      setErrorOcultarInterfaz(mensaje);
    } finally {
      setVerificandoConexion(false);
    }
  };

  /** Guarda en la aplicación los errores que deben ocultar el contenido activo.
   * @param {string} mensaje Descripción del error que se mostrará.
   * @returns {void} Actualiza el estado del error de interfaz.
   * @throws {Error} Si ocurre un error al actualizar el estado de React.
   */
  const ocultarInterfazPorError = (mensaje) => {
    setErrorNotificacion("");
    setErrorOcultarInterfaz(mensaje);
  };

  let contenido;

  if (interfazActual === "inicio") {
    contenido = (
      <InicioSesion
        onIngresarCentro={() => abrirContenido("reportes")}
        onIngresarModulos={() => {
          setErrorOcultarInterfaz("");
          setInterfazActual("gestion");
          setModuloActual(null);
        }}
      />
    );
  } else if (errorOcultarInterfaz) {
    contenido = (
      <section className="pantalla-error-conexion">
        {/* Mensaje y posibles causas del error de conexión. */}
        <div className="cuadro-error-conexion" role="alert">
          <h1>Error al acceder a la base de datos</h1>
          <p>Mensaje de error: {errorOcultarInterfaz}</p>
          <div className="causas-error">
            <p><strong>Posibles causas:</strong></p>
            <p>• Verifique que la API esté en ejecución.</p>
            <p>
              • Verifique la configuración del archivo .env en la carpeta Api
              para conectarse a SQL Server.
            </p>
            <p>
              • Verifique que los procedimientos almacenados estén correctamente
              creados en la base de datos.
            </p>
          </div>
          {interfazActual === "gestion" && moduloActual !== null && (
            <Button
              className="boton-volver"
              onClick={volverCentroGestion}
              variant="outlined"
              startIcon={<ArrowBackIcon />}
            >
              Volver al centro de gestión
            </Button>
          )}
          <Button
            className="boton-cerrar-sesion"
            onClick={solicitarCierreSesion}
            variant="outlined"
            startIcon={<LogoutIcon className="icono-cerrar-sesion" />}
          >
            Cerrar sesión
          </Button>
        </div>
      </section>
    );
  } else {
    let contenidoActivo;

    if (verificandoConexion) {
      contenidoActivo = (
        /* Indicador mientras se comprueba la conexión con la base de datos. */
        <Box className="contenedor-verificacion-conexion">
          <Box className="indicador-verificacion-conexion">
            <Box className="pista-circular-progreso">
              <CircularProgress
                variant="determinate"
                value={100}
                className="progreso-conexion-pista"
              />
              <CircularProgress
                aria-label="Verificando conexión"
                className="progreso-conexion-activo"
              />
            </Box>
            <Typography variant="body1">
              Verificando conexión con la base de datos...
            </Typography>
          </Box>
        </Box>
      );
    } else if (interfazActual === "gestion" && moduloActual === null) {
      contenidoActivo = (
        <CentroGestion onSeleccionarModulo={abrirContenido} />
      );
    } else if (interfazActual === "reportes") {
      contenidoActivo = (
        <CentroReportes
          onErrorNotificacion={setErrorNotificacion}
          onErrorOcultarModulo={ocultarInterfazPorError}
        />
      );
    } else {
      const propiedadesModulo = {
        onErrorNotificacion: setErrorNotificacion,
        onErrorOcultarModulo: ocultarInterfazPorError,
        onVolverCentroGestion: volverCentroGestion,
      };

      if (moduloActual === "clientes") {
        contenidoActivo = <Clientes {...propiedadesModulo} />;
      } else if (moduloActual === "proveedores") {
        contenidoActivo = <Proveedores {...propiedadesModulo} />;
      } else if (moduloActual === "inventarios") {
        contenidoActivo = <Inventario {...propiedadesModulo} />;
      } else if (moduloActual === "ventas") {
        contenidoActivo = <Ventas {...propiedadesModulo} />;
      }
    }

    contenido = (
      <section className="contenido-modulo">
        {/* Acción para cerrar la sesión desde la interfaz activa. */}
        <div className="acciones-navegacion-interfaz">
          <Button
            className="boton-cerrar-sesion"
            onClick={solicitarCierreSesion}
            variant="outlined"
            startIcon={<LogoutIcon className="icono-cerrar-sesion" />}
          >
            Cerrar sesión
          </Button>
        </div>
        {contenidoActivo}
      </section>
    );
  }

  return (
    <main className="contenedor-aplicacion">
      {/* Interfaz elegida y avisos temporales de errores. */}
      {contenido}
      <Snackbar
        autoHideDuration={10000}
        onClose={() => setErrorNotificacion("")}
        open={Boolean(errorNotificacion)}
        anchorOrigin={{ vertical: "top", horizontal: "center" }}
      >
        <Alert
          className="notificacion-error"
          onClose={() => setErrorNotificacion("")}
          severity="error"
          variant="filled"
        >
          {errorNotificacion}
        </Alert>
      </Snackbar>
      <ModalConfirmacion
        abierto={confirmarCierreSesion}
        onClose={() => setConfirmarCierreSesion(false)}
        onConfirmar={cerrarSesion}
        titulo="Cerrar sesión"
        mensaje="¿Deseas cerrar sesión y volver a la pantalla de inicio?"
        textoConfirmar="Cerrar sesión"
        colorIconoTexto="#284272"
        colorBoton="primary"
      />
    </main>
  );
}

export default App;
