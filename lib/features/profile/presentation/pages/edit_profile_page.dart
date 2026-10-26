import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/network/upload_service.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String _existingPhotoUrl = '';
  File? _pickedPhoto;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;
    if (user != null) {
      final appUser = await authRepository.getUserDoc(user.uid);
      if (appUser != null) {
        _nameController.text = appUser.name;
        _phoneController.text = appUser.phone;
        _addressController.text = appUser.address;
        _existingPhotoUrl = appUser.photoUrl;
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;
    if (user == null) return;

    setState(() {
      _pickedPhoto = File(picked.path);
      _isUploadingPhoto = true;
    });
    try {
      final url = await ref
          .read(uploadServiceProvider)
          .uploadImage(_pickedPhoto!, folder: UploadFolders.profileImages);
      await authRepository.updateUserProfile(uid: user.uid, photoUrl: url);
      if (!mounted) return;
      setState(() => _existingPhotoUrl = url);
      showMessage(context, 'Profile photo updated');
    } catch (e) {
      if (mounted)
        showMessage(
            context, 'Could not upload photo: ${friendlyErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      showMessage(context, 'Please enter your name');
      return;
    }
    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await authRepository.updateUserProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );
      if (!mounted) return;
      showMessage(context, 'Profile updated');
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
          context, 'Could not update profile: ${friendlyErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.card,
                          backgroundImage: _pickedPhoto != null
                              ? FileImage(_pickedPhoto!)
                              : (_existingPhotoUrl.isNotEmpty
                                  ? NetworkImage(_existingPhotoUrl)
                                  : null) as ImageProvider?,
                          child:
                              _pickedPhoto == null && _existingPhotoUrl.isEmpty
                                  ? Icon(Icons.person,
                                      size: 48, color: AppColors.accent)
                                  : null,
                        ),
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black38,
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              onPressed: _isUploadingPhoto ? null : _pickPhoto,
                              tooltip: 'Change profile photo',
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  minimumSize: const Size(32, 32)),
                              icon: const Icon(Icons.camera_alt,
                                  size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('Full Name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Phone Number',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Address',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
