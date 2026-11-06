using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Documents;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace TinyRedaction.Desktop;

// 3.0.0 (David: Help in TRT's own window, whatever browser the PC has). The manual stays one web page
// (help/TRT-Help.html, readable on GitHub too); TRT reads its plain set of tags and lays the same text, pictures,
// steps, boxes and tables out itself, in TRT's theme. Nothing here starts a browser or fetches anything.
internal sealed class HtmlNode
{
    public string Name { get; init; } = "";
    public Dictionary<string, string> Attributes { get; } = new(StringComparer.OrdinalIgnoreCase);
    public List<HtmlNode> Children { get; } = [];
    public string? Text { get; init; }
    public string Attribute(string name) => Attributes.TryGetValue(name, out var value) ? value : "";
    public bool HasClass(string name) => Attribute("class").Split(' ', StringSplitOptions.RemoveEmptyEntries).Contains(name);
    public IEnumerable<HtmlNode> Descendants() => Children.SelectMany(c => new[] { c }.Concat(c.Descendants()));
    public HtmlNode? Find(string name) => Descendants().FirstOrDefault(d => d.Name == name);
    public string InnerText => Text != null ? WebUtility.HtmlDecode(Text) : string.Concat(Children.Select(c => c.InnerText));

    private static readonly HashSet<string> Void = ["img", "meta", "link", "br", "hr", "input"];
    // A small, forgiving reader for the manual's own markup (closed tags, quoted attributes).
    public static HtmlNode Parse(string html)
    {
        var root = new HtmlNode { Name = "#root" };
        var open = new Stack<HtmlNode>(); open.Push(root);
        var i = 0;
        while (i < html.Length)
        {
            if (html[i] != '<')
            {
                var next = html.IndexOf('<', i); if (next < 0) next = html.Length;
                open.Peek().Children.Add(new HtmlNode { Name = "#text", Text = html[i..next] });
                i = next; continue;
            }
            if (string.CompareOrdinal(html, i, "<!--", 0, 4) == 0) { var end = html.IndexOf("-->", i, StringComparison.Ordinal); i = end < 0 ? html.Length : end + 3; continue; }
            var close = html.IndexOf('>', i); if (close < 0) break;
            var tag = html[(i + 1)..close]; i = close + 1;
            if (tag.StartsWith('!') || tag.StartsWith('?')) continue;
            if (tag.StartsWith('/'))
            {
                var name = tag[1..].Trim().ToLowerInvariant();
                if (open.Any(n => n.Name == name)) while (open.Count > 1 && open.Pop().Name != name) { }
                continue;
            }
            var selfClosing = tag.EndsWith('/'); if (selfClosing) tag = tag[..^1];
            var m = Regex.Match(tag, @"^\s*([A-Za-z0-9]+)");
            if (!m.Success) continue;
            var node = new HtmlNode { Name = m.Groups[1].Value.ToLowerInvariant() };
            foreach (Match a in Regex.Matches(tag[m.Length..], "([A-Za-z_:][-A-Za-z0-9_:.]*)(?:\\s*=\\s*(?:\"([^\"]*)\"|'([^']*)'|([^\\s\"'>]+)))?"))
                node.Attributes[a.Groups[1].Value] = WebUtility.HtmlDecode(a.Groups[2].Success ? a.Groups[2].Value : a.Groups[3].Success ? a.Groups[3].Value : a.Groups[4].Value);
            open.Peek().Children.Add(node);
            if (node.Name is "script" or "style")
            {
                var end = html.IndexOf("</" + node.Name, i, StringComparison.OrdinalIgnoreCase);
                i = end < 0 ? html.Length : html.IndexOf('>', end) + 1; continue;
            }
            if (!selfClosing && !Void.Contains(node.Name)) open.Push(node);
        }
        return root;
    }
}

internal sealed record HelpTopic(string Group, string Title, string Id);

