import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    home: FoodSearchApp(),
  ));
}

class FoodSearchApp extends StatefulWidget {
  const FoodSearchApp({super.key});

  @override
  State<FoodSearchApp> createState() => _FoodSearchAppState();
}

class _FoodSearchAppState extends State<FoodSearchApp> {
  final TextEditingController _controller = TextEditingController();
  String _searchTerm = '';
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchFood() async {
    final searchTerm = _controller.text.trim();

    if (searchTerm.isEmpty) {
      // Clear search results if search term is empty
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _searchTerm = _controller.text;
      _isLoading = true; // Start loading
    });

    const String apiKey = 'DEMO_KEY';
    final String url =
        'https://api.nal.usda.gov/fdc/v1/foods/search?query=$_searchTerm&api_key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _searchResults = json.decode(response.body)['foods'];
        _isLoading = false; // Stop loading
      });
    } else {
      // Handle error
      print('Failed to load search results');
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  void _showFoodDetails(dynamic food) {
    // Navigate to detailed view passing the food data
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FoodDetailsPage(food: food)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Search'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 300, // Adjust the width as needed
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Search for food...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        _searchFood(); // Call the search function when Enter is pressed
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchFood,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0), // Adjust padding as needed
                child:
                    CircularProgressIndicator(), // Show loading indicator if searching
              ),
            ) // Show loading indicator if searching
          else if (_searchResults.isEmpty && _searchTerm.isNotEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(20.0), // Adjust padding as needed
              child: Text(
                'No results found',
                style: TextStyle(fontSize: 18),
              ),
            ))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  final food = _searchResults[index];
                  return GestureDetector(
                    onTap: () => _showFoodDetails(food),
                    child: ListTile(
                      title: Text(food['description']),
                      subtitle: Text('ID: ${food['fdcId']}'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FoodDetailsPage extends StatelessWidget {
  final dynamic food;

  const FoodDetailsPage({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> foodNutrients = food['foodNutrients'];

    return Scaffold(
      appBar: AppBar(
        title: Text(food['description']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${food['fdcId']}'),
            const SizedBox(height: 8),
            Text('Brand: ${food['brandOwner'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Ingredients: ${food['ingredients'] ?? 'N/A'}'),
            const SizedBox(height: 16),
            const Text(
              'Nutrients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: foodNutrients.length,
                itemBuilder: (BuildContext context, int index) {
                  final nutrient = foodNutrients[index];
                  return ListTile(
                    title: Text(nutrient['nutrientName']),
                    subtitle: Text(
                        'Amount: ${nutrient['value']} ${nutrient['unitName']}'),
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
