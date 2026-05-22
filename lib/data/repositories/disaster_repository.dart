import 'dart:developer' as developer;
import '../models/disaster_model.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';

class DisasterRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<DisasterModel>> getDisasters({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        AppConstants.disastersEndpoint,
        queryParameters: {
          if (category != null) 'category': category,
          'page': page,
          'limit': limit,
        },
      );

      developer.log(
        '✅ API /disasters responded: ${response.statusCode}',
        name: 'DisasterRepository',
      );

      final responseData = response.data;
      List<dynamic> data;

      if (responseData is Map<String, dynamic>) {
        data = responseData['data'] ?? [];
      } else if (responseData is List) {
        data = responseData;
      } else {
        developer.log(
          '⚠️ Unexpected response type: ${responseData.runtimeType}',
          name: 'DisasterRepository',
        );
        data = [];
      }

      developer.log(
        '📦 Parsed ${data.length} disasters from API',
        name: 'DisasterRepository',
      );

      return data.map((json) => DisasterModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      developer.log(
        '❌ getDisasters FAILED: $e',
        name: 'DisasterRepository',
        error: e,
        stackTrace: stackTrace,
      );
      // Re-throw so the provider can handle the error state properly
      rethrow;
    }
  }

  // Get single disaster detail with phases
  Future<DisasterModel> getDisasterDetail(String id) async {
    try {
      final response = await _client.get(
        '${AppConstants.disastersEndpoint}/$id',
      );

      developer.log(
        '✅ API /disasters/$id responded: ${response.statusCode}',
        name: 'DisasterRepository',
      );

      final responseData = response.data;
      Map<String, dynamic> json;

      if (responseData is Map<String, dynamic>) {
        // Backend wraps in {status, data: {...}}
        json = responseData['data'] ?? responseData;
      } else {
        throw FormatException(
          'Unexpected response format: ${responseData.runtimeType}',
        );
      }

      return DisasterModel.fromJson(json);
    } catch (e, stackTrace) {
      developer.log(
        '❌ getDisasterDetail($id) FAILED: $e',
        name: 'DisasterRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Get videos by disaster and phase
  Future<List<VideoModel>> getVideos({
    String? disasterId,
    String? phase,
  }) async {
    try {
      final response = await _client.get(
        AppConstants.videosEndpoint,
        queryParameters: {
          if (disasterId != null) 'disaster_id': disasterId,
          if (phase != null) 'phase': phase,
        },
      );

      developer.log(
        '✅ API /videos responded: ${response.statusCode}',
        name: 'DisasterRepository',
      );

      final responseData = response.data;
      List<dynamic> data;

      if (responseData is Map<String, dynamic>) {
        data = responseData['data'] ?? [];
      } else if (responseData is List) {
        data = responseData;
      } else {
        data = [];
      }

      return data.map((json) => VideoModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      developer.log(
        '❌ getVideos FAILED: $e',
        name: 'DisasterRepository',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
