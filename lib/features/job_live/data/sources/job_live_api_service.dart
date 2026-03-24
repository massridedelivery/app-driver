import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';

abstract class JobLiveApiService {
  Future<Response> cancelJob(String jobId, Map<String, dynamic> data);
  Future<Response> arriveAtStop(String jobId, String stopId);
  Future<Response> departFromStop(String jobId, String stopId);
  Future<Response> updateJobStatus(String jobId, Map<String, dynamic> data);
  Future<Response> getActiveJob();
  Future<Response> getActiveOffer();
  Future<Response> getActiveFoodOrder();
}

@LazySingleton(as: JobLiveApiService)
class JobLiveApiServiceImpl implements JobLiveApiService {
  final Dio _dio;

  JobLiveApiServiceImpl(this._dio);

  @override
  Future<Response> cancelJob(String jobId, Map<String, dynamic> data) async {
    final endpoint = Endpoints.driverJobsCancel.replaceAll(':id', jobId);
    return await _dio.post(endpoint, data: data);
  }

  @override
  Future<Response> arriveAtStop(String jobId, String stopId) async {
    final endpoint = Endpoints.driverJobsStopsArrive
        .replaceAll(':id', jobId)
        .replaceAll(':stop_id', stopId);
    return await _dio.post(endpoint);
  }

  @override
  Future<Response> departFromStop(String jobId, String stopId) async {
    final endpoint = Endpoints.driverJobsStopsDepart
        .replaceAll(':id', jobId)
        .replaceAll(':stop_id', stopId);
    return await _dio.post(endpoint);
  }

  @override
  Future<Response> updateJobStatus(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    final endpoint = Endpoints.driverJobsStatus.replaceAll(':id', jobId);
    return await _dio.patch(endpoint, data: data);
  }

  @override
  Future<Response> getActiveJob() async {
    return await _dio.get(Endpoints.driverJobsActive);
  }

  @override
  Future<Response> getActiveOffer() async {
    return await _dio.get(Endpoints.driverJobsActiveOffer);
  }

  @override
  Future<Response> getActiveFoodOrder() async {
    return await _dio.get(Endpoints.foodDriverOrdersActive);
  }
}
