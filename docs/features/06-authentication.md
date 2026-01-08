# Spinnaker Authentication

## Overview

Spinnaker supports multiple authentication methods to secure access to the UI and API. This guide covers all supported authentication types, their configuration, and how to structure API calls for each method.

---

## Supported Authentication Methods

1. **Basic Authentication** - Username/password (simplest)
2. **OAuth 2.0** - Token-based with external providers
3. **SAML 2.0** - Enterprise SSO
4. **LDAP/Active Directory** - Directory services
5. **X.509 Client Certificates** - Mutual TLS
6. **IAM (Cloud Provider)** - AWS/GCP/Azure native auth
7. **API Keys/Service Accounts** - Long-lived tokens for automation

---

## 1. Basic Authentication

### Details
- **Type:** Username/password credentials
- **Encoding:** Base64 in HTTP Authorization header
- **Complexity:** ⭐ Low
- **Security:** ⭐⭐ Medium
- **Use Case:** Development, demos, internal tools, initial setup

### Configuration

**In spinnakerservice.yaml:**
```yaml
security:
  authn:
    enabled: true
    basic:
      enabled: true
      user:
        username: admin
        password: admin123
```

**Via Gate service (gate.yml):**
```yaml
security:
  basicform:
    enabled: true
  user:
    name: admin
    password: admin123
```

### API Call Structure

**Using curl:**
```bash
# Method 1: -u flag
curl -u admin:admin123 http://localhost:8084/applications

# Method 2: Authorization header
curl -H "Authorization: Basic YWRtaW46YWRtaW4xMjM=" \
  http://localhost:8084/applications

# Generate base64 encoded credentials
echo -n "admin:admin123" | base64
# Output: YWRtaW46YWRtaW4xMjM=
```

**Python example:**
```python
import requests
from requests.auth import HTTPBasicAuth

response = requests.get(
    'http://localhost:8084/applications',
    auth=HTTPBasicAuth('admin', 'admin123')
)

# OR manually with header
headers = {
    'Authorization': 'Basic YWRtaW46YWRtaW4xMjM='
}
response = requests.get(
    'http://localhost:8084/applications',
    headers=headers
)
```

**Java example:**
```java
String auth = "admin:admin123";
String encodedAuth = Base64.getEncoder()
    .encodeToString(auth.getBytes());

HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("http://localhost:8084/applications"))
    .header("Authorization", "Basic " + encodedAuth)
    .build();
```

---

## 2. OAuth 2.0

### Details
- **Type:** Token-based authentication
- **Providers:** GitHub, Google, Azure AD, GitLab, custom
- **Complexity:** ⭐⭐⭐ Medium
- **Security:** ⭐⭐⭐⭐ High
- **Use Case:** Developer access, SaaS integrations, team collaboration

### OAuth Flow
1. User redirects to provider (GitHub/Google/Azure)
2. User authorizes application
3. Provider returns authorization code
4. Application exchanges code for access token
5. Use access token in API calls

### Configuration Examples

#### GitHub OAuth

**1. Create GitHub OAuth App:**
- Go to GitHub → Settings → Developer settings → OAuth Apps
- New OAuth App
- Authorization callback URL: `http://localhost:8084/login`

**2. Configure Spinnaker:**
```yaml
security:
  authn:
    oauth2:
      enabled: true
      client:
        clientId: YOUR_GITHUB_CLIENT_ID
        clientSecret: YOUR_GITHUB_CLIENT_SECRET
        userAuthorizationUri: https://github.com/login/oauth/authorize
        accessTokenUri: https://github.com/login/oauth/access_token
        scope: user:email,read:org
      resource:
        userInfoUri: https://api.github.com/user
      userInfoMapping:
        email: email
        firstName: name
        lastName: ""
        username: login
```

#### Google OAuth

**1. Create Google OAuth Credentials:**
- Google Cloud Console → APIs & Services → Credentials
- Create OAuth 2.0 Client ID
- Authorized redirect URIs: `http://localhost:8084/login`

**2. Configure Spinnaker:**
```yaml
security:
  authn:
    oauth2:
      enabled: true
      client:
        clientId: YOUR_CLIENT_ID.apps.googleusercontent.com
        clientSecret: YOUR_CLIENT_SECRET
        userAuthorizationUri: https://accounts.google.com/o/oauth2/v2/auth
        accessTokenUri: https://oauth2.googleapis.com/token
        scope: profile email
      resource:
        userInfoUri: https://www.googleapis.com/oauth2/v3/userinfo
      userInfoMapping:
        email: email
        firstName: given_name
        lastName: family_name
        username: email
```

