import 'package:flutter/material.dart';
import 'package:hr_genie/Components/CustomAppBar.dart';
import 'package:hr_genie/Components/SubmitButton.dart';
import 'package:hr_genie/Constants/Color.dart';
import 'package:hr_genie/Controller/Services/checkLeaveType.dart';
import 'package:hr_genie/Model/LeaveModel.dart';
import 'package:intl/intl.dart';

class LeaveDetailPage extends StatelessWidget {
  final Leave leaveModel;
  const LeaveDetailPage({super.key, required this.leaveModel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(90),
            child: Column(
              children: [
                const CustomAppBar(title: "Leave Review"),
                Container(
                  height: 20,
                  color: primaryBlue,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Applied on ${DateFormat.yMMMMEEEEd('en-US').format(DateTime.parse(leaveModel.createdAt!))}",
                      style: const TextStyle(
                          color: primaryLightBlue, fontSize: 13),
                    ),
                  ),
                ),
              ],
            )),
        body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: LeaveDetailInfo(
                  label: 'Leave Type',
                  value: checkLeaveType(leaveModel.leaveTypeId!.toString()),
                ),
              ),
              Expanded(
                flex: 1,
                child: LeaveDetailInfo(
                  label: 'Date',
                  value:
                      "${DateFormat.yMMMd('en-US').format(DateTime.parse(leaveModel.startDate!))} to ${DateFormat.yMMMEd('en-US').format(DateTime.parse(leaveModel.endDate!))}",
                ),
              ),
              Expanded(
                flex: 1,
                child: LeaveDetailInfo(
                  label: 'Duration',
                  value: '${truncatNum(leaveModel.durationLength)} Days',
                ),
              ),
              Expanded(
                flex: 1,
                child: LeaveDetailInfo(
                  label: 'Reason',
                  value: leaveModel.reason,
                ),
              ),
              Expanded(
                child: LeaveDetailInfo(
                  label: 'Attachment',
                  value: leaveModel.attachment,
                ),
              ),
              Expanded(
                flex: 1,
                child: LeaveDetailInfo(
                  label: 'Status',
                  value: capitalize(leaveModel.applicationStatus),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "You can cancel your leave application during pending only. Otherwise you'll need to inform your manager",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: instructionTextColor, fontSize: 13),
                    ),
                    SubmitButton(
                      margin: const EdgeInsets.only(bottom: 25, top: 10),
                      label: "Cancel",
                      onPressed: leaveModel.applicationStatus == "pending"
                          ? () {}
                          : null,
                      buttonColor: Colors.red,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class LeaveDetailInfo extends StatelessWidget {
  final String label;
  final String? value;
  const LeaveDetailInfo({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Align(
            alignment: Alignment.topLeft,
            child: Container(
                margin: const EdgeInsets.only(top: 10), child: Text(label))),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.all(10),
          width: double.maxFinite,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: cardColor,
          ),
          child: Text(value ?? ""),
        ),
      ],
    );
  }
}
