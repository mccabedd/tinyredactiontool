using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

// 3.2.0 (David): Auto redaction colour, pictures read by Windows, the line width / Auto colour / tray click settings,
// the File-Edit-View-Redact-Draw menu order, Solid Fill / Blur Fill / Pixelate Fill, the paint-bucket and filled shape
// icons, larger Clear icons. (The New Image fix is checked in Release026Checks.) `--release-320-only` runs these.
internal static class Release320Checks
{
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(3);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("3.2.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static byte[] Pixels(BitmapSource source)
    { var converted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0); var bytes = new byte[source.PixelWidth * source.PixelHeight * 4]; converted.CopyPixels(bytes, source.PixelWidth * 4, 0); return bytes; }
    private static void Fill(byte[] p, int w, int x0, int y0, int x1, int y1, Color c)
    { for (var y = y0; y < y1; y++) for (var x = x0; x < x1; x++) { var o = (y * w + x) * 4; p[o] = c.B; p[o + 1] = c.G; p[o + 2] = c.R; p[o + 3] = c.A; } }
    internal static readonly Color Blue = Color.FromRgb(0x9F, 0xC5, 0xE8), Pink = Color.FromRgb(0xF4, 0xB6, 0xB6);
    // Light blue on the left, pink on the right, black "text" bars on each.
    internal static BitmapSource TextPicture()
    {
        const int w = 300, h = 120; var p = new byte[w * h * 4];
        Fill(p, w, 0, 0, 150, h, Blue); Fill(p, w, 150, 0, w, h, Pink);
        for (var line = 0; line < 3; line++) { Fill(p, w, 45, 50 + line * 7, 105, 54 + line * 7, Colors.Black); Fill(p, w, 195, 50 + line * 7, 255, 54 + line * 7, Colors.Black); }
        var image = BitmapSource.Create(w, h, 96, 96, PixelFormats.Bgra32, null, p, w * 4); image.Freeze(); return image;
    }
    private static string Hex(Color c) => $"#{c.R:X2}{c.G:X2}{c.B:X2}";

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- Auto colour sampling (no editor) ----
        var picture = TextPicture();
        var box = new Region { Shape = RegionShape.Rectangle }; box.PutManual(0, new MediaRect(40, 44, 70, 30));
        check(AutoColour.Sample(picture, box, 0) == Hex(Blue), $"Auto colour finds the light blue around black text, not a dark average ({AutoColour.Sample(picture, box, 0)})");
        var oval = new Region { Shape = RegionShape.Oval, Rotation = 20 }; oval.PutManual(0, new MediaRect(185, 40, 80, 40));
        check(AutoColour.Sample(picture, oval, 0) == Hex(Pink), "an oval (turned) on the pink side takes the pink");
        var polygon = new Region { Shape = RegionShape.Polygon, Polygon = [new(0, 0), new(1, 0.2), new(0.6, 1)] }; polygon.PutManual(0, new MediaRect(40, 40, 70, 40));
        check(AutoColour.Sample(picture, polygon, 0) == Hex(Blue), "a polygon takes the colour along its own edge");
        var clear = BitmapSource.Create(10, 10, 96, 96, PixelFormats.Bgra32, null, new byte[400], 40);
        var all = new Region(); all.PutManual(0, new MediaRect(2, 2, 6, 6));
        check(AutoColour.Sample(clear, all, 0) == null, "on fully see-through pixels Auto has nothing to match and keeps the colour");

        // ---- Settings ----
        var fresh = new AppSettings();
        check(!fresh.AutoRedactionColour && fresh.LineWidth == 4 && fresh.TrayClickOpensEditor, "new settings: Auto colour off, line width 4, a click on the tray icon opens the editor");
        check(AppSettings.Parse("{\"LineWidth\": 99}").LineWidth == 4 && AppSettings.Parse("{\"LineWidth\": 0}").LineWidth == 4 && AppSettings.Parse("{\"LineWidth\": 12}").LineWidth == 12,
            "a line width outside 1 to 20 in settings.json goes back to 4");
        var dialog = new SettingsWindow(new AppSettings { LineWidth = 7, AutoRedactionColour = true, TrayClickOpensEditor = false });
        var collected = dialog.Collect();
        check(collected.LineWidth == 7 && collected.AutoRedactionColour && !collected.TrayClickOpensEditor
              && ((CheckBox)dialog.FindName("AutoColourSettingBox")).IsChecked == true && ((RadioButton)dialog.FindName("TrayBarBox")).IsChecked == true,
            "Settings › Editor shows and keeps the line width, Auto Redaction Colour and the tray click choice");
        dialog.Close();

