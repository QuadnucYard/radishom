#import "../src/lib.typ": *

#set page(width: auto, height: auto)

#set text(font: "Microsoft YaHei")

#let lines = (
  line(
    number: "1",
    color: rgb("#009ace"),
    pin(x: 5., y: 11.),
    station([八卦洲大桥南], [BAGUAZHOUDAQIAONAN]),
    station([笆斗山], [BADOUSHAN], x: 3.),
    pin(x: 2., d: dirs.west),
    station([燕子矶], [YANZIJI], y: 10.),
    station([吉祥庵], [JIXIANG'AN]),
    station([晓庄], [XIAOZHUANG], anchor: "south-west"),
    station([迈皋桥], [MAIGAOQIAO], y: 7.),
    pin(y: 6.5, d: dirs.south),
    station([红山动物园], [HONGSHAN ZOO], y: 6.25),
    station([南京站], [NANJING RAILWAY STATION], anchor: "east", pin: "南京"),
    pin(x: 0., d: dirs.south-west),
    station([新模范马路], [XINMOFANMALU], y: 4),
    station([玄武门], [XUANWUMEN]),
    station([鼓楼], [GULOU], anchor: "south-west"),
    station([珠江路], [ZHUJIANGLU]),
    station([新街口], [XINJIEKOU], anchor: "south-west"),
    station([张府园], [ZHANGFUYUAN]),
    station([三山街], [SANSHANJIE], anchor: "south-west", y: -2.),
    pin(y: -3.5, d: dirs.south),
    station([中华门], [ZHONGHUAMEN], y: -4.),
    station([安德门], [ANDEMEN]),
    pin(x: -2., d: dirs.south-west),
    station([天隆寺], [TIANLONGSI], y: -6.5),
    pin(y: -7., d: dirs.south),
    station([软件大道], [RUANJIANDADAO], x: -1.),
    station([花神庙], [HUASHENMIAO], x: 0.),
    pin(x: 1. + 0.1, d: dirs.east),
    station([南京南站], [NANJING SOUTH RAILWAY STATION], y: -8.),
    pin(y: -8.5, d: dirs.south),
    pin(x: 2., d: dirs.east),
    station([双龙大道], [SHUANGLONGDADAO], y: -9.),
    station([河定桥], [HEDINGQIAO]),
    station([胜太路], [SHENGTAILU], y: -11.),
    station([百家湖], [BAIJIAHU], y: -12.5),
    pin(y: -13., d: dirs.south),
    station([小龙湾], [XIAOLONGWAN]),
    station([竹山路], [ZHUSHANLU], anchor: "north-west"),
    station([天印大道], [TIANYINDADAO]),
    station([龙眠大道], [LONGMIANDADAO], x: 7.),
    pin(x: 7.5, d: dirs.east),
    station([南医大·江苏经贸学院], [NMU/JIETT]),
    station([南京交院], [NJCI]),
    station([中国药科大学], [CPU]),
    pin(y: -15., d: dirs.south-east),
  ),
  line(
    number: "2",
    color: rgb("#a6093d"),
    pin(x: -11., y: -8.5),
    station([鱼嘴], [YUZUI]),
    station([天保街], [TIAOBAOJIE]),
    station([青莲街], [QINGLIANJIE], anchor: "north"),
    station([螺塘路], [LUOTANGLU], anchor: "north-west"),
    pin(x: -7.5, d: dirs.east),
    station([油坊桥], [YOUFANGQIAO], anchor: "west"),
    pin(x: -5.75, y: -6.75, d: dirs.north-east),
    station([雨润大街], [YUANTONG], y: -6., anchor: "north-east"),
    pin(x: -7., y: -5.5, d: dirs.north-west),
    station([元通], [YUANTONG], anchor: "west"),
    station([奥体东], [OLYMPIC STADIUM EAST]),
    station([兴隆大街], [XINGLONGDAJIE], r: 1.0),
    pin(x: -4.5, y: -3, d: dirs.north-east),
    station([集庆门大街], [XINGLONGDAJIE], y: -2),
    pin(y: -1, d: dirs.north),
    station([云锦路], [YUNJINLU]),
    pin(x: -3.5, d: dirs.east),
    station([莫愁湖], [MOCHOUHU], x: -3.),
    pin(y: 0., d: dirs.north-east),
    station([汉中门], [HANZHONGMEN], x: -2.),
    station([上海路], [SHANGHAILU], anchor: "south-west"),
    station([新街口], [XINJIEKOU]),
    station([大行宫], [DAXINGGONG], anchor: "north-west"),
    station([西安门], [XI'ANMEN], x: 2.),
    station([明故宫], [MINGGUGONG], anchor: "south-west"),
    station([苜蓿园], [MUXUYUAN], x: 5.),
    station([下马坊], [XIAMAFANG]),
    station([孝陵卫], [XIAOLINGWEI], x: 7.),
    station([钟灵街], [ZHONGLINGJIE], x: 8.),
    pin(x: 8.5, d: dirs.east),
    station([马群], [MAQUN], x: 9.5),
    pin(y: 1.5, d: dirs.north-east),
    station([金马路], [JINMALU], anchor: "east", y: 3.),
    pin(y: 4., d: dirs.north),
    station([仙鹤门], [XIANHEMEN], x: 10.25),
    station([学则路], [XUEZELU]),
    station([仙林中心], [XIANLINZHONGXIN]),
    station([羊山公园], [YANGSHANGONGYUAN], x: 13.),
    pin(x: 13.5, d: dirs.north-east),
    station([南大仙林校区], [NJU Xianlin Campus], x: 14.),
    station([经天路], [JINGTIANLU]),
    pin(x: 16., d: dirs.east),
    // pin(x: 17.4, d: dirs.east),
    // station([仙林湖], [XIANLINHU]),
    // pin(y: 8., d: dirs.north),
  ),
  line(
    number: "3",
    color: rgb("#009a44"),
    pin(x: -11, y: 12.),
    station([林场], [LINCHANG]),
    station([星火路], [XINGHUOLU], x: -9.5),
    station([东大成贤学院], [SEU CHENGXIAN COLLEGE], anchor: "north"),
    station([泰冯路], [TAIFENGLU], anchor: "south-west"),
    station([天润城], [TIANRUNCHENG], x: -6.),
    pin(x: -5.5, y: 12., d: dirs.east),
    station([柳洲东路], [LIUZHOUDONGLU]),
    station([上元门], [SHANGYUANMEN], x: -2.25),
    station([五塘广场], [WUTANGGUANGCHANG], anchor: "east"),
    station([小市], [XIAOSHI]),
    station([南京站], [NANJING RAILWAY STATION]),
    pin(y: 4.5, d: dirs.south-east),
    station([南京林业大学·新庄], [XINZHUANG], y: 4.),
    pin(y: 3.5, d: dirs.south),
    pin(x: 1., d: dirs.south-west),
    station([鸡鸣寺], [JIMINGSI], y: 2., anchor: "north-west"),
    station([浮桥], [FUQIAO]),
    station([大行宫], [DAXINGGONG]),
    station([常府街], [CHANGFUJIE]),
    station([夫子庙], [FUZIMIAO], y: -2., anchor: "south-west"),
    pin(y: -2.25, d: dirs.south),
    pin(x: 1.5, d: dirs.south-east),
    station([武定门], [WUDINGMEN], y: -3.),
    pin(y: -4, d: dirs.south),
    station([雨花门], [YUHUAMMEN], y: -4.),
    pin(x: 2., d: dirs.south-east),
    // pin(x: 1.5, d: dirs.south),
    station([卡子门], [KAZIMEN], anchor: "south-west"),
    station([大明路], [DAMINGLU], anchor: "east"),
    pin(y: -7.5, d: dirs.south),
    station([明发广场], [MINGFAGUANGCHANG]),
    pin(x: 1., d: dirs.east),
    station([南京南站], [NANJING SOUTH RAILWAY STATION]),
    station([宏运大道], [HONGYUNDADAO], y: -9.),
    station([胜太西路], [SHENGTAIXILU], y: -11.),
    station([天元西路], [TIANYUANXILU], y: -13.),
    pin(y: -14., d: dirs.south),
    station([九龙湖], [JIULONGHU]),
    pin(x: 3., d: dirs.east),
    station([诚信大道], [CHENGXINDADAO], y: -15., anchor: "south-east"),
    station([东大九龙湖校区], [SEU JIULONGHU CAMPUS]),
    station([秣周东路], [MOZHOUDONGLU]),
    station([上秦淮西], [SHANGQINHUAIXI]),
    station([秣陵], [MOLING]),
    pin(y: -19., d: dirs.south),
  ),
  line(
    number: "4",
    color: rgb("#7d55c7"),
    pin(x: -10.5, y: 8.),
    station([珍珠泉东], [ZHENZHUQUANDONG]),
    station([瑞龙郊野公园], [RUILONGJIAOYEGONGYUAN]),
    pin(x: -11.5, y: 7.),
    station([石佛寺], [SHIFOSI], y: 6.75),
    station([定山大街], [DINGSHANDAJIE]),
    station([江北商务区], [JIANGBEISHANGWUQU]),
    station([江北市民中心], [JIANGBEISHIMINZHONGXIN], y: 5.25),
    station([江心洲尾], [JIANGXINZHOUWEI], y: 2.5),
    pin(x: -6.5, y: 2.),
    pin(x: -5., y: 2.),
    station([龙江], [LONGJIANG], anchor: "south-west"),
    station([草场门], [CAOCHANGMEN], anchor: "south-west"),
    station([云南路], [YUNNANLU], anchor: "south-west"),
    station([鼓楼], [GULOU]),
    station([鸡鸣寺], [JIMINGSI]),
    station([九华山], [JIUHUASHAN], x: 2.),
    pin(x: 2.5, d: dirs.east),
    station([岗子村], [GANGZICUN], y: 2.75),
    station([蒋王庙], [JIANGWANGMIAO], x: 4.5),
    station([王家湾], [WANGJIAWAN], x: 5.25),
    pin(x: 5.5, d: dirs.north-east),
    station([聚宝山], [JUBAOSHAN], x: 7.5),
    pin(x: 8.5, d: dirs.east),
    station([徐庄], [XUZHUANG], x: 9.),
    station([金马路], [JINMALU]),
    pin(x: 10. + 0.1, d: dirs.south-east),
    pin(y: 2., d: dirs.south),
    pin(dx: 0.5, d: dirs.east),
    pin(dx: 1., d: dirs.north-east),
    station([汇通路], [HUITONGLU], x: 12.),
    station([灵山], [LINGSHAN], x: 13.),
    station([东流], [DONGLIU], x: 15.),
    pin(x: 16., d: dirs.east),
    station([孟北], [MENGBEI], x: 17.),
    pin(dx: 1.5, d: dirs.north-east),
    station([西岗桦墅], [XIGANGHUASHU], dy: 1.),
    station([仙林湖], [XIANLINHU]),
    pin(y: 8., d: dirs.north),
  ),
  line(
    number: "5",
    color: rgb("#fdda24"),
    pin(x: -4.5, y: 7.),
    station([方家营], [FANGJIAYING]),
    station([南京西站], [NANJINGXIZHAN], anchor: "south-east"),
    pin(y: 5.75, d: dirs.south-west),
    station([静海寺], [JINGHAISI], dy: -0.25, anchor: "east"),
    pin(y: 5., d: dirs.south),
    station([下关], [XIAGUAN], anchor: "south-west"),
    station([盐仓桥], [YANCANGQIAO], x: -3.75),
    pin(x: -3.5, d: dirs.east),
    station([福建路], [FUJIANLU], anchor: "west"),
    station([虹桥], [HONGQIAO]),
    station([青春广场], [QINGCHUNGUANGCHANG], x: -1.5),
    pin(x: -1., d: dirs.south-east),
    station([云南路], [YUNNANLU]),
    station([五台山], [WUTAISHAN]),
    station([上海路], [SHANGHAILU]),
    station([朝天宫], [CHAOTIANGONG]),
    pin(y: -2., d: dirs.south),
    station([三山街], [SANSHANJIE]),
    station([夫子庙], [FUZIMIAO]),
    station([通济门], [TONGJIMEN], x: 2., anchor: "north"),
    station([光华门], [GUANGHUAMEN], anchor: "south-west"),
    pin(x: 4.5, d: dirs.east),
    station([石门坎], [SHIMENKAN]),
    station([七桥瓮], [QIQIAOWENG]),
    station([大校场], [DAJIAOCHANG], anchor: "north-west"),
    station([神机营], [SHENJIYING], y: -7.),
    pin(y: -7.5, d: dirs.south),
    pin(y: -8., d: dirs.south-east),
    station([东山香樟园], [DONGSHANXIANGZHANGYUAN]),
    station([文靖路], [WENJINGLU]),
    station([东山], [DONGSHAN]),
    station([新亭路], [XINTINGLU]),
    station([竹山路], [ZHUSHANLU]),
    station([科宁路], [KENINGLU]),
    pin(y: -15., d: dirs.south),
    station([前庄], [QIANZHUANG]),
    station([诚信大道], [CHENGXINDADAO]),
    pin(x: 2.5, d: dirs.west),
    pin(y: -16., d: dirs.south),
    station([九龙湖南], [JIULONGHUNAN], x: 2.),
    station([吉印大道], [JIYINDADAO], anchor: "south-west"),
    pin(x: 0., d: dirs.west),
  ),
  line(
    number: "6",
    color: rgb("#4bbbb4"),
    pin(x: 1., y: -8. + 0.1),
    station([南京南站], [NANJING SOUTH RAILWAY STATION], x: 2.),
    pin(x: 3.5, d: dirs.east),
    station([夹岗], [JIAGANG], y: -7.),
    station([机场跑道旧址], [JICHANGPAODAOJIUZHI], anchor: "north-east"),
    station([市中医院], [SHIZHONGYIYUAN]),
    station([应天东街], [YINGTIANDONGJIE]),
    station([中和桥], [ZHONGHEQIAO]),
    station([光华门], [GUANGHUAMEN]),
    station([明故宫], [MINGGUGONG]),
    station([富贵山], [FUGUISHAN], y: 1.5),
    pin(y: 2., d: dirs.north),
    pin(y: 2.5 - 0.05, d: dirs.north-west),
    station([岗子村], [GANGZICUN]),
    pin(x: 4., d: dirs.north-east),
    pin(y: 4., d: dirs.north),
    station([花园路], [HUAYUANLU], y: 4.5),
    pin(x: 3., d: dirs.north-west),
    station([红山新城], [HONGSHANXINCHENG], y: 6.),
    pin(y: 6.5, d: dirs.north),
    station([营苑南路], [YINGYUANNANLU]),
    pin(x: 4., d: dirs.north-east),
    station([万寿], [WANSHOU], anchor: "south-west"),
    pin(y: 10., d: dirs.north),
    station([燕江新城], [YANJIANGXINCHENG], x: 4.5),
    station([兴学路], [XINGXUELU], x: 6.),
    station([兴智街], [XINGZHIJIE]),
    station([十月广场], [SHIYUEGUANGCHANG], x: 9.5),
    pin(x: 10.5, d: dirs.east),
    pin(dy: 0.5, d: dirs.north),
    station([金陵石化], [JINLINGSHIHUA], x: 11.5),
    station([栖霞山], [QIXIASHAN]),
    pin(x: 13.5, d: dirs.east),
  ),
  line(
    number: "7",
    color: rgb("#4a7729"),
    pin(x: 10., y: 9.),
    station([仙新路], [XIANXINLU]),
    station([尧化门], [YAOHUAMEN]),
    station([尧化新村], [YAOHUAXINCUN]),
    station([丁家庄南], [DINGJIAZHUANGNAN], y: 6.5),
    pin(x: 7., y: 6., d: dirs.west),
    station([丁家庄], [DINGJIAZHUANG], y: 7.5),
    pin(x: 5., d: dirs.north-west),
    station([万寿], [WANSHOU]),
    station([晓庄], [XIAOZHUANG]),
    station([幕府山], [MUFUSHAN], x: 0.5),
    pin(x: -1., d: dirs.west),
    station([五塘广场], [WUTANGGUANGCHANG]),
    pin(x: -1.5, d: dirs.south-west),
    station([幕府西路], [MUFUXILU], anchor: "east", y: 7.),
    station([钟阜路], [ZHONGFULU], anchor: "south-east"),
    pin(y: 5.5, d: dirs.south),
    station([福建路], [FUJIANLU]),
    pin(x: -3., d: dirs.south-west),
    station([古平岗], [GUPINGGANG], y: 3.25),
    station([草场门], [CAOCHANGMEN]),
    station([清凉山], [QINGLIANGSHAN]),
    station([莫愁湖], [MOCHOUHU]),
    station([大士茶亭], [DASHICHATING]),
    station([南湖], [NANHU]),
    station([应天大街], [YINGTIANDAJIE], y: -3),
    pin(y: -3, d: dirs.south),
    station([梦都大街东], [MENGDUDAJIEDONG]),
    station([新城科技园], [XINCHENGKEJIYUAN]),
    station([中胜], [ZHONGSHENG], anchor: "west"),
    station([嘉陵江东街], [JIALINGJIANGDONGJIE], y: -6.),
    station([永初路], [YONGCHULU], anchor: "west"),
    station([太清路], [TAIQINGLU]),
    station([螺塘路], [LUOTANGLU]),
    station([西善桥], [XISHANQIAO]),
    pin(y: -10., d: dirs.south-west),
  ),
  line(
    number: "9",
    color: rgb("#fa4616"),
    pin(x: 3. - 0.1, y: 6.),
    station([红山新城], [HONGSHANXINCHENG]),
    pin(y: 5., d: dirs.south),
    station([红山路], [HONGSHANLU], x: 2.),
    pin(x: 1.5 - 0.15, d: dirs.west),
    station([南京站], [NANJING RAILWAY STATION]),
    pin(y: 6., d: dirs.north-west),
    station([中央门], [ZHONGYANGMEN]),
    station([钟阜路], [ZHONGFULU]),
    station([四平路广场], [SIPINGLUGUANGCHANG]),
    pin(x: -5., d: dirs.west),
    station([下关], [XIAGUAN]),
    station([白云亭], [BAIYUNTING]),
    station([三汊河], [SANCHAHE]),
    station([龙江], [LONGJIANG]),
    station([管子桥], [GUANZIQIAO]),
    station([江东门], [JIANGDONGMEN]),
    pin(y: -1., d: dirs.south),
    station([清江南路], [QINGJIANNANLU], dx: -0.5),
    pin(dx: -1., d: dirs.west),
    station([上新河], [SHANGXINHE], anchor: "west"),
    station([绿博园], [LVBOYUAN], anchor: "west"),
    pin(dx: -1., d: dirs.south-west),
    station([江苏大剧院·宪法公园], [JSCPA/XIANFAGONGYUAN], anchor: "east"),
    pin(y: -4., d: dirs.south),
  ),
  line(
    number: "10",
    color: rgb("#b9975b"),
    pin(x: -16.5, y: 2.),
    station([雨山路], [YUSHANLU]),
    station([文德路], [WENDELU]),
    station([龙华路], [LONGHUALU]),
    pin(x: -13.5, y: 5., d: dirs.north-east),
    station([南京工业大学], [NANJING TECH]),
    station([浦口万汇城], [PUKOUWANHUICHENG]),
    station([临江·青奥体育公园], [LINJIANG/YOGSP], x: -11.),
    station([江心洲], [JIANGXINZHOU], x: -8.),
    station([绿博园], [LÜBOYUAN]),
    pin(x: -5.5, y: -3, d: dirs.south-east),
    station([梦都大街], [MENGDUDAJIE], y: -3.25),
    station([奥体中心], [OLYMPIC STADIUM], y: -4.),
    pin(y: -4.25, d: dirs.south-west),
    station([元通], [YUANTONG]),
    station([中胜], [ZHONGSHENG]),
    station([小行], [XIAOHANG], y: -6.5),
    pin(x: -4.5, d: dirs.south-east),
    pin(x: -3., d: dirs.east),
    pin(y: -5., d: dirs.north-east),
    station([安德门], [ANDEMEN]),
    station([共青团路], [GONGQINGTUANLU]),
    station([雨花台], [YUHUATAI]),
    station([卡子门], [KAZIMEN]),
    pin(x: 2.25, d: dirs.east),
    pin(x: 3.25, d: dirs.south-east),
    station([机场跑道旧址], [JICHANGPAODAOJIUZHI]),
    pin(x: 4., d: dirs.east),
    station([大校场], [DAJIAOCHANG]),
    station([承天大道], [CHENGTIANDADAO]),
    station([高桥门], [GAOQIAOMEN], x: 5.75),
    pin(x: 6., d: dirs.north-east),
    station([杨庄], [YANGZHUANG], x: 7.),
    station([石杨路], [SHIYANGLU]),
    station([东麒路], [DONGQILU]),
    pin(x: 9., d: dirs.east),
  ),
  line(
    number: "11",
    color: rgb("#ef426f"),
    pin(x: -5., y: 12.5),
    station([浦洲路], [PUZHOULU]),
    station([柳洲东路], [LIUZHOUDONGLU]),
    pin(y: 11., d: dirs.south),
    station([明滨路], [MINGBINLU], x: -5.25),
    station([长江大桥北], [CHANGJIANGDAQIAOBEI]),
    station([柳洲南路], [LIUZHOUNANLU]),
    station([浦东路], [PUDONGLU]),
    station([新马路], [XINMALU]),
    station([南京铁道学院], [NJRTS]),
    station([广西埂大街], [GUANGXIGENGDAJIE]),
    station([江北商务区], [JIANGBEISHANGWUQU]),
    station([七里河], [QILIHE]),
    station([临滁路], [LINCHULU]),
    station([浦口万汇城], [PUKOUWANHUICHENG]),
    station([城南河], [CHENGNANHE]),
    station([江淼路], [JIANGMIAOLU]),
    station([卓越路], [ZHUOYUELU]),
    station([行知路], [XINGZHILU]),
    station([绿水湾路], [LÜSHUIWANLU]),
    station([西江口], [XIJIANGKOU], y: -2),
    station([马骡圩], [MALUOWEI]),
    pin(y: -4., d: dirs.south-west),
  ),
  line(
    number: "S1",
    color: rgb("#4bbbb4"),
    pin(x: 2., y: -8 + 0.1),
    station([南京南站], [NANJING SOUTH RAILWAY STATION]),
    pin(dx: -1., d: dirs.west),
    pin(dy: -1., d: dirs.south-west),
    station([翠屏山], [CUIPINGSHAN], anchor: "east"),
    station([河海大学·佛城西路], [HHU/FOCHENGXILU], anchor: "east"),
    station([吉印大道], [JIYINDADAO], anchor: "east"),
    station([正方中路], [ZHENGFANGZHONGLU]),
    station([翔宇路北], [XIANGYULUBEI]),
    station([翔宇路南], [XIANGYULUNAN]),
    pin(y: -20., d: dirs.south),
    station([禄口机场], [LUKOU INTERNATIONAL AIRPORT]),
    station([空港新城江宁], [KONGGANGXINCHENGJIANGNING]),
    pin(dx: 2.5, d: dirs.east),
  ),
  line(
    number: "S2",
    color: rgb("#ab2328"),
    pin(x: -10., y: -10.),
    station([西善桥], [XISHANQIAO]),
    station([雨花经济开发区], []),
    station([板桥], []),
    station([板桥南], []),
    station([江宁镇], []),
    station([江宁滨江开发区], []),
    station([牧龙], []),
    station([铜井], []),
    pin(dy: -6., d: dirs.south-west),
    station([慈湖], [], dy: -0.5),
    station([湖北路], []),
    station([湖南路], []),
    station([雨山东路], []),
    station([九华路], []),
    station([采石河], []),
    station([当涂东], []),
    station([当涂南], []),
    pin(dy: -6., d: dirs.south),
  ),
  line(
    number: "S3",
    color: rgb("#b06c96"),
    pin(x: 2., y: -8),
    station([南京南站], []),
    station([景明佳园], []),
    station([铁心桥], []),
    station([春江路], []),
    station([贾西], []),
    pin(x: -6.5, d: dirs.west),
    station([油坊桥], []),
    station([永初路], []),
    pin(x: -8., d: dirs.north-west),
    station([平良大街], [], y: -7.),
    station([吴侯街], []),
    station([高庙路], [], y: -8.),
    station([天保], [], y: -9.5),
    station([刘村], [], y: -10.5),
    pin(dy: -4.5, d: dirs.south-west),
    pin(dx: -7.25, d: dirs.north-west, x: -19.75, y: -3.75),
    station([马骡圩], [], y: -12., x: -4.),
    station([兰花塘], [], x: -20.5), // fix: 这里有bug，如果不指定x会跑别的地方去
    station([双垅], []),
    station([石碛河], []),
    station([桥林新城], []),
    station([林山], []),
    station([高家冲], []),
    pin(dx: -3.25, d: dirs.south-west),
  ),
  line(
    number: "S4",
    color: rgb("#ff661f"),
    pin(x: -13., y: 14.),
    station([汊河], []),
    station([汊河新城], [], dx: -0.75),
    station([相官], [], dx: -1.5),
    station([十二里半], []),
    pin(dx: -4., d: dirs.north-west),
    station([水口], [], dx: -0.5),
    station([林楼], [], dx: -1.5),
    pin(dx: -2., d: dirs.west),
    station([大王郢], []),
    pin(dy: -1., d: dirs.south),
    station([苏滁商务中心], [], dy: -0.25),
    station([担子], []),
    pin(dy: -1.5, d: dirs.south-west),
    station([滁州政务中心], [], dx: -0.5),
    station([琅琊山], [], dx: -1.5),
    pin(dx: -2., d: dirs.west),
    station([花博园], [], dy: -0.5),
    station([腰铺], [], dy: -1.5),
    pin(dy: -2., d: dirs.south),
    station([滁州高铁站], []),
    pin(dy: -0.5, d: dirs.south-east),
  ),
  line(
    number: "S5",
    color: rgb("#f5df4d"),
    pin(x: 17.5, y: 8.),
    pin(dy: 2., d: dirs.north),
    station([摄山], []),
    pin(dx: 1.5, d: dirs.east),
    station([江乘], []),
    station([龙潭], [], dx: 1.25),
    pin(dx: 1.5, d: dirs.north-east),
    station([花园营防], [], dx: 0.5),
    station([龙潭新城], []),
    station([靖安], [], dx: 2.5),
    pin(dx: 3., d: dirs.east),
    station([黄天荡], [], dy: 0.5),
    station([万年路], [], dy: 2.),
    pin(dy: 2.5, d: dirs.north),
    station([工农路], [], dx: 0.5),
    station([天宁大道], []),
    station([仪征开发区], [], dx: 2.5),
    station([朴席], [], dx: 4.),
    pin(dx: 4.5, d: dirs.east),
    station([扬州汊河], []),
    station([站南路], []),
    station([扬州西站], []),
    pin(dy: 3., d: dirs.north),
  ),
  line(
    number: "S6",
    color: rgb("#c98bdb"),
    pin(x: 9.5, y: 1.),
    station([马群], []),
    station([百水桥], [], x: 11.),
    station([麒麟门], [], x: 12.),
    station([东郊小镇], [], x: 14.),
    station([古泉], [], x: 16.),
    pin(dx: 7., d: dirs.east),
    pin(dx: 0.5, d: dirs.north-east),
    station([南京猿人洞], []),
    pin(dx: 1.5, d: dirs.east),
    station([汤山], []),
    pin(dy: -0.75, d: dirs.south),
    pin(dx: -0.5, d: dirs.south-west),
    station([泉都大街], []),
    pin(dy: -0.5, d: dirs.south),
    pin(dx: 0.25, d: dirs.south-east),
    pin(dx: 0.75, d: dirs.east),
    station([黄梅], []),
    pin(dx: 1., d: dirs.south-east),
    station([童世界], [], dx: 1.5),
    pin(dx: 2., d: dirs.east),
    station([华阳], []),
    station([崇明], []),
    station([句容], []),
    pin(dy: -6., d: dirs.south),
  ),
  line(
    number: "S7",
    color: rgb("#e89cae"),
    pin(x: 2.5, y: -20.),
    station([空港新城江宁], []),
    pin(dx: 1.25, d: dirs.east),
    station([柘塘], [], x: 4.),
    station([空港新城溧水], []),
    station([群力], [], x: 5.),
    pin(dx: 1.5, d: dirs.south-east),
    station([卧龙湖], [], y: -21.75),
    station([溧水], []),
    station([中山湖], []),
    station([幸庄], []),
    station([无想山], []),
    pin(dy: -2.5, d: dirs.south),
  ),
  line(
    number: "S8",
    color: rgb("#ea7600"),
    pin(x: -6.25, y: 9.75),
    station([长江大桥北], []),
    station([毛纺厂路], []),
    station([泰山新村], [], r: 1.0),
    pin(dy: 1.25, d: dirs.north-west),
    station([泰冯路], []),
    station([高新开发区], []),
    station([信息工程大学], []),
    station([卸甲甸], [], y: 14.25),
    pin(dy: 3.5, d: dirs.north),
    station([大厂], []),
    station([葛塘], []),
    station([长芦], []),
    station([化工园], []),
    station([六合开发区], []),
    station([龙池], []),
    station([雄州], []),
    station([凤凰山公园], []),
    station([方州广场], []),
    station([沈桥], []),
    station([八百桥], []),
    station([金牛湖], []),
    pin(dx: 6., d: dirs.north-east),
  ),
  line(
    number: "S9",
    color: rgb("#f1b434"),
    pin(x: 0., y: -19.),
    station([翔宇路南], []),
    pin(dx: -0.1, d: dirs.south-west),
    pin(y: -20.75, d: dirs.south),
    station([铜山], []),
    pin(x: 1., d: dirs.east),
    station([石湫], [], y: -21.),
    station([明觉], [], y: -22.),
    station([团结圩], [], y: -24.),
    station([高淳], []),
    pin(y: -25., d: dirs.south),
  ),
)

#let nj-metro = metro(..lines)
#diagram(nj-metro, canvas-length: 2.0cm, grid: ((-24, -21), (25, 17)))

#let metro-query(lines, name: none) = {
  for line in lines {
    for sta in line.stations {
      if sta.id == name {
        (sta,)
      }
    }
  }
}
