import 'curriculum_slides_remote_data_source.dart';

class CurriculumSlidesRepository {
  CurriculumSlidesRepository({CurriculumSlidesRemoteDataSource? remote})
      : _remote = remote ?? const CurriculumSlidesRemoteDataSource();

  final CurriculumSlidesRemoteDataSource _remote;

  final _cache = <String, Map<int, CloudCurriculumSlide>>{};

  Future<Map<int, CloudCurriculumSlide>> slidesForTrack(String trackId) async {
    if (_cache.containsKey(trackId)) return _cache[trackId]!;

    final map = await _remote.fetchPublishedByGlobalIndex(trackId);
    _cache[trackId] = map;
    return map;
  }

  void clearCache() => _cache.clear();
}
