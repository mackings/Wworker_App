import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wworker/App/Auth/View/Signup.dart';
import 'package:wworker/Constant/colors.dart';
import 'package:wworker/GeneralWidgets/Nav.dart';
import 'package:wworker/GeneralWidgets/UI/customBtn.dart';
import 'package:wworker/GeneralWidgets/UI/customText.dart';




class FirstOnboard extends ConsumerStatefulWidget {
  const FirstOnboard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FirstOnboardState();
}

class _FirstOnboardState extends ConsumerState<FirstOnboard> {
  int currentIndex = 0;

  static const List<Map<String, String>> onboardingData = [
    {
      "image": "assets/svg/onboard1.svg",
      "title": "Simplify Your Quotation Process",
      "subtitle": "Create, manage and share quote with ease in one app.",
    },
    {
      "image": "assets/svg/onboard2.svg",
      "title": "Turn Ideas into Quotes",
      "subtitle":
          "Use our guided steps to add products, materials, and labor cost with auto-calculations for accuracy.",
    },
    {
      "image": "assets/svg/onboard3.svg",
      "title": "Let’s Create Your First Quote",
      "subtitle": "Start by adding your material dimensions to begin.",
    },
  ];

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in onboardingData) {
        final assetName = item["image"]!;
        SvgAssetLoader(assetName).loadBytes(context);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Nav.push(Signup());
    }
  }

  void _skip() {
    Nav.push(Signup());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: onboardingData.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = onboardingData[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              item["image"]!,
                              height: 300,
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) => const SizedBox(
                                height: 300,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            CustomText(
                              title: item["title"],
                              subtitle: item["subtitle"],
                              titleColor: Colors.black,
                              subtitleColor: Colors.black,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingData.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: currentIndex == index ? 20 : 8,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? const Color(0xFFA16438)
                              : const Color(0xFFD8D8D8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: currentIndex == onboardingData.length - 1
                        ? "Get Started"
                        : "Next",
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),

            Positioned(
              top: 16,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  _skip();
                },
                child: CustomText(
                  title: "Skip",
                  titleColor: ColorsApp.btnColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
