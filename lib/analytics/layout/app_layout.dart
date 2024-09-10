import 'package:flutter/cupertino.dart';
import 'package:mad/analytics/layout/navigation_panel.dart';
import 'package:mad/analytics/layout/top_app_bar.dart';
import 'package:mad/analytics/responsive.dart';

class AppLayout extends StatelessWidget {
  final Widget content;

  const AppLayout({Key? key, required this.content}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: Column(
        children: [
          const TopAppBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: content,
            ),
          ),
        ],
      ),
      desktop: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0, bottom: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 60, child: TopAppBar()),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
