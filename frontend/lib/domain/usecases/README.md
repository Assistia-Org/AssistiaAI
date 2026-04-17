# Use Cases (Kullanım Senaryoları / İş Mantığı)

Bu klasör, uygulamanın özel kullanım senaryolarını (Use Cases) barındırır.
Use case'ler, domain repositories interfacelerini kullanarak uygulamanın iş mantığını yürütür.

Örnek: `LoginUserUseCase`, `GetProductsUseCase`, `CreateOrderUseCase`.

Kurallar:
- Her sınıf genellikle tek bir işi (Single Responsibility) yapar (örn: sadece giriş yapma işlemi).
- Sadece `domain/repositories` içindeki interfacelerle konuşur.
- UI (Presentation) katmanındaki State Management (Provider, BLoC vs) yapıları doğrudan `UseCases` ile iletişim kurar.
