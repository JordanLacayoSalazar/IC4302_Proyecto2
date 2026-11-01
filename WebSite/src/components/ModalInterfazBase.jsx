import {
  Box,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Stack,
  Typography,
} from "@mui/material";
import CloseIcon from "@mui/icons-material/Close";

export default function ModalInterfazBase({
  abierto,
  onClose,
  titulo,
  descripcion,
  Icono,
  maxWidth = "md",
  contenidoSx,
  acciones,
  children,
}) {
  return (
    // Ventana modal que contiene el título, contenido y acciones del formulario.
    <Dialog
      open={abierto}
      onClose={onClose}
      maxWidth={maxWidth}
      fullWidth
      sx={{ borderRadius: 3, overflow: "hidden" }}
    >
      {/* Encabezado del modal con título, descripción e ícono para cerrar. */}
      <DialogTitle
        sx={{
          p: 0,
          background: "linear-gradient(135deg, #0f172a 0%, #1e3a5f 100%)",
          color: "white",
        }}
      >
        <Box
          sx={{
            px: 3,
            py: 2.5,
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
          }}
        >
          <Stack direction="row" spacing={1.5} sx={{ alignItems: "center" }}>
            <Icono />
            <Box sx={{ textAlign: "left" }}>
              <Typography variant="h6" sx={{ fontWeight: 700 }}>
                {titulo}
              </Typography>

              <Typography
                variant="caption"
                sx={{ color: "rgba(255,255,255,0.7)" }}
              >
                {descripcion}
              </Typography>
            </Box>
          </Stack>
          <IconButton
            aria-label="Cerrar ventana"
            onClick={onClose}
            sx={{
              color: "white",
              "&:hover": { backgroundColor: "rgba(255,255,255,0.1)" },
            }}
          >
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>
      {/* Área principal para el contenido específico del formulario o detalle. */}
      <DialogContent
        dividers
        sx={{ backgroundColor: "#f8fafc", p: { xs: 2, md: 3 }, ...contenidoSx }}
      >
        {children}
      </DialogContent>

      {/* Acciones al pie del modal. */}
      <DialogActions sx={{ px: 3, py: 2, backgroundColor: "white", gap: 1 }}>
        {acciones}
      </DialogActions>
    </Dialog>
  );
}