        // ---- Pictures read by Windows ----
        var folder = Path.Combine(output, "release320"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var png = Path.Combine(folder, "see-through.png");
        { var p = Pixels(picture); for (var i = 3; i < p.Length; i += 16) p[i] = 90; var seeThrough = BitmapSource.Create(300, 120, 96, 96, PixelFormats.Bgra32, null, p, 1200);
          var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(seeThrough)); using var stream = File.Create(png); encoder.Save(stream); }
        var fast = StillDecoder.Decode(png); var slow = Wait(() => tools.FrameAsync(png, null, null, CancellationToken.None));
        check(fast != null && fast.Format == PixelFormats.Bgra32 && Pixels(fast).SequenceEqual(Pixels(slow)), "a PNG read by Windows has exactly FFmpeg's pixels, transparency included");
        var jpeg = Path.Combine(folder, "held-sideways.jpg");
        {
            var metadata = new BitmapMetadata("jpg"); metadata.SetQuery("/app1/ifd/{ushort=274}", (ushort)6);
            var encoder = new JpegBitmapEncoder { QualityLevel = 95 }; encoder.Frames.Add(BitmapFrame.Create(picture, null, metadata, null));
            using var stream = File.Create(jpeg); encoder.Save(stream);
        }
        var turned = StillDecoder.Decode(jpeg); var ffmpegTurned = Wait(() => tools.FrameAsync(jpeg, null, null, CancellationToken.None));
        double Difference(BitmapSource a, BitmapSource b) { var pa = Pixels(a); var pb = Pixels(b); double sum = 0; for (var i = 0; i < pa.Length; i += 4) sum += Math.Abs(pa[i] + pa[i + 1] + pa[i + 2] - pb[i] - pb[i + 1] - pb[i + 2]) / 3.0; return sum / (pa.Length / 4); }
        check(turned is { PixelWidth: 120, PixelHeight: 300 } && ffmpegTurned is { PixelWidth: 120, PixelHeight: 300 } && Difference(turned, ffmpegTurned) < 4,
            $"a JPEG held sideways (EXIF) is turned upright just as FFmpeg turns it ({turned?.PixelWidth}×{turned?.PixelHeight}, difference {(turned == null ? -1 : Difference(turned, ffmpegTurned)):0.00})");
        check(!StillDecoder.Handles("a.webp") && !StillDecoder.Handles("a.gif") && !StillDecoder.Handles("a.tga") && StillDecoder.Handles("a.JPG"), "other formats (GIF, WebP, TGA...) are still read by FFmpeg");

