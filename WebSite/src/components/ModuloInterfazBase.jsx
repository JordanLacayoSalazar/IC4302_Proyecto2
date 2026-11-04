import { Box, Button, Paper, Stack, Typography } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";

/** Construye la vista base de un módulo con encabezado, acción y contenido.
 * @param {object} props Título, descripción, iconos, acciones e hijos.
 * @param {Function} [props.onVolver] Acción opcional de regreso dentro del panel.
 * @param {string} [props.textoBotonVolver] Texto personalizado para el botón de regreso.
 * @returns {JSX.Element} Estructura visual del módulo.
 * @throws {Error} Si los hijos o el componente de icono fallan al renderizarse.
 */
export default function ModuloInterfazBase({
  titulo,
  descripcion,
  Icono,
  onVolver,
  textoBotonVolver,
  textoBotonCrear,
  onCrear,
  IconoBotonCrear = AddIcon,
  children,
}) {
  return (
    // Caja que contiene todo el módulo, con un fondo gris claro.
    <Box
      sx={{
        minHeight: "100vh",
        backgroundColor: "#f1f5f9",
        p: { xs: 2, md: 4 },
      }}
    >
      {/* Panel blanco que contiene el encabezado y el contenido del módulo. */}
      <Paper
        elevation={0}
        sx={{
          maxWidth: 1400,
          mx: "auto",
          borderRadius: 4,
          overflow: "hidden",
          border: "1px solid #e2e8f0",
          backgroundColor: "#ffffff",
        }}
      >
        {/* Barra azul con degradado para el título, el icono y la acción principal. */}
        <Box
          sx={{
            px: { xs: 3, md: 4 },
            py: 3,
            background: "linear-gradient(135deg, #0f172a 0%, #1e3a5f 100%)",
            color: "white",
          }}
        >
          {/* Acomoda el título y el botón; en pantallas pequeñas se apilan. */}
          <Box
            sx={{
              display: "flex",
              flexDirection: { xs: "column", sm: "row" },
              justifyContent: "space-between",
              alignItems: { xs: "flex-start", sm: "center" },
              gap: 2,
            }}
          >
            {/* Agrupa el icono con el nombre y la descripción del módulo. */}
            <Stack direction="row" spacing={1.5} sx={{ alignItems: "center" }}>
              {/* Fondo del icono del módulo. */}
              <Box
                sx={{
                  width: 44,
                  height: 44,
                  borderRadius: 2.5,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  backgroundColor: "rgba(255,255,255,0.12)",
                }}
              >
                <Icono />
              </Box>
              {/* Título y texto descriptivo del módulo. */}
              <Box>
                <Typography
                  variant="h4"
                  sx={{
                    fontWeight: 700,
                    fontSize: { xs: "1.6rem", md: "2rem" },
                  }}
                >
                  {titulo}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{ color: "rgba(255,255,255,0.72)", mt: 0.3 }}
                >
                  {descripcion}
                </Typography>
              </Box>
            </Stack>

            <Stack
              direction="row"
              spacing={1.5}
              sx={{
                alignItems: "center",
                flexWrap: "wrap",
                flexShrink: 0,
                "& .MuiButton-root": {
                  height: 48,
                  marginBottom: 0,
                  boxSizing: "border-box",
                },
              }}
            >
              {/* Botón de regreso al centro de gestión, si se proporciona la acción. */}
              {onVolver && (
                <Button
                  className="boton-volver"
                  onClick={onVolver}
                  variant="outlined"
                  startIcon={<ArrowBackIcon />}
                  sx={{
                    width: "fit-content",
                    whiteSpace: "nowrap",
                  }}
                >
                  {textoBotonVolver}
                </Button>
              )}

              {/* Botón para crear un registro nuevo. */}
              {textoBotonCrear && onCrear && (
                <Button
                  variant="contained"
                  startIcon={<IconoBotonCrear />}
                  onClick={onCrear}
                  sx={{
                    width: "fit-content",
                    whiteSpace: "nowrap",
                    backgroundColor: "#22c55e",
                    color: "white",
                    fontWeight: 700,
                    px: 2.5,
                    py: 1.2,
                    borderRadius: 2.5,
                    textTransform: "none",
                    boxShadow: "none",
                    "&:hover": {
                      backgroundColor: "#16a34a",
                      boxShadow: "none",
                    },
                  }}
                >
                  {textoBotonCrear}
                </Button>
              )}
            </Stack>
          </Box>
        </Box>

        {/* Contenido específico que proporciona cada módulo. */}
        {children}
      </Paper>
    </Box>
  );
}
