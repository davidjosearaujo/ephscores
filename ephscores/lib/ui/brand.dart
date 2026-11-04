import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';

/// The logo, drawn from the single master file so the app, the launcher icons
/// and the web icons can never drift apart.
const logoAsset = 'assets/brand/logo.svg';

/// The three coloured arms of the star, as written in [logoAsset] (they are
/// the score colours of the app). A test checks the SVG still uses them.
const logoArmColors = [Palette.green, Palette.amber, Palette.red];

/// The logo: a navy badge holding the star, whose three top arms are green,
/// amber and red. The badge brings its own navy background, so the same
/// image works on light surfaces, dark ones and the navy header alike.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    logoAsset,
    width: size,
    height: size,
    semanticsLabel: 'EPHScores',
  );
}

/// Recolours the logo so a single arm can be shown on its own, or none.
class _LogoLayer extends ColorMapper {
  /// All three coloured arms look like the white ones: the "unlit" logo.
  const _LogoLayer.unlit() : arm = null;

  /// Only [arm] is drawn; everything else is transparent, so the layer can be
  /// faded in over the unlit logo without changing anything else.
  const _LogoLayer.only(Color this.arm);

  final Color? arm;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (arm == null) {
      return logoArmColors.contains(color) ? Colors.white : color;
    }
    return color == arm ? color : Colors.transparent;
  }

  // The SVG cache is keyed by the mapper, so it needs value equality.
  @override
  bool operator ==(Object other) => other is _LogoLayer && other.arm == arm;

  @override
  int get hashCode => arm.hashCode;
}

/// The logo with its three arms lighting up in turn, green, amber, red, once.
/// It then settles on the plain [AppLogo], and is static from the start when
/// the system asks to reduce motion.
///
/// An SVG can't animate parts of itself, so the unlit logo is stacked with one
/// transparent layer per coloured arm, each made from the same file and faded
/// in. The final swap to a single image avoids doubled antialiased edges.
class LogoReveal extends StatefulWidget {
  const LogoReveal({super.key, this.size = 160});

  final double size;

  @override
  State<LogoReveal> createState() => _LogoRevealState();
}

class _LogoRevealState extends State<LogoReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..addStatusListener(_onStatus);

  // Left to right across the top, like the gauge it echoes.
  late final List<Animation<double>> _fades = [
    for (final (i, _) in logoArmColors.indexed)
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.12 + i * 0.22,
          0.42 + i * 0.22,
          curve: Curves.easeOut,
        ),
      ),
  ];

  bool _started = false;
  bool _done = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _done = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _done = true;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _layer(_LogoLayer colors) => SvgPicture.asset(
    logoAsset,
    width: widget.size,
    height: widget.size,
    colorMapper: colors,
  );

  @override
  Widget build(BuildContext context) {
    if (_done) return AppLogo(size: widget.size);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          _layer(const _LogoLayer.unlit()),
          for (final (i, arm) in logoArmColors.indexed)
            FadeTransition(
              opacity: _fades[i],
              child: _layer(_LogoLayer.only(arm)),
            ),
        ],
      ),
    );
  }
}

/// "EPHScores" in two weights: heavy "EPH", regular "Scores".
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.style, this.textAlign});

  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text.rich(
    textAlign: textAlign,
    TextSpan(
      style: style,
      children: const [
        TextSpan(
          text: 'EPH',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        TextSpan(
          text: 'Scores',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
      ],
    ),
  );
}
