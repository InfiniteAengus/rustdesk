import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/model.dart';
import 'package:flutter_hbb/widgets/dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import '../models/server_model.dart';
import 'home_page.dart';
import '../models/model.dart';

class ServerPage extends StatelessWidget implements PageShape {
  @override
  final title = translate("Share Screen");

  @override
  final icon = Icon(Icons.mobile_screen_share);

  @override
  final appBarActions = [
    PopupMenuButton<String>(
        icon: Icon(Icons.more_vert),
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              child: Text(translate("Change ID")),
              value: "changeID",
              enabled: false,
            ),
            PopupMenuItem(
              child: Text(translate("Set your own password")),
              value: "changePW",
              enabled: FFI.serverModel.isStart,
            ),
            PopupMenuItem(
              child: Text(translate("Refresh random password")),
              value: "refreshPW",
              enabled: FFI.serverModel.isStart,
            )
          ];
        },
        onSelected: (value) {
          if (value == "changeID") {
            // TODO
          } else if (value == "changePW") {
            updatePasswordDialog();
          } else if (value == "refreshPW") {
            () async {
              showLoading(translate("Waiting"));
              if (await FFI.serverModel.updatePassword("")) {
                showSuccess();
              } else {
                showError();
              }
              debugPrint("end updatePassword");
            }();
          }
        })
  ];

  @override
  Widget build(BuildContext context) {
    checkService();
    return ChangeNotifierProvider.value(
        value: FFI.serverModel,
        child: Consumer<ServerModel>(
            builder: (context, serverModel, child) => SingleChildScrollView(
                  controller: FFI.serverModel.controller,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ServerInfo(),
                        PermissionChecker(),
                        ConnectionManager(),
                        SizedBox.fromSize(size: Size(0, 15.0)),
                      ],
                    ),
                  ),
                )));
  }
}

void checkService() async {
  FFI.invokeMethod("check_service"); // jvm
  // for Android 10/11,MANAGE_EXTERNAL_STORAGE permission from a system setting page
  if (PermissionManager.isWaitingFile() && !FFI.serverModel.fileOk) {
    PermissionManager.complete("file", await PermissionManager.check("file"));
    debugPrint("file permission finished");
  }
}

class ServerInfo extends StatefulWidget {
  @override
  _ServerInfoState createState() => _ServerInfoState();
}

class _ServerInfoState extends State<ServerInfo> {
  final model = FFI.serverModel;
  var _passwdShow = false;

  @override
  Widget build(BuildContext context) {
    return model.isStart
        ? PaddingCard(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                readOnly: true,
                style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: MyTheme.accent),
                controller: model.serverId,
                decoration: InputDecoration(
                  icon: const Icon(Icons.perm_identity),
                  labelText: translate("ID"),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.bold, color: MyTheme.accent50),
                ),
                onSaved: (String? value) {},
              ),
              TextFormField(
                readOnly: true,
                obscureText: !_passwdShow,
                style: TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: MyTheme.accent),
                controller: model.serverPasswd,
                decoration: InputDecoration(
                    icon: const Icon(Icons.lock),
                    labelText: translate("Password"),
                    labelStyle: TextStyle(
                        fontWeight: FontWeight.bold, color: MyTheme.accent50),
                    suffix: IconButton(
                        icon: Icon(Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _passwdShow = !_passwdShow;
                          });
                        })),
                onSaved: (String? value) {},
              ),
            ],
          ))
        : PaddingCard(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                  child: Row(
                children: [
                  Icon(Icons.warning_amber_sharp,
                      color: Colors.redAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    translate("Service is not running"),
                    style: TextStyle(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: MyTheme.accent80,
                    ),
                  )
                ],
              )),
              SizedBox(height: 5),
              Center(
                  child: Text(
                translate("android_start_service_tip"),
                style: TextStyle(fontSize: 12, color: MyTheme.darkGray),
              ))
            ],
          ));
  }
}

class PermissionChecker extends StatefulWidget {
  @override
  _PermissionCheckerState createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<PermissionChecker> {
  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    final hasAudioPermission = androidVersion >= 30;
    final status;
    if (serverModel.connectStatus == -1) {
      status = 'not_ready_status';
    } else if (serverModel.connectStatus == 0) {
      status = 'connecting_status';
    } else {
      status = 'Ready';
    }
    return PaddingCard(
        title: translate("Permissions"),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PermissionRow(translate("Screen Capture"), serverModel.mediaOk,
                serverModel.toggleService),
            PermissionRow(translate("Input Control"), serverModel.inputOk,
                serverModel.toggleInput),
            PermissionRow(translate("File Transfer"), serverModel.fileOk,
                serverModel.toggleFile),
            hasAudioPermission
                ? PermissionRow(translate("Audio Capture"), serverModel.audioOk,
                    serverModel.toggleAudio)
                : Text(
                    "* ${translate("android_version_audio_tip")}",
                    style: TextStyle(color: MyTheme.darkGray),
                  ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                    flex: 0,
                    child: serverModel.mediaOk
                        ? ElevatedButton.icon(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red)),
                            icon: Icon(Icons.stop),
                            onPressed: serverModel.toggleService,
                            label: Text(translate("Stop service")))
                        : ElevatedButton.icon(
                            icon: Icon(Icons.play_arrow),
                            onPressed: serverModel.toggleService,
                            label: Text(translate("Start Service")))),
                Expanded(
                    child: serverModel.mediaOk
                        ? Row(
                            children: [
                              Expanded(
                                  flex: 0,
                                  child: Padding(
                                      padding:
                                          EdgeInsets.only(left: 20, right: 5),
                                      child: Icon(Icons.circle,
                                          color: serverModel.connectStatus > 0
                                              ? Colors.greenAccent
                                              : Colors.deepOrangeAccent,
                                          size: 10))),
                              Expanded(
                                  child: Text(translate(status),
                                      softWrap: true,
                                      style: TextStyle(
                                          fontSize: 14.0,
                                          color: MyTheme.accent50)))
                            ],
                          )
                        : SizedBox.shrink())
              ],
            ),
          ],
        ));
  }
}

