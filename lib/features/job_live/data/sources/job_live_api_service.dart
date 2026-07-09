import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/base_api_service.dart';

abstract class JobLiveApiService {
  Future<Response> cancelJob(String jobId, Map<String, dynamic> data);
  Future<Response> arriveAtStop(String jobId, String stopId);
  Future<Response> departFromStop(String jobId, String stopId);
  Future<Response> updateJobStatus(String jobId, Map<String, dynamic> data);
  Future<Response> getActiveSummary();
  Future<Response> getActiveJob({double? lat, double? lng});
  Future<Response> getActiveOffer({double? lat, double? lng});
  Future<Response> getActiveFoodOrder({double? lat, double? lng});
}

@LazySingleton(as: JobLiveApiService)
class JobLiveApiServiceImpl extends BaseApiService implements JobLiveApiService {
  JobLiveApiServiceImpl(super.dio);

  @override
  Future<Response> cancelJob(String jobId, Map<String, dynamic> data) async {
    final endpoint = Endpoints.driverJobsCancel.replaceAll(':id', jobId);
    return await post(endpoint, data: data);
  }

  @override
  Future<Response> arriveAtStop(String jobId, String stopId) async {
    final endpoint = Endpoints.driverJobsStopsArrive
        .replaceAll(':id', jobId)
        .replaceAll(':stop_id', stopId);
    return await post(endpoint);
  }

  @override
  Future<Response> departFromStop(String jobId, String stopId) async {
    final endpoint = Endpoints.driverJobsStopsDepart
        .replaceAll(':id', jobId)
        .replaceAll(':stop_id', stopId);
    return await post(endpoint);
  }

  @override
  Future<Response> updateJobStatus(
    String jobId,
    Map<String, dynamic> data,
  ) async {
    final endpoint = Endpoints.driverJobsStatus.replaceAll(':id', jobId);
    return await patch(endpoint, data: data);
  }

  @override
  Future<Response> getActiveSummary() async {
    return await get(Endpoints.driverActive);
  }

  @override
  Future<Response> getActiveJob({double? lat, double? lng}) async {
    final queryParameters = {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    return await get(Endpoints.driverJobsActive, queryParameters: queryParameters);
  }

  @override
  Future<Response> getActiveOffer({double? lat, double? lng}) async {
    final queryParameters = {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    return await get(Endpoints.driverJobsActiveOffer, queryParameters: queryParameters);
  }

  @override
  Future<Response> getActiveFoodOrder({double? lat, double? lng}) async {
    final queryParameters = {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
    return await get(Endpoints.foodDriverOrdersActive, queryParameters: queryParameters);
  }
}