internal sealed class HelpPalette
{
    public required Color Back, Panel, Line, Text, Soft, Accent, AccentSoft, Tip, TipLine, Warn, WarnLine, Stop, StopLine, Badge;
    // The manual's own colours (TRT-Help.html's :root and dark blocks).
    public static HelpPalette For(bool dark) => dark
        ? new() { Back = C("#2b2b2b"), Panel = C("#353535"), Line = C("#4a4a4a"), Text = C("#f0f0f0"), Soft = C("#b9bec6"), Accent = C("#8fb8e6"), AccentSoft = C("#2f3e4e"), Tip = C("#243528"), TipLine = C("#66bb6a"), Warn = C("#3a3020"), WarnLine = C("#f2c27a"), Stop = C("#3c2524"), StopLine = C("#ef7b72"), Badge = C("#d32f2f") }
        : new() { Back = C("#ffffff"), Panel = C("#f3f4f6"), Line = C("#d9dce1"), Text = C("#1e1e1e"), Soft = C("#5b6470"), Accent = C("#1765a5"), AccentSoft = C("#e5f1fb"), Tip = C("#eaf6ec"), TipLine = C("#2e7d32"), Warn = C("#fff4e0"), WarnLine = C("#c77700"), Stop = C("#fdecea"), StopLine = C("#b3261e"), Badge = C("#d32f2f") };
    private static Color C(string hex) => (Color)ColorConverter.ConvertFromString(hex);
    public SolidColorBrush Brush(Color c) { var b = new SolidColorBrush(c); b.Freeze(); return b; }
}

internal sealed class HelpDocument
{
    public FlowDocument Document { get; }
    public string Title { get; private set; } = "TinyRedactionTool Help";
    public string Subtitle { get; private set; } = "";
    public List<HelpTopic> Topics { get; } = [];
    public Dictionary<string, Block> Targets { get; } = [];
    public List<Hyperlink> Links { get; } = [];
    public List<string> MissingPictures { get; } = [];
    public int Pictures { get; private set; }
    public event Action<string>? LinkClicked;

    private readonly string folder;
    private readonly HelpPalette p;
    private bool firstHeading = true;

    public HelpDocument(string manualPath, bool dark)
    {
        folder = Path.GetDirectoryName(manualPath)!;
        p = HelpPalette.For(dark);
        Document = new FlowDocument
        {
            FontFamily = new FontFamily("Segoe UI"), FontSize = 14.5, LineHeight = 23, Background = p.Brush(p.Back), Foreground = p.Brush(p.Text),
            PagePadding = new Thickness(36, 6, 36, 60), TextAlignment = TextAlignment.Left, ColumnWidth = 100000, MaxPageWidth = 1000,
        };
        var root = HtmlNode.Parse(File.ReadAllText(manualPath, Encoding.UTF8));
        if (root.Find("header") is { } header)
        {
            Title = header.Find("h1")?.InnerText.Trim() ?? Title;
            Subtitle = Collapse(header.Find("p")?.InnerText ?? "").Trim();
        }
        if (root.Find("nav") is { } nav)
        {
            var group = "";
            foreach (var item in nav.Children)
            {
                if (item.Name == "strong") group = item.InnerText.Trim();
                else if (item.Name == "a" && item.Attribute("href").StartsWith('#')) Topics.Add(new(group, Collapse(item.InnerText).Trim(), item.Attribute("href")[1..]));
            }
        }
        if (root.Find("main") is { } main) foreach (var block in Blocks(main.Children)) Document.Blocks.Add(block);
    }

    private static string Collapse(string text) => Regex.Replace(text, @"\s+", " ");

    // ---- Blocks ----
    private IEnumerable<Block> Blocks(IEnumerable<HtmlNode> nodes)
    {
        var loose = new List<HtmlNode>();
        IEnumerable<Block> Flush()
        {
            if (loose.Count == 0 || loose.All(n => n.Name == "#text" && string.IsNullOrWhiteSpace(n.Text))) { loose.Clear(); yield break; }
            var para = Paragraph(loose); loose = []; yield return para;
        }
        foreach (var n in nodes)
        {
            if (!IsBlock(n)) { loose.Add(n); continue; }
            foreach (var b in Flush()) yield return b;
            foreach (var b in Block(n)) yield return b;
        }
        foreach (var b in Flush()) yield return b;
    }
    private static bool IsBlock(HtmlNode n) => n.Name is "h1" or "h2" or "h3" or "p" or "ul" or "ol" or "table" or "figure" or "div" or "dl" or "dt" or "dd";

