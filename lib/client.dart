import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _defaultContentType = 'application/json; charset=utf-8';
const _defaultAcceptType = 'application/json; charset=utf-8';
const _xContentMd5 = 'content-md5';
const _host = 'host';
const _date = 'date';

class AliYunClient {
  /// Your access key ID
  String keyId;

  /// Your secret access key
  String accessKey;

  /// The default `Content-Type` header value.
  /// Defaults to `application/json`
  String defaultContentType;

  /// The deafult `Accept` header value.
  /// Defaults to `application/json`
  String defaultAcceptType;

  List<String> whiteListHeaders;

  AliYunClient({
    required this.keyId,
    required this.accessKey,
    this.defaultContentType = _defaultContentType,
    this.defaultAcceptType = _defaultAcceptType,
    this.whiteListHeaders = const [''],
  });

  Map<String, String> signedHeaders(String path, {
    String? method = 'POST',
    Map<String, dynamic>? headers,
    String? body,
    DateTime? dateTime,
  }) {
    if (path.isEmpty) {
      throw AssertionError('path is empty');
    }

    /// Split the URI into segments
    final parsedUri = Uri.parse(path);

    /// The endpoint used
    final baseUrl = '${parsedUri.scheme}://${parsedUri.host}';

    path = parsedUri.path;

    /// Format the `method` correctly
    method = method!.toUpperCase();
    headers ??= {};

    /// Set the `content-type`
    if (headers['content-type'] == null) {
      headers['content-type'] = defaultContentType;
    }

    /// Set the `accept` header
    if (headers['accept'] == null) {
      headers['accept'] = defaultAcceptType;
    }

    /// Set the `body`, if any
    if (body == null || method == 'GET') {
      body = '';
    }

    /// Sets or generate the `dateTime` parameter needed for the signature
    dateTime ??= DateTime.now();
    var formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss z', 'en_US');
    headers[_date] = '${formatter.format(dateTime)}GMT';

    headers['x-ca-timestamp'] = dateTime.millisecondsSinceEpoch.toString();

    headers['x-ca-nonce'] = const Uuid().v4();

    /// Sets the `host` header
    final baseUri = Uri.parse(baseUrl);
    headers[_host] = baseUri.host;

    headers['user-agent'] = 'ALIYUN-ANDROID-DEMO';

    headers['x-ca-key'] = keyId;

    headers['CA_VERSION'] = '1';

    var bytes = utf8.encode(body);
    headers[_xContentMd5] = base64.encode(md5.convert(bytes).bytes);


    var headersToSign = SplayTreeMap<String, String>();
    var signHeadersStringBuilder = StringBuffer();
    var flag = 0;
    for (var header in headers.entries) {
      if (header.key.startsWith('x-ca-') || whiteListHeaders.contains(header.key)) {
        if (flag != 0) {
          signHeadersStringBuilder.write(',');
        }
        flag++;
        signHeadersStringBuilder.write(header.key);
        headersToSign[header.key] = headers[header.key];
      }
    }
    headers.addAll({
      'x-ca-signature-headers': signHeadersStringBuilder.toString()
    });

    String signString = '$method\n$defaultAcceptType\n${headers[_xContentMd5]}\n$defaultContentType\n${headers[_date]}\n';
    var sb = StringBuffer();
    for (var e in headersToSign.entries) {
      sb.write("${e.key}:${e.value}\n");
    }
    signString = signString + sb.toString() + path;

    var signBytes = utf8.encode(signString);
    var secretKey = utf8.encode(accessKey);
    var hmacSha256 = Hmac(sha256, secretKey);
    var digest = hmacSha256.convert(signBytes);
    headers['x-ca-signature'] = base64.encode(digest.bytes);

    Map<String, dynamic> newHeaders = {};
    headers.forEach((key, values) {
      var temp = utf8.encode(values);
      values = latin1.decode(temp);
      newHeaders.addAll({key: values});
    });

    return newHeaders.cast<String, String>();
  }

  String generateDatetime() {
    DateTime dateTime = DateTime.now();
    var formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss z', 'en_US');
    return '${formatter.format(dateTime)}GMT';
  }
}