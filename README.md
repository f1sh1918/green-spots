# green-spots

Nice spots in the green

## Backend Basic

- add redirect in .htaccess to directly go to login
- add ACF, WPGraphQL, WPGraphQL for ACF, WOGraphQL IDE, WPGraphQL Smart Cache
- add auth plugin here: https://github.com/wp-graphql/wp-graphql-jwt-authentication
- add salt in config.php -> change it to invalidate all tokens
- add jwt token filter to keep token alive for 5 hours (testing)

### API

#### Example post query

```
query getSpots {
  spots(where: {status: PUBLISH}, first: 10) {
    nodes {
      author {
        node {
          name
        }
      }
      date
      id
      title
      greenspots {
        image {
          node {
            sourceUrl
          }
        }
        image2 {
          node {
            sourceUrl
          }
        }
        image3 {
          node {
            sourceUrl
          }
        }
        lat
        long
        swim
        space
        secure
        fire
      }
    }
  }
}
```

#### Example auth token query

```
mutation LoginUser {
  login(
    input: {clientMutationId: "uniqueId", username: "admin", password: ")(5rhuZTWO8oVYoLWN"}
  ) {
    authToken
    refreshToken
    user {
      id
      name
    }
  }
}
```

#### Example refresh token query

```
mutation RefreshAuthToken {
  refreshJwtAuthToken(
    input: {
      clientMutationId: "uniqueId"
      jwtRefreshToken: "your_refresh_token",
  }) {
    authToken
  }
}

```
