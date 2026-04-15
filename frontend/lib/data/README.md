# Data Layer
Bu katman uygulamanın veri ihtiyacını karşılar ve dış dünya (API, Database, Local Storage) ile Domain katmanı arasındaki bağlantıyı kurar. Domain katmanında tanımlanan Repository'lerin implementasyonları (gerçekleştirimleri) burada yapılır.

## Alt Klasörler
- `datasources/` : Remote (API) veya Local (Veri Tabanı, SharedPreferences) verilerin direkt alındığı kod parçaları.
- `models/` : Veriyi pars eden, (Örn: JSON'dan dönüştüren) ve Domain katmanındaki Entities'leri miras alan yapılar (DTO).
- `repositories/` : Domain katmanındaki arayüzlerin (Interface) gerçek kodlarıyla bağlandığı yer. DataSource sınıfından veri alır, Model sınıfına dönüştürür.
