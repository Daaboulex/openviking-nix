{
  meta = {
    reason = "pandas-stubs' test suite fails at collection under pytest 9.1 (PytestRemovedIn10Warning raised as an error); the stubs themselves are fine and reach this repo only as pdfplumber's nativeCheckInput";
    added = "2026-07-30";
    upstream = "https://github.com/pandas-dev/pandas-stubs";
  };
  dropWhenBuilds = pkgs: pkgs.python3Packages.pandas-stubs;
  overlay = _final: prev: {
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (_pyfinal: pyprev: {
        pandas-stubs = pyprev.pandas-stubs.overridePythonAttrs (_old: {
          doCheck = false;
          pythonImportsCheck = [ ];
        });
      })
    ];
  };
}
