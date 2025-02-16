import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/types/types.dart';

typedef ResultType = Future<PinSubmitResult> Function(String numbers);

Future<void> showPinModalBottomSheet(
    {required BuildContext context,
    required ResultType handleSubmit,
    required String title}) async {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        String error = "";
        String newTitle = "";
        int numberOfNumbers = 0;
        List numbers = List.filled(6, 0);

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
          void reInit() {
            setModalState(() {
              numberOfNumbers = 0;
              numbers = List.filled(6, 0);
            });
          }

          void handleType(int index) async {
            if (error.isNotEmpty) {
              setModalState(() {
                error = "";
              });
            }
            if (index <= 8) {
              setModalState(() {
                numbers[numberOfNumbers] = index + 1;
                numberOfNumbers++;
                log(numbers.toString());
              });
            } else if (index == 9) {
              setModalState(() {
                numbers[numberOfNumbers] = 0;

                log(numbers.toString());
                numberOfNumbers++;
              });
            } else {
              if (numberOfNumbers <= 0) {
                return;
              }
              setModalState(() {
                numbers[numberOfNumbers] = 0;
                numberOfNumbers--;
                log(numbers.toString());
              });
            }

            if (numberOfNumbers == 6) {
              final PinSubmitResult result =
                  await handleSubmit(numbers.join().toString());
              log("result: $result");
              if (result.success && !result.repeat ||
                  !result.success && !result.repeat) {
                reInit();
                Navigator.pop(context);
                return;
              } else if (result.success && result.repeat) {
                setModalState(() {
                  numberOfNumbers = 0;
                  numbers = List.filled(6, 0);
                  String? title = result.newTitle;
                  if (title != null) {
                    newTitle = title;
                  }
                });
                return;
              }

              String? errorText = result.error;
              logError("Error Text $errorText");

              String? title = result.newTitle;

              setModalState(() {
                if (errorText != null) {
                  error = errorText;
                }
                if (title != null) {
                  newTitle = title;
                }
              });

              reInit();
            }
          }

          return Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              color: Color(0XFF212121),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    newTitle.isEmpty ? title : newTitle,
                    style: GoogleFonts.exo(color: Colors.white, fontSize: 20),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final isFull = numberOfNumbers > index;

                      return Container(
                        decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.white),
                            borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        width: width * 0.1,
                        height: height * 0.05,
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.all(5),
                        child: isFull
                            ? Align(
                                alignment: Alignment.center,
                                child: Container(
                                  alignment: Alignment.center,
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50)),
                                ),
                              )
                            : Container(),
                      );
                    }),
                  ),
                ),
                if (error.isNotEmpty)
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              FeatherIcons.alertCircle,
                              color: Colors.pinkAccent,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(error,
                                style: GoogleFonts.roboto(
                                    color: Colors.pinkAccent)),
                          ],
                        )
                      ],
                    ),
                  ),
                SizedBox(
                  height: 30,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: List.generate(11, (index) {
                      return Container(
                        width: width * 0.26,
                        height: height * 0.055,
                        decoration: BoxDecoration(
                            color: Color(0XFF454545),
                            borderRadius: BorderRadius.circular(5)),
                        margin: const EdgeInsets.all(5),
                        child: Material(
                          elevation: 5,
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(5),
                            onTap: () {
                              handleType(index);
                            },
                            child: Center(
                              child: index > 9
                                  ? Icon(
                                      Icons.backspace,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      "${getIndex(index)}",
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )
              ],
            ),
          );
        });
      });
}

int getIndex(int index) {
  if (index <= 8) {
    return index + 1;
  } else if (index == 9) {
    return 0;
  }

  return 1;
}
