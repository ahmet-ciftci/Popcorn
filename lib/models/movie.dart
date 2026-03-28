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
  String tagline = '';
  int runtime = 0;
  List<String> genres = [];
  String director = '';

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.genreIds,
    this.tagline = '',
    this.runtime = 0,
    this.genres = const [],
    this.director = '',
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
    tagline = json['tagline'] ?? '';
    runtime = json['runtime'] ?? 0;

    // get genre names from the detail response
    List<String> genreNames = [];
    if (json['genres'] != null) {
      for (var g in json['genres']) {
        genreNames.add(g['name']);
      }
    }
    genres = genreNames;

    // find director from credits
    if (json['credits'] != null && json['credits']['crew'] != null) {
      for (var person in json['credits']['crew']) {
        if (person['job'] == 'Director') {
          director = person['name'];
          break;
        }
      }
    }
  }

  String getFullPosterUrl() {
    return ApiConstants.imageBaseUrl + posterPath;
  }

  String getFullBackdropUrl() {
    return ApiConstants.imageBaseUrl + backdropPath;
  }
}
