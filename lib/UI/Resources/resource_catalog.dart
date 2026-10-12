import 'resource_article.dart';
import 'terms_of_service.dart';

ResourceArticle resourceArticle(ResourceTopic topic) =>
    resourceArticles.firstWhere((article) => article.topic == topic);

const _muffinIngredients = ResourceSection(
  id: 'muffin-ingredients',
  title: 'What’s in the blue meal muffin?',
  bullets: [
    '3 large egg whites',
    '1/2 teaspoon cream of tartar',
    '1 tablespoon sugar',
    '2 tablespoons Smucker’s seedless raspberry jam, or another flavor with '
        '50 calories per tablespoon',
    '2 tablespoons King Arthur Gluten-Free Measure for Measure Flour',
    '1 1/2 teaspoons soy protein powder; alternatively, whey protein '
        '(10 calories)',
    '1 teaspoon McCormick blue food coloring',
  ],
);

const _muffinMethod = ResourceSection(
  // The supplied recipe and https://www.bluepoop.info/ both omit when the
  // listed food coloring is added. Keep the method faithful pending review.
  id: 'muffin-method',
  title: 'Make the blue meal muffin',
  steps: [
    ResourceStep(
      title: 'Preheat the oven',
      description: 'Preheat the oven to 350°F.',
    ),
    ResourceStep(
      title: 'Beat the egg whites',
      description:
          'Use electric beaters to beat the egg whites with the cream '
          'of tartar and sugar for 1 minute, or until soft peaks form.',
    ),
    ResourceStep(
      title: 'Add the jam',
      description:
          'Add 2 tablespoons of jam and continue to beat for 30 seconds.',
    ),
    ResourceStep(
      title: 'Add the flour',
      description:
          'Add the flour in two batches, 1 tablespoon at a time, '
          'and beat for a full minute after each addition.',
    ),
    ResourceStep(
      title: 'Add the protein powder',
      description: 'Add the protein powder and beat until incorporated.',
    ),
    ResourceStep(
      title: 'Fill the muffin tins',
      description:
          'Line muffin tins with parchment paper and fill two of '
          'them with the batter.',
    ),
    ResourceStep(
      title: 'Bake',
      description:
          'Cook for 30 minutes, or until the internal temperature '
          'reaches 206°F.',
    ),
  ],
);

