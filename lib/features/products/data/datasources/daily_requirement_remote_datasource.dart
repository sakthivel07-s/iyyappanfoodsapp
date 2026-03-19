import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/daily_requirement.dart';
import '../models/daily_requirement_model.dart';

abstract class DailyRequirementRemoteDataSource {
  Stream<Either<Failure, List<DailyRequirement>>> getDailyRequirements(DateTime date);
  Future<Either<Failure, void>> saveDailyRequirement(DailyRequirementModel requirement);
}

class DailyRequirementRemoteDataSourceImpl implements DailyRequirementRemoteDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'daily_requirements';

  DailyRequirementRemoteDataSourceImpl(this._firestore);

  @override
  Stream<Either<Failure, List<DailyRequirement>>> getDailyRequirements(DateTime date) {
    // Standardize date to start of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map<Either<Failure, List<DailyRequirement>>>((snap) {
      final list = snap.docs.map((d) => DailyRequirementModel.fromFirestore(d)).toList();
      return Right(list);
    }).handleError((e) => Left(ServerFailure(e.toString())));
  }

  @override
  Future<Either<Failure, void>> saveDailyRequirement(DailyRequirementModel requirement) async {
    try {
      // Use document ID as customerId + YYYYMMDD to ensure one entry per customer per day
      final dateStr = '${requirement.date.year}${requirement.date.month.toString().padLeft(2, '0')}${requirement.date.day.toString().padLeft(2, '0')}';
      final docId = '${requirement.customerId}_$dateStr';

      await _firestore.collection(_collection).doc(docId).set(requirement.toFirestore(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
