# Domain Layer
Bu katman uygulamanın temel iş kurallarını (business logic) içeren ve hiçbir dış pakete (Flutter, HTTP) bağımlı olmayan en saf katmandır.

## Alt Klasörler
- `entities/` : Saf Dart objeleri. Uygulamanın temel ve değişmez veri modelleri.
- `repositories/` : Uygulamanın veri ihtiyacını belirten Interface (Abstract) yapıları. Data katmanı bunu kullanarak implementasyon yapacaktır.
- `usecases/` : Kullanıcının veya sistemin gerçekleştirebileceği her bir tekil işlem (Örn: login, getUser, saveData).
