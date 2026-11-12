using System.Windows;
using System.Windows.Controls;
using System.Windows.Shapes;

namespace TinyRedaction.Desktop;

// The editor's toolbar as chosen in Settings › Editor (0.24.0, David): which buttons show, in which order, with
// separators, and which sit on the right (at the bottom when the toolbar is vertical).
public partial class MainWindow
{
    private Dictionary<string, Button>? toolbarButtons;
    // Every toolbar button by its name, collected once from MainWindow.xaml.
    private Dictionary<string, Button> ToolbarButtons => toolbarButtons ??=
        ToolButtons.Children.OfType<Button>().Concat(RightTools.Children.OfType<Button>()).Where(b => !string.IsNullOrEmpty(b.Name)).ToDictionary(b => b.Name);
    // The caption of each button, for the list in Settings (one line).
    internal static IReadOnlyDictionary<string, string> ToolbarLabels { get; private set; } = new Dictionary<string, string>();
    internal void ArrangeToolbar(AppSettings settings)
    {
        var buttons = ToolbarButtons;
        ToolbarLabels = buttons.ToDictionary(b => b.Key, b => ((b.Value.Content as string) ?? b.Key).Replace("\n", " "));
        ToolButtons.Children.Clear(); RightTools.Children.Clear();
        var panel = (Panel)ToolButtons;
        void Separator()
        {
            // No separator at either end of a side, nor two in a row.
            if (panel.Children.Count == 0 || panel.Children[^1] is Rectangle) return;
            panel.Children.Add(new Rectangle { Style = (Style)FindResource("ToolSeparator") });
        }
        foreach (var id in AppSettings.CleanToolbar(settings.EditorToolbar))
        {
            if (id == AppSettings.ToolbarSeparator) { Separator(); continue; }
            // 3.1.3: a blank gap the size of a button (sized in ApplySettings).
            if (id == AppSettings.ToolbarSpacer) { panel.Children.Add(new Border { Tag = AppSettings.ToolbarSpacer, Background = System.Windows.Media.Brushes.Transparent, IsHitTestVisible = false }); continue; }
            if (id == AppSettings.ToolbarRightSide) { TrimSeparator(panel); panel = RightTools; continue; }
            if (settings.EditorHiddenButtons.Contains(id) || !buttons.TryGetValue(id, out var button)) continue;
            panel.Children.Add(button);
        }
        TrimSeparator(panel);
        static void TrimSeparator(Panel side) { if (side.Children.Count > 0 && side.Children[^1] is Rectangle) side.Children.RemoveAt(side.Children.Count - 1); }
    }
    // Whether a button is on the toolbar (checks).
    internal bool OnToolbar(string id) => ToolbarButtons.TryGetValue(id, out var b) && (ToolButtons.Children.Contains(b) || RightTools.Children.Contains(b));
    internal int SpacerCount => ToolButtons.Children.Cast<UIElement>().Concat(RightTools.Children.Cast<UIElement>()).Count(c => c is Border { Tag: AppSettings.ToolbarSpacer });
    internal bool OnRightSide(string id) => ToolbarButtons.TryGetValue(id, out var b) && RightTools.Children.Contains(b);
}
