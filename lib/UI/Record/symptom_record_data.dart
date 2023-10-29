import 'package:stripes_ui/UI/Record/question_screen.dart';

class SymptomRecordData {
  final QuestionsListener? listener;

  final String? editId;

  final bool? isEdit;

  final DateTime? submitTime;

  final String? initialDesc;

  static const empty = SymptomRecordData();

  const SymptomRecordData(
      {this.listener,
      this.isEdit,
      this.editId,
      this.submitTime,
      this.initialDesc});
}
