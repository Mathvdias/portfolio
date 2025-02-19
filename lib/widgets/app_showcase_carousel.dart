import 'package:flutter/material.dart';

class AppShowcaseCarousel extends StatefulWidget {
  const AppShowcaseCarousel({super.key});

  @override
  State<AppShowcaseCarousel> createState() => _AppShowcaseCarouselState();
}

class _AppShowcaseCarouselState extends State<AppShowcaseCarousel> {
  final CarouselController controller = CarouselController(initialItem: 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.sizeOf(context).height;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height / 2),
      child: CarouselView.weighted(
        controller: controller,
        itemSnapping: true,
        flexWeights: const <int>[1, 7, 1],
        children: AppShowcase.values.map((AppShowcase app) {
          return AppShowcaseCard(app: app);
        }).toList(),
      ),
    );
  }
}

class AppShowcaseCard extends StatelessWidget {
  const AppShowcaseCard({super.key, required this.app});

  final AppShowcase app;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              image: NetworkImage(app.imageUrl),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                app.name,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                app.description,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum AppShowcase {
  app1('Flutter App 1', 'A beautiful mobile application', 'URL_TO_APP_1_SCREENSHOT'),
  app2('Flutter App 2', 'An innovative solution', 'URL_TO_APP_2_SCREENSHOT'),
  app3('Flutter App 3', 'Cutting-edge technology', 'URL_TO_APP_3_SCREENSHOT');

  const AppShowcase(this.name, this.description, this.imageUrl);
  final String name;
  final String description;
  final String imageUrl;
}

class CarouselController {
  CarouselController({required this.initialItem});
  final int initialItem;
  void dispose() {}
}

class CarouselView extends StatelessWidget {
  const CarouselView.weighted({
    super.key,
    required this.controller,
    required this.itemSnapping,
    required this.flexWeights,
    required this.children,
  });

  final CarouselController controller;
  final bool itemSnapping;
  final List<int> flexWeights;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: children,
    );
  }
}