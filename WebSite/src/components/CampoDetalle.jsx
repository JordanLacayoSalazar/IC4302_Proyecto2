import { Box, Typography } from "@mui/material";

/** Muestra una etiqueta y su valor junto a un icono descriptivo.
 * @param {object} props Icono, etiqueta y valor del dato.
 * @returns {JSX.Element} Fila visual de detalle.
 * @throws {Error} Si el icono o el valor no puede renderizarse.
 */
export default function CampoDetalle({ icono, etiqueta, valor }) {
  return (
    // Fila de detalle con ícono, etiqueta y valor asociado.
    <Box
      sx={{
        display: "flex",
        gap: 1.5,
        alignItems: "flex-start",
        p: 1.5,
        borderRadius: 2,
        backgroundColor: "#f8fafc",
        border: "1px solid #e2e8f0",
      }}
    >
      {/* Ícono representativo del dato. */}
      <Box
        sx={{
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          width: 36,
          height: 36,
          borderRadius: 2,
          backgroundColor: "#e0f2fe",
          color: "#0284c7",
          flexShrink: 0,
        }}
      >
        {icono}
      </Box>

      {/* Etiqueta y valor del campo mostrado. */}
      <Box sx={{ minWidth: 0, textAlign: "left" }}>
        <Typography
          variant="caption"
          sx={{
            display: "block",
            color: "#64748b",
            fontWeight: 600,
            textTransform: "uppercase",
            letterSpacing: "0.04em",
          }}
        >
          {etiqueta}
        </Typography>

        <Typography
          variant="body2"
          sx={{
            mt: 0.3,
            color: "#1e293b",
            fontWeight: 500,
            wordBreak: "break-word",
          }}
        >
          {valor || "No disponible"}
        </Typography>
      </Box>
    </Box>
  );
}
