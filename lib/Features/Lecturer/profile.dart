import 'package:flutter/material.dart';

const Color tealPrimary = Color(0xFF2E9E8E);
const Color tealDark = Color(0xFF227A6D);
const Color tealLight = Color(0xFFE0F2F0);

// ─── Profile View Page ────────────────────────────────────────────────────────
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String fullName = 'Dr Sulphuric Moyo';
  String role = 'Lecturer';
  String staffId = '';
  String department = '';
  String email = '';
  String phone = '';

  Future<void> _openEditProfile() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfile(
          initialName: fullName,
          initialRole: role,
          initialStaffId: staffId,
          initialDepartment: department,
          initialEmail: email,
          initialPhone: phone,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        fullName = result['fullName'] ?? fullName;
        role = result['role'] ?? role;
        staffId = result['staffId'] ?? staffId;
        department = result['department'] ?? department;
        email = result['email'] ?? email;
        phone = result['phone'] ?? phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────────────
            const SizedBox(height: 60),
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.person,
                  size: 52,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: tealPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              role,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // ── Info Card ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tealPrimary.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Personal Information', value: ''),
                    _Divider(),
                    _InfoRow(label: 'Staff ID', value: staffId),
                    _Divider(),
                    _InfoRow(label: 'Department', value: department),
                    _Divider(),
                    _InfoRow(label: 'Email', value: email),
                    _Divider(),
                    _InfoRow(label: 'Phone', value: phone),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Edit Button ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: _openEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tealPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── Info Row Widget ──────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isHeader = label == 'Personal Information';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? tealDark : tealPrimary,
            ),
          ),
          const Spacer(),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: tealPrimary.withOpacity(0.1),
      indent: 16,
      endIndent: 16,
    );
  }
}

// ─── Edit Profile Page ────────────────────────────────────────────────────────
class EditProfile extends StatefulWidget {
  final String initialName;
  final String initialRole;
  final String initialStaffId;
  final String initialDepartment;
  final String initialEmail;
  final String initialPhone;

  const EditProfile({
    super.key,
    required this.initialName,
    required this.initialRole,
    required this.initialStaffId,
    required this.initialDepartment,
    required this.initialEmail,
    required this.initialPhone,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _staffIdController;
  late TextEditingController _departmentController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _roleController = TextEditingController(text: widget.initialRole);
    _staffIdController = TextEditingController(text: widget.initialStaffId);
    _departmentController =
        TextEditingController(text: widget.initialDepartment);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _staffIdController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, {
      'fullName': _nameController.text.trim(),
      'role': _roleController.text.trim(),
      'staffId': _staffIdController.text.trim(),
      'department': _departmentController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── Avatar placeholder (image picker will be added when DB is connected) ──
            const SizedBox(height: 40),
            Center(
              child: CircleAvatar(
                radius: 52,
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.person,
                  size: 52,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ── Form Fields ─────────────────────────────────────────────────
            _FormField(controller: _nameController, hint: 'Full name'),
            const SizedBox(height: 12),
            _FormField(controller: _roleController, hint: 'Role'),
            const SizedBox(height: 12),
            _FormField(controller: _staffIdController, hint: 'Staff ID'),
            const SizedBox(height: 12),
            _FormField(controller: _departmentController, hint: 'Department'),
            const SizedBox(height: 12),
            _FormField(
              controller: _emailController,
              hint: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _FormField(
              controller: _phoneController,
              hint: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),

            // ── Save Button ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Form Field ──────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tealPrimary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: tealPrimary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tealPrimary, width: 1.5),
        ),
      ),
    );
  }
}
