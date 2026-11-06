using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using TinyRedaction.Core;

namespace TinyRedaction.Desktop;

// Text, Line and Polyline annotations (0.9.0): options bar, Annotations panel, floating text
// editor and video timing. Style changes apply to the selected annotation (undoable), otherwise
// to the style for new annotations, as in the baseline.
public partial class MainWindow
{
    private bool updatingAnnotationUi, closingTextEditor;
    private void InitializeAnnotations()
    {
        AnnotationDash.ItemsSource = LineStyleItem.Dashes; AnnotationEnds.ItemsSource = LineStyleItem.Ends;
        AnnotationFont.ItemsSource = Fonts.SystemFontFamilies.Select(f => f.Source).Distinct().OrderBy(f => f, StringComparer.CurrentCultureIgnoreCase).ToList();
        Preview.AnnotationSelectionChanged += _ => Refresh();
        Preview.TextEditRequested += OpenTextEditor;
        Preview.TextEditConfirmRequested += () => CloseTextEditor(false);
        TextEditorPanel.IsKeyboardFocusWithinChanged += TextEditorFocusChanged;
        InitializeRegionPopup();
    }
    internal static string KindName(AnnotationKind k) => k switch
    {
        AnnotationKind.Rectangle => "Rectangle Outline", AnnotationKind.Oval => "Ellipse Outline", AnnotationKind.Freehand => "Pen", AnnotationKind.Picture => "Pasted Image", _ => k.ToString()
    };
    private Annotation? SelectedAnnotation => Preview.SelectedAnnotation is { } a && Project.Annotations.Contains(a) ? a : null;
    private void RefreshAnnotations()
    {
        updatingAnnotationUi = true;
        try
        {
            var selected = SelectedAnnotation;
            AnnotationsList.ItemsSource = null; AnnotationsList.ItemsSource = Project.Annotations.OrderBy(a => a.Order).ToArray(); AnnotationsList.SelectedItem = selected;
            AnnotationKind? kind = selected?.Kind ?? PreviewSurface.AnnotationKindFor(Preview.Tool);
            // A pasted picture (0.26.0) has no colour, width or font.
            if (kind == AnnotationKind.Picture) kind = null;
            AnnotationOptions.Visibility = kind == null ? Visibility.Collapsed : Visibility.Visible;
            EffectOptions.Visibility = kind == null ? Visibility.Visible : Visibility.Collapsed;
            DeleteAnnotationButton.IsEnabled = !busy && selected != null;
            EditAnnotationTextButton.IsEnabled = !busy && selected?.Kind == AnnotationKind.Text;
            var video = Project.Media?.IsVideo == true && Preview.Timeline != null;
            AnnotationTiming.Visibility = video && selected != null ? Visibility.Visible : Visibility.Collapsed;
            if (video && selected != null)
                AnnotationTimingText.Text = $"Shown on frames {Preview.Timeline!.IndexAt(selected.Start) + 1}–{Preview.Timeline.IndexAt(selected.End) + 1} (exact, no extra buffer)";
            if (kind is not { } k) return;
            var style = selected ?? Preview.AnnotationStyle;
            AnnotationOptionsLabel.Text = KindName(k) + (selected == null ? " (new)" : "");
            LineOptions.Visibility = k == AnnotationKind.Text ? Visibility.Collapsed : Visibility.Visible;
            EndsOptions.Visibility = k is AnnotationKind.Line or AnnotationKind.Polyline ? Visibility.Visible : Visibility.Collapsed;
            JoinOptions.Visibility = k == AnnotationKind.Polyline ? Visibility.Visible : Visibility.Collapsed;
            TextOptions.Visibility = k == AnnotationKind.Text ? Visibility.Visible : Visibility.Collapsed;
            AnnotationColorFill.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString(style.Color));
            AnnotationWidth.Value = style.Width;
            AnnotationDash.SelectedIndex = (int)style.Dash; AnnotationEnds.SelectedIndex = (int)style.Ends; AnnotationJoin.SelectedIndex = (int)style.Join;
            var fonts = (List<string>)AnnotationFont.ItemsSource;
            if (!fonts.Contains(style.FontFamily)) fonts.Add(style.FontFamily);
            AnnotationFont.SelectedItem = style.FontFamily;
            if (!AnnotationSize.IsKeyboardFocusWithin) AnnotationSize.Value = style.FontSize;
            AnnotationBold.IsChecked = style.Bold; AnnotationItalic.IsChecked = style.Italic; AnnotationAlign.SelectedIndex = (int)style.Align;
        }
        finally { updatingAnnotationUi = false; }
    }
    // Reads the options bar into the selected annotation (one undo step) or the new-annotation style.
    private void ApplyAnnotationOptions(string? colour = null)
    {
        if (initializing || updatingAnnotationUi || busy) return;
        var target = SelectedAnnotation;
        var style = new Annotation(); style.CopyStyleFrom(target ?? Preview.AnnotationStyle);
        if (colour != null) style.Color = colour;
        style.Width = (int)Math.Clamp(Math.Round(AnnotationWidth.Value), Annotation.MinWidth, Annotation.MaxWidth);
        if (AnnotationDash.SelectedIndex >= 0) style.Dash = (AnnotationDash)AnnotationDash.SelectedIndex;
        if (AnnotationEnds.SelectedIndex >= 0) style.Ends = (AnnotationEnds)AnnotationEnds.SelectedIndex;
        if (AnnotationJoin.SelectedIndex >= 0) style.Join = (AnnotationJoin)AnnotationJoin.SelectedIndex;
        if (AnnotationFont.SelectedItem is string font) style.FontFamily = font;
        style.FontSize = Math.Clamp(Math.Round(AnnotationSize.Value, 1), Annotation.MinFontSize, Annotation.MaxFontSize);
        style.Bold = AnnotationBold.IsChecked == true; style.Italic = AnnotationItalic.IsChecked == true;
        if (AnnotationAlign.SelectedIndex >= 0) style.Align = (AnnotationAlign)AnnotationAlign.SelectedIndex;
        if (target == null) { Preview.AnnotationStyle.CopyStyleFrom(style); RefreshAnnotations(); return; }
        if (target.SameStyle(style)) { RefreshAnnotations(); return; }
        Pause(); history.Checkpoint(Project); target.CopyStyleFrom(style); Refresh();
    }
    private void AnnotationOptionChanged(object sender, SelectionChangedEventArgs e) => ApplyAnnotationOptions();
    private void AnnotationOptionClicked(object sender, RoutedEventArgs e) => ApplyAnnotationOptions();
    private void AnnotationWidthChanged(object sender, RoutedPropertyChangedEventArgs<double> e) => ApplyAnnotationOptions();
    private void ChooseAnnotationColor(object sender, RoutedEventArgs e)
    {
        if (busy) return;
        var current = (Color)ColorConverter.ConvertFromString((SelectedAnnotation ?? Preview.AnnotationStyle).Color);
        using var dialog = new System.Windows.Forms.ColorDialog { FullOpen = true, AnyColor = true, Color = System.Drawing.Color.FromArgb(current.R, current.G, current.B) };
        if (dialog.ShowDialog(new DialogOwner(new System.Windows.Interop.WindowInteropHelper(this).Handle)) != System.Windows.Forms.DialogResult.OK) return;
        ApplyAnnotationOptions($"#{dialog.Color.R:X2}{dialog.Color.G:X2}{dialog.Color.B:X2}");
    }
    private void AnnotationListSelected(object sender, SelectionChangedEventArgs e)
    {
        if (updatingAnnotationUi || busy) return;
        Preview.SelectAnnotation(AnnotationsList.SelectedItem as Annotation);
    }
    private void DeleteAnnotation(object sender, RoutedEventArgs e)
    {
        if (busy || SelectedAnnotation is not { } a) return;
        history.Checkpoint(Project); Project.Annotations.Remove(a); Preview.SelectAnnotation(null); Refresh();
        Status.Text = "Annotation deleted. Undo restores it.";
    }
    private void ClearAnnotations(object sender, RoutedEventArgs e)
    {
        if (busy || Project.Annotations.Count == 0) return;
        history.Checkpoint(Project); Project.Annotations.Clear(); Preview.SelectAnnotation(null); Refresh(); Status.Text = "All annotations cleared. Undo brings them back.";
    }
    private void EditAnnotationText(object sender, RoutedEventArgs e)
    {
        if (busy || SelectedAnnotation is not { Kind: AnnotationKind.Text } a) return;
        Pause(); Preview.BeginTextEdit(a);
    }
    private async void AnnotationBeginHere(object sender, RoutedEventArgs e) => await SetAnnotationBoundary(true);
    private async void AnnotationEndHere(object sender, RoutedEventArgs e) => await SetAnnotationBoundary(false);
    // Exact inclusive frames: the shown paused frame becomes the first or last annotated frame.
    private async Task SetAnnotationBoundary(bool begin)
    {
        if (busy || seekWork != null || SelectedAnnotation is not { } a || Preview.Timeline is not { } map) return;
        Pause(); if (Preview.UsePlayer) await SeekExact(Time);
        if (Preview.UsePlayer || !Project.Annotations.Contains(a)) return;
        var frame = map.Frames[map.IndexAt(Time)].Time;
        history.Checkpoint(Project);
        if (begin) { a.Start = frame; a.End = Math.Max(a.End, frame); } else { a.End = frame; a.Start = Math.Min(a.Start, frame); }
        Refresh();
        Status.Text = $"Annotation shown on frames {map.IndexAt(a.Start) + 1}–{map.IndexAt(a.End) + 1}, exactly (no extra buffer).";
    }
    private void OpenTextEditor(Annotation a)
    {
        Pause();
        var rect = Preview.ScreenRect(a.Box);
        TextEditorPanel.Visibility = Visibility.Visible; TextOptions.IsEnabled = false; PositionRegionPopup();
        updatingAnnotationUi = true;
        try
        {
            AnnotationTextBox.Text = a.Text;
            if (TextFont.ItemsSource == null) TextFont.ItemsSource = AnnotationFont.ItemsSource;
            ShowEditorStyle();
        }
        finally { updatingAnnotationUi = false; }
        TextEditorPanel.UpdateLayout();
        var width = TextEditorPanel.ActualWidth; var height = TextEditorPanel.ActualHeight;
        var x = Math.Clamp(rect.X + rect.Width / 2 - width / 2, 0, Math.Max(0, TextEditorLayer.ActualWidth - width));
        var y = rect.Bottom + 8;
        if (y + height > TextEditorLayer.ActualHeight) y = Math.Max(0, rect.Top - 8 - height);
        Canvas.SetLeft(TextEditorPanel, x); Canvas.SetTop(TextEditorPanel, y);
        AnnotationTextBox.Focus(); AnnotationTextBox.CaretIndex = AnnotationTextBox.Text.Length;
        Hint("Type the text. Enter adds a line; Ctrl+Enter or a click outside finishes; Esc cancels.");
    }
    internal void CloseTextEditor(bool cancel)
    {
        if (closingTextEditor || TextEditorPanel.Visibility != Visibility.Visible) return;
        closingTextEditor = true;
        try
        {
            TextEditorPanel.Visibility = Visibility.Collapsed; TextOptions.IsEnabled = true;
            var wasNew = Preview.EditingText is { } editing && !Project.Annotations.Contains(editing);
            if (cancel) { Preview.CancelTextEdit(); Status.Text = wasNew ? "Text cancelled." : "Text edit cancelled; the previous text and style are kept."; }
            else if (!Preview.CommitTextEdit() && string.IsNullOrWhiteSpace(AnnotationTextBox.Text))
                Status.Text = wasNew ? "No text was entered, so no text annotation was added." : "Empty text is not stored; the previous text is kept.";
            else Status.Text = "Text annotation updated. Double-click it to edit again.";
            Refresh();
        }
        finally { closingTextEditor = false; }
    }
    private void AnnotationTextChanged(object sender, TextChangedEventArgs e)
    {
        if (updatingAnnotationUi || Preview.EditingPreview is not { } working) return;
        working.Text = AnnotationTextBox.Text; Preview.InvalidateVisual();
    }
    // Text window: its style row edits the working copy live; Close/Ctrl+Enter
    // applies text and style together (one Undo step), Esc discards both.
    private void ShowEditorStyle()
    {
        if (Preview.EditingPreview is not { } s) return;
        TextColorFill.Background = new SolidColorBrush((Color)ColorConverter.ConvertFromString(s.Color));
        var fonts = (List<string>)AnnotationFont.ItemsSource;
        if (!fonts.Contains(s.FontFamily)) fonts.Add(s.FontFamily);
        TextFont.SelectedItem = s.FontFamily;
        if (!TextSize.IsKeyboardFocusWithin) TextSize.Text = s.FontSize.ToString("0.#", CultureInfo.InvariantCulture);
        TextBold.IsChecked = s.Bold; TextItalic.IsChecked = s.Italic;
        TextAlignLeft.IsChecked = s.Align == Core.AnnotationAlign.Left; TextAlignCentre.IsChecked = s.Align == Core.AnnotationAlign.Centre; TextAlignRight.IsChecked = s.Align == Core.AnnotationAlign.Right;
    }
    private void EditorChanged(Action<Annotation> change)
    {
        if (updatingAnnotationUi || Preview.EditingPreview is not { } working) return;
        change(working);
        updatingAnnotationUi = true; try { ShowEditorStyle(); } finally { updatingAnnotationUi = false; }
        Preview.InvalidateVisual();
    }
    private void EditorStyleChanged(object sender, SelectionChangedEventArgs e) => EditorChanged(s => { if (TextFont.SelectedItem is string font) s.FontFamily = font; });
    private void EditorStyleClicked(object sender, RoutedEventArgs e) => EditorChanged(s => { s.Bold = TextBold.IsChecked == true; s.Italic = TextItalic.IsChecked == true; });
    private void EditorAlignClicked(object sender, RoutedEventArgs e) =>
        EditorChanged(s => s.Align = (AnnotationAlign)int.Parse((string)((FrameworkElement)sender).Tag, CultureInfo.InvariantCulture));
    private void EditorSizeTyped(object sender, TextChangedEventArgs e) => EditorChanged(s =>
    {
        if (double.TryParse(TextSize.Text, NumberStyles.Float, CultureInfo.InvariantCulture, out var size) && size >= Annotation.MinFontSize && size <= Annotation.MaxFontSize) s.FontSize = Math.Round(size, 1);
    });
    private void EditorSizeStep(object sender, RoutedEventArgs e) => EditorChanged(s =>
    {
        s.FontSize = Math.Clamp(Math.Round(s.FontSize) + int.Parse((string)((FrameworkElement)sender).Tag, CultureInfo.InvariantCulture), Annotation.MinFontSize, Annotation.MaxFontSize);
        TextSize.Text = s.FontSize.ToString("0.#", CultureInfo.InvariantCulture);
    });
    private void ChooseEditorTextColor(object sender, RoutedEventArgs e)
    {
        if (Preview.EditingPreview is not { } working) return;
        var current = (Color)ColorConverter.ConvertFromString(working.Color);
        using var dialog = new System.Windows.Forms.ColorDialog { FullOpen = true, AnyColor = true, Color = System.Drawing.Color.FromArgb(current.R, current.G, current.B) };
        // The colour dialog takes focus; keep the editor open meanwhile.
        closingTextEditor = true;
        try { if (dialog.ShowDialog(new DialogOwner(new System.Windows.Interop.WindowInteropHelper(this).Handle)) != System.Windows.Forms.DialogResult.OK) return; }
        finally { closingTextEditor = false; AnnotationTextBox.Focus(); }
        EditorChanged(s => s.Color = $"#{dialog.Color.R:X2}{dialog.Color.G:X2}{dialog.Color.B:X2}");
    }
    private void AnnotationTextKey(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter && Keyboard.Modifiers.HasFlag(ModifierKeys.Control)) { CloseTextEditor(false); e.Handled = true; }
        else if (e.Key == Key.Escape) { CloseTextEditor(true); e.Handled = true; }
    }
    private void AnnotationTextDone(object sender, RoutedEventArgs e) => CloseTextEditor(false);
    // Clicking anywhere else confirms the editor, as in the baseline. Checked after the focus
    // move settles, so the font list's drop-down or the colour dialog don't close it.
    private void TextEditorFocusChanged(object sender, DependencyPropertyChangedEventArgs e)
    {
        if ((bool)e.NewValue || closingTextEditor) return;
        Dispatcher.BeginInvoke(() =>
        {
            if (TextEditorPanel.Visibility == Visibility.Visible && !TextEditorPanel.IsKeyboardFocusWithin && !TextFont.IsDropDownOpen && !closingTextEditor) CloseTextEditor(false);
        }, System.Windows.Threading.DispatcherPriority.Input);
    }
    private void DrawAnnotationLane(MediaReference m)
    {
        var violet = new SolidColorBrush(Color.FromRgb(0xA8, 0x55, 0xF7)); violet.Freeze();
        foreach (var a in Project.Annotations)
        {
            var left = a.Start / m.Duration * RangeLane.ActualWidth; var right = a.End / m.Duration * RangeLane.ActualWidth;
            var tip = $"Annotation \"{a}\": {a.Start:0.000}–{a.End:0.000} s";
            var line = new System.Windows.Shapes.Rectangle { Width = Math.Max(2, right - left), Height = 2, Fill = violet, ToolTip = tip };
            Canvas.SetLeft(line, left); Canvas.SetTop(line, 25); RangeLane.Children.Add(line);
            foreach (var x in new[] { left, right })
            { var dot = new System.Windows.Shapes.Ellipse { Width = 4, Height = 4, Fill = violet, ToolTip = tip }; Canvas.SetLeft(dot, x - 2); Canvas.SetTop(dot, 24); RangeLane.Children.Add(dot); }
        }
    }
}

