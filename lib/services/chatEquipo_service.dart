import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:user_auth_crudd10/model/ChatMessage.dart';
import 'package:user_auth_crudd10/services/storage_service.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';
import 'package:path/path.dart' as path;  // Agregar esta importación
import 'package:http_parser/http_parser.dart';  // Agregar esta importación

class ChatService {
  final storage = StorageService();

  Future<List<ChatMessage>> getMessages(int equipoId) async {
    final url = '$baseUrl/chat/equipos/$equipoId/mensajes';
    print('➡️ Enviando GET a: $url');
    
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      
      print('⬅️ Respuesta código: ${response.statusCode}');
      print('📜 Respuesta body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar los mensajes. Código: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getMessages: $e');
      rethrow;
    }
  }

Future<ChatMessage> sendFile(int equipoId, int userId, File file, String fileType) async {
  try {
    String url = '$baseUrl/chat/mensaje';
    
    var request = http.MultipartRequest('POST', Uri.parse(url));
    
    final headers = await getHeaders();
    request.headers.addAll(headers);
    
    // Agregar los campos
    request.fields['equipo_id'] = equipoId.toString();
    request.fields['tipo'] = fileType;
    request.fields['mensaje'] = ''; // Agregar mensaje vacío
    
    // Agregar el archivo
    var stream = http.ByteStream(file.openRead());
    var length = await file.length();
    String fileName = file.path.split('/').last;
    
    print('Enviando archivo: $fileName');
    print('Tipo: $fileType');
    print('Tamaño: $length bytes');
    
    var multipartFile = http.MultipartFile(
      'archivo',
      stream,
      length,
      filename: fileName,
      contentType: fileType == 'imagen' 
          ? MediaType('image', 'jpeg')
          : MediaType('application', 'octet-stream'),
    );
    
    request.files.add(multipartFile);
    
    print('Enviando petición...');
    var response = await request.send();
    print('Código de respuesta: ${response.statusCode}');
    
    var responseData = await response.stream.bytesToString();
    print('Respuesta: $responseData');
    
    if (response.statusCode == 201) {
      return ChatMessage.fromJson(json.decode(responseData));
    } else {
      throw Exception('Error al enviar el archivo. Código: ${response.statusCode}\nRespuesta: $responseData');
    }
  } catch (e) {
    print('❌ Error en sendFile: $e');
    rethrow;
  }
}

  
   Future<ChatMessage> sendMessage(
    int equipoId, 
    int userId, 
    String message, 
    {int? replyToId}
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/mensaje'),
        headers: await getHeaders(),
        body: json.encode({
          'equipo_id': equipoId,
          'mensaje': message,
          'reply_to_id': replyToId,
        }),
      );

      if (response.statusCode == 201) {
        return ChatMessage.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al enviar el mensaje');
      }
    } catch (e) {
      print('❌ Error en sendMessage: $e');
      rethrow;
    }
  }
  

  Future<Map<String, String>> getHeaders() async {
    final token = await storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }
}