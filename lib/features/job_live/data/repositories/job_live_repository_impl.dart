import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../data/sources/job_live_api_service.dart';
import '../../domain/repositories/job_live_repository.dart';

@LazySingleton(as: JobLiveRepository)
class JobLiveRepositoryImpl implements JobLiveRepository {
  final JobLiveApiService _apiService;

  JobLiveRepositoryImpl(this._apiService);

  @override
  Future<void> cancelJob(String jobId, Map<String, dynamic> data) async {
    await _apiService.cancelJob(jobId, data);
  }

  @override
  Future<void> arriveAtStop(String jobId, String stopId) async {
    await _apiService.arriveAtStop(jobId, stopId);
  }

  @override
  Future<void> departFromStop(String jobId, String stopId) async {
    await _apiService.departFromStop(jobId, stopId);
  }

  @override
  Future<void> updateJobStatus(String jobId, Map<String, dynamic> data) async {
    await _apiService.updateJobStatus(jobId, data);
  }

  @override
  Future<dynamic> getActiveJob({double? lat, double? lng}) async {
    try {
      final response = await _apiService.getActiveJob(lat: lat, lng: lng);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Gracefully handle "no active job"
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<dynamic> getActiveOffer({double? lat, double? lng}) async {
    try {
      final response = await _apiService.getActiveOffer(lat: lat, lng: lng);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<dynamic> getActiveFoodOrder({double? lat, double? lng}) async {
    try {
      final response = await _apiService.getActiveFoodOrder(lat: lat, lng: lng);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Gracefully handle "no active food order"
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
    return null;
  }
}
