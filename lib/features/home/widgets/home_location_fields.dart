import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../navigation/models/destination_model.dart';

class HomeLocationFields extends StatelessWidget {
  const HomeLocationFields({
    required this.currentLocationController,
    required this.currentLocationFocusNode,
    required this.destinationController,
    required this.destinationFocusNode,
    required this.isDestinationEditable,
    required this.currentLocationOptionsBuilder,
    required this.destinationOptionsBuilder,
    required this.onCurrentLocationSelected,
    required this.onDestinationSelected,
    required this.onCurrentLocationTextChanged,
    required this.onDestinationTextChanged,
    required this.canStartNavigation,
    required this.isNavigationLoading,
    required this.onCurrentLocationPressed,
    required this.onQrPressed,
    required this.onDestinationPressed,
    required this.onStartNavigationPressed,
    required this.onDestinationSwipeUp,
    required this.onDestinationSwipeDown,
    super.key,
  });

  final TextEditingController currentLocationController;
  final FocusNode currentLocationFocusNode;
  final TextEditingController destinationController;
  final FocusNode destinationFocusNode;
  final bool isDestinationEditable;
  final AutocompleteOptionsBuilder<DestinationModel>
      currentLocationOptionsBuilder;
  final AutocompleteOptionsBuilder<DestinationModel> destinationOptionsBuilder;
  final AutocompleteOnSelected<DestinationModel> onCurrentLocationSelected;
  final AutocompleteOnSelected<DestinationModel> onDestinationSelected;
  final ValueChanged<String> onCurrentLocationTextChanged;
  final ValueChanged<String> onDestinationTextChanged;
  final bool canStartNavigation;
  final bool isNavigationLoading;
  final VoidCallback onCurrentLocationPressed;
  final VoidCallback onQrPressed;
  final VoidCallback onDestinationPressed;
  final VoidCallback onStartNavigationPressed;
  final VoidCallback onDestinationSwipeUp;
  final VoidCallback onDestinationSwipeDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CurrentLocationField(
          controller: currentLocationController,
          focusNode: currentLocationFocusNode,
          leadingAsset: AppAssets.currentLocation,
          optionsBuilder: currentLocationOptionsBuilder,
          onSelected: onCurrentLocationSelected,
          onTextChanged: onCurrentLocationTextChanged,
          onPressed: onCurrentLocationPressed,
          trailing: IconButton(
            tooltip: 'Scan current-location QR checkpoint',
            onPressed: onQrPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: SvgPicture.asset(
              AppAssets.scanQr,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 5),
        _DestinationField(
          controller: destinationController,
          focusNode: destinationFocusNode,
          isEditable: isDestinationEditable,
          optionsBuilder: destinationOptionsBuilder,
          onSelected: onDestinationSelected,
          onTextChanged: onDestinationTextChanged,
          canStartNavigation: canStartNavigation,
          isNavigationLoading: isNavigationLoading,
          onPressed: onDestinationPressed,
          onStartNavigationPressed: onStartNavigationPressed,
          onSwipeUp: onDestinationSwipeUp,
          onSwipeDown: onDestinationSwipeDown,
        ),
      ],
    );
  }
}