    private IEnumerable<Block> Block(HtmlNode n)
    {
        switch (n.Name)
        {
            case "h2":
            {
                var heading = Paragraph(n.Children);
                heading.FontSize = 22; heading.FontWeight = FontWeights.SemiBold; heading.LineHeight = 30;
                heading.Margin = new Thickness(0, firstHeading ? 14 : 34, 0, 8);
                if (!firstHeading) { heading.BorderBrush = p.Brush(p.Line); heading.BorderThickness = new Thickness(0, 1, 0, 0); heading.Padding = new Thickness(0, 16, 0, 0); }
                firstHeading = false;
                if (n.Attribute("id") is { Length: > 0 } id) { heading.Tag = id; Targets[id] = heading; }
                yield return heading; break;
            }
            case "h3":
            {
                var heading = Paragraph(n.Children);
                heading.FontSize = 17; heading.FontWeight = FontWeights.SemiBold; heading.Margin = new Thickness(0, 18, 0, 4);
                yield return heading; break;
            }
            case "p": yield return Paragraph(n.Children); break;
            case "ul": case "ol": yield return List(n); break;
            case "table": yield return Table(n); break;
            case "figure": yield return new BlockUIContainer(Figure(n)) { Margin = new Thickness(0, 10, 0, 16) }; break;
            case "dl":
                foreach (var item in n.Children.Where(c => c.Name is "dt" or "dd"))
                {
                    var para = Paragraph(item.Children);
                    if (item.Name == "dt") { para.FontWeight = FontWeights.SemiBold; para.Margin = new Thickness(0, 14, 0, 2); }
                    else para.Margin = new Thickness(0, 0, 0, 0);
                    yield return para;
                }
                break;
            case "div" when n.HasClass("box"): yield return Box(n); break;
            case "div" when n.HasClass("two"):
            {
                var grid = new UniformGrid { Columns = 2 };
                foreach (var figure in n.Children.Where(c => c.Name == "figure")) { var f = Figure(figure); f.Margin = new Thickness(0, 0, 18, 0); grid.Children.Add(f); }
                yield return new BlockUIContainer(grid) { Margin = new Thickness(0, 10, 0, 16) }; break;
            }
            default: foreach (var b in Blocks(n.Children)) yield return b; break;
        }
    }

    private Paragraph Paragraph(IEnumerable<HtmlNode> nodes)
    {
        var para = new Paragraph { Margin = new Thickness(0, 6, 0, 6) };
        foreach (var inline in Inlines(nodes)) para.Inlines.Add(inline);
        Trim(para.Inlines);
        return para;
    }
    // HTML ignores the spaces at the start and end of a block.
    private static void Trim(InlineCollection inlines)
    {
        while (inlines.FirstInline is Run first && first.Text.TrimStart().Length == 0) inlines.Remove(first);
        if (inlines.FirstInline is Run start) start.Text = start.Text.TrimStart();
        else if (inlines.FirstInline is Span span) Trim(span.Inlines);
        while (inlines.LastInline is Run last && last.Text.TrimEnd().Length == 0) inlines.Remove(last);
        if (inlines.LastInline is Run end) end.Text = end.Text.TrimEnd();
    }

    private List List(HtmlNode n)
    {
        var steps = n.Name == "ol";
        var list = new List { MarkerStyle = steps ? TextMarkerStyle.Decimal : TextMarkerStyle.Disc, Margin = new Thickness(0, 4, 0, 8), Padding = new Thickness(steps ? 30 : 24, 0, 0, 0) };
        foreach (var li in n.Children.Where(c => c.Name == "li"))
        {
            var item = new ListItem { Margin = new Thickness(0, steps ? 4 : 2, 0, steps ? 4 : 2) };
            foreach (var b in Blocks(li.Children)) { if (b is Paragraph para) para.Margin = new Thickness(0); item.Blocks.Add(b); }
            list.ListItems.Add(item);
        }
        if (steps) list.FontWeight = FontWeights.Normal;
        return list;
    }

    private Table Table(HtmlNode n)
    {
        var rows = n.Descendants().Where(d => d.Name == "tr").ToList();
        var columns = rows.Count == 0 ? 1 : rows.Max(r => r.Children.Count(c => c.Name is "td" or "th"));
        var table = new Table { CellSpacing = 0, Margin = new Thickness(0, 8, 0, 14) };
        double[] widths = columns switch { 1 => [1], 2 => [n.HasClass("tools") ? 0.9 : 1, 2.6], 3 => [0.35, 1, 3], _ => Enumerable.Repeat(1.0, columns).ToArray() };
        foreach (var w in widths) table.Columns.Add(new TableColumn { Width = new GridLength(w, GridUnitType.Star) });
        var group = new TableRowGroup(); table.RowGroups.Add(group);
        foreach (var tr in rows)
        {
            var row = new TableRow();
            foreach (var cellNode in tr.Children.Where(c => c.Name is "td" or "th"))
            {
                var cell = new TableCell { Padding = new Thickness(8, 5, 8, 5), BorderBrush = p.Brush(p.Line), BorderThickness = new Thickness(0, 0, 0, 1) };
                foreach (var b in Blocks(cellNode.Children)) { if (b is Paragraph para) para.Margin = new Thickness(0); cell.Blocks.Add(b); }
                if (cell.Blocks.Count == 0) cell.Blocks.Add(new Paragraph());
                if (cellNode.Name == "th") { cell.Background = p.Brush(p.Panel); cell.FontWeight = FontWeights.SemiBold; }
                row.Cells.Add(cell);
            }
            group.Rows.Add(row);
        }
        return table;
    }

