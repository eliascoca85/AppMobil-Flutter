import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; // Archivo generado por FlutterFire CLI
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// --- Modelos de Datos ---

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String imagen;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.imagen,
  });

  factory Producto.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    String imagenUrl = data['imagen'] ?? '';
    // Si la imagen es SVG o vacía, usar asset local
    if (imagenUrl.isEmpty || imagenUrl.endsWith('.svg')) {
      imagenUrl = 'assets/images/default.png';
    }
    return Producto(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      precio: (data['precio'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      imagen: imagenUrl,
    );
  }
}

class ItemCarrito {
  final Producto producto;
  int cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});
}

class Pedido {
  final String id;
  final List<Map<String, dynamic>> items;
  final double total;
  final String estado;
  final DateTime fecha;

  Pedido({
    required this.id,
    required this.items,
    required this.total,
    required this.estado,
    required this.fecha,
  });

  factory Pedido.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Pedido(
      id: doc.id,
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      total: (data['total'] ?? 0.0).toDouble(),
      estado: data['estado'] ?? 'Pendiente',
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }
}

// --- Gestión de Estado del Carrito (Provider) ---

class CartProvider with ChangeNotifier {
  final Map<String, ItemCarrito> _items = {};

  Map<String, ItemCarrito> get items => {..._items};

  int get itemCount => _items.length;

  int get totalItemsCount {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.cantidad;
    });
    return total;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.producto.precio * cartItem.cantidad;
    });
    return total;
  }

  void addItem(Producto producto) {
    if (_items.containsKey(producto.id)) {
      _items.update(
        producto.id,
        (existingItem) => ItemCarrito(
          producto: existingItem.producto,
          cantidad: existingItem.cantidad + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        producto.id,
        () => ItemCarrito(producto: producto),
      );
    }
    notifyListeners();
  }

  void updateItemQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity > 0) {
      _items.update(
        productId,
        (existingItem) => ItemCarrito(
          producto: existingItem.producto,
          cantidad: quantity,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// --- Punto de Entrada de la App ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        title: 'Gestión de Pedidos',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme(
            brightness: Brightness.dark,
            primary: Color(0xFF00FFF7),
            onPrimary: Colors.black,
            secondary: Color(0xFF8F00FF),
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            background: Color(0xFF181A20),
            onBackground: Colors.white,
            surface: Color(0xFF23272F),
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF181A20),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF23272F),
            foregroundColor: Color(0xFF00FFF7),
            elevation: 4,
            titleTextStyle: TextStyle(
              color: Color(0xFF00FFF7),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 1.2,
            ),
            iconTheme: IconThemeData(color: Color(0xFF00FFF7)),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF8F00FF),
            foregroundColor: Colors.white,
            elevation: 6,
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF23272F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: const BorderSide(color: Color(0xFF00FFF7), width: 1),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF23272F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00FFF7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8F00FF), width: 2),
            ),
            labelStyle: const TextStyle(color: Color(0xFF00FFF7)),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(
              color: Colors.white,
              fontFamily: 'Orbitron',
              fontSize: 16,
            ),
            bodyMedium: TextStyle(
              color: Colors.white70,
              fontFamily: 'Orbitron',
              fontSize: 14,
            ),
            titleLarge: TextStyle(
              color: Color(0xFF00FFF7),
              fontFamily: 'Orbitron',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FFF7),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              elevation: 4,
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(0xFF8F00FF),
            contentTextStyle:
                TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
            behavior: SnackBarBehavior.floating,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF23272F),
            selectedItemColor: Color(0xFF00FFF7),
            unselectedItemColor: Colors.white54,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

// --- Pantalla Principal con Navegación ---

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    CatalogoScreen(),
    CarritoScreen(),
    HistorialScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToAdmin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda Online'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Catálogo',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: <Widget>[
                const Icon(Icons.shopping_cart),
                Consumer<CartProvider>(
                  builder: (_, cart, ch) => cart.totalItemsCount > 0
                      ? Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '${cart.totalItemsCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                )
              ],
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Mis Pedidos',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
      ),
      floatingActionButton: AdminFloatingButton(
        onPressed: () => _goToAdmin(context),
      ),
    );
  }
}

