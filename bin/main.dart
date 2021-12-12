import 'package:web_scraper/web_scraper.dart';
import 'dart:io';
import 'package:http/http.dart' show get;
import 'package:csv/csv.dart';

void main() {
  getProduct(productId: 1944);
  // getMainPage();
  // for (String key in _brands.keys) {
  //   getBrandPage(brand: key, brandCode: _brands[key]!);
  // }
  // getBrandPage(brand: '건드', brandCode: 93);
}

enum PRODUCT_IMG_TYPE { MAIN, BANNER }

const Map<String, int> _brands = {
  '매직캐슬': 155,
  '건드': 93,
  '마담알렉산더': 122,
  '맨하탄-토이': 129,
  '뮤키킴': 130,
  '보니카': 145,
  '로렌스': 123,
  '에릭칼': 125,
  '월드넘버원-부': 116,
  '포크마니스': 96,
  '푸쉰': 117,
  '키두지': 108,
  '키즈-프리퍼드': 92
};

getMainPage() async {
  const mainUrl = 'https://magiccastle.co.kr/';
  final webScraper = WebScraper(mainUrl);
  if (await webScraper.loadWebPage('product/list.html?cate_no=155&page=1')) {
    print(webScraper.getAllScripts());
  }
}

getPopularProducts() async {}

getBrandPage({String brand = '', required int brandCode}) async {
  const mainUrl = 'https://magiccastle.co.kr/';
  final webScraper = WebScraper(mainUrl);
  int pageNo = 1;
  while (await webScraper
      .loadWebPage('product/list.html?cate_no=$brandCode&page=$pageNo')) {
    // 메인 정보 가져오기
    List<Map<String, dynamic>> products = webScraper.getElement(
      'div.mt-3 > div.xans-product > div.ec-base-product > div.row > div',
      ['id'],
    );
    // 상품이 없을 경우 종료
    if (products.length == 0) break;

    for (var product in products) {
      String allId = product['attributes']['id'];
      String id = allId.split('_')[1];
      getProduct(brandName: brand, productId: int.parse(id));
    }
    pageNo++;
  }
}

/**
 * 상품 정보 가져오기
 */
void getProduct({String brandName = '', required int productId}) async {
  final webScraper = WebScraper('https://magiccastle.co.kr');
  if (await webScraper.loadWebPage('/product/1/$productId/')) {
    List<List<dynamic>> _infoData = [];

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

    _infoData.add(mInfo);

    // 메인 이미지
    List<Map<String, dynamic>> mainImg = webScraper
        .getElement('div.prdImgView > p.prdImg > a > img', ['id', 'src']);

    print('메인이미지 URL : https:' + mainImg.single['attributes']['src']);

    // 배너 이미지
    List<Map<String, dynamic>> bannerImg = webScraper
        .getElement('div#tab-responsive-1 > div.cont > p > img', ['id', 'src']);

    String bannerImgUrl = 'https://magiccastle.co.kr';

    if (bannerImg.length < 1) {
      List<Map<String, dynamic>> anotherBannerImg = webScraper.getElement(
          'div#tab-responsive-1 > div.cont > div > img', ['id', 'src']);
      bannerImgUrl = bannerImgUrl + anotherBannerImg[0]['attributes']['src'];
    } else {
      bannerImgUrl = bannerImgUrl + bannerImg[0]['attributes']['src'];
    }

    print(bannerImgUrl);

    List<String> mInfoDetail = [];

    List<Map<String, dynamic>> table = webScraper
        .getElement('div#tab-responsive-1 > div.cont > table > tbody > tr', []);
    for (var map in table) {
      String title = map['title'];
      mInfoDetail.add(title);
    }
    _infoData.add(mInfoDetail);

    _downloadImg(
        img_url: 'https:' + mainImg.single['attributes']['src'],
        brandName: brandName,
        productName: product_name,
        productImgType: PRODUCT_IMG_TYPE.MAIN);

    _downloadImg(
        img_url: bannerImgUrl,
        brandName: brandName,
        productName: product_name,
        productImgType: PRODUCT_IMG_TYPE.BANNER);

    writeInfoFile(
        datas: _infoData, productName: product_name, brandName: brandName);
  }
}

writeInfoFile(
    {String brandName = "",
    required String productName,
    required List<List<dynamic>> datas}) async {
  if (productName.contains('/')) productName = productName.replaceAll('/', '_');
  productName = productName.trim();
  productName = productName.replaceAll(RegExp(r"\s+"), '_');

  var directoryPath = 'data';
  var firstPath =
      '$directoryPath/' + '${brandName.isNotEmpty ? '$brandName' : ''}';
  var secondPath = firstPath + '/$productName';

  var filePathAndName = '$secondPath/$productName.csv';

  await Directory(firstPath).create(recursive: true); // <-- 1
  await Directory(secondPath).create(recursive: true); // <--

  String csv = const ListToCsvConverter().convert(datas);

  File file2 = new File(filePathAndName); // <-- 2
  await file2.writeAsString(csv); // <-- 3
}

/***
 ** 이미지 다운로드 코드
 **/
_downloadImg(
    {required String img_url,
    String brandName = "",
    required String productName,
    required PRODUCT_IMG_TYPE productImgType}) async {
  if (productName.contains('/')) productName = productName.replaceAll('/', '_');
  productName = productName.trim();
  productName = productName.replaceAll(RegExp(r"\s+"), '_');

  var url = Uri.parse(img_url); // <-- 1
  var response = await get(url); // <--2

  var directoryPath = 'data';
  var firstPath =
      '$directoryPath/' + '${brandName.isNotEmpty ? '$brandName' : ''}';
  var secondPath = firstPath + '/$productName';

  var filePathAndName =
      '$secondPath/${productName}_${productImgType == PRODUCT_IMG_TYPE.MAIN ? 'main' : 'banner'}.jpg';

  await Directory(firstPath).create(recursive: true); // <-- 1
  await Directory(secondPath).create(recursive: true); // <--

  File file2 = new File(filePathAndName); // <-- 2
  await file2.writeAsBytes(response.bodyBytes); // <-- 3
}
