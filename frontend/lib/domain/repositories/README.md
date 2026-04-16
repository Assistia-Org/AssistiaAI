# Repositories (Arayüzler / Interfaces)
Verilerin nereden alınacağıyla ilgilenmeden, sistemin neye ihtiyacı olduğunu belirten sözleşmelerdir (Abstract Classes).

**Örnek Sınıflar:**
```dart
abstract class AuthRepository {
  Future<User> login(String username, String password);
}
```
