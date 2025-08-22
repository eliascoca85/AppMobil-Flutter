## Ejecución rápida del proyecto

1. **Requisitos previos**:
	- Flutter instalado ([guía oficial](https://docs.flutter.dev/get-started/install))
	- Cuenta de Firebase y Cloudinary (configurar credenciales en el código)
2. **Instalar dependencias**:
	- Ejecuta en terminal:
	  ```
	  flutter pub get
	  ```
3. **Configurar Firebase**:
	- Descarga `google-services.json` de tu proyecto Firebase y colócalo en `android/app/`.
	- Asegúrate de tener configurado Firestore y Auth en Firebase Console.
4. **Configurar Cloudinary**:
	- Crea un upload preset unsigned y copia el nombre y cloud name en el código (`main.dart`).
5. **Ejecutar la app**:
	- Conecta un dispositivo o emulador Android y ejecuta:
	  ```
	  flutter run
	  ```
6. **Permisos**:
	- Acepta los permisos de almacenamiento/galería en el dispositivo para subir imágenes.

---
samples, guidance on mobile development, and a full API reference.

# gestion_pedidos_flutter

Aplicación Flutter para gestión de pedidos, productos y usuarios con autenticación y panel de administración.

## Tecnologías y APIs utilizadas

- **Flutter**: Framework para desarrollo de apps móviles multiplataforma.
- **Firebase Auth**: Autenticación de usuarios (email, Google).
- **Cloud Firestore**: Base de datos NoSQL en tiempo real para productos, pedidos y usuarios.
- **Provider**: Gestión de estado reactivo en la app.
- **Cloudinary**: Almacenamiento y entrega de imágenes de productos mediante API REST.
- **image_picker**: Permite seleccionar imágenes desde la galería del dispositivo.
- **http**: Realiza peticiones HTTP para subir imágenes a Cloudinary.

## Principales métodos y flujos

- **Autenticación**: Registro e inicio de sesión de usuarios y administradores usando Firebase Auth.
- **Gestión de productos**: CRUD de productos (crear, editar, eliminar) con imágenes subidas a Cloudinary.
- **Gestión de pedidos**: Los usuarios pueden realizar y eliminar pedidos; los administradores pueden ver y gestionar todos los productos.
- **Subida de imágenes**: Se selecciona una imagen con image_picker y se sube a Cloudinary usando un upload preset unsigned vía HTTP POST. Se almacena la URL devuelta en Firestore.
- **Roles**: Los usuarios tienen rol de 'usuario' o 'admin', controlado en la colección 'usuarios' de Firestore.

## ¿Cómo funciona?

1. El usuario se registra o inicia sesión (Firebase Auth).
2. Puede ver productos, agregarlos al carrito y realizar pedidos (Firestore).
3. Los administradores pueden agregar/editar productos, subir imágenes (Cloudinary), y gestionar otros administradores.
4. Las imágenes se suben a Cloudinary y se muestran en la app mediante su URL pública.

---
Este proyecto es una base para apps de e-commerce o gestión de inventario con autenticación y panel administrativo.

##PRIMERA VERSION 

Ejecutable https://www.mediafire.com/file/e147dhc38qal33i/app-release.apk/file o mi github Releases
