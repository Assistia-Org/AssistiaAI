# UseCases (Kullanım Durumları)
Uygulamanın yapabileceği spesifik bir tekil görevi yerine getiren sınıf veya fonksiyonlardır. Sadece ilgili işlevin iş mantığını barındırır. Presentation (Bloc vb.) katmanı sadece bu UseCase yapılarıyla iletişim kurar.

**Örnek Sınıflar:**
- `login_usecase.dart` -> Sadece giriş yapma görevini yönetir.
- `get_user_profile_usecase.dart` -> Profil getirmeyi yönetir.