#### Azure AD OAuth

**1. Register App in Azure:**
- Azure Portal → App registrations → New registration
- Redirect URI: `http://localhost:8084/login`

**2. Configure Spinnaker:**
```yaml
security:
  authn:
    oauth2:
      enabled: true
      client:
        clientId: YOUR_AZURE_CLIENT_ID
        clientSecret: YOUR_AZURE_CLIENT_SECRET
        userAuthorizationUri: https://login.microsoftonline.com/YOUR_TENANT_ID/oauth2/v2.0/authorize
        accessTokenUri: https://login.microsoftonline.com/YOUR_TENANT_ID/oauth2/v2.0/token
        scope: openid profile email
      resource:
        userInfoUri: https://graph.microsoft.com/v1.0/me
      userInfoMapping:
        email: mail
        firstName: givenName
        lastName: surname
        username: userPrincipalName
```

### API Call Structure

**Using curl:**
```bash
# Use Bearer token in Authorization header
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5..." \
  http://localhost:8084/applications
```

**Python example:**
```python
import requests

# Access token obtained from OAuth flow
access_token = "eyJhbGciOiJIUzI1NiIsInR5..."

headers = {
    'Authorization': f'Bearer {access_token}'
}

response = requests.get(
    'http://localhost:8084/applications',
    headers=headers
)
```

**Getting access token (Python):**
```python
from requests_oauthlib import OAuth2Session

# OAuth configuration
client_id = 'YOUR_CLIENT_ID'
client_secret = 'YOUR_CLIENT_SECRET'
authorization_base_url = 'https://github.com/login/oauth/authorize'
token_url = 'https://github.com/login/oauth/access_token'

# Create OAuth session
oauth = OAuth2Session(client_id)

# Get authorization URL
authorization_url, state = oauth.authorization_url(authorization_base_url)
print(f'Please go to {authorization_url} and authorize access.')

# After user authorizes, get callback URL
redirect_response = input('Paste the full redirect URL here: ')

# Fetch access token
token = oauth.fetch_token(
    token_url,
    authorization_response=redirect_response,
    client_secret=client_secret
)

access_token = token['access_token']
```

---

## 3. SAML 2.0

### Details
- **Type:** XML-based SSO authentication
- **Providers:** Okta, OneLogin, Azure AD, ADFS, Ping Identity
- **Complexity:** ⭐⭐⭐⭐ High
- **Security:** ⭐⭐⭐⭐ High
- **Use Case:** Enterprise SSO, corporate environments

### Configuration Example (Okta)

**1. Create SAML App in Okta:**
- Okta Admin → Applications → Create App Integration
- SAML 2.0
- Single sign-on URL: `http://localhost:8084/saml/SSO`
- Audience URI: `http://localhost:8084`

**2. Generate keystore:**
```bash
keytool -genkey -v -keystore saml.jks -alias saml \
  -keyalg RSA -keysize 2048 -validity 10000
```

**3. Configure Spinnaker:**
```yaml
security:
  authn:
    saml:
      enabled: true
      keyStore: /opt/spinnaker/saml/saml.jks
      keyStorePassword: changeit
      keyStoreAliasName: saml
      metadataUrl: https://dev-12345.okta.com/app/exk.../sso/saml/metadata
      issuerId: http://localhost:8084
      serviceAddress: http://localhost:8084
      userAttributeMapping:
        firstName: FirstName
        lastName: LastName
        email: Email
        username: Username
        roles: Groups
```

### Configuration Example (Azure AD SAML)

```yaml
security:
  authn:
    saml:
      enabled: true
      keyStore: /opt/spinnaker/saml/saml.jks
      keyStorePassword: changeit
      keyStoreAliasName: saml
      metadataUrl: https://login.microsoftonline.com/YOUR_TENANT_ID/federationmetadata/2007-06/federationmetadata.xml
      issuerId: spn:YOUR_APP_ID
      serviceAddress: http://your-spinnaker-gate.com
      userAttributeMapping:
        email: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
        firstName: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname
        lastName: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname
        username: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
```

### API Call Structure

