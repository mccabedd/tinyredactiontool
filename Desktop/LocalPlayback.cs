using System.Diagnostics;
using System.IO;
using System.Globalization;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text.Json;
using System.Windows;
using System.Windows.Media.Imaging;
using LibVLCSharp.Shared;

namespace TinyRedaction.Desktop;

// Native video/audio presentation owns timing. This adapter never extracts frames with FFmpeg.
// The callback output is deliberately CPU-rendered and capped at 1280px for bounded WPF transfers.
public sealed class LocalPlayback : IDisposable
{
    private readonly Lazy<LibVLC> engine;
    private LibVLCSharp.Shared.MediaPlayer? player;
    private Media? media;
    private StreamMediaInput? input;
    private FileStream? stream;
    private readonly IntPtr[] buffers = new IntPtr[8];
    private readonly bool[] occupied = new bool[8];
    private IntPtr shutdownBuffer;
    private bool stopping;
    private byte[] pixels = [];
    private readonly object frameLock = new();
    private int width, height, pitch;
    private bool dirty;
    private double speed = 1;
    private long displayed;
    private double presentedTime;
    private double nativeClockSeconds;
    private long clockTicks;
    private bool haveClock, wantPlaying, buffering, clockRunning;
    // 0.21.2 (David: "freezes, then jumps"): after a seek the engine decodes from the previous keyframe, which can
    // take seconds, while this clock ran on; the first new picture then showed a later time than it was. Now the
    // clock waits for that first picture and starts from the seek target.
    private bool awaitingFrame;
    // Starting at a speed other than 1x right after a seek stalled the engine for about 1.8 s on a phone video
    // (probed in 0.21.2; changing speed while playing did not). So playback after a seek starts at 1x and
    // switches to the chosen speed when the first picture arrives; the clock follows the engine's actual rate.
    private double clockSpeed = 1;
    private double? deferredSpeed;
    private int framesSinceSeek;
    private long firstFrameTicks;
    private const double SettleSeconds = 0.2;
    private double EstimateClock() => nativeClockSeconds + (haveClock && clockRunning && !awaitingFrame ? Math.Max(0, (Stopwatch.GetTimestamp() - clockTicks) / (double)Stopwatch.Frequency) * clockSpeed : 0);
    private void SetClockRunning(bool running)
    {
        // Preserve elapsed time across buffering, pause and resume transitions.
        nativeClockSeconds = EstimateClock(); clockTicks = Stopwatch.GetTimestamp(); clockRunning = running;
    }
    private long requestedMilliseconds;
    private readonly LibVLCSharp.Shared.MediaPlayer.LibVLCVideoLockCb lockCallback;
    private readonly LibVLCSharp.Shared.MediaPlayer.LibVLCVideoUnlockCb unlockCallback;
    private readonly LibVLCSharp.Shared.MediaPlayer.LibVLCVideoDisplayCb displayCallback;

