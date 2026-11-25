import 'package:flutter/material.dart';

const travelBlue = Color(0xFF2454E6);
const travelInk = Color(0xFF171A21);
const travelMuted = Color(0xFF596271);
const travelLine = Color(0xFFE0E4EA);
const travelGray = Color(0xFFF2F4F7);
const travelTint = Color(0xFFEAF0FF);
const travelOrange = Color(0xFFAF510D);
const _travelFont = 'Pretendard';

ThemeData travelTheme() {
  final colors = ColorScheme.fromSeed(seedColor: travelBlue).copyWith(
    primary: travelBlue,
    onPrimary: Colors.white,
    primaryContainer: travelTint,
    onPrimaryContainer: const Color(0xFF16378D),
    surface: Colors.white,
    onSurface: travelInk,
    onSurfaceVariant: travelMuted,
    outline: travelMuted,
    outlineVariant: travelLine,
    surfaceContainerHighest: travelGray,
  );
  final base = ThemeData(colorScheme: colors, fontFamily: _travelFont);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.white,
    dividerColor: travelLine,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: travelInk,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: _travelFont,
        color: travelInk,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(
            fontSize: 32,
            height: 1.22,
            fontWeight: FontWeight.w800,
            color: travelInk,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: travelInk,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: travelInk,
          ),
        )
        .apply(fontFamily: _travelFont),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: travelGray,
      border: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: travelBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: travelLine),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: shape,
        textStyle: const TextStyle(
          fontFamily: _travelFont,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        foregroundColor: travelInk,
        side: const BorderSide(color: travelLine),
        shape: shape,
        textStyle: const TextStyle(
          fontFamily: _travelFont,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: travelBlue,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
  );
}

class TravelWidth extends StatelessWidget {
  const TravelWidth({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class TravelHeading extends StatelessWidget {
  const TravelHeading(this.title, {super.key, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.bodyMedium?.copyWith(color: travelMuted, height: 1.5),
        ),
      ],
    );
  }
}

class TravelSteps extends StatelessWidget {
  const TravelSteps({super.key, required this.steps, required this.current});

  final List<String> steps;
  final int current;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${steps.length}단계 중 ${current + 1}단계: ${steps[current]}',
    excludeSemantics: true,
    child: Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: index <= current ? travelBlue : travelLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: index <= current ? travelBlue : travelMuted,
                    fontWeight: index == current ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
