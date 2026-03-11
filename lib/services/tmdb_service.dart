import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/movie.dart';

class TMDBService {
  // get movie details by ID
  Future<Movie?> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return Movie.fromJson(json);
      } else {
        print('Failed to load movie: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching movie details: $e');
      return null;
    }
  }
}
