import 'package:dio/dio.dart';
import 'package:user_auth_crudd10/model/Story.dart';

class StoriesService {
  final Dio dio = Dio();
  final String apiUrl = 'https://proyect.aftconta.mx/api';

  Future<List<Story>> getStories() async {
    try {
      print('Fetching stories from: $apiUrl/stories');
      final response = await dio.get('$apiUrl/stories');

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final stories = data.map((json) => Story.fromJson(json, '')).toList();

        // Debug las URLs de las imágenes
        for (var story in stories) {
          print('Story image URL: ${story.imageUrl}');
        }

        return stories;
      }
      throw Exception('Failed to load stories');
    } catch (e) {
      print('Error in getStories: $e');
      throw Exception('Error fetching stories: $e');
    }
  }
}
