import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

class InvigilatorReport extends StatefulWidget {
  final String courseCode;
  final String date;
  final String venue;

  const InvigilatorReport({
    super.key,
    required this.courseCode,
    required this.date,
    required this.venue,
  });

  @override
  State<InvigilatorReport> createState() => _InvigilatorReportState();
}

class _InvigilatorReportState extends State<InvigilatorReport> {
  final TextEditingController _reportController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final reportText = _reportController.text.trim();
    if (reportText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a report before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    try {
      await FirebaseFirestore.instance.collection('invigilator_reports').add({
        'courseCode': widget.courseCode,
        'date': widget.date,
        'venue': widget.venue,
        'report': reportText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        _reportController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: tealDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearReport() {
    _reportController.clear();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AAS',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 15,
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────────
            const SizedBox(height: 8),
            const Text(
              'Write Report',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: tealPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // ── Assignment details card ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tealPrimary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  _detailRow('COURSE', widget.courseCode),
                  const SizedBox(height: 10),
                  _detailRow('DATE', widget.date),
                  const SizedBox(height: 10),
                  _detailRow('VENUE', widget.venue),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Report text area ───────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tealPrimary.withOpacity(0.2)),
              ),
              child: TextField(
                controller: _reportController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write report here',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Warning notice ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tealPrimary.withOpacity(0.15)),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700, height: 1.5),
                  children: const [
                    TextSpan(
                      text:
                          'Before submitting, ensure all exam details are correct and clearly described any incident, observations, or issues that occurred during the session. ',
                    ),
                    TextSpan(
                      text:
                          'Submit the report only after verifying all information.',
                      style: TextStyle(
                          color: tealPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Action buttons ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearReport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tealDark,
                      side: const BorderSide(color: tealPrimary, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Clear',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: tealDark,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