class _DestinationField extends StatelessWidget {
  const _DestinationField({
    required this.controller,
    required this.focusNode,
    required this.isEditable,
    required this.optionsBuilder,
    required this.onSelected,
    required this.onTextChanged,
    required this.canStartNavigation,
    required this.isNavigationLoading,
    required this.onPressed,
    required this.onStartNavigationPressed,
    required this.onSwipeUp,
    required this.onSwipeDown,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditable;
  final AutocompleteOptionsBuilder<DestinationModel> optionsBuilder;
  final AutocompleteOnSelected<DestinationModel> onSelected;
  final ValueChanged<String> onTextChanged;
  final bool canStartNavigation;
  final bool isNavigationLoading;
  final VoidCallback onPressed;
  final VoidCallback onStartNavigationPressed;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;

  void _handleVerticalDragEnd(DragEndDetails details) {
    final verticalVelocity = details.primaryVelocity ?? 0;

    if (verticalVelocity < -150) {
      onSwipeUp();
    } else if (verticalVelocity > 150) {
      onSwipeDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: Container(
          height: 55,
          padding: const EdgeInsets.fromLTRB(20, 0, 17, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A77B4), width: 1.25),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 27,
                height: 31,
                child: Center(
                  child: SvgPicture.asset(
                    AppAssets.destinationPin,
                    width: 26,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: isEditable
                    ? RawAutocomplete<DestinationModel>(
                        textEditingController: controller,
                        focusNode: focusNode,
                        displayStringForOption: (option) => option.name,
                        optionsBuilder: optionsBuilder,
                        onSelected: onSelected,
                        fieldViewBuilder:
                            (
                              context,
                              textController,
                              fieldFocusNode,
                              onFieldSubmitted,
                            ) {
                              return TextField(
                                controller: textController,
                                focusNode: fieldFocusNode,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                textCapitalization: TextCapitalization.words,
                                maxLines: 1,
                                cursorColor: const Color(0xFF2A77B4),
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E1E1E),
                                  height: 1,
                                ),
                                decoration: const InputDecoration.collapsed(
                                  hintText: 'Where to?',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFB8B8B8),
                                    height: 1,
                                  ),
                                ),
                                onChanged: onTextChanged,
                                onSubmitted: (_) {
                                  onFieldSubmitted();
                                  if (canStartNavigation) {
                                    onStartNavigationPressed();
                                  }
                                },
                              );
                            },
                        optionsViewBuilder: _buildOptionsView,
                      )
                    : Text(
                        controller.text.isEmpty
                            ? 'Where to?'
                            : controller.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: controller.text.isEmpty
                              ? const Color(0xFFB8B8B8)
                              : const Color(0xFF1E1E1E),
                          height: 1,
                        ),
                      ),
              ),
              if (isNavigationLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF2A77B4),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Calculate route',
                  onPressed:
                      canStartNavigation ? onStartNavigationPressed : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 40,
                  ),
                  icon: const Icon(Icons.directions, size: 27),
                  color: const Color(0xFF2A77B4),
                  disabledColor: const Color(0xFFCDD2D6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrentLocationField extends StatelessWidget {
  const _CurrentLocationField({
    required this.controller,
    required this.focusNode,
    required this.leadingAsset,
    required this.optionsBuilder,
    required this.onSelected,
    required this.onTextChanged,
    required this.onPressed,
    this.trailing,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String leadingAsset;
  final AutocompleteOptionsBuilder<DestinationModel> optionsBuilder;
  final AutocompleteOnSelected<DestinationModel> onSelected;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: const Color(0x33000000),
      borderRadius: BorderRadius.circular(28),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          height: 55,
          padding: const EdgeInsets.fromLTRB(20, 0, 17, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF2A77B4), width: 1.25),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 27,
                height: 31,
                child: Center(
                  child: SvgPicture.asset(
                    leadingAsset,
                    width: 26,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: RawAutocomplete<DestinationModel>(
                  textEditingController: controller,
                  focusNode: focusNode,
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: optionsBuilder,
                  onSelected: onSelected,
                  fieldViewBuilder:
                      (
                        context,
                        textController,
                        fieldFocusNode,
                        onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: textController,
                          focusNode: fieldFocusNode,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.search,
                          textCapitalization: TextCapitalization.words,
                          maxLines: 1,
                          cursorColor: const Color(0xFF2A77B4),
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E1E1E),
                            height: 1,
                          ),
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Current Location',
                            hintStyle: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB8B8B8),
                              height: 1,
                            ),
                          ),
                          onChanged: onTextChanged,
                          onSubmitted: (_) {
                            onFieldSubmitted();
                            fieldFocusNode.unfocus();
                          },
                        );
                      },
                  optionsViewBuilder: _buildOptionsView,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildOptionsView(
  BuildContext context,
  AutocompleteOnSelected<DestinationModel> onSelected,
  Iterable<DestinationModel> options,
) {
  final optionList = options.toList(growable: false);

  return Align(
    alignment: Alignment.topLeft,
    child: Material(
      elevation: 8,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 72,
          maxHeight: 280,
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          shrinkWrap: true,
          itemCount: optionList.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final option = optionList[index];
            final details = [
              option.floorId,
              option.nodeType,
            ].whereType<String>().where((value) => value.trim().isNotEmpty);

            return ListTile(
              dense: true,
              leading: const Icon(
                Icons.place_outlined,
                color: Color(0xFF2A77B4),
              ),
              title: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: details.isEmpty
                  ? null
                  : Text(
                      details.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              onTap: () => onSelected(option),
            );
          },
        ),
      ),
    ),
  );
}
