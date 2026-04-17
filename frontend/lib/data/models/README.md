# Models (Veri Modelleri)

Bu klasör, dış kaynaklardan (API, Veritabanı vb.) gelen ham verilerin Dart nesnelerine dönüştürüleceği sınıfları barındırır.
Domain katmanındaki `Entities` sınıflarından farklı olarak, serialization (serileştirme - ek: JSON to Object) mantığı BURADA yer alır.

Örnek: `UserModel`, `ProductModel`.

Kurallar:
- Genellikle Domain katmanındaki `Entities` (Örn: `User`) sınıflarını `extends` eder (genişletir).
- `fromJson`, `toJson` gibi veriyi dönüştüren metodlar buradadır.
- (Opsiyonel) 'json_serializable' ve 'freezed' gibi paketler kullanıldığında generate edilen dökümanlar burada olabilir.
