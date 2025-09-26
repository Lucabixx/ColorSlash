Quickstart v10 - Full sync + settings + V2 embedding fix

1. Extract archive.
2. (Optional) Generate keystore: sh scripts/generate_keystore.sh
3. Move keystore to android/app/ and create android/key.properties from android/key.properties.example
4. Add your firebase files: android/app/google-services.json and ios/Runner/GoogleService-Info.plist
5. flutter pub get
6. flutter run or flutter build appbundle --release
