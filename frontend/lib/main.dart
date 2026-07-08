import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

void main() {
  runApp(const RentzyApp());
}

class RentzyApp extends StatelessWidget {
  const RentzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentzy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF00E676),
          surface: const Color(0xFF1E1E2E),
          background: const Color(0xFF12121A),
          error: Colors.redAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF12121A),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E1E2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF252538),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B3B5E), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  User? _currentUser;
  bool _isAuthScreen = false;

  void _onUserChanged(User? user) {
    setState(() {
      _currentUser = user;
      _isAuthScreen = false;
    });
  }

  void _logout() {
    setState(() {
      _currentUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null && _isAuthScreen) {
      return AuthScreen(onAuthSuccess: _onUserChanged, onBack: () => setState(() => _isAuthScreen = false));
    }
    return HomeScreen(
      currentUser: _currentUser,
      onLoginRequired: () => setState(() => _isAuthScreen = true),
      onLogout: _logout,
    );
  }
}

// --- AUTH SCREEN ---
class AuthScreen extends StatefulWidget {
  final Function(User) onAuthSuccess;
  final VoidCallback onBack;

  const AuthScreen({super.key, required this.onAuthSuccess, required this.onBack});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _email = '';
  String _password = '';
  String _name = '';
  String _phone = '';
  double _lat = 37.774929;
  double _long = -122.419416;
  bool _isLoading = false;
  String? _errorMessage;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? user;
    if (_isLogin) {
      user = await ApiService.login(_email, _password);
    } else {
      user = await ApiService.register(
        name: _name,
        email: _email,
        password: _password,
        phone: _phone.isEmpty ? null : _phone,
        lat: _lat,
        long: _long,
      );
    }

    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      widget.onAuthSuccess(user);
    } else {
      setState(() {
        _errorMessage = _isLogin ? 'Invalid credentials.' : 'Registration failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: widget.onBack,
                          ),
                          const Spacer(),
                          Text(
                            _isLogin ? 'Login to Rentzy' : 'Join Rentzy',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? 'Welcome back! Seed User: john@example.com (pass: password123)' : 'Create your account to start listing or rating properties',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_isLogin) ...[
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Name *'),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          onSaved: (val) => _name = val ?? '',
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email *'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
                        onSaved: (val) => _email = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Password *'),
                        obscureText: true,
                        validator: (val) => val == null || val.length < 6 ? 'Password must be 6+ chars' : null,
                        onSaved: (val) => _password = val ?? '',
                      ),
                      if (!_isLogin) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                          onSaved: (val) => _phone = val ?? '',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: '37.7749',
                                decoration: const InputDecoration(labelText: 'Latitude (Simulated)'),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => _lat = double.tryParse(val ?? '') ?? 37.7749,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '-122.4194',
                                decoration: const InputDecoration(labelText: 'Longitude (Simulated)'),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => _long = double.tryParse(val ?? '') ?? -122.4194,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  final User? currentUser;
  final VoidCallback onLoginRequired;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.currentUser,
    required this.onLoginRequired,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;

  // Search & Filter state
  final _searchController = TextEditingController();
  final _cityController = TextEditingController();
  double _radius = 5.0; // km
  bool _useLocation = false;
  String _propertyType = 'all'; // 'all', 'rent', 'sale'
  String _furnishing = 'all'; // 'all', 'fully', 'semi', 'unfurnished'
  final List<String> _selectedAmenities = [];

  // User simulated location (defaults to SF soma area)
  double _userLat = 37.774929;
  double _userLong = -122.419416;

  final List<String> _amenitiesOptions = ['AC', 'WiFi', 'Gym', 'Pool', 'Parking'];

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      _userLat = widget.currentUser!.lat ?? 37.774929;
      _userLong = widget.currentUser!.long ?? -122.419416;
      _useLocation = true;
    }
    _fetchProperties();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser != oldWidget.currentUser && widget.currentUser != null) {
      setState(() {
        _userLat = widget.currentUser!.lat ?? 37.774929;
        _userLong = widget.currentUser!.long ?? -122.419416;
        _useLocation = true;
      });
      _fetchProperties();
    }
  }

  void _fetchProperties() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getProperties(
      lat: _useLocation ? _userLat : null,
      long: _useLocation ? _userLong : null,
      radius: _radius,
      type: _propertyType,
      city: _cityController.text,
      query: _searchController.text,
      furnishing: _furnishing,
      amenities: _selectedAmenities.isEmpty ? null : _selectedAmenities,
    );
    setState(() {
      _properties = list;
      _isLoading = false;
    });
  }

  void _toggleAmenity(String amenity) {
    setState(() {
      if (_selectedAmenities.contains(amenity)) {
        _selectedAmenities.remove(amenity);
      } else {
        _selectedAmenities.add(amenity);
      }
    });
    _fetchProperties();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.maps_home_work, color: Color(0xFF6C63FF), size: 28),
            const SizedBox(width: 8),
            const Text('Rentzy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        actions: [
          if (widget.currentUser != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF6C63FF),
                      child: Text(widget.currentUser!.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.currentUser!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_box, color: Color(0xFF00E676)),
              tooltip: 'List a Property',
              onPressed: () async {
                final success = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPropertyScreen(token: widget.currentUser!.token!)),
                );
                if (success == true) {
                  _fetchProperties();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: widget.onLogout,
            ),
          ] else ...[
            TextButton.icon(
              icon: const Icon(Icons.login, color: Color(0xFF6C63FF)),
              label: const Text('Login / Sign Up', style: TextStyle(color: Color(0xFF6C63FF))),
              onPressed: widget.onLoginRequired,
            ),
            const SizedBox(width: 16),
          ]
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar Filters Panel (Web Layout)
          Container(
            width: 320,
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
              border: Border(right: BorderSide(color: Color(0xFF2D2D3E), width: 1)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Search & Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 24, color: Color(0xFF2D2D3E)),
                  
                  // Text Search
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Keyword (e.g. 1BHK, 2BHK, 3BHK)',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (_) => _fetchProperties(),
                  ),
                  const SizedBox(height: 16),

                  // City Filter
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      hintText: 'City (e.g. Kolkata)',
                      prefixIcon: Icon(Icons.location_city, size: 20),
                    ),
                    onChanged: (_) => _fetchProperties(),
                  ),
                  const SizedBox(height: 24),

                  // Radius Search toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Radius Search', style: TextStyle(fontWeight: FontWeight.bold)),
                      Switch(
                        value: _useLocation,
                        activeColor: const Color(0xFF6C63FF),
                        onChanged: (val) {
                          setState(() => _useLocation = val);
                          _fetchProperties();
                        },
                      ),
                    ],
                  ),
                  if (_useLocation) ...[
                    const SizedBox(height: 8),
                    Text('Diameter Radius: ${_radius.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.grey)),
                    Slider(
                      value: _radius,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      activeColor: const Color(0xFF6C63FF),
                      label: '${_radius.toStringAsFixed(0)} km',
                      onChanged: (val) {
                        setState(() => _radius = val);
                      },
                      onChangeEnd: (_) => _fetchProperties(),
                    ),
                    // Display current coordinates
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252538),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Searching around:\nLat: ${_userLat.toStringAsFixed(4)}, Long: ${_userLong.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12, color: Colors.amberAccent),
                      ),
                    ),
                  ],
                  const Divider(height: 32, color: Color(0xFF2D2D3E)),

                  // Property Type Selector
                  const Text('Listing Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    dropdownColor: const Color(0xFF1E1E2E),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Listings')),
                      DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                      DropdownMenuItem(value: 'sale', child: Text('For Sale / Buy')),
                    ],
                    onChanged: (val) {
                      setState(() => _propertyType = val ?? 'all');
                      _fetchProperties();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Furnishing Type Selector
                  const Text('Furnishing Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _furnishing,
                    dropdownColor: const Color(0xFF1E1E2E),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Any furnishing')),
                      DropdownMenuItem(value: 'fully', child: Text('Fully Furnished')),
                      DropdownMenuItem(value: 'semi', child: Text('Semi Furnished')),
                      DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
                    ],
                    onChanged: (val) {
                      setState(() => _furnishing = val ?? 'all');
                      _fetchProperties();
                    },
                  ),
                  const Divider(height: 32, color: Color(0xFF2D2D3E)),

                  // Amenities Checklist
                  const Text('Required Amenities', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._amenitiesOptions.map((amenity) {
                    final isChecked = _selectedAmenities.contains(amenity);
                    return CheckboxListTile(
                      title: Text(amenity),
                      value: isChecked,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF6C63FF),
                      onChanged: (_) => _toggleAmenity(amenity),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Main Listings Area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Text(
                              '${_properties.length} ${_properties.length == 1 ? 'Property' : 'Properties'} found',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            if (_useLocation)
                              const Chip(
                                avatar: Icon(Icons.my_location, size: 16, color: Colors.greenAccent),
                                label: Text('Sorted by proximity'),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _properties.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.house_siding_rounded, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No properties match your search filters.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 24,
                                  mainAxisSpacing: 24,
                                ),
                                itemCount: _properties.length,
                                itemBuilder: (context, index) {
                                  final property = _properties[index];
                                  return PropertyCard(
                                    property: property,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PropertyDetailScreen(
                                            propertyId: property.propertyId,
                                            currentUser: widget.currentUser,
                                            onLoginRequired: widget.onLoginRequired,
                                          ),
                                        ),
                                      ).then((_) => _fetchProperties());
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// --- PROPERTY CARD COMPONENT ---
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDistance = property.distance != null;
    final primaryImg = property.images.isNotEmpty
        ? property.images.first
        : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      primaryImg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
                    ),
                    // Price tag
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
                        ),
                        child: Text(
                          property.propertyType == 'rent'
                              ? '₹${property.price.toInt().toString()}/mo'
                              : '₹${property.price.toInt().toString()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    // Sale/Rent label
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: property.propertyType == 'rent' ? const Color(0xFF6C63FF) : const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          property.propertyType.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              property.rating > 0
                                  ? '${property.rating.toStringAsFixed(1)} (${property.ratingsCount})'
                                  : 'New',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${property.address}, ${property.city}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (hasDistance) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.directions_walk, size: 14, color: Colors.greenAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${property.distance!.toStringAsFixed(2)} km away',
                            style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Amenities list
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: property.amenities.take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252538),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            amenity,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PROPERTY DETAIL SCREEN ---
class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;
  final User? currentUser;
  final VoidCallback onLoginRequired;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.currentUser,
    required this.onLoginRequired,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _HomeScreenRatingState {
  int rating = 5;
  final reviewController = TextEditingController();
  bool isSubmitting = false;
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  Property? _property;
  bool _isLoading = true;
  final _ratingState = _HomeScreenRatingState();

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  void _fetchDetail() async {
    setState(() => _isLoading = true);
    final detail = await ApiService.getPropertyDetail(widget.propertyId);
    setState(() {
      _property = detail;
      _isLoading = false;
    });
  }

  void _submitReview() async {
    if (widget.currentUser == null) {
      widget.onLoginRequired();
      return;
    }

    if (_ratingState.reviewController.text.trim().isEmpty) return;

    setState(() => _ratingState.isSubmitting = true);
    final success = await ApiService.addRating(
      token: widget.currentUser!.token!,
      propertyId: widget.propertyId,
      rating: _ratingState.rating,
      review: _ratingState.reviewController.text,
    );

    setState(() => _ratingState.isSubmitting = false);

    if (success) {
      _ratingState.reviewController.clear();
      _fetchDetail(); // Reload detail
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!'), backgroundColor: Color(0xFF00E676)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property Details')),
        body: const Center(child: Text('Property not found.')),
      );
    }

    final p = _property!;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title),
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Horizontal Image Row
                SizedBox(
                  height: 350,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: p.images.isNotEmpty ? p.images.length : 1,
                    itemBuilder: (context, idx) {
                      final url = p.images.isNotEmpty ? p.images[idx] : 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=600';
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            url,
                            width: 500,
                            height: 350,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Main Info Sections
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Details & Amenities
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p.propertyType == 'rent' ? '₹${p.price.toInt().toString()}/month' : '₹${p.price.toInt().toString()}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                              ),
                              const SizedBox(width: 16),
                              Chip(
                                label: Text(p.propertyType.toUpperCase()),
                                backgroundColor: const Color(0xFF6C63FF),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('Furnishing: ${p.furnishing}'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 24),
                              const SizedBox(width: 4),
                              Text(
                                p.rating > 0 ? '${p.rating.toStringAsFixed(1)} (${p.ratingsCount} reviews)' : 'No ratings yet',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            p.description,
                            style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          const Text('Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(p.address, style: const TextStyle(fontSize: 15, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Location selected from map/GPS', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 24),
                          const Text('Amenities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: p.amenities.map((amenity) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF3B3B5E), width: 1),
                                ),
                                child: Text(amenity, style: const TextStyle(fontSize: 14)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),

                    // Right Column: Owner Card & Leave Review
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Owner Information Card
                          Card(
                            color: const Color(0xFF1E1E2E),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Contact Listed Owner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Divider(height: 24, color: Color(0xFF2D2D3E)),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundImage: p.owner.photo != null && p.owner.photo!.isNotEmpty
                                            ? NetworkImage(p.owner.photo!)
                                            : null,
                                        backgroundColor: const Color(0xFF6C63FF),
                                        child: p.owner.photo == null || p.owner.photo!.isEmpty
                                            ? Text(p.owner.name[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.owner.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                            const Text('Listed Agent / Owner', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E676),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                    icon: const Icon(Icons.phone),
                                    label: Text(p.owner.phone ?? 'No Phone Provided'),
                                    onPressed: () {}, // Simulated action
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Leave Review Form
                          Card(
                            color: const Color(0xFF1E1E2E),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text('Write a Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Divider(height: 24, color: Color(0xFF2D2D3E)),
                                  Row(
                                    children: [
                                      const Text('Rating: '),
                                      ...List.generate(5, (idx) {
                                        final starVal = idx + 1;
                                        return IconButton(
                                          icon: Icon(
                                            _ratingState.rating >= starVal ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                          ),
                                          onPressed: () {
                                            setState(() => _ratingState.rating = starVal);
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _ratingState.reviewController,
                                    maxLines: 3,
                                    decoration: const InputDecoration(
                                      hintText: 'Tell others about your experience...',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_ratingState.isSubmitting)
                                    const Center(child: CircularProgressIndicator())
                                  else
                                    ElevatedButton(
                                      onPressed: _submitReview,
                                      child: const Text('Submit Review'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 48, color: Color(0xFF2D2D3E)),
                // Reviews & Ratings List Section
                const Text('User Reviews', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (p.ratings.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No reviews yet. Be the first to review!', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: p.ratings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, idx) {
                      final r = p.ratings[idx];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: r.userPhoto != null && r.userPhoto!.isNotEmpty
                                      ? NetworkImage(r.userPhoto!)
                                      : null,
                                  backgroundColor: const Color(0xFF6C63FF),
                                  child: r.userPhoto == null || r.userPhoto!.isEmpty
                                      ? Text(r.userName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        return Icon(
                                          r.rating > starIdx ? Icons.star : Icons.star_border,
                                          color: Colors.amber,
                                          size: 14,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (r.createdAt != null)
                                  Text(
                                    r.createdAt!.substring(0, 10),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              r.review ?? '',
                              style: const TextStyle(height: 1.4, color: Colors.white70),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- ADD PROPERTY SCREEN ---
class AddPropertyScreen extends StatefulWidget {
  final String token;

  const AddPropertyScreen({super.key, required this.token});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  double _price = 0.0;
  String _propertyType = 'rent';
  String _furnishing = 'unfurnished';
  final List<String> _amenities = [];
  String _address = '';
  String _city = '';
  double _lat = 37.7749;
  double _long = -122.4194;
  final List<String> _imageUrls = [];
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  final List<String> _amenitiesOptions = ['AC', 'WiFi', 'Gym', 'Pool', 'Parking'];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Must have at least one image url, otherwise add a fallback placeholder
    final imagesList = _imageUrls.isNotEmpty
        ? _imageUrls
        : ['https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800'];

    setState(() => _isLoading = true);
    final success = await ApiService.createProperty(
      token: widget.token,
      title: _title,
      description: _description,
      price: _price,
      propertyType: _propertyType,
      furnishing: _furnishing,
      amenities: _amenities,
      address: _address,
      city: _city,
      lat: _lat,
      long: _long,
      images: imagesList,
    );
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to list property. please check server logs.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _addImageUrl() {
    if (_imageUrlController.text.trim().isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlController.text.trim());
        _imageUrlController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List New Property'),
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Property Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(height: 32, color: Color(0xFF2D2D3E)),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _title = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 4,
                        onSaved: (val) => _description = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Price (₹) *'),
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Must be a valid number' : null,
                              onSaved: (val) => _price = double.tryParse(val ?? '') ?? 0.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _propertyType,
                              decoration: const InputDecoration(labelText: 'Listing Type'),
                              dropdownColor: const Color(0xFF1E1E2E),
                              items: const [
                                DropdownMenuItem(value: 'rent', child: Text('For Rent')),
                                DropdownMenuItem(value: 'sale', child: Text('For Sale')),
                              ],
                              onChanged: (val) => setState(() => _propertyType = val ?? 'rent'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _furnishing,
                        decoration: const InputDecoration(labelText: 'Furnishing Status'),
                        dropdownColor: const Color(0xFF1E1E2E),
                        items: const [
                          DropdownMenuItem(value: 'unfurnished', child: Text('Unfurnished')),
                          DropdownMenuItem(value: 'semi', child: Text('Semi Furnished')),
                          DropdownMenuItem(value: 'fully', child: Text('Fully Furnished')),
                        ],
                        onChanged: (val) => setState(() => _furnishing = val ?? 'unfurnished'),
                      ),
                      const SizedBox(height: 24),
                      const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _amenitiesOptions.map((amenity) {
                          final isSelected = _amenities.contains(amenity);
                          return FilterChip(
                            label: Text(amenity),
                            selected: isSelected,
                            selectedColor: const Color(0xFF6C63FF),
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _amenities.add(amenity);
                                } else {
                                  _amenities.remove(amenity);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text('Location Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 24, color: Color(0xFF2D2D3E)),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Address *'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _address = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        onSaved: (val) => _city = val ?? '',
                      ),
                      const SizedBox(height: 16),
                      /*Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: '37.7749',
                              decoration: const InputDecoration(labelText: 'Latitude *'),
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Must be a valid latitude' : null,
                              onSaved: (val) => _lat = double.tryParse(val ?? '') ?? 37.7749,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              initialValue: '-122.4194',
                              decoration: const InputDecoration(labelText: 'Longitude *'),
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Must be a valid longitude' : null,
                              onSaved: (val) => _long = double.tryParse(val ?? '') ?? -122.4194,
                            ),
                          ),
                        ],
                      ),*/
                      const SizedBox(height: 24),
                      const Text('Property Images (URLs)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: 24, color: Color(0xFF2D2D3E)),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _imageUrlController,
                              decoration: const InputDecoration(
                                hintText: 'Image URL (e.g. Unsplash URL)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF00E676), size: 36),
                            onPressed: _addImageUrl,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_imageUrls.isNotEmpty) ...[
                        const Text('Added Images:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: _imageUrls.map((url) {
                            return Chip(
                              label: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onDeleted: () {
                                setState(() => _imageUrls.remove(url));
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Publish Listing'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}