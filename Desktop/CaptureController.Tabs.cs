using System.Windows;

namespace TinyRedaction.Desktop;

// Tabs (3.5.0, David). Each tab is an editor window of its own; one is shown at a time, all in the same place, with the
// same tab bar along the top. Switching tabs shows the chosen one where the last one was and hides the other, so each
// keeps its own picture or video, Undo, zoom and side panel. A new screenshot, recording or opened file goes to a new
// tab when the shown one already has something in it.
internal sealed partial class CaptureController
{
    private readonly List<MainWindow> tabs = [];
    private MainWindow? closingShown; private string? closingPlace; // The shown tab that is closing: the next one takes its place.
    internal IReadOnlyList<MainWindow> Tabs => tabs;
    // Checks written before tabs keep one tab: captures, files and Paste replace what it shows, as they did then.
    internal bool ReplaceInShownTab { get; set; }

    internal void RefreshTabs()
    {
        foreach (var tab in tabs) tab.ShowTabs(tabs, editor);
    }
    // Shows this tab where the shown one is, then hides the other.
    internal void SelectTab(MainWindow tab)
    {
        if (!tabs.Contains(tab)) return;
        var from = editor;
        editor = tab;
        if (from != null && from != tab && from.IsVisible)
        {
            tab.TakePlacement(from);
            tab.Show(); tab.Activate();
            from.Hide();
        }
        else { tab.Show(); if (tab.WindowState == WindowState.Minimized) tab.WindowState = WindowState.Normal; tab.Activate(); }
        RefreshTabs();
    }
    internal MainWindow NewTab(MainWindow? from)
    {
        from ??= editor;
        if (from == null || !tabs.Contains(from)) return OpenEditor();
        var created = CreateEditor();
        created.TakePlacement(from);
        SelectTab(created);
        return created;
    }
    internal MainWindow NewEmptyTab(MainWindow from) => NewTab(from);
    internal void StepTab(MainWindow from, int step)
    {
        if (tabs.Count < 2 || tabs.IndexOf(from) is var at && at < 0) return;
        SelectTab(tabs[((at + step) % tabs.Count + tabs.Count) % tabs.Count]);
    }
    // Opens something in a new tab; if it doesn't open, the new tab goes again and the previous one is shown.
    internal async Task<bool> OpenInNewTabAsync(MainWindow from, Func<MainWindow, Task<bool>> open)
    {
        var tab = NewTab(from);
        var opened = false;
        try { opened = await open(tab); }
        finally
        {
            if (!opened && tabs.Contains(tab) && tab.IsEmptyTab)
            {
                if (tabs.Contains(from)) SelectTab(from);
                tab.CloseAsTab();
            }
        }
        return opened;
    }

    // The tab's ✕, Ctrl+W, a middle click: asks when it has unsaved work (No and Cancel both keep it).
    internal bool CloseTab(MainWindow tab)
    {
        if (!tabs.Contains(tab)) return true;
        if (tab.IsBusy) { SelectTab(tab); ThemedMessage.Show(tab, "Cancel the current task and wait for it to stop, then close.", "Still Working"); return false; }
        if (tab.HasUnsavedWork)
        {
            if (tab != editor) SelectTab(tab); // The question is about the tab in view.
            if (tab.AskDiscard() != MessageBoxResult.Yes) return false;
        }
        return CloseAnswered(tab);
    }
    private bool CloseAnswered(MainWindow tab)
    {
        // The tab to its left takes its place (the first tab's: the one to its right).
        if (tab == editor && tabs.Count > 1) { var at = tabs.IndexOf(tab); SelectTab(tabs[at > 0 ? at - 1 : 1]); }
        return tab.CloseAsTab();
    }
    private void WatchClosing(MainWindow tab, System.ComponentModel.CancelEventArgs e)
    {
        if (e.Cancel || !tab.IsVisible) return;
        closingShown = tab; closingPlace = tab.CurrentPlacement();
    }
    private void TabClosed(MainWindow tab)
    {
        var at = tabs.IndexOf(tab);
        tabs.Remove(tab);
        if (editor == tab)
        {
            // The shown tab went (the window's own ✕ on a last tab, or a check): the one beside it takes its place.
            editor = tabs.Count == 0 ? null : tabs[Math.Clamp(at - 1, 0, tabs.Count - 1)];
            if (editor == windowClosing && tabs.FirstOrDefault(t => t != windowClosing) is { } other) editor = other;
            if (editor != null && editor != windowClosing && !editor.IsVisible && !quitting && !disposed)
            {
                if (closingShown == tab && closingPlace != null) editor.ApplyPlacement(closingPlace);
                editor.Show(); editor.Activate();
            }
        }
        if (closingShown == tab) { closingShown = null; closingPlace = null; }
        RefreshTabs();
    }