const List<ResourceArticle> resourceArticles = [
  ResourceArticle(
    topic: ResourceTopic.blueMealStudy,
    title: 'What is the Blue Meal Study?',
    summary: 'Learn the purpose of the study and how it works.',
    description:
        'The Blue Meal Study helps track how quickly food moves '
        'through your body using a blue meal. You’ll record symptoms and '
        'bowel movements to support this process.',
    sections: [
      ResourceSection(
        id: 'study-steps',
        title: 'What you’ll do',
        initiallyExpanded: true,
        paragraphs: [
          'This is an overview. Follow the study instructions in your '
              'tracking screen for the timing and requirements of each step.',
        ],
        steps: [
          ResourceStep(
            title: 'Eat the first blue meal',
            description:
                'Eat the blue muffin and record the time you '
                'finish eating.',
          ),
          ResourceStep(
            title: 'Record bowel movements',
            description:
                'Log bowel movements and symptoms as directed '
                'in your study instructions.',
          ),
          ResourceStep(
            title: 'Eat the second blue meal',
            description:
                'After the waiting period, follow your study '
                'instructions to eat and record the second blue muffin.',
          ),
          ResourceStep(
            title: 'Continue recording',
            description:
                'Keep logging bowel movements for the second '
                'tracking period.',
          ),
        ],
      ),
      _muffinIngredients,
      ResourceSection(
        id: 'study-duration',
        title: 'How long does it take?',
        paragraphs: [
          'The study includes two tracking periods separated by a waiting '
              'period. Timing varies based on when bowel movements occur, '
              'so it may be different for each person.',
          'Your study tracking screen explains when to move to the next step.',
        ],
      ),
      ResourceSection(
        id: 'study-withdrawal',
        title: 'How do I withdraw?',
        paragraphs: [
          'If you would like to stop participating, contact the study team '
              'at BlueMeal@iu.edu.',
        ],
        links: [
          ResourceLink(
            label: 'Email the study team',
            url: 'mailto:BlueMeal@iu.edu',
          ),
        ],
      ),
    ],
    relatedTopics: [ResourceTopic.symptomTracking, ResourceTopic.bristolScale],
  ),
  ResourceArticle(
    topic: ResourceTopic.blueMealAtHome,
    title: 'Blue Meal Study at home',
    summary: 'Explore the at-home guide and blue muffin recipe.',
    description:
        'You can try a simple version of the Blue Meal Study at '
        'home to understand how digestion works. This helps track how long '
        'it takes food to move through the body. If you’re enrolled in a '
        'study, follow your study instructions.',
    sections: [
      ResourceSection(
        id: 'why-try-it',
        title: 'Why try this?',
        bullets: [
          'Learn how your digestion works.',
          'Notice patterns between meals and symptoms.',
          'Share helpful information with your care team.',
        ],
      ),
      ResourceSection(
        id: 'at-home-steps',
        title: 'How it works',
        initiallyExpanded: true,
        steps: [
          ResourceStep(
            title: 'Eat a blue meal',
            description: 'After a 6–8 hour fast, eat a blue-colored meal.',
          ),
          ResourceStep(
            title: 'Record the time',
            description: 'Note when you finish eating.',
          ),
          ResourceStep(
            title: 'Track bowel movements',
            description: 'Log each bowel movement after the meal.',
          ),
          ResourceStep(
            title: 'Look for color changes',
            description:
                'Record the first blue or green bowel movement '
                'after the meal.',
          ),
          ResourceStep(
            title: 'Continue logging',
            description:
                'Keep tracking until stool returns to its normal '
                'color.',
          ),
        ],
      ),
      ResourceSection(
        id: 'at-home-tips',
        title: 'Tips for tracking',
        bullets: [
          'The first bowel movement may not be blue.',
          'You may have multiple blue bowel movements.',
          'Don’t worry about being exact; track what you notice.',
        ],
      ),
      _muffinIngredients,
      _muffinMethod,
    ],
    relatedTopics: [ResourceTopic.bristolScale, ResourceTopic.bluePoop],
  ),
  ResourceArticle(
    topic: ResourceTopic.bristolScale,
    title: 'What is the Bristol Stool Scale?',
    summary: 'Understand stool types and choose the closest match.',
    description:
        'The Bristol Stool Scale helps you describe what a bowel '
        'movement looks like. It uses simple categories so you can choose '
        'the closest match.',
    sections: [
      ResourceSection(
        id: 'why-stool-types-matter',
        title: 'Why this matters',
        paragraphs: [
          'Recording stool type gives you and your care team a consistent '
              'way to describe bowel movements and notice changes over time.',
        ],
      ),
      ResourceSection(
        id: 'stool-types',
        title: 'Find the closest stool type',
        initiallyExpanded: true,
        showBristolScale: true,
      ),
      ResourceSection(
        id: 'stool-type-tips',
        title: 'If you’re unsure which type to pick',
        bullets: [
          'Choose the type that looks most similar.',
          'It doesn’t have to be a perfect match.',
          'Add a note to your log if you want to describe more detail.',
        ],
      ),
    ],
    relatedTopics: [ResourceTopic.symptomTracking, ResourceTopic.blueMealStudy],
  ),
  ResourceArticle(
    topic: ResourceTopic.symptomTracking,
    title: 'How do I track symptoms?',
    summary: 'Build a consistent record of symptoms, meals, and timing.',
    description:
        'Tracking helps you understand patterns and changes over '
        'time. With STRiPES, you can log symptoms, meals, and timing '
        'for accurate tracking.',
    sections: [
      ResourceSection(
        id: 'tracking-basics',
        title: 'Start with the basics',
        initiallyExpanded: true,
        steps: [
          ResourceStep(
            title: 'Select symptoms',
            description:
                'Choose all symptoms you notice. Select one or '
                'more categories that apply.',
          ),
          ResourceStep(
            title: 'Log when it happens',
            description:
                'Record symptoms as they occur, or as soon '
                'as possible.',
          ),
          ResourceStep(
            title: 'Add details',
            description:
                'Include helpful information such as timing, '
                'severity, or notes when you can.',
          ),
          ResourceStep(
            title: 'Repeat daily',
            description:
                'Keep tracking consistently. Log symptoms each '
                'day during the study.',
          ),
        ],
      ),
      ResourceSection(
        id: 'blue-meal-tracking',
        title: 'Tracking during the Blue Meal Study',
        paragraphs: [
          'Follow the instructions for your current study step. Record '
              'when you finish the blue meal and log bowel movements '
              'as they happen.',
          'The first bowel movement may not be blue. Record color changes '
              'as you notice them, and continue tracking for the period '
              'specified in your study instructions.',
        ],
      ),
      ResourceSection(
        id: 'different-situations',
        title: 'How to log different situations',
        steps: [
          ResourceStep(
            title: 'Single events, such as a bowel movement',
            description: 'Log each time it happens.',
          ),
          ResourceStep(
            title: 'Ongoing symptoms, such as pain',
            description:
                'Log when the symptom starts. Update or add '
                'another entry if it changes or lasts a long time.',
          ),
          ResourceStep(
            title: 'Multiple symptoms together',
            description:
                'Log them in one entry when possible. Add details '
                'or notes to describe each symptom.',
          ),
          ResourceStep(
            title: 'Something doesn’t go as planned',
            description:
                'If you don’t finish a meal, for example, still '
                'log the entry and add a note explaining what happened.',
          ),
        ],
      ),
      ResourceSection(
        id: 'when-to-log',
        title: 'When should I log?',
        paragraphs: [
          'Log symptoms when they happen. If you miss an entry, log it '
              'as soon as you remember.',
          'For ongoing symptoms such as pain, log when the symptom '
              'starts and update the entry if it changes.',
        ],
      ),
    ],
    relatedTopics: [ResourceTopic.bristolScale, ResourceTopic.blueMealStudy],
  ),
  ResourceArticle(
    topic: ResourceTopic.bluePoop,
    title: 'Bluepoop.info',
    summary: 'Explore the science and recipe behind the blue meal.',
    description:
        'Bluepoop.info is the companion site to STRiPES. It '
        'explains the science behind the blue meal method used to '
        'measure gastrointestinal transit time.',
    sections: [
      ResourceSection(
        id: 'visit-bluepoop',
        title: 'Explore the companion site',
        initiallyExpanded: true,
        paragraphs: [
          'Find the full muffin recipe, step-by-step instructions, '
              'the math behind transit time and lag phase, and '
              'the published research the method is based on.',
        ],
        links: [
          ResourceLink(
            label: 'Visit bluepoop.info',
            url: 'https://www.bluepoop.info/',
          ),
        ],
      ),
    ],
    relatedTopics: [ResourceTopic.blueMealAtHome, ResourceTopic.blueMealStudy],
  ),
  ResourceArticle(
    topic: ResourceTopic.termsOfService,
    title: 'Terms of Service',
    summary: 'Review the terms for using STRiPES.',
    description:
        'Read the app’s terms, including basic use, study '
        'participation, privacy, and support contacts.',
    sections: [
      ResourceSection(
        id: 'terms',
        title: 'Terms of Service for Stripes',
        initiallyExpanded: true,
        markdown: stripesTermsOfServiceMarkdown,
      ),
    ],
  ),
];
