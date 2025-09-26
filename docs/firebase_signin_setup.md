Firebase Google Sign-In setup (v9)

1. In Firebase Console add Android app package name app.lucabixx.colorslash
2. Add SHA-1 fingerprint from your keystore (keytool -list -v -keystore colorslash-release-key.jks -alias colorslash)
3. Download google-services.json and put it in android/app/
4. Enable Google provider in Authentication -> Sign-in method
5. Rebuild app
