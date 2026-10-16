# Web data lifecycle

Contrail Web is local-first. The static site can be hosted by GitHub Pages or
any user-operated HTTP server without adding a Contrail application backend.

## Storage map

| Data | Browser storage | Network behavior |
| --- | --- | --- |
| Habits, check-ins, and tracked durations | Hive backed by IndexedDB | Local changes do not trigger a request; configured backup/sync actions may upload them |
| Theme, personalization, and backup settings | Shared Preferences backed by browser storage | Local changes do not trigger a request; allowlisted settings may be backed up or synchronized |
| WebDAV password | Persistent browser storage scoped to the current origin | Direct mode sends it to WebDAV; compatibility mode relays it through the configured stateless gateway |
| Versioned backup documents | User-selected WebDAV provider | Uploaded only after explicit configuration and a manual or enabled automatic backup |
| CRDT current-state document | User-selected WebDAV provider | Read or written only when bidirectional synchronization runs |

Closing a tab does not delete IndexedDB or browser preferences. Data can still
be removed when the user clears site data, uses private browsing, the browser
evicts origin storage under pressure, or the deployment origin changes.

The password is masked by default in the configuration UI and is excluded from
backup documents. Browser storage is not a hardware-backed secure enclave, so
only run Contrail from an origin you trust and use HTTPS outside local testing.

Contrail should never describe browser persistence as a backup. Users who need
recovery across devices or after browser-data loss must configure WebDAV.

Automatic backup and bidirectional synchronization are separate. Automatic
backup writes timestamped, restorable snapshots. On Web it checks whether a
backup is due when the app starts or returns to the foreground; a closed static
page cannot run background work. Bidirectional synchronization currently runs
from the explicit sync action and maintains `contrail_crdt_v2.json`.

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
