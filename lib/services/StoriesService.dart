import 'package:dio/dio.dart';
import 'package:user_auth_crudd10/model/Story.dart';
import 'package:user_auth_crudd10/utils/constantes.dart';

class StoriesService {
   final dio = Dio();

  Future<List<Story>> getStories() async {
    try {
      final response = await dio.get('$baseUrl/stories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Story.fromJson(json)).toList();
      }
      throw Exception('Failed to load stories');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}