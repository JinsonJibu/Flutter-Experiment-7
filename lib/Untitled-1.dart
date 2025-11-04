import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProductSearchApp());
}

class ProductSearchApp extends StatelessWidget {
  const ProductSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Search',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductSearchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? productData;
  bool isSearching = false;
  String errorMessage = '';

  Future<void> searchProduct() async {
    setState(() {
      isSearching = true;
      productData = null;
      errorMessage = '';
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: _searchController.text.trim())
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'Product not found';
          isSearching = false;
        });
        return;
      }

      setState(() {
        productData = querySnapshot.docs.first.data();
        isSearching = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error searching product: $e';
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Search'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Product Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: searchProduct,
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isSearching)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (productData != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          'Name: ${productData!['name']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        leading: const Icon(Icons.inventory),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          'Quantity: ${productData!['quantity']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        leading: const Icon(Icons.numbers),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          'Price: \$${productData!['price']}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        leading: const Icon(Icons.attach_money),
                      ),
                      if (productData!['quantity'] < 5)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Low Stock!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}