**Note:** SAML is browser-based (session cookies). For API calls, use service accounts or API keys instead.

**With session cookie:**
```bash
# After SAML login in browser, extract session cookie
curl -b "SESSION=MTU2NzE4NTY..." \
  http://localhost:8084/applications
```

**Python with session:**
```python
import requests

session = requests.Session()

# After SAML login, session has cookies
# Use session for API calls
response = session.get('http://localhost:8084/applications')
```

---

## 4. LDAP/Active Directory

### Details
- **Type:** Directory service authentication
- **Complexity:** ⭐⭐ Low-Medium
- **Security:** ⭐⭐⭐ Medium-High
- **Use Case:** On-premises enterprise, existing AD infrastructure

### Configuration

```yaml
security:
  authn:
    ldap:
      enabled: true
      url: ldap://ldap.example.com:389
      # OR for SSL: ldaps://ldap.example.com:636
      
      # Manager credentials for LDAP queries
      managerDn: cn=admin,dc=example,dc=com
      managerPassword: admin_password
      
      # User search configuration
      userSearchBase: ou=users,dc=example,dc=com
      userSearchFilter: (uid={0})
      # For AD: (sAMAccountName={0})
      
  # Authorization with LDAP groups
  authz:
    groupMembership:
      service: LDAP
      ldap:
        url: ldap://ldap.example.com:389
        managerDn: cn=admin,dc=example,dc=com
        managerPassword: admin_password
        groupSearchBase: ou=groups,dc=example,dc=com
        groupSearchFilter: (member={0})
        groupRoleAttributes: cn
```

### Active Directory Specific Configuration

```yaml
security:
  authn:
    ldap:
      enabled: true
      url: ldap://ad.company.com:389
      managerDn: CN=Service Account,OU=Service Accounts,DC=company,DC=com
      managerPassword: service_password
      userSearchBase: OU=Users,DC=company,DC=com
      userSearchFilter: (sAMAccountName={0})
      
  authz:
    groupMembership:
      service: LDAP
      ldap:
        url: ldap://ad.company.com:389
        managerDn: CN=Service Account,OU=Service Accounts,DC=company,DC=com
        managerPassword: service_password
        groupSearchBase: OU=Groups,DC=company,DC=com
        groupSearchFilter: (member={0})
        groupRoleAttributes: cn
```

### API Call Structure

**Using curl:**
```bash
# Use LDAP credentials with Basic Auth
curl -u john.doe:ldap_password \
  http://localhost:8084/applications
```

**Python example:**
```python
import requests
from requests.auth import HTTPBasicAuth

# LDAP credentials
response = requests.get(
    'http://localhost:8084/applications',
    auth=HTTPBasicAuth('john.doe', 'ldap_password')
)
```

---

## 5. X.509 Client Certificates

### Details
- **Type:** Certificate-based mutual TLS
- **Complexity:** ⭐⭐⭐ Medium
- **Security:** ⭐⭐⭐⭐⭐ Very High
- **Use Case:** Service accounts, automated systems, high-security environments

### Configuration

**1. Generate certificates:**
```bash
# Create CA
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt

# Create client certificate
openssl genrsa -out client.key 4096
openssl req -new -key client.key -out client.csr
openssl x509 -req -days 365 -in client.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out client.crt

# Create truststore
keytool -import -alias ca -file ca.crt -keystore truststore.jks \
  -storepass changeit -noprompt
```

**2. Configure Spinnaker:**
```yaml
security:
  apiSecurity:
    ssl:
      enabled: true
      clientAuth: NEED  # or WANT for optional
      keyStore: /opt/spinnaker/certs/keystore.jks
      keyStorePassword: changeit
      keyStoreType: JKS
      trustStore: /opt/spinnaker/certs/truststore.jks
      trustStorePassword: changeit
      trustStoreType: JKS
    x509:
      enabled: true
      subjectPrincipalRegex: CN=(.*?)(?:,|$)
      roleOid: 1.2.840.10070.8.1  # Optional: OID for roles in cert
```

### API Call Structure

**Using curl:**
```bash
# With separate cert and key files
curl --cert client.crt --key client.key \
  https://localhost:8084/applications

# With PKCS12 bundle
curl --cert-type P12 --cert client.p12:password \
  https://localhost:8084/applications

# With CA verification
curl --cert client.crt --key client.key --cacert ca.crt \
  https://localhost:8084/applications
```

