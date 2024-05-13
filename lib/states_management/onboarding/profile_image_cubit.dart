import 'dart:io';
import 'dart:typed_data'; // Importe isso para usar Uint8List

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageCubit extends Cubit<File> {
  final _picker = ImagePicker();
  ProfileImageCubit() : super(File(''));

  Future<void> init() async {
    // Carrega o arquivo de imagem padrão do diretório de assets
    final ByteData data = await rootBundle.load('assets/profile.png');
    final Uint8List bytes = data.buffer.asUint8List();
    emit(File.fromRawPath(bytes));
  }

  Future<void> getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    emit(File(image.path));
  }
}
