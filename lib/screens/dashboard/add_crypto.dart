// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:ui';
import 'package:moonwallet/main.dart';
import 'package:moonwallet/service/wallet_saver.dart';
import 'package:moonwallet/utils/colors.dart';
import 'package:moonwallet/utils/crypto.dart';
import 'package:moonwallet/utils/themes.dart';
import 'package:ulid/ulid.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:moonwallet/logger/logger.dart';
import 'package:moonwallet/service/crypto_storage_manager.dart';
import 'package:moonwallet/service/token_manager.dart';
import 'package:moonwallet/types/types.dart';
import 'package:moonwallet/utils/constant.dart';
import 'package:moonwallet/utils/prefs.dart';
import 'package:moonwallet/widgets/snackbar.dart';

class AddCryptoView extends StatefulWidget {
  const AddCryptoView({super.key});

  @override
  State<AddCryptoView> createState() => _AddCryptoViewState();
}

class _AddCryptoViewState extends State<AddCryptoView> {
  bool isDarkMode = true;
  Crypto? selectedNetwork;
  List<Crypto> reorganizedCrypto = [];
  SearchingContractInfo? searchingContractInfo;
  final cryptoStorageManager = CryptoStorageManager();
  final tokenManager = TokenManager();
  List<PublicData> accounts = [];
  final web3Manager = WalletSaver();
  final encryptService = EncryptService();

  bool hasSaved = false;
  PublicData? currentAccount;
  final nullAccount = PublicData(
      keyId: "",
      creationDate: 0,
      walletName: "",
      address: "",
      isWatchOnly: false);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _contractAddressController =
      TextEditingController();

