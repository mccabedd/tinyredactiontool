using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using TinyRedaction.Core;
using TinyRedaction.Desktop;

internal static class FollowLossChecks
{
    public static void Run(string output, Action<bool, string> check)
    {
        var fixture = Task.Run(async () =>
        {
            using var tools = new MediaTools(); var path = await TrackingChecks.WriteVideo(tools, output, true);
            var map = await tools.ProbeTimelineAsync(path, CancellationToken.None);
            var media = new MediaReference(path, new FileInfo(path).Length, await ProjectStore.HashAsync(path), 128, 96, .7, true);
            return (map, media, image: await tools.FrameAsync(path, map.Frames[0], null, CancellationToken.None));
        }).GetAwaiter().GetResult();
        foreach (var choice in new[] { "ContinueButton", "EndButton", "CorrectButton", "NoSeed", "Close" })
        {
            var window = new MainWindow(new()) { WindowState = WindowState.Normal, Left = -20000, Top = 0, ShowInTaskbar = false }; window.Show();
            var preview = (PreviewSurface)window.FindName("Preview");
            try
            {
                var region = new Region { Start = 0, End = .6 }; region.PutManual(0, choice == "NoSeed" ? new(24, 20, 4, 4) : new(24, 20, 16, 16));
                preview.Project = new() { Media = fixture.media, Regions = [region] }; preview.Timeline = fixture.map; preview.Image = fixture.image; preview.Selected = region;
                typeof(MainWindow).GetMethod("Refresh", BindingFlags.NonPublic | BindingFlags.Instance)!.Invoke(window, null);
                var seen = false; var valid = false; var dialogs = 0; var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
                timer.Tick += (_, _) =>
                {
                    var dialog = window.OwnedWindows.OfType<FollowLossReview>().FirstOrDefault(); if (dialog == null || !dialog.IsVisible) return;
                    // Continue redaction may lose the subject again and ask again; that second question is closed.
                    if (++dialogs > 1) { dialog.Close(); return; }
                    seen = true;
                    valid = choice == "NoSeed" ? !((Button)dialog.FindName("EndButton")).IsEnabled :
                        ((TextBlock)dialog.FindName("MatchedLabel")).Text.Contains("0.300 s") && ((TextBlock)dialog.FindName("UnmatchedLabel")).Text.Contains("0.400 s") && dialog.FindName("KeepButton") == null && dialog.Title == "Tracking Stopped" &&
                        ((Image)dialog.FindName("MatchedImage")).Source != null && ((Image)dialog.FindName("UnmatchedImage")).Source != null;
                    if (choice != "ContinueButton") timer.Stop();
                    if (choice == "EndButton")
                    {
                        dialog.UpdateLayout();
                        var shot = new RenderTargetBitmap((int)dialog.ActualWidth, (int)dialog.ActualHeight, 96, 96, PixelFormats.Pbgra32); shot.Render(dialog);
                        var png = new PngBitmapEncoder(); png.Frames.Add(BitmapFrame.Create(shot));
                        using var file = File.Create(Path.Combine(output, "follow-loss-review.png")); png.Save(file);
                    }
                    if (choice is "Close" or "NoSeed") dialog.Close();
                    else ((Button)dialog.FindName(choice)).RaiseEvent(new RoutedEventArgs(Button.ClickEvent));
                };
                timer.Start(); Pump(window, window.FollowSelectedSubject); timer.Stop();
                check(seen && valid, "loss review shows exact boundary frames and valid choices: " + choice);
                if (choice == "EndButton")
                {
                    check(region.End == .3 && preview.Time == .3 && region.Tracking.All(s => s.State == ReviewState.Unreviewed) && region.Keyframes.All(k => k.Time <= .3), "confirmed loss end trims only at last matched frame and retains review");
                    typeof(MainWindow).GetMethod("Undo", BindingFlags.NonPublic | BindingFlags.Instance)!.Invoke(window, [window, new RoutedEventArgs()]);
                    check(preview.Project.Regions[0].End == .6 && preview.Project.Regions[0].Tracking.Any(s => s.State == ReviewState.Lost), "Undo restores confirmed loss end and unresolved tail");
                }
                else if (choice == "CorrectButton")
                {
                    check(region.End == .6 && preview.Time == .4 && !preview.UsePlayer && preview.Tool == "Select" && region.Tracking.Any(s => s.State == ReviewState.Lost), "correction opens exact unmatched frame without ending or reviewing range");
                    preview.Time = .5; region.PutManual(.5, new(39, 25, 16, 16));
                    Pump(window, window.FollowSelectedSubject);
                    check(preview.Time == .5 && region.Keyframes.Any(k => k.Time == .6 && k.Origin == KeyframeOrigin.Tracking) && region.Tracking.Any(s => s.State == ReviewState.Lost && s.Start == .4), "manual correction resumes Follow while preserving earlier unresolved loss");
                }
                else if (choice == "ContinueButton")
                    check(region.Keyframes.Any(k => k.Time == .4 && k.Origin == KeyframeOrigin.Manual) && (dialogs > 1 || region.Keyframes.Any(k => k.Time > .4 && k.Origin == KeyframeOrigin.Tracking)) && region.End == .6,
                        "Continue redaction keeps the box on the lost frame and tracks on from there (asking again if it loses the subject again)");
                else check(region.End == .6 && region.Tracking.Any(s => s.State == ReviewState.Lost), "keeping loss review preserves range and unresolved state: " + choice);
                // 0.14.0: no Review step (David), so a loss no longer blocks export, but it is never marked as checked either.
                check(preview.Project.Regions[0].Tracking.All(s => s.State != ReviewState.Reviewed), "a loss decision never marks the followed range as checked: " + choice);
            }
            finally { preview.Project = new(); preview.Selected = null; window.Close(); }
        }
    }
    private static void Pump(MainWindow window, Func<Task> operation)
    {
        Task? task = null; var frame = new DispatcherFrame(); var timer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(25) };
        timer.Tick += (_, _) => { if (task?.IsCompleted == true) frame.Continue = false; };
        window.Dispatcher.BeginInvoke(() => { task = operation(); }); timer.Start(); Dispatcher.PushFrame(frame); timer.Stop(); task!.GetAwaiter().GetResult();
    }
}