    // File › Close All Tabs (keepEditorOpen: the editor stays with one empty tab), the window's ✕ and Quit (it closes).
    // Unsaved tabs are shown and asked about in turn: Yes closes that tab, No keeps it and goes on to the next, Cancel
    // stops (the rest stay open). True when every tab closed (or, keeping the editor open, was emptied).
    internal bool CloseAllTabs(bool keepEditorOpen)
    {
        var all = true;
        foreach (var tab in tabs.ToList())
        {
            if (!tabs.Contains(tab)) continue;
            if (tab.IsBusy) { SelectTab(tab); ThemedMessage.Show(tab, "Cancel the current task and wait for it to stop, then close.", "Still Working"); return false; }
            if (tab.HasUnsavedWork)
            {
                if (tab != editor) SelectTab(tab);
                var answer = tab.AskDiscard();
                if (answer == MessageBoxResult.Cancel) return false;
                if (answer == MessageBoxResult.No) { all = false; continue; }
            }
            if (keepEditorOpen && tabs.Count == 1) { tab.ResetTab(); RefreshTabs(); return all; }
            if (!CloseAnswered(tab)) return false;
        }
        return all;
    }

    // The editor window's own ✕ (or Close Editor) on the tab in view: the other tabs close first. Each unsaved one is
    // shown in turn (over the closing one) and asked about: Yes closes it, No keeps it, Cancel stops (false: nothing
    // more closes, the tab in view included). The closing tab then asks its own question.
    private MainWindow? windowClosing; // Can't be shown again while it closes.
    internal bool CloseOtherTabs(MainWindow closing)
    {
        windowClosing = closing;
        try { return CloseOthers(closing); } finally { windowClosing = null; }
    }
    private bool CloseOthers(MainWindow closing)
    {
        foreach (var tab in tabs.ToList())
        {
            if (tab == closing || !tabs.Contains(tab)) continue;
            if (tab.IsBusy) { ThemedMessage.Show(closing, "Another tab is still working. Cancel its task and wait for it to stop, then close.", "Still Working"); return false; }
            if (tab.HasUnsavedWork)
            {
                if (!tab.IsVisible) { tab.TakePlacement(closing); tab.Show(); }
                tab.Activate();
                var answer = tab.AskDiscard();
                if (answer == MessageBoxResult.Cancel) { if (tab != editor) tab.Hide(); closing.Activate(); return false; }
                if (answer == MessageBoxResult.No) { if (tab != editor) tab.Hide(); continue; }
            }
            if (tab.IsVisible && tab != editor) tab.Hide();
            tab.CloseAsTab();
        }
        if (closing.IsVisible) closing.Activate();
        return true;
    }

    // File › Save All Tabs: Save in each tab with something unsaved, in turn (each is shown while it saves; a
    // screenshot asks where to save it). Stops at a tab that wasn't saved (cancelled, or not ready), and shows it.
    internal async Task<int> SaveAllTabsAsync()
    {
        var start = editor; var saved = 0;
        foreach (var tab in tabs.ToList())
        {
            if (!tabs.Contains(tab) || !tab.NeedsSave) continue;
            if (tab != editor) SelectTab(tab);
            if (!await tab.SaveAsync()) { tab.Notice($"Save All Tabs stopped here: this tab was not saved. {(saved == 0 ? "No tabs were" : saved == 1 ? "1 tab was" : $"{saved} tabs were")} saved before it."); return saved; }
            saved++;
        }
        if (start != null && tabs.Contains(start) && start != editor) SelectTab(start);
        editor?.Notice(saved == 0 ? "Every tab was already saved." : saved == 1 ? "Saved 1 tab." : $"Saved {saved} tabs.");
        return saved;
    }
}
