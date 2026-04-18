# Data Sources (Veri Kaynakları)

Bu klasör, verinin FİZİKSEL olarak nereden geldiğini tanımlayan sınıfları içerir. İki ana kategoriye ayrılabilir:
1. `remote`: Dış api çağrıları (HTTP istekleri, Firebase vb.).
2. `local`: Yerel cihaz hafızası (SharedPreferences, SQLite, Hive vb.).

Örnek: `AuthRemoteDataSource`, `UserLocalDataSource`.

Kurallar:
- Veritabanı veya API bağlantı kodları doğrudan buraya yazılır.
- Herhangi bir state management (Provider/BLoC) kodu içermez.
- `data/repositories` tarafından tüketilir (çağrılır).
