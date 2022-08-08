import 'package:stripes_ui/UI/Record/question_screen.dart';

class SymptomRecordData {
  final QuestionsListener? listener;

  final bool? isEditing;

  final DateTime? submitTime;

  final String? initialDesc;

  static const empty = SymptomRecordData();

  const SymptomRecordData(
      {this.listener, this.isEditing, this.submitTime, this.initialDesc});
}
