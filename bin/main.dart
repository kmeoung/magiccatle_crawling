import 'package:web_scraper/web_scraper.dart';
import 'dart:io';
import 'package:http/http.dart' show get;

void main() {
  getProduct(819);
  // getMainPage();
}

enum PRODUCT_IMG_TYPE { MAIN, BANNER }

getMainPage() async {
  const mainUrl = 'https://magiccastle.co.kr/';
  final webScraper = WebScraper(mainUrl);
  if (await webScraper.loadWebPage('')) {
    print(webScraper.getAllScripts());
  }
}

/**
 * 이미지 다운로드 코드
 */
_downloadImg(
    {required String img_url,
    required String productName,
    required PRODUCT_IMG_TYPE productImgType}) async {
  //comment out the next two lines to prevent the device from getting
  // the image from the web in order to prove that the picture is
  // coming from the device instead of the web.
  var url = Uri.parse(img_url); // <-- 1
  var response = await get(url); // <--2
  // var documentDirectory = await getApplicationDocumentsDirectory();
  var directoryPath = 'img';
  var firstPath = '$directoryPath/$productName';
  var filePathAndName =
      '$directoryPath/$productName/${productName}_${productImgType == PRODUCT_IMG_TYPE.MAIN ? 'main' : 'banner'}.jpg';
  //comment out the next three lines to prevent the image from being saved
  //to the device to show that it's coming from the internet
  await Directory(firstPath).create(recursive: true); // <-- 1
  File file2 = new File(filePathAndName); // <-- 2
  file2.writeAsBytesSync(response.bodyBytes); // <-- 3
}

void getProduct(int productId) async {
  final webScraper = WebScraper('https://magiccastle.co.kr');
  if (await webScraper.loadWebPage('/product/1/$productId/')) {
    // 메인 정보 가져오기
    List<Map<String, dynamic>> infoTitle = webScraper.getElement(
      'div.infoArea > div.info_wrap > div > div.d_info > ul > li > span.info_title',
      [],
    );

    // 메인 이미지 가져오기
    List<Map<String, dynamic>> infoCont = webScraper.getElement(
      'div.infoArea > div.info_wrap > div > div.d_info > ul > li > span.info_cont',
      [],
    );

    List<Map<String, String>> mInfo = [];
    String product_name = '';
    for (int i = 0; i < infoCont.length; i++) {
      String mInfoTitle = infoTitle[i]['title'] is String
          ? infoTitle[i]['title'] == '적립금' || infoTitle[i]['title'] == '수량'
              ? ''
              : infoTitle[i]['title']
          : '';
      String mInfoCont =
          infoCont[i]['title'] is String ? infoCont[i]['title'] : '';

      if (mInfoTitle.isNotEmpty) {
        mInfo.add({mInfoTitle: mInfoCont});

        print('$mInfoTitle : $mInfoCont');

        if (mInfoTitle == '상품명') product_name = mInfoCont;
      }
    }
    // 메인 이미지
    List<Map<String, dynamic>> mainImg = webScraper
        .getElement('div.prdImgView > p.prdImg > a > img', ['id', 'src']);

    print('메인이미지 URL : https:' + mainImg.single['attributes']['src']);

    _downloadImg(
        img_url: 'https:' + mainImg.single['attributes']['src'],
        productName: product_name,
        productImgType: PRODUCT_IMG_TYPE.MAIN);

    // 배너 이미지
    List<Map<String, dynamic>> bannerImg = webScraper
        .getElement('div#tab-responsive-1 > div.cont > p > img', ['id', 'src']);

    print('배너이미지 URL : https://magiccastle.co.kr' +
        bannerImg[0]['attributes']['src']);

    _downloadImg(
        img_url:
            'https://magiccastle.co.kr' + bannerImg[0]['attributes']['src'],
        productName: product_name,
        productImgType: PRODUCT_IMG_TYPE.BANNER);

    List<Map<String, dynamic>> table = webScraper
        .getElement('div#tab-responsive-1 > div.cont > table > tbody > tr', []);
    for (var map in table) {
      print(map['title']);
    }
  }
}
