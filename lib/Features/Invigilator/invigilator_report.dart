import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvigilatorReport extends StatefulWidget {
  const InvigilatorReport({super.key});

  @override
  State<InvigilatorReport> createState() => _InvigilatorReportState();
}

class _InvigilatorReportState extends State<InvigilatorReport> {
  static const Color tealPrimary = Color(0xFF2E9E8E);
  static const Color tealDark = Color(0xFF227A6D);
  final TextEditingController _incidentController = TextEditingController();

  @override
  void dispose() {
    _incidentController.dispose();
    super.dispose();
  }

  void _showExportOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Attendance List',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tealDark),
            ),
            const SizedBox(height: 8),
            const Text('Select a format to download the attendance report.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _ExportTile(
                    icon: Icons.picture_as_pdf,
                    label: 'PDF Document',
                    color: Colors.red.shade400,
                    onTap: () => _handleDownload('PDF'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ExportTile(
                    icon: Icons.table_chart,
                    label: 'Excel Sheet',
                    color: Colors.green.shade600,
                    onTap: () => _handleDownload('Excel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _handleDownload(String type) {
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text('Downloading $type report...'),
          ],
        ),
        backgroundColor: tealPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        backgroundColor: tealPrimary,
        elevation: 0,
        title: const Text(
          'Final Exam Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistics Section
            const Text(
              'ATTENDANCE SUMMARY',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealDark, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(label: 'Expected', value: '150', color: Colors.blue.shade700),
                  _StatItem(label: 'Present', value: '142', color: Colors.green.shade700),
                  _StatItem(label: 'Absent', value: '8', color: Colors.red.shade700),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Incident Reporting
            const Text(
              'INCIDENT REPORTING',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: tealDark, letterSpacing: 1.2),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
              ),
              child: TextField(
                controller: _incidentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Record any irregularities, technical issues, or exam misconduct cases here...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  contentPadding: const EdgeInsets.all(20),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showExportOptions,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('EXPORT LIST'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tealPrimary,
                      side: const BorderSide(color: tealPrimary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report submitted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('SUBMIT FINAL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ExportTile({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