**Python example:**
```python
import requests

# With separate files
response = requests.get(
    'https://localhost:8084/applications',
    cert=('client.crt', 'client.key'),
    verify='ca.crt'  # or False to skip CA verification
)

# With PKCS12 file (requires cryptography library)
from requests_pkcs12 import get

response = get(
    'https://localhost:8084/applications',
    pkcs12_filename='client.p12',
    pkcs12_password='password'
)
```

**Java example:**
```java
KeyStore keyStore = KeyStore.getInstance("PKCS12");
keyStore.load(new FileInputStream("client.p12"), "password".toCharArray());

SSLContext sslContext = SSLContextBuilder.create()
    .loadKeyMaterial(keyStore, "password".toCharArray())
    .loadTrustMaterial(new File("ca.crt"), null)
    .build();

HttpClient client = HttpClients.custom()
    .setSSLContext(sslContext)
    .build();
```

---

## 6. IAM (Cloud Provider Authentication)

### Details
- **Type:** Cloud-native authentication
- **Providers:** AWS IAM, GCP Service Accounts, Azure Managed Identities
- **Complexity:** ⭐⭐ Low-Medium
- **Security:** ⭐⭐⭐⭐ High
- **Use Case:** Cloud-native deployments, serverless, container workloads

### AWS IAM Configuration

**1. Create IAM role:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**2. Configure Spinnaker:**
```yaml
providers:
  aws:
    enabled: true
    accounts:
    - name: my-aws-account
      assumeRole: arn:aws:iam::123456789012:role/SpinnakerRole
      
security:
  authn:
    enabled: true
```

**3. API call with AWS credentials:**
```bash
# Assume role
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/SpinnakerRole \
  --role-session-name spinnaker

# Use temporary credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

# Sign request with AWS Signature Version 4
# (typically handled by AWS SDK)
```

### GCP Service Account Configuration

**1. Create service account:**
```bash
gcloud iam service-accounts create spinnaker-sa \
  --display-name="Spinnaker Service Account"

gcloud iam service-accounts keys create key.json \
  --iam-account=spinnaker-sa@project.iam.gserviceaccount.com
```

**2. Configure Spinnaker:**
```yaml
providers:
  kubernetes:
    enabled: true
    accounts:
    - name: gke-cluster
      serviceAccount: true
      serviceAccountJsonPath: /opt/spinnaker/gcp/key.json
```

**3. API call structure:**
```bash
# Get access token
gcloud auth print-access-token

# Use in API call
curl -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  http://localhost:8084/applications
```

**Python example:**
```python
from google.auth import default
from google.auth.transport.requests import Request

# Get credentials
credentials, project = default()

# Refresh token
credentials.refresh(Request())
access_token = credentials.token

# Use in API call
headers = {'Authorization': f'Bearer {access_token}'}
response = requests.get(
    'http://localhost:8084/applications',
    headers=headers
)
```

### Azure Managed Identity Configuration

**1. Enable managed identity on Azure resource**

**2. Configure Spinnaker:**
```yaml
providers:
  azure:
    enabled: true
    accounts:
    - name: my-azure-account
      clientId: YOUR_CLIENT_ID
      useManagedIdentity: true
```

**3. API call structure:**
```bash
# Get token from Azure Instance Metadata Service
TOKEN=$(curl -H Metadata:true \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/")

# Use token
ACCESS_TOKEN=$(echo $TOKEN | jq -r .access_token)
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
  http://localhost:8084/applications
```

---

## 7. API Keys / Service Accounts

### Details
- **Type:** Long-lived tokens for automation
- **Complexity:** ⭐ Low
- **Security:** ⭐⭐⭐ Medium-High (with proper scoping)
- **Use Case:** CI/CD pipelines, automation, integrations, XL Release

### Configuration

**1. Enable Fiat (authorization service):**
```yaml
services:
  fiat:
    enabled: true
    baseUrl: http://spin-fiat:7003

security:
  authn:
    enabled: true
  authz:
    enabled: true
```

**2. Create service account via API:**
```bash
# Create service account
curl -u admin:admin123 -X POST http://localhost:8084/serviceAccounts \
  -H "Content-Type: application/json" \
  -d '{
    "name": "jenkins-ci",
    "memberOf": ["developers", "deployers"]
  }'

# List service accounts
curl -u admin:admin123 http://localhost:8084/serviceAccounts
```

