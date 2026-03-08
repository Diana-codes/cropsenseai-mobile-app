class RwandaLocations {
  /// Location hierarchy used in both web and mobile:
  /// Province -> District -> Sectors -> (optional) Cells -> (optional) Villages
  ///
  /// For some districts we only have sector names (no cells/villages).
  static const Map<String, Map<String, dynamic>> data = {
    "Kigali City": {
      "districts": {
        "Gasabo": {
          "sectors": {
            "Bumbogo": {
              "cells": {
                "Nyamugari": ["Kabuga", "Nyamugari", "Rugende"],
                "Bisebeye": ["Bisebeye", "Gasura", "Nyagatare"],
                "Rusagara": ["Rusagara", "Kabeza", "Gasagara"],
              },
            },
            "Remera": {
              "cells": {
                "Rukiri I": ["Agatare", "Kabeza", "Nyabisindu"],
                "Rukiri II": ["Gikondo", "Kacyiru", "Remera"],
                "Nyarurama": ["Amahoro", "Kimironko", "Nyarurama"],
              },
            },
          },
        },
        "Kicukiro": {
          "sectors": {
            "Gahanga": {
              "cells": {
                "Akabahizi": ["Akabahizi", "Gahanga", "Masaka"],
                "Shyembe": ["Nyanza", "Shyembe", "Kabeza"],
              },
            },
          },
        },
        "Nyarugenge": {
          "sectors": {
            "Nyamirambo": {
              "cells": {
                "Rwampara": ["Biryogo", "Rwampara", "Nyabugogo"],
                "Nyakabanda": ["Muhima", "Nyakabanda", "Kigali"],
              },
            },
          },
        },
      },
    },
    "Eastern Province": {
      "districts": {
        "Bugesera": {
          "sectors": {
            "Gashora": {
              "cells": {
                "Biryogo": ["Akagera", "Biryogo", "Kabuye"],
                "Kibungo": ["Gashora", "Kibungo", "Nyamata"],
                "Mwendo": ["Karama", "Mwendo", "Ntarama"],
              },
            },
            "Ntarama": {
              "cells": {
                "Cyugaro": ["Cyugaro", "Kabuye", "Ntarama"],
                "Nyamugari": ["Gako", "Mayange", "Nyamugari"],
                "Zaza": ["Rilima", "Ruhuha", "Zaza"],
              },
            },
          },
        },
        "Gatsibo": {
          "sectors": [
            "Gasange",
            "Gatsibo",
            "Gitoki",
            "Kabarore",
            "Kageyo",
            "Kiramuruzi",
            "Kiziguro",
            "Muhura",
            "Murambi",
            "Ngarama",
            "Nyagihanga",
            "Remera",
            "Rugarama",
            "Rwimbogo",
          ],
        },
        "Kayonza": {
          "sectors": [
            "Gahini",
            "Kabare",
            "Kabarondo",
            "Mukarange",
            "Murama",
            "Murundi",
            "Mwiri",
            "Ndego",
            "Nyamirama",
            "Rukara",
            "Ruramira",
            "Rwinkwavu",
          ],
        },
        "Kirehe": {
          "sectors": [
            "Gahara",
            "Gatore",
            "Kigarama",
            "Kigina",
            "Kirehe",
            "Mahama",
            "Mpanga",
            "Musaza",
            "Mushikiri",
            "Nasho",
            "Nyamugari",
            "Nyarubuye",
          ],
        },
        "Ngoma": {
          "sectors": [
            "Gashanda",
            "Jarama",
            "Karembo",
            "Kazo",
            "Kibungo",
            "Mugesera",
            "Murama",
            "Mutenderi",
            "Remera",
            "Rukira",
            "Rukumberi",
            "Rurenge",
            "Sake",
            "Zaza",
          ],
        },
        "Nyagatare": {
          "sectors": [
            "Gatunda",
            "Karama",
            "Karangazi",
            "Katabagemu",
            "Kiyombe",
            "Matimba",
            "Mimuri",
            "Mukama",
            "Musheli",
            "Nyagatare",
            "Rukomo",
            "Rwempasha",
            "Rwimiyaga",
            "Tabagwe",
          ],
        },
        "Rwamagana": {
          "sectors": [
            "Fumbwe",
            "Gahengeri",
            "Gishari",
            "Karenge",
            "Kigabiro",
            "Muhazi",
            "Munyaga",
            "Munyiginya",
            "Musha",
            "Muyumbu",
            "Mwulire",
            "Nzige",
            "Nyakaliro",
            "Rubona",
          ],
        },
      },
    },
    "Northern Province": {
      "districts": {
        "Burera": {
          "sectors": [
            "Bungwe",
            "Butaro",
            "Cyanika",
            "Cyeru",
            "Gahunga",
            "Gatebe",
            "Gitovu",
            "Kagogo",
            "Kinoni",
            "Kinyababa",
            "Kivuye",
            "Nemba",
            "Rugarama",
            "Rugengabari",
            "Ruhunde",
            "Rusarabuye",
            "Rwerere",
          ],
        },
        "Gakenke": {
          "sectors": [
            "Busengo",
            "Coko",
            "Cyabingo",
            "Gakenke",
            "Gashenyi",
            "Mugunga",
            "Janja",
            "Kamubuga",
            "Karambo",
            "Kivuruga",
            "Mataba",
            "Minazi",
            "Muzo",
            "Muyongwe",
            "Muhondo",
            "Nemba",
            "Ruli",
            "Rushashi",
            "Rusasa",
            "Rukara",
          ],
        },
        "Gicumbi": {
          "sectors": [
            "Bukure",
            "Bwisige",
            "Byumba",
            "Cyumba",
            "Giti",
            "Kaniga",
            "Manyagiro",
            "Miyove",
            "Kageyo",
            "Mukarange",
            "Muko",
            "Mutete",
            "Nyamiyaga",
            "Nyankenke",
            "Rubaya",
            "Rukomo",
            "Rushaki",
            "Rutare",
            "Ruvune",
            "Shangasha",
          ],
        },
        "Musanze": {
          "sectors": [
            "Busogo",
            "Cyuve",
            "Gacaca",
            "Gashaki",
            "Gataraga",
            "Kimonyi",
            "Kinigi",
            "Muhoza",
            "Muko",
            "Musanze",
            "Nkotsi",
            "Nyange",
            "Remera",
            "Rwaza",
            "Shingiro",
          ],
        },
        "Rulindo": {
          "sectors": [
            "Base",
            "Burega",
            "Bushoki",
            "Buyoga",
            "Cyinzuzi",
            "Cyungo",
            "Kinihira",
            "Kisaro",
            "Masoro",
            "Mbogo",
            "Murambi",
            "Ngoma",
            "Ntarabana",
            "Rukozo",
            "Rusoza",
            "Shyorongi",
            "Tumba",
          ],
        },
      },
    },
    "Southern Province": {
      "districts": {
        "Gisagara": {
          "sectors": [
            "Gikonko",
            "Gishubi",
            "Kansi",
            "Kibilizi",
            "Kibirizi",
            "Kigembe",
            "Mamba",
            "Muganza",
            "Mugombwa",
            "Mukindo",
            "Musha",
            "Ndora",
            "Nyanza",
            "Save",
          ],
        },
        "Huye": {
          "sectors": [
            "Gishamvu",
            "Karama",
            "Kigoma",
            "Kinazi",
            "Maraba",
            "Mbazi",
            "Mukura",
            "Ngoma",
            "Ruhashya",
            "Rusatira",
            "Rwaniro",
            "Simbi",
            "Tumba",
            "Huye",
          ],
        },
        "Kamonyi": {
          "sectors": [
            "Gacurabwenge",
            "Karama",
            "Kayenzi",
            "Kayumbu",
            "Mugina",
            "Musambira",
            "Ngamba",
            "Nyamiyaga",
            "Nyarubaka",
            "Rugalika",
            "Rugarika",
            "Runda",
          ],
        },
        "Muhanga": {
          "sectors": [
            "Cyeza",
            "Kabacuzi",
            "Kibangu",
            "Kiyumba",
            "Muhanga",
            "Mushishiro",
            "Nyabinoni",
            "Nyamabuye",
            "Nyarusange",
            "Rongi",
            "Rugendabari",
            "Shyogwe",
          ],
        },
        "Nyamagabe": {
          "sectors": [
            "Buruhukiro",
            "Cyanika",
            "Gasaka",
            "Gatare",
            "Kaduha",
            "Kamegeri",
            "Kibumbwe",
            "Kibirizi",
            "Kibumbwe",
            "Kitabi",
            "Mbazi",
            "Mugano",
            "Musange",
            "Musebeya",
            "Mushubi",
            "Nkomane",
            "Tare",
            "Uwinkingi",
          ],
        },
        "Nyanza": {
          "sectors": [
            "Busasamana",
            "Busoro",
            "Cyabakamyi",
            "Kibirizi",
            "Mukingo",
            "Muyira",
            "Ntyazo",
            "Nyagisozi",
            "Rwabicuma",
          ],
        },
        "Nyaruguru": {
          "sectors": [
            "Cyahinda",
            "Busanze",
            "Kibeho",
            "Kivu",
            "Mata",
            "Muganza",
            "Munini",
            "Ngera",
            "Ngoma",
            "Nyabimata",
            "Nyagisozi",
            "Ruheru",
            "Ruramba",
            "Rusenge",
          ],
        },
        "Ruhango": {
          "sectors": [
            "Bweramana",
            "Byimana",
            "Kabagali",
            "Kinazi",
            "Kinihira",
            "Mbuye",
            "Mwendo",
            "Ntongwe",
            "Ruhango",
          ],
        },
      },
    },
    "Western Province": {
      "districts": {
        "Karongi": {
          "sectors": [
            "Bwishyura",
            "Gashari",
            "Gishyita",
            "Gitesi",
            "Mubuga",
            "Murambi",
            "Murundi",
            "Mutuntu",
            "Rubengera",
            "Rugabano",
            "Ruganda",
            "Rwankuba",
            "Twumba",
          ],
        },
        "Ngororero": {
          "sectors": [
            "Bwira",
            "Gatumba",
            "Hindiro",
            "Kabaya",
            "Kageyo",
            "Kavumu",
            "Matyazo",
            "Muhanda",
            "Muhororo",
            "Ndaro",
            "Ngororero",
            "Nyange",
            "Sovu",
          ],
        },
        "Nyabihu": {
          "sectors": [
            "Bigogwe",
            "Jenda",
            "Jomba",
            "Kabatwa",
            "Karago",
            "Kintobo",
            "Mukamira",
            "Muringa",
            "Rambura",
            "Rugera",
            "Rurembo",
            "Shyira",
          ],
        },
        "Nyamasheke": {
          "sectors": [
            "Bushekeri",
            "Bushenge",
            "Cyato",
            "Gihombo",
            "Kagano",
            "Kanjongo",
            "Karambi",
            "Karengera",
            "Kirimbi",
            "Macuba",
            "Mahembe",
            "Nyabitekeri",
            "Rangiro",
            "Ruharambuga",
            "Shangi",
          ],
        },
        "Rubavu": {
          "sectors": [
            "Bugeshi",
            "Busasamana",
            "Cyanzarwe",
            "Gisenyi",
            "Kanama",
            "Kanzenze",
            "Mudende",
            "Nyakiliba",
            "Nyamyumba",
            "Nyundo",
            "Rubavu",
            "Rugerero",
          ],
        },
        "Rusizi": {
          "sectors": [
            "Bugarama",
            "Butare",
            "Bweyeye",
            "Gikundamvura",
            "Gashonga",
            "Giheke",
            "Gihundwe",
            "Gitambi",
            "Kamembe",
            "Muganza",
            "Mururu",
            "Nkanka",
            "Nkombo",
            "Nkungu",
            "Nyakabuye",
            "Nyakarenzo",
            "Nzahaha",
            "Rwimbogo",
          ],
        },
        "Rutsiro": {
          "sectors": [
            "Boneza",
            "Gihango",
            "Kigeyo",
            "Kivumu",
            "Manihira",
            "Mukura",
            "Murunda",
            "Musasa",
            "Mushonyi",
            "Mushubati",
            "Nyabirasi",
            "Ruhango",
            "Rusebeya",
          ],
        },
      },
    },
  };

  static List<String> getProvinces() {
    return data.keys.toList();
  }

  static List<String> getDistricts(String province) {
    if (province.isEmpty || !data.containsKey(province)) return [];
    final provinceData = data[province] as Map<String, dynamic>?;
    final districts = provinceData?['districts'] as Map<String, dynamic>?;
    if (districts == null) return [];
    return districts.keys.toList();
  }

  static List<String> getSectors(String province, String district) {
    if (province.isEmpty || district.isEmpty) return [];
    final provinceData = data[province] as Map<String, dynamic>?;
    final districts = provinceData?['districts'] as Map<String, dynamic>?;
    if (districts == null || !districts.containsKey(district)) return [];
    final districtData = districts[district] as Map<String, dynamic>?;
    if (districtData == null) return [];
    final sectors = districtData['sectors'];
    if (sectors is Map<String, dynamic>) {
      return sectors.keys.toList();
    } else if (sectors is List) {
      return List<String>.from(sectors);
    }
    return [];
  }

  static List<String> getCells(String province, String district, String sector) {
    if (province.isEmpty || district.isEmpty || sector.isEmpty) return [];
    
    try {
      // Access province data
      final provinceEntry = data[province];
      if (provinceEntry == null) return [];
      
      // Access districts
      final districts = provinceEntry['districts'];
      if (districts == null) return [];
      if (districts is! Map) return [];
      
      // Check if district exists
      if (!districts.containsKey(district)) return [];
      final districtEntry = districts[district];
      if (districtEntry == null) return [];
      if (districtEntry is! Map) return [];
      
      // Access sectors
      final sectors = districtEntry['sectors'];
      if (sectors == null) return [];
      
      // If sectors is a List (just sector names), there are no cells
      if (sectors is List) return [];
      
      // If sectors is a Map (nested structure with cells), check for this sector
      if (sectors is! Map) return [];
      
      // Check if sector exists
      if (!sectors.containsKey(sector)) return [];
      final sectorEntry = sectors[sector];
      if (sectorEntry == null) return [];
      if (sectorEntry is! Map) return [];
      
      // Access cells
      final cells = sectorEntry['cells'];
      if (cells == null) return [];
      if (cells is! Map) {
        // Extract cell names from map keys
        final cellList = <String>[];
        cells.forEach((key, value) {
          cellList.add(key.toString());
        });
        return cellList;
      }
      
      return [];
    } catch (e) {
      // Return empty list on any error
      return [];
    }
  }

  static List<String> getVillages(
    String province,
    String district,
    String sector,
    String cell,
  ) {
    if (province.isEmpty ||
        district.isEmpty ||
        sector.isEmpty ||
        cell.isEmpty) return [];

    try {
      // Access province data
      final provinceEntry = data[province];
      if (provinceEntry == null) return [];
      
      // Access districts
      final districts = provinceEntry['districts'];
      if (districts == null) return [];
      if (districts is! Map) return [];
      
      // Check if district exists
      if (!districts.containsKey(district)) return [];
      final districtEntry = districts[district];
      if (districtEntry == null) return [];
      if (districtEntry is! Map) return [];
      
      // Access sectors
      final sectors = districtEntry['sectors'];
      if (sectors == null) return [];
      
      // If sectors is a List, there are no cells/villages
      if (sectors is List) return [];
      
      // If sectors is a Map, check for this sector
      if (sectors is! Map) return [];
      
      // Check if sector exists
      if (!sectors.containsKey(sector)) return [];
      final sectorEntry = sectors[sector];
      if (sectorEntry == null) return [];
      if (sectorEntry is! Map) return [];
      
      // Access cells
      final cells = sectorEntry['cells'];
      if (cells == null) return [];
      if (cells is! Map) {
        // Check if cell exists
        if (!cells.containsKey(cell)) return [];
        final villages = cells[cell];
        if (villages is List) {
          return List<String>.from(villages.map((v) => v.toString()));
        }
      }
      
      return [];
    } catch (e) {
      // Return empty list on any error
      return [];
    }
  }
}
