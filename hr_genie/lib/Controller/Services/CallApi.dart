// ignore_for_file: file_names

import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hr_genie/Constants/PrintColor.dart';
import 'package:hr_genie/Controller/Services/CachedStation.dart';
import 'package:hr_genie/Model/EmployeeModel.dart';
import 'package:hr_genie/Model/ErrorModel.dart';
import 'package:hr_genie/Model/LeaveModel.dart';
import 'package:hr_genie/Model/LeaveQuotaModel.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallApi {
  String? baseUrl = dotenv.env['baseUrl'];

  Future<http.Response> postLogin({
    required email,
    required password,
  }) async {
    http.Response response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    return response;
  }

  Future<void> postLogout(String accessToken) async {
    http.Response response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accessToken,
      },
    );
  }

  Future<Employee> getUserData() async {
    final userDataRes = await CacheStore().getCache('user_data')!;

    final jsonData = json.decode(userDataRes!);
    final Map<String, dynamic> data = jsonData['data'];
    final employee = Employee.fromJson(data);
    String id = employee.employeeId!;
    print("User ID: $id");

    return employee;
  }

// TODO: Make this function dynamic instead of static
  Future<http.StreamedResponse?> refreshToken(
      {required http.Request originalRequest}) async {
    final refreshToken = await CacheStore().getCache('refresh_token');

    if (refreshToken != null) {
      Map<String, String> headers = {
        "Content-Type": "application/json",
        "Cookie": refreshToken,
      };

      http.Response response = await http.post(
        Uri.parse('$baseUrl/refresh_token'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        //SUCCESS
        final rawCookie = response.headers['set-cookie'];
        final jsonData = jsonDecode(response.body)['token'];
        final String newToken = jsonData;

        if (rawCookie != null) {
          await CacheStore().setCache('refresh_token', rawCookie);
        }
        await CacheStore().setCache('access_token', newToken);

        // TODO: Call the original request
        http.StreamedResponse newResponse =
            await http.Client().send(originalRequest);
        printGreen("Refreshed Token");
        return newResponse;
      } else {
        //UNAUTHORIZED
        // TODO: Clear all cache and redirect user to login page
        printRed("Unsuccessful: ${response.statusCode}");
        return null;
      }
    }
    printRed('refresh token is not found');
    return null;
  }

  void callLeaveQuota(http.Response response) {
    final jsonData = jsonDecode(response.body)['data'];
    List<LeaveQuota> quotaList = [];
    for (var item in jsonData) {
      LeaveQuota leaveQuota = LeaveQuota.fromJson(item);
      quotaList.add(leaveQuota);
    }
    printGreen(
        "Leave Quota successfully fetched: ${quotaList[0].leaveType} = ${quotaList[0].quota}");
  }

  Future<http.Response> fetchLeaveQuota(String accessToken) async {
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    };
    http.Response response = await http.get(
      Uri.parse('$baseUrl/leaves/quota'),
      headers: headers,
    );
    return response;
  }

  Future<http.StreamedResponse> httpRequest(
      {required String method,
      required String endpoint,
      String? accessToken,
      Map<String, dynamic>? requestBody}) async {
    // TODO: change this address to env
    String? baseUrl = dotenv.env['baseUrl'];

    Map<String, String> requestHeader = {
      "Content-Type": "application/json",
      "Authorization": accessToken ?? "",
    };

    http.Request request = http.Request(method, Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll(requestHeader);

    if (requestBody != null) {
      request.body = jsonEncode(requestBody);
    }

    http.StreamedResponse response = await http.Client().send(request);

    String jsonBody = await response.stream.bytesToString();
    Map<String, dynamic> responseBody = jsonDecode(jsonBody);
    if (response.statusCode == 400 &&
        responseBody['error'] ==
            'Access token expired. Please refresh your token.') {
      // TODO: call refresh_token endpoint
      http.StreamedResponse? refreshResponse =
          await refreshToken(originalRequest: request);
      if (refreshResponse != null) {}
    }
    return response;
  }

  Future<http.Response> postNewPassword({
    required newPassword,
  }) async {
    final accessToken = await CacheStore().getCache('access_token')!;
    print("accessToken:$accessToken");
    http.Response response = await http.post(
      Uri.parse('$baseUrl/first_login'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${accessToken ?? ""}",
      },
      body: jsonEncode({
        "password": newPassword,
      }),
    );
    print('returning respone from postNewPassword');
    return response;
  }

  Future<http.Response> fetchHistoryLeaves() async {
    final accessToken = await CacheStore().getCache('access_token')!;
    http.Response response = await http.get(
      Uri.parse('$baseUrl/leaves'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${accessToken ?? ""}",
      },
    );
    print("History Leaves: ${response.body}");
    return response;
  }

  Future<http.Response> fetchRequestLeaves(String? departmentId) async {
    final accessToken = await CacheStore().getCache('access_token')!;
    http.Response response = await http.get(
      Uri.parse('$baseUrl/leaves/$departmentId'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${accessToken ?? ""}",
      },
    );

    return response;
  }

  Future<http.Response> patchRequest(Leave leaveModel, String decision,
      String? rejectReason, bool isEmployee) async {
    final accessToken = await CacheStore().getCache('access_token')!;
    final String employeeEndpoint =
        '$baseUrl/leaves/cancel/${leaveModel.leaveId}';
    final String managerEndpoint = '$baseUrl/leaves/${leaveModel.leaveId}';

    http.Response response = await http.patch(
        Uri.parse(isEmployee ? employeeEndpoint : managerEndpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${accessToken ?? ""}",
        },
        body: jsonEncode(
            {"applicationStatus": decision, "rejectReason": rejectReason}));
    return response;
  }

  Future<http.Response> postLeavesApp(
      {required String leaveTypeId,
      required DateTime startDate,
      required DateTime endDate,
      required String durationType,
      required String reason,
      required String? attachment}) async {
    final accessToken = await CacheStore().getCache('access_token')!;
    http.Response response = await http.post(Uri.parse('$baseUrl/leaves'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${accessToken ?? ""}",
        },
        body: jsonEncode({
          "leave_type_id": checkTypeId(leaveTypeId),
          "start_date": DateFormat('yyyy-MM-dd').format(startDate),
          "end_date": DateFormat('yyyy-MM-dd').format(endDate),
          "duration": durationType,
          "reason": reason,
          "attachment": attachment
        }));
    printYellow("Done calling postLeaveApp");
    print(
        "leaveTypeId: $leaveTypeId\nstartDate: ${DateFormat('yyyy-MM-dd').format(startDate)}\nendDate: ${DateFormat('yyyy-MM-dd').format(endDate)}\nduration: $durationType\nreason: $reason\nattachment: $attachment");

    return response;
  }

  int? checkTypeId(String leaveTypeId) {
    switch (leaveTypeId) {
      case 'Annual':
        return 1;
      case 'Medical':
        return 2;
      case 'Parental':
        return 3;
      case 'Emergency':
        return 4;
      case 'Unpaid':
        return 5;
      default:
        return null;
    }
  }
}
