import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripes_backend_helper/QuestionModel/question.dart';
import 'package:stripes_ui/Providers/questions_provider.dart';
import 'package:stripes_ui/UI/CommonWidgets/loading.dart';
import 'package:stripes_ui/UI/CommonWidgets/user_profile_button.dart';
import 'package:stripes_ui/UI/Layout/home_screen.dart';
import 'package:stripes_ui/UI/Layout/tab_view.dart';
import 'package:stripes_ui/Util/breakpoint.dart';
import 'package:stripes_ui/Util/constants.dart';
import 'package:stripes_ui/Util/extensions.dart';

class SymptomTypeManagement extends ConsumerWidget {
  final String? category;

  const SymptomTypeManagement({required this.category, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isSmall = getBreakpoint(context).isLessThan(Breakpoint.medium);
    final AsyncValue<Map<String, List<Question>>> questions =
        ref.watch(questionsByType(context));

    Widget loaded(Map<String, List<Question>> questions) {
      final List<Question>? ofCategory =
          category != null ? questions[category] : null;

      return RefreshWidget(
        depth: RefreshDepth.subuser,
        scrollable: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () {
                      context.goNamed(Routes.SYMPTOMS);
                    },
                    icon: const Icon(Icons.keyboard_arrow_left)),
                category != null
                    ? Text(
                        category!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor),
                        textAlign: TextAlign.left,
                      )
                    : Text(
                        "No Category Provided",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor),
                        textAlign: TextAlign.left,
                      ),
                const Spacer(),
              ],
            ),
            const SizedBox(
              height: 6.0,
            ),
            if (ofCategory == null)
              Center(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Category not created"),
                      const SizedBox(
                        height: 8.0,
                      ),
                      FilledButton.icon(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                          label: const Text("Create"))
                    ]),
              ),
            if (ofCategory != null)
              ...ofCategory
                  .map(
                    (question) => ListTile(
                      title: Text(question.prompt),
                    ),
                  )
                  .separated(
                      by: const Divider(
                        endIndent: 8.0,
                        indent: 8.0,
                      ),
                      includeEnds: true),
          ]),
        ),
      );
    }

    return PageWrap(
        actions: [
          if (!isSmall)
            ...TabOption.values.map((tab) => LargeNavButton(tab: tab)),
          const UserProfileButton(
            selected: true,
          )
        ],
        bottomNav: isSmall ? const SmallLayout() : null,
        child: questions.map(
            data: (data) => loaded(data.value),
            loading: (_) => const LoadingWidget(),
            error: (error) => Center(
                  child: Text("Error: ${error.error.toString()}"),
                )));
  }
}
