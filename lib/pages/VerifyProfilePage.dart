import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:user_auth_crudd10/services/VerificationService.dart';

class VerifyProfilePage extends StatefulWidget {
  const VerifyProfilePage({Key? key}) : super(key: key);

  @override
  _VerifyProfilePageState createState() => _VerifyProfilePageState();
}

class _VerifyProfilePageState extends State<VerifyProfilePage> {
  File? _dniImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Método para seleccionar una imagen
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _dniImage = File(pickedFile.path);
      });
    }
  }

  // Método para eliminar la imagen seleccionada
  void _removeImage() {
    setState(() {
      _dniImage = null;
    });
  }

  // Método para enviar la imagen al servidor
  Future<void> _submitVerification() async {
    if (_dniImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona una imagen.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear una instancia de VerificationService
      final verificationService = VerificationService();
      final response = await verificationService.uploadDni(_dniImage!);

      if (response['success']) {
     ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text(
      'DNI subido correctamente.',
      style: TextStyle(color: Colors.white), // Cambia el color del texto
    ),
    backgroundColor: Colors.green, // Cambia el color de fondo del SnackBar
    behavior: SnackBarBehavior.floating, // Opcional: hace que el SnackBar flote
  ),
);

        Navigator.pop(context); // Regresar a la página anterior
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir el DNI.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verificar Perfil',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue,
        elevation: 0, // Eliminar sombra del AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Sube una imagen de tu DNI para verificar tu perfil.',
              style: GoogleFonts.inter(
                  fontSize: 16, color: Colors.blueGrey[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Mostrar la imagen seleccionada con un botón para eliminarla
            if (_dniImage != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: FileImage(_dniImage!),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _removeImage,
                  ),
                ],
              ),
            const SizedBox(height: 20),
            // Botón para seleccionar imagen
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                'Seleccionar Imagen',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
             _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _dniImage == null ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dniImage == null ? Colors.grey : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: Text(
                      'Enviar Verificación',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}