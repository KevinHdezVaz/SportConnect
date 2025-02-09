import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_auth_crudd10/pages/screens/Equipos/detalle_equipo.screen.dart';
import 'package:user_auth_crudd10/services/equipo_service.dart';

class CrearEquipoScreen extends StatefulWidget {
  @override
  _CrearEquipoScreenState createState() => _CrearEquipoScreenState();
}

class _CrearEquipoScreenState extends State<CrearEquipoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _colorController = TextEditingController();
  File? _logoFile;
  bool _isLoading = false;
  final _equipoService = EquipoService();
  String? _selectedPredefinedLogo;
  bool _esAbierto = false; // Por defecto, equipo abierto

  final List<String> _predefinedLogos = [
    'assets/logos/logo1.png',
    'assets/logos/logo2.png',
    'assets/logos/logo3.png',
    'assets/logos/logo5.png',
    'assets/logos/logo6.png',
    'assets/logos/logo7.png',
    'assets/logos/logo8.png',
    'assets/logos/logo9.png',
    'assets/logos/logo10.png',
    'assets/logos/logo11.png',
    'assets/logos/logo12.png'
  ];
  Future<void> _crearEquipo() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final equipo = await _equipoService.crearEquipo(
          nombre: _nombreController.text,
          colorUniforme: _colorController.text,
          logo: _logoFile,
          logoPredefinido: _selectedPredefinedLogo,
          esAbierto: _esAbierto,
        );

        // Mostrar SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('¡Felicidades! Has creado tu equipo exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Esperar un momento para que se vea el SnackBar
        await Future.delayed(Duration(seconds: 1));

        // Navegar a la pantalla de detalles
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DetalleEquipoScreen(
              equipo: equipo,
              userId: equipo.miembros.first.id,
            ),
          ),
          (route) {
            // Mantener solo la ruta del ProfilePage
            return route.isFirst;
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crear Equipo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildLogoSelector(),
                  SizedBox(height: 30),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Información del Equipo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 24),
                    TextFormField(
                      controller: _nombreController,
                      style: TextStyle(
                          color: Colors
                              .black), // Cambia el color del texto ingresado a negro
                      decoration: InputDecoration(
                        labelText: 'Nombre del equipo',
                        labelStyle: TextStyle(
                            color: Colors
                                .blueGrey), // Cambia el color del label a negro
                        prefixIcon: Icon(Icons.sports_soccer,
                            color: Colors.black), // Cambia el color del ícono
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ingresa un nombre' : null,
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _colorController,
                      style: TextStyle(
                          color: Colors.black), // Color del texto ingresado
                      decoration: InputDecoration(
                        labelText: 'Color del uniforme',
                        labelStyle: TextStyle(
                            color: Colors.blueGrey), // Color del label
                        prefixIcon: Icon(Icons.palette,
                            color: Colors.black), // Color del icono
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color:
                                  Colors.black), // Borde negro cuando se enfoca
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Ingresa un color' : null,
                    ),
                    SizedBox(height: 32),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _crearEquipo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Crear Equipo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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

  void _showLogoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleccionar Logo',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.photo_library),
                  label: Text(
                    'Galería',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _selectImage();
                  },
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.sports_soccer),
                  label: Text('Logos predeterminados',
                      style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.pop(context);
                    _showPredefinedLogos();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPredefinedLogos() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Selecciona un logo: ', style: TextStyle(color: Colors.black)),
        content: Container(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _predefinedLogos.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPredefinedLogo = _predefinedLogos[index];
                    _logoFile = null;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    _predefinedLogos[index],
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSelector() {
    return Column(
      children: [
        GestureDetector(
          onTap: _showLogoOptions, // Nuevo método
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _logoFile != null
                  ? Image.file(_logoFile!, fit: BoxFit.cover)
                  : _selectedPredefinedLogo != null // Nueva variable
                      ? Image.asset(_selectedPredefinedLogo!, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40,
                                  color: Theme.of(context).primaryColor),
                              SizedBox(height: 8),
                              Text('Agregar logo',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ],
                          ),
                        ),
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          _logoFile != null || _selectedPredefinedLogo != null
              ? 'Toca para cambiar'
              : 'Logo del equipo',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _logoFile = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
