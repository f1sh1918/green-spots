# green-spots

Nice spots in the green

## Backend Basic

- add redirect in .htaccess to directly go to login
- add ACF, WPGraphQL, WPGraphQL for ACF, WOGraphQL IDE, WPGraphQL Smart Cache
- add auth plugin here: https://github.com/wp-graphql/wp-graphql-jwt-authentication
- add salt in config.php -> change it to invalidate all tokens
- add jwt token filter to keep token alive for 1 year (testing)

### API

#### Example post query

```
query getPosts {
  posts(where: {status: PUBLISH}, first: 10) {
    nodes {
      id
      title
      greenspots {
        sterne
      }
    }
  }
}
```

#### Example auth token query

```
mutation LoginUser {
  login( input: {
    clientMutationId: "uniqueId",
    username: "user",
    password: "examplePw"
  } ) {
    authToken
    user {
      id
      name
    }
  }
}
```