  final publicDataManager = PublicDataManager();
  AppColors colors = AppColors(
      primaryColor: Color(0XFF0D0D0D),
      themeColor: Colors.greenAccent,
      greenColor: Colors.greenAccent,
      secondaryColor: Color(0XFF121212),
      grayColor: Color(0XFF353535),
      textColor: Colors.white,
      redColor: Colors.pinkAccent);
  bool saved = false;
  Themes themes = Themes();
  String savedThemeName = "";
  Future<void> getSavedTheme() async {
    try {
      final manager = ColorsManager();
      final savedName = await manager.getThemeName();
      setState(() {
        savedThemeName = savedName ?? "";
      });
      final savedTheme = await manager.getDefaultTheme();
      setState(() {
        colors = savedTheme;
      });
    } catch (e) {
      logError(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    getSavedTheme();
    getSavedWallets();
  }

  String generateUUID() {
    return Ulid().toUuid();
  }

  Future<void> getSavedWallets() async {
    try {
      final savedData = await web3Manager.getPublicData();

      final lastAccount = await encryptService.getLastConnectedAddress();

      int count = 0;
      if (savedData != null && lastAccount != null) {
        for (final account in savedData) {
          final newAccount = PublicData.fromJson(account);
          setState(() {
            accounts.add(newAccount);
          });
          count++;
        }
      }

      log("Retrieved $count wallets");

      for (final account in accounts) {
        if (account.address == lastAccount) {
          currentAccount = account;
          await reorganizeCrypto(account: account);

          log("The current wallet is ${json.encode(account.toJson())}");
          break;
        } else {
          log("Not account found");
          currentAccount = accounts[0];
        }
      }
    } catch (e) {
      logError('Error getting saved wallets: $e');
    }
  }

  Future<void> reorganizeCrypto({required PublicData account}) async {
    if (currentAccount == null) {
      logError("The current account is null");
      return;
    }
    List<Crypto> newCryptos = [];
    final savedCrypto =
        await cryptoStorageManager.getSavedCryptos(wallet: account);
    if (savedCrypto != null) {
      newCryptos.addAll(savedCrypto);
    }

    newCryptos.sort((a, b) => (a.name).compareTo(b.name));
    log("New cryptos ${newCryptos.length}");

    setState(() {
      reorganizedCrypto = newCryptos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: colors.primaryColor,
        appBar: AppBar(
          surfaceTintColor: colors.grayColor,
          backgroundColor: colors.primaryColor,
          actions: [
            Container(
              margin: const EdgeInsets.all(10),
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                  color: colors.grayColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5)),
              child: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: colors.primaryColor,
                      context: context,
                      builder: (ctx) {
                        return StatefulBuilder(builder: (bCtx, setModalState) {
                          return SizedBox(
                              height: MediaQuery.of(context).size.height * 0.95,
                              child: Scaffold(
                                backgroundColor: colors.primaryColor,
                                appBar: AppBar(
                                  actions: [
                                    IconButton(
                                        onPressed: () async {
                                          if (selectedNetwork == null) {
                                            showCustomSnackBar(
                                                primaryColor:
                                                    colors.primaryColor,
                                                context: context,
                                                message:
                                                    'Please select a network.',
                                                iconColor: Colors.pinkAccent);
                                          }
                                          if (_contractAddressController
                                              .text.isEmpty) {
                                            showCustomSnackBar(
                                                primaryColor:
                                                    colors.primaryColor,
                                                context: context,
                                                message:
                                                    'Please enter a contract address.',
                                                iconColor: Colors.pinkAccent);
                                          }
                                          final tokenFoundedData =
                                              await tokenManager.getCryptoInfo(
                                                  address:
                                                      _contractAddressController
                                                          .text
                                                          .trim(),
                                                  network: selectedNetwork ??
                                                      cryptos[0]);
                                          setState(() {
                                            searchingContractInfo =
                                                tokenFoundedData;
                                          });
                                          if (tokenFoundedData != null) {
                                            showDialog(
                                                context: context,
                                                builder: (btx) {
                                                  return BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 8, sigmaY: 8),
                                                    child: AlertDialog(
                                                      backgroundColor:
                                                          colors.primaryColor,
                                                      title: Text(
                                                        "Confirmation",
                                                        style:
                                                            GoogleFonts.roboto(
                                                                color: colors
                                                                    .textColor),
                                                      ),
                                                      content: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Row(
                                                              spacing: 10,
                                                              children: [
                                                                Text(
                                                                  "Name :",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.5)),
                                                                ),
                                                                Text(
                                                                  "${tokenFoundedData.name}",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.8),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Row(
                                                              spacing: 10,
                                                              children: [
                                                                Text(
                                                                  "Symbol :",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.5)),
                                                                ),
                                                                Text(
                                                                  "${tokenFoundedData.symbol}",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.8),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Row(
                                                              spacing: 10,
                                                              children: [
                                                                Text(
                                                                  "Decimals :",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.5)),
                                                                ),
                                                                Text(
                                                                  "${tokenFoundedData.decimals}",
                                                                  style: GoogleFonts.roboto(
                                                                      color: colors
                                                                          .textColor
                                                                          .withOpacity(
                                                                              0.8),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      colors
                                                                          .textColor),
                                                          child: Text(
                                                            "Add Token",
                                                            style: GoogleFonts
                                                                .roboto(
                                                                    color: colors
                                                                        .primaryColor),
                                                          ),
                                                          onPressed: () async {
                                                            final List<Crypto>?
                                                                cryptos =
                                                                await cryptoStorageManager
                                                                    .getSavedCryptos(
                                                                        wallet: currentAccount ??
                                                                            nullAccount);
                                                            if (cryptos !=
                                                                null) {
                                                              for (final crypto
                                                                  in cryptos) {
                                                                if (crypto.contractAddress !=
                                                                        null &&
                                                                    crypto.contractAddress
                                                                            ?.trim()
                                                                            .toLowerCase() ==
                                                                        _contractAddressController
                                                                            .text
                                                                            .trim()
                                                                            .toLowerCase()) {
                                                                  showCustomSnackBar(
                                                                      primaryColor:
                                                                          colors
                                                                              .primaryColor,
                                                                      context:
                                                                          context,
                                                                      message:
                                                                          'Token already added.',
                                                                      iconColor:
                                                                          Colors
                                                                              .orange);
                                                                  Navigator.pop(
                                                                      context);
                                                                  return;
                                                                }
                                                              }
                                                            }

                                                            final newCrypto = Crypto(
                                                                symbol: searchingContractInfo?.symbol ??
                                                                    "",
                                                                name: searchingContractInfo
                                                                        ?.name ??
                                                                    "Unknown ",
                                                                color: selectedNetwork
                                                                        ?.color ??
                                                                    Colors
                                                                        .white,
                                                                type:
                                                                    CryptoType
                                                                        .token,
                                                                valueUsd: 0,
                                                                cryptoId:
                                                                    generateUUID(),
                                                                canDisplay:
                                                                    true,
                                                                network:
                                                                    selectedNetwork,
                                                                decimals:
                                                                    searchingContractInfo
                                                                        ?.decimals
                                                                        .toInt(),
                                                                binanceSymbol:
                                                                    "${searchingContractInfo?.symbol}USDT",
                                                                contractAddress:
                                                                    _contractAddressController
                                                                        .text);
                                                            final saveResult =
                                                                await cryptoStorageManager.addCrypto(
                                                                    wallet: currentAccount ??
                                                                        nullAccount,
                                                                    crypto:
                                                                        newCrypto);
                                                            if (saveResult) {
                                                              hasSaved = true;
                                                              showCustomSnackBar(
                                                                  primaryColor:
                                                                      colors
                                                                          .primaryColor,
                                                                  context:
                                                                      context,
                                                                  icon: Icons
                                                                      .check,
                                                                  message:
                                                                      'Token added successfully.',
                                                                  iconColor:
                                                                      Colors
                                                                          .green);
                                                              Navigator.pop(
                                                                  context);
                                                            } else {
                                                              showCustomSnackBar(
                                                                primaryColor: colors
                                                                    .primaryColor,
                                                                context:
                                                                    context,
                                                                message:
                                                                    'Error adding token.',
                                                                iconColor:
                                                                    Colors.red,
                                                              );
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          },
                                                        ),
                                                        TextButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .pinkAccent),
                                                          child: Text(
                                                            "Cancel",
                                                            style: GoogleFonts
                                                                .roboto(
                                                                    color: colors
                                                                        .textColor),
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(btx);
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                });
                                          } else {
                                            showCustomSnackBar(
                                                primaryColor:
                                                    colors.primaryColor,
                                                context: context,
                                                message: 'Token not found.',
                                                iconColor: Colors.pinkAccent);
                                          }
                                        },
                                        icon: Icon(
                                          Icons.check,
                                          color:
                                              colors.textColor.withOpacity(0.5),
                                        ))
                                  ],
                                  backgroundColor: colors.primaryColor,
                                  leading: IconButton(
                                      onPressed: () {
                                        if (hasSaved) {
                                          Navigator.pushNamed(
                                              context, Routes.pageManager);
                                        } else {
                                          Navigator.pop(context);
                                        }
                                      },
                                      icon: Icon(
                                        LucideIcons.chevronLeft,
                                        color:
                                            colors.textColor.withOpacity(0.5),
                                      )),
                                ),
                                body: SingleChildScrollView(
                                  child: Column(
                                    spacing: 10,
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          showModalBottomSheet(
                                              backgroundColor:
                                                  colors.primaryColor,
                                              context: context,
                                              builder: (ctx) {
                                                return SingleChildScrollView(
                                                  child: Column(
                                                    children: reorganizedCrypto
                                                        .where((crypto) =>
                                                            crypto.type ==
                                                            CryptoType.network)
                                                        .toList()
                                                        .map((crypto) {
                                                      return ListTile(
                                                        leading: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(50),
                                                          child: Image.asset(
                                                            crypto.icon ?? "",
                                                            fit: BoxFit.cover,
                                                            width: 30,
                                                            height: 30,
                                                          ),
                                                        ),
                                                        title: Text(crypto.name,
                                                            style: GoogleFonts
                                                                .roboto(
                                                                    color: colors
                                                                        .textColor)),
                                                        onTap: () {
                                                          setModalState(() {
                                                            selectedNetwork =
                                                                crypto;
                                                          });
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        trailing: Icon(
                                                          LucideIcons
                                                              .chevronRight,
                                                          color:
                                                              colors.textColor,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                );
                                              });
                                        },
                                        title: Text(
                                          "${selectedNetwork != null ? selectedNetwork?.name : "Select an network"}",
                                          style: GoogleFonts.roboto(
                                              color: colors.textColor
                                                  .withOpacity(0.5)),
                                        ),
                                        trailing: Icon(
                                          LucideIcons.chevronRight,
                                          color: colors.textColor,
                                        ),
                                      ),
                                      SizedBox(
                                        width: width * 0.92,
                                        child: TextField(
                                          style: GoogleFonts.roboto(
                                              color: colors.textColor),
                                          cursorColor: colors.themeColor,
                                          controller:
                                              _contractAddressController,
                                          decoration: InputDecoration(
                                              hintText: "Contract address",
                                              hintStyle: GoogleFonts.robotoFlex(
                                                  color: colors.textColor
                                                      .withOpacity(0.4)),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 8),
                                              prefixIcon: Icon(
                                                LucideIcons.scrollText,
                                                color: colors.textColor
                                                    .withOpacity(0.3),
                                              ),
                                              filled: true,
                                              fillColor: colors.grayColor
                                                  .withOpacity(0.1),
                                              enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                      width: 0,
                                                      color:
                                                          Colors.transparent)),
                                              focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                      width: 0,
                                                      color:
                                                          Colors.transparent))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ));
                        });
                      });
                },
                icon: Icon(
                  LucideIcons.plus,
                  color: colors.textColor,
                  size: 20,
                ),
              ),
            ),
          ],
          leading: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, Routes.pageManager);
              },
              icon: Icon(
                LucideIcons.chevronLeft,
                color: colors.textColor,
              )),
          title: Text(
            "Manage Coins ",
            style: GoogleFonts.robotoFlex(color: colors.textColor),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            spacing: 15,
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: width * 0.92,
                  child: TextField(
                    onChanged: (v) {
                      setState(() {
                        _searchController.text = v;
                      });
                    },
                    style: GoogleFonts.roboto(color: colors.textColor),
                    cursorColor: colors.themeColor,
                    controller: _searchController,
                    decoration: InputDecoration(
                        hintText: "Search Crypto",
                        hintStyle: GoogleFonts.robotoFlex(
                            color: colors.textColor.withOpacity(0.4)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colors.textColor.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: colors.grayColor.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                width: 0, color: Colors.transparent))),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: List.generate(
                      reorganizedCrypto
                          .where((c) => c.symbol
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase()))
                          .length, (i) {
                    final crypto = reorganizedCrypto
                        .where((c) => c.symbol
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase()))
                        .toList()[i];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 20),
                        onTap: () {},
                        leading: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: crypto.icon == null
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                          color:
                                              colors.textColor.withOpacity(0.6),
                                          borderRadius:
                                              BorderRadius.circular(50)),
                                      child: Center(
                                        child: Text(
                                          crypto.symbol.length > 2
                                              ? crypto.symbol.substring(0, 2)
                                              : crypto.symbol,
                                          style: GoogleFonts.roboto(
                                              color: colors.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                    )
                                  : Image.asset(
                                      crypto.icon ?? "",
                                      width: 40,
                                      height: 40,
                                    ),
                            ),
                            if (crypto.type == CryptoType.token)
                              Positioned(
                                  top: 25,
                                  left: 25,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.asset(
                                      crypto.network?.icon ?? "",
                                      width: 15,
                                      height: 15,
                                    ),
                                  ))
                          ],
                        ),
                        title: Text(
                          crypto.symbol,
                          style: GoogleFonts.roboto(
                              color: colors.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: Switch(
                            value: crypto.canDisplay,
                            onChanged: (newVal) async {
                              final result =
                                  await cryptoStorageManager.toggleCanDisplay(
                                      wallet: currentAccount ?? nullAccount,
                                      cryptoId: crypto.cryptoId,
                                      value: newVal);
                              if (result) {
                                log("State changed successfully");
                                await reorganizeCrypto(
                                    account: currentAccount ?? nullAccount);
                              } else {
                                log("Error changing state");
                              }
                            }),
                      ),
                    );
                  }),
                ),
              )
            ],
          ),
        ));
  }
}
