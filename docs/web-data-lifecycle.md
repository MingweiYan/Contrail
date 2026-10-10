# Web data lifecycle

Contrail Web is local-first. The static site can be hosted by GitHub Pages or
any user-operated HTTP server without adding a Contrail application backend.

## Storage map

| Data | Browser storage | Network behavior |
| --- | --- | --- |
| Habits, check-ins, and tracked durations | Hive backed by IndexedDB | Never sent automatically |
| Theme, personalization, and backup settings | Shared Preferences backed by browser storage | Never sent automatically |
| WebDAV password | Process memory only | Direct mode sends it to WebDAV; compatibility mode relays it through the configured stateless gateway |
| Backup documents | User-selected WebDAV provider | Uploaded only after explicit configuration and a manual or enabled automatic backup |

Closing a tab does not delete IndexedDB or browser preferences. Data can still
be removed when the user clears site data, uses private browsing, the browser
evicts origin storage under pressure, or the deployment origin changes.

Contrail should never describe browser persistence as a backup. Users who need
recovery across devices or after browser-data loss must configure WebDAV.

## Outbound traffic contract

With no WebDAV credentials configured, application startup and local habit
operations do not make storage-provider requests. The WebDAV client checks the
local configuration before every list, read, write, or delete operation. CI
runs this contract in a real browser and fails if an unconfigured service calls
its injected HTTP transport.

The static deployment does not proxy, relay, or retain user business data. An
integrated deployment can enable the bundled compatibility gateway for WebDAV
providers that do not satisfy browser CORS requirements. The gateway does not
persist credentials or payloads, but it processes both in memory while the
request is in flight. The integrated service should therefore be self-hosted or
operated by a party the user trusts.