// --- Widget para obtener el rol del usuario actual ---
class AdminFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AdminFloatingButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return FutureBuilder(
      future:
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        if (data['rol'] == 'admin') {
          return FloatingActionButton(
            onPressed: onPressed,
            tooltip: 'Administración',
            child: const Icon(Icons.admin_panel_settings),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// --- Pantalla de Administración (solo para administradores) ---
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Administración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Agregar producto'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => const AddProductDialog(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar o eliminar productos'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProductsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Gestionar administradores'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageAdminsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- Diálogo para agregar producto (simplificado) ---
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _descripcionController = TextEditingController();
  bool _loading = false;
  String? _error;
  File? _pickedImage;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final cloudName = 'dseop8c3g'; // tu cloud name
      final uploadPreset = 'tiendaflutter'; // tu upload preset
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['secure_url'];
      } else {
        setState(() {
          _error = 'Error subiendo imagen: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error subiendo imagen: ${response.statusCode}')),
        );
        return null;
      }
    } catch (e) {
      setState(() {
        _error = 'Error subiendo imagen: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e')),
      );
      return null;
    }
  }

  Future<void> _addProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
        if (imageUrl == null) throw Exception('No se pudo subir la imagen');
      }
      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': _nombreController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'imagen': imageUrl ?? '',
        'descripcion': _descripcionController.text.trim(),
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado correctamente.')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_pickedImage!,
                          height: 100, width: 100, fit: BoxFit.cover),
                    )
                  : Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _addProduct,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Agregar'),
        ),
      ],
    );
  }
}

// --- Pantalla para editar/eliminar productos (simplificada) ---
class EditProductsScreen extends StatelessWidget {
  const EditProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar/Eliminar Productos')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('productos').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay productos.'));
          }
          final productos = snapshot.data!.docs;
          return ListView.builder(
            itemCount: productos.length,
            itemBuilder: (ctx, i) {
              final prod = productos[i];
              return ListTile(
                title: Text(prod['nombre'] ?? ''),
                subtitle: Text(
                    'Precio: \\${prod['precio']} | Stock: \\${prod['stock']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => EditProductDialog(
                            doc: prod,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await prod.reference.delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EditProductDialog extends StatefulWidget {
  final DocumentSnapshot doc;
  const EditProductDialog({super.key, required this.doc});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  bool _loading = false;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  // bool _loading = false;
  String? _error;
  File? _pickedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final data = widget.doc.data() as Map<String, dynamic>;
    _nombreController = TextEditingController(text: data['nombre'] ?? '');
    _descripcionController =
        TextEditingController(text: data['descripcion'] ?? '');
    _precioController =
        TextEditingController(text: data['precio']?.toString() ?? '');
    _stockController =
        TextEditingController(text: data['stock']?.toString() ?? '');
    _currentImageUrl = data['imagen'] ?? '';
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ninguna imagen.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final cloudName = 'dseop8c3g'; // tu cloud name
      final uploadPreset = 'tiendaflutter'; // tu upload preset
      final url =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);
        return data['secure_url'];
      } else {
        setState(() {
          _error = 'Error subiendo imagen: ${response.statusCode}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error subiendo imagen: ${response.statusCode}')),
        );
        return null;
      }
    } catch (e) {
      setState(() {
        _error = 'Error subiendo imagen: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e')),
      );
      return null;
    }
  }

  Future<void> _editProduct() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String? imageUrl = _currentImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
        if (imageUrl == null) throw Exception('No se pudo subir la imagen');
      }
      await widget.doc.reference.update({
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0.0,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'imagen': imageUrl ?? '',
      });
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto editado correctamente.')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar producto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _pickedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_pickedImage!,
                          height: 100, width: 100, fit: BoxFit.cover),
                    )
                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_currentImageUrl!,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/default.png',
                                      height: 100, width: 100)),
                        )
                      : Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Icon(Icons.add_a_photo,
                              size: 40, color: Colors.grey),
                        ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _editProduct,
          child: _loading
              ? const CircularProgressIndicator()
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

