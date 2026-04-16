# Entities (Varlıklar)
Uygulamanın en temel, başka hiçbir kütüphaneye (Flutter vs.) bağımlı olmayan nesneleridir. Sadece dart sınıflarını (class) içerir, JSON çevirme kodları barındırmazlar.

**Örnek Sınıflar:**
```dart
class User {
  final String id;
  final String name;
  User({required this.id, required this.name});
}
```