**3. Generate API token (if using token-based auth):**
```bash
# This depends on your token generation mechanism
# Example with custom implementation:
curl -u admin:admin123 -X POST http://localhost:8084/api/tokens \
  -H "Content-Type: application/json" \
  -d '{
    "serviceAccount": "jenkins-ci",
    "expiresIn": "365d"
  }'
```

### API Call Structure

**Method 1: Custom headers**
```bash
curl -H "X-Spinnaker-User: jenkins-ci" \
     -H "X-Spinnaker-Api-Key: sk_live_abc123..." \
     http://localhost:8084/applications
```

**Method 2: Bearer token**
```bash
curl -H "Authorization: Bearer service-account-token" \
  http://localhost:8084/applications
```

**Method 3: Basic auth with service account**
```bash
curl -u jenkins-ci:token_password \
  http://localhost:8084/applications
```

**Python example:**
```python
import requests

# Method 1: Custom headers
headers = {
    'X-Spinnaker-User': 'jenkins-ci',
    'X-Spinnaker-Api-Key': 'sk_live_abc123...'
}

# Method 2: Bearer token
headers = {
    'Authorization': 'Bearer service-account-token'
}

response = requests.get(
    'http://localhost:8084/applications',
    headers=headers
)
```

**Java example (for XL Release):**
```java
// Using OkHttp
OkHttpClient client = new OkHttpClient();

Request request = new Request.Builder()
    .url("http://localhost:8084/applications")
    .addHeader("X-Spinnaker-User", "xlrelease-service")
    .addHeader("X-Spinnaker-Api-Key", "your-api-key")
    .build();

Response response = client.newCall(request).execute();
```

---

## Comparison Matrix

| Auth Type | Complexity | Security | Best For | API Access | Session Type |
|-----------|------------|----------|----------|------------|--------------|
| **Basic Auth** | ⭐ Low | ⭐⭐ Medium | Dev/Testing | ✅ Easy | Stateless |
| **OAuth 2.0** | ⭐⭐⭐ Medium | ⭐⭐⭐⭐ High | SaaS/Developers | ✅ Good | Token |
| **SAML** | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐ High | Enterprise SSO | ⚠️ Limited | Session |
| **LDAP/AD** | ⭐⭐ Low | ⭐⭐⭐ Medium | On-premises | ✅ Easy | Stateless |
| **X.509** | ⭐⭐⭐ Medium | ⭐⭐⭐⭐⭐ Very High | Services/mTLS | ✅ Good | Certificate |
| **IAM** | ⭐⭐ Low-Medium | ⭐⭐⭐⭐ High | Cloud Native | ✅ Good | Token |
| **API Keys** | ⭐ Low | ⭐⭐⭐ Medium-High | Automation | ✅ Excellent | Stateless |

---

## Recommended Setup for XL Release Integration

### Option 1: Service Accounts (Recommended)

**Advantages:**
- ✅ Purpose-built for automation
- ✅ Easy to manage and revoke
- ✅ Supports role-based access
- ✅ No user credentials needed

**Setup:**
```yaml
# Enable Fiat
services:
  fiat:
    enabled: true

# Create service account
curl -X POST http://localhost:8084/serviceAccounts \
  -H "Content-Type: application/json" \
  -d '{
    "name": "xlrelease-integration",
    "memberOf": ["deployers"]
  }'
```

**Usage in XL Release:**
```groovy
// XL Release HTTP connection configuration
headers = [
  'X-Spinnaker-User': 'xlrelease-integration',
  'Content-Type': 'application/json'
]
```

### Option 2: Basic Auth (Quick Setup)

**Advantages:**
- ✅ Simple to implement
- ✅ No additional configuration
- ✅ Works immediately

**Usage in XL Release:**
```groovy
// XL Release HTTP connection
username = 'admin'
password = 'admin123'
authMethod = 'Basic'
```

### Option 3: OAuth 2.0 (Enterprise)

**Advantages:**
- ✅ Token refresh support
- ✅ Enterprise-grade security
- ✅ Centralized identity management

**Setup:**
Configure OAuth provider (Azure AD/Okta), then use token-based auth in XL Release.

---

## Security Best Practices

