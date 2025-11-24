# green-spots

Nice spots in the green

## Backend Basic

- add redirect in .htaccess to directly go to login
- add ACF plugin 
- add auth plugin here: https://github.com/usefulteam/jwt-auth
- add salt in config.php -> change it to invalidate all tokens
- add jwt token filter to keep token alive for 5 hours (testing)

### REST API

#### Example spot query

```
https://backend.ballonfabrik.org/wp-json/wp/v2/spot/
```

#### Example authentication
Query:
```
https://backend.ballonfabrik.org/wp-json/jwt-auth/v1/token?username={username}&password={password}
```
Response:
```json
"success": true,
    "statusCode": 200,
    "code": "jwt_auth_valid_credential",
    "message": "Credential is valid",
    "data": {
        "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2JhY2tlbmQuYmFsbG9uZmFicmlrLm9yZyIsImlhdCI6MTc2Mzk3NTc3OSwibmJmIjoxNzYzOTc1Nzc5LCJleHAiOjE3NjM5NzYzNzksImRhdGEiOnsidXNlciI6eyJpZCI6MSwiZGV2aWNlIjoiIiwicGFzcyI6IjdlY2EzZmIyMjlmYzQwNmYxMjQwOTI1ZTE2NmZlZTZjIn19fQ.vr9AosuYeA8Lbq4pvvkDVBVf9DXdP0RO4tLg32Y-PhM",
        "id": 1,
        "email": "mail@test.com",
        "nicename": "admin",
        "firstName": "",
        "lastName": "",
        "displayName": "admin"
    }
}
```
