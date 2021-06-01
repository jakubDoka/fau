version       = "0.0.1"
author        = "Anuken"
description   = "WIP Nim game framework"
license       = "MIT"
srcDir        = ""
bin           = @["tools/faupack", "tools/antialias", "tools/fauproject"]
binDir        = "build"

requires "nim >= 1.4.2"
requires "https://github.com/rlipsc/polymorph#d29924c9824940649a30bdf2a4de0575d6a5758b"
requires "https://github.com/treeform/staticglfw#d299a0d1727054749100a901d3b4f4fa92ed72f5"
requires "cligen >= 1.3.2"
requires "chroma >= 0.2.5"
requires "pixie >= 2.0.2"
requires "vmath >= 1.0.8"
requires "stbimage >= 2.5"