        // ---- In the editor ----
        var temp = Path.Combine(output, "release320-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release320-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ShowActivated = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var opened = Wait(() => controller.OpenEditor().OpenPathAsync(png));
            var editor = controller.Editor!; var preview = (PreviewSurface)editor.FindName("Preview");
            T Find<T>(string name) where T : class => (T)editor.FindName(name);
            void Refresh() { typeof(MainWindow).GetMethod("Refresh", BindingFlags.Instance | BindingFlags.NonPublic)!.Invoke(editor, null); editor.UpdateLayout(); }
            check(opened && preview.Image is { PixelWidth: 300, PixelHeight: 120 }, "a PNG opens in the editor (read by Windows)");
            { var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using (var stream = File.Create(Path.Combine(folder, "plain.png"))) encoder.Save(stream); }
            check(Wait(() => editor.OpenPathAsync(Path.Combine(folder, "plain.png"))), "the text picture opens");

            // Menus, names and icons.
            var menu = (Menu)editor.FindName("MainMenu");
            string Header(MenuItem m) => (m.Header as string ?? "").Replace("_", "");
            var redact = menu.Items.OfType<MenuItem>().First(m => Header(m) == "Redact").Items.OfType<MenuItem>().Select(Header).ToArray();
            check(redact.SequenceEqual(["Solid Fill", "Blur Fill", "Pixelate Fill", "Redaction Colour…", "Eyedropper"]), "the Redact menu says Solid Fill, Blur Fill, Pixelate Fill, Redaction Colour, Eyedropper: " + string.Join(" | ", redact));
            var tools3 = new[] { ("OpaqueTool", "Solid Fill"), ("BlurTool", "Blur Fill"), ("PixelateTool", "Pixelate Fill") };
            check(tools3.All(t => Find<Button>(t.Item1) is { } b && b.Content as string == t.Item2 && b.ToolTip as string == t.Item2), "the toolbar says Solid Fill, Blur Fill and Pixelate Fill (tooltips too)");
            check(Find<Button>("PopupOpaque") is { Content: "Solid", ToolTip: "Solid Fill" } && Find<Button>("PopupBlur").ToolTip as string == "Blur Fill" && Find<Button>("PopupPixelate").ToolTip as string == "Pixelate Fill",
                "the redaction window says Solid (tooltip Solid Fill)");
            check(Find<Button>("ColorSwatch").ToolTip as string == "Redaction Colour" && Find<Button>("PopupColorSwatch").ToolTip as string == "Redaction Colour"
                  && Find<Button>("EyedropperButton").ToolTip as string == "Eyedropper" && Find<Button>("PopupEyedropper").ToolTip as string == "Eyedropper",
                "the colour button's tooltip is Redaction Colour and the picker's is Eyedropper");
            var options = Find<StackPanel>("PopupColorOption").Children.OfType<FrameworkElement>().Select(e => e.Name).ToArray();
            check(options.SequenceEqual(["PopupColorSwatch", "PopupAutoColour", "PopupEyedropper"]), "Auto sits between the Redaction Colour and the Eyedropper in the redaction window: " + string.Join(", ", options));
            var bucket = (Geometry)editor.FindResource("IconSolidFill");
            check(Find<Button>("OpaqueTool").GetValue(Toolbar.IconProperty) == bucket && Find<Button>("PopupOpaque").GetValue(Toolbar.IconProperty) == bucket,
                "Solid Fill has the paint-bucket icon (toolbar and redaction window)");
            check(new[] { "RectangleTool", "OvalTool", "PolygonTool" }.All(n => Find<Button>(n).GetValue(Toolbar.AccentProperty) is Geometry g && g == Find<Button>(n).GetValue(Toolbar.IconProperty)),
                "the Rectangle, Oval and Polygon redaction icons are filled in");
            var clearSizes = new[] { "IconClearRedactions", "IconClearAnnotations" }.Select(k => ((Geometry)editor.FindResource(k)).Bounds).ToArray();
            var reference = ((Geometry)editor.FindResource("IconFileInfo")).Bounds;
            check(clearSizes.All(b => b.Height >= reference.Height * 0.8 && b.Width >= 13), $"the Clear Redactions and Clear Annotations icons are about as large as the others ({string.Join(", ", clearSizes.Select(b => $"{b.Width:0.#}×{b.Height:0.#}"))}; File Info {reference.Width:0.#}×{reference.Height:0.#})");

            // Line width setting.
            var wide = editor.Settings.Copy(); wide.LineWidth = 9; editor.ApplySettings(wide);
            check(preview.AnnotationStyle.Width == 9 && Find<NumberSpinner>("AnnotationWidth").Value == 9, "the line width in Settings is what new lines start with");
            var normal = editor.Settings.Copy(); normal.LineWidth = 4; editor.ApplySettings(normal);

            // Auto colour, drawn and moved with the real mouse path.
            var auto = editor.Settings.Copy(); auto.AutoRedactionColour = true; editor.ApplySettings(auto);
            preview.DrawingEffect = RedactionEffect.Opaque; preview.Tool = "Rectangle"; preview.Fit(); preview.UpdateLayout(); Refresh();
            Point On(double x, double y) { var r = preview.ScreenRect(new MediaRect(x, y, 0, 0)); return new(r.X, r.Y); }
            preview.MouseDownAt(On(40, 44), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(80, 60)); preview.PointerMove(On(110, 74)); preview.PointerUp(); Refresh();
            var drawn = preview.Selected;
            check(drawn is { AutoColor: true, Effect: RedactionEffect.Opaque } && drawn.Color == Hex(Blue) && Find<CheckBox>("PopupAutoColour").IsChecked == true,
                $"with Auto on, a Solid Fill drawn over black text on light blue is light blue ({drawn?.Color}), and Auto is ticked in its window");
            preview.MouseDownAt(On(75, 59), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(150, 59)); preview.PointerMove(On(225, 59)); preview.PointerUp(); Refresh();
            check(drawn?.Color == Hex(Pink) && drawn.GeometryAt(0).X > 180, $"moved onto the pink side it turns pink ({drawn?.Color})");
            editor.ApplyColor("#00FF00", "Chose"); Refresh();
            check(drawn is { AutoColor: false, Color: "#00FF00" } && Find<CheckBox>("PopupAutoColour").IsChecked == false, "choosing a colour by hand turns Auto off for that redaction");
            Find<CheckBox>("PopupAutoColour").IsChecked = true; Refresh();
            check(drawn is { AutoColor: true } && drawn.Color == Hex(Pink), "ticking Auto again in its window matches the colour around it at once");
            var manual = editor.Settings.Copy(); manual.AutoRedactionColour = false; editor.ApplySettings(manual);
            preview.Selected = null; preview.Tool = "Rectangle"; Refresh();
            preview.MouseDownAt(On(42, 90), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(70, 100)); preview.PointerMove(On(100, 110)); preview.PointerUp(); Refresh();
            check(preview.Selected is { AutoColor: false, Color: "#00FF00" } plain && plain != drawn, $"with Auto off (the default), a new Solid Fill uses the chosen Redaction Colour, not the last matched one ({preview.Selected?.Color})");

            // New Image at a picture's size, then that picture pasted (David's video, 16 Nov): it becomes the image itself.
            preview.Selected = null; Refresh();
            editor.AnswerNewPicture = d => { d.Carry.IsChecked = false; d.WidthBox.Value = 300; d.HeightBox.Value = 120; d.White.IsChecked = true; d.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && editor.IsNewPicture && preview.Project.Media is { Width: 300, Height: 120 }, "a New Image the size of the picture opens");
            var blankPath = preview.Project.Media!.Path;
            check(Wait(() => editor.AddPictureFilesAsync([Path.Combine(folder, "plain.png")])) == 1 && preview.Project.Annotations.Count == 0 && preview.Project.Media!.Path != blankPath
                  && preview.Image is { } baked && Pixels(baked)[(10 * 300 + 10) * 4 + 2] == Blue.R && editor.IsNewPicture,
                "a picture that fills the empty New Image becomes part of it (no item left on top to catch clicks)");
            check(File.ReadAllBytes(preview.Project.Media!.Path).Length > 0 && StillDecoder.Decode(preview.Project.Media.Path) is { } saved && Pixels(saved)[(10 * 300 + 10) * 4 + 2] == Blue.R,
                "so Save Media As saves the picture, not just the white background");
            preview.Tool = "Rectangle"; preview.DrawingEffect = RedactionEffect.Opaque; preview.Fit(); preview.UpdateLayout(); Refresh();
            preview.MouseDownAt(On(40, 44), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(80, 60)); preview.PointerMove(On(110, 74)); preview.PointerUp(); Refresh();
            check(preview.Project.Regions.Count == 1 && preview.Selected != null, "and a redaction can be drawn on it straight away");
            // A smaller pasted picture stays an item, but a drawing tool draws over it; only Select grabs it.
            editor.AnswerNewPicture = d => { d.Carry.IsChecked = false; d.WidthBox.Value = 600; d.HeightBox.Value = 300; d.White.IsChecked = true; d.Accept(); return true; };
            check(Wait(() => editor.NewPictureAsync()) && Wait(() => editor.AddPictureFilesAsync([Path.Combine(folder, "plain.png")])) == 1 && preview.Project.Annotations.Count == 1,
                "a smaller picture on a larger New Image stays a picture you can move");
            var item = preview.Project.Annotations[0]; var itemBox = item.Box;
            preview.Tool = "Rectangle"; preview.SelectAnnotation(null); preview.Fit(); preview.UpdateLayout(); Refresh(); // Esc, or a click elsewhere, lets go of it.
            var x0 = itemBox.X + 40; var y0 = itemBox.Y + 30;
            preview.MouseDownAt(On(x0, y0), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(x0 + 30, y0 + 20)); preview.PointerMove(On(x0 + 60, y0 + 40)); preview.PointerUp(); Refresh();
            check(preview.Project.Regions.Count == 1 && item.Box == itemBox, "once it is let go, dragging on the picture with the Rectangle tool draws a redaction instead of moving it");
            preview.Tool = "Select"; preview.Selected = null; Refresh();
            preview.MouseDownAt(On(itemBox.X + 5, itemBox.Y + 5), System.Windows.Input.MouseButton.Left, 1); preview.PointerMove(On(itemBox.X + 25, itemBox.Y + 15)); preview.PointerMove(On(itemBox.X + 45, itemBox.Y + 25)); preview.PointerUp(); Refresh();
            check(item.Box.X > itemBox.X + 30 && preview.SelectedAnnotation == item, "with Select, the picture is grabbed and moved as before");

            // Tray icon clicks.
            controller.Bar.Hide(); controller.TrayClicked(doubleClick: true);
            check(controller.Bar.IsVisible, "a double-click on the tray icon shows the capture bar");
            editor.Close(); Wait(() => Task.FromResult(true));
            controller.TrayClicked(doubleClick: false);
            check(controller.Editor is { IsVisible: true } again && again != editor, "a single click on the tray icon opens the editor");
            var swapped = controller.Settings.Copy(); swapped.TrayClickOpensEditor = false; controller.Apply(swapped);
            controller.Bar.Hide(); controller.TrayClicked(doubleClick: false);
            check(controller.Bar.IsVisible, "swapped in Settings, a single click shows the capture bar instead");
            controller.Editor?.Close();
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } open) open.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }
}