    private Section Box(HtmlNode n)
    {
        var (back, line) = n.HasClass("stop") ? (p.Stop, p.StopLine) : n.HasClass("warn") ? (p.Warn, p.WarnLine) : (p.Tip, p.TipLine);
        var section = new Section { Background = p.Brush(back), BorderBrush = p.Brush(line), BorderThickness = new Thickness(4, 0, 0, 0), Padding = new Thickness(14, 8, 14, 8), Margin = new Thickness(0, 10, 0, 12) };
        // The box's first bold words are its title, on a line of their own.
        var children = n.Children.SkipWhile(c => c.Name == "#text" && string.IsNullOrWhiteSpace(c.Text)).ToList();
        if (children.FirstOrDefault() is { Name: "b" } title)
        {
            var heading = Paragraph(title.Children); heading.FontWeight = FontWeights.SemiBold; heading.Margin = new Thickness(0, 0, 0, 2);
            section.Blocks.Add(heading); children.RemoveAt(0);
        }
        foreach (var b in Blocks(children)) { if (b is Paragraph para) para.Margin = new Thickness(0); section.Blocks.Add(b); }
        return section;
    }

    private FrameworkElement Figure(HtmlNode n)
    {
        var panel = new StackPanel { HorizontalAlignment = HorizontalAlignment.Left };
        var img = n.Children.FirstOrDefault(c => c.Name == "img");
        if (img != null && Picture(img) is { } picture)
        {
            var style = img.Attribute("style");
            var width = Regex.Match(style, @"max-width:\s*(\d+)px") is { Success: true } m ? double.Parse(m.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture) : picture.Width;
            var image = new Image { Source = picture, Stretch = Stretch.Uniform, StretchDirection = StretchDirection.DownOnly, MaxWidth = Math.Min(width, picture.Width), ToolTip = img.Attribute("alt") is { Length: > 0 } alt ? alt : null };
            RenderOptions.SetBitmapScalingMode(image, BitmapScalingMode.HighQuality);
            var badges = n.HasClass("callouts") ? n.Children.Where(c => c.Name == "span").ToList() : [];
            var framed = new Grid { HorizontalAlignment = HorizontalAlignment.Left };
            framed.Children.Add(image);
            if (badges.Count > 0)
            {
                // The numbered red badges sit at the same places on the picture as on the web page (left/top in per cent).
                var canvas = new Canvas { IsHitTestVisible = false };
                var placed = new List<(FrameworkElement Badge, double X, double Y)>();
                foreach (var b in badges)
                {
                    double Percent(string key) => Regex.Match(b.Attribute("style"), key + @":\s*([\d.]+)%") is { Success: true } v ? double.Parse(v.Groups[1].Value, System.Globalization.CultureInfo.InvariantCulture) / 100 : 0;
                    var badge = new Border { Width = 28, Height = 28, CornerRadius = new CornerRadius(14), Background = p.Brush(p.Badge),
                        Child = new TextBlock { Text = b.InnerText.Trim(), Foreground = Brushes.White, FontWeight = FontWeights.Bold, FontSize = 15, HorizontalAlignment = HorizontalAlignment.Center, VerticalAlignment = VerticalAlignment.Center } };
                    canvas.Children.Add(badge); placed.Add((badge, Percent("left"), Percent("top")));
                }
                canvas.SizeChanged += (_, e) => { foreach (var (badge, x, y) in placed) { Canvas.SetLeft(badge, x * e.NewSize.Width - 14); Canvas.SetTop(badge, y * e.NewSize.Height - 14); } };
                framed.Children.Add(canvas);
            }
            panel.Children.Add(new Border { Child = framed, BorderBrush = p.Brush(p.Line), BorderThickness = new Thickness(1), HorizontalAlignment = HorizontalAlignment.Left });
        }
        if (n.Children.FirstOrDefault(c => c.Name == "figcaption") is { } caption)
            panel.Children.Add(new TextBlock { Text = Collapse(caption.InnerText).Trim(), Foreground = p.Brush(p.Soft), FontSize = 13, TextWrapping = TextWrapping.Wrap, Margin = new Thickness(0, 6, 0, 0), MaxWidth = 900 });
        return panel;
    }

