using System.Buffers.Binary;
using System.IO;
using System.Text;

namespace TinyRedaction.Desktop;

// Minimal forward-only Matroska transport for independently encoded PNG frames.
// Not a general muxer. One track, one keyframe per cluster, no seeking/lacing.
// Microsecond timestamps and explicit BlockDuration preserve variable frame timing.
internal sealed class TimestampedPngStream(Stream output)
{
    private static void Id(Stream stream, uint id)
    {
        Span<byte> bytes = stackalloc byte[4]; BinaryPrimitives.WriteUInt32BigEndian(bytes, id);
        var start = 0; while (start < 3 && bytes[start] == 0) start++; stream.Write(bytes[start..]);
    }
    private static void Size(Stream stream, ulong value)
    {
        var length = 1; while (length < 8 && value >= (1UL << (7 * length)) - 1) length++;
        if (value >= (1UL << 56) - 1) throw new InvalidDataException("Transport element is too large.");
        Span<byte> bytes = stackalloc byte[8]; var encoded = value | (1UL << (7 * length));
        BinaryPrimitives.WriteUInt64BigEndian(bytes, encoded); stream.Write(bytes[(8 - length)..]);
    }
    private static byte[] Element(uint id, byte[] value)
    { using var stream = new MemoryStream(); Id(stream, id); Size(stream, (ulong)value.Length); stream.Write(value); return stream.ToArray(); }
    private static byte[] Master(uint id, params byte[][] elements) => Element(id, elements.SelectMany(e => e).ToArray());
    private static byte[] Number(uint id, ulong value)
    {
        Span<byte> bytes = stackalloc byte[8]; BinaryPrimitives.WriteUInt64BigEndian(bytes, value);
        var start = 0; while (start < 7 && bytes[start] == 0) start++; return Element(id, bytes[start..].ToArray());
    }
    private static byte[] Text(uint id, string value) => Element(id, Encoding.ASCII.GetBytes(value));
    public async Task BeginAsync(int width, int height, double duration, double lastDuration, CancellationToken cancellation)
    {
        var ebml = Master(0x1A45DFA3, Number(0x4286, 1), Number(0x42F7, 1), Number(0x42F2, 4), Number(0x42F3, 8), Text(0x4282, "matroska"), Number(0x4287, 4), Number(0x4285, 2));
        var floatBytes = new byte[8]; BinaryPrimitives.WriteInt64BigEndian(floatBytes, BitConverter.DoubleToInt64Bits(duration * 1_000_000));
        var info = Master(0x1549A966, Number(0x2AD7B1, 1000), Text(0x4D80, "TRT"), Text(0x5741, "TRT"), Element(0x4489, floatBytes));
        byte[] bitmapInfo;
        using (var memory = new MemoryStream())
        {
            using var writer = new BinaryWriter(memory, Encoding.ASCII, true);
            writer.Write(40); writer.Write(width); writer.Write(height); writer.Write((short)1); writer.Write((short)32); writer.Write("MPNG"u8); writer.Write(checked(width * height * 4));
            writer.Write(0); writer.Write(0); writer.Write(0); writer.Write(0); bitmapInfo = memory.ToArray();
        }
        var tracks = Master(0x1654AE6B, Master(0xAE, Number(0xD7, 1), Number(0x73C5, 1), Number(0x83, 1), Number(0x9C, 0),
            Number(0x23E383, (ulong)Math.Max(1, Math.Round(lastDuration * 1_000_000_000))), Text(0x86, "V_MS/VFW/FOURCC"), Element(0x63A2, bitmapInfo),
            Master(0xE0, Number(0xB0, (ulong)width), Number(0xBA, (ulong)height))));
        using var header = new MemoryStream(); header.Write(ebml); Id(header, 0x18538067);
        // Unknown segment length permits a streaming, non-seekable sink.
        header.Write(new byte[] { 1, 255, 255, 255, 255, 255, 255, 255 }); header.Write(info); header.Write(tracks);
        await output.WriteAsync(header.ToArray(), cancellation);
    }
    public async Task FrameAsync(ReadOnlyMemory<byte> png, long timestamp, long duration, CancellationToken cancellation)
    {
        var stamp = Number(0xE7, checked((ulong)timestamp)); var frameDuration = Number(0x9B, checked((ulong)duration));
        using var blockPrefix = new MemoryStream(); Id(blockPrefix, 0xA1); Size(blockPrefix, (ulong)png.Length + 4); blockPrefix.Write(new byte[] { 0x81, 0, 0, 0 });
        var groupSize = (ulong)blockPrefix.Length + (ulong)png.Length + (ulong)frameDuration.Length;
        using var groupPrefix = new MemoryStream(); Id(groupPrefix, 0xA0); Size(groupPrefix, groupSize); groupPrefix.Write(blockPrefix.ToArray());
        using var prefix = new MemoryStream(); Id(prefix, 0x1F43B675); Size(prefix, (ulong)stamp.Length + (ulong)groupPrefix.Length + (ulong)png.Length + (ulong)frameDuration.Length);
        prefix.Write(stamp); prefix.Write(groupPrefix.ToArray());
        await output.WriteAsync(prefix.ToArray(), cancellation); await output.WriteAsync(png, cancellation); await output.WriteAsync(frameDuration, cancellation);
    }
}
