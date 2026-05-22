import 'package:flutter/material.dart';
import 'dart:developer' as developer;
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
      final results = await _repository.getDisasters(category: category);
      
      // Fixed Order: Banjir first, then Kebakaran Hutan
      results.sort((a, b) {
        final nameA = a.name.toLowerCase();
        final nameB = b.name.toLowerCase();
        
        if (nameA.contains('banjir')) return -1;
        if (nameB.contains('banjir')) return 1;
        if (nameA.contains('kebakaran')) return -1;
        if (nameB.contains('kebakaran')) return 1;
        return 0;
      });

      _disasters = results;
      _listState = LoadingState.loaded;

      developer.log(
        '✅ Loaded ${results.length} disasters from API',
        name: 'DisasterProvider',
      );
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _listState = LoadingState.error;
      developer.log(
        '❌ loadDisasters FAILED: $e',
        name: 'DisasterProvider',
        error: e,
        stackTrace: stackTrace,
      );
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
      developer.log(
        '✅ Loaded detail for disaster: ${_selectedDisaster?.name}',
        name: 'DisasterProvider',
      );
    } catch (e, stackTrace) {
      _errorMessage = e.toString();
      _detailState = LoadingState.error;
      developer.log(
        '❌ loadDisasterDetail($id) FAILED: $e',
        name: 'DisasterProvider',
        error: e,
        stackTrace: stackTrace,
      );
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
      developer.log(
        '✅ Loaded ${_videos.length} videos',
        name: 'DisasterProvider',
      );
    } catch (e, stackTrace) {
      _videoState = LoadingState.error;
      developer.log(
        '❌ loadVideos FAILED: $e',
        name: 'DisasterProvider',
        error: e,
        stackTrace: stackTrace,
      );
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
