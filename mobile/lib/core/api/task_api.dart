import 'package:dio/dio.dart';

import '../../models/task.dart';
import 'api_client.dart';

class TaskApi {
  TaskApi(this._dio);

  final Dio _dio;

  Future<List<Task>> list({TaskStatus? status, String? search}) async {
    try {
      final response = await _dio.get(
        '/api/tasks',
        queryParameters: {
          if (status != null) 'status': status.wire,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      final data = response.data as List;
      return data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Task> create({
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    try {
      final response = await _dio.post(
        '/api/tasks',
        data: {
          'title': title,
          'description': description,
          'status': status.wire,
        },
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<Task> update(
    int id, {
    required String title,
    required String description,
    required TaskStatus status,
  }) async {
    try {
      final response = await _dio.put(
        '/api/tasks/$id',
        data: {
          'title': title,
          'description': description,
          'status': status.wire,
        },
      );
      return Task.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } catch (e) {
      throw toApiException(e);
    }
  }
}
