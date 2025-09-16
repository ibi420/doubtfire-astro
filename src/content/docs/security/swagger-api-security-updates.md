---
title:  Swagger API Security updates
---

## Overview
This document outlines the changes made to address potential vulnerabilities related to the Swagger API documentation in the Doubtfire application.

## Potential Impact if Unfixed
If this vulnerability is not addressed, unauthorized users could access the Swagger API documentation in production environments, potentially exposing sensitive API details. This could lead to:
- Unauthorized access to API endpoints.
- Increased risk of exploitation of unprotected or misconfigured endpoints.
- Leakage of sensitive information about the API structure and functionality.

## Changes Implemented

### 1. Disable Swagger in Production
- Swagger API documentation is now disabled in production environments as it is only needed during development.
- **Action Taken:** Added a conditional check in the Swagger initializer to ensure that Swagger is only accessible in development environments.

### Context for the Decision
- During testing, I attempted to access Swagger documentation on the production site by manipulating the URL to `https://ontrack.deakin.edu.au/home/api/swagger_doc.json` and `https://ontrack.deakin.edu.au/home/swagger_doc.json`. However, I observed that any such attempts were redirected back to `https://ontrack.deakin.edu.au/home`, indicating that Swagger is not needed in production or there are additional protective measures not included in the Thothtech version of Ontrack.

## Affected Components
The following components and files were updated as part of this security enhancement:
- **doubtfire-api:**
  - Updated the Swagger initializer to disable Swagger in production.
  - **Affected file:** `config/initializers/swagger.rb`

## Recommendations
- Regularly review and update API documentation tools to ensure they are secure.
- Continuously monitor for vulnerabilities in third-party libraries and implement patches promptly.
- **Additional Security Measures:**
  - Enforce authentication and authorization for accessing API documentation if needed in non-development environments.
  - Log and monitor access to the Swagger endpoint to detect unauthorized attempts.

## References
- [Swagger Security Best Practices](https://swagger.io/docs/security/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)

## Version History
- **Version:** 1.2
- **Date:** 08/20/2025
- **Author:** Ibitope Fatoki
