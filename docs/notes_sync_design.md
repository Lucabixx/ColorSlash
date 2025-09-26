Sync design - v10

- On app startup: sync local SQLite notes with Firestore notes collection.
- On note create/update/delete: update local DB and immediately sync change to Firestore.
- Conflict resolution: use `lastModified` timestamp; newest wins.
- Attachments uploaded to Firebase Storage; Firestore documents contain storage URLs.
