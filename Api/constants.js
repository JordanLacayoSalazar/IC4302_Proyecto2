const NODOS_LOGIN = Object.freeze([
  Object.freeze({
    branchId: 1,
    branchName: "Corporativo",
    database: "WWI_Corporativo",
    hostServer: "localhost",
    port: 1433,
  }),
  Object.freeze({
    branchId: 2,
    branchName: "San Jose",
    database: "WWI_SanJose",
    hostServer: "localhost",
    port: 1434,
  }),
  Object.freeze({
    branchId: 3,
    branchName: "Limon",
    database: "WWI_Limon",
    hostServer: "localhost",
    port: 1435,
  }),
]);

const BRANCH_IDS_VALIDOS = Object.freeze(
  NODOS_LOGIN.map(({ branchId }) => branchId),
);
const ROLES_USUARIO_VALIDOS = Object.freeze(["Administrador", "Corporativo"]);
const BRANCH_ID_PREDETERMINADO = NODOS_LOGIN[0].branchId;
const PUERTO_API_PREDETERMINADO = 3000;
const CODIGOS_NODO_NO_DISPONIBLE = Object.freeze([
  "ECONNCLOSED",
  "ECONNREFUSED",
  "ECONNRESET",
  "EHOSTUNREACH",
  "EINSTLOOKUP",
  "ENETUNREACH",
  "ENOTOPEN",
  "ESOCKET",
  "ETIMEOUT",
]);
const FORMATO_DB_CONFIG =
  /^Server=localhost,1433;Database=WWI_Corporativo;User Id=[^;]+;Password=[^;]+;TrustServerCertificate=true;$/i;

const CODIGOS_HTTP = Object.freeze({
  OK: 200,
  OK_CREATED: 201,
  OK_NO_CONTENT: 204,
  ERR_BAD_REQUEST: 400,
  ERR_UNAUTHORIZED: 401,
  ERR_NOT_FOUND: 404,
  ERR_CONFLICT: 409,
  ERR_INTERNAL_SERVER_ERROR: 500,
  ERR_SERVICE_UNAVAILABLE: 503,
});

module.exports = {
  BRANCH_ID_PREDETERMINADO,
  BRANCH_IDS_VALIDOS,
  CODIGOS_HTTP,
  CODIGOS_NODO_NO_DISPONIBLE,
  FORMATO_DB_CONFIG,
  NODOS_LOGIN,
  PUERTO_API_PREDETERMINADO,
  ROLES_USUARIO_VALIDOS,
};
