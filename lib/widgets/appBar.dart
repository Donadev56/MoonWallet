// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/service/vibration.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/widgets/func/show_accounts_list.dart';
import 'package:moonwallet/widgets/func/show_custom_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

typedef EditWalletNameType = void Function(String newName, int index);
typedef ActionWithIndexType = void Function(int index);
typedef ActionWithCryptoId = Future<bool> Function(
    String cryptoId, BuildContext? context);

typedef ReorderList = Future<void> Function(int oldIndex, int newIndex);
typedef SearchWallet = void Function(String query);

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color primaryColor;
  final Color textColor;
  final Color surfaceTintColor;
  final PublicData currentAccount;
  final List<PublicData> accounts;
  final List<Crypto> availableCryptos;
  final EditWalletNameType editWalletName;
  final double totalBalanceUsd;
  final Future<void> Function(
      {Color? color, required int index, IconData? icon}) editVisualData;
  final ActionWithCryptoId deleteWallet;
  final ActionWithIndexType changeAccount;
  final ActionWithIndexType showPrivateData;
  final ReorderList reorderList;
  final Color secondaryColor;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final File? profileImage;
  final double balanceOfAllAccounts;
  final bool isHidden;
  final AppColors colors;
  final bool isTotalBalanceUpdated;
  final Future<void> Function(bool state) updateBioState;

  final Future<void> Function(File image) refreshProfile;
  final bool canUseBio;
  final Future<bool> Function(
      {required PublicData account,
      String? name,
      IconData? icon,
      Color? color}) editWallet;

  const CustomAppBar(
      {super.key,
      required this.canUseBio,
      required this.totalBalanceUsd,
      required this.primaryColor,
      required this.textColor,
      required this.surfaceTintColor,
      required this.currentAccount,
      required this.accounts,
      required this.editWalletName,
      required this.deleteWallet,
      required this.changeAccount,
      required this.secondaryColor,
      required this.reorderList,
      required this.showPrivateData,
      required this.scaffoldKey,
      required this.balanceOfAllAccounts,
      required this.isHidden,
      required this.colors,
      required this.editVisualData,
      required this.isTotalBalanceUpdated,
      required this.availableCryptos,
      required this.profileImage,
      required this.editWallet,
      required this.refreshProfile ,
      required this.updateBioState});

  @override
  Widget build(BuildContext context) {
    // ignore: no_leading_underscores_for_local_identifiers

    return AppBar(
      backgroundColor: primaryColor,
      surfaceTintColor: primaryColor,
      leading: IconButton(
          onPressed: () {
            showCustomDrawer(
              updateBioState: updateBioState,
                canUseBio: canUseBio,
                deleteWallet: (acc) async {
                  deleteWallet(acc.keyId, null);
                },
                refreshProfile: refreshProfile,
                editWallet: editWallet,
                totalBalanceUsd: totalBalanceUsd,
                context: context,
                profileImage: profileImage,
                colors: colors,
                account: currentAccount,
                availableCryptos: availableCryptos);
          },
          icon: profileImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.file(
                    profileImage!,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(
                  Icons.person,
                  color: textColor,
                )),
      title: Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await vibrate(duration: 10);
              showAccountList(
                  colors: colors,
                  context: context,
                  accounts: accounts,
                  currentAccount: currentAccount,
                  editWalletName: editWalletName,
                  deleteWallet: (id) async {
                    final res = await deleteWallet(id, context);
                    return res;
                  },
                  changeAccount: changeAccount,
                  showPrivateData: showPrivateData,
                  reorderList: reorderList,
                  editVisualData: editVisualData);
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentAccount.walletName,
                    style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Icon(
                    FeatherIcons.chevronDown,
                    color: textColor,
                  )
                ],
              ),
            )),
      ),
      actions: <Widget>[
        IconButton(
            onPressed: () {
              launchUrl(Uri.parse(
                  "https://x.com/eternalprotcl?t=m1cADuEKb9tTlngYCrlB3Q&s=09"));
            },
            icon: Icon(
              LucideIcons.twitter,
              color: textColor,
            )),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomPopupMenuItem<T> extends PopupMenuEntry<T> {
  final T value;
  final Widget child;
  final double height;
  final VoidCallback onTap;

  const CustomPopupMenuItem({
    required this.value,
    required this.child,
    this.height = kMinInteractiveDimension,
    required this.onTap,
  });

  @override
  bool represents(T? value) => this.value == value;

  @override
  CustomPopupMenuItemState<T> createState() => CustomPopupMenuItemState<T>();
}

class CustomPopupMenuItemState<T> extends State<CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.centerLeft,
      child: PopupMenuItem(
        child: widget.child,
        onTap: widget.onTap,
      ),
    );
  }
}
