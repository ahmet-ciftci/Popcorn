import '../constants/api_constants.dart';

class Movie {
  int id = 0;
  String title = '';
  String overview = '';
  String posterPath = '';
  String backdropPath = '';
  String releaseDate = '';
  double voteAverage = 0.0;
  List<int> genreIds = [];

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
  });

  Movie.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    overview = json['overview'];
    posterPath = json['poster_path'] ?? '';
    backdropPath = json['backdrop_path'] ?? '';
    releaseDate = json['release_date'] ?? '';
    voteAverage = json['vote_average'].toDouble();
    genreIds = List<int>.from(json['genre_ids'] ?? []);
  }

  String getFullPosterUrl() {
    return ApiConstants.imageBaseUrl + posterPath;
  }

  String getFullBackdropUrl() {
    return ApiConstants.imageBaseUrl + backdropPath;
  }
}
