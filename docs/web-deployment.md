# Web deployment

Contrail Web is a static Flutter application. The official build has no
application backend and does not upload habit data unless the user configures a
third-party WebDAV endpoint.

## Build

For a domain root:

```sh
flutter build web --release --no-wasm-dry-run
```

For a repository subpath such as GitHub Pages:

```sh
flutter build web --release --no-wasm-dry-run --base-href /Contrail/
```

Publish the contents of `build/web`. Contrail uses hash-based routes, so direct
links such as `/#/statistics` survive reloads without a server-side rewrite.

## Self-hosting

Any static server can host `build/web`. HTTPS is strongly recommended because a
page loaded over HTTPS cannot connect to an HTTP WebDAV endpoint. Do not add a
cloud proxy unless its privacy implications are explicitly accepted: the
current design keeps user data between the browser and the user-selected
storage provider.

Browser WebDAV requires the provider (or a user-operated same-origin gateway)
to permit CORS for the site origin. It must allow `GET`, `PUT`, `DELETE`,
`PROPFIND`, and `MKCOL`, plus the `Authorization`, `Content-Type`, and `Depth`
request headers. WebDAV passwords are held only in memory on Web and must be
entered again after a reload.

See [Web data lifecycle](web-data-lifecycle.md) for the exact local storage,
retention, and outbound traffic contract.
