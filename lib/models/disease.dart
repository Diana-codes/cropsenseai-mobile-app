class Disease {
  final String id;
  final String name;
  final String? scientificName;
  final String description;
  final List<String> symptoms;
  final String severityLevel;
  final List<String> affectedCrops;
  final String? imageUrl;
  final DateTime createdAt;

  Disease({
    required this.id,
    required this.name,
    this.scientificName,
    required this.description,
    required this.symptoms,
    required this.severityLevel,
    required this.affectedCrops,
    this.imageUrl,
    required this.createdAt,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'] as String,
      name: json['name'] as String,
      scientificName: json['scientific_name'] as String?,
      description: json['description'] as String,
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      severityLevel: json['severity_level'] as String,
      affectedCrops: (json['affected_crops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'description': description,
      'symptoms': symptoms,
      'severity_level': severityLevel,
      'affected_crops': affectedCrops,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DetectionResult {
  final String id;
  final String userId;
  final String? diseaseId;
  final Disease? disease;
  final String imageUrl;
  final double confidenceScore;
  final List<PredictionScore> topPredictions;
  final String? location;
  final String? cropType;
  final String? notes;
  final String status;
  final DateTime createdAt;

  DetectionResult({
    required this.id,
    required this.userId,
    this.diseaseId,
    this.disease,
    required this.imageUrl,
    required this.confidenceScore,
    required this.topPredictions,
    this.location,
    this.cropType,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      diseaseId: json['disease_id'] as String?,
      disease: json['disease'] != null
          ? Disease.fromJson(json['disease'] as Map<String, dynamic>)
          : null,
      imageUrl: json['image_url'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      topPredictions: (json['top_predictions'] as List<dynamic>?)
              ?.map((e) => PredictionScore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      location: json['location'] as String?,
      cropType: json['crop_type'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PredictionScore {
  final String disease;
  final double confidence;

  PredictionScore({
    required this.disease,
    required this.confidence,
  });

  factory PredictionScore.fromJson(Map<String, dynamic> json) {
    return PredictionScore(
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'confidence': confidence,
    };
  }
}

class Recommendation {
  final String id;
  final String? diseaseId;
  final String recommendationType;
  final String title;
  final String description;
  final List<String> steps;
  final List<Map<String, dynamic>> products;
  final List<String> organicOptions;
  final double costEstimate;
  final int effectivenessRating;
  final int priority;

  Recommendation({
    required this.id,
    this.diseaseId,
    required this.recommendationType,
    required this.title,
    required this.description,
    required this.steps,
    required this.products,
    required this.organicOptions,
    required this.costEstimate,
    required this.effectivenessRating,
    required this.priority,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      diseaseId: json['disease_id'] as String?,
      recommendationType: json['recommendation_type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      organicOptions: (json['organic_options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      costEstimate: (json['cost_estimate'] as num?)?.toDouble() ?? 0.0,
      effectivenessRating: json['effectiveness_rating'] as int? ?? 0,
      priority: json['priority'] as int? ?? 1,
    );
  }
}
