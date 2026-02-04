import 'package:flutter/material.dart';

/// Screen showing "Letter to Our Neighbors" — a note on reclaiming our humanity.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Letter from Twingl.'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'To Our Neighbors',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Section 1: Hello
            _LetterSection(
              icon: Icons.waving_hand,
              iconColor: Colors.amber,
              text:
                  'Hello,\nAs we step out of the quiet years of the pandemic, many of us have grown used to a world without touch. Screens have given us efficiency, but the trust and warmth built through face-to-face interactions have quietly faded away.',
            ),
            const SizedBox(height: 24),

            // Section 2: The AI Question
            _LetterSection(
              icon: Icons.smart_toy,
              iconColor: Colors.blueGrey,
              text:
                  "Now, standing at the dawn of the AI era, we face a new reality. Algorithms answer faster than we can, and machines are learning to do our work. Behind this convenience, a quiet question lingers in our minds:\n\n'In a world where machines do so much, what is left for us?'",
            ),
            const SizedBox(height: 24),

            // Section 3: The Twingl Answer
            _LetterSection(
              icon: Icons.favorite,
              iconColor: Colors.red,
              text:
                  'At Twingl, we found the answer in the things AI can never replace: the joy of growing and the warmth of being together.',
            ),
            const SizedBox(height: 24),

            // Section 4: Human Connection
            _LetterSection(
              icon: Icons.psychology,
              iconColor: Colors.deepPurple,
              text:
                  'Technology can give you knowledge, but it cannot offer genuine empathy when you struggle. It cannot share the thrill of your breakthrough. The excitement of learning and the fulfillment of teaching—these are experiences that belong solely to human connection.',
            ),
            const SizedBox(height: 24),

            // Section 5: Mission & Roles
            _LetterSection(
              icon: Icons.people_alt,
              iconColor: Colors.green,
              text:
                  'We built Twingl to restore these lost values. We want to bridge the gap between online convenience and the depth of offline interaction.\n\nHere, you are not just a user.\n\n🎒 **As a Student**, you rediscover the pure joy of personal growth.\n💡 **As a Tutor**, you share your experience and give others the courage to try.\n\nThis journey of patience, mentorship, and mutual support is something no machine can mimic.',
              useRichText: true,
            ),
            const SizedBox(height: 24),

            // Section 6: The Proverb
            _LetterSection(
              icon: Icons.explore,
              iconColor: Colors.blue,
              text:
                  "There is an old African proverb:\n\n**'If you want to go fast, go alone. If you want to go far, go together.'**",
              useRichText: true,
            ),
            const SizedBox(height: 24),

            // Section 7: Outro
            _LetterSection(
              icon: Icons.rocket_launch,
              iconColor: Colors.orange,
              text:
                  "In a world obsessed with speed, we choose to go far. We invite you to join this journey—not just with technology, but with your friends, family, colleagues, and the mentors living right next door.\n\nLet's restore our true potential. Let's go far, together.",
            ),
            const SizedBox(height: 24),

            // Footer
            Align(
              alignment: Alignment.centerRight,
              child: RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  children: [
                    const TextSpan(text: 'With hope,\n'),
                    TextSpan(
                      text: 'The Twingl Team',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            height: 1.5,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A section with an icon on the left and text on the right.
class _LetterSection extends StatelessWidget {
  const _LetterSection({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.useRichText = false,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final bool useRichText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 32, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: useRichText
              ? _buildRichText(context)
              : Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
        ),
      ],
    );
  }

  Widget _buildRichText(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
        ) ??
        const TextStyle();
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    final defaultColor =
        baseStyle.copyWith(color: Theme.of(context).colorScheme.onSurface);

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    var lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: defaultColor,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1) ?? '',
        style: boldStyle.copyWith(
            color: Theme.of(context).colorScheme.onSurface),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: defaultColor,
      ));
    }

    return RichText(
      text: TextSpan(
        style: defaultColor,
        children: spans,
      ),
    );
  }
}
