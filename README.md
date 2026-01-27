# DeepLinkHandler

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

Una librería Swift moderna y desacoplada para el manejo centralizado de deep links y navegación en aplicaciones iOS con UIKit. Diseñada con arquitectura limpia y principios SOLID, permite gestionar rutas de navegación sin crear dependencias fuertes entre módulos.

## 📋 Tabla de Contenidos

- [Características](#-características)
- [Arquitectura](#-arquitectura)
- [Instalación](#-instalación)
- [Inicio Rápido](#-inicio-rápido)
- [Guía de Uso](#-guía-de-uso)
- [API Reference](#-api-reference)
- [Mejores Prácticas](#-mejores-prácticas)
- [Ejemplos Avanzados](#-ejemplos-avanzados)

## ✨ Características

- 🔗 **Manejo Centralizado de Deep Links**: Sistema unificado para procesar y enrutar deep links sin acoplamiento entre módulos
- 🧭 **Navegación Desacoplada**: Sistema de navegación basado en URLs que elimina dependencias directas entre ViewControllers
- 🎯 **Pattern Matching Inteligente**: Motor de matching avanzado con soporte para parámetros tipados (`:id`, `:uuid`, `:string`, etc.)
- 🔄 **Soporte Async/Await**: APIs modernas con soporte completo para async/await (iOS 13+)
- 🏗️ **Arquitectura Modular**: Diseño basado en módulos que permite escalabilidad y mantenibilidad
- 🎨 **Transiciones Flexibles**: Soporte para diferentes tipos de transiciones (push, modal, root) con estilos personalizables
- ✅ **Validación de Parámetros**: Validación automática de parámetros requeridos antes de ejecutar handlers
- 📦 **Type-Safe**: Uso de tipos seguros y protocolos para prevenir errores en tiempo de compilación

## 🏗️ Arquitectura

DeepLinkHandler está construido siguiendo principios de **Clean Architecture** y **Domain-Driven Design**, organizando el código en capas bien definidas:

```
DeepLinkHandler/
├── Domain/              # Lógica de negocio y entidades
│   ├── Entities/        # Entidades del dominio
│   ├── Services/        # Servicios del dominio
│   └── ValueObjects/    # Objetos de valor
├── Delivery/            # Capa de presentación y casos de uso
│   ├── Application/    # Flujos de aplicación
│   └── Builder/        # Builders para construcción de URLs
└── Infrastructure/     # Implementaciones técnicas
    ├── Adapters/       # Adaptadores para integración
    └── Repositories/   # Repositorios de datos
```

### Componentes Principales

- **DeepLinkHandler**: Singleton que actúa como orquestador central para el registro y procesamiento de deep links
- **DeepLinkMatcher**: Motor de matching que resuelve URLs contra patrones registrados y extrae parámetros
- **AppFlowRouter**: Protocolo que define la interfaz para navegación y routing
- **DeepLinkModule**: Protocolo que deben implementar los módulos para manejar deep links específicos
- **ApplicationInteractor**: Abstracción para la interacción con la navegación de la aplicación

## 📦 Instalación

### Swift Package Manager

Agrega DeepLinkHandler como dependencia en tu `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tu-usuario/DeepLinkHandler.git", from: "1.0.0")
]
```

O en Xcode:
1. File → Add Packages...
2. Ingresa la URL del repositorio
3. Selecciona la versión deseada

### Requisitos

- iOS 13.0+
- Swift 5.10+
- Xcode 14.0+

## 🚀 Inicio Rápido

> **💡 Configuración del Scheme**: DeepLinkHandler permite configurar el scheme de deep links una sola vez durante el setup de la aplicación. Esto significa que en tus módulos solo necesitas especificar el **path** (sin el scheme), y el sistema automáticamente construirá las URLs completas usando el scheme configurado. Esto facilita el mantenimiento y permite cambiar el scheme fácilmente por entorno (dev, staging, production).

### 1. Configuración Inicial

En tu `AppDelegate` o `SceneDelegate`, configura la navegación y el scheme de deep links:

```swift
import UIKit
import DeepLinkHandler

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Configurar navegación centralizada y scheme de deep links
        // El scheme se usa para construir URLs completas automáticamente
        AppFlow.setupNavigation(window: window!, scheme: "myapp")
        
        // Registrar módulos de deep links
        registerDeepLinkModules()
        
        window?.makeKeyAndVisible()
        return true
    }
    
    private func registerDeepLinkModules() {
        // Registrar módulos aquí
        AppFlow.router.subscribe {
            ProfileModule()
        }
    }
}
```

> **Nota Importante**: El scheme se configura una sola vez durante el setup. Todos los deep links registrados usarán automáticamente este scheme, por lo que solo necesitas especificar el path en los módulos.

### 2. Crear un Módulo de Deep Link

Define un módulo que implemente `AppModule` y `DeepLinkModule`. **Solo especifica el path, sin el scheme**:

```swift
import Foundation
import DeepLinkHandler
import UIKit

// Definir el módulo que contiene los deep links
class ProfileModule: AppModule {
    var urls: [DeepLinkModule] = [
        ProfileDeepLink()
    ]
}

// Implementar el handler específico para el deep link
// ⚠️ IMPORTANTE: Solo especifica el path, sin el scheme
// El scheme se agrega automáticamente desde la configuración
struct ProfileDeepLink: DeepLinkModule {
    var url: URLPattern = "profile/:id"  // Sin "myapp://"
    var parameters: [String] = [] // Parámetros requeridos en query params
    var type: DeeplinkType = .navigation
    
    func handle(
        fullPath: URLConvertible,
        values: [String: Any],
        data: Data?,
        completion: AppNavigationCompletion?
    ) {
        // Extraer el ID del path
        guard let userId = values["id"] as? String else {
            completion?(.failure(DeepLinkError.missingParameters(params: ["id"])))
            return
        }
        
        // Crear y navegar al ViewController
        let profileVC = ProfileViewController(userId: userId)
        NavigationService.shared.navigate(
            to: fullPath,
            with: .push,
            viewController: profileVC
        )
        
        completion?(.success(Data()))
    }
}
```

> **💡 Ventaja**: Al no especificar el scheme en cada módulo, puedes cambiar el scheme de toda la aplicación desde un solo lugar (`AppFlow.setupNavigation`), facilitando el mantenimiento y la configuración por entorno (dev, staging, production).

### 3. Procesar Deep Links Entrantes

En tu `AppDelegate`, maneja los deep links:

```swift
func application(_ app: UIApplication,
                 open url: URL,
                 options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    AppFlow.router.open(url: url.absoluteString) { result in
        switch result {
        case .success:
            print("Deep link procesado exitosamente")
        case .failure(let error):
            print("Error procesando deep link: \(error.localizedDescription)")
        }
    }
    return true
}
```

## 📖 Guía de Uso

### Configuración del Scheme

El scheme se configura una sola vez durante el setup de la aplicación usando `AppFlow.setupNavigation(window:scheme:)`. Todos los deep links registrados automáticamente usarán este scheme:

```swift
// Configurar scheme durante el setup
AppFlow.setupNavigation(window: window, scheme: "myapp")

// También puedes configurarlo manualmente después
DeepLinkConfig.configure(scheme: "myapp")
```

**Ventajas de este enfoque:**
- ✅ Cambio centralizado del scheme
- ✅ Fácil configuración por entorno
- ✅ Menos código repetitivo en módulos
- ✅ Mejor mantenibilidad

### Registro de Módulos

Los módulos se registran usando el método `subscribe` del router:

```swift
AppFlow.router.subscribe {
    ProfileModule()
}

AppFlow.router.subscribe {
    SettingsModule()
}

AppFlow.router.subscribe {
    CheckoutModule()
}
```

### Patrones de URL

DeepLinkHandler soporta patrones de URL flexibles con parámetros tipados. **Solo especifica el path, sin el scheme**:

```swift
// Parámetros simples (sin scheme)
"profile/:id"                    // Se convierte en: myapp://profile/:id
"user/:id/posts/:postId"         // Se convierte en: myapp://user/:id/posts/:postId

// Parámetros tipados
"product/:int:id"                // Extrae Int, se convierte en: myapp://product/:int:id
"user/:uuid:userId"              // Extrae UUID, se convierte en: myapp://user/:uuid:userId
"search/:string:query"           // Extrae String, se convierte en: myapp://search/:string:query
"files/:path:filePath"           // Extrae path completo, se convierte en: myapp://files/:path:filePath

// Query parameters (se pueden especificar en la URL completa al abrir)
"search"                          // Path base, query params se agregan al abrir
```

**Al abrir deep links**, puedes usar solo el path o la URL completa:

```swift
// Opción 1: Solo path (recomendado) - usa el scheme configurado
AppFlow.router.open(url: "profile/123") { result in }

// Opción 2: URL completa (si necesitas otro scheme o URL externa)
AppFlow.router.open(url: "myapp://profile/123") { result in }
```

### Tipos de Deep Links

Existen dos tipos de deep links:

- **`.navigation`**: Para navegación entre pantallas
- **`.services`**: Para llamadas a servicios o acciones sin navegación

```swift
var type: DeeplinkType = .navigation  // Para navegación
var type: DeeplinkType = .services     // Para servicios
```

### Transiciones de Navegación

El sistema soporta tres tipos de transiciones:

```swift
enum NavigationTransitions {
    case push      // Push en el navigation stack
    case modal     // Presentación modal
    case root      // Cambiar root view controller
}
```

#### Especificar Transición en la URL

Puedes especificar la transición directamente en la URL (al abrir el deep link):

```swift
// Al abrir, puedes agregar query parameters para la transición
AppFlow.router.open(url: "profile/123?presentation=modal&modalPresentationStyle=pageSheet") { result in }

// En el handler, la URL completa ya incluye estos parámetros
NavigationService.shared.navigate(
    to: fullPath,  // La URL contiene la información de transición
    with: .push,   // Fallback si no se especifica en la URL
    viewController: profileVC
)
```

### Uso con Async/Await

Para iOS 13+, puedes usar async/await. Puedes usar solo el path (recomendado):

```swift
Task {
    do {
        // Solo path - el scheme se agrega automáticamente
        let result = try await AppFlow.router.open(
            url: "profile/123"
        )
        print("Navegación completada")
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

// También puedes usar URL completa si es necesario
Task {
    do {
        let result = try await AppFlow.router.open(
            url: "myapp://profile/123"
        )
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

### Property Wrapper para Deep Links

Usa el property wrapper `@DeepLink` para definir rutas de forma type-safe. **Solo especifica el path**:

```swift
struct AppRoutes {
    // Solo path, sin scheme
    @DeepLink("profile/:id")
    static var profile: DeepLinkPath
    
    @DeepLink("settings", tracing: "settings_screen")
    static var settings: DeepLinkPath
}

// Uso - el scheme se agrega automáticamente
AppFlow.router.open(url: AppRoutes.profile) { result in
    // ...
}
```

### DeepLinkBuilder

Construye URLs complejas de forma fluida. El builder usa automáticamente el scheme configurado:

```swift
let url = DeepLinkBuilder(AppRoutes.profile)
    .addPathSegment("oauth")
    .addPathSegment("12345")
    .addParameter(key: "token", value: "abc123")
    .addParameter(key: "presentation", value: "modal")
    .build()

// Resultado (con scheme "myapp" configurado):
// "myapp://profile/:id/oauth/12345?token=abc123&presentation=modal"
```

### Context y Observer

Para casos avanzados, puedes pasar contexto y observadores:

```swift
let context = Context(
    view: containerView,
    parentViewController: parentVC
)

let observer: Observer = { observable in
    observable.value?.forEach { key, value in
        print("\(key): \(value)")
    }
}

AppFlow.router.open(
    url: "embedded/view",  // Solo path, el scheme se agrega automáticamente
    data: nil,
    context: context,
    observer: observer
) { result in
    // ...
}
```

## 📚 API Reference

### DeepLinkHandler

Clase singleton principal para el manejo de deep links.

```swift
public final class DeepLinkHandler {
    public static let shared: DeepLinkHandler
    
    // Registrar módulo
    public func registerModule(factory: @escaping () -> AppModule)
    
    // Abrir deep link
    public func open(url: String, completion: AppNavigationCompletion?)
    public func open(_ deepLink: DeepLinkPath, completion: AppNavigationCompletion?)
    public func open(url: String, data: Data?, completion: AppNavigationCompletion?)
}
```

### AppFlowRouter

Protocolo que define la interfaz de routing.

```swift
public protocol AppFlowRouter {
    func open(url: String, data: Data?, context: Context?, observer: Observer?, callback: AppNavigationCompletion?)
    func open(url: DeepLinkPath, data: Data?, context: Context?, observer: Observer?, callback: AppNavigationCompletion?)
    func subscribe(factory: @escaping () -> AppModule)
    
    // Async/Await (iOS 13+)
    @available(iOS 13.0, *)
    func open(url: String, data: Data?, context: Context?, observer: Observer?) async throws -> Data
}
```

### DeepLinkModule

Protocolo que deben implementar los handlers de deep links.

```swift
public protocol DeepLinkModule {
    var url: URLPattern { get }
    var parameters: [String] { get }
    var type: DeeplinkType { get }
    
    func handle(
        fullPath: URLConvertible,
        values: [String: Any],
        data: Data?,
        completion: AppNavigationCompletion?
    )
}
```

### NavigationService

Servicio singleton para navegación.

```swift
public struct NavigationService {
    public static var shared: NavigationService
    
    public func navigate(using transition: NavigationTransitions, viewController: UIViewController)
    public func navigate(to urlConvertible: URLConvertible, with defaultTransition: NavigationTransitions, viewController: UIViewController)
}
```

### DeepLinkError

Errores que pueden ocurrir durante el procesamiento:

```swift
public enum DeepLinkError: Error {
    case handlerNotFound(url: String)
    case unmatchedPattern(url: String)
    case missingParameters(params: [String])
}
```

## 🎯 Mejores Prácticas

### 1. Organización por Módulos

Agrupa deep links relacionados en módulos:

```swift
class UserModule: AppModule {
    var urls: [DeepLinkModule] = [
        UserProfileDeepLink(),
        UserSettingsDeepLink(),
        UserPostsDeepLink()
    ]
}
```

### 2. Validación Temprana

Valida parámetros requeridos al inicio del handler:

```swift
func handle(fullPath: URLConvertible, values: [String: Any], data: Data?, completion: AppNavigationCompletion?) {
    guard let userId = values["id"] as? String,
          let email = fullPath.queryParameters["email"] else {
        completion?(.failure(DeepLinkError.missingParameters(params: ["id", "email"])))
        return
    }
    // Continuar con la lógica...
}
```

### 3. Separación de Responsabilidades

Mantén los handlers enfocados solo en la navegación o acción específica:

```swift
struct CheckoutDeepLink: DeepLinkModule {
    func handle(...) {
        // 1. Validar parámetros
        // 2. Crear ViewController o ejecutar acción
        // 3. Navegar o completar
        // NO: Lógica de negocio compleja aquí
    }
}
```

### 4. Uso de DeepLinkPath

Define rutas centralizadas para evitar strings mágicos. **Solo especifica el path**:

```swift
extension DeepLinkPath {
    static var profile: DeepLinkPath {
        DeepLinkPath(path: "profile/:id", tracingKey: "profile_screen")
    }
    
    static var checkout: DeepLinkPath {
        DeepLinkPath(path: "checkout", tracingKey: "checkout_flow")
    }
}
```

### 4.1. Configuración del Scheme

Configura el scheme una sola vez durante el setup de la aplicación. Esto permite cambiar el scheme fácilmente por entorno:

```swift
// En AppDelegate o SceneDelegate
func application(_ application: UIApplication, 
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // Configurar scheme según el entorno
    #if DEBUG
    let scheme = "myapp-dev"
    #elseif STAGING
    let scheme = "myapp-staging"
    #else
    let scheme = "myapp"
    #endif
    
    AppFlow.setupNavigation(window: window!, scheme: scheme)
    
    return true
}
```

### 5. Manejo de Errores

Implementa manejo robusto de errores:

```swift
AppFlow.router.open(url: urlString) { result in
    switch result {
    case .success(let data):
        // Procesar éxito
        break
    case .failure(let error):
        switch error {
        case .handlerNotFound(let url):
            // Mostrar error al usuario o log
            break
        case .missingParameters(let params):
            // Validar y solicitar parámetros faltantes
            break
        case .unmatchedPattern(let url):
            // Log para debugging
            break
        }
    }
}
```

## 🔥 Ejemplos Avanzados

### Deep Link con Parámetros Complejos

```swift
struct ProductDetailDeepLink: DeepLinkModule {
    // Solo path, sin scheme
    var url: URLPattern = "product/:int:productId/:string:category"
    var parameters: [String] = ["source"]
    var type: DeeplinkType = .navigation
    
    func handle(fullPath: URLConvertible, values: [String: Any], data: Data?, completion: AppNavigationCompletion?) {
        guard let productId = values["productId"] as? Int,
              let category = values["category"] as? String,
              let source = fullPath.queryParameters["source"] else {
            completion?(.failure(DeepLinkError.missingParameters(params: ["source"])))
            return
        }
        
        let productVC = ProductDetailViewController(
            productId: productId,
            category: category,
            source: source
        )
        
        NavigationService.shared.navigate(
            to: fullPath,
            with: .push,
            viewController: productVC
        )
        
        completion?(.success(Data()))
    }
}
```

### Deep Link para Servicios (Sin Navegación)

```swift
struct LogoutDeepLink: DeepLinkModule {
    // Solo path, sin scheme
    var url: URLPattern = "auth/logout"
    var parameters: [String] = []
    var type: DeeplinkType = .services
    
    func handle(fullPath: URLConvertible, values: [String: Any], data: Data?, completion: AppNavigationCompletion?) {
        // Ejecutar lógica de logout
        AuthService.shared.logout()
        
        // Navegar a login (opcional)
        let loginVC = LoginViewController()
        NavigationService.shared.navigate(
            using: .root,
            viewController: loginVC
        )
        
        completion?(.success(Data()))
    }
}
```

### Deep Link con Payload Data

```swift
struct ShareContentDeepLink: DeepLinkModule {
    // Solo path, sin scheme
    var url: URLPattern = "share/:string:contentType"
    var parameters: [String] = []
    var type: DeeplinkType = .navigation
    
    func handle(fullPath: URLConvertible, values: [String: Any], data: Data?, completion: AppNavigationCompletion?) {
        guard let contentType = values["contentType"] as? String else {
            completion?(.failure(DeepLinkError.missingParameters(params: ["contentType"])))
            return
        }
        
        // Decodificar payload si existe
        var sharedContent: ShareableContent?
        if let data = data {
            sharedContent = try? JSONDecoder().decode(ShareableContent.self, from: data)
        }
        
        let shareVC = ShareViewController(
            contentType: contentType,
            content: sharedContent
        )
        
        NavigationService.shared.navigate(
            to: fullPath,
            with: .modal,
            viewController: shareVC
        )
        
        completion?(.success(Data()))
    }
}
```

### Integración con Universal Links

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return
    }
    
    // Convertir universal link a deep link interno
    let deepLinkURL = convertUniversalLinkToDeepLink(url)
    
    AppFlow.router.open(url: deepLinkURL) { result in
        // Manejar resultado
    }
}
```

### Testing

```swift
import XCTest
@testable import DeepLinkHandler

class DeepLinkHandlerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Configurar scheme para testing
        DeepLinkConfig.configure(scheme: "testapp")
    }
    
    func testProfileDeepLink() {
        let expectation = expectation(description: "Deep link processed")
        
        // Puedes usar solo el path o la URL completa
        AppFlow.router.open(url: "profile/123") { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Error: \(error.localizedDescription)")
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}
```

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👤 Autor

**Junior Quevedo Gutiérrez**

## 🙏 Agradecimientos

- Inspirado en arquitecturas modernas de routing y deep linking
- Diseñado siguiendo principios SOLID y Clean Architecture

---

⭐ Si este proyecto te resulta útil, considera darle una estrella en GitHub.
