import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/movie.dart';

class TMDBService {
  // search movies
  Future<List<Movie>> searchMovies(String query, int page) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/search/movie?api_key=${ApiConstants.apiKey}&query=$query&page=$page',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<Movie> movies = [];
      for (var item in data['results']) {
        movies.add(Movie.fromJson(item));
      }
      return movies;
    } else {
      print('search failed: ${response.statusCode}');
      return [];
    }
  }

  // get movie details
  Future<Movie?> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/movie/$movieId?api_key=${ApiConstants.apiKey}&append_to_response=credits',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Movie.fromJson(data);
      } else {
        print('Failed to load movie: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
