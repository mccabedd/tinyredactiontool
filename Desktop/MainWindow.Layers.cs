using System.IO;
using System.Windows;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// 3.0.0 (David): layers in the Properties pane. Move Up and Move Down (the arrows beside each list,
// Edit › Layers, Ctrl+] and Ctrl+[), Duplicate Layer (Ctrl+D), Delete Layer, and Flatten Image, which burns
// the redactions and annotations into a picture. Merge Down and Merge Visible were left out at David's choice.
public partial class MainWindow
{
    // The pane's buttons say which list they belong to (Tag); the menu and keys use whatever is selected.
    private object? SelectedLayer(string? list) => list switch
    {
        "Region" => Preview.Selected is { } r && Project.Regions.Contains(r) ? r : null,
        "Annotation" => SelectedAnnotation,
        _ => (object?)SelectedAnnotation ?? (Preview.Selected is { } s && Project.Regions.Contains(s) ? s : null),
    };
    private static string? ListOf(object sender) => (sender as FrameworkElement)?.Tag as string;
    private void MoveLayerUp(object sender, RoutedEventArgs e) => MoveSelectedLayer(true, ListOf(sender));
    private void MoveLayerDown(object sender, RoutedEventArgs e) => MoveSelectedLayer(false, ListOf(sender));
    private void DuplicateLayer(object sender, RoutedEventArgs e) => DuplicateSelectedLayer(ListOf(sender));
    private static string LayerName(object item) => item is Region r ? $"\"{r.Name}\"" : $"the {KindName(((Annotation)item).Kind).ToLowerInvariant()}";

    internal bool MoveSelectedLayer(bool up, string? list)
    {
        if (busy || Preview.HasMultiSelection || SelectedLayer(list) is not { } item) return false;
        if (!Layers.CanMove(Project, item, up)) { Status.Text = up ? "It is already the top layer." : "It is already the bottom layer."; return false; }
        if (playing || Preview.UsePlayer) Pause();
        history.Checkpoint(Project);
        var passed = Layers.Move(Project, item, up);
        Refresh();
        var other = passed?.GetType() != item.GetType();
        Status.Text = up ? other ? "Moved to the top layer." : $"Moved up, above {LayerName(passed!)}." : other ? "Moved to the bottom layer." : $"Moved down, below {LayerName(passed!)}.";
        return true;
    }

    // The copy goes on top, 10 pixels right and down, and is selected, ready to move.
    internal bool DuplicateSelectedLayer(string? list)
    {
        if (busy || Preview.HasMultiSelection || Project.Media is not { } m || SelectedLayer(list) is not { } item) return false;
        if (playing || Preview.UsePlayer) Pause();
        history.Checkpoint(Project);
        if (item is Region r)
        {
            var copy = Layers.Copy(Project, r);
            var (dx, dy) = Layers.CopyOffset(copy.Keyframes.Select(k => k.Bounds).ToList(), m.Width, m.Height);
            copy.Keyframes = copy.Keyframes.Select(k => k with { Bounds = k.Bounds with { X = k.Bounds.X + dx, Y = k.Bounds.Y + dy } }).ToList();
            Project.Regions.Add(copy);
            Preview.SelectAnnotation(null); Preview.Selected = copy;
            Status.Text = $"Duplicated as \"{copy.Name}\", on top. Undo removes it.";
        }
        else
        {
            var a = (Annotation)item; var copy = Layers.Copy(Project, a);
            var (dx, dy) = Layers.CopyOffset([copy.Bounds()], m.Width, m.Height);
            copy.Translate(dx, dy, m.Width, m.Height);
            Project.Annotations.Add(copy);
            Preview.Selected = null; Preview.SelectAnnotation(copy);
            Status.Text = $"Duplicated {LayerName(a)}, on top. Undo removes it.";
        }
        Refresh();
        return true;
    }

    // Flatten Image (pictures): the redactions and annotations become part of a new working copy of the
    // picture, drawn exactly as Export draws them, and the lists empty. The crop stays a crop. The original
    // file is never changed, and Undo brings the separate layers back.
    private async void FlattenImage(object sender, RoutedEventArgs e) => await FlattenImageAsync();
    internal string? FlattenBlockReason() =>
        Project.Media is not { } m ? "Open an image first." :
        m.IsVideo ? "Flatten works on images, not videos." :
        Animation != null ? "Flatten works on still images, not animated GIFs." :
        Project.Regions.Count + Project.Annotations.Count == 0 ? "There are no redactions or annotations to flatten." :
        captures == null ? "Flatten needs the capture part of TRT, which is not running." : null;
    internal async Task<bool> FlattenImageAsync()
    {
        if (busy || closing) return false;
        if (FlattenBlockReason() is { } reason) { Status.Text = reason; return false; }
        if (Preview.Image is not { } image || Project.Media is not { } media) return false;
        var before = ProjectStore.Serialize(Project); var done = false; string? made = null;
        await RunWork(async token =>
        {
            var whole = ProjectStore.Deserialize(before); whole.Crop = null; whole.Export.KeepAudio = false; whole.Export.DeleteOriginal = false;
            ExportGate.Check(whole, policy); // The same rules as Export (a policy that allows only boxes, and so on).
            var picture = await Task.Run(() => RenderForCopy(image, whole, 0, null, token), token);
            made = captures!.Store.NewFile("EDITED", ".png");
            CaptureController.WritePng(picture, made);
            token.ThrowIfCancellationRequested();
            var project = ProjectStore.Deserialize(before);
            project.Regions.Clear(); project.Annotations.Clear();
            project.Media = media with { Path = made, Length = new FileInfo(made).Length, Sha256 = await ProjectStore.HashAsync(made, token) };
            await LoadMedia(made, project, token, keepHistory: true);
            done = true;
        }, "Flatten cancelled. Nothing was changed.", "Flattening the Image");
        if (!done) { if (made != null && captures!.Store.Owns(made) && Project.Media?.Path != made) ReleaseCapture(made); return false; }
        history.Checkpoint(before);
        savedSnapshot = null;
        Status.Text = "Image flattened: the redactions and annotations are now part of the picture. The original file is unchanged; Undo separates them again.";
        return true;
    }

    private void UpdateLayerButtons()
    {
        if (RegionUpButton == null) return;
        var region = SelectedLayer("Region"); var annotation = SelectedLayer("Annotation"); var any = SelectedLayer(null);
        var single = !busy && !Preview.HasMultiSelection;
        RegionUpButton.IsEnabled = single && region != null && Layers.CanMove(Project, region, true);
        RegionDownButton.IsEnabled = single && region != null && Layers.CanMove(Project, region, false);
        AnnotationUpButton.IsEnabled = single && annotation != null && Layers.CanMove(Project, annotation, true);
        AnnotationDownButton.IsEnabled = single && annotation != null && Layers.CanMove(Project, annotation, false);
        DuplicateRegionButton.IsEnabled = single && region != null;
        DuplicateAnnotationButton.IsEnabled = single && annotation != null;
        MoveUpMenuItem.IsEnabled = single && any != null && Layers.CanMove(Project, any, true);
        MoveDownMenuItem.IsEnabled = single && any != null && Layers.CanMove(Project, any, false);
        DuplicateMenuItem.IsEnabled = single && any != null;
        FlattenImageButton.IsEnabled = !busy && FlattenBlockReason() == null;
    }
}
