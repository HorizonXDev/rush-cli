// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Assets _$AssetsFromJson(Map json) {
  return $checkedNew('Assets', json, () {
    $checkKeys(json,
        allowedKeys: const ['icon', 'other'], requiredKeys: const ['icon']);
    final val = Assets(
      icon: $checkedConvert(json, 'icon', (v) => v as String),
      other: $checkedConvert(json, 'other',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
    );
    return val;
  });
}

Map<String, dynamic> _$AssetsToJson(Assets instance) {
  final val = <String, dynamic>{
    'icon': instance.icon,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('other', instance.other);
  return val;
}
