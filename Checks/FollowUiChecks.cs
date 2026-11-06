using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class FollowUiChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        var fixture = Task.Run(async () =>
        {
            using var tools = new MediaTools(); var path = await TrackingChecks.WriteVideo(tools, output, false);
            var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
            var image = await tools.FrameAsync(path, map.Frames[0], null, CancellationToken.None);
            var media = new MediaReference(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), 128, 96, map.Frames[^1].Time + map.Frames[^1].Duration, true);
            return (map, image, media);
        }).GetAwaiter().GetResult();
        foreach (var effect in new[] { RedactionEffect.Pixelate, RedactionEffect.Blur, RedactionEffect.Opaque })
        {
            Console.WriteLine("Running actual WPF Follow controller after selecting " + effect);
            var window = new MainWindow(new()) { WindowState = WindowState.Normal, Left = -20000, Top = 0, ShowInTaskbar = false };
            window.Show();
            var preview = (PreviewSurface)window.FindName("Preview");
            try
            {
                var region = new Region { Start = 0, End = fixture.media.Duration }; region.PutManual(0, new(24, 20, 16, 16));
                preview.Project = new RedactionProject { Media = fixture.media, Regions = [region] };
                preview.Timeline = fixture.map; preview.Image = fixture.image;
                var regions = (ListBox)window.FindName("Regions"); regions.ItemsSource = preview.Project.Regions; regions.SelectedItem = region;
                var button = (Button)window.FindName(effect == RedactionEffect.Pixelate ? "PixelateTool" : effect == RedactionEffect.Blur ? "BlurTool" : "OpaqueTool");
                button.RaiseEvent(new RoutedEventArgs(Button.ClickEvent)); window.UpdateLayout();
                check(region.Effect == effect, "WPF selection applies " + effect + " before Follow");
                Task? operation = null; var frame = new DispatcherFrame(); var deadline = DateTime.UtcNow.AddSeconds(30);
                var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(20) };
                timer.Tick += (_, _) => { if (operation?.IsCompleted == true || DateTime.UtcNow >= deadline) frame.Continue = false; };
                window.Dispatcher.BeginInvoke(() =>
                {
                    check(SynchronizationContext.Current is DispatcherSynchronizationContext, "Follow starts in actual WPF dispatcher context: " + effect);
                    operation = window.FollowSelectedSubject();
                });
                timer.Start(); Dispatcher.PushFrame(frame); timer.Stop();
                if (operation?.IsCompleted != true) throw new TimeoutException("WPF Follow did not complete: " + effect);
                operation.GetAwaiter().GetResult();
                // Drain posted progress at normal priority before asserting completion.
                window.Dispatcher.Invoke(() => { }, DispatcherPriority.Background);
                check(region.Keyframes.Any(k => k.Origin == KeyframeOrigin.Tracking) && region.Tracking.Count > 0, "WPF Follow completes with editable results: " + effect);
                check(preview.Time == fixture.map.Frames[0].Time && preview.IsEnabled && ((Button)window.FindName("FollowSubjectButton")).IsEnabled, "WPF Follow returns to exact seed and restores editor controls: " + effect);
                check(((TextBlock)window.FindName("Status")).Text.Contains("Ready to check"), "WPF Follow progress does not overwrite completion status: " + effect);
            }
            finally { preview.Project = new(); preview.Selected = null; window.Close(); }
        }
    }
}