    public event EventHandler? FrameAvailable;
    public event EventHandler? MediaOpened;
    public event EventHandler? MediaEnded;
    public event EventHandler? MediaFailed;
    public string? LastError { get; private set; }
    public bool IsLoaded => player != null;
    public int FrameWidth => width;
    public int FrameHeight => height;
    public long DisplayedFrames => Interlocked.Read(ref displayed);
    public bool HasAudioTrack => (player?.AudioTrackCount ?? 0) > 0;
    public int DecodedAudioBlocks => media?.Statistics.DecodedAudio ?? 0;
    public double PresentedTime { get { lock (frameLock) return presentedTime; } }
    // While paused, a new position is only remembered (0.21.2): every frame step and slider move used to make the
    // engine seek and decode in the background, competing with the exact-frame decoding, and Play then sought again.
    // Play seeks once, and not at all when the engine is already within 0.15 s of the place.
    private bool seekPending;
    internal const double ResumeTolerance = 0.15;
    public TimeSpan Position
    {
        get => TimeSpan.FromMilliseconds(seekPending || player == null ? Interlocked.Read(ref requestedMilliseconds) : Math.Max(0, player.Time));
        set
        {
            var seconds = Math.Max(0, value.TotalSeconds);
            Interlocked.Exchange(ref requestedMilliseconds, (long)(seconds * 1000));
            lock (frameLock) { nativeClockSeconds = seconds; clockTicks = Stopwatch.GetTimestamp(); haveClock = true; clockRunning = false; presentedTime = seconds; }
            if (player == null) return;
            if (player.IsPlaying) { lock (frameLock) awaitingFrame = true; player.Time = (long)(seconds * 1000); seekPending = false; }
            else seekPending = true;
        }
    }
    // Changing speed while playing is a plain rate change; probes on a phone video and a screen recording (0.21.2)
    // showed that seeking or pausing around it only added freezes.
    public double SpeedRatio
    {
        get => speed;
        set
        {
            if (!double.IsFinite(value) || value is < 0.25 or > 2) throw new ArgumentOutOfRangeException(nameof(value));
            lock (frameLock) { nativeClockSeconds = EstimateClock(); clockTicks = Stopwatch.GetTimestamp(); speed = clockSpeed = value; deferredSpeed = null; }
            if (player != null && player.SetRate((float)value) != 0) throw new InvalidOperationException("Playback engine rejected this speed.");
        }
    }
    // Diagnostics only: the sound is decoded and timed as usual but not heard.
    internal bool Muted { get; set; }
    public LocalPlayback(bool silentTestOutput = false)
    {
        var options = new List<string> { "--ignore-config", "--no-video-title-show", "--no-osd", "--no-spu", "--no-sub-autodetect-file", "--no-metadata-network-access", "--no-media-library", "--no-plugins-cache", "--avcodec-hw=none", "--no-stats", "--quiet" };
        if (silentTestOutput) { options.Add("--aout=dummy"); options.Add("--stats"); }        engine = new Lazy<LibVLC>(() => { NativePlaybackRuntime.Initialize(); return new LibVLC(options.ToArray()); });
        lockCallback = LockVideo; unlockCallback = UnlockVideo; displayCallback = DisplayVideo;
    }
    public void Open(string path, int canonicalWidth, int canonicalHeight)
    {
        Close();
        if (!Path.IsPathFullyQualified(path) || !File.Exists(path)) throw new IOException("Playback requires an existing local filesystem source.");
        var scale = Math.Min(1, 1280d / Math.Max(canonicalWidth, canonicalHeight));
        width = Math.Max(1, (int)Math.Round(canonicalWidth * scale));
        height = Math.Max(1, (int)Math.Round(canonicalHeight * scale)); pitch = checked(width * 4);
        pixels = new byte[checked(pitch * height)];
        try
        {
            for (var i = 0; i < buffers.Length; i++) buffers[i] = Marshal.AllocHGlobal(pixels.Length);
            shutdownBuffer = Marshal.AllocHGlobal(pixels.Length);
            stopping = false;
            // No media URL is passed to libVLC. Managed callbacks read only this already-open file.
            stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 65536, FileOptions.RandomAccess);
            input = new StreamMediaInput(stream);
            media = new Media(engine.Value, input);
            media.AddOption(":video-track=0"); media.AddOption(":audio-track=0");
            player = new LibVLCSharp.Shared.MediaPlayer(engine.Value);
            player.AspectRatio = canonicalWidth + ":" + canonicalHeight;
            player.SetVideoFormat("RV32", (uint)width, (uint)height, (uint)pitch);
            player.SetVideoCallbacks(lockCallback, unlockCallback, displayCallback);
            player.TimeChanged += (_, e) =>
            {
                lock (frameLock)
                {
                    var seconds = Math.Max(0, e.Time / 1000d);
                    // Some silent MP4 inputs repeat an old native time while
                    // presenting new frames. Never rewind the live clock for it.
                    if (!awaitingFrame && seconds > EstimateClock()) { nativeClockSeconds = seconds; clockTicks = Stopwatch.GetTimestamp(); }
                    haveClock = true;
                }
            };
            player.Buffering += (_, e) => { lock (frameLock) { buffering = e.Cache < 100; SetClockRunning(wantPlaying && !buffering && haveClock); } };
            player.Playing += (_, _) => { lock (frameLock) { haveClock = true; SetClockRunning(wantPlaying && !buffering); } MediaOpened?.Invoke(this, EventArgs.Empty); };
            player.Paused += (_, _) => { lock (frameLock) SetClockRunning(false); };
            player.EndReached += (_, _) => { lock (frameLock) { SetClockRunning(false); wantPlaying = false; } MediaEnded?.Invoke(this, EventArgs.Empty); };
            player.EncounteredError += (_, _) => { LastError = "The private playback decoder could not decode this source."; MediaFailed?.Invoke(this, EventArgs.Empty); };
            player.Media = media;
            presentedTime = 0; nativeClockSeconds = 0; clockTicks = Stopwatch.GetTimestamp(); haveClock = false; wantPlaying = false; buffering = false; clockRunning = false; awaitingFrame = false; seekPending = false; displayed = 0; LastError = null;
        }
        catch { Close(); throw; }
    }
    public void Play()
    {
        if (player == null) return;
        lock (frameLock) wantPlaying = true;
        if (player.State == VLCState.Ended)
        {
            player.Stop(); Interlocked.Exchange(ref requestedMilliseconds, 0);
            lock (frameLock) { presentedTime = 0; }
        }
        if (Muted) player.Mute = true;
        var target = Interlocked.Read(ref requestedMilliseconds) / 1000d;
        var starting = !player.IsPlaying && player.State is VLCState.Stopped or VLCState.NothingSpecial;
        var seeking = !starting && seekPending && Math.Abs(Math.Max(0, player.Time) / 1000d - target) > ResumeTolerance;
        var engineSpeed = (starting || seeking) && speed != 1 ? 1 : speed;
        lock (frameLock) { clockSpeed = engineSpeed; deferredSpeed = engineSpeed != speed ? speed : null; framesSinceSeek = 0; firstFrameTicks = Stopwatch.GetTimestamp(); if (starting || seeking) awaitingFrame = true; }
        player.SetRate((float)engineSpeed);
        if (starting)
        {
            media!.AddOption(":start-time=" + target.ToString(CultureInfo.InvariantCulture));
            if (!player.Play()) throw new InvalidOperationException("Playback did not start.");
        }
        else if (seeking) player.Time = (long)(target * 1000);
        else if (seekPending) lock (frameLock) { nativeClockSeconds = Math.Max(0, player.Time) / 1000d; clockTicks = Stopwatch.GetTimestamp(); } // Resume where the engine is.
        seekPending = false;
        player.SetPause(false);
    }
    private void ApplySpeed(double chosen)
    {
        lock (frameLock)
        {
            if (stopping || speed != chosen) return; // Closed, or another speed was chosen meanwhile.
            nativeClockSeconds = EstimateClock(); clockTicks = Stopwatch.GetTimestamp(); clockSpeed = chosen;
        }
        try { player?.SetRate((float)chosen); } catch (Exception ex) when (ex is ObjectDisposedException or NullReferenceException) { } // Closed meanwhile.
    }
    public void Pause()
    {
        if (player == null) return;
        lock (frameLock) { SetClockRunning(false); wantPlaying = false; }
        player.SetPause(true);
    }
    private IntPtr LockVideo(IntPtr opaque, IntPtr planes)
    {
        lock (frameLock)
        {
            while (!stopping)
            {
                for (var i = 0; i < buffers.Length; i++)
                    if (!occupied[i]) { occupied[i] = true; Marshal.WriteIntPtr(planes, buffers[i]); return buffers[i]; }
                Monitor.Wait(frameLock);
            }
            Marshal.WriteIntPtr(planes, shutdownBuffer); return shutdownBuffer;
        }
    }
    private void UnlockVideo(IntPtr opaque, IntPtr picture, IntPtr planes)
    { /* Decode completion is not presentation. Keep this picture until Display. */ }
    private void DisplayVideo(IntPtr opaque, IntPtr picture)
    {
        lock (frameLock)
        {
            if (stopping) return;
            var index = Array.IndexOf(buffers, picture);
            if (index < 0) return;
            Marshal.Copy(picture, pixels, 0, pixels.Length);
            occupied[index] = false; Monitor.PulseAll(frameLock);
            dirty = true;
            // No calls into libVLC from a video callback: native Stop can hold
            // the player lock while waiting for this callback to return.
            // The first picture after a seek starts the clock at the place asked for.
            if (awaitingFrame) { awaitingFrame = false; nativeClockSeconds = Interlocked.Read(ref requestedMilliseconds) / 1000d; clockTicks = firstFrameTicks = Stopwatch.GetTimestamp(); }
            presentedTime = EstimateClock();
            // Now switch to the chosen speed, on another thread (see above).
            // The first pictures can still belong to the seek; switching on the first one stalled the engine again,
            // so wait for two pictures and 0.2 s (probed on a 30 fps phone video).
            if (deferredSpeed is { } chosen && ++framesSinceSeek >= 2 && (Stopwatch.GetTimestamp() - firstFrameTicks) / (double)Stopwatch.Frequency >= SettleSeconds) { deferredSpeed = null; ThreadPool.QueueUserWorkItem(_ => ApplySpeed(chosen)); }
        }
        Interlocked.Increment(ref displayed);
        FrameAvailable?.Invoke(this, EventArgs.Empty);
    }
    public bool CopyLatest(WriteableBitmap destination, out double timestamp)
    {
        lock (frameLock)
        {
            timestamp = presentedTime;
            if (!dirty || destination.PixelWidth != width || destination.PixelHeight != height) return false;
            destination.WritePixels(new Int32Rect(0, 0, width, height), pixels, pitch, 0); dirty = false; return true;
        }
    }
    public byte[] SnapshotPixels()
    { lock (frameLock) return (byte[])pixels.Clone(); }
    public void Close()
    {
        lock (frameLock) { stopping = true; wantPlaying = false; clockRunning = false; Monitor.PulseAll(frameLock); }
        player?.Stop(); player?.Dispose(); player = null; requestedMilliseconds = 0;
        media?.Dispose(); media = null; input?.Dispose(); input = null; stream?.Dispose(); stream = null;
        for (var i = 0; i < buffers.Length; i++)
        { if (buffers[i] != IntPtr.Zero) Marshal.FreeHGlobal(buffers[i]); buffers[i] = IntPtr.Zero; occupied[i] = false; }
        if (shutdownBuffer != IntPtr.Zero) { Marshal.FreeHGlobal(shutdownBuffer); shutdownBuffer = IntPtr.Zero; }
        lock (frameLock) { pixels = []; dirty = false; }
    }
    public void Dispose() { Close(); if (engine.IsValueCreated) engine.Value.Dispose(); }
}

