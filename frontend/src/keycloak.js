import Keycloak from "keycloak-js";

const keycloakConfig = {
  url: process.env.REACT_APP_KEYCLOAK_URL || "http://localhost:8080",
  realm: process.env.REACT_APP_KEYCLOAK_REALM || "bezpieczenstwo_projekt_realm",
  clientId: process.env.REACT_APP_KEYCLOAK_CLIENT_ID || "frontend-app",
};

console.log("Keycloak config:", keycloakConfig);

const keycloak = new Keycloak(keycloakConfig);

export default keycloak;
