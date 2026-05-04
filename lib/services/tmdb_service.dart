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

  // get trending movies this week
  Future<List<Movie>?> getTrendingMoviesWeek() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/trending/movie/week?api_key=${ApiConstants.apiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Movie> movies = [];
        for (var item in data['results']) {
          movies.add(Movie.fromJson(item));
        }
        return movies;
      } else {
        print('Failed to load trending: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // get popular movies
  Future<List<Movie>?> getPopularMovies() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/movie/popular?api_key=${ApiConstants.apiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Movie> movies = [];
        for (var item in data['results']) {
          movies.add(Movie.fromJson(item));
        }
        return movies;
      } else {
        print('Failed to load popular: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // discover movies by genres + sort
  Future<List<Movie>?> discoverMovies(List<int> genreIds, String sortBy) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/discover/movie?api_key=${ApiConstants.apiKey}&with_genres=${genreIds.join(',')}&sort_by=$sortBy',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Movie> movies = [];
        for (var item in data['results']) {
          movies.add(Movie.fromJson(item));
        }
        return movies;
      } else {
        print('Failed to discover movies: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
