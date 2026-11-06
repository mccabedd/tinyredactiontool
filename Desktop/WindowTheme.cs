using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using Forms = System.Windows.Forms;
using Drawing = System.Drawing;

namespace TinyRedaction.Desktop;

// Light and Dark beyond TRT's own colours (0.28.0, David: menus and dialogue boxes follow the theme): every TRT window's
// title bar is drawn dark in Dark (Windows 10 2004 and later, and Windows 11), and the Windows Forms menus (the
// notification-area menu and the ruler's menu) get the same colours as TRT's WPF menus.
internal static class WindowTheme
{
    private static bool registered;
    // Each TRT window takes the theme's title bar when it is shown.
    public static void Register()
    {
        if (registered) return;
        registered = true;
        EventManager.RegisterClassHandler(typeof(Window), FrameworkElement.LoadedEvent, new RoutedEventHandler((sender, _) => Apply((Window)sender)));
    }
    public static void ApplyToAll()
    {
        if (Application.Current == null) return;
        foreach (Window window in Application.Current.Windows) Apply(window);
    }
    public static void Apply(Window window)
    {
        var handle = new WindowInteropHelper(window).Handle;
        if (handle == IntPtr.Zero) return;
        var dark = MainWindow.DarkTheme ? 1 : 0;
        try { _ = DwmSetWindowAttribute(handle, UseImmersiveDarkMode, ref dark, sizeof(int)); }
        catch (Exception ex) when (ex is DllNotFoundException or EntryPointNotFoundException) { }
    }
    // What Windows was last asked to draw for this window's title bar (for checks).
    internal static bool? TitleBarDark(Window window)
    {
        var handle = new WindowInteropHelper(window).Handle;
        if (handle == IntPtr.Zero) return null;
        try { return DwmGetWindowAttribute(handle, UseImmersiveDarkMode, out var value, sizeof(int)) == 0 ? value != 0 : null; }
        catch (Exception ex) when (ex is DllNotFoundException or EntryPointNotFoundException) { return null; }
    }
    private const int UseImmersiveDarkMode = 20;
    [DllImport("dwmapi.dll")] private static extern int DwmSetWindowAttribute(IntPtr window, int attribute, ref int value, int size);
    [DllImport("dwmapi.dll")] private static extern int DwmGetWindowAttribute(IntPtr window, int attribute, out int value, int size);

    // ---- Windows Forms menus ----
    public static void Apply(Forms.ToolStrip menu, bool dark)
    {
        var colours = new MenuColours(dark);
        menu.Renderer = new Forms.ToolStripProfessionalRenderer(colours) { RoundedEdges = false };
        menu.BackColor = colours.MenuBack; menu.ForeColor = colours.Text;
        foreach (Forms.ToolStripItem item in menu.Items) { item.ForeColor = colours.Text; item.BackColor = colours.MenuBack; }
    }
    internal sealed class MenuColours(bool dark) : Forms.ProfessionalColorTable
    {
        public readonly Drawing.Color MenuBack = dark ? Drawing.Color.FromArgb(0x33, 0x33, 0x33) : Drawing.Color.FromArgb(0xFB, 0xFB, 0xFB);
        public readonly Drawing.Color Text = dark ? Drawing.Color.FromArgb(0xF0, 0xF0, 0xF0) : Drawing.Color.FromArgb(0x1E, 0x1E, 0x1E);
        private readonly Drawing.Color hover = dark ? Drawing.Color.FromArgb(0x61, 0x61, 0x61) : Drawing.Color.FromArgb(0xE5, 0xF1, 0xFB);
        private readonly Drawing.Color line = dark ? Drawing.Color.FromArgb(0x6E, 0x6E, 0x6E) : Drawing.Color.FromArgb(0xC8, 0xC8, 0xC8);
        public override Drawing.Color ToolStripDropDownBackground => MenuBack;
        public override Drawing.Color ImageMarginGradientBegin => MenuBack;
        public override Drawing.Color ImageMarginGradientMiddle => MenuBack;
        public override Drawing.Color ImageMarginGradientEnd => MenuBack;
        public override Drawing.Color MenuBorder => line;
        public override Drawing.Color MenuItemBorder => hover;
        public override Drawing.Color MenuItemSelected => hover;
        public override Drawing.Color MenuItemSelectedGradientBegin => hover;
        public override Drawing.Color MenuItemSelectedGradientEnd => hover;
        public override Drawing.Color MenuItemPressedGradientBegin => hover;
        public override Drawing.Color MenuItemPressedGradientEnd => hover;
        public override Drawing.Color SeparatorDark => line;
        public override Drawing.Color SeparatorLight => MenuBack;
        public override Drawing.Color CheckBackground => hover;
        public override Drawing.Color CheckSelectedBackground => hover;
        public override Drawing.Color CheckPressedBackground => hover;
    }
}
