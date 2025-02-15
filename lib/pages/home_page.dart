import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/MathPartido.dart';
import 'package:user_auth_crudd10/model/OrderItem.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/model/Torneo.dart';
import 'package:user_auth_crudd10/pages/Mercadopago/paymentScreen.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/AvailableMatchesScreen.dart';
import 'package:user_auth_crudd10/pages/PartidosDisponibles/MatchDetailsScreen.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/invitaciones.screen.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentDetails.dart';
import 'package:user_auth_crudd10/pages/screens/Tournaments/TournamentScreen.dart';
import 'package:user_auth_crudd10/pages/screens/stories/StoriesSection.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/StoriesService.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/services/torneo_service.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Torneo>> futureTorneos;
  final int count = 0;
  int _invitacionesPendientes = 0;
  final _equipoService = EquipoService();
  late Future<List<Story>> futureStories;

final MatchService _matchService = MatchService();
late Future<List<MathPartido>> futureMatches;

  DateTime selectedDate = DateTime.now();
  List<DateTime> next7Days = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    futureStories = StoriesService().getStories();
    _loadUserProfile();
    _loadInvitaciones();
    // Inicializar next7Days
    for (int i = 0; i < 7; i++) {
      next7Days.add(DateTime.now().add(Duration(days: i)));
    }
      _loadMatches();


  }

  final _authService = AuthService();
  Map<String, dynamic>? userData;

  String? imageUrl;

  Future<void> _loadInvitaciones() async {
    try {
      final count = await _equipoService.getInvitacionesPendientesCount();
      setState(() {
        _invitacionesPendientes = count;
      });
    } catch (e) {
      print('Error cargando invitaciones: $e');
    }
  }

  

  Future<void> _cargarDatos() async {
    setState(() {
      futureTorneos = TorneoService().getTorneos();
      _loadUserProfile();
      _loadInvitaciones();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _authService.getProfile();
      setState(() {
        userData = response;
      });
    } catch (e) {
      print('Error cargando perfil: $e');
    }
  }

  void _loadMatches() {
  setState(() {
    futureMatches = _matchService.getAvailableMatches(selectedDate);
  });
}

  @override
  Widget build(BuildContext context) {
    if (userData != null && userData!['profile_image'] != null) {
      imageUrl =
          'https://proyect.aftconta.mx/storage/${userData!['profile_image']}';
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: CustomScrollView(
                  slivers: [
                    // Contenido principal
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Buscador
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Foto de perfil
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(Icons.person,
                                                      color: Colors.blue),
                                            )
                                          : Icon(Icons.person,
                                              color: Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  // Saludo y nombre
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Hola,',
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                                255, 87, 84, 84),
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          userData!['name'] ?? '',
                                          style: GoogleFonts.inter(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Botones
                                  //aqui va las notificaciones de invitaciones
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withOpacity(0.1),
                                    ),
                                    child: Stack(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.notifications_none,
                                              color: Colors.blue),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      InvitacionesScreen()),
                                            ).then((_) => _loadInvitaciones());
                                          },
                                        ),
                                        if (_invitacionesPendientes > 0)
                                          Positioned(
                                            right: 8,
                                            top: 8,
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                _invitacionesPendientes
                                                    .toString(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),
// Add after search container
                            const StoriesSection(),

                            ElevatedButton(
                              onPressed: () async {
                                final items = [
                                  OrderItem(
                                    title: "Producto 1",
                                    quantity: 1,
                                    unitPrice: 100.0,
                                  ),
                                ];

                                try {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        items: items,
                                        customerName: 'Nombre del Cliente',
                                        customerEmail: 'email@cliente.com',
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('¡Pago exitoso!')),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: Text('Pagar ahora'),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Torneos Activos',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => TournamentsScreen()),
                                    );
                                  },
                                  child: Text('Ver todos'),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: FutureBuilder<List<Torneo>>(
                                future: futureTorneos,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Error de conexión',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                futureTorneos = TorneoService()
                                                    .getTorneos();
                                              });
                                            },
                                            child: Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return Center(
                                        child: Text(
                                            'No hay torneos disponibles.'));
                                  }

                                  return CarouselSlider.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index, realIndex) {
                                      Torneo torneo = snapshot.data![index];
                                      return Container(
                                        width:
                                            320, // Ancho fijo para cada tarjeta
                                        margin: EdgeInsets.only(
                                            right: 8), // Espacio entre tarjetas
                                        child:
                                            _buildTorneoCard(context, torneo),
                                      );
                                    },
                                    options: CarouselOptions(
                                      height: 220,
                                      aspectRatio: 16 / 9,
                                      viewportFraction:
                                          0.8, // Muestra parcialmente las tarjetas adyacentes
                                      initialPage: 0,
                                      enableInfiniteScroll: true,
                                      reverse: false,
                                      autoPlay: true,
                                      autoPlayInterval: Duration(seconds: 5),
                                      autoPlayAnimationDuration:
                                          Duration(milliseconds: 800),
                                      autoPlayCurve: Curves.fastOutSlowIn,
                                      enlargeCenterPage: true,
                                      scrollDirection: Axis.horizontal,
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: 24),

                            // Sección de partidos disponibles
                           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'Partidos Disponibles',
      style: TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AvailableMatchesScreen()),
        );
      },
      child: Text('Ver todos'),
    ),
  ],
),
SizedBox(height: 16),
Container(
  height: 100,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: next7Days.length,
    itemBuilder: (context, index) {
      final date = next7Days[index];
      final isSelected = DateUtils.isSameDay(date, selectedDate);
      return GestureDetector(
      onTap: () {
  setState(() {
    selectedDate = date;
    _loadMatches();  
  });
},
        child: Container(
          width: 70,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(date).toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('d').format(date),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
FutureBuilder<List<MathPartido>>(
  future: futureMatches,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error cargando partidos'));
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: Text('No hay partidos disponibles'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 45, left: 16, right: 16),
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        final match = snapshot.data![index];
        
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 6,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.sports_soccer, color: Colors.white),
            ),
            title: Text(
              match.fieldName,
              style: TextStyle(fontWeight: FontWeight.bold , color: Colors.black),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
Text('${match.formattedStartTime} - ${match.formattedEndTime}',  style: TextStyle(color: Colors.orange)),                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${match.currentPlayers}/${match.maxPlayers} jugadores',),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${match.price}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.status == 'open' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    match.status == 'open' ? 'Disponible' : 'Completo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
   Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailsScreen(match: match),
                ),
              );            },
          ),
        );
      },
    );
  },
),
                        
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

Widget _buildTorneoCard(BuildContext context, Torneo torneo) {
  return Card(
    margin: EdgeInsets.all(8),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TournamentDetails(
                    torneo: torneo,
                  )),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  torneo.imagenesTorneo!.isNotEmpty
                      ? torneo.imagenesTorneo![0]
                      : 'https://via.placeholder.com/150',
                  height: 100, // Altura más pequeña para la imagen
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Inscripciones Abiertas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12), // Padding más pequeño
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  torneo.nombre,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16, // Tamaño de fuente más pequeño
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people,
                        size: 12, color: Colors.grey), // Ícono más pequeño
                    SizedBox(width: 4),
                    Text(
                      '${torneo.minimoEquipos} equipos inscritos',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12, // Tamaño de fuente más pequeño
                      ),
                    ),
                    Spacer(),
                    Text(
                      '\$${torneo.cuotaInscripcion}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12, // Tamaño de fuente más pequeño
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
