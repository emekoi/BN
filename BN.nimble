version     = "1.1.0"
author      = "Luke Parker/kayabaNerve"
description = "A BigNumber Package for Nim using imath."
license     = "MIT"

installFiles = @[
  "BN.nim",
  "BN/imath.c",
  "BN/imath.h",
  "BN/wrapper.c",
  "BN/wrapper.h"
]

requires "nim >= 0.18.0"