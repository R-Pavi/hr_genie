import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_genie/Components/CustomTextField.dart';
import 'package:hr_genie/Components/SubmitButton.dart';
import 'package:hr_genie/Controller/Cubit/UpdatePassword/UpdatePasswordCubit.dart';
import 'package:hr_genie/Controller/Cubit/UpdatePassword/UpdatePasswordState.dart';
import 'package:hr_genie/Controller/Services/StatusMessage.dart';
import 'package:hr_genie/Controller/Services/TextStyle.dart';

class PasswordUpdateForm extends StatelessWidget {
  const PasswordUpdateForm({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController repeatController = TextEditingController();

    return BlocBuilder<UpdatePasswordCubit, UpdatePasswordState>(
      builder: (context, state) {
        return BlocBuilder<UpdatePasswordCubit, UpdatePasswordState>(
          builder: (context, state) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.white,
              body: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 400,
                  height: 650,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      //set border radius more than 50% of height and width to make circle
                    ),
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.key,
                          size: 170,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: const Text(
                            "Choose a strong password, avoid reusing passwords. Remember it or use a secure password manager.",
                            textAlign: TextAlign.left,
                            style:
                                TextStyle(color: Colors.black38, fontSize: 13),
                          ),
                        ),
                        CustomTextField(
                            obscureText: true,
                            hintText: "New Password",
                            onchanged: (value) {
                              if (value == "") {
                                repeatController.clear();
                              }
                              // _textFieldFocusNode.requestFocus();
                              context
                                  .read<UpdatePasswordCubit>()
                                  .newPasswordChanged(value);
                            },
                            errorStyle: state.newPassValid
                                ? TextStyleStore().success()
                                : TextStyleStore().failed(),
                            errorText: state.newPassValid
                                ? null
                                : MSG.newPassword.errorMsg),
                        CustomTextField(
                            controller: repeatController,
                            obscureText: true,
                            enabled: state.newPassword == "" ? false : true,
                            hintText: "Repeat Password",
                            onchanged: (value) {
                              context
                                  .read<UpdatePasswordCubit>()
                                  .repeatPasswordChanged(value);
                            },
                            errorStyle: null,
                            errorText: null),
                        SubmitButton(
                            label: "Update",
                            margin: const EdgeInsets.fromLTRB(0, 150, 0, 40),
                            onPressed: !state.isMatched ? null : () {})
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
