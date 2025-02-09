import 'package:flutter/material.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/model/Equipo.dart';
import 'package:user_auth_crudd10/model/Miembro.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class SeleccionarEquipoScreen extends StatefulWidget {
  final int torneoId;
  const SeleccionarEquipoScreen({
    Key? key,
    required this.torneoId,
  }) : super(key: key);

  @override
  _SeleccionarEquipoScreenState createState() =>
      _SeleccionarEquipoScreenState();
}

class _SeleccionarEquipoScreenState extends State<SeleccionarEquipoScreen> {
  final _equipoService = EquipoService();
  final _authService = AuthService();
  List<Equipo> equiposAbiertos = [];
  List<Equipo> equiposPrivados = [];
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
   _cargarUsuario().then((_) => _cargarEquipos());

  }
 
  Future<void> _cargarUsuario() async {
    try {
      final userData = await _authService.getProfile();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los datos del usuario: $e')),
        );
      }
    }
  }

Future<void> _cargarEquipos() async {
  try {
    final listaEquipos = await _equipoService.obtenerEquiposDisponibles(widget.torneoId);
    if (mounted) {
      setState(() {
        // Separar equipos abiertos (del torneo) y privados (del usuario)
        equiposAbiertos = listaEquipos
            .where((equipo) => equipo.esAbierto)
            .toList();
            
        // Obtener el equipo privado donde el usuario es capitán
        equiposPrivados = listaEquipos
            .where((equipo) => 
                !equipo.esAbierto && 
                equipo.miembros.any((m) => 
                    m.id.toString() == _userData?['id'].toString() &&
                    m.pivot.rol == 'capitan' &&
                    m.pivot.estado == 'activo'))
            .toList();
            
        _isLoading = false;
      });

      // Debug logs
      print('Equipos abiertos encontrados: ${equiposAbiertos.length}');
      print('Equipos privados encontrados: ${equiposPrivados.length}');
      if (equiposPrivados.isNotEmpty) {
        print('Equipo privado encontrado:');
        print('ID: ${equiposPrivados.first.id}');
        print('Nombre: ${equiposPrivados.first.nombre}');
        print('Miembros: ${equiposPrivados.first.miembros.map((m) => '${m.id}:${m.pivot.rol}').join(', ')}');
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los equipos: $e')),
      );
    }
  }
}

  Future<void> _handleUnirseEquipo(Equipo equipo) async {
    try {
      if (_userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Debes iniciar sesión para unirte a un equipo')),
        );
        return;
      }

      // Verificar si el usuario ya está en cualquier equipo
      bool yaEstaEnAlgunEquipo = false;
      for (var otroEquipo in [...equiposAbiertos, ...equiposPrivados]) {
        if (otroEquipo.miembros.any((m) =>
            m.id.toString() == _userData!['id'].toString() &&
            m.pivot.estado == 'activo')) {
          yaEstaEnAlgunEquipo = true;
          break;
        }
      }

      if (yaEstaEnAlgunEquipo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ya perteneces a un equipo. Solo puedes estar en un equipo a la vez.')),
        );
        return;
      }

      // Mostrar diálogo de selección de posición
      final posicion = await _mostrarDialogoPosicion(equipo);
      if (posicion == null) return;

      setState(() => _isLoading = true);

      if (equipo.esAbierto) {
        if (equipo.plazasDisponibles <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay plazas disponibles en este equipo')),
          );
          return;
        }

        await _equipoService.unirseAEquipoAbierto(
          equipoId: equipo.id,
          userId: _userData!['id'],
          posicion: posicion,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Te has unido al equipo exitosamente')),
        );
      } else {
        await _equipoService.solicitarUnirseAEquipoPrivado(
            equipo.id, _userData!['id']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud enviada al capitán del equipo')),
        );
      }

      await _cargarEquipos();
    } catch (e) {
      print("Error al unirse al equipo: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            'La Liguillatir',
            style: TextStyle(color: Colors.white),
          ),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: const Color.fromARGB(255, 225, 217, 217),
            tabs: [
              Tab(
                text: 'PARTICIPANTES',
              ),
              Tab(text: 'COMENTARIOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                try {
                  await _cargarEquipos();
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: _buildParticipantesTab(),
            ),
            _buildComentariosTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantesTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Mapeo de colores a emojis
    final coloresEquipos = [
      {'nombre': 'Verde', 'emoji': '🟢'},
      {'nombre': 'Rojo', 'emoji': '🔴'},
      {'nombre': 'Azul', 'emoji': '🔵'},
      {'nombre': 'Amarillo', 'emoji': '💛'},
      {'nombre': 'Naranja', 'emoji': '🟠'},
      {'nombre': 'Morado', 'emoji': '💜'},
      {'nombre': 'Negro', 'emoji': '⚫'},
      {'nombre': 'Blanco', 'emoji': '⚪'},
      {'nombre': 'Gris', 'emoji': '⚪'},
      {'nombre': 'Dorado', 'emoji': '🟡'},
      {'nombre': 'Plateado', 'emoji': '⚪'},
      {'nombre': 'Rosa', 'emoji': '💗'},
    ];

    return ListView(
      children: [
        // Equipos Abiertos
        ...equiposAbiertos.asMap().entries.map((entry) {
          int index = entry.key;
          Equipo equipo = entry.value;
          var colorInfo = coloresEquipos[index % coloresEquipos.length];

          return _buildEquipoSection(
            color: colorInfo['nombre']!,
            emoji: colorInfo['emoji']!,
            equipo: equipo,
            plazasDisponibles: equipo.plazasDisponibles,
          );
        }).toList(),

        // Equipos Privados
        ...equiposPrivados.map((equipo) {
          // Encontrar el color correspondiente basado en el nombre del equipo
          var colorInfo = coloresEquipos.firstWhere(
            (color) => color['nombre'] == equipo.colorUniforme,
            orElse: () => {'nombre': 'Equipo', 'emoji': '⚽'},
          );

          return _buildEquipoSection(
            color: equipo.nombre,
            emoji: colorInfo['emoji']!,
            equipo: equipo,
            plazasDisponibles: equipo.plazasDisponibles,
            isPrivate: true,
          );
        }).toList(),

        // Si no hay equipos, mostrar mensaje
        if (equiposAbiertos.isEmpty && equiposPrivados.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No hay equipos disponibles en este momento',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEquipoSection({
    required String color,
    required String emoji,
    required int plazasDisponibles,
    Equipo? equipo,
    bool isPrivate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Agregar este Padding para mostrar el encabezado del equipo
        Padding(
          padding: EdgeInsets.all(5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    color,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Text(
                    emoji,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(right: 20),
                child: Text(
                  '$plazasDisponibles Plazas',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildUnirmeButton(equipo, isPrivate),
              ...['Portero', 'L.Derecho', 'L.Izquierdo', 'Central', 'Delantero']
                  .map((posicion) {
                    
                Miembro? jugador;
                if (equipo != null) {
                  try {
                    jugador = equipo.miembros.firstWhere(
                      (m) =>
                          m.pivot.estado == 'activo' && m.posicion == posicion,
                    );
                  } catch (_) {
                    jugador = null;
                  }
                }
                return _buildJugadorSlot(posicion, jugador);
              }).toList(),
            ],
          ),
        ),
        Divider(height: 32),
      ],
    );
  }

 
 
 Widget _buildJugadorSlot(String posicion, Miembro? jugador) {
  print('Construyendo slot para posición: $posicion');
  if (jugador != null) {
    print('Jugador encontrado: ${jugador.name} con posición: ${jugador.posicion}');
  }

  String? imageUrl;
  if (jugador?.profileImage != null) {
    imageUrl = 'https://proyect.aftconta.mx/storage/${jugador!.profileImage}';
  }

  return Container(
    width: 85,
    margin: EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[200],
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: jugador == null
              ? Icon(Icons.person_outline, color: Colors.grey)
              : null,
        ),
        SizedBox(height: 8),
        Text(
          jugador?.name ?? 'Disponible',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: jugador != null ? Colors.blue : Colors.green,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          posicion,
          style: TextStyle(fontSize: 11, color: Colors.black),
        ),
      ],
    ),
  );
}


  bool yaEstaEnEquipo(Equipo equipo) {
    return equipo.miembros.any((m) =>
        m.id.toString() == _userData?['id'].toString() &&
        m.pivot.estado == 'activo');
  }

  Equipo? _obtenerEquipoCapitan() {
    if (_userData == null) return null;

    // Buscar en todos los equipos privados no inscritos al torneo
    var equipoCapitan = equiposPrivados.firstWhere(
      (equipo) => equipo.miembros.any((m) =>
          m.id.toString() == _userData!['id'].toString() &&
          m.pivot.rol == 'capitan' &&
          m.pivot.estado == 'activo'),
    );

    // Si no se encontró en los equipos privados, buscar en el servicio
    if (equipoCapitan == null) {
      // Aquí podrías hacer una llamada al servicio para obtener el equipo del capitán
      // Por ahora, solo retornamos null
    }

    return equipoCapitan;
  }

  bool esCapitanConEquipoNoInscrito() {
    if (_userData == null) return false;
    return _obtenerEquipoCapitan() != null;
  }
