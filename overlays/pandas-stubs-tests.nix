# pandas-stubs 2.3.3.260113's test suite is stale against the numpy/pandas
# that nixpkgs pairs with python 3.14: 23 of 2196 tests fail on deprecation-
# warning assertions (DID NOT WARN / NumPy 'generic' timedelta deprecation).
# The stubs themselves are fine; skip the checks until nixpkgs ships a newer
# pandas-stubs. pdfplumber (an openviking dependency) pulls pandas-stubs, so
# this unblocks the whole env on the default interpreter.
{
  meta = {
    reason = "pandas-stubs 2.3.3.260113 tests fail against python 3.14's numpy/pandas (23 warning-assertion failures); skip its checks so pdfplumber's chain builds";
    added = "2026-07-13";
    upstream = "https://github.com/pandas-dev/pandas-stubs";
  };
  # Version proxy: a build failure is not eval-visible, so heal on nixpkgs
  # bumping pandas-stubs (an upstream release against current pandas/numpy is
  # the real fix); the heal job's full-check verification decides whether the
  # bump truly builds, and restores this fix if it does not.
  dropWhen = pkgs: pkgs.python3Packages.pandas-stubs.version != "2.3.3.260113";
  overlay = final: prev: {
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (_pyfinal: pyprev: {
        pandas-stubs = pyprev.pandas-stubs.overridePythonAttrs (_old: {
          # Without the test env, pandas (a check-only input) is absent, so
          # the import smoke must go with it.
          doCheck = false;
          pythonImportsCheck = [ ];
        });
      })
    ];
  };
}
