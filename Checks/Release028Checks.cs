using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using Microsoft.Win32;
using TinyRedaction.Core;
using TinyRedaction.Desktop;
using Forms = System.Windows.Forms;

// 0.28.0: David's final part-one edits: File › Remove History (also in the capture bar's menu and the notification-area
// menu), menus, dialogue boxes, title bars and the tray menu in Dark, the Nav Bar height (Release025/026), animated GIFs
// that play (click with Select to pause) and export animated, and the About box in this TRT's style. `--release-028-only`.
internal static class Release028Checks
{
    private static void Pump() => Dispatcher.CurrentDispatcher.Invoke(DispatcherPriority.Background, new Action(() => { }));
    private static T Wait<T>(Func<Task<T>> operation)
    {
        Task<T>? task = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddMinutes(4);
        var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
        Dispatcher.CurrentDispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
        if (task?.IsCompleted != true) throw new TimeoutException("0.28.0 check timed out.");
        return task.GetAwaiter().GetResult();
    }
    private static Color Colour(Brush? brush) => brush is SolidColorBrush s ? s.Color : Colors.Transparent;

    public static void Run(MediaTools tools, string output, Action<bool, string> check)
    {
        ThemedMessage.Answer = (_, _, _) => MessageBoxResult.Yes; // No box may wait for a person here.
        try { RunChecks(tools, output, check); }
        finally { ThemedMessage.Answer = null; MainWindow.ApplyThemeResources("Light"); }
    }
    private static void RunChecks(MediaTools tools, string output, Action<bool, string> check)
    {
        // ---- Windows' memory of TRT's Open and Save boxes (a throw-away key, never David's real one) ----
        const string root = @"Software\TRT-Checks-028\ComDlg32";
        Registry.CurrentUser.DeleteSubKeyTree(@"Software\TRT-Checks-028", false);
        try
        {
            using (var key = Registry.CurrentUser.CreateSubKey(root + @"\LastVisitedPidlMRU"))
            {
                byte[] Entry(string program) => [.. System.Text.Encoding.Unicode.GetBytes(program + "\0"), 0x14, 0x00, 0x1F, 0x50];
                key.SetValue("0", Entry("TinyTest.exe"), RegistryValueKind.Binary); key.SetValue("1", Entry("Other.exe"), RegistryValueKind.Binary); key.SetValue("2", Entry("tinytest.EXE"), RegistryValueKind.Binary);
                key.SetValue("MRUListEx", new byte[] { 2, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF }, RegistryValueKind.Binary);
            }
            var removed = DialogMemory.Forget("TinyTest.exe", root);
            using var after = Registry.CurrentUser.OpenSubKey(root + @"\LastVisitedPidlMRU")!;
            check(removed == 2 && after.GetValue("0") == null && after.GetValue("2") == null && after.GetValue("1") != null
                  && ((byte[])after.GetValue("MRUListEx")!).SequenceEqual(new byte[] { 1, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF }),
                "Remove History forgets only TRT's own entries in Windows' Open/Save folder memory, and keeps the order list right");
            check(DialogMemory.OwnProgramName() == null, "the checks (run by dotnet.exe) never touch the real Open/Save memory");
        }
        finally { Registry.CurrentUser.DeleteSubKeyTree(@"Software\TRT-Checks-028", false); }

        var folder = Path.Combine(output, "release028"); if (Directory.Exists(folder)) Directory.Delete(folder, true); Directory.CreateDirectory(folder);
        var temp = Path.Combine(output, "release028-temp"); if (Directory.Exists(temp)) Directory.Delete(temp, true); Directory.CreateDirectory(temp);
        var savedPath = AppSettings.Path; AppSettings.Path = Path.Combine(output, "release028-settings.json"); if (File.Exists(AppSettings.Path)) File.Delete(AppSettings.Path);
        var controller = new CaptureController(new ManagedPolicy(), false, temp);
        controller.EditorFactory = () => new MainWindow(controller.Policy) { WindowState = WindowState.Normal, Width = 1240, Height = 800, Left = -20000, Top = 0, ShowInTaskbar = false, ConfirmKeepQuestion = (_, _, _) => true };
        try
        {
            controller.Start(); controller.Bar!.Left = -20000;
            var editor = controller.OpenEditor(); editor.UpdateLayout(); Pump();
            var preview = (PreviewSurface)editor.FindName("Preview");

            // ---- Remove History ----
            var menu = (Menu)editor.FindName("MainMenu");
            List<MenuItem> All(ItemsControl parent) => parent.Items.OfType<MenuItem>().SelectMany(m => new[] { m }.Concat(All(m))).ToList();
            string Header(MenuItem m) => (m.Header as string ?? "").Replace("_", "");
            var fileMenu = menu.Items.OfType<MenuItem>().First(m => Header(m) == "File");
            check(All(fileMenu).Any(m => Header(m) == "Remove History…") && Descendants<Button>(controller.Bar).Any(b => b.ContextMenu?.Items.OfType<MenuItem>().Any(m => Header(m) == "Remove History…") == true),
                "File › Remove History…, and the capture bar's menu has it too");
            check(Descendants<Button>(controller.Bar).Any(b => b.ContextMenu?.Items.OfType<MenuItem>().Any(m => Header(m) == "Help") == true), "3.0.0: the capture bar's menu has Help (the manual)");
            var shown = controller.Store.NewFile("SCREENSHOT", ".png"); WriteImage(shown, NewPictureWindow.Blank(60, 40, Colors.Teal));
            var old = controller.Store.NewFile("SCREENSHOT", ".png"); WriteImage(old, NewPictureWindow.Blank(60, 40, Colors.Orange));
            check(Wait(() => editor.OpenPathAsync(shown)), "a capture is open in the editor");
            var abandoned = Path.Combine(temp, CaptureStore.FolderPrefix + "0123456789abcdef0123456789abcdef"); Directory.CreateDirectory(abandoned);
            File.WriteAllText(Path.Combine(abandoned, ".session.lock"), ""); WriteImage(Path.Combine(abandoned, "NEW_20261105_101010.png"), NewPictureWindow.Blank(8, 8, Colors.Red));
            var scratch = Path.Combine(temp, VideoExport.ScratchFolder, "masks-0123"); Directory.CreateDirectory(scratch); File.WriteAllText(Path.Combine(scratch, "mask.png"), "x");
            controller.Settings.LastSaveFolder = folder;
            var report = controller.RemoveHistory();
            check(File.Exists(shown) && !File.Exists(old) && !Directory.Exists(abandoned) && !Directory.Exists(scratch) && controller.Settings.LastSaveFolder == null,
                $"Remove History wipes the old capture, a leftover session's New picture and export scratch, forgets the last save folder, and keeps what the editor shows ({report})");
            check(report.Contains("Wiped 3") && report.Contains("stays until you close it"), "and says so in plain words");

            // ---- Dark menus, title bars, message boxes and the tray menu ----
            MainWindow.ApplyThemeResources("Dark"); Pump(); editor.UpdateLayout();
            var dark = (Color)ColorConverter.ConvertFromString("#F0F0F0");
            check(Colour(fileMenu.Foreground) == dark && All(fileMenu).All(m => m.Template == Application.Current.Resources["MenuItemTemplate"]) && Colour((Brush)Application.Current.Resources["MenuBackground"]) == (Color)ColorConverter.ConvertFromString("#333333"),
                "in Dark the menus are dark: light text on the dark menu colour, drawn by TRT's own menu template");
            var editorTitle = WindowTheme.TitleBarDark(editor);
            check(editorTitle is null or true, $"in Dark the editor's title bar is dark (Windows says {editorTitle?.ToString() ?? "unsupported"})");
            var box = new ThemedMessage("Wipe it?", "Question", MessageBoxButton.YesNo, MessageBoxImage.Question) { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
            box.Show(); box.UpdateLayout();
            var buttons = Descendants<Button>(box).Select(b => b.Content as string).ToList();
            check(Colour(box.Background) == (Color)ColorConverter.ConvertFromString("#3E3E3E") && buttons.SequenceEqual(["Yes", "No"]) && Descendants<TextBlock>(box).Any(t => t.Text == "Wipe it?" && Colour(t.Foreground) == dark),
                "TRT's message boxes are dark in Dark, with the usual Yes and No");
            check(WindowTheme.TitleBarDark(box) is null or true, "and their title bars are dark");
            box.Close();
            using (var tray = new Forms.ContextMenuStrip())
            {
                tray.Items.Add("Quit TinyRedactionTool");
                WindowTheme.Apply(tray, true);
                check(tray.BackColor.R == 0x33 && tray.Items[0].ForeColor.R == 0xF0 && tray.Renderer is Forms.ToolStripProfessionalRenderer, "the notification-area menu is dark in Dark");
                WindowTheme.Apply(tray, false);
                check(tray.BackColor.R == 0xFB && tray.Items[0].ForeColor.R == 0x1E, "and light in Light");
            }
            var sources = Path.GetFullPath(Path.Combine(output, "..", "Desktop"));
            var plain = Directory.Exists(sources) ? Directory.GetFiles(sources, "*.cs").Where(f => System.Text.RegularExpressions.Regex.IsMatch(File.ReadAllText(f), @"\bMessageBox\.Show\(")).Select(Path.GetFileName).ToList() : ["(sources not found)"];
            check(plain.Count == 0, $"no Windows message box is left (they are always light): every one is TRT's themed box ({string.Join(", ", plain)})");
            var about = new AboutWindow("0.28.0") { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
            about.Show(); about.UpdateLayout();
            check(Colour(about.Background) == (Color)ColorConverter.ConvertFromString("#3E3E3E") && Descendants<Image>(about).Any(i => i.Source != null) && Descendants<Button>(about).Any(b => (string)b.Content == "Close"),
                "the About box is in TRT's style: it follows Dark, with the TRT icon and a Close button");
            SaveShot(about, Path.Combine(output, "about-box-dark.png"));
            about.Close();
            MainWindow.ApplyThemeResources("Light"); Pump();
            check(WindowTheme.TitleBarDark(editor) is null or false && Colour(fileMenu.Foreground) == (Color)ColorConverter.ConvertFromString("#1E1E1E"), "back in Light, title bars and menus are light again");
            about = new AboutWindow("0.28.0") { Left = -20000, Top = 0, ShowActivated = false, WindowStartupLocation = WindowStartupLocation.Manual };
            about.Show(); about.UpdateLayout(); SaveShot(about, Path.Combine(output, "about-box.png")); about.Close();

            // ---- Animated GIFs ----
            var gifPath = Path.Combine(folder, "moving.gif");
            WriteGif(gifPath, 3, 120, 80);
            var animation = GifAnimation.Load(gifPath)!;
            check(animation is { Frames.Count: 3, Width: 120, Height: 80 } && animation.Delays.All(d => d == 100), "an animated GIF is read as three whole frames, a tenth of a second each");
            check(GifAnimation.Load(Path.Combine(folder, "none.png")) == null, "other pictures are not animations");
            check(Wait(() => editor.OpenPathAsync(gifPath)) && editor.Animation != null && editor.AnimationPlaying, "the GIF plays as soon as it opens");
            var before = editor.AnimationFrame;
            var moved = Wait(async () => { await Task.Delay(450); return editor.AnimationFrame; });
            check(moved != before && preview.Image == editor.Animation!.Frames[moved], $"its frames change on screen (frame {before + 1} to {moved + 1})");
            preview.Tool = "Select";
            var centre = new Point(preview.ActualWidth / 2, preview.ActualHeight / 2);
            void Click(Point p) { preview.MouseDownAt(p, MouseButton.Left, 1); preview.PointerUp(); Pump(); }
            Click(centre);
            check(!editor.AnimationPlaying, "with Select, a click on the picture pauses it");
            var paused = editor.AnimationFrame;
            Wait(async () => { await Task.Delay(300); return 0; });
            check(editor.AnimationFrame == paused, "paused, it stays on its frame");
            Click(centre);
            check(editor.AnimationPlaying, "a second click plays it again");
            preview.Tool = "Rectangle"; Click(centre); preview.Tool = "Select";
            check(editor.AnimationPlaying, "a click with another tool doesn't pause it");
            // A black box over the moving square on every frame; export as GIF keeps all three frames, each redacted.
            var region = new Region { Name = "Box", Start = 0, End = 0, Effect = RedactionEffect.Opaque }; region.PutManual(0, new MediaRect(0, 20, 120, 40));
            preview.Project.Regions.Add(region);
            var scale = Math.Min(preview.ActualWidth / 120, preview.ActualHeight / 80); preview.Selected = region; Click(new Point(centre.X, centre.Y - 35 * scale));
            check(editor.AnimationPlaying, "a click that only puts a selected shape away doesn't pause it");
            var exported = Path.Combine(folder, "moving-redacted.gif");
            var snapshot = ProjectStore.Deserialize(ProjectStore.Serialize(preview.Project));
            Wait(async () => { await ImageExport.ExportAsync(exported, snapshot, new ManagedPolicy(), preview.Image!, CancellationToken.None, tools, editor.Animation); return 0; });
            var written = GifAnimation.Load(exported);
            check(written is { Frames.Count: 3 } && written.Delays.All(d => d == 100), "exported as GIF it stays animated: three frames, same timing");
            var black = written != null && written.Frames.All(f => { var px = new byte[4]; f.CopyPixels(new Int32Rect(60, 40, 1, 1), px, 4, 0); return px[0] < 20 && px[1] < 20 && px[2] < 20; });
            check(black, "and the box is black on every frame");
            var still = Path.Combine(folder, "moving-frame.png");
            Wait(async () => { await ImageExport.ExportAsync(still, snapshot, new ManagedPolicy(), preview.Image!, CancellationToken.None, tools, editor.Animation); return 0; });
            check(File.Exists(still) && BitmapDecoder.Create(new Uri(still), BitmapCreateOptions.None, BitmapCacheOption.OnLoad).Frames.Count == 1, "exported as PNG it is the frame shown");
            editor.Close(); Pump();
            check(!editor.AnimationPlaying, "closing the editor stops the animation");
        }
        finally { AppSettings.Path = savedPath; if (controller.Editor is { } openEditor) openEditor.Close(); controller.Store.WipeAll(); controller.Dispose(); }
    }

    private static void WriteGif(string path, int frames, int width, int height)
    {
        var encoder = new GifBitmapEncoder();
        for (var i = 0; i < frames; i++)
        {
            var pixels = new byte[width * height * 4];
            for (var p = 0; p < pixels.Length; p += 4) { pixels[p] = 240; pixels[p + 1] = 240; pixels[p + 2] = 240; pixels[p + 3] = 255; }
            for (var y = 30; y < 50; y++) for (var x = 10 + i * 35; x < 30 + i * 35; x++) { var o = (y * width + x) * 4; pixels[o] = 0; pixels[o + 1] = 0; pixels[o + 2] = 230; }
            encoder.Frames.Add(BitmapFrame.Create(BitmapSource.Create(width, height, 96, 96, PixelFormats.Bgra32, null, pixels, width * 4)));
        }
        using var stream = File.Create(path); encoder.Save(stream);
    }
    private static void SaveShot(Window window, string path)
    {
        var root = (FrameworkElement)VisualTreeHelper.GetChild(window, 0);
        var shot = new RenderTargetBitmap((int)Math.Ceiling(root.ActualWidth), (int)Math.Ceiling(root.ActualHeight), 96, 96, PixelFormats.Pbgra32);
        shot.Render(root); WriteImage(path, shot);
    }
    private static IEnumerable<T> Descendants<T>(DependencyObject root) where T : DependencyObject
    {
        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(root); i++)
        {
            var child = VisualTreeHelper.GetChild(root, i);
            if (child is T found) yield return found;
            foreach (var deeper in Descendants<T>(child)) yield return deeper;
        }
    }
    private static void WriteImage(string path, BitmapSource picture)
    {
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(picture)); using var stream = File.Create(path); encoder.Save(stream);
    }
}
