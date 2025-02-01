import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/gallery/gallerycubit_cubit.dart';
import 'package:gallery_two/bloc/selection/selection_cubit.dart';
import 'package:gallery_two/classes/gallery_image_file.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  void initState() {
    context.read<GalleryCubit>().loadGallery();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          if (state is GalleryLoaded) {
            return PopScope(
              canPop: context.read<SelectionCubit>().state is SelectionActive,
              onPopInvokedWithResult: (didPop, result) {
                if (context.read<SelectionCubit>().state is SelectionActive) {
                  context.read<SelectionCubit>().cancalSelection();
                } else {
                  Navigator.pop(context);
                }
              },
              child: _gallery(state.gallery),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  PreferredSize _appBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: BlocBuilder<SelectionCubit, SelectionState>(
        builder: (context, state) {
          if (state is SelectionActive) {
            return AppBar(
              title: Text("${state.indexes.length} Bilder ausgewählt"),
              actions: [
                IconButton(
                  onPressed: () async {
                    await context
                        .read<GalleryCubit>()
                        .deleteSelectedImages(state.indexes);
                    context.read<SelectionCubit>().cancalSelection();
                  },
                  icon: Icon(Icons.delete),
                )
              ],
            );
          }
          return AppBar(
            title: const Text("Galerie"),
          );
        },
      ),
    );
  }

  Widget _gallery(galleryItems) {
    return ListView.builder(
      itemCount: galleryItems.length,
      itemBuilder: (context, index) {
        final date = galleryItems.keys.elementAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                date,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: galleryItems[date]!.length,
              itemBuilder: (context, index) {
                return _image(galleryItems[date]![index]);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _image(GalleryImageFile galleryFile) {
    final index = galleryFile.id;
    final file = galleryFile.file;
    return GestureDetector(
      onLongPress: () {
        context.read<SelectionCubit>().toggleSelection(index);
      },
      onTap: () {
        if (context.read<SelectionCubit>().state is SelectionActive) {
          context.read<SelectionCubit>().toggleSelection(index);
        } else {
          ImageProvider ss = FileImage(file);
          showImageViewer(context, ss);
        }
      },
      child: BlocBuilder<SelectionCubit, SelectionState>(
        buildWhen: (previous, current) {
          if (previous.indexes.contains(index) &&
              current.indexes.contains(index)) {
            return false;
          } else if (!previous.indexes.contains(index) &&
              !current.indexes.contains(index)) {
            return false;
          }
          return true;
        },
        builder: (context, state) {
          bool isSelected = state.indexes.contains(index);

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
              ),
              if (isSelected) _selectionOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _selectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.7),
      ),
      child: const Center(
        child: Icon(
          Icons.check_circle,
          color: Colors.white,
          size: 60,
        ),
      ),
    );
  }
}
