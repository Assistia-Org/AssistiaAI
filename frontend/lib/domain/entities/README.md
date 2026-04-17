# Entities (Varlıklar)

Bu klasör, uygulamanın temel iş nesnelerini (Business Objects/Entities) barındırır.
Entities, uygulamanın temel data yapılarıdır ve genellikle frameworks, veritabanları veya UI bağımlılığı içermeyen saf Dart sınıflarıdır.

Örnek: `User`, `Product`, `Order` gibi.

Kurallar:
- JSON serileştirme (@JsonSerializable vb.) kodları İÇERMEMELİDİR. Bunlar Data layer'ındaki Model'lerde olur.
- Sadece iş mantığını temsil eden alanlar ve metodlar içerir.