// --- Pantalla para gestionar administradores (simplificada) ---
class ManageAdminsScreen extends StatelessWidget {
  const ManageAdminsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Administradores')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay usuarios.'));
          }
          final usuarios = snapshot.data!.docs;
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (ctx, i) {
              final user = usuarios[i];
              return ListTile(
                title: Text(user['email'] ?? ''),
                subtitle: Text('Rol: \\${user['rol']}'),
                trailing: DropdownButton<String>(
                  value: user['rol'],
                  items: const [
                    DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) async {
                    if (val != null) {
                      await user.reference.update({'rol': val});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- Pantalla de Autenticación ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isLogin) {
        // Iniciar sesión
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // Registrarse
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Guardar usuario en Firestore con rol 'usuario'
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(cred.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'rol': 'usuario',
        });
      }
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // Cancelado

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Si es la primera vez, guarda email y rol
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'rol': 'usuario',
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Iniciar Sesión' : 'Registrarse'),
            ),
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: const Text('Iniciar sesión con Google'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin
                  ? '¿No tienes cuenta? Regístrate'
                  : '¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Pantalla: Catálogo de Productos ---

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        final productos = snapshot.data!.docs
            .map((doc) => Producto.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(10.0),
          itemCount: productos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (ctx, i) => GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(productos[i].nombre),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: productos[i].imagen.startsWith('http')
                              ? Image.network(
                                  productos[i].imagen,
                                  height: 120,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('assets/images/default.png',
                                          height: 120),
                                )
                              : Image.asset(
                                  productos[i].imagen,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                            'Precio: \$${productos[i].precio.toStringAsFixed(2)}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('Descripción:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(productos[i].descripcion.isNotEmpty
                            ? productos[i].descripcion
                            : 'Sin descripción'),
                        const SizedBox(height: 10),
                        Text('Stock: ${productos[i].stock}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        cart.addItem(productos[i]);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${productos[i].nombre} añadido al carrito.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Text('Añadir al carrito'),
                    ),
                  ],
                ),
              );
            },
            child: Card(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: productos[i].imagen.startsWith('http')
                        ? Image.network(
                            productos[i].imagen,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/images/default.png'),
                          )
                        : Image.asset(
                            productos[i].imagen,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      productos[i].nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('\$${productos[i].precio.toStringAsFixed(2)}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      child: const Text('Añadir'),
                      onPressed: () {
                        cart.addItem(productos[i]);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${productos[i].nombre} añadido al carrito.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Pantalla: Carrito de Compras ---

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return cart.items.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_shopping_cart, size: 80, color: Colors.grey),
                SizedBox(height: 20),
                Text('Tu carrito está vacío',
                    style: TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final item = cart.items.values.toList()[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              item.producto.imagen.startsWith('http')
                                  ? NetworkImage(item.producto.imagen)
                                  : AssetImage('assets/images/default.png')
                                      as ImageProvider,
                        ),
                        title: Text(item.producto.nombre),
                        subtitle: Text(
                            'Total: \$${(item.producto.precio * item.cantidad).toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () => cart.updateItemQuantity(
                                  item.producto.id, item.cantidad - 1),
                            ),
                            Text('${item.cantidad}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => cart.updateItemQuantity(
                                  item.producto.id, item.cantidad + 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text('Total', style: TextStyle(fontSize: 20)),
                      const Spacer(),
                      Chip(
                        label: Text(
                          '\$${cart.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      TextButton(
                        child: const Text('REALIZAR PEDIDO'),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            // Si no está autenticado, mostrar pantalla de login
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AuthScreen()),
                            );
                            // Después de login, volver a comprobar
                            if (FirebaseAuth.instance.currentUser == null) {
                              return;
                            }
                          }
                          await FirebaseFirestore.instance
                              .collection('pedidos')
                              .add({
                            'usuarioId': FirebaseAuth.instance.currentUser!.uid,
                            'items': cart.items.values
                                .map((item) => {
                                      'productoId': item.producto.id,
                                      'nombre': item.producto.nombre,
                                      'cantidad': item.cantidad,
                                      'precio': item.producto.precio,
                                    })
                                .toList(),
                            'total': cart.totalAmount,
                            'estado': 'Pendiente',
                            'fecha': Timestamp.now(),
                          });
                          cart.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('¡Pedido realizado con éxito!')));
                        },
                      )
                    ],
                  ),
                ),
              )
            ],
          );
  }
}

// --- Pantalla: Historial de Pedidos ---

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pedidos')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No has realizado ningún pedido.'));
        }

        final pedidosDocs = snapshot.data!.docs;
        final pedidos =
            pedidosDocs.map((doc) => Pedido.fromFirestore(doc)).toList();

        return Stack(
          children: [
            ListView.builder(
              itemCount: pedidos.length,
              itemBuilder: (ctx, i) {
                final pedido = pedidos[i];
                final pedidoDoc = pedidosDocs[i];
                // Solo mostrar botón eliminar si el pedido es del usuario actual
                final puedeEliminar =
                    user != null && pedidoDoc['usuarioId'] == user.uid;
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                              'Pedido #${pedido.id.substring(0, 6)} - \$${pedido.total.toStringAsFixed(2)}'),
                        ),
                        if (puedeEliminar)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Eliminar pedido',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar pedido'),
                                  content: const Text(
                                      '¿Estás seguro de eliminar este pedido?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancelar'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await pedidoDoc.reference.delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Pedido eliminado')),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    subtitle:
                        Text(pedido.fecha.toLocal().toString().split(' ')[0]),
                    children: pedido.items
                        .map((item) => ListTile(
                              title: Text('${item['nombre']}'),
                              subtitle: Text('Cantidad: ${item['cantidad']}'),
                              trailing: Text(
                                  '\$${(item['precio'] * item['cantidad']).toStringAsFixed(2)}'),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
            if (pedidos.isNotEmpty && user != null)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Eliminar todos'),
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar todos los pedidos'),
                        content: const Text(
                            '¿Estás seguro de eliminar todos tus pedidos?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Eliminar todos'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final userPedidos = pedidosDocs
                          .where((doc) => doc['usuarioId'] == user.uid);
                      for (final doc in userPedidos) {
                        await doc.reference.delete();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Todos los pedidos eliminados')),
                      );
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
