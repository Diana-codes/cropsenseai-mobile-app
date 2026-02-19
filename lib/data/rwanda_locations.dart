class RwandaLocations {
  static const Map<String, Map<String, dynamic>> data = {
    "Eastern Province": {
      "districts": {
        "Bugesera": {
          "sectors": {
            "Gashora": {
              "cells": {
                "Biryogo": ["Akagera", "Biryogo", "Kabuye"],
                "Kibungo": ["Gashora", "Kibungo", "Nyamata"],
                "Mwendo": ["Karama", "Mwendo", "Ntarama"]
              }
            },
            "Ntarama": {
              "cells": {
                "Cyugaro": ["Cyugaro", "Kabuye", "Ntarama"],
                "Nyamugari": ["Gako", "Mayange", "Nyamugari"],
                "Zaza": ["Rilima", "Ruhuha", "Zaza"]
              }
            }
          }
        }
      }
    },
    "Kigali City": {
      "districts": {
        "Gasabo": {
          "sectors": {
            "Bumbogo": {
              "cells": {
                "Nyamugari": ["Kabuga", "Nyamugari", "Rugende"],
                "Bisebeye": ["Bisebeye", "Gasura", "Nyagatare"],
                "Rusagara": ["Rusagara", "Kabeza", "Gasagara"]
              }
            },
            "Remera": {
              "cells": {
                "Rukiri I": ["Agatare", "Kabeza", "Nyabisindu"],
                "Rukiri II": ["Gikondo", "Kacyiru", "Remera"],
                "Nyarurama": ["Amahoro", "Kimironko", "Nyarurama"]
              }
            }
          }
        },
        "Kicukiro": {
          "sectors": {
            "Gahanga": {
              "cells": {
                "Akabahizi": ["Akabahizi", "Gahanga", "Masaka"],
                "Shyembe": ["Nyanza", "Shyembe", "Kabeza"]
              }
            }
          }
        }
      }
    },
    "Southern Province": {
      "districts": {
        "Huye": {
          "sectors": {
            "Gishamvu": {
              "cells": {
                "Gasumba": ["Gasumba", "Gishamvu", "Karama"],
                "Kigarama": ["Kigarama", "Maraba", "Mbazi"]
              }
            }
          }
        }
      }
    }
  };

  static List<String> getProvinces() {
    return data.keys.toList();
  }

  static List<String> getDistricts(String province) {
    if (province.isEmpty || !data.containsKey(province)) return [];
    return (data[province]!['districts'] as Map<String, dynamic>).keys.toList();
  }

  static List<String> getSectors(String province, String district) {
    if (province.isEmpty || district.isEmpty) return [];
    final districts = data[province]?['districts'] as Map<String, dynamic>?;
    if (districts == null || !districts.containsKey(district)) return [];
    return (districts[district]['sectors'] as Map<String, dynamic>).keys.toList();
  }

  static List<String> getCells(String province, String district, String sector) {
    if (province.isEmpty || district.isEmpty || sector.isEmpty) return [];
    final districts = data[province]?['districts'] as Map<String, dynamic>?;
    if (districts == null) return [];
    final sectors = districts[district]?['sectors'] as Map<String, dynamic>?;
    if (sectors == null || !sectors.containsKey(sector)) return [];
    return (sectors[sector]['cells'] as Map<String, dynamic>).keys.toList();
  }

  static List<String> getVillages(
      String province, String district, String sector, String cell) {
    if (province.isEmpty ||
        district.isEmpty ||
        sector.isEmpty ||
        cell.isEmpty) return [];
    final districts = data[province]?['districts'] as Map<String, dynamic>?;
    if (districts == null) return [];
    final sectors = districts[district]?['sectors'] as Map<String, dynamic>?;
    if (sectors == null) return [];
    final cells = sectors[sector]?['cells'] as Map<String, dynamic>?;
    if (cells == null || !cells.containsKey(cell)) return [];
    return List<String>.from(cells[cell] as List);
  }
}
