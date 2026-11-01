import {
  Box,
  FormControl,
  IconButton,
  InputLabel,
  MenuItem,
  Select,
  Typography,
} from "@mui/material";
import KeyboardArrowLeftIcon from "@mui/icons-material/KeyboardArrowLeft";
import KeyboardArrowRightIcon from "@mui/icons-material/KeyboardArrowRight";

/**
 * Muestra los controles de página de una tabla cuyos datos se consultan al servidor.
 * @param {{pagina: number, filasPorPagina: number, hayMas: boolean, onCambiarPagina: Function, onCambiarFilasPorPagina: Function}} props Estado y manejadores de la paginación.
 * @returns {JSX.Element} Controles de paginación.
 */
export default function ControlesPaginacionTabla({
  pagina,
  filasPorPagina,
  hayMas,
  onCambiarPagina,
  onCambiarFilasPorPagina,
}) {
  return (
    <Box className="controles-paginacion-tabla">
      <Box className="controles-paginacion-tabla-contenido">
        <FormControl
          size="small"
          className="controles-paginacion-tabla-selector"
        >
          <InputLabel id="filas-por-pagina-etiqueta">
            Filas por página
          </InputLabel>
          <Select
            labelId="filas-por-pagina-etiqueta"
            value={filasPorPagina}
            label="Filas por página"
            onChange={(evento) =>
              onCambiarFilasPorPagina(Number(evento.target.value))
            }
          >
            {[5, 10, 20].map((cantidad) => (
              <MenuItem key={cantidad} value={cantidad}>
                {cantidad}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <Typography variant="body2">Página {pagina + 1}</Typography>
        <IconButton
          aria-label="Página anterior"
          onClick={(evento) => onCambiarPagina(evento, pagina - 1)}
          disabled={pagina === 0}
          size="small"
        >
          <KeyboardArrowLeftIcon />
        </IconButton>
        <IconButton
          aria-label="Página siguiente"
          onClick={(evento) => onCambiarPagina(evento, pagina + 1)}
          disabled={!hayMas}
          size="small"
        >
          <KeyboardArrowRightIcon />
        </IconButton>
      </Box>
    </Box>
  );
}
