import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokedex',
      theme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.red,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
      ),
      home: const PokedexHomePage(),
    );
  }
}

class Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int height;
  final int weight;
  final String description;

  Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.height,
    required this.weight,
    required this.description,
  });

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['front_default'] ?? '',
      types: (json['types'] as List)
          .map((type) => type['type']['name'] as String)
          .toList(),
      height: json['height'],
      weight: json['weight'],
      description: '',
    );
  }
}

class PokedexHomePage extends StatefulWidget {
  const PokedexHomePage({super.key});

  @override
  State<PokedexHomePage> createState() => _PokedexHomePageState();
}

class _PokedexHomePageState extends State<PokedexHomePage> {
  final TextEditingController _searchController = TextEditingController();
  Pokemon? _currentPokemon;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _fetchRandomPokemon();
  }

  Future<void> _fetchPokemon(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/${query.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final pokemonData = json.decode(response.body);

        // Fetch species data for description
        final speciesResponse = await http.get(
          Uri.parse(
            'https://pokeapi.co/api/v2/pokemon-species/${pokemonData['id']}',
          ),
        );

        String description = 'No description available';
        if (speciesResponse.statusCode == 200) {
          final speciesData = json.decode(speciesResponse.body);
          final flavorTexts = speciesData['flavor_text_entries'] as List;
          final englishText = flavorTexts.firstWhere(
            (text) => text['language']['name'] == 'en',
            orElse: () => null,
          );
          if (englishText != null) {
            description = englishText['flavor_text']
                .toString()
                .replaceAll('\n', ' ')
                .replaceAll('\f', ' ');
          }
        }

        final pokemon = Pokemon.fromJson(pokemonData);
        setState(() {
          _currentPokemon = Pokemon(
            id: pokemon.id,
            name: pokemon.name,
            imageUrl: pokemon.imageUrl,
            types: pokemon.types,
            height: pokemon.height,
            weight: pokemon.weight,
            description: description,
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Pokemon not found!';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching Pokemon: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRandomPokemon() async {
    final randomId = (DateTime.now().millisecondsSinceEpoch % 1010) + 1;
    await _fetchPokemon(randomId.toString());
  }

  void _searchPokemon() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _fetchPokemon(query);
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Colors.red;
      case 'water':
        return Colors.blue;
      case 'grass':
        return Colors.green;
      case 'electric':
        return Colors.yellow;
      case 'psychic':
        return Colors.pink;
      case 'ice':
        return Colors.lightBlue;
      case 'dragon':
        return Colors.deepPurple;
      case 'dark':
        return Colors.black87;
      case 'fairy':
        return Colors.pinkAccent;
      case 'fighting':
        return Colors.brown;
      case 'poison':
        return Colors.purple;
      case 'ground':
        return Colors.orange;
      case 'flying':
        return Colors.indigo;
      case 'bug':
        return Colors.lightGreen;
      case 'rock':
        return Colors.grey;
      case 'ghost':
        return Colors.deepPurple;
      case 'steel':
        return Colors.blueGrey;
      case 'normal':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pokedex'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: _fetchRandomPokemon,
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar and Pokemon Display with padding
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search by name or number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.search),
                              hintStyle: TextStyle(fontSize: 13),
                            ),
                            onSubmitted: (_) => _searchPokemon(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _searchPokemon,
                          child: const Text('Search'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Pokemon Display
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : _currentPokemon != null
                          ? _buildPokemonCard(_currentPokemon!)
                          : const Center(child: Text('No Pokemon loaded')),
                    ),
                  ],
                ),
              ),
            ),
            //Footer
            Container(
              width: double.maxFinite,
              padding: EdgeInsets.symmetric(vertical: 5),
              color: Colors.red,
              child: Text(
                "© 2025 Joebert L. Cerezo • Pokedex App",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonCard(Pokemon pokemon) {
    return SingleChildScrollView(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pokemon Image
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[100],
                ),
                child: pokemon.imageUrl.isNotEmpty
                    ? Image.network(
                        pokemon.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(height: 16),

              // Pokemon Name and ID
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')} ${pokemon.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Pokemon Types
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pokemon.types.map((type) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Pokemon Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Height',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${pokemon.height / 10} m'),
                    ],
                  ),
                  Column(
                    children: [
                      const Text(
                        'Weight',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${pokemon.weight / 10} kg'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pokemon Description
              if (pokemon.description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    pokemon.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
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
