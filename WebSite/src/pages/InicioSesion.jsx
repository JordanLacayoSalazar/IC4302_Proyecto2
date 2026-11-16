import { useState } from "react";
import { solicitarJson, guardarTokenSesion } from "../components/apiHerramientas";

/** Muestra la portada del proyecto y permite elegir una de sus dos interfaces.
 * @param {{onIngresarUsuario: Function, onError: Function}} props Acciones de autenticación.
 * @returns {JSX.Element} Interfaz de inicio.
 */
export default function InicioSesion({ onIngresarUsuario, onError }) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [enviando, setEnviando] = useState(false);

  const iniciarSesion = async (event) => {
    event.preventDefault();
    setEnviando(true);

    try {
      const respuesta = await solicitarJson("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      guardarTokenSesion(respuesta.token);
      onIngresarUsuario(respuesta.usuario);
    } catch (error) {
      onError(error.message || String(error));
    } finally {
      setEnviando(false);
    }
  };

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
      <form className="panel-inicio-sesion" onSubmit={iniciarSesion}>
        <h2>Iniciar sesión</h2>
        <label className="campo-inicio-sesion">
          <span>Nombre de usuario</span>
          <input
            autoComplete="username"
            maxLength={50}
            name="nombreUsuario"
            onChange={(event) => setUsername(event.target.value)}
            required
            type="text"
            value={username}
          />
        </label>
        <label className="campo-inicio-sesion">
          <span>Contraseña</span>
          <input
            autoComplete="current-password"
            maxLength={100}
            name="contrasena"
            onChange={(event) => setPassword(event.target.value)}
            required
            type="password"
            value={password}
          />
        </label>
        <button className="boton-ingresar" disabled={enviando} type="submit">
          {enviando ? "Verificando..." : "Ingresar"}
        </button>
      </form>
    </section>
  );
}
