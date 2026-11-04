import { Box, Tabs, Tab } from "@mui/material";

/** Renderiza el panel asociado al índice de pestaña seleccionado.
 * @param {object} props Contenido, índice activo e identificadores accesibles.
 * @returns {JSX.Element} Panel de contenido.
 * @throws {Error} Si el contenido hijo genera un error al renderizarse.
 */
function TabPanel(props) {
  const { children, value, index, ...other } = props;
  return (
    // Panel con el contenido de la pestaña seleccionada.
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`pestana-tabpanel-${index}`}
      aria-labelledby={`pestana-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ pt: 3 }}>{children}</Box>}
    </div>
  );
}

/** Genera los atributos ARIA relacionados de una pestaña.
 * @param {number} index Índice de la pestaña.
 * @returns {{id: string, 'aria-controls': string}} Identificadores accesibles.
 * @throws {RangeError} Si el índice no puede convertirse en identificador.
 */
function a11yProps(index) {
  return {
    id: `pestana-tab-${index}`,
    "aria-controls": `pestana-tabpanel-${index}`,
  };
}

/** Muestra pestañas y sus paneles de contenido.
 * @param {object} props Lista de pestañas, índice activo y manejador de cambio.
 * @returns {JSX.Element} Navegación y paneles de pestañas.
 * @throws {Error} Si una pestaña o su contenido falla durante el renderizado.
 */
export default function PestanasInterfazBase({
  pestanas,
  tabActual,
  onChangeTab,
}) {
  return (
    // Navegación por pestañas y paneles de contenido asociados.
    <Box sx={{ width: "100%" }}>
      {/* Controles para cambiar de sección. */}
      <Box sx={{ borderBottom: 1, borderColor: "divider" }}>
        <Tabs
          value={tabActual}
          onChange={onChangeTab}
          variant="scrollable"
          scrollButtons="auto"
          aria-label="pestañas de interfaz base"
          sx={{
            "& .MuiTab-root": {
              textTransform: "none",
              fontWeight: 600,
              fontSize: "0.95rem",
              minHeight: 56,
            },
          }}
        >
          {pestanas.map((pestana, index) => (
            <Tab
              key={index}
              label={pestana.etiqueta}
              icon={pestana.icono}
              iconPosition="start"
              {...a11yProps(index)}
              // Si la pestaña tiene error, la pintamos de rojo
              sx={
                pestana.tieneError
                  ? {
                      color: "error.main",
                      "&.Mui-selected": { color: "error.main" },
                    }
                  : {}
              }
            />
          ))}
        </Tabs>
      </Box>

      {/* Sección correspondiente a cada pestaña. */}
      {pestanas.map((pestana, index) => (
        <TabPanel key={index} value={tabActual} index={index}>
          {pestana.contenido}
        </TabPanel>
      ))}
    </Box>
  );
}
