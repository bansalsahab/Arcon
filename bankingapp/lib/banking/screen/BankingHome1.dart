import 'package:bankingapp/banking/model/BankingModel.dart';
import 'package:bankingapp/banking/utils/BankingColors.dart';
import 'package:bankingapp/banking/utils/BankingContants.dart';
import 'package:bankingapp/banking/utils/BankingDataGenerator.dart';
import 'package:bankingapp/banking/utils/BankingImages.dart';
import 'package:bankingapp/banking/utils/BankingWidget.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:bankingapp/services/api.dart';
import 'package:intl/intl.dart';

class BankingHome1 extends StatefulWidget {
  static String tag = '/BankingHome1';

  @override
  BankingHome1State createState() => BankingHome1State();
}

class BankingHome1State extends State<BankingHome1> {
  int currentIndexPage = 0;
  int? pageLength;

  late List<BankingHomeModel> mList1;
  late List<BankingHomeModel2> mList2;

  final NumberFormat _fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  bool _loading = false;
  int _pendingPaise = 0;
  int _investedPaise = 0;
  List<dynamic> _txs = [];

  @override
  void initState() {
    super.initState();
    currentIndexPage = 0;
    pageLength = 3;
    mList1 = bankingHomeList1();
    mList2 = bankingHomeList2();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final port = await ApiClient.portfolio();
      final pending = await ApiClient.pendingRoundups();
      final txs = await ApiClient.transactions(limit: 10, offset: 0);
      setState(() {
        _pendingPaise = (pending['total_paise'] as num?)?.toInt() ?? 0;
        _investedPaise = (port['invested_total_paise'] as num?)?.toInt() ?? 0;
        _txs = txs;
      });
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 330,
              floating: false,
              pinned: true,
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              backgroundColor: innerBoxIsScrolled ? Banking_Primary : Banking_app_Background,
              actionsIconTheme: IconThemeData(opacity: 0.0),
              title: Container(
                padding: EdgeInsets.fromLTRB(16, 42, 16, 32),
                margin: EdgeInsets.only(bottom: 8, top: 8),
                child: Row(
                  children: [
                    CircleAvatar(backgroundImage: AssetImage(Banking_ic_user1), radius: 24),
                    10.width,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Hello,Laura", style: primaryTextStyle(color: Banking_TextColorWhite, size: 16, fontFamily: fontRegular)),
                        Text("How are you today?", style: primaryTextStyle(color: Banking_TextColorWhite, size: 16, fontFamily: fontRegular)),
                      ],
                    ).expand(),
                    Icon(Icons.notifications, size: 30, color: Banking_whitePureColor)
                  ],
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomLeft, end: Alignment.topLeft, colors: <Color>[Banking_Primary, Banking_palColor]),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 80, 16, 8),
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 0),
                      decoration: boxDecorationWithRoundedCorners(borderRadius: BorderRadius.circular(10), boxShadow: defaultBoxShadow()),
                      child: Column(
                        children: [
                          Container(
                            height: 130,
                            child: PageView(
                              children: [
                                TopCard(
                                  name: "Roundup Portfolio",
                                  acno: "User",
                                  bal: _fmt.format((_pendingPaise + _investedPaise) / 100.0),
                                ),
                              ],
                              onPageChanged: (value) {
                                setState(() => currentIndexPage = value);
                              },
                            ),
                          ),
                          8.height,
                          Align(
                            alignment: Alignment.center,
                            child: DotsIndicator(
                              dotsCount: 3,
                              position: currentIndexPage.toDouble(),
                              decorator: DotsDecorator(
                                size: Size.square(8.0),
                                activeSize: Size.square(8.0),
                                color: Banking_view_color,
                                activeColor: Banking_TextColorPrimary,
                              ),
                            ),
                          ),
                          10.height,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(top: 8, bottom: 8),
                                decoration: boxDecorationWithRoundedCorners(backgroundColor: Banking_Primary, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_shopping_cart, color: Banking_TextColorWhite, size: 24),
                                    10.width,
                                    Text('Add Tx ₹247.00', style: primaryTextStyle(size: 16, color: Banking_TextColorWhite)),
                                  ],
                                ),
                              ).onTap(() async {
                                try {
                                  await ApiClient.createTransaction(247.00, merchant: 'Shop');
                                  toast('Transaction added');
                                  _load();
                                } catch (e) {
                                  toast(e.toString());
                                }
                              }).expand(),
                              10.width,
                              Container(
                                padding: EdgeInsets.only(top: 8, bottom: 8),
                                decoration: boxDecorationWithRoundedCorners(backgroundColor: Banking_Primary, borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(Banking_ic_Transfer, color: Banking_TextColorWhite),
                                    10.width,
                                    Text('Execute Sweep', style: primaryTextStyle(size: 16, color: Banking_TextColorWhite)),
                                  ],
                                ),
                              ).onTap(() async {
                                try {
                                  final r = await ApiClient.executeSweep();
                                  toast('Sweep: ${r['status'] ?? 'done'}');
                                  _load();
                                } catch (e) { toast(e.toString()); }
                              }).expand(),
                            ],
                          ).paddingAll(16)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ];
        },
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16),
            color: Banking_app_Background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Transactions", style: primaryTextStyle(size: 16, color: Banking_TextColorPrimary, fontFamily: fontRegular)),
                    if (_loading) SizedBox(width:16, height:16, child:CircularProgressIndicator(strokeWidth:2)),
                  ],
                ),
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _txs.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final t = _txs[index] as Map<String, dynamic>;
                    final amtPaise = (t['amount_paise'] as num?)?.toInt() ?? 0;
                    final merch = (t['merchant'] as String?) ?? 'Txn ${t['id']}';
                    return Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(top: 8, bottom: 8),
                      decoration: boxDecorationRoundedWithShadow(8, backgroundColor: Banking_whitePureColor, spreadRadius: 0, blurRadius: 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet, size: 30, color: Banking_Primary),
                          10.width,
                          Text(merch, style: primaryTextStyle(size: 16, color: Banking_TextColorPrimary, fontFamily: fontMedium)).expand(),
                          Text(_fmt.format(amtPaise/100.0), style: primaryTextStyle(color: Banking_Primary, size: 16)),
                        ],
                      ),
                    );
                  },
                ),
                16.height,
                Text("22 Feb 2020", style: primaryTextStyle(size: 16, color: Banking_TextColorSecondary, fontFamily: fontRegular)),
                Divider(),
                ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: 15,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    BankingHomeModel2 data = mList2[index % mList2.length];
                    return Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(top: 8, bottom: 8),
                      decoration: boxDecorationRoundedWithShadow(8, backgroundColor: Banking_whitePureColor, spreadRadius: 0, blurRadius: 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(data.icon!, height: 30, width: 30, color: index == 2 ? Banking_Primary : Banking_Primary),
                          10.width,
                          Text(data.title!, style: primaryTextStyle(size: 16, color: Banking_TextColorPrimary, fontFamily: fontRegular)).expand(),
                          Align(alignment: Alignment.centerRight, child: Text(data.charge!, style: primaryTextStyle(color: data.color, size: 16)))
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
