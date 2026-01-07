class VersionComparator {
  static int compare({required String currentVersion, required String latestVersion}) {
    List<int> v1 = latestVersion.split('.').map(int.parse).toList();
    List<int> v2 = currentVersion.split('.').map(int.parse).toList();

    // Major Version vergleichen (erste Zahl)
    if (v1[0] != v2[0]) return v1[0].compareTo(v2[0]);

    // Minor Version vergleichen (zweite Zahl)
    if (v1[1] != v2[1]) return v1[1].compareTo(v2[1]);

    // Patch Version vergleichen (dritte Zahl)
    return v1[2].compareTo(v2[2]);
  }

  static bool isHigher({required String currentVersion, required String latestVersion}) {
    return compare(currentVersion: currentVersion, latestVersion: latestVersion) > 0;
  }
}
