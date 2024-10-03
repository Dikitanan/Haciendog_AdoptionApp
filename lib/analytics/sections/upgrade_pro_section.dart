import 'package:flutter/material.dart';
import 'package:mad/analytics/responsive.dart';
import 'package:mad/analytics/styles/styles.dart';

class UpgradeProSection extends StatelessWidget {
  const UpgradeProSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Styles.defaultYellowColor,
        borderRadius: Styles.defaultBorderRadius,
      ),
      padding: EdgeInsets.symmetric(horizontal: Styles.defaultPadding),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.fitWidth,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 18,
                      ),
                      children: [
                        const TextSpan(
                          text: "   ",
                        ),
                        TextSpan(
                          text: "   ",
                          style: TextStyle(
                            color: Styles.defaultRedColor,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: !Responsive.isMobile(context),
                  child: Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: "    "),
                            TextSpan(
                              text: "    ",
                              style: TextStyle(
                                color: Styles.defaultRedColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: "   ",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                    "assets/icons/haciendoglogo-removebg-preview.png"),
              ),
            ),
          ),
          Expanded(
            child: Container(),
          ),
        ],
      ),
    );
  }
}