// One picture in the Ends or Dashes list (0.15.0): a short line, its dashes and any
// arrowheads, drawn in a 64 × 14 box by App.xaml's LineStyleTemplate. Order matches the enums.
public sealed record LineStyleItem(string Name, Geometry Line, Geometry? Heads, DoubleCollection? Dash)
{
    private static readonly Geometry Straight = Geometry.Parse("M4,7 L60,7");
    private static DoubleCollection Pattern(params double[] values) { var d = new DoubleCollection(values); d.Freeze(); return d; }
    public static IReadOnlyList<LineStyleItem> Dashes { get; } =
    [
        new("Solid", Straight, null, null),
        new("Dash", Straight, null, Pattern(3, 2)),
        new("Dot", Straight, null, Pattern(1, 1)),
        new("Dash-Dot", Straight, null, Pattern(3, 1.5, 1, 1.5)),
        new("Dash-Dot-Dot", Straight, null, Pattern(3, 1.5, 1, 1.5, 1, 1.5)),
    ];
    public static IReadOnlyList<LineStyleItem> Ends { get; } =
    [
        new("No Arrows", Straight, null, null),
        new("Arrow at End", Geometry.Parse("M4,7 L52,7"), Geometry.Parse("M61,7 L50,1.5 L50,12.5 Z"), null),
        new("Arrow at Start", Geometry.Parse("M12,7 L60,7"), Geometry.Parse("M3,7 L14,1.5 L14,12.5 Z"), null),
        new("Arrows Both Ends", Geometry.Parse("M12,7 L52,7"), Geometry.Parse("M61,7 L50,1.5 L50,12.5 Z M3,7 L14,1.5 L14,12.5 Z"), null),
        new("Dot at End", Straight, Geometry.Parse("M62,7 A4,4 0 1 1 62,6.99 Z"), null),
        new("Dot at Start", Straight, Geometry.Parse("M10,7 A4,4 0 1 1 10,6.99 Z"), null),
        new("Dots Both Ends", Straight, Geometry.Parse("M62,7 A4,4 0 1 1 62,6.99 Z M10,7 A4,4 0 1 1 10,6.99 Z"), null),
    ];
}
