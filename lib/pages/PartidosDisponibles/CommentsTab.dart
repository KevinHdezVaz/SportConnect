import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_auth_crudd10/auth/auth_service.dart';
import 'package:user_auth_crudd10/services/MatchService.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Importar para imágenes en caché
import 'package:shimmer/shimmer.dart'; // Opcional, para efecto de carga

class CommentsTab extends StatefulWidget {
  final int matchId;

  const CommentsTab({Key? key, required this.matchId}) : super(key: key);

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final TextEditingController _commentController = TextEditingController();
  final MatchService _matchService = MatchService();
  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  // Mensaje predeterminado mejorado del administrador en una sola tarjeta
  final Map<String, dynamic> _defaultComment = {
    "user": {"name": "FutPlay", "profileImage": "assets/icons/logoapp.png"},
    "text": "👋 ¡Hola! Te esperamos con camiseta roja 🔴 y azul 🔵.\n"
        "⏰ Llega 10 min antes para ganar 1 punto escaneando el QR con el organizador.\n"
        "🔄 Cada jugador recibirá un número para rotar al portero cada 7-8 min.\n"
        "🏆 Vota al MVP al final y gánate 1 punto automático.\n"
        "😄 Con 20 puntos, obtén 5€ en tu monedero.\n"
        "🌟 Valora a tu organizador.\n"
        "👥 Pregunta por agregar amigos.\n"
        "🔔 Si faltan 12 jugadores confirmados 1 hora antes, el evento se cancelará.",
    "timestamp": "27/02/25, 10:02 HH",
  };

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _matchService.getComments(widget.matchId);
      // Ordenar comentarios dinámicos del más nuevo al más antiguo (por timestamp, descendente)
      comments.sort((b, a) {
        final timestampA =
            DateTime.parse(a['created_at'] ?? a['timestamp'] ?? '1970-01-01');
        final timestampB =
            DateTime.parse(b['created_at'] ?? b['timestamp'] ?? '1970-01-01');
        return timestampA
            .compareTo(timestampB); // Orden descendente (nuevo -> antiguo)
      });

      if (mounted) {
        setState(() {
          _comments = comments; // Solo cargar los comentarios dinámicos
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments: $e');
      if (mounted) {
        setState(() {
          _comments = []; // Limpiar la lista en caso de error
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al cargar comentarios: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty ||
        _commentController.text.trim().length > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('El comentario debe tener entre 1 y 60 caracteres'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      final userId = await AuthService().getCurrentUserId();
      final userName = 'Usuario$userId';
      final newComment = await _matchService.addComment(
          widget.matchId, _commentController.text.trim());
      await _loadComments();
      if (mounted) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Comentario agregado'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al agregar comentario: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

 @override
Widget build(BuildContext context) {
  return _isLoading
      ? Center(child: CircularProgressIndicator())
      : Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Mostrar el mensaje predeterminado del admin fijo al inicio (arriba)
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Bordes redondeados
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green,
                                backgroundImage: _defaultComment['user']['profileImage'] != null
                                    ? AssetImage(_defaultComment['user']['profileImage'] as String) as ImageProvider
                                    : null,
                                child: _defaultComment['user']['profileImage'] == null
                                    ? Icon(Icons.person, color: Colors.white)
                                    : null,
                                radius: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _defaultComment['user']['name'],
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14),
                                        ),
                                        Text(
                                          _defaultComment['timestamp'],
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _defaultComment['text'],
                                      style: TextStyle(color: Colors.black, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Mostrar comentarios dinámicos de los usuarios en orden nuevo -> antiguo (arriba: recientes, abajo: antiguos)
                  ..._comments.map((comment) {
                    final String? profileImage = comment['user']['profile_image'] as String?; // Obtener profile_image del usuario
                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Bordes redondeados
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          backgroundImage: profileImage != null
                              ? CachedNetworkImageProvider('https://proyect.aftconta.mx/storage/$profileImage')
                              : null,
                          child: profileImage == null
                              ? Text(
                                  comment['user']['name'][0],
                                  style: TextStyle(color: Colors.white),
                                )
                              : null,
                          onBackgroundImageError: profileImage != null
                              ? (exception, stackTrace) => debugPrint('Error loading profile image: $exception')
                              : null, // Solo establecer onBackgroundImageError si profileImage no es null
                          radius: 16,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              comment['user']['name'],
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            Text(
                              comment['timestamp'] ?? DateFormat('dd/MM/yy, HH:mm').format(DateTime.now()),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          comment['text'],
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLength: 60, // Límite de caracteres
                      maxLines: null, // Permite múltiples líneas
                      style: TextStyle(color: Colors.black), // Texto en color negro
                      decoration: InputDecoration(
                        hintText: 'Escribe tu comentario o pregunta...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                        counterText: '${60 - _commentController.text.length} caracteres restantes',
                        counterStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[600]),
                          onPressed: () => _commentController.clear(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.green, size: 35),
                        onPressed: _addComment,
                        tooltip: 'Enviar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
}
}