### 1. **Use HTTPS in Production**
```yaml
security:
  apiSecurity:
    ssl:
      enabled: true
      keyStore: /path/to/keystore.jks
      keyStorePassword: changeit
```

### 2. **Rotate Credentials Regularly**
- API keys: Every 90 days
- Service account tokens: Every 6 months
- Certificates: Before expiration

### 3. **Implement Least Privilege**
```yaml
# Fiat authorization
authz:
  enabled: true
  
# Assign minimal required permissions
permissions:
  READ: ["developers", "operators"]
  WRITE: ["deployers"]
  EXECUTE: ["deployers", "release-managers"]
```

### 4. **Enable Audit Logging**
```yaml
# Echo service configuration
echo:
  enabled: true
  
# Track authentication events
logging:
  level:
    com.netflix.spinnaker.gate.security: DEBUG
```

### 5. **Use Service Accounts for Automation**
- ❌ Don't use personal accounts in CI/CD
- ✅ Create dedicated service accounts
- ✅ Document service account usage
- ✅ Revoke unused accounts

### 6. **Monitor Authentication Failures**
```bash
# Check Gate logs for auth failures
kubectl logs -n spinnaker deployment/spin-gate | grep "authentication failed"
```

---

## Troubleshooting

### Basic Auth Not Working

**Problem:** 401 Unauthorized with Basic Auth

**Solutions:**
1. Verify credentials are correct
2. Check Base64 encoding:
   ```bash
   echo -n "admin:admin123" | base64
   ```
3. Ensure Gate service has auth enabled:
   ```bash
   kubectl logs -n spinnaker deployment/spin-gate | grep "basicform"
   ```

### OAuth Token Expired

**Problem:** 401 with message "Token expired"

**Solution:**
```python
# Implement token refresh
if response.status_code == 401:
    # Refresh token
    new_token = oauth_session.refresh_token(token_url)
    # Retry request
```

### SAML Configuration Issues

**Problem:** SAML login fails or redirects incorrectly

**Solutions:**
1. Verify metadata URL is accessible
2. Check keystore password
3. Validate service address matches Gate URL
4. Review SAML response in browser dev tools

### LDAP Connection Failed

**Problem:** Cannot connect to LDAP server

**Solutions:**
```bash
# Test LDAP connection
ldapsearch -x -H ldap://ldap.example.com -b "dc=example,dc=com" -D "cn=admin,dc=example,dc=com" -W

# Check firewall rules
telnet ldap.example.com 389

# Verify DN format matches directory structure
```

### Certificate Verification Failed

**Problem:** SSL certificate errors with X.509

**Solutions:**
```bash
# Verify certificate validity
openssl x509 -in client.crt -noout -dates -subject

# Check certificate chain
openssl verify -CAfile ca.crt client.crt

# Test mTLS connection
openssl s_client -connect localhost:8084 -cert client.crt -key client.key
```

---

## Testing Authentication

### Test Basic Auth
```bash
# Should return 200 OK
curl -u admin:admin123 -w "\nHTTP Status: %{http_code}\n" \
  http://localhost:8084/applications

# Should return 401 Unauthorized
curl -w "\nHTTP Status: %{http_code}\n" \
  http://localhost:8084/applications
```

### Test OAuth Token
```bash
# Valid token - should return 200
curl -H "Authorization: Bearer valid_token" \
  -w "\nHTTP Status: %{http_code}\n" \
  http://localhost:8084/applications

# Invalid token - should return 401
curl -H "Authorization: Bearer invalid_token" \
  -w "\nHTTP Status: %{http_code}\n" \
  http://localhost:8084/applications
```

### Test Service Account
```bash
# Create test service account
curl -u admin:admin123 -X POST http://localhost:8084/serviceAccounts \
  -H "Content-Type: application/json" \
  -d '{"name": "test-account"}'

# Test access
curl -H "X-Spinnaker-User: test-account" \
  http://localhost:8084/applications
```

---

## References

- [Spinnaker Security Documentation](https://spinnaker.io/docs/setup/security/)
- [Gate Service Configuration](https://spinnaker.io/docs/reference/halyard/commands/#hal-config-security)
- [Fiat Authorization](https://spinnaker.io/docs/setup/security/authorization/)
- [OAuth 2.0 RFC](https://tools.ietf.org/html/rfc6749)
- [SAML 2.0 Specification](http://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)

---

**Status:** Complete authentication guide for all supported methods
