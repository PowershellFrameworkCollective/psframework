# Modules

This folder contains modules included within PSFramework.
If possible, avoid including modules, but when not otherwise possible, this is the place to put them in.

Fundamental rules:

+ MIT License Modules only
+ Only Modules publicly available through Github or similar
+ Modules must be build-able from source without build dependencies
+ No Breaking Change policy applies to these modules as well
+ Must not lead to any runspace-/process-wide conflicts: No DLLs, no Type Extension XML that conflicts on import
+ Only one version of a given module
+ For each module, create a %MODULENAME%.md document besides this readme, describing ...
  + ... what it is needed/used for
  + ... any adjustments made from its source
  + ... where it is from

> Remember

Nested modules are evil and should be avoided!
