import 'package:flutter/material.dart';
import '../../data/models/disaster_model.dart';
import '../../data/repositories/disaster_repository.dart';

enum LoadingState { idle, loading, loaded, error }

class DisasterProvider extends ChangeNotifier {
  final DisasterRepository _repository = DisasterRepository();

  // State
  LoadingState _listState = LoadingState.idle;
  LoadingState _detailState = LoadingState.idle;
  LoadingState _videoState = LoadingState.idle;

  List<DisasterModel> _disasters = [];
  DisasterModel? _selectedDisaster;
  List<VideoModel> _videos = [];
  String? _errorMessage;

  // Getters
  LoadingState get listState => _listState;
  LoadingState get detailState => _detailState;
  LoadingState get videoState => _videoState;
  List<DisasterModel> get disasters => _disasters;
  DisasterModel? get selectedDisaster => _selectedDisaster;
  List<VideoModel> get videos => _videos;
  String? get errorMessage => _errorMessage;

  bool get isListLoading => _listState == LoadingState.loading;
  bool get isDetailLoading => _detailState == LoadingState.loading;
  bool get isVideoLoading => _videoState == LoadingState.loading;

  Future<void> loadDisasters({String? category}) async {
    _listState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _disasters = await _repository.getDisasters(category: category);
      _listState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _listState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<void> loadDisasterDetail(String id) async {
    _detailState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedDisaster = await _repository.getDisasterDetail(id);
      _detailState = LoadingState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _detailState = LoadingState.error;
    }
    notifyListeners();
  }

  Future<void> loadVideos({String? disasterId, String? phase}) async {
    _videoState = LoadingState.loading;
    notifyListeners();

    try {
      _videos = await _repository.getVideos(
        disasterId: disasterId,
        phase: phase,
      );
      _videoState = LoadingState.loaded;
    } catch (e) {
      _videoState = LoadingState.error;
    }
    notifyListeners();
  }

  PhaseContent? getPhase(String phase) {
    if (_selectedDisaster == null) return null;
    try {
      return _selectedDisaster!.phases.firstWhere((p) => p.phase == phase);
    } catch (_) {
      return null;
    }
  }

  void clearSelectedDisaster() {
    _selectedDisaster = null;
    notifyListeners();
  }
}