class PermissionRow extends StatelessWidget {
  PermissionRow(this.name, this.isOk, this.onPressed);

  final String name;
  final bool isOk;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
                width: 140,
                child: Text(name,
                    style: TextStyle(fontSize: 16.0, color: MyTheme.accent50))),
            SizedBox(
              width: 50,
              child: Text(isOk ? translate("ON") : translate("OFF"),
                  style: TextStyle(
                      fontSize: 16.0,
                      color: isOk ? Colors.green : Colors.grey)),
            )
          ],
        ),
        TextButton(
            onPressed: onPressed,
            child: Text(
              translate(isOk ? "CLOSE" : "OPEN"),
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
        const Divider(height: 0)
      ],
    );
  }
}

class ConnectionManager extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final serverModel = Provider.of<ServerModel>(context);
    return Column(
        children: serverModel.clients.entries
            .map((entry) => PaddingCard(
                title: translate(entry.value.isFileTransfer
                    ? "File Connection"
                    : "Screen Connection"),
                titleIcon: entry.value.isFileTransfer
                    ? Icons.folder_outlined
                    : Icons.mobile_screen_share,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: clientInfo(entry.value)),
                        Expanded(
                            flex: -1,
                            child: entry.value.isFileTransfer ||
                                    !entry.value.authorized
                                ? SizedBox.shrink()
                                : IconButton(
                                    onPressed: () {
                                      FFI.chatModel
                                          .changeCurrentID(entry.value.id);
                                      final bar =
                                          navigationBarKey.currentWidget;
                                      if (bar != null) {
                                        bar as BottomNavigationBar;
                                        bar.onTap!(1);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.chat,
                                      color: MyTheme.accent80,
                                    )))
                      ],
                    ),
                    entry.value.authorized
                        ? SizedBox.shrink()
                        : Text(
                            translate("android_new_connection_tip"),
                            style: TextStyle(color: Colors.black54),
                          ),
                    entry.value.authorized
                        ? ElevatedButton.icon(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.red)),
                            icon: Icon(Icons.close),
                            onPressed: () {
                              FFI.setByName("close_conn", entry.key.toString());
                              FFI.invokeMethod(
                                  "cancel_notification", entry.key);
                            },
                            label: Text(translate("Close")))
                        : Row(children: [
                            TextButton(
                                child: Text(translate("Dismiss")),
                                onPressed: () {
                                  serverModel.sendLoginResponse(
                                      entry.value, false);
                                }),
                            SizedBox(width: 20),
                            ElevatedButton(
                                child: Text(translate("Accept")),
                                onPressed: () {
                                  serverModel.sendLoginResponse(
                                      entry.value, true);
                                }),
                          ]),
                  ],
                )))
            .toList());
  }
}

class PaddingCard extends StatelessWidget {
  PaddingCard({required this.child, this.title, this.titleIcon});

  final String? title;
  final IconData? titleIcon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final children = [child];
    if (title != null) {
      children.insert(
          0,
          Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  titleIcon != null
                      ? Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(titleIcon,
                              color: MyTheme.accent80, size: 30))
                      : SizedBox.shrink(),
                  Text(
                    title!,
                    style: TextStyle(
                      fontFamily: 'WorkSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: MyTheme.accent80,
                    ),
                  )
                ],
              )));
    }
    return Container(
        width: double.maxFinite,
        child: Card(
          margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ));
  }
}

Widget clientInfo(Client client) {
  return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
                flex: -1,
                child: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                        child: Text(client.name[0]),
                        backgroundColor: MyTheme.border))),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Text(client.name,
                      style: TextStyle(color: MyTheme.idColor, fontSize: 18)),
                  SizedBox(width: 8),
                  Text(client.peerId,
                      style: TextStyle(color: MyTheme.idColor, fontSize: 10))
                ]))
          ],
        ),
      ]));
}

void toAndroidChannelInit() {
  FFI.setMethodCallHandler((method, arguments) {
    debugPrint("flutter got android msg,$method,$arguments");
    try {
      switch (method) {
        case "start_capture":
          {
            SmartDialog.dismiss();
            FFI.serverModel.updateClientState();
            break;
          }
        case "on_state_changed":
          {
            var name = arguments["name"] as String;
            var value = arguments["value"] as String == "true";
            debugPrint("from jvm:on_state_changed,$name:$value");
            FFI.serverModel.changeStatue(name, value);
            break;
          }
        case "on_android_permission_result":
          {
            var type = arguments["type"] as String;
            var result = arguments["result"] as bool;
            PermissionManager.complete(type, result);
            break;
          }
        case "on_media_projection_canceled":
          {
            FFI.serverModel.stopService();
            break;
          }
      }
    } catch (e) {
      debugPrint("MethodCallHandler err:$e");
    }
    return "";
  });
}
