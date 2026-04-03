import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/sources/base_api_service.dart';

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
  Future<Response> getActiveJob() async {
    return await get(Endpoints.driverJobsActive);
  }

  @override
  Future<Response> getActiveOffer() async {
    return await get(Endpoints.driverJobsActiveOffer);
  }

  @override
  Future<Response> getActiveFoodOrder() async {
    return await get(Endpoints.foodDriverOrdersActive);
  }
}
