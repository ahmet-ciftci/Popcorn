import 'services/tmdb_service.dart';

void main() async {
  var tmdb = TMDBService();
  var movie = await tmdb.getMovieDetails(13363);

  if (movie != null) {
    print('Title: ${movie.title}');
    print('Rating: ${movie.voteAverage}');
    print('Released: ${movie.releaseDate}');
    print('Overview: ${movie.overview}');
    print('Poster: ${movie.getFullPosterUrl()}');
    print('Backdrop: ${movie.getFullBackdropUrl()}');
  } else {
    print('Failed to load movie. Check your API key.');
  }
}
