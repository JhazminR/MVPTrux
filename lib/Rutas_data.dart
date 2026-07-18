import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ============================================================================
//  CLASE DESTINO
// ============================================================================
class Destino {
  final String nombre;
  final String direccion;
  final LatLng coordenadas;
  final int? puntoIndice; // Índice en la polyline (0, 119, 238, 356)

  Destino({
    required this.nombre,
    required this.direccion,
    required this.coordenadas,
    this.puntoIndice,
  });
}

// ============================================================================
//  CLASE RUTA
// ============================================================================
class Ruta {
  final String id;
  final String nombre;
  final String color;
  final String letra;
  final String empresa;
  final List<LatLng> polyline;
  final List<Destino> destinos;

  Ruta({
    required this.id,
    required this.nombre,
    required this.color,
    required this.letra,
    required this.empresa,
    required this.polyline,
    required this.destinos,
  });

  // Obtener destino por su índice en la polyline
  Destino? getDestinoPorIndice(int index) {
    try {
      return destinos.firstWhere((d) => d.puntoIndice == index);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
//  REPOSITORIO DE DATOS PRINCIPAL
// ============================================================================
class RutasData {
  // --------------------------------------------------------------------------
  //  1. DATOS ESTÁTICOS DE LA RUTA (ID, Nombre, Colores)
  // --------------------------------------------------------------------------
  static const String rutaId = 'RUTA_001';
  static const String rutaNombre = 'Panamericana Norte - Villa El Contador';
  static const String rutaColor = 'Rojo con blanco';
  static const String rutaLetra = 'D';
  static const String rutaEmpresa = 'Ícaro';

  // --------------------------------------------------------------------------
  //  2. POLYLINE
  // --------------------------------------------------------------------------
  static final List<LatLng> _polyline = [
    LatLng(-8.0496345, -79.0865509),
    LatLng(-8.0499763, -79.0866396),
    LatLng(-8.0500094, -79.0865631),
    LatLng(-8.0504994, -79.0855492),
    LatLng(-8.0509403, -79.0847137),
    LatLng(-8.0513628, -79.0839168),
    LatLng(-8.051787, -79.0831078),
    LatLng(-8.0522176, -79.0823073),
    LatLng(-8.0526999, -79.0813704),
    LatLng(-8.0532549, -79.0803413),
    LatLng(-8.0534217, -79.0799887),
    LatLng(-8.053458, -79.0799535),
    LatLng(-8.0539734, -79.0795025),
    LatLng(-8.0548175, -79.0788173),
    LatLng(-8.0555903, -79.0781257),
    LatLng(-8.0563383, -79.078923),
    LatLng(-8.0563732, -79.0789368),
    LatLng(-8.0571303, -79.0790219),
    LatLng(-8.0578227, -79.0790743),
    LatLng(-8.058651, -79.0783547),
    LatLng(-8.0594725, -79.0776458),
    LatLng(-8.0599957, -79.0771985),
    LatLng(-8.0602783, -79.0769577),
    LatLng(-8.0607671, -79.0765411),
    LatLng(-8.0607857, -79.0765431),
    LatLng(-8.0611875, -79.0773442),
    LatLng(-8.0612689, -79.0775118),
    LatLng(-8.0615978, -79.0781788),
    LatLng(-8.0618127, -79.0784741),
    LatLng(-8.0622039, -79.0788855),
    LatLng(-8.0625436, -79.079292),
    LatLng(-8.0628358, -79.0796891),
    LatLng(-8.0631689, -79.0801841),
    LatLng(-8.0634472, -79.0804784),
    LatLng(-8.0634646, -79.0804775),
    LatLng(-8.0636662, -79.0801631),
    LatLng(-8.0638089, -79.0799195),
    LatLng(-8.0638401, -79.0798635),
    LatLng(-8.0639645, -79.0796125),
    LatLng(-8.0641625, -79.079272),
    LatLng(-8.0643347, -79.0789377),
    LatLng(-8.0644716, -79.0787082),
    LatLng(-8.0647835, -79.0781671),
    LatLng(-8.0649119, -79.0779664),
    LatLng(-8.0650546, -79.0777347),
    LatLng(-8.0651773, -79.0776215),
    LatLng(-8.0652159, -79.0775921),
    LatLng(-8.0653736, -79.0774545),
    LatLng(-8.0655532, -79.0772965),
    LatLng(-8.0656102, -79.0772319),
    LatLng(-8.065883, -79.076956),
    LatLng(-8.0660777, -79.0767516),
    LatLng(-8.0664049, -79.0764181),
    LatLng(-8.0665389, -79.0762791),
    LatLng(-8.0669636, -79.0758063),
    LatLng(-8.0672568, -79.0755301),
    LatLng(-8.0675456, -79.0752624),
    LatLng(-8.06789, -79.0749249),
    LatLng(-8.0680582, -79.074764),
    LatLng(-8.0685, -79.0742747),
    LatLng(-8.0687735, -79.0740022),
    LatLng(-8.0689663, -79.0738204),
    LatLng(-8.0691851, -79.0736757),
    LatLng(-8.0692007, -79.0736531),
    LatLng(-8.0689223, -79.0731092),
    LatLng(-8.0688674, -79.073006),
    LatLng(-8.0687242, -79.0726983),
    LatLng(-8.0682797, -79.0716654),
    LatLng(-8.0680576, -79.0711596),
    LatLng(-8.0678262, -79.0706217),
    LatLng(-8.0677764, -79.070497),
    LatLng(-8.067512, -79.0699732),
    LatLng(-8.0672681, -79.0694112),
    LatLng(-8.0670558, -79.0689276),
    LatLng(-8.0668803, -79.0685301),
    LatLng(-8.0667172, -79.0681544),
    LatLng(-8.0665863, -79.0678664),
    LatLng(-8.0663647, -79.06738),
    LatLng(-8.0662048, -79.0670337),
    LatLng(-8.0661501, -79.0669204),
    LatLng(-8.0659717, -79.0665147),
    LatLng(-8.0657523, -79.0660476),
    LatLng(-8.0654787, -79.0654137),
    LatLng(-8.0652642, -79.0649172),
    LatLng(-8.0650735, -79.064521),
    LatLng(-8.0649273, -79.0641812),
    LatLng(-8.0648053, -79.0639043),
    LatLng(-8.0647021, -79.0636779),
    LatLng(-8.0644949, -79.0632203),
    LatLng(-8.0643511, -79.0629005),
    LatLng(-8.0641769, -79.0625132),
    LatLng(-8.064114, -79.062371),
    LatLng(-8.0640237, -79.0621567),
    LatLng(-8.064024, -79.0620957),
    LatLng(-8.0640546, -79.0620544),
    LatLng(-8.0641453, -79.0620188),
    LatLng(-8.0643748, -79.0619382),
    LatLng(-8.0645707, -79.06187),
    LatLng(-8.064872, -79.0617615),
    LatLng(-8.0650468, -79.0616995),
    LatLng(-8.0652102, -79.061656),
    LatLng(-8.0652508, -79.0615437),
    LatLng(-8.0652736, -79.0614016),
    LatLng(-8.0652953, -79.0613222),
    LatLng(-8.0652946, -79.0612595),
    LatLng(-8.0652781, -79.0612025),
    LatLng(-8.0651674, -79.0609066),
    LatLng(-8.0650665, -79.0606062),
    LatLng(-8.0648862, -79.0600697),
    LatLng(-8.0646571, -79.0594193),
    LatLng(-8.0644211, -79.0587065),
    LatLng(-8.0642534, -79.0582625),
    LatLng(-8.064189, -79.0580784),
    LatLng(-8.064199, -79.058059),
    LatLng(-8.0645278, -79.05793),
    LatLng(-8.0648807, -79.0578126),
    LatLng(-8.0658197, -79.0574484),
    LatLng(-8.0666216, -79.0571584),
    LatLng(-8.0673121, -79.0569224),
    LatLng(-8.0678326, -79.0567936),
    LatLng(-8.0683212, -79.0566434),
    LatLng(-8.069033, -79.0563859),
    LatLng(-8.0702439, -79.0559782),
    LatLng(-8.0714124, -79.0555491),
    LatLng(-8.0725862, -79.055132),
    LatLng(-8.0737577, -79.0546936),
    LatLng(-8.0737685, -79.0546725),
    LatLng(-8.07364, -79.0542861),
    LatLng(-8.0734248, -79.053688),
    LatLng(-8.0734886, -79.0536558),
    LatLng(-8.0743145, -79.0532937),
    LatLng(-8.0748954, -79.0529771),
    LatLng(-8.0750062, -79.0529243),
    LatLng(-8.0759198, -79.0524932),
    LatLng(-8.0765604, -79.0522075),
    LatLng(-8.0767964, -79.052082),
    LatLng(-8.0772006, -79.0519004),
    LatLng(-8.0777509, -79.0516651),
    LatLng(-8.0787548, -79.0512252),
    LatLng(-8.0796205, -79.0508229),
    LatLng(-8.0805823, -79.0503745),
    LatLng(-8.0814148, -79.0500057),
    LatLng(-8.0814359, -79.0499111),
    LatLng(-8.0811756, -79.0493452),
    LatLng(-8.0808755, -79.0487417),
    LatLng(-8.0805914, -79.0481496),
    LatLng(-8.0806014, -79.048107),
    LatLng(-8.081088, -79.0478933),
    LatLng(-8.0815886, -79.0476647),
    LatLng(-8.0815944, -79.0476259),
    LatLng(-8.0813242, -79.0470229),
    LatLng(-8.0809923, -79.0462987),
    LatLng(-8.0807374, -79.0456925),
    LatLng(-8.0807098, -79.0456318),
    LatLng(-8.080714, -79.0456116),
    LatLng(-8.0812198, -79.0453818),
    LatLng(-8.0817286, -79.045143),
    LatLng(-8.0822491, -79.0448963),
    LatLng(-8.0829177, -79.0446184),
    LatLng(-8.0834594, -79.0443663),
    LatLng(-8.0843604, -79.0438568),
    LatLng(-8.0851113, -79.0435269),
    LatLng(-8.0853357, -79.0434269),
    LatLng(-8.0855252, -79.0433378),
    LatLng(-8.0856475, -79.0432766),
    LatLng(-8.0866068, -79.0428269),
    LatLng(-8.0877017, -79.0423005),
    LatLng(-8.0877647, -79.0422669),
    LatLng(-8.0883838, -79.042008),
    LatLng(-8.0886833, -79.0418845),
    LatLng(-8.0888098, -79.0418332),
    LatLng(-8.0893618, -79.0415909),
    LatLng(-8.0901423, -79.0412303),
    LatLng(-8.0912631, -79.040722),
    LatLng(-8.0915197, -79.0406154),
    LatLng(-8.0915439, -79.0406347),
    LatLng(-8.0915459, -79.0407496),
    LatLng(-8.0915313, -79.041113),
    LatLng(-8.0913981, -79.0416871),
    LatLng(-8.0912149, -79.0420546),
    LatLng(-8.0910608, -79.0428798),
    LatLng(-8.0910241, -79.0444193),
    LatLng(-8.0909689, -79.0460419),
    LatLng(-8.0909351, -79.0473197),
    LatLng(-8.0909324, -79.0474657),
    LatLng(-8.0909482, -79.0474872),
    LatLng(-8.0911639, -79.0475356),
    LatLng(-8.0919553, -79.0476992),
    LatLng(-8.0927626, -79.0479084),
    LatLng(-8.0941567, -79.0482269),
    LatLng(-8.0952691, -79.0484486),
    LatLng(-8.0952922, -79.0484484),
    LatLng(-8.0953181, -79.0484451),
    LatLng(-8.095341, -79.0484544),
    LatLng(-8.0954784, -79.0485563),
    LatLng(-8.0959878, -79.0487533),
    LatLng(-8.0965723, -79.0489794),
    LatLng(-8.0969695, -79.0491125),
    LatLng(-8.09734, -79.0492466),
    LatLng(-8.0980972, -79.049518),
    LatLng(-8.0984715, -79.0496659),
    LatLng(-8.0992761, -79.0499542),
    LatLng(-8.0997582, -79.0501367),
    LatLng(-8.0999998, -79.0502359),
    LatLng(-8.1006197, -79.0504549),
    LatLng(-8.1006496, -79.0504547),
    LatLng(-8.100718, -79.0504205),
    LatLng(-8.1008233, -79.0504072),
    LatLng(-8.1008401, -79.0503908),
    LatLng(-8.1008583, -79.0502222),
    LatLng(-8.1008798, -79.049926),
    LatLng(-8.100887, -79.0497528),
    LatLng(-8.1009062, -79.0492796),
    LatLng(-8.1009069, -79.0485519),
    LatLng(-8.1008983, -79.0483763),
    LatLng(-8.100891, -79.0480235),
    LatLng(-8.1009711, -79.04729),
    LatLng(-8.101074, -79.046482),
    LatLng(-8.1012556, -79.0455618),
    LatLng(-8.1013206, -79.045252),
    LatLng(-8.1013814, -79.0449852),
    LatLng(-8.1015025, -79.0444872),
    LatLng(-8.1015274, -79.0443272),
    LatLng(-8.1016325, -79.0438343),
    LatLng(-8.1017505, -79.0432993),
    LatLng(-8.1018297, -79.0428989),
    LatLng(-8.1019877, -79.0421956),
    LatLng(-8.1020612, -79.0417149),
    LatLng(-8.1021281, -79.0414716),
    LatLng(-8.1021947, -79.0411687),
    LatLng(-8.1023777, -79.0406362),
    LatLng(-8.1027517, -79.0395842),
    LatLng(-8.1028404, -79.0394319),
    LatLng(-8.1030301, -79.0390736),
    LatLng(-8.1031457, -79.0388356),
    LatLng(-8.1034366, -79.0382849),
    LatLng(-8.1036185, -79.0379409),
    LatLng(-8.1041181, -79.0369404),
    LatLng(-8.104161, -79.0368495),
    LatLng(-8.1042069, -79.0367562),
    LatLng(-8.1042308, -79.0367389),
    LatLng(-8.1043012, -79.0367168),
    LatLng(-8.1043261, -79.0367024),
    LatLng(-8.1045027, -79.0363566),
    LatLng(-8.1048356, -79.0357305),
    LatLng(-8.1048697, -79.0356981),
    LatLng(-8.1048936, -79.0356863),
    LatLng(-8.1049285, -79.035689),
    LatLng(-8.1051987, -79.0357953),
    LatLng(-8.1058564, -79.0360635),
    LatLng(-8.1059201, -79.0361064),
    LatLng(-8.1061262, -79.036197),
    LatLng(-8.1069304, -79.0365281),
    LatLng(-8.1079349, -79.036934),
    LatLng(-8.1085835, -79.0372048),
    LatLng(-8.1091772, -79.0375144),
    LatLng(-8.1095301, -79.0378249),
    LatLng(-8.1097339, -79.0379951),
    LatLng(-8.1098737, -79.0381113),
    LatLng(-8.109967, -79.0381785),
    LatLng(-8.1099886, -79.0381746),
    LatLng(-8.1100461, -79.0381016),
    LatLng(-8.1103444, -79.0376868),
    LatLng(-8.1106981, -79.0371871),
    LatLng(-8.111374, -79.036226),
    LatLng(-8.1115837, -79.0359389),
    LatLng(-8.1116742, -79.0358098),
    LatLng(-8.1121105, -79.0351892),
    LatLng(-8.1125778, -79.0346255),
    LatLng(-8.1126148, -79.0345722),
    LatLng(-8.1127203, -79.034459),
    LatLng(-8.1128686, -79.0342839),
    LatLng(-8.1132022, -79.0338703),
    LatLng(-8.1134341, -79.0335974),
    LatLng(-8.1136306, -79.033368),
    LatLng(-8.1139649, -79.0329596),
    LatLng(-8.1140405, -79.0328452),
    LatLng(-8.1141139, -79.0327484),
    LatLng(-8.1143202, -79.0324822),
    LatLng(-8.1143437, -79.0324423),
    LatLng(-8.1143706, -79.0323827),
    LatLng(-8.1143875, -79.0323528),
    LatLng(-8.1147031, -79.032119),
    LatLng(-8.115063, -79.031838),
    LatLng(-8.1154094, -79.0315762),
    LatLng(-8.1157272, -79.0313341),
    LatLng(-8.1157637, -79.0313039),
    LatLng(-8.1158285, -79.031215),
    LatLng(-8.1160621, -79.0307652),
    LatLng(-8.1163136, -79.0302336),
    LatLng(-8.1163402, -79.0302106),
    LatLng(-8.1164863, -79.0300456),
    LatLng(-8.1165585, -79.0299436),
    LatLng(-8.116734, -79.0297445),
    LatLng(-8.117005, -79.0294271),
    LatLng(-8.1172993, -79.0290616),
    LatLng(-8.1175976, -79.0286983),
    LatLng(-8.1180162, -79.0282147),
    LatLng(-8.118505, -79.0276103),
    LatLng(-8.118598, -79.0275191),
    LatLng(-8.1195875, -79.0263268),
    LatLng(-8.1195793, -79.0263002),
    LatLng(-8.1195278, -79.0262569),
    LatLng(-8.1190089, -79.0258208),
    LatLng(-8.118881, -79.0257156),
    LatLng(-8.1185584, -79.0254015),
    LatLng(-8.118494, -79.0253254),
    LatLng(-8.1183302, -79.0251604),
    LatLng(-8.1181463, -79.0249615),
    LatLng(-8.1181349, -79.024933),
    LatLng(-8.11811, -79.0248707),
    LatLng(-8.1180927, -79.0248438),
    LatLng(-8.1178874, -79.024622),
    LatLng(-8.1177433, -79.0244626),
    LatLng(-8.1174562, -79.0241479),
    LatLng(-8.1171543, -79.0238653),
    LatLng(-8.1168934, -79.0236245),
    LatLng(-8.1166281, -79.0233702),
    LatLng(-8.1163633, -79.0231185),
    LatLng(-8.1156644, -79.0224243),
    LatLng(-8.1152507, -79.0219946),
    LatLng(-8.1148537, -79.0215797),
    LatLng(-8.1146506, -79.0213517),
    LatLng(-8.1141191, -79.0208259),
    LatLng(-8.1136699, -79.0204592),
    LatLng(-8.1133429, -79.0201909),
    LatLng(-8.1133358, -79.0201704),
    LatLng(-8.1135841, -79.0198089),
    LatLng(-8.1138011, -79.0195052),
    LatLng(-8.1139628, -79.0192825),
    LatLng(-8.1142735, -79.0188226),
    LatLng(-8.1145662, -79.0183843),
    LatLng(-8.114825, -79.0180066),
    LatLng(-8.1151438, -79.017537),
    LatLng(-8.1154718, -79.0170502),
    LatLng(-8.1158415, -79.0165394),
    LatLng(-8.1160834, -79.0162067),
    LatLng(-8.1161439, -79.0161169),
    LatLng(-8.1161392, -79.0160917),
    LatLng(-8.1158208, -79.0158673),
    LatLng(-8.115218, -79.0154261),
    LatLng(-8.114929, -79.0151618),
    LatLng(-8.1143295, -79.0147669),
    LatLng(-8.1143182, -79.0147399),
    LatLng(-8.1144277, -79.0140632),
    LatLng(-8.1145172, -79.0135502),
    LatLng(-8.1145555, -79.0131955),
    LatLng(-8.1145714, -79.013054),
    LatLng(-8.1146166, -79.0127999),
    LatLng(-8.1147189, -79.0121668),
    LatLng(-8.1147539, -79.0119083),
    LatLng(-8.114884, -79.011018),
    LatLng(-8.1150506, -79.0100862),
    LatLng(-8.1152988, -79.0094787),
    LatLng(-8.1153745, -79.0088336),
    LatLng(-8.1151945, -79.0080246),
    LatLng(-8.1149257, -79.0069885),
    LatLng(-8.1148234, -79.0065225),
    LatLng(-8.1148328, -79.0065072),
    LatLng(-8.1154123, -79.0064177),
    LatLng(-8.1160462, -79.0063512),
    LatLng(-8.1161262, -79.0063515),
    LatLng(-8.1162085, -79.0063542),
    LatLng(-8.1164298, -79.0063982),
    LatLng(-8.116486, -79.0064222),
    LatLng(-8.1166519, -79.0065323),
    LatLng(-8.1169164, -79.0067364),
    LatLng(-8.116936, -79.0067341),
    LatLng(-8.1173916, -79.0060914),
    LatLng(-8.1175973, -79.0057819),
    LatLng(-8.1177381, -79.005577),
    LatLng(-8.1178683, -79.0053898),
    LatLng(-8.1178896, -79.0053861),
    LatLng(-8.1182537, -79.0056574),
    LatLng(-8.1187736, -79.0060332),
    LatLng(-8.1192335, -79.0063675),
    LatLng(-8.1195913, -79.0066278),
    LatLng(-8.1199511, -79.0068893),
    LatLng(-8.1200586, -79.0069939),
    LatLng(-8.1201276, -79.0071307),
    LatLng(-8.1205093, -79.0078887),
    LatLng(-8.1206302, -79.008114),
    LatLng(-8.1208912, -79.0086529),
    LatLng(-8.1210146, -79.0088768),
    LatLng(-8.1211345, -79.0091065),
    LatLng(-8.121501, -79.0098199),
    LatLng(-8.1215942, -79.0100033),
  ];

  // --------------------------------------------------------------------------
  //  3. DESTINOS CLAVE
  // --------------------------------------------------------------------------
  static final List<Destino> _destinos = [
    Destino(
      nombre: 'Panamericana Norte',
      direccion: 'Au. Panamericana Norte 7660',
      coordenadas: const LatLng(-8.0496345, -79.0865509),
      puntoIndice: 0,
    ),
    Destino(
      nombre: 'Parque Amauta - La Esperanza',
      direccion: '6 De Enero 675-733, La Esperanza',
      coordenadas: const LatLng(-8.0673121, -79.0569224),
      puntoIndice: 119,
    ),
    Destino(
      nombre: 'Mall Plaza Trujillo',
      direccion: 'Av. Mansiche s/n',
      coordenadas: const LatLng(-8.1009, -79.04927),
      puntoIndice: 238,
    ),
    Destino(
      nombre: 'Av. Del Contador',
      direccion: 'Final de la Av. Del Contador con Prol. Francisco de Zela',
      coordenadas: const LatLng(-8.1215942, -79.0100033),
      puntoIndice: 356,
    ),
    Destino(
      nombre: 'UTP - Universidad Tecnológica del Perú',
      direccion: 'Av. Nicolás de Piérola 1221, Trujillo',
      coordenadas: const LatLng(-8.0980171, -79.0377729),
    ),
    Destino(
      nombre: 'Plaza de Armas de Trujillo',
      direccion: 'Trujillo 13001',
      coordenadas: const LatLng(-8.1126485, -79.0290394),
    ),
  ];

  // --------------------------------------------------------------------------
  //  4. GETTER DE LA RUTA PRINCIPAL
  // --------------------------------------------------------------------------
  static Ruta get rutaPrincipal {
    return Ruta(
      id: rutaId,
      nombre: rutaNombre,
      color: rutaColor,
      letra: rutaLetra,
      empresa: rutaEmpresa,
      polyline: List.unmodifiable(_polyline),
      destinos: List.unmodifiable(_destinos),
    );
  }

  // --------------------------------------------------------------------------
  //  5. LÓGICA DE CÁLCULO (PROXIMIDAD, TIEMPOS Y BÚSQUEDA)
  // --------------------------------------------------------------------------

  // 5.1 Calcular distancia en metros (Fórmula de Haversine para caminar o línea recta)
  static double calcularDistanciaMetros(LatLng inicio, LatLng fin) {
    const double radioTierra = 6371000; // Radio de la Tierra en metros
    double dLat = _gradosARadianes(fin.latitude - inicio.latitude);
    double dLng = _gradosARadianes(fin.longitude - inicio.longitude);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_gradosARadianes(inicio.latitude)) *
            cos(_gradosARadianes(fin.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierra * c;
  }

  static double _gradosARadianes(double grados) {
    return grados * pi / 180;
  }

  // 5.2 Calcular la distancia exacta a través de la ruta (siguiendo la polyline)
  static double calcularDistanciaRuta(int indexInicio, int indexFin) {
    if (indexInicio < 0 ||
        indexFin >= _polyline.length ||
        indexInicio >= indexFin) {
      return 0.0;
    }

    double distanciaTotal = 0.0;
    for (int i = indexInicio; i < indexFin; i++) {
      distanciaTotal += calcularDistanciaMetros(_polyline[i], _polyline[i + 1]);
    }
    return distanciaTotal;
  }

  // 5.3 Calcular ETA (Tiempo Estimado de Llegada) en minutos
  // Asumimos una velocidad promedio de 18 km/h para el micro
  static int calcularETA(double distanciaMetros, {double velocidadKmH = 18.0}) {
    if (distanciaMetros <= 0) return 0;

    // Convertir km/h a metros por segundo
    double velocidadMetrosPorSegundo = velocidadKmH * (1000 / 3600);
    double segundos = distanciaMetros / velocidadMetrosPorSegundo;

    return (segundos / 60)
        .ceil(); // Redondea hacia arriba al minuto más cercano
  }

  // 5.4 Distancia de un punto a un segmento (en metros)
  static double _distanciaASegmento(LatLng punto, LatLng p1, LatLng p2) {
    double x0 = punto.latitude;
    double y0 = punto.longitude;
    double x1 = p1.latitude;
    double y1 = p1.longitude;
    double x2 = p2.latitude;
    double y2 = p2.longitude;

    double dx = x2 - x1;
    double dy = y2 - y1;

    if (dx == 0 && dy == 0) {
      double distGrados = sqrt(pow(x0 - x1, 2) + pow(y0 - y1, 2));
      return distGrados * 111320;
    }

    double t = ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);

    double nearestX = x1 + t * dx;
    double nearestY = y1 + t * dy;

    double distGrados = sqrt(pow(x0 - nearestX, 2) + pow(y0 - nearestY, 2));
    return distGrados * 111320;
  }

  // 5.5 Verificar si el usuario está SOBRE la ruta
  static bool isUserOnRoute(
    LatLng userLocation, {
    double toleranceMeters = 30,
  }) {
    if (_polyline.isEmpty) return false;

    for (int i = 0; i < _polyline.length - 1; i++) {
      double distancia = _distanciaASegmento(
        userLocation,
        _polyline[i],
        _polyline[i + 1],
      );
      if (distancia <= toleranceMeters) {
        return true;
      }
    }
    return false;
  }

  // 5.6 Obtener el punto más cercano de la ruta al usuario
  static LatLng getNearestPointOnRoute(LatLng userLocation) {
    if (_polyline.isEmpty) return userLocation;

    LatLng nearestPoint = _polyline[0];
    double minDistance = double.infinity;

    for (int i = 0; i < _polyline.length - 1; i++) {
      LatLng p1 = _polyline[i];
      LatLng p2 = _polyline[i + 1];

      double x0 = userLocation.latitude;
      double y0 = userLocation.longitude;
      double x1 = p1.latitude;
      double y1 = p1.longitude;
      double x2 = p2.latitude;
      double y2 = p2.longitude;

      double dx = x2 - x1;
      double dy = y2 - y1;

      if (dx == 0 && dy == 0) {
        double d = sqrt(pow(x0 - x1, 2) + pow(y0 - y1, 2));
        if (d < minDistance) {
          minDistance = d;
          nearestPoint = p1;
        }
        continue;
      }

      double t = ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy);
      t = t.clamp(0.0, 1.0);

      double nearestX = x1 + t * dx;
      double nearestY = y1 + t * dy;
      LatLng candidate = LatLng(nearestX, nearestY);
      double d = sqrt(pow(x0 - nearestX, 2) + pow(y0 - nearestY, 2));

      if (d < minDistance) {
        minDistance = d;
        nearestPoint = candidate;
      }
    }
    return nearestPoint;
  }

  // 5.7 Obtener el índice más cercano en la polyline
  static int getNearestIndexOnRoute(LatLng userLocation) {
    if (_polyline.isEmpty) return 0;

    int nearestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < _polyline.length; i++) {
      double latDiff = userLocation.latitude - _polyline[i].latitude;
      double lngDiff = userLocation.longitude - _polyline[i].longitude;
      double d = sqrt(latDiff * latDiff + lngDiff * lngDiff);
      if (d < minDistance) {
        minDistance = d;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  // 5.8 Buscar destino por nombre
  static Destino? getDestinoByNombre(String nombre) {
    try {
      return _destinos.firstWhere((d) => d.nombre == nombre);
    } catch (e) {
      return null;
    }
  }

  // 5.9 Obtener todos los destinos
  static List<Destino> getDestinos() {
    return List.unmodifiable(_destinos);
  }
}
