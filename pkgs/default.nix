{
  callPackage,
  nanobrew-src ? null,
}:
{
  nanobrew = callPackage ./nanobrew {
    inherit nanobrew-src;
  };
}
