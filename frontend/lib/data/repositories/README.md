# Repositories (Somut Veri Erişim Katmanı)

Bu klasör, **Domain** katmanında (domain/repositories) tanımlanan arayüzlerin (interface) gerçek implementasyonlarını barındırır.
Görevi, `Data Sources` (Veri kaynakları -> Local/Remote) klasöründeki sınıfları koordine ederek veriyi hazırlamak ve ihtiyaç anında Local veya Remote kaynaktan hangisine gidileceğine karar vermektir (Örn: Caching mantığı).

Örnek: `UserRepositoryImpl` extends/implements `UserRepository` (domain'den).

Kurallar:
- Domain katmanındaki interfacelere STRICTLY (kesin) bağımlıdır.
- Data kaynaklarındaki (`datasources`) DTO/Modelleri, Domain'in anladığı `Entities` nesnelerine dönüştürüp üst katmana (Use Cases vs) öyle yollar.
- Hata yönetimi (Exceptions to Failures mapping) burada yapılır.
