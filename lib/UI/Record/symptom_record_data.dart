import 'package:stripes_ui/UI/Record/question_screen.dart';

class SymptomRecordData {
  final QuestionsListener? listener;

  final String? editId;

  final DateTime? submitTime;

  final String? initialDesc;

  static const empty = SymptomRecordData();

  const SymptomRecordData(
      {this.listener, this.editId, this.submitTime, this.initialDesc});
}
