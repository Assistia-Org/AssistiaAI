# Repositories (Soyut Veri Erişim Katmanı)

Bu klasör, veri erişimi için arayüz (interface/abstract class) tanımlamalarını barındırır.
Gerçek veri işlemlerinin (API çağrıları, local veritabanı okuma/yazma) NASIL yapılacağı burada tanımlanmaz, sadece NE yapılacağı tanımlanır.

Örnek: `UserRepository` abstract class'ı.

Kurallar:
- Implementation (gerçek kod) içermez.
- Data katmanındaki repository'ler bu interfaceleri implemente (uygular) eder.
- Data kaynaklarına olan bağımlılığı tersine çevirmek (Dependency Inversion) için kullanılır.
