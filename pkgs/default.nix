{
  callPackage,
  zig ? null,
  nanobrew-src ? null,
}:
{
  nanobrew = callPackage ./nanobrew {
    inherit zig nanobrew-src;
  };
}
