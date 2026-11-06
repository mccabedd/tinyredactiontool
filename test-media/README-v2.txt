TRT-Moving-Text-v2.mp4
12 seconds, 640 x 360, 24 fps, 288 frames, H.264 Baseline, YUV 4:2:0, no audio.
Synthetic text TEST ID 4827 follows a smooth curved path and returns to its start.
Verified: full FFmpeg decode; TRT MediaTools timeline and exact-frame loading at
frames 0, 72, 144 and 287; TRT LocalPlayback native frame callbacks advance.
The older sample had a movement calculation error. Use this v2 file instead.
The corruption reported in the user's TRT session was not reproduced locally.