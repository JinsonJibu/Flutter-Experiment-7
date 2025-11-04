import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProductApp());
}

class ProductApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product Inventory Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProductScreen(),
    );
  }
}

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  String status = "";

  // Firestore reference
  final CollectionReference products =
      FirebaseFirestore.instance.collection('products');

  // Function to add product
  Future<void> addProduct() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      await products.add({
        'name': _nameController.text,
        'quantity': int.parse(_quantityController.text),
        'price': double.parse(_priceController.text),
      });

      setState(() {
        status = "Product saved successfully!";
      });

      // Clear fields
      _nameController.clear();
      _quantityController.clear();
      _priceController.clear();
    }
  }

  // Calculate total stock value
  double calculateTotalStockValue(List<QueryDocumentSnapshot> products) {
    double total = 0;
    for (var product in products) {
      total += (product['quantity'] as num) * (product['price'] as num);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Inventory Tracker'),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Product Name'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter product name' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter quantity' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Please enter price' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: addProduct,
                    child: Text('Save Product'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    status,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: products.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final records = snapshot.data!.docs;
                  if (records.isEmpty) {
                    return Center(child: Text('No products found'));
                  }

                  // Calculate total stock value
                  double totalStockValue = calculateTotalStockValue(records);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final product = records[index];
                            final quantity = product['quantity'] as num;
                            final price = product['price'] as num;

                            return ListTile(
                              title: Text(product['name']),
                              subtitle: Text(
                                'Quantity: $quantity, Price: \$${price.toStringAsFixed(2)}',
                              ),
                              trailing: quantity < 5
                                  ? Text(
                                      'Low Stock!',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Text(
                          'Total Stock Value: \$${totalStockValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