    private BitmapSource? Picture(HtmlNode img)
    {
        var src = img.Attribute("src");
        if (src.Length == 0 || src.Contains(':')) return null; // Never anything from outside the manual's folder.
        var path = Path.GetFullPath(Path.Combine(folder, src.Replace('/', Path.DirectorySeparatorChar)));
        if (!path.StartsWith(folder, StringComparison.OrdinalIgnoreCase) || !File.Exists(path)) { MissingPictures.Add(src); return null; }
        try
        {
            var bitmap = new BitmapImage();
            bitmap.BeginInit(); bitmap.CacheOption = BitmapCacheOption.OnLoad; bitmap.UriSource = new Uri(path); bitmap.EndInit(); bitmap.Freeze();
            Pictures++;
            // Shown at its pixel size (the help pictures are made at 96 dpi).
            return bitmap.DpiX is > 0 and not 96 ? Rescale(bitmap) : bitmap;
        }
        catch (Exception ex) when (ex is IOException or NotSupportedException or UriFormatException or InvalidOperationException) { MissingPictures.Add(src); return null; }
    }
    private static BitmapSource Rescale(BitmapSource b)
    {
        var stride = (b.PixelWidth * b.Format.BitsPerPixel + 7) / 8; var pixels = new byte[stride * b.PixelHeight]; b.CopyPixels(pixels, stride, 0);
        var copy = BitmapSource.Create(b.PixelWidth, b.PixelHeight, 96, 96, b.Format, b.Palette, pixels, stride); copy.Freeze(); return copy;
    }

    // ---- Inlines ----
    private IEnumerable<Inline> Inlines(IEnumerable<HtmlNode> nodes)
    {
        foreach (var n in nodes)
        {
            switch (n.Name)
            {
                case "#text":
                    var text = Collapse(WebUtility.HtmlDecode(n.Text ?? ""));
                    if (text.Length > 0) yield return new Run(text);
                    break;
                case "b" or "strong":
                    yield return Wrap(new Bold(), n); break;
                case "span" when n.HasClass("ui"):
                    yield return Wrap(new Bold { FontWeight = FontWeights.SemiBold }, n); break;
                case "kbd":
                    yield return new InlineUIContainer(new Border
                    {
                        BorderBrush = p.Brush(p.Line), BorderThickness = new Thickness(1, 1, 1, 2), CornerRadius = new CornerRadius(4), Background = p.Brush(p.Panel), Padding = new Thickness(5, 0, 5, 0), Margin = new Thickness(1, 0, 1, 0),
                        Child = new TextBlock { Text = n.InnerText, FontSize = 12.5, Foreground = p.Brush(p.Text) },
                    }) { BaselineAlignment = BaselineAlignment.Center };
                    break;
                case "img":
                    if (Picture(n) is { } icon)
                    {
                        var image = new Image { Source = icon, Height = 26, Stretch = Stretch.Uniform, Margin = new Thickness(1, 0, 1, 0), ToolTip = n.Attribute("alt") is { Length: > 0 } alt ? alt : null };
                        RenderOptions.SetBitmapScalingMode(image, BitmapScalingMode.HighQuality);
                        yield return new InlineUIContainer(image) { BaselineAlignment = BaselineAlignment.Center };
                    }
                    break;
                case "a":
                    var target = n.Attribute("href");
                    if (target.StartsWith('#'))
                    {
                        var link = (Hyperlink)Wrap(new Hyperlink { Foreground = p.Brush(p.Accent), Cursor = System.Windows.Input.Cursors.Hand }, n);
                        var id = target[1..]; link.Click += (_, _) => LinkClicked?.Invoke(id); link.Tag = id; Links.Add(link);
                        yield return link;
                    }
                    else yield return Wrap(new Span(), n); // Only links inside the manual work; nothing opens a browser.
                    break;
                default:
                    foreach (var inline in Inlines(n.Children)) yield return inline;
                    break;
            }
        }
    }
    private Span Wrap(Span span, HtmlNode n) { foreach (var inline in Inlines(n.Children)) span.Inlines.Add(inline); return span; }
}
