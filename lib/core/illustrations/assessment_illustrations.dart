import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Original hand-authored illustrations for the channel/bottom/bank
/// picture-choice questions (see `assets/illustrations/assessment/`).
///
/// Keyed by `questionId:code` rather than just the option code, since
/// `bottomChannelType` and `banksChannelType` both reuse the reference
/// codes `NAT`/`ART` for unrelated pictures.
abstract final class AssessmentIllustrations {
  static const String _base = 'assets/illustrations/assessment';

  static const Map<String, String> _assetByKey = <String, String>{
    'channelForm:FLAT': '$_base/channel_form_flat.svg',
    'channelForm:U': '$_base/channel_form_u.svg',
    'channelForm:V': '$_base/channel_form_v.svg',
    'bottomChannelType:NAT': '$_base/bottom_type_natural.svg',
    'bottomChannelType:ART': '$_base/bottom_type_artificial.svg',
    'banksChannelType:NAT': '$_base/bank_type_natural.svg',
    'banksChannelType:ART': '$_base/bank_type_artificial.svg',
    'banksChannelType:LAS': '$_base/bank_type_laid_stones.svg',
  };

  static String? assetFor(String questionId, String? code) =>
      code == null ? null : _assetByKey['$questionId:$code'];

  /// A picture-choice card's image slot: the matching illustration, or a
  /// plain question-mark glyph for the synthetic "I'm not sure" option.
  static Widget widgetFor(String questionId, String? code) {
    final asset = assetFor(questionId, code);
    if (asset == null) {
      return const ColoredBox(
        color: Color(0xFFE9F7F7),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsRegular.question,
            color: Color(0xFF506773),
          ),
        ),
      );
    }
    return SvgPicture.asset(asset, fit: BoxFit.cover);
  }
}
