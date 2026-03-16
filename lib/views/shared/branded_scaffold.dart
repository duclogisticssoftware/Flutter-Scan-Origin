import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandedScaffold extends StatelessWidget {
  final Widget child;
  final bool showAppBar;
  final String? title;
  const BrandedScaffold({super.key, required this.child, this.showAppBar = true, this.title});

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      'assets/images/company_logo.svg',
      height: 28,
      semanticsLabel: 'Company Logo',
    );
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  logo,
                  const SizedBox(width: 8),
                  Text(title ?? 'LMS APP'),
                ],
              ),
              centerTitle: true,
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F7FB), Colors.white],
          ),
        ),
        child: child,
      ),
    );
  }
}


