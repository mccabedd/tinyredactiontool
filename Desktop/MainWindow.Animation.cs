using System.IO;
using System.Windows.Threading;

namespace TinyRedaction.Desktop;

// Animated GIFs in the editor (0.28.0, David): they play as they open; with Select, a click on the picture (away from
// the shapes) pauses or plays them. Redactions and annotations sit on every frame. Export as GIF keeps the animation
// (ImageExport); Copy, and export as PNG, JPG or WebP, take the frame shown.
public partial class MainWindow
{
    private GifAnimation? animation;
    private int animationFrame;
    private readonly DispatcherTimer animationTimer = new();
    internal GifAnimation? Animation => animation;
    internal bool AnimationPlaying => animationTimer.IsEnabled;
    internal int AnimationFrame => animationFrame;

    // Reads the animation of a GIF being opened (on a worker; null when it is not animated). Too large to hold: a note,
    // and the GIF opens as a still.
    private async Task<GifAnimation?> ReadAnimationAsync(string path, CancellationToken token)
    {
        try { return await Task.Run(() => GifAnimation.Load(path, token), token); }
        catch (InvalidDataException ex) { Dispatcher.Invoke(() => Status.Text = ex.Message + " It opens as a still image."); return null; }
        catch (Exception ex) when (ex is NotSupportedException or FileFormatException or IOException or ArgumentException) { return null; }
    }
    private void ShowAnimation(GifAnimation? next)
    {
        StopAnimation(); animation = next; animationFrame = 0;
        if (next == null) return;
        if (animationTimer.Tag == null) { animationTimer.Tick += (_, _) => NextAnimationFrame(); animationTimer.Tag = true; }
        Preview.Image = next.Frames[0]; Preview.InvalidateVisual();
        PlayAnimation();
    }
    private void PlayAnimation()
    {
        if (animation == null) return;
        animationTimer.Interval = TimeSpan.FromMilliseconds(animation.Delays[animationFrame]);
        animationTimer.Start();
    }
    internal void StopAnimation() => animationTimer.Stop();
    private void NextAnimationFrame()
    {
        if (animation == null || Preview.Image == null) { animationTimer.Stop(); return; }
        animationFrame = (animationFrame + 1) % animation.Frames.Count;
        Preview.Image = animation.Frames[animationFrame]; Preview.InvalidateVisual();
        animationTimer.Interval = TimeSpan.FromMilliseconds(animation.Delays[animationFrame]);
    }
    // With Select, a click on the picture: pause or play.
    internal void ToggleAnimation()
    {
        if (animation == null || Preview.Tool != "Select") return;
        if (AnimationPlaying) { StopAnimation(); Status.Text = $"Animation paused on frame {animationFrame + 1} of {animation.Frames.Count}. Click the picture again to play."; }
        else { PlayAnimation(); Status.Text = "Animation playing. Click the picture to pause."; }
    }
}
