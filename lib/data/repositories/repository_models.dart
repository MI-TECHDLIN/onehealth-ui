import 'dart:convert';
import 'dart:typed_data';

class AuthUser {
  const AuthUser({
    required this.username,
    required this.displayName,
    this.email,
    this.scopes = const <String>[],
  });

  final String username;
  final String displayName;
  final String? email;
  final List<String> scopes;
}

class StreamSite {
  const StreamSite({
    required this.code,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.cityName,
    this.isUserGenerated = false,
    this.distanceKm,
  });

  final String code;
  final String name;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? cityName;
  final bool isUserGenerated;
  final double? distanceKm;

  StreamSite withDistance(double value) => StreamSite(
    code: code,
    name: name,
    latitude: latitude,
    longitude: longitude,
    altitude: altitude,
    cityName: cityName,
    isUserGenerated: isUserGenerated,
    distanceKm: value,
  );
}

class ReferenceValue {
  const ReferenceValue({
    required this.code,
    required this.name,
    this.description,
  });

  final String code;
  final String name;
  final String? description;
}

enum SiteKind { research, userGenerated }

enum AssessmentMediaRole {
  upstreamPhoto,
  downstreamPhoto,
  surroundingPhoto,
  interestingPhoto,
  video,
}

class AssessmentAttachment {
  const AssessmentAttachment({
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  final String filename;
  final Uint8List bytes;
  final String? contentType;

  Map<String, Object?> toJson() => <String, Object?>{
    'filename': filename,
    'bytes': base64Encode(bytes),
    if (contentType != null) 'contentType': contentType,
  };

  factory AssessmentAttachment.fromJson(Map<String, dynamic> json) =>
      AssessmentAttachment(
        filename: json['filename'] as String,
        bytes: base64Decode(json['bytes'] as String),
        contentType: json['contentType'] as String?,
      );
}

class AssessmentDraft {
  const AssessmentDraft({
    required this.id,
    required this.siteCode,
    this.siteKind = SiteKind.research,
    this.latitude = 0,
    this.longitude = 0,
    this.attachments = const <AssessmentMediaRole, AssessmentAttachment>{},
    this.channelForm,
    this.bottomChannelType,
    this.banksChannelType,
    this.habitats = const <String>[],
    this.fallenBiomassTypes = const <String>[],
    this.waterFlow,
    this.waterColor,
    this.waterAbstraction,
    this.hasDams,
    this.numberOfDams,
    this.pipes,
    this.waterDischarge,
    this.construction,
    this.waterHeight,
    this.imperviousAreasLeft,
    this.imperviousAreasRight,
    this.isVegetationCoveredLeft,
    this.isVegetationCoveredRight,
    this.vegetationTypeLeft,
    this.vegetationTypeRight,
    this.hasInvasivePlantSpecies,
    this.invasivePlantSpecies,
    this.recentVegetationCuts,
    this.overallAssessment = 'MODERATE',
    this.joy = 3,
    this.serenity = 3,
    this.anger = 3,
    this.fear = 3,
  });

  final String id;
  final String siteCode;
  final SiteKind siteKind;
  final double latitude;
  final double longitude;
  final Map<AssessmentMediaRole, AssessmentAttachment> attachments;
  final String? channelForm;
  final String? bottomChannelType;
  final String? banksChannelType;
  final List<String> habitats;
  final List<String> fallenBiomassTypes;
  final String? waterFlow;
  final String? waterColor;
  final bool? waterAbstraction;
  final bool? hasDams;
  final int? numberOfDams;
  final bool? pipes;
  final bool? waterDischarge;
  final bool? construction;
  final String? waterHeight;
  final bool? imperviousAreasLeft;
  final bool? imperviousAreasRight;
  final bool? isVegetationCoveredLeft;
  final bool? isVegetationCoveredRight;
  final String? vegetationTypeLeft;
  final String? vegetationTypeRight;
  final bool? hasInvasivePlantSpecies;
  final String? invasivePlantSpecies;
  final bool? recentVegetationCuts;
  final String overallAssessment;
  final int joy;
  final int serenity;
  final int anger;
  final int fear;

  Map<String, Object?> toSubmissionJson({
    Map<AssessmentMediaRole, String> uploadedFileIds =
        const <AssessmentMediaRole, String>{},
  }) {
    for (final feeling in <int>[joy, serenity, anger, fear]) {
      if (feeling < 0 || feeling > 5) {
        throw const FormatException('Feeling values must be between 0 and 5.');
      }
    }
    if (overallAssessment.isEmpty) {
      throw const FormatException('An overall assessment is required.');
    }

    final json = <String, Object?>{
      'longitude': longitude,
      'latitude': latitude,
      if (siteKind == SiteKind.research) 'researchSite': siteCode,
      if (siteKind == SiteKind.userGenerated) 'userGeneratedSite': siteCode,
      'overallAssessment': overallAssessment,
      'joy': joy,
      'serenity': serenity,
      'anger': anger,
      'fear': fear,
    };

    void addValue(String key, Object? value) {
      if (value == null) return;
      if (value is String && (value.isEmpty || _isNotSure(value))) return;
      if (value is List && value.isEmpty) return;
      json[key] = value;
    }

    for (final entry in uploadedFileIds.entries) {
      addValue(entry.key.name, entry.value);
    }
    addValue('channelForm', channelForm);
    addValue('bottomChannelType', bottomChannelType);
    addValue('banksChannelType', banksChannelType);
    addValue('habitats', habitats);
    addValue('fallenBiomassTypes', fallenBiomassTypes);
    addValue('waterFlow', waterFlow);
    addValue('waterColor', waterColor);
    addValue('waterAbstraction', waterAbstraction);
    addValue('hasDams', hasDams);
    addValue('numberOfDams', numberOfDams);
    addValue('pipes', pipes);
    addValue('waterDischarge', waterDischarge);
    addValue('construction', construction);
    addValue('waterHeight', waterHeight);
    addValue('imperviousAreasLeft', imperviousAreasLeft);
    addValue('imperviousAreasRight', imperviousAreasRight);
    addValue('isVegetationCoveredLeft', isVegetationCoveredLeft);
    addValue('isVegetationCoveredRight', isVegetationCoveredRight);
    addValue('vegetationTypeLeft', vegetationTypeLeft);
    addValue('vegetationTypeRight', vegetationTypeRight);
    addValue('hasInvasivePlantSpecies', hasInvasivePlantSpecies);
    addValue('invasivePlantSpecies', invasivePlantSpecies);
    addValue('recentVegetationCuts', recentVegetationCuts);
    return json;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'siteCode': siteCode,
    'siteKind': siteKind.name,
    'latitude': latitude,
    'longitude': longitude,
    'attachments': <String, Object?>{
      for (final entry in attachments.entries)
        entry.key.name: entry.value.toJson(),
    },
    ...toSubmissionJson(),
  };

  factory AssessmentDraft.fromJson(Map<String, dynamic> json) {
    final attachmentsJson = json['attachments'];
    return AssessmentDraft(
      id: json['id'] as String,
      siteCode: json['siteCode'] as String,
      siteKind: SiteKind.values.byName(
        json['siteKind'] as String? ?? SiteKind.research.name,
      ),
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      attachments: attachmentsJson is Map
          ? <AssessmentMediaRole, AssessmentAttachment>{
              for (final entry in attachmentsJson.entries)
                AssessmentMediaRole.values.byName(entry.key as String):
                    AssessmentAttachment.fromJson(
                      Map<String, dynamic>.from(entry.value as Map),
                    ),
            }
          : const <AssessmentMediaRole, AssessmentAttachment>{},
      channelForm: json['channelForm'] as String?,
      bottomChannelType: json['bottomChannelType'] as String?,
      banksChannelType: json['banksChannelType'] as String?,
      habitats: _strings(json['habitats']),
      fallenBiomassTypes: _strings(json['fallenBiomassTypes']),
      waterFlow: json['waterFlow'] as String?,
      waterColor: json['waterColor'] as String?,
      waterAbstraction: json['waterAbstraction'] as bool?,
      hasDams: json['hasDams'] as bool?,
      numberOfDams: (json['numberOfDams'] as num?)?.toInt(),
      pipes: json['pipes'] as bool?,
      waterDischarge: json['waterDischarge'] as bool?,
      construction: json['construction'] as bool?,
      waterHeight: json['waterHeight'] as String?,
      imperviousAreasLeft: json['imperviousAreasLeft'] as bool?,
      imperviousAreasRight: json['imperviousAreasRight'] as bool?,
      isVegetationCoveredLeft: json['isVegetationCoveredLeft'] as bool?,
      isVegetationCoveredRight: json['isVegetationCoveredRight'] as bool?,
      vegetationTypeLeft: json['vegetationTypeLeft'] as String?,
      vegetationTypeRight: json['vegetationTypeRight'] as String?,
      hasInvasivePlantSpecies: json['hasInvasivePlantSpecies'] as bool?,
      invasivePlantSpecies: json['invasivePlantSpecies'] as String?,
      recentVegetationCuts: json['recentVegetationCuts'] as bool?,
      overallAssessment: json['overallAssessment'] as String? ?? 'MODERATE',
      joy: (json['joy'] as num?)?.toInt() ?? 3,
      serenity: (json['serenity'] as num?)?.toInt() ?? 3,
      anger: (json['anger'] as num?)?.toInt() ?? 3,
      fear: (json['fear'] as num?)?.toInt() ?? 3,
    );
  }
}

class AssessmentRecord {
  const AssessmentRecord({
    required this.id,
    required this.siteCode,
    required this.submittedAt,
    this.siteKind = SiteKind.research,
    this.latitude,
    this.longitude,
    this.username,
    this.overallAssessment,
    this.channelForm,
    this.bottomChannelType,
    this.banksChannelType,
    this.habitats = const <String>[],
    this.fallenBiomassTypes = const <String>[],
    this.waterFlow,
    this.waterColor,
    this.waterAbstraction,
    this.hasDams,
    this.numberOfDams,
    this.pipes,
    this.waterDischarge,
    this.construction,
    this.waterHeight,
    this.imperviousAreasLeft,
    this.imperviousAreasRight,
    this.isVegetationCoveredLeft,
    this.isVegetationCoveredRight,
    this.vegetationTypeLeft,
    this.vegetationTypeRight,
    this.hasInvasivePlantSpecies,
    this.invasivePlantSpecies,
    this.recentVegetationCuts,
    this.joy,
    this.serenity,
    this.anger,
    this.fear,
    this.fileIds = const <AssessmentMediaRole, String>{},
  });

  final String id;
  final String siteCode;
  final SiteKind siteKind;
  final DateTime submittedAt;
  final double? latitude;
  final double? longitude;
  final String? username;
  final String? overallAssessment;
  final String? channelForm;
  final String? bottomChannelType;
  final String? banksChannelType;
  final List<String> habitats;
  final List<String> fallenBiomassTypes;
  final String? waterFlow;
  final String? waterColor;
  final bool? waterAbstraction;
  final bool? hasDams;
  final int? numberOfDams;
  final bool? pipes;
  final bool? waterDischarge;
  final bool? construction;
  final String? waterHeight;
  final bool? imperviousAreasLeft;
  final bool? imperviousAreasRight;
  final bool? isVegetationCoveredLeft;
  final bool? isVegetationCoveredRight;
  final String? vegetationTypeLeft;
  final String? vegetationTypeRight;
  final bool? hasInvasivePlantSpecies;
  final String? invasivePlantSpecies;
  final bool? recentVegetationCuts;
  final int? joy;
  final int? serenity;
  final int? anger;
  final int? fear;
  final Map<AssessmentMediaRole, String> fileIds;

  factory AssessmentRecord.fromApiJson(Map<String, dynamic> json) {
    final researchSite = json['researchSite'];
    final siteKind = researchSite == null
        ? SiteKind.userGenerated
        : SiteKind.research;
    final siteCode = (researchSite ?? json['userGeneratedSite'] ?? '').toString();
    final fileIds = <AssessmentMediaRole, String>{};
    for (final role in AssessmentMediaRole.values) {
      final value = json[role.name];
      if (value != null && value.toString().isNotEmpty) {
        fileIds[role] = value.toString();
      }
    }
    return AssessmentRecord(
      id: json['id'].toString(),
      siteCode: siteCode,
      siteKind: siteKind,
      submittedAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      latitude: _nullableDouble(json['latitude']),
      longitude: _nullableDouble(json['longitude']),
      username: json['user'] as String?,
      overallAssessment: json['overallAssessment'] as String?,
      channelForm: json['channelForm'] as String?,
      bottomChannelType: json['bottomChannelType'] as String?,
      banksChannelType: json['banksChannelType'] as String?,
      habitats: _strings(json['habitats']),
      fallenBiomassTypes: _strings(json['fallenBiomassTypes']),
      waterFlow: json['waterFlow'] as String?,
      waterColor: json['waterColor'] as String?,
      waterAbstraction: json['waterAbstraction'] as bool?,
      hasDams: json['hasDams'] as bool?,
      numberOfDams: (json['numberOfDams'] as num?)?.toInt(),
      pipes: json['pipes'] as bool?,
      waterDischarge: json['waterDischarge'] as bool?,
      construction: json['construction'] as bool?,
      waterHeight: json['waterHeight']?.toString(),
      imperviousAreasLeft: json['imperviousAreasLeft'] as bool?,
      imperviousAreasRight: json['imperviousAreasRight'] as bool?,
      isVegetationCoveredLeft: json['isVegetationCoveredLeft'] as bool?,
      isVegetationCoveredRight: json['isVegetationCoveredRight'] as bool?,
      vegetationTypeLeft: json['vegetationTypeLeft'] as String?,
      vegetationTypeRight: json['vegetationTypeRight'] as String?,
      hasInvasivePlantSpecies: json['hasInvasivePlantSpecies'] as bool?,
      invasivePlantSpecies: json['invasivePlantSpecies'] as String?,
      recentVegetationCuts: json['recentVegetationCuts'] as bool?,
      joy: (json['joy'] as num?)?.toInt(),
      serenity: (json['serenity'] as num?)?.toInt(),
      anger: (json['anger'] as num?)?.toInt(),
      fear: (json['fear'] as num?)?.toInt(),
      fileIds: fileIds,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'siteCode': siteCode,
    'siteKind': siteKind.name,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    if (username != null) 'username': username,
    if (overallAssessment != null) 'overallAssessment': overallAssessment,
  };

  factory AssessmentRecord.fromJson(Map<String, dynamic> json) =>
      AssessmentRecord(
        id: json['id'] as String,
        siteCode: json['siteCode'] as String,
        siteKind: SiteKind.values.byName(
          json['siteKind'] as String? ?? SiteKind.research.name,
        ),
        submittedAt: DateTime.parse(json['submittedAt'] as String).toUtc(),
        latitude: _nullableDouble(json['latitude']),
        longitude: _nullableDouble(json['longitude']),
        username: json['username'] as String?,
        overallAssessment: json['overallAssessment'] as String?,
      );
}

bool _isNotSure(String value) {
  final normalized = value.toLowerCase().replaceAll("'", '').trim();
  return normalized == 'i am not sure' || normalized == 'im not sure';
}

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
double? _nullableDouble(Object? value) => (value as num?)?.toDouble();
List<String> _strings(Object? value) => value is List
    ? value.whereType<Object>().map((item) => item.toString()).toList()
    : const <String>[];