internal static class NativePlaybackRuntime
{
    private static readonly object gate = new();
    private static readonly List<FileStream> leases = [];
    private static bool initialized;
    internal static void Initialize()
    {
        lock (gate)
        {
            if (initialized) return;
            var root = Path.Combine(AppContext.BaseDirectory, "native");
            using var resource = Assembly.GetExecutingAssembly().GetManifestResourceStream("native-manifest.json") ?? throw new InvalidDataException("Native playback manifest missing.");
            var manifest = JsonSerializer.Deserialize<Dictionary<string, string>>(resource) ?? throw new InvalidDataException("Native playback manifest invalid.");
            var actual = Directory.EnumerateFiles(root, "*.dll", SearchOption.AllDirectories).Select(p => Path.GetRelativePath(root, p).Replace('\\', '/')).ToHashSet(StringComparer.OrdinalIgnoreCase);
            if (!actual.SetEquals(manifest.Keys)) throw new InvalidDataException("Unexpected or missing playback native modules. Startup blocked.");
            try
            {
                foreach (var (relative, hash) in manifest)
                {
                    var path = Path.GetFullPath(Path.Combine(root, relative));
                    if (!path.StartsWith(Path.GetFullPath(root) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Invalid native manifest path.");
                    var file = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read); leases.Add(file);
                    if (!Convert.ToHexString(SHA256.HashData(file)).Equals(hash, StringComparison.OrdinalIgnoreCase)) throw new InvalidDataException("Playback native hash mismatch. Startup blocked.");
                }
                Environment.SetEnvironmentVariable("VLC_PLUGIN_PATH", Path.Combine(root, "plugins"));
                LibVLCSharp.Shared.Core.Initialize(root);
                initialized = true;
            }
            catch { foreach (var file in leases) file.Dispose(); leases.Clear(); throw; }
        }
    }
}
