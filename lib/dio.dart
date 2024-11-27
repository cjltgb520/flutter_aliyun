import 'dart:convert';

import 'package:dio/dio.dart';

import 'client.dart';

extension DioExtension on RequestOptions {
  RequestOptions sign(AliYunClient client, {DateTime? dateTime}) {
    final signed = client.signedHeaders(
        uri.toString(),
        method: method,
        headers: headers,
        body: data != null ? jsonEncode(data) : null,
        dateTime: dateTime
    );

    headers.addAll(signed);
    return this;
  }
}