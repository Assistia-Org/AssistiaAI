# Core Layer
Bu katman, projede bulunan diğer Domain, Data ve Presentation katmanlarının ortak olarak kullanabileceği yapıntıları içerir. Tüm mimariye hizmet eden çekirdek kısımdır.

## Alt Klasörler
- `constants/` : Uygulamada değişmeyecek sabitler (Örneğin: API Base URL, asset dizinleri vb.).
- `errors/` : Uygulamada yaşanabilecek ortak hata tipleri (Exceptions ve Failures).
- `network/` : Ağ isteği yapan ana yapılandırmalar (Örn: Dio client ayarları, Token Interceptor vb.).
- `theme/` : Ortak renkler, yazı tipleri ve uygulamanın tema modları.
- `utils/` : Çeşitli yardımcı formatlayıcı fonksiyonlar.
