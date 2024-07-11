import 'package:flutter/material.dart';
import 'package:mad/analytics/models/card_details.dart';
import 'package:mad/analytics/widgets/card_details_widget.dart';
import 'package:mad/analytics/widgets/category_box.dart';

class CardsSection extends StatelessWidget {
  final List<CardDetails> cardDetails;

  const CardsSection({Key? key, required this.cardDetails}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CategoryBox(
      title: "Your Cards",
      suffix: Container(),
      children: cardDetails
          .map(
            (CardDetails details) => CardDetailsWidget(cardDetails: details),
          )
          .toList(),
    );
  }
}
