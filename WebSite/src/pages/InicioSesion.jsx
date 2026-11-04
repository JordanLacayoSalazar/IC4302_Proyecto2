/** Muestra la portada del proyecto y permite elegir una de sus dos interfaces.
 * @param {{onIngresarCentro: Function, onIngresarModulos: Function}} props Acciones para entrar al centro de reportes o a los módulos.
 * @returns {JSX.Element} Interfaz de inicio.
 * @throws {Error} Si ocurre un error al renderizar la portada.
 */
export default function InicioSesion({ onIngresarCentro, onIngresarModulos }) {
  return (
    <section aria-labelledby="titulo-inicio" className="contenido-inicio">
      {/* Encabezado del proyecto e integrantes. */}
      <header className="encabezado">
        <p className="titulo-tec">Instituto Tecnológico de Costa Rica</p>
        <p className="titulo-curso">IC4302 - Bases de Datos II</p>
        <h1 id="titulo-inicio" className="titulo-proyecto">
          Proyecto #2: Wide World Importers
        </h1>
        <p className="subtitulo-proyecto">Bases de datos distribuidas</p>
        <p className="integrantes">
          Integrantes del grupo: Jordan Lacayo y Antony Campbell.
        </p>
      </header>

      {/* Formulario de inicio de sesión */}
      <div className="panel-inicio-sesion">
        <h2>Iniciar sesión</h2>
        <label className="campo-inicio-sesion">
          <span>Nombre de usuario</span>
          <input
            autoComplete="username"
            name="nombreUsuario"
            type="text"
          />
        </label>
        <label className="campo-inicio-sesion">
          <span>Contraseña</span>
          <input
            autoComplete="current-password"
            name="contrasena"
            type="password"
          />
        </label>
        <button className="boton-ingresar" type="button">
          Ingresar
        </button>
      </div>

      {/* ELIMINAR LUEGO: Botones temporales */}
      <div aria-label="Accesos temporales" className="opciones-inicio-temporales">
        <button onClick={onIngresarModulos} type="button">
          Ingresar Módulos
        </button>
        <button onClick={onIngresarCentro} type="button">
          Ingresar Reportes
        </button>
      </div>
    </section>
  );
}
