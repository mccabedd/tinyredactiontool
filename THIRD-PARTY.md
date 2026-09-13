# Third-Party Software and Licences

TinyRedactionTool includes or is built with third-party open-source software.

## TinyRedactionTool

Copyright (C) 2026 David McCabe

TinyRedactionTool is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 2 of the License, or (at your option) any
later version.

SPDX-License-Identifier: GPL-2.0-or-later

The full GNU GPL version 2 text is provided in the repository's `LICENSE` file.

---

## FFmpeg

Project: FFmpeg
Website: https://ffmpeg.org/
Source: https://github.com/FFmpeg/FFmpeg

TinyRedactionTool uses a custom static build of FFmpeg.

FFmpeg is normally licensed under the GNU Lesser General Public License
version 2.1 or later. When built with GPL components such as libx264 and with
`--enable-gpl`, the resulting FFmpeg binary is licensed under the GNU General
Public License version 2 or later.

The TinyRedactionTool FFmpeg build uses GPL-enabled components and therefore
reports its licence as:

**GNU General Public License version 2 or later (GPL-2.0-or-later).**

SPDX-License-Identifier: GPL-2.0-or-later

FFmpeg copyright belongs to the FFmpeg developers and contributors. The full
GNU GPL version 2 licence text is provided in this repository's `LICENSE`
file.

---

## x264

Project: x264
Website: https://www.videolan.org/developers/x264.html
Source: https://code.videolan.org/videolan/x264

x264 is used by TinyRedactionTool's custom FFmpeg build for H.264 video
encoding.

x264 is licensed under the GNU General Public License version 2 or later. A
separate commercial licence is also available from x264 LLC for parties who
do not wish to be bound by the GPL; TinyRedactionTool uses the GPL-licensed
build.

SPDX-License-Identifier: GPL-2.0-or-later

Copyright belongs to the x264 authors and contributors.

The GNU GPL version 2 licence text is provided in this repository's `LICENSE`
file.

---

## libvpx

Project: libvpx
Source: https://github.com/webmproject/libvpx

libvpx is used by TinyRedactionTool's custom FFmpeg build for VP9 video
encoding.

libvpx is distributed under a BSD 3-Clause-style licence and includes an
additional patent grant.

SPDX-License-Identifier: BSD-3-Clause

### libvpx licence notice

Copyright (c) 2010, The WebM Project authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
- Neither the name of Google, nor the WebM Project, nor the names of its
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

The libvpx patent grant is available at:

https://github.com/webmproject/libvpx/blob/main/PATENTS

---

## Opus / libopus

Project: Opus
Website: https://opus-codec.org/
Source: https://github.com/xiph/opus

libopus is used by TinyRedactionTool's custom FFmpeg build for Opus audio
encoding in WebM output.

SPDX-License-Identifier: BSD-3-Clause

### libopus licence notice

Copyright 2001-2023 Xiph.Org, Skype Limited, Octasic,
Jean-Marc Valin, Timothy B. Terriberry, CSIRO, Gregory Maxwell,
Mark Borgerding, Erik de Castro Lopo, Mozilla, Amazon

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
- Neither the name of Internet Society, IETF or IETF Trust, nor the names of
  specific contributors, may be used to endorse or promote products derived
  from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Opus is also subject to royalty-free patent licences documented by the Opus
project:

https://opus-codec.org/license/

---

## libwebp

Project: libwebp
Source: https://github.com/webmproject/libwebp

libwebp is used by TinyRedactionTool's custom FFmpeg build for WebP image
encoding and decoding.

SPDX-License-Identifier: BSD-3-Clause

### libwebp licence notice

Copyright (c) 2010, Google Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
- Neither the name of Google nor the names of its contributors may be used to
  endorse or promote products derived from this software without specific
  prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

The libwebp patent grant is available at:

https://github.com/webmproject/libwebp/blob/main/PATENTS

---

## zlib

Project: zlib
Website: https://zlib.net/
Source: https://github.com/madler/zlib

TinyRedactionTool's custom FFmpeg/FFprobe build is linked statically
(`--extra-ldflags='-static'`), and the build toolchain explicitly installs
zlib (`mingw-w64-ucrt-x86_64-zlib`) as a build dependency. zlib is compiled
directly into the embedded `ffmpeg.exe`/`ffprobe.exe` binaries, where it is
used internally by FFmpeg's PNG encoder/decoder and related codec paths.

SPDX-License-Identifier: Zlib

### zlib licence notice

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software in a
   product, an acknowledgment in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

Jean-loup Gailly (jloup@gzip.org) and Mark Adler (madler@alumni.caltech.edu)

---

## MinGW-w64 Runtime and GCC Runtime Library

Project: MinGW-w64
Website: https://www.mingw-w64.org/
Source: https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/

TinyRedactionTool's custom FFmpeg/FFprobe build is compiled with the
MinGW-w64 GCC toolchain (`mingw-w64-ucrt-x86_64-gcc` and related packages)
and linked statically, so the resulting Windows binaries include:

- **The MinGW-w64 runtime and headers.** These are contributed under a mix of
  predominantly Public Domain and MIT-style terms across the project's
  various components. See the canonical licence summary at:
  https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/COPYING

- **GCC's runtime support library (libgcc, and any other GCC runtime
  components pulled in by static linking).** GCC itself is licensed under
  the GNU General Public License version 3. However, libgcc and the other
  runtime libraries distributed with GCC are licensed under GPLv3 **with the
  GCC Runtime Library Exception, version 3.1**. This exception specifically
  permits compiled programs to statically or dynamically link against these
  runtime components without the resulting program being subject to GPLv3,
  provided the conditions of the exception are met. The full exception text
  is available at:
  https://www.gnu.org/licenses/gcc-exception-3.1.en.html

No part of GCC's own GPLv3-licensed compiler source is distributed with
TinyRedactionTool; only the excepted runtime support libraries are present,
compiled into the embedded FFmpeg/FFprobe binaries as an ordinary consequence
of using the MinGW-w64 toolchain to build them.

---

## PS2EXE

Project: PS2EXE
Source: https://github.com/MScholtes/PS2EXE

PS2EXE is used as a build tool to package the PowerShell application into a
Windows executable.

The current PS2EXE repository carries the **Microsoft Limited Public License
version 1.1**.

PS2EXE remains copyright of its respective authors and contributors. Refer to
the upstream repository for the complete licence text:

https://github.com/MScholtes/PS2EXE/blob/master/LICENSE

---

## MSYS2 and Build Toolchain

The optional custom-FFmpeg build process uses MSYS2 and packages supplied
through the MSYS2 environment.

MSYS2 itself and the packages it distributes are separate projects with their
own respective licences. They are used to build FFmpeg and are not bundled as
the TinyRedactionTool runtime environment.

MSYS2: https://www.msys2.org/

---

## Source Availability

TinyRedactionTool's PowerShell source and build scripts are intended to be
kept alongside distributed releases so that the standalone executable can be
rebuilt.

The custom FFmpeg build scripts identify and obtain the corresponding
upstream open-source components used to build the embedded FFmpeg binary,
pinned to a specific upstream FFmpeg source commit and a specific MSYS2
package snapshot (see `SECURITY-AUDIT.md` for the exact pinned commit hash
and archive hash). Those upstream projects' own repositories remain the
canonical source for the pinned revisions used.

Third-party projects retain their own copyrights, trademarks, licence terms
and patent grants.

---

This file is provided as a practical third-party attribution summary and is
not legal advice.