Widget _buildUnirmeButton(Equipo? equipo, bool isPrivate) {
  if (_userData == null || equipo == null) return Container();

  // Verificar si el usuario es capitán
  bool esCaptain = equipo.miembros.any((m) {
    print('Verificando miembro: ${m.id} - rol: ${m.pivot.rol}');
    return m.id.toString() == _userData!['id'].toString() && 
           m.pivot.rol == 'capitan' && 
           m.pivot.estado == 'activo';
  });

  print('Usuario ID: ${_userData!['id']}');
  print('Es capitán: $esCaptain');
  print('Es equipo privado: ${!equipo.esAbierto}');
  print('Miembros del equipo: ${equipo.miembros.map((m) => '${m.id}:${m.pivot.rol}').join(', ')}');

  // Si es un equipo privado y el usuario es capitán, mostrar botón de inscripción
  if (!equipo.esAbierto && esCaptain) {
    return Container(
      width: 85,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _mostrarDialogoInscripcionEquipo(equipo),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add, color: Colors.orange, size: 24),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Inscribir Equipo',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  // Si el equipo es abierto, mostrar botón de unirse
  if (equipo.esAbierto) {
    // Verificar si el usuario ya está en algún equipo
    bool yaEstaEnAlgunEquipo = false;
    for (var otroEquipo in [...equiposAbiertos, ...equiposPrivados]) {
      if (otroEquipo.miembros.any((m) =>
          m.id.toString() == _userData!['id'].toString() &&
          m.pivot.estado == 'activo' &&
          !m.pivot.rol.contains('capitan'))) {
        yaEstaEnAlgunEquipo = true;
        break;
      }
    }

    // Si no está en ningún equipo o es capitán, mostrar botón
    if (!yaEstaEnAlgunEquipo || esCaptain) {
      return Container(
        width: 85,
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () => _handleUnirseEquipo(equipo),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.green, size: 24),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unirme',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
      );
    }
  }

  // Si no cumple ninguna condición, retornar contenedor vacío
  return Container();
}
 Future<void> _mostrarDialogoInscripcionEquipo(Equipo equipo) async {
  // Mapa para almacenar las posiciones seleccionadas
  Map<int, Map<String, dynamic>> miembrosSeleccionados = {};

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Inscribir ${equipo.nombre}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Selecciona los jugadores y sus posiciones:'),
                  SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: equipo.miembros
                          .where((m) => m.pivot.estado == 'activo')
                          .length,
                      itemBuilder: (context, index) {
                        final miembro = equipo.miembros
                            .where((m) => m.pivot.estado == 'activo')
                            .toList()[index];
                            
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: miembro.profileImage != null
                                  ? NetworkImage(
                                      'https://proyect.aftconta.mx/storage/${miembro.profileImage}')
                                  : null,
                              child: miembro.profileImage == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(miembro.name),
                            subtitle: Row(
                              children: [
                                Checkbox(
                                  value: miembrosSeleccionados
                                      .containsKey(miembro.id),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        miembrosSeleccionados[miembro.id] = {
                                          'user_id': miembro.id,
                                          'posicion': null
                                        };
                                      } else {
                                        miembrosSeleccionados
                                            .remove(miembro.id);
                                      }
                                    });
                                  },
                                ),
                                if (miembrosSeleccionados
                                    .containsKey(miembro.id))
                                  Expanded(
                                    child: DropdownButton<String>(
                                      value: miembrosSeleccionados[miembro.id]
                                          ?['posicion'],
                                      hint: Text('Seleccionar posición'),
                                      items: [
                                        'Portero',
                                        'L.Derecho',
                                        'L.Izquierdo',
                                        'Central',
                                        'Delantero'
                                      ].map((String posicion) {
                                        return DropdownMenuItem<String>(
                                          value: posicion,
                                          child: Text(posicion),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          miembrosSeleccionados[miembro.id]
                                              ?['posicion'] = newValue;
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final miembrosValidos = miembrosSeleccionados.values
                              .where((m) => m['posicion'] != null)
                              .length;

                          if (miembrosValidos < 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Selecciona al menos 5 jugadores y asígnales una posición'),
                              ),
                            );
                            return;
                          }

                          try {
                            await _equipoService.inscribirEquipoEnTorneo(
                              equipoId: equipo.id,
                              torneoId: widget.torneoId,
                              miembros: miembrosSeleccionados.values.toList(),
                            );

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Equipo inscrito exitosamente')
                              ),
                            );
                            _cargarEquipos();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al inscribir el equipo: $e')
                              ),
                            );
                          }
                        },
                        child: Text('Inscribir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildEmptyTeamSlot() {
    return Container(
      width: 280,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('No hay equipos disponibles'),
      ),
    );
  }

  Future<String?> _mostrarDialogoPosicion(Equipo equipo) async {
    final posiciones = [
      {
        'nombre': 'Portero',
        'icono': 'assets/logos/portero.png',
        'color': Colors.yellow
      },
      {
        'nombre': 'Defensa Central',
        'icono': 'assets/logos/patada.png',
        'color': Colors.blue
      },
      {
        'nombre': 'Lateral Derecho',
        'icono': 'assets/logos/voleo.png',
        'color': Colors.blue
      },
      {
        'nombre': 'Lateral Izquierdo',
        'icono': 'assets/logos/voleo.png',
        'color': Colors.blue
      },
      {
        'nombre': 'Mediocampista',
        'icono': 'assets/logos/disparar.png',
        'color': Colors.yellow
      },
      {
        'nombre': 'Delantero',
        'icono': 'assets/logos/patear.png',
        'color': Colors.red
      },
    ];

    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecciona tu posición',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // Mostrar las posiciones como botones
                ...posiciones.map((posicion) {
                  return ListTile(
                    leading: Image.asset(
                      posicion['icono']
                          as String, // Carga la imagen desde assets
                      width: 40, // Ajusta el tamaño según sea necesario
                      height: 40,
                    ),
                    title: Text(
                      posicion['nombre'] as String,
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        posicion['nombre'], // Devuelve la posición seleccionada
                      );
                    },
                  );
                }).toList(),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(
                      context), // Cierra el diálogo sin seleccionar
                  child: Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPosicionButton(
      String nombrePosicion, Map<String, dynamic> posicion) {
    return InkWell(
      onTap: () {
        Navigator.pop(
            context, nombrePosicion); // Devuelve la posición seleccionada
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: posicion['color'] as Color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          posicion['icono'] as IconData,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildComentariosTab() {
    return Center(child: Text('Comentarios del torneo'));
  }
}
