import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gallery_two/bloc/gallery/gallerycubit_cubit.dart';
import 'package:gallery_two/bloc/selection/selection_cubit.dart';
import 'package:gallery_two/classes/gallery_image_file.dart';
import 'package:gallery_two/core/widgets/custom_image_viewer.dart';

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
        builder: (context, galleryState) {
          if (galleryState is GalleryLoaded) {
            return BlocBuilder<SelectionCubit, SelectionState>(
              builder: (context, selectionState) {
                final bool isSelectionActive =
                    selectionState is SelectionActive;
                return PopScope(
                  canPop: !isSelectionActive,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    if (isSelectionActive) {
                      context.read<SelectionCubit>().cancalSelection();
                    }
                  },
                  child: _gallery(galleryState.gallery),
                );
              },
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
                    if (context.mounted) {
                      context.read<SelectionCubit>().cancalSelection();
                    }
                  },
                  icon: const Icon(Icons.delete),
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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CustomImageViewer(imageProvider: ss),
            ),
          );
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
