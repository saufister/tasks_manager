import 'package:flutter/material.dart';
import 'package:flutter_reorderable_list/flutter_reorderable_list.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:task_manager/core/model/reorder_list_model.dart';

class ReoderableItem extends StatefulWidget {
  ReoderableItem({
    @required this.data,
    this.isFirst,
    this.isLast,
    this.draggingMode,
    this.deleteCallback,
    @required this.controller,
    @required this.focusNode,
  });

  final ItemData data;
  final bool isFirst;
  final bool isLast;
  final DraggingMode draggingMode;
  final Function deleteCallback;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  _ReoderableItemState createState() => _ReoderableItemState();
}

class _ReoderableItemState extends State<ReoderableItem> {
  bool isFocus = false;
  bool firstBuild = true;

  @override
  void initState() {
    if (widget.data.subtask.subtaskName != "")
      widget.controller.text = widget.data.subtask.subtaskName;

    widget.focusNode.addListener(_onFocusChange);
    super.initState();
  }

  void _onFocusChange() {
    setState(() {
      widget.focusNode.hasFocus ? isFocus = true : isFocus = false;
    });
  }

  @override
  void dispose() {
    //widget.controller.dispose();
    super.dispose();
  }

  Widget _buildChild(BuildContext context, ReorderableItemState state) {
    BoxDecoration decoration;

    if (state == ReorderableItemState.dragProxy ||
        state == ReorderableItemState.dragProxyFinished) {
      // slightly transparent background white dragging (just like on iOS)
      decoration = BoxDecoration(color: Color(0xD0FFFFFF));
    } else {
      bool placeholder = state == ReorderableItemState.placeholder;
      decoration = BoxDecoration(
          border: Border(
              top: widget.isFirst && !placeholder
                  ? BorderSide.none //
                  : BorderSide.none,
              bottom: widget.isLast && placeholder
                  ? BorderSide.none //
                  : BorderSide.none),
          color: placeholder ? null : Colors.white);
    }

    // For iOS dragging mode, there will be drag handle on the right that triggers
    // reordering; For android mode it will be just an empty container
    Widget dragHandle = widget.draggingMode == DraggingMode.iOS
        ? ReorderableListener(
            child: Container(
              padding: EdgeInsets.all(ScreenUtil().setWidth(15)),
              color: Color(0x08000000),
              child: Center(
                child: Icon(Icons.reorder, color: Color(0xFF888888)),
              ),
            ),
          )
        : Container();

    Widget content = Container(
      decoration: decoration,
      child: SafeArea(
          top: false,
          bottom: false,
          child: Opacity(
            // hide content for placeholder
            opacity: state == ReorderableItemState.placeholder ? 0.0 : 1.0,
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      children: [
                        dragHandle,
                        Checkbox(
                            activeColor: Theme.of(context).primaryColor,
                            value: widget.data.subtask.isDone,
                            onChanged: (value) {
                              setState(() {
                                widget.data.subtask.isDone = value;
                              });
                            }),
                        Flexible(
                            child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          autofocus: widget.data.subtask.subtaskName == "" &&
                                  widget.isLast == true
                              ? true
                              : false,
                          maxLines: null,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          style: widget.data.subtask.isDone == true
                              ? TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 16)
                              : TextStyle(color: Colors.black, fontSize: 16),
                          onChanged: (value) {
                            setState(() {
                              firstBuild = false;
                              widget.data.subtask.subtaskName = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                          ),
                        ))
                      ],
                    ),
                  ),
                  Visibility(
                    visible: isFocus,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          widget.deleteCallback.call(widget.data.key);
                        });
                      },
                      child: Icon(Icons.close,
                          color: Colors.grey, size: ScreenUtil().setWidth(60)),
                    ),
                  )
                ],
              ),
            ),
          )),
    );

    // For android dragging mode, wrap the entire content in DelayedReorderableListener
    if (widget.draggingMode == DraggingMode.Android) {
      content = DelayedReorderableListener(
        child: content,
      );
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableItem(key: widget.data.key, childBuilder: _buildChild);
  }
}
