# Руководство по сборке и публикации: ParanormalLens

Инструкция для сборки релизных бинарников для **Google Play Store**, **Apple App Store** и **RuStore**.

---

## 🛠 1. Подготовка окружения (Prerequisites)

1. Убедитесь, что Flutter SDK установлен и добавлен в PATH.
2. В терминале в папке `ParanormalLens` выполните загрузку зависимостей:
   ```bash
   flutter pub get
   ```

---

## 📦 2. Двухконтурная сборка по флейворам (Build Flavors)

В проект заложена поддержка флагов компиляции `FLAVOR`:

### А. Для RuStore (Россия / СНГ):
* Подключает биллинг в рублях и рекламу РСЯ:
```bash
flutter build apk --release --dart-define=FLAVOR=rustore
```
Готовый файл: `build/app/outputs/flutter-apk/app-release.apk` (загружается в консоль разработчика RuStore).

---

### Б. Для Google Play Store:
* Подключает RevenueCat (IAP в долларах) и Google AdMob. Собирает оптимизированный формат Android App Bundle (AAB):
```bash
flutter build appbundle --release --dart-define=FLAVOR=global_store
```
Готовый файл: `build/app/outputs/bundle/release/app-release.aab` (загружается в Google Play Console).

---

### В. Для Apple App Store (iOS):
* Сборка архива для App Store Connect / TestFlight (требуется macOS):
```bash
flutter build ipa --release --dart-define=FLAVOR=global_store
```
Готовый архив: `build/ios/archive/Runner.xcarchive` (загружается через Xcode или Transporter).

---

## 🔑 3. Создание ключа подписи (Android Keystore)

Перед релизом в Google Play и RuStore сгенерируйте релизный ключ подписи:

```bash
keytool -genkey -v -keystore paranormal_key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias paranormal_alias
```

Создайте файл `android/key.properties`:
```properties
storePassword=ВАШ_ПАРОЛЬ_ХРАНИЛИЩА
keyPassword=ВАШ_ПАРОЛЬ_КЛЮЧА
keyAlias=paranormal_alias
storeFile=../paranormal_key.jks
```

---

## 📋 4. Чек-лист для успешной модерации (Store Compliance)

### В Apple App Store:
* [x] **Дисклеймер развлечения**: В описании и в приложении присутствует строка *"For entertainment purposes only. App simulates paranormal detections."*
* [x] **Восстановление покупок**: В Paywall присутствует обязательная кнопка *"Восстановить покупки"*.
* [x] **Разрешения камеры и микрофона**: В `Info.plist` подробно указано, что камера используется для видоискателя, а микрофон — для акустического распознавания молитвы.

### В RuStore и РФ (152-ФЗ):
* [x] **Локальность данных**: Приложение не собирает персональные данные на зарубежные серверы (все расчеты происходят офлайн на телефоне).
* [x] **Платежи**: Для RuStore используется рублевая монетизация без привязки к Google Play Billing.
