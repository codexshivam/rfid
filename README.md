# RFID Project

RFID-based password vault with Appwrite backend integration, per-user secret isolation, realtime hardware tap login, and client-side encryption.

## Backend Setup (Appwrite)

### 1. Create Database and Collections
Create database:

- Database ID: `UniVault_DB` (or your own ID, then update `.env`)

Create collections:

- `profiles`
- `secrets`
- `sessions`

### 2. Collection Attributes

`profiles`:

- `name` (string, required)
- `orgUnit` (string, required)
- `rfid_uid` (string, required, unique)

`secrets`:

- `service_name` (string, required)
- `username` (string, required)
- `password` (string, required) -> encrypted text only
- `category` (string, required) -> allowed values: `Personal`, `Work`, `Others`
- `user_id` (string, required)
- `rfid_uid` (string, required)

`sessions` (hardware state document for ESP32 bridge):

- `is_active` (boolean, required)
- `current_uid` (string, required)

Notes:

- `Last Modified` is system-managed from document update time and is not user-editable in the UI.
- If your Appwrite schema uses a different UID field name, the app includes fallback lookups (`rfid_uid`, `rfidUid`, `uid`, `user_id`, `current_uid`) to support migration.

### 3. Security Rules

`profiles`:

- Grant read to authenticated users only.
- Disable direct create from client app (admin/service workflow only).

`secrets`:

- Demo mode guest access: keep public read permissions enabled for quick RFID demos.
- App queries `secrets` by `rfid_uid` on every active hardware tap.

### 4. Realtime Hardware Channel

Hardware listener subscribes to:

`databases.{databaseId}.collections.{sessionsCollectionId}.documents.{deviceDocumentId}`

When `is_active=true` and `current_uid` is present:

- app immediately loads profile by `rfid_uid`
- app immediately fetches secrets by `rfid_uid`
- no formal `Account.createSession` wait in demo guest mode

Demo mode shortcut:

- Use the `Demo Login` button in the auth panel to trigger a guest login with UID `00000000`.
- Ensure matching records exist in `profiles` and `secrets` for that UID.

When `is_active=false`:

- app logs out UI state

## Encryption Strategy

Passwords are encrypted on Flutter side before sending to Appwrite.

- Algorithm: AES-CBC (via `encrypt` package)
- Key derivation seed: `rfid_uid + account_id + APP_ENCRYPTION_SALT`
- Key digest: SHA-256
- Stored payload format: `base64url(iv):base64(ciphertext)`

Without the correct RFID UID and account context, decryption fails.

## Environment Variables

1. Copy `.env.example` to `.env`
2. Fill real values from Appwrite Console

Required keys:

- `APPWRITE_ENDPOINT`
- `APPWRITE_PROJECT_ID`
- `APPWRITE_DATABASE_ID`
- `APPWRITE_PROFILES_COLLECTION_ID`
- `APPWRITE_SECRETS_COLLECTION_ID`
- `APPWRITE_SESSIONS_COLLECTION_ID`
- `APPWRITE_DEVICE_DOCUMENT_ID`
- `APP_ENCRYPTION_SALT`

## Run

```bash
flutter pub get
flutter run
```

## Web Publish (Simple GitHub Pages)

1. In GitHub, open Settings > Pages.
2. Set Source to Deploy from a branch.
3. Select branch `main` and folder `/docs`.

Build and publish manually:

```bash
flutter pub get
flutter build web --release --no-tree-shake-icons --base-href /<your-repository-name>/

rm -rf docs
mkdir -p docs
cp -R build/web/* docs/
touch docs/.nojekyll
```

Then commit and push `docs/`.

Your site will be available at:

`https://<your-github-username>.github.io/<your-repository-name>/`
