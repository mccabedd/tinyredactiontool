# TinyRedactionTool v2.5.0 FINAL
# Consolidated from user-tested B1-r4 source SHA-256
# 594488A98BAFC465F90ECEB7CA43CC4E4C50879869CC5619A14BCC07F6AE1D0D
# Frozen v2.1.0 ancestry SHA-256
# 2BC392FD52587343AB4CEA95B19C295286E44E4D3543634D9D3D1E383567BDC7
# Accepted D1b Default Pixelate preview-parity source SHA-256
# 177906F4208F0E2F629108057169EDF8647DD6C713885ED65FD726D02C2CDA21
#
# D2 is an RC-facing polish slice only: user-facing Default/Aggressive
# terminology, the locked Blur/Pixelate warning copy, and the lighter
# #3C3F47 Dark Mode base. Export/media logic remains D1b.
#
# D3 changes ONLY the compact warning-dialog presentation plumbing needed for
# the Blur/Pixelate warning: bold the word Aggressive and pre-tick the
# session-suppression checkbox for that warning only.
##
# RC1 freeze note:
# Application behaviour is frozen from the accepted D3 candidate. The only
# runtime-visible RC-preparation change was the About-dialog identity
# "TinyRedactionTool v2.2.0 RC1".
#
# Final v2.2.0 promotion note:
# RC1 passed user regression testing. The only runtime-visible RC1 -> final
# change is the About-dialog identity "TinyRedactionTool v2.2.0".
#
# D1 is the first staged candidate that enables export for both additional
# UserRotation and committed Enhanced Blur/Pixelate redactions.
#
# D1 REQUIRES the matching D1 custom FFmpeg build profile. The old v2.1 media
# tool intentionally lacks transpose/avgblur/lutyuv and must not be used for D1.
#
# v2.3.0 S1c is the adversarial/regression candidate built on the user-accepted
# S1b-r2 destructive deletion checkpoint:
# - original-file deletion remains OFF by default and retains the accepted
#   overwrite / flush / verify / delete path and stream-enumeration correction;
# - S1c adds no new destructive primitive and does not alter overwrite strength;
# - Export Image / Export Video now looks neutral/disabled until at least one
#   committed redaction or standalone still-image annotation is actually exportable;
# - enabled export keeps the established blue primary-action appearance;
# - the export-success and original-deleted success dialogs now use the same
#   TinyRedactionTool-themed compact dialog family as the destructive confirmation
#   and countdown, removing the mixed stock/custom appearance;
# - the deletion-capability information popup uses that same themed information dialog;
# - the previously requested LEFT-side '?' information control is retained;
# - S1c packaging adds disposable adversarial helpers for normal, read-only,
#   hard-link, replaced-path, locked-file, network and delete-OFF regression tests;
# - FFmpeg, FFprobe, redaction/export validation, timing, masks, and the secure
#   builder remain unchanged.
#
# S1c-r2 UI correction:
# - the S1 secure-deletion checkbox, capability status, and information button
#   now receive explicit Day/Dark theme colours in Apply-Theme; this fixes the
#   black-on-dark Output text seen during S1c adversarial testing;
# - destructive deletion logic and all adversarial helper behaviour are unchanged.
#
# v2.3.0 D5a video-annotation slice:
# - user-tested S1c-r2 is the accepted baseline; secure source deletion remains unchanged;
# - Text, Line and Polyline annotations are now available on video and apply to the
#   entire logical video by default;
# - preview/export use exact logical-frame activation with no annotation safety buffer;
# - creation-order layering is preserved without weakening the security-redaction pass.
#
# v2.3.0 D5b-r2 annotation-timing replacement slice:
# - user-tested D5a remains the accepted baseline; the first D5b timing UI was rejected
#   during user testing because its separate Begin Here / End Here / Whole Video controls
#   broke the established temporal workflow and required confusing list re-selection;
# - standalone video Text/Line/Polyline annotations now reuse the existing bottom-row
#   Begin / End / Cancel controls contextually as Begin Annotation / End Annotation /
#   Cancel Annotation, matching the already-familiar redaction timing flow;
# - a video annotation remains a movable/editable draft until Begin Annotation is clicked;
#   End Annotation commits the exact inclusive StartFrame/EndFrame range with no redaction
#   safety buffer; Cancel Annotation during a pending range returns to the pre-range draft;
# - no Whole Video timing control exists: a full-video annotation is explicitly ranged from
#   the first logical frame through the final logical frame;
# - the Annotations list retains its Range column only as post-commit feedback;
# - video outline-only Rectangle/Oval/Freeform creation remains deferred;
# - FFmpeg, FFprobe, destructive deletion primitives and the secure builder are unchanged.
#
# D5b-r3 UI/timeline polish:
# - compact the Redaction Area guidance blocks and give the longer buffer note more height;
# - expand the Text status area so two-line Begin Annotation guidance is never clipped;
# - reflow the bottom transport row whenever Blur/Pixelate strength controls appear, preventing
#   the strength slider/label from overlapping Begin Redaction / Begin Annotation;
# - show standalone annotation ranges on the timeline in a separate violet lane beneath the
#   existing red security-redaction lane; annotation markers use exact logical-frame timing;
# - annotation-list refresh now invalidates the marker strip so add/remove/clear updates paint immediately;
# - no export/security/timing/deletion primitive changes.
#
# v2.3.0 G1-r2 managed-policy loader checkpoint:
# - adds an optional, generic local policy/configuration loader;
# - no policy is required and normal public behaviour is unchanged when none exists;
# - automatically checks only the machine-local ProgramData policy path;
# - an explicit -ManagedPolicyPath is supported for managed deployment/testing;
# - malformed, unsupported, network-hosted or reparse-point policy files fail closed at startup.
#
# v2.3.0 G2a managed-control slice:
# - adds the first deliberately narrow managed enforcement controls;
# - blockNetworkSource=true blocks UNC and mapped-network source media before it is opened;
# - blockNetworkDestination=true blocks UNC and mapped-network export destinations before encoding starts;
# - false/absent controls retain the accepted public warning behaviour rather than silently weakening it;
# - unknown controls and non-Boolean values fail closed at startup;
# - local cloud-sync folders are NOT claimed to be detected by these controls;
# - no authentication, encryption-at-rest check, audit logging, updater or network service is added.
#
# v2.3.0 G2b managed-control slice:
# - preserves the accepted G2a network-path controls unchanged;
# - adds disableSourceDeletion=true so a managed deployment can prohibit TinyRedactionTool
#   from deleting the original source after export;
# - the deletion checkbox remains visible but is unchecked/disabled and labelled as managed;
# - the export path independently forces source deletion OFF while the policy is active;
# - false/absent disableSourceDeletion preserves the accepted S1c-r2 deletion workflow;
# - destructive deletion primitives themselves are unchanged;
# - no authentication, encryption-at-rest check, audit logging, updater or network service is added.
#
# v2.3.0 G2c managed-control slice:
# - preserves the accepted G2a network-path and G2b source-deletion controls unchanged;
# - adds disableAudioRetention=true so a managed deployment can require video exports
#   to omit the source audio track that TinyRedactionTool does not inspect or redact;
# - the Keep original audio checkbox remains visible for video but is unchecked/disabled
#   and explicitly labelled as disabled by managed policy;
# - the export path independently forces audio retention OFF while the policy is active;
# - false/absent disableAudioRetention preserves the accepted opt-in audio workflow;
# - FFmpeg/FFprobe, export validation and audio-warning primitives themselves are unchanged;
# - no authentication, encryption-at-rest check, audit logging, updater or network service is added.
#
# v2.3.0 G2d managed-control slice:
# - preserves the accepted G2a-G2c controls unchanged;
# - adds disableVisualObscuration=true so a managed deployment can prohibit Blur and
#   Pixelate redactions while retaining opaque Coloured Box secure redaction;
# - Blur/Pixelate style buttons remain visible but are disabled while the policy is active;
# - Get-SelectedMode independently resolves to Coloured Box under the policy, and export
#   refuses any unexpected pre-existing/injected Blur or Pixelate redaction state;
# - false/absent disableVisualObscuration preserves the accepted visual-obscuration warning,
#   Standard/Aggressive behaviour and export paths unchanged;
# - annotations remain available and are not misrepresented as secure redaction;
# - no authentication, encryption-at-rest check, audit logging, updater or network service is added.
#
# v2.3.0 D5c-r2 pre-RC Text UX / startup polish slice:
# - builds directly on the verified D5c-r1 candidate; all accepted G2d managed controls remain unchanged;
# - adds an in-preview floating multiline editor for Text annotations; typing updates the existing
#   Text draft/committed annotation live while the established Appearance controls continue to own styling;
# - the floating editor opens automatically after a new Text Box is drawn and can be reopened for a
#   selected committed Text annotation by double-clicking the annotation or its Annotations-list row;
# - Ctrl+Enter closes the editor; Create Annotation retains the established commit/Begin semantics; Escape cancels a new draft or
#   restores the text that existed when committed-text editing began; clicking the preview closes the editor;
# - the floating editor is viewport-only UI state and never enters export geometry, timing or media processing;
# - the main window now starts maximized (normal Windows maximized state, not borderless/kiosk fullscreen);
# - FFmpeg, FFprobe, redaction/annotation export, CFR/VFR timing, destructive deletion and governance
#   enforcement are unchanged.

param(
    [Parameter(Mandatory = $false)]
    [string]$ManagedPolicyPath = "",
    [string]$ApprovedMediaToolDirectory = ""
)

# One instance per interactive user/session, independent of launch directory.
$script:InstanceKey='Local\TinyRedactionTool-v250-'+[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$script:InstanceMutex=New-Object Threading.Mutex($false,($script:InstanceKey+'-instance'))
$script:InstanceSignal=New-Object Threading.EventWaitHandle($false,[Threading.EventResetMode]::AutoReset,($script:InstanceKey+'-restore'))
$script:InstanceOwned=$false
try{$script:InstanceOwned=$script:InstanceMutex.WaitOne(0)}catch [Threading.AbandonedMutexException]{$script:InstanceOwned=$true}
if(-not $script:InstanceOwned){[void]$script:InstanceSignal.Set();$script:InstanceSignal.Dispose();$script:InstanceMutex.Dispose();exit 0}


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Managed-policy state. This remains $null during ordinary public use.
# The loader stores only validated policy identity/version, the canonical local
# policy source path, and the small supported Boolean control set. No media
# paths/content are placed in governance state.
$script:ManagedPolicy = $null
$script:ManagedPolicySource = $null
$script:ManagedPolicyExplicit = -not [string]::IsNullOrWhiteSpace($ManagedPolicyPath)
$script:ManagedPolicyMachinePath = if ([string]::IsNullOrWhiteSpace($env:ProgramData)) {
    $null
}
else {
    Join-Path $env:ProgramData 'TinyRedactionTool\policy.json'
}

# v2.0.0 Slice 4: WinForms has no built-in magnifying-glass cursor. Build one
# at runtime from the already-embedded Zoom glyph, using a tiny native helper
# to convert an HICON into an HCURSOR with the hotspot inside the lens.
if (-not ("ZoomCursorNativeV1" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class ZoomCursorNativeV1
{
    [StructLayout(LayoutKind.Sequential)]
    private struct ICONINFO
    {
        [MarshalAs(UnmanagedType.Bool)] public bool fIcon;
        public uint xHotspot;
        public uint yHotspot;
        public IntPtr hbmMask;
        public IntPtr hbmColor;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool GetIconInfo(IntPtr hIcon, out ICONINFO pIconInfo);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr CreateIconIndirect(ref ICONINFO icon);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyIcon(IntPtr hIcon);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool DestroyCursor(IntPtr hCursor);

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern bool DeleteObject(IntPtr hObject);

    public static IntPtr CreateCursorFromIcon(IntPtr hIcon, uint hotX, uint hotY)
    {
        ICONINFO info;
        if (!GetIconInfo(hIcon, out info)) return IntPtr.Zero;
        try
        {
            info.fIcon = false;
            info.xHotspot = hotX;
            info.yHotspot = hotY;
            return CreateIconIndirect(ref info);
        }
        finally
        {
            if (info.hbmMask != IntPtr.Zero) DeleteObject(info.hbmMask);
            if (info.hbmColor != IntPtr.Zero) DeleteObject(info.hbmColor);
        }
    }

    public static void DestroyIconHandle(IntPtr hIcon)
    {
        if (hIcon != IntPtr.Zero) DestroyIcon(hIcon);
    }

    public static void DestroyCursorHandle(IntPtr hCursor)
    {
        if (hCursor != IntPtr.Zero) DestroyCursor(hCursor);
    }
}
"@
}

# Native Open/Save dialog wrapper used so Windows does not add source
# filenames/paths to Recent Items/MRU history. Windows PowerShell 5.1's
# WinForms FileDialog does not expose AddToRecent, so use the documented
# OFN_DONTADDTORECENT flag directly instead of relying on a newer .NET API.
#
# SECURITY/COMPATIBILITY NOTE:
# OPENFILENAME contains writable native character buffers. Do not use
# StringBuilder fields inside this structure: .NET Framework cannot marshal
# StringBuilder as a structure field. Use explicitly allocated unmanaged
# UTF-16 buffers and free them immediately after the dialog closes.
if (-not ("SecureFileDialogNativeV2" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class SecureFileDialogNativeV2
{
    [StructLayout(LayoutKind.Sequential)]
    private struct OPENFILENAME
    {
        public int lStructSize;
        public IntPtr hwndOwner;
        public IntPtr hInstance;
        public IntPtr lpstrFilter;
        public IntPtr lpstrCustomFilter;
        public int nMaxCustFilter;
        public int nFilterIndex;
        public IntPtr lpstrFile;
        public int nMaxFile;
        public IntPtr lpstrFileTitle;
        public int nMaxFileTitle;
        public IntPtr lpstrInitialDir;
        public IntPtr lpstrTitle;
        public int Flags;
        public short nFileOffset;
        public short nFileExtension;
        public IntPtr lpstrDefExt;
        public IntPtr lCustData;
        public IntPtr lpfnHook;
        public IntPtr lpTemplateName;
        public IntPtr pvReserved;
        public int dwReserved;
        public int FlagsEx;
    }

    private const int OFN_OVERWRITEPROMPT = 0x00000002;
    private const int OFN_HIDEREADONLY = 0x00000004;
    private const int OFN_NOCHANGEDIR = 0x00000008;
    private const int OFN_PATHMUSTEXIST = 0x00000800;
    private const int OFN_FILEMUSTEXIST = 0x00001000;
    private const int OFN_EXPLORER = 0x00080000;
    private const int OFN_ENABLESIZING = 0x00800000;
    private const int OFN_DONTADDTORECENT = 0x02000000;
    private const int FileBufferChars = 32768;

    [DllImport("comdlg32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetOpenFileName(ref OPENFILENAME ofn);

    [DllImport("comdlg32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetSaveFileName(ref OPENFILENAME ofn);

    [DllImport("comdlg32.dll")]
    private static extern int CommDlgExtendedError();

    private static string MakeFilter(string filter)
    {
        if (String.IsNullOrEmpty(filter)) return "All files\0*.*\0\0";
        return filter.Replace("|", "\0") + "\0\0";
    }

    private static IntPtr AllocUtf16(string value)
    {
        if (value == null) return IntPtr.Zero;
        byte[] bytes = Encoding.Unicode.GetBytes(value + "\0");
        IntPtr ptr = Marshal.AllocHGlobal(bytes.Length);
        Marshal.Copy(bytes, 0, ptr, bytes.Length);
        return ptr;
    }

    private static IntPtr AllocFileBuffer(string initialFile)
    {
        int byteCount = FileBufferChars * 2;
        byte[] buffer = new byte[byteCount];

        if (!String.IsNullOrEmpty(initialFile))
        {
            byte[] initial = Encoding.Unicode.GetBytes(initialFile);
            int copyCount = Math.Min(initial.Length, byteCount - 2);
            Buffer.BlockCopy(initial, 0, buffer, 0, copyCount);
        }

        IntPtr ptr = Marshal.AllocHGlobal(byteCount);
        Marshal.Copy(buffer, 0, ptr, byteCount);
        return ptr;
    }

    private static void Free(ref IntPtr ptr)
    {
        if (ptr != IntPtr.Zero)
        {
            Marshal.FreeHGlobal(ptr);
            ptr = IntPtr.Zero;
        }
    }

    private static OPENFILENAME Create(
        IntPtr owner,
        IntPtr filter,
        IntPtr title,
        IntPtr fileBuffer,
        IntPtr defaultExt,
        int flags)
    {
        OPENFILENAME ofn = new OPENFILENAME();
        ofn.lStructSize = Marshal.SizeOf(typeof(OPENFILENAME));
        ofn.hwndOwner = owner;
        ofn.lpstrFilter = filter;
        ofn.nFilterIndex = 1;
        ofn.lpstrFile = fileBuffer;
        ofn.nMaxFile = FileBufferChars;
        ofn.lpstrFileTitle = IntPtr.Zero;
        ofn.nMaxFileTitle = 0;
        ofn.lpstrTitle = title;
        ofn.lpstrDefExt = defaultExt;
        ofn.Flags = flags | OFN_EXPLORER | OFN_ENABLESIZING | OFN_NOCHANGEDIR | OFN_DONTADDTORECENT;
        return ofn;
    }

    private static string Finish(bool ok, ref OPENFILENAME ofn)
    {
        if (ok) return Marshal.PtrToStringUni(ofn.lpstrFile);

        int error = CommDlgExtendedError();
        if (error == 0) return null; // user cancelled

        throw new Win32Exception(error, "Windows file dialog failed (CommDlgExtendedError 0x" + error.ToString("X4") + ").");
    }

    public static string ShowOpen(IntPtr owner, string filter, string title)
    {
        IntPtr filterPtr = IntPtr.Zero;
        IntPtr titlePtr = IntPtr.Zero;
        IntPtr filePtr = IntPtr.Zero;

        try
        {
            filterPtr = AllocUtf16(MakeFilter(filter));
            titlePtr = AllocUtf16(title);
            filePtr = AllocFileBuffer(null);

            OPENFILENAME ofn = Create(
                owner, filterPtr, titlePtr, filePtr, IntPtr.Zero,
                OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST | OFN_HIDEREADONLY);

            bool ok = GetOpenFileName(ref ofn);
            return Finish(ok, ref ofn);
        }
        finally
        {
            Free(ref filePtr);
            Free(ref titlePtr);
            Free(ref filterPtr);
        }
    }

    public static string ShowSave(IntPtr owner, string filter, string title, string initialFile, string defaultExt)
    {
        IntPtr filterPtr = IntPtr.Zero;
        IntPtr titlePtr = IntPtr.Zero;
        IntPtr filePtr = IntPtr.Zero;
        IntPtr defaultExtPtr = IntPtr.Zero;

        try
        {
            filterPtr = AllocUtf16(MakeFilter(filter));
            titlePtr = AllocUtf16(title);
            filePtr = AllocFileBuffer(initialFile);
            defaultExtPtr = AllocUtf16(defaultExt);

            OPENFILENAME ofn = Create(
                owner, filterPtr, titlePtr, filePtr, defaultExtPtr,
                OFN_PATHMUSTEXIST | OFN_OVERWRITEPROMPT | OFN_HIDEREADONLY);

            bool ok = GetSaveFileName(ref ofn);
            return Finish(ok, ref ofn);
        }
        finally
        {
            Free(ref defaultExtPtr);
            Free(ref filePtr);
            Free(ref titlePtr);
            Free(ref filterPtr);
        }
    }
}

"@
}

# S1a: read-only source identity and storage-capability inspection. This helper
# never writes to the source. It uses ordinary file/volume handles and refuses
# to elevate if Windows cannot provide a defensible answer in the current user
# context.
if (-not ("SourceDeletionNativeV1" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32.SafeHandles;

public sealed class SourceDeletionInspectionV1
{
    public bool Ok;
    public string Error;
    public ulong VolumeSerialNumber;
    public string FileIdHex;
    public long FileLength;
    public uint NumberOfLinks;
    public uint FileAttributes;
    public string FinalPath;
    public bool RemoteProtocolKnown;
    public bool IsRemote;
    public bool SeekPenaltyKnown;
    public bool IncursSeekPenalty;
    public bool BusTypeKnown;
    public int BusType;
    public bool CanWriteDelete;
}

public static class SourceDeletionNativeV1
{
    private const uint FILE_READ_ATTRIBUTES = 0x00000080;
    private const uint GENERIC_READ = 0x80000000;
    private const uint GENERIC_WRITE = 0x40000000;
    private const uint DELETE = 0x00010000;
    private const uint FILE_SHARE_READ = 0x00000001;
    private const uint FILE_SHARE_WRITE = 0x00000002;
    private const uint FILE_SHARE_DELETE = 0x00000004;
    private const uint OPEN_EXISTING = 3;
    private const int FileStandardInfo = 1;
    private const int FileAttributeTagInfo = 9;
    private const int FileRemoteProtocolInfo = 13;
    private const int FileIdInfo = 18;
    private const uint IOCTL_STORAGE_QUERY_PROPERTY = 0x002D1400;
    private const int StorageDeviceProperty = 0;
    private const int StorageDeviceSeekPenaltyProperty = 7;
    private const int PropertyStandardQuery = 0;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFileW(
        string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes,
        uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetFileInformationByHandleEx(
        SafeFileHandle hFile, int fileInformationClass, byte[] lpFileInformation, uint dwBufferSize);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern uint GetFinalPathNameByHandleW(
        SafeFileHandle hFile, StringBuilder lpszFilePath, uint cchFilePath, uint dwFlags);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetVolumePathNameW(
        string lpszFileName, StringBuilder lpszVolumePathName, uint cchBufferLength);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetVolumeNameForVolumeMountPointW(
        string lpszVolumeMountPoint, StringBuilder lpszVolumeName, uint cchBufferLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeviceIoControl(
        SafeFileHandle hDevice, uint dwIoControlCode,
        byte[] lpInBuffer, uint nInBufferSize,
        byte[] lpOutBuffer, uint nOutBufferSize,
        out uint lpBytesReturned, IntPtr lpOverlapped);

    private static SafeFileHandle Open(string path, uint access)
    {
        return CreateFileW(path, access,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
    }

    private static string HexId(byte[] b, int offset, int count)
    {
        StringBuilder sb = new StringBuilder(count * 2);
        for (int i = 0; i < count; i++) sb.Append(b[offset + i].ToString("X2"));
        return sb.ToString();
    }

    private static SafeFileHandle OpenSourceVolume(string sourcePath)
    {
        StringBuilder mount = new StringBuilder(1024);
        if (!GetVolumePathNameW(sourcePath, mount, (uint)mount.Capacity)) return null;
        StringBuilder volume = new StringBuilder(1024);
        if (!GetVolumeNameForVolumeMountPointW(mount.ToString(), volume, (uint)volume.Capacity)) return null;
        string volumePath = volume.ToString().TrimEnd('\\');
        if (String.IsNullOrWhiteSpace(volumePath)) return null;
        return Open(volumePath, 0);
    }

    private static bool QueryStorageProperty(SafeFileHandle hVolume, int propertyId, byte[] output, out uint returned)
    {
        returned = 0;
        byte[] query = new byte[12];
        Buffer.BlockCopy(BitConverter.GetBytes(propertyId), 0, query, 0, 4);
        Buffer.BlockCopy(BitConverter.GetBytes(PropertyStandardQuery), 0, query, 4, 4);
        return DeviceIoControl(hVolume, IOCTL_STORAGE_QUERY_PROPERTY,
            query, (uint)query.Length, output, (uint)output.Length,
            out returned, IntPtr.Zero);
    }

    private static bool TryStorageCharacteristics(string sourcePath, out bool seekPenalty, out int busType)
    {
        seekPenalty = false;
        busType = -1;
        using (SafeFileHandle hVolume = OpenSourceVolume(sourcePath))
        {
            if (hVolume == null || hVolume.IsInvalid) return false;

            byte[] seek = new byte[16];
            uint seekReturned;
            if (!QueryStorageProperty(hVolume, StorageDeviceSeekPenaltyProperty, seek, out seekReturned) || seekReturned < 9)
                return false;
            seekPenalty = seek[8] != 0;

            byte[] device = new byte[512];
            uint deviceReturned;
            if (!QueryStorageProperty(hVolume, StorageDeviceProperty, device, out deviceReturned) || deviceReturned < 32)
                return false;
            busType = BitConverter.ToInt32(device, 28);
            return true;
        }
    }

    public static SourceDeletionInspectionV1 Inspect(string path)
    {
        SourceDeletionInspectionV1 r = new SourceDeletionInspectionV1();
        r.Error = "";
        if (String.IsNullOrWhiteSpace(path)) { r.Error = "No source path."; return r; }

        try
        {
            using (SafeFileHandle h = Open(path, FILE_READ_ATTRIBUTES))
            {
                if (h == null || h.IsInvalid) { r.Error = "Windows could not open the source for identity inspection."; return r; }

                byte[] id = new byte[24];
                if (!GetFileInformationByHandleEx(h, FileIdInfo, id, (uint)id.Length))
                { r.Error = "Windows did not provide a stable file identity."; return r; }
                r.VolumeSerialNumber = BitConverter.ToUInt64(id, 0);
                r.FileIdHex = HexId(id, 8, 16);

                byte[] standard = new byte[24];
                if (!GetFileInformationByHandleEx(h, FileStandardInfo, standard, (uint)standard.Length))
                { r.Error = "Windows did not provide standard file information."; return r; }
                r.FileLength = BitConverter.ToInt64(standard, 8);
                r.NumberOfLinks = BitConverter.ToUInt32(standard, 16);
                if (standard[21] != 0) { r.Error = "The selected source is not a normal file."; return r; }

                byte[] attrs = new byte[8];
                if (!GetFileInformationByHandleEx(h, FileAttributeTagInfo, attrs, (uint)attrs.Length))
                { r.Error = "Windows did not provide source file attributes."; return r; }
                r.FileAttributes = BitConverter.ToUInt32(attrs, 0);

                byte[] remote = new byte[256];
                if (GetFileInformationByHandleEx(h, FileRemoteProtocolInfo, remote, (uint)remote.Length))
                {
                    r.RemoteProtocolKnown = true;
                    r.IsRemote = BitConverter.ToUInt32(remote, 4) != 0;
                }

                StringBuilder finalPath = new StringBuilder(32768);
                uint needed = GetFinalPathNameByHandleW(h, finalPath, (uint)finalPath.Capacity, 0);
                r.FinalPath = (needed > 0 && needed < finalPath.Capacity) ? finalPath.ToString() : Path.GetFullPath(path);
            }

            using (SafeFileHandle writable = Open(path, GENERIC_READ | GENERIC_WRITE | DELETE))
            {
                r.CanWriteDelete = writable != null && !writable.IsInvalid;
            }

            bool seekPenalty;
            int busType;
            bool storageKnown = TryStorageCharacteristics(path, out seekPenalty, out busType);
            r.SeekPenaltyKnown = storageKnown;
            r.IncursSeekPenalty = seekPenalty;
            r.BusTypeKnown = storageKnown;
            r.BusType = busType;
            r.Ok = true;
            return r;
        }
        catch (Exception ex)
        {
            r.Error = ex.Message;
            return r;
        }
    }
}

"@
}

# S1b: destructive overwrite/verify/delete helper. This code is called only
# after the existing validated export, explicit confirmation, five-second
# countdown, and a final source-identity/capability revalidation. It never
# elevates and it deletes by the exact open file handle rather than by pathname.
if (-not ("SourceDeletionDestructiveV1" -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

public sealed class SourceDeletionExecutionResultV1
{
    public bool Started;
    public bool OverwriteVerified;
    public bool DeleteAttempted;
    public bool DeleteMarked;
    public bool Deleted;
    public string Error;
    public long LogicalBytes;
    public long WorkBytes;
    public int NamedStreamsProcessed;
}

public static class SourceDeletionDestructiveV1
{
    private const uint GENERIC_READ = 0x80000000;
    private const uint GENERIC_WRITE = 0x40000000;
    private const uint DELETE = 0x00010000;
    private const uint FILE_SHARE_READ = 0x00000001;
    private const uint FILE_SHARE_WRITE = 0x00000002;
    private const uint FILE_SHARE_DELETE = 0x00000004;
    private const uint OPEN_EXISTING = 3;
    private const int FileStandardInfo = 1;
    private const int FileAttributeTagInfo = 9;
    private const int FileIdInfo = 18;
    private const int FileDispositionInfo = 4;
    private const uint FILE_BEGIN = 0;
    private const uint FILE_ATTRIBUTE_SPARSE_FILE = 0x00000200;
    private const uint FILE_ATTRIBUTE_REPARSE_POINT = 0x00000400;
    private const uint FILE_ATTRIBUTE_COMPRESSED = 0x00000800;
    private const uint FILE_ATTRIBUTE_ENCRYPTED = 0x00004000;
    private static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
    private const int ERROR_INVALID_FUNCTION = 1;
    private const int ERROR_HANDLE_EOF = 38;
    private const int ERROR_NOT_SUPPORTED = 50;
    private const int ERROR_INVALID_PARAMETER = 87;
    private const int ERROR_NO_MORE_FILES = 18;
    private const int BUFFER_SIZE = 1024 * 1024;

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct WIN32_FIND_STREAM_DATA
    {
        public long StreamSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 296)]
        public string cStreamName;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct FILE_DISPOSITION_INFO
    {
        [MarshalAs(UnmanagedType.U1)]
        public bool DeleteFile;
    }

    private sealed class StreamEntry
    {
        public string Name;
        public long Length;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern SafeFileHandle CreateFileW(
        string lpFileName, uint dwDesiredAccess, uint dwShareMode, IntPtr lpSecurityAttributes,
        uint dwCreationDisposition, uint dwFlagsAndAttributes, IntPtr hTemplateFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetFileInformationByHandleEx(
        SafeFileHandle hFile, int fileInformationClass, byte[] lpFileInformation, uint dwBufferSize);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetFilePointerEx(
        SafeFileHandle hFile, long liDistanceToMove, out long lpNewFilePointer, uint dwMoveMethod);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool WriteFile(
        SafeFileHandle hFile, byte[] lpBuffer, uint nNumberOfBytesToWrite,
        out uint lpNumberOfBytesWritten, IntPtr lpOverlapped);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool ReadFile(
        SafeFileHandle hFile, byte[] lpBuffer, uint nNumberOfBytesToRead,
        out uint lpNumberOfBytesRead, IntPtr lpOverlapped);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FlushFileBuffers(SafeFileHandle hFile);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool SetFileInformationByHandle(
        SafeFileHandle hFile, int fileInformationClass,
        ref FILE_DISPOSITION_INFO lpFileInformation, uint dwBufferSize);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr FindFirstStreamW(
        string lpFileName, int infoLevel, out WIN32_FIND_STREAM_DATA lpFindStreamData, uint dwFlags);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FindNextStreamW(
        IntPtr hFindStream, out WIN32_FIND_STREAM_DATA lpFindStreamData);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool FindClose(IntPtr hFindFile);

    private static string Win32Error(string prefix)
    {
        return prefix + " (Windows error " + Marshal.GetLastWin32Error().ToString() + ").";
    }

    private static string HexId(byte[] b, int offset, int count)
    {
        char[] chars = new char[count * 2];
        const string hex = "0123456789ABCDEF";
        for (int i = 0; i < count; i++)
        {
            byte v = b[offset + i];
            chars[i * 2] = hex[v >> 4];
            chars[i * 2 + 1] = hex[v & 0x0F];
        }
        return new string(chars);
    }

    private static bool TryReadSafetyInfo(
        SafeFileHandle h, out ulong volumeSerial, out string fileId, out long length,
        out uint links, out uint attrs, out string error)
    {
        volumeSerial = 0;
        fileId = "";
        length = 0;
        links = 0;
        attrs = 0;
        error = "";

        byte[] id = new byte[24];
        if (!GetFileInformationByHandleEx(h, FileIdInfo, id, (uint)id.Length))
        { error = Win32Error("Windows could not re-read the source identity"); return false; }
        volumeSerial = BitConverter.ToUInt64(id, 0);
        fileId = HexId(id, 8, 16);

        byte[] standard = new byte[24];
        if (!GetFileInformationByHandleEx(h, FileStandardInfo, standard, (uint)standard.Length))
        { error = Win32Error("Windows could not re-read source file information"); return false; }
        length = BitConverter.ToInt64(standard, 8);
        links = BitConverter.ToUInt32(standard, 16);
        if (standard[21] != 0)
        { error = "The selected source is no longer a normal file."; return false; }

        byte[] attrInfo = new byte[8];
        if (!GetFileInformationByHandleEx(h, FileAttributeTagInfo, attrInfo, (uint)attrInfo.Length))
        { error = Win32Error("Windows could not re-read source attributes"); return false; }
        attrs = BitConverter.ToUInt32(attrInfo, 0);
        return true;
    }

    private static bool TryEnumerateNamedStreams(string path, out List<StreamEntry> streams, out string error)
    {
        streams = new List<StreamEntry>();
        error = "";
        WIN32_FIND_STREAM_DATA data;
        IntPtr find = FindFirstStreamW(path, 0, out data, 0);
        if (find == INVALID_HANDLE_VALUE)
        {
            int code = Marshal.GetLastWin32Error();
            if (code == ERROR_INVALID_FUNCTION || code == ERROR_NOT_SUPPORTED || code == ERROR_INVALID_PARAMETER || code == ERROR_HANDLE_EOF)
                return true;
            error = "Windows could not enumerate file data streams (Windows error " + code.ToString() + ").";
            return false;
        }

        try
        {
            while (true)
            {
                string name = data.cStreamName ?? "";
                if (!String.Equals(name, "::$DATA", StringComparison.OrdinalIgnoreCase))
                {
                    if (data.StreamSize < 0)
                    { error = "Windows reported an invalid named data-stream length."; return false; }
                    StreamEntry e = new StreamEntry();
                    e.Name = name;
                    e.Length = data.StreamSize;
                    streams.Add(e);
                }

                WIN32_FIND_STREAM_DATA next;
                if (!FindNextStreamW(find, out next))
                {
                    int code = Marshal.GetLastWin32Error();
                    if (code == ERROR_HANDLE_EOF || code == ERROR_NO_MORE_FILES) break;
                    error = "Windows could not finish enumerating file data streams (Windows error " + code.ToString() + ").";
                    return false;
                }
                data = next;
            }
        }
        finally
        {
            FindClose(find);
        }
        return true;
    }

    private static SafeFileHandle OpenDataStream(string path, uint access)
    {
        return CreateFileW(path, access, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
    }

    private static bool TryGetStreamLength(SafeFileHandle h, out long length, out string error)
    {
        length = 0;
        error = "";
        byte[] standard = new byte[24];
        if (!GetFileInformationByHandleEx(h, FileStandardInfo, standard, (uint)standard.Length))
        {
            error = Win32Error("Windows could not read a data-stream length");
            return false;
        }
        length = BitConverter.ToInt64(standard, 8);
        if (length < 0)
        {
            error = "Windows reported an invalid data-stream length.";
            return false;
        }
        return true;
    }

    private static bool SeekStart(SafeFileHandle h, out string error)
    {
        error = "";
        long pos;
        if (!SetFilePointerEx(h, 0, out pos, FILE_BEGIN))
        { error = Win32Error("Windows could not seek within the source file"); return false; }
        return true;
    }

    private static void Report(Action<long,long,string> progress, long done, long total, string phase)
    {
        if (progress == null) return;
        try { progress(done, total, phase); } catch { }
    }

    private static bool OverwriteAndVerify(
        SafeFileHandle h, long length, byte[] zeroBuffer, byte[] readBuffer,
        ref long workDone, long workTotal, Action<long,long,string> progress, out string error)
    {
        error = "";
        if (!SeekStart(h, out error)) return false;

        long remaining = length;
        while (remaining > 0)
        {
            uint request = (uint)Math.Min((long)zeroBuffer.Length, remaining);
            uint written;
            if (!WriteFile(h, zeroBuffer, request, out written, IntPtr.Zero))
            {
                error = Win32Error("Windows could not complete the source overwrite");
                return false;
            }
            if (written != request)
            {
                error = "Windows completed only part of an overwrite write.";
                return false;
            }
            remaining -= written;
            workDone += written;
            Report(progress, workDone, workTotal, "Overwriting original...");
        }

        if (!FlushFileBuffers(h))
        {
            error = Win32Error("Windows could not flush the overwritten source data");
            return false;
        }

        if (!SeekStart(h, out error)) return false;
        remaining = length;
        while (remaining > 0)
        {
            uint request = (uint)Math.Min((long)readBuffer.Length, remaining);
            uint read;
            if (!ReadFile(h, readBuffer, request, out read, IntPtr.Zero))
            {
                error = Win32Error("Windows could not verify the source overwrite");
                return false;
            }
            if (read == 0)
            {
                error = "The source became shorter while the overwrite was being verified.";
                return false;
            }
            for (int i = 0; i < (int)read; i++)
            {
                if (readBuffer[i] != 0)
                {
                    error = "Overwrite verification found data that was not zero.";
                    return false;
                }
            }
            remaining -= read;
            workDone += read;
            Report(progress, workDone, workTotal, "Verifying overwrite...");
        }

        long finalLength;
        string lengthError;
        if (!TryGetStreamLength(h, out finalLength, out lengthError))
        {
            error = lengthError;
            return false;
        }
        if (finalLength != length)
        {
            error = "A source data stream changed length during overwrite verification.";
            return false;
        }
        return true;
    }

    public static SourceDeletionExecutionResultV1 Execute(
        string path, ulong expectedVolumeSerial, string expectedFileIdHex,
        long expectedLength, Action<long,long,string> progress)
    {
        SourceDeletionExecutionResultV1 r = new SourceDeletionExecutionResultV1();
        r.Error = "";
        if (String.IsNullOrWhiteSpace(path))
        { r.Error = "The source path is unavailable."; return r; }

        SafeFileHandle main = null;
        try
        {
            // Enumerate named streams before taking the destructive DELETE
            // handle. Some filesystem implementations may need to open their
            // own metadata handle during FindFirstStreamW. Identity is checked
            // again on the destructive handle before any byte is modified.
            List<StreamEntry> named;
            string streamError;
            if (!TryEnumerateNamedStreams(path, out named, out streamError))
            { r.Error = streamError; return r; }

            main = CreateFileW(path, GENERIC_READ | GENERIC_WRITE | DELETE,
                FILE_SHARE_READ | FILE_SHARE_WRITE, IntPtr.Zero, OPEN_EXISTING, 0, IntPtr.Zero);
            if (main == null || main.IsInvalid)
            { r.Error = Win32Error("Windows could not open the source for overwrite and deletion"); return r; }

            ulong volumeSerial;
            string fileId;
            long mainLength;
            uint links;
            uint attrs;
            string safetyError;
            if (!TryReadSafetyInfo(main, out volumeSerial, out fileId, out mainLength, out links, out attrs, out safetyError))
            { r.Error = safetyError; return r; }

            if (volumeSerial != expectedVolumeSerial ||
                !String.Equals(fileId, expectedFileIdHex ?? "", StringComparison.OrdinalIgnoreCase) ||
                mainLength != expectedLength)
            {
                r.Error = "The original file changed or was replaced before overwrite began.";
                return r;
            }
            if (links != 1)
            { r.Error = "The original file now has more than one filesystem name."; return r; }

            uint forbidden = FILE_ATTRIBUTE_SPARSE_FILE | FILE_ATTRIBUTE_REPARSE_POINT |
                FILE_ATTRIBUTE_COMPRESSED | FILE_ATTRIBUTE_ENCRYPTED;
            if ((attrs & forbidden) != 0)
            { r.Error = "The original file now uses storage features that prevent safe overwrite verification."; return r; }

            long logical = mainLength;
            foreach (StreamEntry e in named)
            {
                if (e.Length > Int64.MaxValue - logical)
                { r.Error = "The source data-stream sizes are too large to process safely."; return r; }
                logical += e.Length;

                using (SafeFileHandle probe = OpenDataStream(path + e.Name, GENERIC_READ | GENERIC_WRITE))
                {
                    if (probe == null || probe.IsInvalid)
                    {
                        r.Error = "Windows could not open every named data stream for overwrite.";
                        return r;
                    }
                }
            }

            if (logical > (Int64.MaxValue / 2))
            { r.Error = "The source is too large to track overwrite verification safely."; return r; }

            r.LogicalBytes = logical;
            r.WorkBytes = logical * 2;
            long workDone = 0;
            byte[] zeroBuffer = new byte[BUFFER_SIZE];
            byte[] readBuffer = new byte[BUFFER_SIZE];

            foreach (StreamEntry e in named)
            {
                using (SafeFileHandle stream = OpenDataStream(path + e.Name, GENERIC_READ | GENERIC_WRITE))
                {
                    if (stream == null || stream.IsInvalid)
                    {
                        r.Error = "A named data stream became unavailable before overwrite.";
                        return r;
                    }
                    long currentStreamLength;
                    string currentStreamError;
                    if (!TryGetStreamLength(stream, out currentStreamLength, out currentStreamError))
                    {
                        r.Error = currentStreamError;
                        return r;
                    }
                    if (currentStreamLength != e.Length)
                    {
                        r.Error = "A named data stream changed before overwrite began.";
                        return r;
                    }
                    if (e.Length > 0) r.Started = true;
                    string opError;
                    if (!OverwriteAndVerify(stream, e.Length, zeroBuffer, readBuffer,
                        ref workDone, r.WorkBytes, progress, out opError))
                    {
                        r.Error = opError;
                        return r;
                    }
                    r.NamedStreamsProcessed++;
                }
            }

            if (mainLength > 0) r.Started = true;
            string mainError;
            if (!OverwriteAndVerify(main, mainLength, zeroBuffer, readBuffer,
                ref workDone, r.WorkBytes, progress, out mainError))
            {
                r.Error = mainError;
                return r;
            }

            ulong finalVolumeSerial;
            string finalFileId;
            long finalMainLength;
            uint finalLinks;
            uint finalAttrs;
            string finalSafetyError;
            if (!TryReadSafetyInfo(main, out finalVolumeSerial, out finalFileId, out finalMainLength,
                out finalLinks, out finalAttrs, out finalSafetyError))
            {
                r.Error = finalSafetyError;
                return r;
            }
            if (finalVolumeSerial != expectedVolumeSerial ||
                !String.Equals(finalFileId, expectedFileIdHex ?? "", StringComparison.OrdinalIgnoreCase) ||
                finalMainLength != mainLength || finalLinks != 1)
            {
                r.Error = "The source changed while overwrite verification was in progress.";
                return r;
            }

            r.OverwriteVerified = true;

            // Even an empty file is destructively changed once deletion is attempted.
            r.Started = true;
            r.DeleteAttempted = true;
            Report(progress, r.WorkBytes, r.WorkBytes, "Removing original file...");

            FILE_DISPOSITION_INFO disposition = new FILE_DISPOSITION_INFO();
            disposition.DeleteFile = true;
            if (!SetFileInformationByHandle(main, FileDispositionInfo, ref disposition,
                (uint)Marshal.SizeOf(typeof(FILE_DISPOSITION_INFO))))
            {
                r.Error = Win32Error("The source contents were verified, but Windows could not mark the file for deletion");
                return r;
            }
            r.DeleteMarked = true;
        }
        catch (Exception ex)
        {
            r.Error = ex.Message;
            return r;
        }
        finally
        {
            if (main != null) main.Dispose();
        }

        for (int i = 0; i < 20 && File.Exists(path); i++)
            System.Threading.Thread.Sleep(50);

        r.Deleted = !File.Exists(path);
        if (!r.Deleted && String.IsNullOrWhiteSpace(r.Error))
            r.Error = "The source contents were overwritten and verified, but Windows still reports the file as present.";
        return r;
    }
}
"@
}

[System.Windows.Forms.Application]::EnableVisualStyles()

# ----------------------------
# Packaged media-tool bootstrap
# ----------------------------
# GZip tools remain assembly resources until the owning instance expands them. For the
# packaged EXE only, expand them into a unique per-run directory under TEMP,
# verify their SHA-256 pins before execution, and remove the runtime directory
# when the GUI closes. The distributed application remains one EXE.
$script:EmbeddedMediaRuntimeDir = $null
$script:EmbeddedFFmpegRuntimePath = $null
$script:EmbeddedFFprobeRuntimePath = $null
# SECURITY: once an approved runtime tool has been hash-verified, keep a read
# handle open without write/delete sharing for the entire application session.
# This closes the post-verification tamper window without re-hashing a ~27 MB
# executable before every frame-preview invocation.
$script:ApprovedFFmpegLock = $null
$script:ApprovedFFprobeLock = $null
$script:EmbeddedFFmpegPayloadGzip = "ffmpeg.exe.gz"
$script:EmbeddedFFprobePayloadGzip = "ffprobe.exe.gz"

function Get-TRTRuntimeRoot {
    $temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if(Get-NetworkPathReason $temp){throw 'Packaged media tools require local temporary storage.'}
    $parent=Join-Path $temp 'TinyRedactionTool'
    if(Test-Path -LiteralPath $parent){if((Get-Item -LiteralPath $parent).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected runtime folder rejected.'}}
    else{[void][IO.Directory]::CreateDirectory($parent)}
    return $parent
}
function Remove-TRTRuntimeFolder([string]$target) {
    $parent=Get-TRTRuntimeRoot;$target=[IO.Path]::GetFullPath($target)
    if([IO.Path]::GetDirectoryName($target) -ne $parent -or [IO.Path]::GetFileName($target) -notmatch '^run-[a-f0-9]{32}$'){throw 'Runtime cleanup path rejected.'}
    if(-not (Test-Path -LiteralPath $target)){return}
    if((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Redirected runtime folder rejected.'}
    $items=@(Get-ChildItem -LiteralPath $target -Force)
    if(@($items|Where-Object{$_.PSIsContainer -or $_.Name -notin @('ffmpeg.exe','ffprobe.exe','.runtime.lock') -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)}).Count){throw 'Unexpected runtime folder entry; cleanup stopped.'}
    foreach($item in $items){Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop}
    [IO.Directory]::Delete($target,$false)
}
function Recover-OwnedRuntimeFolders {
    $parent=Get-TRTRuntimeRoot
    foreach($folder in @(Get-ChildItem -LiteralPath $parent -Directory -Filter 'run-*')){
        if($folder.Name -notmatch '^run-[a-f0-9]{32}$' -or ($folder.Attributes -band [IO.FileAttributes]::ReparsePoint)){continue}
        $marker=Join-Path $folder.FullName '.runtime.lock';$lease=$null
        if(-not (Test-Path -LiteralPath $marker)){
            # Only empty interrupted pre-lease folders qualify without a marker.
            if(@(Get-ChildItem -LiteralPath $folder.FullName -Force).Count -eq 0){[IO.Directory]::Delete($folder.FullName,$false)}
            continue
        }
        if((Get-Item -LiteralPath $marker).Attributes -band [IO.FileAttributes]::ReparsePoint){continue}
        try{$lease=[IO.File]::Open($marker,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}catch{continue}
        try{
            $reader=[IO.StreamReader]::new($lease,[Text.Encoding]::ASCII,$false,1024,$true)
            try{$tag=$reader.ReadToEnd()}finally{$reader.Dispose()}
            # A crash can interrupt the initial marker write. Only a prefix of
            # this version's marker qualifies; folder contents remain checked.
            if(-not 'TRT-RUNTIME-v250-1'.StartsWith($tag,[StringComparison]::Ordinal)){continue}
            $lease.Dispose();$lease=$null
            Remove-TRTRuntimeFolder $folder.FullName
        }finally{if($lease){$lease.Dispose()}}
    }
}




function Expand-EmbeddedGzipTool([string]$gzipPath,[string]$destinationPath) {
    $payload=[Reflection.Assembly]::GetEntryAssembly().GetManifestResourceStream($gzipPath)
    if(-not $payload){throw 'The packaged media resource is missing.'}
    $gzip=$null;$output=$null
    try{
        $gzip=[IO.Compression.GZipStream]::new($payload,[IO.Compression.CompressionMode]::Decompress)
        $output=[IO.File]::Open($destinationPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        $gzip.CopyTo($output);$output.Flush($true)
    }finally{if($output){$output.Dispose()};if($gzip){$gzip.Dispose()};$payload.Dispose()}
    if((Get-Item -LiteralPath $destinationPath).Length -lt 256KB){throw 'Embedded media resource did not expand safely.'}
}

function Initialize-EmbeddedMediaTools {
    if(-not (Test-IsPackagedHost)){return}
    Recover-OwnedRuntimeFolders
    $parent=Get-TRTRuntimeRoot
    $runDir=Join-Path $parent ('run-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($runDir)
    $script:EmbeddedMediaRuntimeDir=$runDir
    try{
        $script:RuntimeToolLease=[IO.File]::Open((Join-Path $runDir '.runtime.lock'),[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $tag=[Text.Encoding]::ASCII.GetBytes('TRT-RUNTIME-v250-1')
        $script:RuntimeToolLease.Write($tag,0,$tag.Length);$script:RuntimeToolLease.Flush($true)
        $runtimeFFmpeg=Join-Path $runDir 'ffmpeg.exe';$runtimeFFprobe=Join-Path $runDir 'ffprobe.exe'
        Expand-EmbeddedGzipTool 'ffmpeg.exe.gz' $runtimeFFmpeg
        Expand-EmbeddedGzipTool 'ffprobe.exe.gz' $runtimeFFprobe
        $script:EmbeddedFFmpegRuntimePath=$runtimeFFmpeg;$script:EmbeddedFFprobeRuntimePath=$runtimeFFprobe
    }catch{Remove-EmbeddedMediaTools;throw}
}

function Close-ApprovedMediaToolLocks {
    foreach ($name in @('ApprovedFFmpegLock','ApprovedFFprobeLock')) {
        $handle = Get-Variable -Name $name -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($handle) {
            try { $handle.Dispose() } catch {}
            Set-Variable -Name $name -Scope Script -Value $null
        }
    }
}

function Remove-EmbeddedMediaTools {
    Close-ApprovedMediaToolLocks
    if($script:RuntimeToolLease){$script:RuntimeToolLease.Dispose();$script:RuntimeToolLease=$null}
    if(-not $script:EmbeddedMediaRuntimeDir){return}
    try{
        Remove-TRTRuntimeFolder $script:EmbeddedMediaRuntimeDir
        $script:EmbeddedMediaRuntimeDir=$null;$script:EmbeddedFFmpegRuntimePath=$null;$script:EmbeddedFFprobeRuntimePath=$null
    }catch{
        [Windows.Forms.MessageBox]::Show(('TRT runtime-tool cleanup failed; recovery will be retried on the next launch. '+$_.Exception.GetBaseException().Message),'Temporary cleanup','OK','Warning')|Out-Null
    }
}
 
# ----------------------------
# Helpers
# ----------------------------
# Standalone builder/bootstrap integration points.
#
# DEVELOPMENT / PLAIN-PS1 USE:
#   These may remain blank while testing the script. In that mode TinyRedactionTool
#   still location-pins both binaries beside this PS1 and NEVER searches PATH.
#
# PACKAGED RELEASES:
#   The standalone builder MUST inject the SHA-256 of the exact ffmpeg.exe and
#   ffprobe.exe it ships. A packaged EXE fails closed if either value is blank.
#
# Compute the approved hashes from the exact release binaries with:
#   (Get-FileHash -LiteralPath .\ffmpeg.exe  -Algorithm SHA256).Hash
#   (Get-FileHash -LiteralPath .\ffprobe.exe -Algorithm SHA256).Hash
#
# Then replace the two empty strings below with the resulting 64-character hashes
# before packaging. Do not hash a different build and do not use placeholder values.
$script:ExpectedFFmpegSha256 = "643D9CFE006D0F72763B7A46B66AC23067B6A8BF4C113044781C11E862C34AFC"
$script:ExpectedFFprobeSha256 = "84F5DEDA1C8D648A588AEE7BAD7148EE0DA02569C39A7C1B41048729BE9763F2"

function Test-IsPackagedHost {
    try {
        $hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $hostName = [System.IO.Path]::GetFileNameWithoutExtension($hostExe)
        return ($hostName -notin @("powershell", "powershell_ise", "pwsh"))
    }
    catch {
        # If host identity cannot be established, err on the secure side.
        return $true
    }
}

function Test-ApprovedTool([string]$path, [string]$expectedHash, [string]$displayName) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }

    if ([string]::IsNullOrWhiteSpace($expectedHash)) {
        if (Test-IsPackagedHost) {
            [System.Windows.Forms.MessageBox]::Show(
                "$displayName SHA-256 pinning was not populated by the standalone builder. This packaged release will not execute an unpinned media tool.",
                "$displayName trust check failed",
                "OK",
                "Error"
            ) | Out-Null
            return $false
        }

        # Plain-PS1 development mode: location pinning still prevents an
        # arbitrary PATH binary from being selected. Release packaging is not
        # allowed to rely on this weaker development-only state.
        return $true
    }

    if ($expectedHash -notmatch '^[0-9A-Fa-f]{64}$') {
        [System.Windows.Forms.MessageBox]::Show(
            "$displayName hash verification is configured incorrectly. The expected SHA-256 must contain exactly 64 hexadecimal characters.",
            "$displayName trust check failed",
            "OK",
            "Error"
        ) | Out-Null
        return $false
    }

    # SECURITY: open the exact executable with FileShare.Read only, hash the
    # bytes through that already-open handle, and retain the handle for the
    # lifetime of the GUI. Other readers (including CreateProcess) are allowed,
    # but later write/delete opens are denied by Windows. This prevents a tool
    # from being modified after startup verification and then executed via the
    # already-resolved path.
    $lock = $null
    $sha = $null
    try {
        $lock = [System.IO.File]::Open(
            $path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read
        )
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha.ComputeHash($lock)
        $actual = ([System.BitConverter]::ToString($hashBytes)).Replace('-', '')

        if (-not $actual.Equals($expectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
            $lock.Dispose()
            $lock = $null
            [System.Windows.Forms.MessageBox]::Show(
                "The bundled $displayName does not match the approved SHA-256 hash and will not be executed.",
                "$displayName trust check failed",
                "OK",
                "Error"
            ) | Out-Null
            return $false
        }

        # Retain the verified handle so the approved bytes cannot be replaced or
        # appended to while TinyRedactionTool is running.
        if ($displayName -eq 'FFmpeg') {
            if ($script:ApprovedFFmpegLock) { try { $script:ApprovedFFmpegLock.Dispose() } catch {} }
            $script:ApprovedFFmpegLock = $lock
        }
        elseif ($displayName -eq 'FFprobe') {
            if ($script:ApprovedFFprobeLock) { try { $script:ApprovedFFprobeLock.Dispose() } catch {} }
            $script:ApprovedFFprobeLock = $lock
        }
        else {
            $lock.Dispose()
            $lock = $null
            throw "Unknown approved media tool."
        }
        $lock = $null # ownership transferred to the script-scoped trust lock
    }
    catch {
        if ($lock) { try { $lock.Dispose() } catch {} }
        [System.Windows.Forms.MessageBox]::Show(
            "The bundled $displayName could not be verified and locked against modification and will not be executed.",
            "$displayName trust check failed",
            "OK",
            "Error"
        ) | Out-Null
        return $false
    }
    finally {
        if ($sha) { $sha.Dispose() }
    }
    return $true
}

function Find-ApprovedMediaTool([string]$fileName, [string]$expectedHash, [string]$displayName) {
    # SECURITY: Never search PATH. FFmpeg receives the complete unredacted
    # source media; FFprobe is a post-export security gate. Both are therefore
    # restricted to the application/script directory and, in packaged builds,
    # must be cryptographically pinned by the standalone builder.
    $candidates = New-Object System.Collections.Generic.List[string]

    # In the single-EXE build, PS2EXE payloads are expanded into a unique
    # per-run directory before tool resolution. Hash verification below still
    # occurs before either executable is used.
    if ($fileName -eq "ffmpeg.exe" -and $script:EmbeddedFFmpegRuntimePath) {
        [void]$candidates.Add($script:EmbeddedFFmpegRuntimePath)
    }
    elseif ($fileName -eq "ffprobe.exe" -and $script:EmbeddedFFprobeRuntimePath) {
        [void]$candidates.Add($script:EmbeddedFFprobeRuntimePath)
    }

    if(-not (Test-IsPackagedHost) -and $ApprovedMediaToolDirectory){
        $toolRoot=[IO.Path]::GetFullPath($ApprovedMediaToolDirectory)
        if(Get-NetworkPathReason $toolRoot){throw 'Approved media tools must be local.'}
        foreach($name in @($fileName.Replace('.exe','-custom.exe'),$fileName)){
            $toolPath=Join-Path $toolRoot $name
            if((Test-Path -LiteralPath $toolPath -PathType Leaf) -and (Get-FileHash -LiteralPath $toolPath).Hash -eq $expectedHash){[void]$candidates.Add($toolPath)}
        }
        if(-not $candidates.Count){throw 'The explicit media-tool directory has no approved matching tool.'}
    }
    try {
        $hostExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $hostName = [System.IO.Path]::GetFileNameWithoutExtension($hostExe)
        $exeDir = Split-Path -Parent $hostExe

        if ($hostName -in @("powershell", "powershell_ise", "pwsh")) {
            if ($PSScriptRoot) { [void]$candidates.Add((Join-Path $PSScriptRoot $fileName)) }
        }
        elseif ($exeDir) {
            [void]$candidates.Add((Join-Path $exeDir $fileName))
        }
    } catch {}

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            if (Test-ApprovedTool $candidate $expectedHash $displayName) {
                return [System.IO.Path]::GetFullPath($candidate)
            }
            return $null
        }
    }

    [System.Windows.Forms.MessageBox]::Show(
        "The approved application-local $fileName was not found.`r`n`r`nPut the intended $fileName beside this script (or beside the packaged .exe). TinyRedactionTool will not fall back to a copy found on PATH.",
        "$displayName not found",
        "OK",
        "Error"
    ) | Out-Null
    return $null
}

function Find-FFmpeg {
    return Find-ApprovedMediaTool "ffmpeg.exe" $script:ExpectedFFmpegSha256 "FFmpeg"
}

function Find-FFprobe {
    return Find-ApprovedMediaTool "ffprobe.exe" $script:ExpectedFFprobeSha256 "FFprobe"
}

function Test-D1MediaToolCapabilities([string]$ffmpegPath) {
    $filters = & $ffmpegPath -hide_banner -filters 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { return $false }

    foreach ($name in @("transpose","avgblur","lutyuv")) {
        if ($filters -notmatch ("(?m)^ .{2,4}\s+" + [regex]::Escape($name) + "\s")) {
            return $false
        }
    }
    return $true
}

function SecToText([double]$seconds) {
    $ts = [TimeSpan]::FromSeconds($seconds)
    return "{0:00}:{1:00}:{2:00.000}" -f [math]::Floor($ts.TotalHours), $ts.Minutes, ($ts.Seconds + ($ts.Milliseconds/1000.0))
}

# Implements the Windows/MSVCRT command-line quoting rules, including embedded
# quotes and trailing backslashes. Media processes still use UseShellExecute
# = $false; this only makes .Arguments unambiguous for unusual legal paths.
function Quote-Arg([string]$s) {
    if ($null -eq $s) { return '""' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0
    foreach ($ch in $s.ToCharArray()) {
        if ($ch -eq '\') {
            $slashes++
            continue
        }
        if ($ch -eq '"') {
            if ($slashes -gt 0) { [void]$sb.Append((('\' * ($slashes * 2)) -join '')) }
            [void]$sb.Append('\"')
            $slashes = 0
            continue
        }
        if ($slashes -gt 0) {
            [void]$sb.Append((('\' * $slashes) -join ''))
            $slashes = 0
        }
        [void]$sb.Append($ch)
    }
    if ($slashes -gt 0) { [void]$sb.Append((('\' * ($slashes * 2)) -join '')) }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Get-NetworkPathReason([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    try {
        $full = [System.IO.Path]::GetFullPath($path)
    }
    catch {
        $full = $path
    }

    if ($full.StartsWith('\\') -or $full.StartsWith('\\?\UNC\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return "UNC/network path"
    }

    try {
        $root = [System.IO.Path]::GetPathRoot($full)
        if ($root -and $root -match '^[A-Za-z]:\\$') {
            $drive = New-Object System.IO.DriveInfo($root)
            if ($drive.DriveType -eq [System.IO.DriveType]::Network) {
                return "mapped network drive"
            }
        }
    } catch {}
    return $null
}

# G2d: validate the deliberately small v1 managed-policy envelope and the supported
# strengthening controls. Unknown controls still fail closed so a deployment
# cannot silently believe an unsupported requirement is being enforced.
function ConvertTo-ManagedPolicyV1([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) {
        throw "No managed policy path was supplied."
    }

    try { $full = [System.IO.Path]::GetFullPath($path) }
    catch { throw "The managed policy path is invalid." }

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "The managed policy file does not exist."
    }

    $networkReason = Get-NetworkPathReason $full
    if ($networkReason) {
        throw "Managed policy files must be stored on local storage."
    }

    try { $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop }
    catch { throw "Windows could not inspect the managed policy file." }

    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Managed policy files cannot be reparse points."
    }
    if ($item.Length -le 0 -or $item.Length -gt 65536) {
        throw "The managed policy file must be between 1 byte and 64 KiB."
    }

    try {
        $utf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $json = [System.IO.File]::ReadAllText($full, $utf8)
    }
    catch {
        throw "The managed policy file must be valid UTF-8 text."
    }

    try { $obj = $json | ConvertFrom-Json -ErrorAction Stop }
    catch { throw "The managed policy file is not valid JSON." }

    if (-not ($obj -is [System.Management.Automation.PSCustomObject])) {
        throw "The managed policy root must be a JSON object."
    }

    $allowed = @('schemaVersion','policyId','policyVersion','controls')
    $names = @($obj.PSObject.Properties.Name)
    foreach ($required in $allowed) {
        if ($names -notcontains $required) {
            throw "The managed policy is missing required property '$required'."
        }
    }
    foreach ($name in $names) {
        if ($allowed -notcontains $name) {
            throw "The managed policy contains unsupported property '$name'."
        }
    }

    if (-not (($obj.schemaVersion -is [int]) -or ($obj.schemaVersion -is [long])) -or [int64]$obj.schemaVersion -ne 1) {
        throw "The managed policy schemaVersion is unsupported."
    }

    $policyId = [string]$obj.policyId
    $policyVersion = [string]$obj.policyVersion
    if ($policyId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') {
        throw "policyId must be 1-64 characters using letters, numbers, dot, underscore or hyphen."
    }
    if ($policyVersion -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$') {
        throw "policyVersion must be 1-32 characters using letters, numbers, dot, underscore or hyphen."
    }

    if (-not ($obj.controls -is [System.Management.Automation.PSCustomObject])) {
        throw "controls must be a JSON object."
    }

    # G2d supports the accepted G2a network controls, G2b source-deletion disablement,
    # G2c audio-retention disablement, and a managed switch that can prohibit Blur/Pixelate
    # visual-obscuration redactions while retaining opaque Coloured Box redaction.
    # Enumerate the property collection directly for Windows PowerShell 5.1 compatibility
    # (the G1-r2 empty-object correction). False/absent controls preserve the accepted
    # public/application behaviour rather than silently weakening it.
    $allowedControls = @('blockNetworkSource','blockNetworkDestination','disableSourceDeletion','disableAudioRetention','disableVisualObscuration')
    $blockNetworkSource = $false
    $blockNetworkDestination = $false
    $disableSourceDeletion = $false
    $disableAudioRetention = $false
    $disableVisualObscuration = $false
    foreach ($controlProperty in $obj.controls.PSObject.Properties) {
        $controlName = [string]$controlProperty.Name
        if ($allowedControls -notcontains $controlName) {
            throw "The managed policy contains unsupported control '$controlName'."
        }
        if (-not ($controlProperty.Value -is [bool])) {
            throw "Managed control '$controlName' must be true or false."
        }
        if ($controlName -eq 'blockNetworkSource') {
            $blockNetworkSource = [bool]$controlProperty.Value
        }
        elseif ($controlName -eq 'blockNetworkDestination') {
            $blockNetworkDestination = [bool]$controlProperty.Value
        }
        elseif ($controlName -eq 'disableSourceDeletion') {
            $disableSourceDeletion = [bool]$controlProperty.Value
        }
        elseif ($controlName -eq 'disableAudioRetention') {
            $disableAudioRetention = [bool]$controlProperty.Value
        }
        elseif ($controlName -eq 'disableVisualObscuration') {
            $disableVisualObscuration = [bool]$controlProperty.Value
        }
    }

    return [pscustomobject]@{
        SchemaVersion = 1
        PolicyId = $policyId
        PolicyVersion = $policyVersion
        Path = $full
        BlockNetworkSource = [bool]$blockNetworkSource
        BlockNetworkDestination = [bool]$blockNetworkDestination
        DisableSourceDeletion = [bool]$disableSourceDeletion
        DisableAudioRetention = [bool]$disableAudioRetention
        DisableVisualObscuration = [bool]$disableVisualObscuration
    }
}

function Initialize-ManagedPolicy {
    $candidate = $null
    if ($script:ManagedPolicyExplicit) {
        $candidate = $ManagedPolicyPath
    }
    elseif ($script:ManagedPolicyMachinePath -and (Test-Path -LiteralPath $script:ManagedPolicyMachinePath -PathType Leaf)) {
        $candidate = $script:ManagedPolicyMachinePath
    }

    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $script:ManagedPolicy = $null
        $script:ManagedPolicySource = $null
        return
    }

    $policy = ConvertTo-ManagedPolicyV1 $candidate
    $script:ManagedPolicy = $policy
    $script:ManagedPolicySource = $policy.Path
}

try {
    Initialize-ManagedPolicy
}
catch {
    [System.Windows.Forms.MessageBox]::Show(
        ("TinyRedactionTool could not load the configured managed policy.`r`n`r`n" + $_.Exception.Message + "`r`n`r`nThe application has not started."),
        "Managed policy error",
        "OK",
        "Error"
    ) | Out-Null
    exit 2
}

function Normalize-DeletionPath([string]$path) {
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    try { $full = [System.IO.Path]::GetFullPath($path) } catch { $full = $path }
    if ($full.StartsWith('\\?\UNC\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return ('\\' + $full.Substring(8)).TrimEnd('\')
    }
    if ($full.StartsWith('\\?\', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $full.Substring(4).TrimEnd('\')
    }
    return $full.TrimEnd('\')
}

function Get-SourceDeletionCapability([string]$path) {
    $result = [pscustomobject]@{
        Class = 'Unavailable'
        StatusText = 'Automatic deletion unavailable for this source.'
        Reason = 'TinyRedactionTool could not reliably inspect this source.'
        Inspection = $null
        LastWriteTicks = 0L
    }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $result.Reason = 'The original file is no longer available at the path that was opened.'
        return $result
    }

    try { $inspection = [SourceDeletionNativeV1]::Inspect($path) } catch {
        $result.Reason = 'Windows could not provide the file information needed for automatic deletion.'
        return $result
    }
    $result.Inspection = $inspection
    try { $result.LastWriteTicks = [System.IO.File]::GetLastWriteTimeUtc($path).Ticks } catch {}

    if (-not $inspection -or -not $inspection.Ok) {
        $result.Reason = 'Windows could not provide a stable identity for this file.'
        return $result
    }
    if ((Get-NetworkPathReason $path) -or ($inspection.RemoteProtocolKnown -and $inspection.IsRemote)) {
        $result.Reason = 'This file is stored on a shared or remote location.'
        return $result
    }
    if ($inspection.NumberOfLinks -ne 1) {
        $result.Reason = 'This file has more than one filesystem name, so TinyRedactionTool will not overwrite it automatically.'
        return $result
    }

    $attrs = [uint32]$inspection.FileAttributes
    $FILE_ATTRIBUTE_SPARSE_FILE = [uint32]0x00000200
    $FILE_ATTRIBUTE_REPARSE_POINT = [uint32]0x00000400
    $FILE_ATTRIBUTE_COMPRESSED = [uint32]0x00000800
    $FILE_ATTRIBUTE_ENCRYPTED = [uint32]0x00004000
    if (($attrs -band $FILE_ATTRIBUTE_REPARSE_POINT) -ne 0) {
        $result.Reason = 'This file is provided through a redirected or synchronized location that cannot be safely verified.'
        return $result
    }
    if (($attrs -band ($FILE_ATTRIBUTE_SPARSE_FILE -bor $FILE_ATTRIBUTE_COMPRESSED -bor $FILE_ATTRIBUTE_ENCRYPTED)) -ne 0) {
        $result.Reason = 'This file uses storage features that prevent reliable overwrite verification.'
        return $result
    }
    if (-not $inspection.CanWriteDelete) {
        $result.Reason = 'Windows does not currently allow TinyRedactionTool to overwrite and delete this file.'
        return $result
    }
    if (-not $inspection.SeekPenaltyKnown -or -not $inspection.BusTypeKnown) {
        $result.Reason = 'TinyRedactionTool could not reliably determine how this file is stored.'
        return $result
    }
    # Reject storage stacks whose physical backing is remote, virtual, pooled,
    # or otherwise too indirect for a file-overwrite assurance claim.
    if ([int]$inspection.BusType -in @(0,6,9,14,15,16)) {
        $result.Reason = 'This file is stored through a device or storage layer that TinyRedactionTool cannot safely verify.'
        return $result
    }

    if ($inspection.IncursSeekPenalty) {
        $result.Class = 'VerifiedOverwrite'
        $result.StatusText = 'Secure overwrite available.'
        $result.Reason = 'TinyRedactionTool identified this as supported local storage where a complete overwrite can be verified.'
    }
    else {
        $result.Class = 'BestEffortOverwrite'
        $result.StatusText = 'Enhanced deletion available.'
        $result.Reason = 'TinyRedactionTool can overwrite and verify the logical file, but this storage may retain inaccessible internal copies.'
    }
    return $result
}

function Test-SameSourceDeletionIdentity($baseline, $current) {
    if (-not $baseline -or -not $current -or -not $baseline.Inspection -or -not $current.Inspection) { return $false }
    $a = $baseline.Inspection
    $b = $current.Inspection
    if (-not $a.Ok -or -not $b.Ok) { return $false }
    if ([uint64]$a.VolumeSerialNumber -ne [uint64]$b.VolumeSerialNumber) { return $false }
    if (-not [string]::Equals([string]$a.FileIdHex, [string]$b.FileIdHex, [System.StringComparison]::OrdinalIgnoreCase)) { return $false }
    if ([int64]$a.FileLength -ne [int64]$b.FileLength) { return $false }
    if ([int64]$baseline.LastWriteTicks -ne [int64]$current.LastWriteTicks) { return $false }
    return $true
}

function Test-DeletionOutputCollision([string]$sourcePath, [string]$destinationPath, $baselineIdentity) {
    $srcNorm = Normalize-DeletionPath $sourcePath
    $dstNorm = Normalize-DeletionPath $destinationPath
    if ($srcNorm -and $dstNorm -and [string]::Equals($srcNorm, $dstNorm, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    if ($baselineIdentity -and (Test-Path -LiteralPath $destinationPath -PathType Leaf)) {
        $destCap = Get-SourceDeletionCapability $destinationPath
        if ($destCap.Inspection -and $destCap.Inspection.Ok -and $baselineIdentity.Inspection) {
            if ([uint64]$destCap.Inspection.VolumeSerialNumber -eq [uint64]$baselineIdentity.Inspection.VolumeSerialNumber -and
                [string]::Equals([string]$destCap.Inspection.FileIdHex, [string]$baselineIdentity.Inspection.FileIdHex, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    }
    return $false
}

function Update-SourceDeletionUi {
    if (-not $chkDeleteOriginal -or -not $lblDeleteCapability) { return }

    # G2b managed control: an organisation may prohibit TinyRedactionTool's
    # optional destructive source-deletion workflow. Keep the existing control
    # visible so the restriction is explicit, but make it impossible to select.
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableSourceDeletion) {
        $chkDeleteOriginal.Checked = $false
        $chkDeleteOriginal.Enabled = $false
        $script:deleteOriginalRequested = $false
        $lblDeleteCapability.Text = 'Disabled by managed policy.'
        if ($btnDeleteInfo) { $btnDeleteInfo.Enabled = $true }
        $policyDeletionReason = 'The configured managed policy does not allow TinyRedactionTool to delete the original source file.'
        $script:appToolTip.SetToolTip($lblDeleteCapability, $policyDeletionReason)
        $script:appToolTip.SetToolTip($chkDeleteOriginal, $policyDeletionReason)
        return
    }

    if (-not $videoPath) {
        $chkDeleteOriginal.Checked = $false
        $chkDeleteOriginal.Enabled = $false
        $lblDeleteCapability.Text = 'Open a source to check deletion availability.'
        if ($btnDeleteInfo) { $btnDeleteInfo.Enabled = $false }
        $script:appToolTip.SetToolTip($lblDeleteCapability, '')
        return
    }
    if ($btnDeleteInfo) { $btnDeleteInfo.Enabled = $true }
    if (-not $sourceDeletionCapability) {
        $chkDeleteOriginal.Checked = $false
        $chkDeleteOriginal.Enabled = $false
        $lblDeleteCapability.Text = 'Automatic deletion unavailable for this source.'
        $script:appToolTip.SetToolTip($lblDeleteCapability, 'TinyRedactionTool could not reliably inspect this source.')
        return
    }
    $available = ($sourceDeletionCapability.Class -in @('VerifiedOverwrite','BestEffortOverwrite'))
    if (-not $available) { $chkDeleteOriginal.Checked = $false }
    $chkDeleteOriginal.Enabled = $available
    $lblDeleteCapability.Text = [string]$sourceDeletionCapability.StatusText
    $script:appToolTip.SetToolTip($lblDeleteCapability, [string]$sourceDeletionCapability.Reason)
    $script:appToolTip.SetToolTip($chkDeleteOriginal, [string]$sourceDeletionCapability.Reason)
}

function Reset-SourceDeletionState {
    $script:sourceDeletionIdentity = $null
    $script:sourceDeletionCapability = $null
    $script:deleteOriginalRequested = $false
    if ($chkDeleteOriginal) { $chkDeleteOriginal.Checked = $false }
    Update-SourceDeletionUi
}

function Initialize-SourceDeletionStateForSource {
    $script:deleteOriginalRequested = $false
    if ($chkDeleteOriginal) { $chkDeleteOriginal.Checked = $false }
    if (-not $videoPath) {
        $script:sourceDeletionIdentity = $null
        $script:sourceDeletionCapability = $null
        Update-SourceDeletionUi
        return
    }
    $cap = Get-SourceDeletionCapability $videoPath
    $script:sourceDeletionIdentity = $cap
    $script:sourceDeletionCapability = $cap
    Update-SourceDeletionUi
}

function Revalidate-SourceDeletionRequest {
    $result = [pscustomobject]@{ Ok = $false; Capability = $null; Error = '' }
    if (-not $videoPath -or -not $sourceDeletionIdentity) {
        $result.Error = 'The original file can no longer be identified safely.'
        return $result
    }
    $current = Get-SourceDeletionCapability $videoPath
    $result.Capability = $current
    if (-not (Test-SameSourceDeletionIdentity $sourceDeletionIdentity $current)) {
        $result.Error = 'The original file has changed or been replaced since it was opened.'
        return $result
    }
    if ($current.Class -notin @('VerifiedOverwrite','BestEffortOverwrite')) {
        $result.Error = [string]$current.Reason
        return $result
    }
    $result.Ok = $true
    return $result
}

function Get-SafeFFmpegError([string]$text, [string]$sensitivePath) {
    if ([string]::IsNullOrWhiteSpace($text)) { return "FFmpeg reported an error." }
    $safe = $text
    if (-not [string]::IsNullOrWhiteSpace($sensitivePath)) {
        $safe = $safe.Replace($sensitivePath, "[source media]")
    }
    $safe = $safe.Trim()
    if ($safe.Length -gt 1600) { $safe = $safe.Substring(0,1600) + "..." }
    return $safe
}

function Get-FrameTimingMap($ffprobe, [string]$path) {
    # SECURITY: enumerate the actual presentation timing of every decoded frame
    # with the trusted embedded FFprobe. Keep only compact typed arrays in
    # memory; do not materialize a huge JSON object or write timing data to disk.
    # This is the timing authority for both CFR and VFR video. A source is
    # accepted only when this complete map can be established and independently
    # reconciled with a full FFmpeg decode pass.
    $result = @{
        Ok = $false; Error = ""; FrameCount = 0; Duration = 0.0; AverageFps = 0.0
        FirstPresentationTime = 0.0; LastPresentationTime = 0.0
        NominalInterval = 0.0; HasVariableIntervals = $false
        Timestamps = $null; Times = $null; Durations = $null; KeyFrames = $null
    }

    if ([string]::IsNullOrWhiteSpace($ffprobe) -or -not (Test-Path -LiteralPath $ffprobe)) {
        $result.Error = "The trusted FFprobe executable is unavailable."
        return $result
    }

    # Bound memory use. Two million frames is already more than 18 hours at
    # 30 fps (or more than 9 hours at 60 fps). Sources beyond this deliberate
    # safety bound fail closed rather than risking runaway process memory.
    $maxFrames = 2000000
    $timestamps = [System.Collections.Generic.List[System.Int64]]::new()
    $rawTimes = [System.Collections.Generic.List[System.Double]]::new()
    $reportedDurations = [System.Collections.Generic.List[System.Double]]::new()
    $keyFrames = [System.Collections.Generic.List[System.Byte]]::new()

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffprobe
    $psi.Arguments = "-hide_banner -v error -select_streams v:0 -show_frames -show_entries frame=best_effort_timestamp,best_effort_timestamp_time,duration_time,key_frame -of compact=p=0:nk=0 -i " + (Quote-Arg $path)
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $p = $null
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $parseError = $null
        $lineNumber = 0

        while (($line = $p.StandardOutput.ReadLine()) -ne $null) {
            $lineNumber++
            if ([string]::IsNullOrWhiteSpace($line)) { continue }

            if ($line.Length -gt 4096) {
                $parseError = "FFprobe returned an unexpectedly long frame-timing record."
                try { $p.Kill() } catch {}
                break
            }

            $fields = @{}
            foreach ($part in $line.Split('|')) {
                $eq = $part.IndexOf('=')
                if ($eq -le 0) { continue }
                $fields[$part.Substring(0,$eq)] = $part.Substring($eq + 1)
            }

            if (-not $fields.ContainsKey('best_effort_timestamp') -or
                -not $fields.ContainsKey('best_effort_timestamp_time') -or
                -not $fields.ContainsKey('key_frame')) {
                $parseError = "FFprobe returned a frame without the required presentation-timing fields."
                try { $p.Kill() } catch {}
                break
            }

            $pts = [int64]0
            $time = [double]0.0
            $key = [int]0
            if (-not [int64]::TryParse($fields['best_effort_timestamp'], [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$pts) -or
                -not [double]::TryParse($fields['best_effort_timestamp_time'], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$time) -or
                -not [int]::TryParse($fields['key_frame'], [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$key) -or
                [double]::IsNaN($time) -or [double]::IsInfinity($time) -or
                ($key -ne 0 -and $key -ne 1)) {
                $parseError = "FFprobe returned an unusable frame presentation timestamp."
                try { $p.Kill() } catch {}
                break
            }

            # FFmpeg filter expressions evaluate numeric operands as doubles.
            # Keep raw PTS values inside the exact IEEE-754 integer range so the
            # exact-preview selector eq(pts,target) cannot round to a neighbour.
            $maxExactPts = [int64]9007199254740991
            if ($pts -gt $maxExactPts -or $pts -lt (-1 * $maxExactPts)) {
                $parseError = "A frame timestamp is too large for exact FFmpeg frame selection."
                try { $p.Kill() } catch {}
                break
            }

            if ($rawTimes.Count -gt 0) {
                $lastIndex = $rawTimes.Count - 1
                if ($time -le $rawTimes[$lastIndex] -or $pts -le $timestamps[$lastIndex]) {
                    $parseError = "Frame presentation timestamps are not strictly increasing, so a unique frame-to-time mapping cannot be established safely."
                    try { $p.Kill() } catch {}
                    break
                }
            }

            $reportedDuration = [double]::NaN
            if ($fields.ContainsKey('duration_time') -and
                -not [string]::IsNullOrWhiteSpace($fields['duration_time']) -and
                $fields['duration_time'] -ne 'N/A') {
                $parsedDuration = [double]0.0
                if ([double]::TryParse($fields['duration_time'], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedDuration) -and
                    -not [double]::IsNaN($parsedDuration) -and -not [double]::IsInfinity($parsedDuration) -and
                    $parsedDuration -gt 0.0) {
                    $reportedDuration = $parsedDuration
                }
            }

            $timestamps.Add($pts)
            $rawTimes.Add($time)
            $reportedDurations.Add($reportedDuration)
            $keyFrames.Add([byte]$key)

            if ($timestamps.Count -gt $maxFrames) {
                $parseError = "The video contains too many frames to build the timing map within the application's safety memory bound."
                try { $p.Kill() } catch {}
                break
            }

            if (($lineNumber % 250) -eq 0) {
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        $p.WaitForExit()
        $stderrTask.Wait(2000) | Out-Null
        $stderr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($parseError) {
            $result.Error = $parseError
            return $result
        }
        if ($p.ExitCode -ne 0) {
            $safeProbeError = if ([string]::IsNullOrWhiteSpace($stderr)) { "FFprobe reported an error." } else { Get-SafeFFmpegError $stderr $path }
            $result.Error = "FFprobe could not enumerate video frame timing. " + $safeProbeError
            return $result
        }
        if ($timestamps.Count -le 0) {
            $result.Error = "FFprobe returned no video frames, so frame timing cannot be established safely."
            return $result
        }

        $count = $timestamps.Count
        $firstTime = $rawTimes[0]
        $lastTime = $rawTimes[$count - 1]
        $nominalInterval = 0.0
        if ($count -gt 1) {
            $nominalInterval = ($lastTime - $firstTime) / [double]($count - 1)
            if ($nominalInterval -le 0.0 -or [double]::IsNaN($nominalInterval) -or [double]::IsInfinity($nominalInterval)) {
                $result.Error = "The frame timing map does not contain a usable presentation interval."
                return $result
            }
        }

        $relativeTimes = [System.Collections.Generic.List[System.Double]]::new()
        $durations = [System.Collections.Generic.List[System.Double]]::new()
        $hasVariableIntervals = $false
        $intervalTolerance = if ($nominalInterval -gt 0.0) { [Math]::Max(0.00005, $nominalInterval * 0.002) } else { 0.00005 }

        for ($i = 0; $i -lt $count; $i++) {
            $relative = $rawTimes[$i] - $firstTime
            if ($relative -lt 0.0 -or [double]::IsNaN($relative) -or [double]::IsInfinity($relative)) {
                $result.Error = "The frame timing map could not be normalized safely."
                return $result
            }
            $relativeTimes.Add($relative)

            if ($i -lt ($count - 1)) {
                $frameDuration = $rawTimes[$i + 1] - $rawTimes[$i]
                if ($frameDuration -le 0.0) {
                    $result.Error = "The frame timing map contains a non-positive presentation interval."
                    return $result
                }
                if ($nominalInterval -gt 0.0 -and [Math]::Abs($frameDuration - $nominalInterval) -gt $intervalTolerance) {
                    $hasVariableIntervals = $true
                }
                $durations.Add($frameDuration)
            }
            else {
                $lastDuration = $reportedDurations[$i]
                if ([double]::IsNaN($lastDuration) -or [double]::IsInfinity($lastDuration) -or $lastDuration -le 0.0) {
                    $lastDuration = $nominalInterval
                }
                if ($lastDuration -le 0.0 -or [double]::IsNaN($lastDuration) -or [double]::IsInfinity($lastDuration)) {
                    $result.Error = "The final frame duration could not be established safely."
                    return $result
                }
                if ($nominalInterval -gt 0.0 -and [Math]::Abs($lastDuration - $nominalInterval) -gt $intervalTolerance) {
                    $hasVariableIntervals = $true
                }
                $durations.Add($lastDuration)
            }
        }

        $duration = ($lastTime - $firstTime) + $durations[$count - 1]
        if ($duration -le 0.0 -or [double]::IsNaN($duration) -or [double]::IsInfinity($duration)) {
            $result.Error = "The video duration could not be established from the frame timing map."
            return $result
        }

        $averageFps = [double]$count / $duration
        if ($averageFps -le 0.0 -or [double]::IsNaN($averageFps) -or [double]::IsInfinity($averageFps)) {
            $result.Error = "The frame timing map produced an invalid average frame rate."
            return $result
        }

        $result.FrameCount = $count
        $result.Duration = $duration
        $result.AverageFps = $averageFps
        $result.FirstPresentationTime = $firstTime
        $result.LastPresentationTime = $relativeTimes[$count - 1]
        $result.NominalInterval = $nominalInterval
        $result.HasVariableIntervals = $hasVariableIntervals
        $result.Timestamps = $timestamps.ToArray()
        $result.Times = $relativeTimes.ToArray()
        $result.Durations = $durations.ToArray()
        $result.KeyFrames = $keyFrames.ToArray()
        $result.Ok = $true
        return $result
    }
    catch {
        $result.Error = "The trusted frame timing map could not be established."
        return $result
    }
    finally {
        if ($p) { $p.Dispose() }
    }
}

# Secure media preflight. Dimensions are taken from an explicitly autorotated
# decoded frame held only in memory, so the UI and export filter graph use the
# same display-coordinate space even when the source carries a rotation matrix.
# For video, trusted FFprobe establishes the complete presentation-timing map;
# a separate full FFmpeg decode pass must then report exactly the same number of
# decoded frames. VFR is accepted only through that validated/reconciled model.
function Get-VideoInfo($ffmpeg, $ffprobe, $path, [bool]$imageMode = $false) {
    $info = @{
        Width = 0; Height = 0; Duration = 0.0; Fps = 0.0; FrameCount = 0
        HasAudio = $false; IsSafe = $false; IsVfr = $false; Error = ""
        FrameTimeline = $null
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-hide_banner -nostdin -loglevel error -autorotate -i " + (Quote-Arg $path) + " -map 0:v:0 -frames:v 1 -f image2pipe -vcodec png pipe:1"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $ms = New-Object System.IO.MemoryStream
        $copyTask = $p.StandardOutput.BaseStream.CopyToAsync($ms)
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $copyTask.GetAwaiter().GetResult()
        $p.WaitForExit()
        $stderrTask.Wait(1000) | Out-Null
        $frameErr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }
        $bytes = $ms.ToArray()
        $ms.Dispose()

        if ($p.ExitCode -ne 0 -or $bytes.Length -eq 0) {
            $info.Error = "FFmpeg could not decode the first video/image frame. " + (Get-SafeFFmpegError $frameErr $path)
            return $info
        }

        $imgStream = New-Object System.IO.MemoryStream(,$bytes)
        try {
            $img = [System.Drawing.Image]::FromStream($imgStream)
            $info.Width = $img.Width
            $info.Height = $img.Height
            $img.Dispose()
        }
        finally {
            $imgStream.Dispose()
        }
    }
    catch {
        $info.Error = "The media preflight could not decode the first frame."
        return $info
    }

    if ($imageMode) {
        $info.Duration = 0.0
        $info.Fps = 1.0
        $info.FrameCount = 1
        $info.IsSafe = $true
        return $info
    }

    # SECURITY: native VFR support is fail-closed. FFprobe's complete frame map
    # is authoritative for logical frame identity and timing; failure to build a
    # strict, usable map rejects the source rather than falling back to fps math.
    $timing = Get-FrameTimingMap $ffprobe $path
    if (-not $timing.Ok) {
        $info.Error = "The video's frame timing could not be established safely. " + $timing.Error
        return $info
    }
    $info.FrameTimeline = $timing

    # Independent reconciliation: fully decode the selected video stream with
    # trusted FFmpeg and count decoded frames. No decoded media is written to
    # disk; wrapped_avframe is discarded by the null muxer.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-progress pipe:1 -hide_banner -nostdin -nostats -loglevel info -autorotate -i " + (Quote-Arg $path) + " -map 0:v:0 -an -sn -dn -c:v wrapped_avframe -fps_mode:v:0 passthrough -enc_time_base:v:0 filter -f null NUL"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $p.StandardOutput.ReadToEndAsync()
        $stderrTask = $p.StandardError.ReadToEndAsync()
        while (-not $p.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 30
        }
        $p.WaitForExit()
        $stdoutTask.Wait(2000) | Out-Null
        $stderrTask.Wait(2000) | Out-Null
        $progressText = if ($stdoutTask.IsCompleted) { $stdoutTask.Result } else { "" }
        $probeText = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($p.ExitCode -ne 0) {
            $info.Error = "FFmpeg could not complete the frame-identity reconciliation pass. " + (Get-SafeFFmpegError $probeText $path)
            return $info
        }

        $info.HasAudio = [bool]($probeText -match '(?m)^\s*Stream #\d+:\d+.*Audio:')

        $frameMatches = [regex]::Matches($progressText, '(?m)^frame=(\d+)\s*$')
        if ($frameMatches.Count -eq 0) {
            $info.Error = "FFmpeg did not return a reliable decoded-frame count. The file was not opened."
            return $info
        }

        $frameCount = [int64]$frameMatches[$frameMatches.Count - 1].Groups[1].Value
        if ($frameCount -le 0) {
            $info.Error = "The video's decoded-frame count could not be established safely."
            return $info
        }

        if ([int64]$timing.FrameCount -ne $frameCount) {
            $info.Error = "FFprobe and FFmpeg reported different decoded frame counts. The file was not opened because frame identity cannot be reconciled safely."
            return $info
        }

        $info.FrameCount = $frameCount
        $info.Duration = [double]$timing.Duration
        $info.Fps = [double]$timing.AverageFps   # informational average only
        $info.IsVfr = [bool]$timing.HasVariableIntervals
        if ($info.Duration -le 0 -or $info.Fps -le 0 -or
            [double]::IsNaN($info.Duration) -or [double]::IsInfinity($info.Duration) -or
            [double]::IsNaN($info.Fps) -or [double]::IsInfinity($info.Fps)) {
            $info.Error = "The validated frame timeline did not produce usable duration/rate information."
            return $info
        }

        $probeText = $null
        $progressText = $null
        $info.IsSafe = $true
        return $info
    }
    catch {
        $info.Error = "The video frame-identity reconciliation check failed."
        return $info
    }
}

function Get-OutputInspection($ffprobe, [string]$path) {
    $result = @{
        Ok = $false; Error = ""; VideoCount = 0; AudioCount = 0; SubtitleCount = 0
        DataCount = 0; AttachmentCount = 0; ChapterCount = 0
        Width = 0; Height = 0; Duration = 0.0; MetadataKeys = @()
    }

    # SECURITY: this function is part of the post-export commit gate. Use
    # ffprobe's structured JSON rather than regexing FFmpeg's human-readable
    # -i banner, so a formatting change cannot silently turn into a false pass.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffprobe
    $psi.Arguments = "-v error -show_streams -show_chapters -show_format -of json " + (Quote-Arg $path)
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $p.StandardOutput.ReadToEndAsync()
        $stderrTask = $p.StandardError.ReadToEndAsync()
        $p.WaitForExit()
        $stdoutTask.Wait(2000) | Out-Null
        $stderrTask.Wait(2000) | Out-Null

        $jsonText = if ($stdoutTask.IsCompleted) { $stdoutTask.Result } else { "" }
        $probeErr = if ($stderrTask.IsCompleted) { $stderrTask.Result } else { "" }

        if ($p.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($jsonText)) {
            $result.Error = "The exported file could not be inspected by FFprobe. " + (Get-SafeFFmpegError $probeErr $path)
            return $result
        }

        try {
            $probe = $jsonText | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $result.Error = "FFprobe returned malformed structured inspection data."
            return $result
        }
    }
    catch {
        $result.Error = "The exported file could not be inspected by FFprobe."
        return $result
    }

    # ConvertFrom-Json in Windows PowerShell 5.1 may represent a single item
    # differently from an array, so always force collection semantics here.
    $streams = @($probe.streams)
    foreach ($stream in $streams) {
        switch ([string]$stream.codec_type) {
            "video"      { $result.VideoCount++ }
            "audio"      { $result.AudioCount++ }
            "subtitle"   { $result.SubtitleCount++ }
            "data"       { $result.DataCount++ }
            "attachment" { $result.AttachmentCount++ }
        }
    }

    $result.ChapterCount = @($probe.chapters).Count

    $videoStreams = @($streams | Where-Object { $_.codec_type -eq "video" })
    if ($videoStreams.Count -gt 0) {
        $firstVideo = $videoStreams[0]
        if ($null -ne $firstVideo.width)  { $result.Width = [int]$firstVideo.width }
        if ($null -ne $firstVideo.height) { $result.Height = [int]$firstVideo.height }
    }

    # Prefer the container duration; fall back to the first video stream only
    # if the muxer does not expose a format duration. Images legitimately have
    # no useful duration and are handled separately by Test-ExportSecurity.
    $durationValue = $null
    if ($probe.format -and $null -ne $probe.format.duration) {
        $durationValue = [string]$probe.format.duration
    }
    if (($null -eq $durationValue -or $durationValue -eq "" -or $durationValue -eq "N/A") -and $videoStreams.Count -gt 0) {
        if ($null -ne $videoStreams[0].duration) { $durationValue = [string]$videoStreams[0].duration }
    }
    if ($durationValue -and $durationValue -ne "N/A") {
        $parsedDuration = 0.0
        if ([double]::TryParse($durationValue, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedDuration)) {
            $result.Duration = $parsedDuration
        }
    }

    # Inspect global, stream and chapter tag *keys*. After -map_metadata -1 /
    # -map_metadata:s -1 / -map_chapters -1, only explicitly allowed muxer or
    # encoder housekeeping may remain. Any unfamiliar key fails closed later.
    $keys = New-Object System.Collections.Generic.List[string]
    function Add-InspectionTagKeys($tags) {
        if ($null -eq $tags) { return }
        foreach ($prop in $tags.PSObject.Properties) {
            $name = [string]$prop.Name
            if (-not [string]::IsNullOrWhiteSpace($name) -and -not $keys.Contains($name)) {
                [void]$keys.Add($name)
            }
        }
    }

    if ($probe.format) { Add-InspectionTagKeys $probe.format.tags }
    foreach ($stream in $streams) { Add-InspectionTagKeys $stream.tags }
    foreach ($chapter in @($probe.chapters)) { Add-InspectionTagKeys $chapter.tags }

    $result.MetadataKeys = @($keys)
    $result.Ok = ($result.VideoCount -gt 0)
    if (-not $result.Ok) {
        $result.Error = "No readable video/image stream was found in the exported file."
    }

    # Drop the structured inspection object after extracting the required
    # security properties. TinyRedactionTool does not persist the JSON.
    $probe = $null
    $jsonText = $null
    return $result
}

function Test-ExportSecurity($ffmpeg, $ffprobe, [string]$path, [bool]$imageMode, [bool]$expectAudio, [int]$expectedWidth, [int]$expectedHeight, [double]$expectedDuration, $expectedTimeline) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return @{ Ok = $false; Error = "The temporary export was not created." }
    }
    try {
        if ((Get-Item -LiteralPath $path -ErrorAction Stop).Length -le 0) {
            return @{ Ok = $false; Error = "The temporary export is empty." }
        }
    } catch {
        return @{ Ok = $false; Error = "The temporary export could not be read." }
    }

    $inspect = Get-OutputInspection $ffprobe $path
    if (-not $inspect.Ok) { return @{ Ok = $false; Error = $inspect.Error } }
    if ($inspect.VideoCount -ne 1) { return @{ Ok = $false; Error = "Validation found an unexpected number of video/image streams." } }
    if ($inspect.SubtitleCount -ne 0 -or $inspect.DataCount -ne 0 -or $inspect.AttachmentCount -ne 0) {
        return @{ Ok = $false; Error = "Validation found an unexpected subtitle, data or attachment stream." }
    }
    if ($inspect.ChapterCount -ne 0) { return @{ Ok = $false; Error = "Validation found chapter metadata in the export." } }

    $expectedAudioCount = if ($expectAudio) { 1 } else { 0 }
    if ($inspect.AudioCount -ne $expectedAudioCount) {
        return @{ Ok = $false; Error = "Validation found an unexpected audio-stream state." }
    }
    if ($inspect.Width -ne $expectedWidth -or $inspect.Height -ne $expectedHeight) {
        return @{ Ok = $false; Error = "Validation found unexpected output dimensions ($($inspect.Width)x$($inspect.Height))." }
    }

    # Allow only muxer/encoder bookkeeping that FFmpeg itself generates after
    # metadata stripping. Anything else fails closed rather than guessing
    # whether an unfamiliar tag might have originated in the source media.
    $allowedMetadata = @(
        'major_brand','minor_version','compatible_brands','encoder','handler_name',
        'vendor_id','duration','language','software'
    )
    foreach ($key in $inspect.MetadataKeys) {
        if ($allowedMetadata -notcontains $key.ToLowerInvariant()) {
            return @{ Ok = $false; Error = "Validation found unexpected metadata key '$key'." }
        }
    }

    if (-not $imageMode) {
        $tol = [Math]::Max(1.0, $expectedDuration * 0.02)
        if ($inspect.Duration -le 0 -or [Math]::Abs($inspect.Duration - $expectedDuration) -gt $tol) {
            return @{ Ok = $false; Error = "Validation found an implausible output duration." }
        }

        # SECURITY: a successful encode is not enough. Re-enumerate the actual
        # decoded output frames with trusted FFprobe and reconcile them against
        # the already-validated source timeline. This detects silent CFR
        # conversion, frame duplication/drop, or timestamp distortion before a
        # .partial file is promoted to the user's destination. Both timelines
        # are normalized to their first presentation timestamp by
        # Get-FrameTimingMap, so harmless container start-time offsets do not
        # affect the comparison.
        if (-not $expectedTimeline -or -not $expectedTimeline.Ok -or
            -not $expectedTimeline.Times -or -not $expectedTimeline.Durations -or
            [int64]$expectedTimeline.FrameCount -le 0) {
            return @{ Ok = $false; Error = "The validated source frame timeline is unavailable for export verification." }
        }

        $actualTimeline = Get-FrameTimingMap $ffprobe $path
        if (-not $actualTimeline.Ok) {
            return @{ Ok = $false; Error = "Validation could not establish the exported frame timeline safely. $($actualTimeline.Error)" }
        }
        if ([int64]$actualTimeline.FrameCount -ne [int64]$expectedTimeline.FrameCount) {
            return @{ Ok = $false; Error = "Validation found a frame-count mismatch between source and export." }
        }

        $nominal = [double]$expectedTimeline.NominalInterval
        # WebM commonly represents timestamps at millisecond resolution, while
        # MP4 may use a finer timescale. Allow only a small muxer-quantization
        # tolerance; this is intentionally far tighter than one video frame.
        $timeTolerance = if ($nominal -gt 0.0) {
            [Math]::Max(0.0015, [Math]::Min(0.005, $nominal * 0.02))
        } else { 0.0015 }

        for ($i = 0; $i -lt [int]$expectedTimeline.FrameCount; $i++) {
            $expectedTime = [double]$expectedTimeline.Times[$i]
            $actualTime = [double]$actualTimeline.Times[$i]
            if ([Math]::Abs($actualTime - $expectedTime) -gt $timeTolerance) {
                return @{ Ok = $false; Error = "Validation found altered presentation timing at output frame $i." }
            }
        }

        # Do not compare Get-FrameTimingMap.Duration here: after H.264
        # encoding FFprobe may report a nominal per-frame duration on the final
        # decoded frame even when the container/video duration and every actual
        # presentation timestamp are correct. Frame count + every normalized
        # frame start are the unambiguous invariants. Container duration is
        # validated separately above.
    }

    # Decode one frame from the newly generated (already-redacted) file. This
    # is intentionally lightweight; exact colour-byte comparison would give a
    # false sense of security on lossy codecs because compression alters solid
    # colours slightly around block/edge boundaries.
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ffmpeg
    $psi.Arguments = "-hide_banner -nostdin -loglevel error -i " + (Quote-Arg $path) + " -map 0:v:0 -frames:v 1 -an -sn -dn -c:v wrapped_avframe -f null NUL"
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    try {
        $p = [System.Diagnostics.Process]::Start($psi)
        $decodeErr = $p.StandardError.ReadToEnd()
        $null = $p.StandardOutput.ReadToEnd()
        $p.WaitForExit()
        if ($p.ExitCode -ne 0) {
            return @{ Ok = $false; Error = "Validation could not decode the exported video/image stream." }
        }
    }
    catch {
        return @{ Ok = $false; Error = "Validation could not decode the exported video/image stream." }
    }

    return @{ Ok = $true; Error = "" }
}

# Maps the user-facing 1-10 Blur/Pixelate strength slider to the actual
# parameters each effect uses under the hood. Each table's index-5 (strength
# 5, the slider's default position) reproduces this app's original hardcoded
# constant, so anyone who never touches the slider sees the exact same result
# as before - the slider only ever makes the effect adjustable, not different
# by default.
#
# Get-BlurRadiusTarget: target luma radius fed into Get-SafeBoxBlurSpec below
# (used for the real FFmpeg export). It's a *target* rather than the radius
# actually used, since Get-SafeBoxBlurSpec still has to clamp it down for
# small redaction boxes where a large radius isn't legal.
function Get-BlurRadiusTarget([int]$strength) {
    # Re-based so the slider's default (5) hides text far more reliably on
    # high-resolution images: every position now maps to what used to sit
    # 3 notches higher (old position 8's radius, 26, is the new position 5;
    # old position 5's radius, 12, is the new position 2), and positions 8-10
    # extend the same growth curve past the old table's ceiling of 42.
    $table = @(10,12,16,20,26,33,42,54,68,86)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# Get-PixelateDivisor: how many times smaller the redaction box is shrunk
# before being scaled back up with nearest-neighbor interpolation - a bigger
# divisor means bigger, chunkier blocks (stronger pixelation). Shared by both
# the real FFmpeg export (Build-RedactionFilterComplex) and the live image
# preview (Get-LiveEffectPatch) so what's shown matches what's exported.
function Get-PixelateDivisor([int]$strength) {
    $table = @(6,9,12,15,18,24,30,38,48,60)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# Get-BlurLiveDivisor: the equivalent shrink-then-bicubic-upscale divisor used
# only by the live image preview's cheap GDI+ blur approximation (there's no
# GDI+ box blur, so this stands in for Get-BlurRadiusTarget's real boxblur on
# that path). Kept as a separate table from Get-PixelateDivisor since the two
# approximations respond differently to the same divisor value.
function Get-BlurLiveDivisor([int]$strength) {
    # Shifted by the same 3 notches as Get-BlurRadiusTarget above, so the
    # live GDI+ preview keeps tracking the strengthened real boxblur curve
    # position-for-position.
    $table = @(8,10,13,16,20,25,30,38,46,58)
    $idx = [Math]::Max(1, [Math]::Min(10, $strength)) - 1
    return $table[$idx]
}

# ---------------------------------------------------------------------------
# v2.2.0 C1 Enhanced Blur/Pixelate — strength-5 application prototype.
#
# Exact public deterministic A1-R8 5P20-CN reference:
#   - long axis: 5 structural cells (short axis aspect-derived, minimum 2);
#   - 4x oversampled intermediate lattice;
#   - 2.0x overlapping pooled neighbourhoods;
#   - 8 luma levels;
#   - 7-symbol non-uniform neutral-centred chroma codebook.
#
# SECURITY BOUNDARY: protected source pixels are consulted only while building
# the tiny proxy. Final Enhanced Blur/Pixelate rendering uses only that proxy.
# C1 applies this exact renderer to still-image live preview. Enhanced export is
# fail-closed until the custom FFmpeg profile is extended and reapproved.
function Get-EnhancedProxyDimensions {
    param([int]$RegionWidth,[int]$RegionHeight,[int]$LongAxisCells = 5)
    if ($RegionWidth -ge $RegionHeight) {
        $pw = $LongAxisCells
        $ph = [Math]::Max(2,[Math]::Round($LongAxisCells * ($RegionHeight / [double]$RegionWidth)))
    } else {
        $ph = $LongAxisCells
        $pw = [Math]::Max(2,[Math]::Round($LongAxisCells * ($RegionWidth / [double]$RegionHeight)))
    }
    return @([int]$pw,[int]$ph)
}

function Quantize-EnhancedLuma {
    param([double]$Value,[int]$Levels = 8)
    $v = [Math]::Max(0.0,[Math]::Min(255.0,$Value))
    $step = 255.0 / ($Levels - 1)
    return [Math]::Round($v / $step) * $step
}

function Quantize-EnhancedChromaNeutral {
    param([double]$Value)
    [double[]]$symbols = @(-48.0,-24.0,-10.0,0.0,10.0,24.0,48.0)
    $delta = [Math]::Max(-127.0,[Math]::Min(127.0,$Value - 128.0))
    $best = $symbols[0]
    $bestDistance = [Math]::Abs($delta - $best)
    foreach ($symbol in $symbols) {
        $distance = [Math]::Abs($delta - $symbol)
        if ($distance -lt $bestDistance) { $best = $symbol; $bestDistance = $distance }
    }
    return 128.0 + $best
}

function Quantize-EnhancedProxy {
    param([System.Drawing.Bitmap]$Proxy)
    for ($yy=0; $yy -lt $Proxy.Height; $yy++) {
        for ($xx=0; $xx -lt $Proxy.Width; $xx++) {
            $c=$Proxy.GetPixel($xx,$yy)
            $yv=0.2126*$c.R + 0.7152*$c.G + 0.0722*$c.B
            $cb=128.0 + (($c.B-$yv)*0.5389)
            $cr=128.0 + (($c.R-$yv)*0.6350)
            $qy=Quantize-EnhancedLuma $yv 8
            $qcb=Quantize-EnhancedChromaNeutral $cb
            $qcr=Quantize-EnhancedChromaNeutral $cr
            $r=$qy + 1.5748*($qcr-128.0)
            $b=$qy + 1.8556*($qcb-128.0)
            $g=($qy - 0.2126*$r - 0.0722*$b) / 0.7152
            $ri=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$r)))
            $gi=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$g)))
            $bi=[int][Math]::Round([Math]::Max(0.0,[Math]::Min(255.0,$b)))
            $Proxy.SetPixel($xx,$yy,[System.Drawing.Color]::FromArgb($ri,$gi,$bi))
        }
    }
}

function Get-EnhancedReflectedIndex {
    param([int]$Index,[int]$Length)
    if ($Length -le 1) { return 0 }
    $i=$Index
    while ($i -lt 0 -or $i -ge $Length) {
        if ($i -lt 0) { $i=-$i-1 }
        elseif ($i -ge $Length) { $i=(2*$Length)-$i-1 }
    }
    return $i
}

function New-EnhancedStructuralProxy {
    param([System.Drawing.Bitmap]$Source,[System.Drawing.Rectangle]$Region)
    $dims=Get-EnhancedProxyDimensions $Region.Width $Region.Height 5
    $proxyW=[int]$dims[0]; $proxyH=[int]$dims[1]
    $oversample=4; $poolFactor=2.0
    $latticeW=[Math]::Max($proxyW,$proxyW*$oversample)
    $latticeH=[Math]::Max($proxyH,$proxyH*$oversample)
    $lattice=New-Object System.Drawing.Bitmap($latticeW,$latticeH,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $lg=[System.Drawing.Graphics]::FromImage($lattice)
    try {
        $lg.Clear([System.Drawing.Color]::Black)
        $lg.CompositingMode=[System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $lg.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $lg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $lg.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $lg.SmoothingMode=[System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $dest=New-Object System.Drawing.Rectangle(0,0,$latticeW,$latticeH)
        $lg.DrawImage($Source,$dest,$Region.X,$Region.Y,$Region.Width,$Region.Height,[System.Drawing.GraphicsUnit]::Pixel)
    } finally { $lg.Dispose() }
    $proxy=New-Object System.Drawing.Bitmap($proxyW,$proxyH,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $windowW=[Math]::Max(1,[int][Math]::Round($oversample*$poolFactor))
        $windowH=[Math]::Max(1,[int][Math]::Round($oversample*$poolFactor))
        for ($py=0; $py -lt $proxyH; $py++) {
            for ($px=0; $px -lt $proxyW; $px++) {
                $centerX=(($px+0.5)*$oversample)-0.5
                $centerY=(($py+0.5)*$oversample)-0.5
                $left=[int][Math]::Floor($centerX-(($windowW-1)/2.0))
                $top=[int][Math]::Floor($centerY-(($windowH-1)/2.0))
                [double]$sumR=0; [double]$sumG=0; [double]$sumB=0; [int]$count=0
                for ($wy=0; $wy -lt $windowH; $wy++) {
                    $ly=Get-EnhancedReflectedIndex ($top+$wy) $latticeH
                    for ($wx=0; $wx -lt $windowW; $wx++) {
                        $lx=Get-EnhancedReflectedIndex ($left+$wx) $latticeW
                        $c=$lattice.GetPixel($lx,$ly)
                        $sumR+=$c.R; $sumG+=$c.G; $sumB+=$c.B; $count++
                    }
                }
                $r=[int][Math]::Round($sumR/$count); $g=[int][Math]::Round($sumG/$count); $b=[int][Math]::Round($sumB/$count)
                $proxy.SetPixel($px,$py,[System.Drawing.Color]::FromArgb($r,$g,$b))
            }
        }
    } finally { $lattice.Dispose() }
    Quantize-EnhancedProxy $proxy
    return $proxy
}

function New-EnhancedReconstructedPatch {
    param(
        [System.Drawing.Bitmap]$Proxy,
        [int]$TargetWidth,
        [int]$TargetHeight,
        [ValidateSet("Blur","Pixelate")]
        [string]$Mode
    )

    # C1a changes ONLY the cosmetic reconstruction after the accepted safe
    # structural proxy has already been built. Nothing in this function reads
    # protected source pixels.
    #
    # The C1 renderer stretched the tiny 5xN proxy directly to output size:
    #   Blur     -> bicubic, which could ring/halo and look "inverted";
    #   Pixelate -> nearest-neighbour, exposing only a handful of giant cells.
    #
    # C1a first creates a denser COSMETIC grid from the safe proxy. Those extra
    # samples are interpolation only and contain no additional source detail.
    # The final visual therefore resembles conventional Blur/Pixelate while
    # preserving the exact same structural-information ceiling.

    if ($TargetWidth -le 0 -or $TargetHeight -le 0) { return $null }

    $wrapAttr = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapAttr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

    try {
        if ($Mode -eq "Pixelate") {
            # Match the visual block density of Standard strength 5, but derive
            # every cosmetic cell solely from the already-safe proxy.
            $divisor = Get-PixelateDivisor 5
            $gridW = [Math]::Max(
                $Proxy.Width,
                [Math]::Max(2,[int][Math]::Floor($TargetWidth / [double]$divisor)))
            $gridH = [Math]::Max(
                $Proxy.Height,
                [Math]::Max(2,[int][Math]::Floor($TargetHeight / [double]$divisor)))

            $grid = New-Object System.Drawing.Bitmap(
                $gridW,
                $gridH,
                [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

            $gg = [System.Drawing.Graphics]::FromImage($grid)
            try {
                $gg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $gg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
                $gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

                $dest = New-Object System.Drawing.Rectangle(0,0,$gridW,$gridH)
                $gg.DrawImage(
                    $Proxy,
                    $dest,
                    0,0,$Proxy.Width,$Proxy.Height,
                    [System.Drawing.GraphicsUnit]::Pixel,
                    $wrapAttr)
            }
            finally {
                $gg.Dispose()
            }

            $patch = New-Object System.Drawing.Bitmap(
                $TargetWidth,
                $TargetHeight,
                [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

            $pg = [System.Drawing.Graphics]::FromImage($patch)
            try {
                $pg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $pg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $pg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

                $dest = New-Object System.Drawing.Rectangle(0,0,$TargetWidth,$TargetHeight)
                $pg.DrawImage(
                    $grid,
                    $dest,
                    0,0,$grid.Width,$grid.Height,
                    [System.Drawing.GraphicsUnit]::Pixel,
                    $wrapAttr)
            }
            finally {
                $pg.Dispose()
                $grid.Dispose()
            }

            return $patch
        }

        # Enhanced Blur: build a Standard-strength-5-density cosmetic image
        # from the safe proxy using bilinear interpolation (not bicubic, which
        # caused visible ringing), then low-pass it once more before scaling to
        # final size. The smoothing stages operate ONLY on proxy-derived pixels.
        $divisor = Get-BlurLiveDivisor 5
        $gridW = [Math]::Max(
            $Proxy.Width,
            [Math]::Max(2,[int][Math]::Floor($TargetWidth / [double]$divisor)))
        $gridH = [Math]::Max(
            $Proxy.Height,
            [Math]::Max(2,[int][Math]::Floor($TargetHeight / [double]$divisor)))

        $grid = New-Object System.Drawing.Bitmap(
            $gridW,
            $gridH,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $gg = [System.Drawing.Graphics]::FromImage($grid)
        try {
            $gg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $gg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $gg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $gg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $gg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$gridW,$gridH)
            $gg.DrawImage(
                $Proxy,
                $dest,
                0,0,$Proxy.Width,$Proxy.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $gg.Dispose()
        }

        # One extra proxy-only low-pass stage makes the result read as Blur
        # rather than a magnified structural heat-map.
        $smoothW = [Math]::Max(
            $Proxy.Width,
            [Math]::Max(2,[int][Math]::Ceiling($gridW / 2.0)))
        $smoothH = [Math]::Max(
            $Proxy.Height,
            [Math]::Max(2,[int][Math]::Ceiling($gridH / 2.0)))

        $smooth = New-Object System.Drawing.Bitmap(
            $smoothW,
            $smoothH,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $sg = [System.Drawing.Graphics]::FromImage($smooth)
        try {
            $sg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $sg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $sg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$smoothW,$smoothH)
            $sg.DrawImage(
                $grid,
                $dest,
                0,0,$grid.Width,$grid.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $sg.Dispose()
            $grid.Dispose()
        }

        $patch = New-Object System.Drawing.Bitmap(
            $TargetWidth,
            $TargetHeight,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)

        $pg = [System.Drawing.Graphics]::FromImage($patch)
        try {
            $pg.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $pg.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $pg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBilinear
            $pg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $pg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality

            $dest = New-Object System.Drawing.Rectangle(0,0,$TargetWidth,$TargetHeight)
            $pg.DrawImage(
                $smooth,
                $dest,
                0,0,$smooth.Width,$smooth.Height,
                [System.Drawing.GraphicsUnit]::Pixel,
                $wrapAttr)
        }
        finally {
            $pg.Dispose()
            $smooth.Dispose()
        }

        return $patch
    }
    finally {
        $wrapAttr.Dispose()
    }
}

function Get-EnhancedExportEffectSpec {
    param(
        [string]$Mode,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H
    )

    # Export information ceiling mirrors the accepted application architecture:
    # 5-cell long axis, 4x intermediate lattice, P20 overlapping pooling,
    # 8 luma levels, 7 neutral-centred chroma symbols.
    #
    # FFmpeg implements the pooling as an 8x8 average on the 4x lattice before
    # collapsing to the final tiny proxy. Everything after that point is purely
    # cosmetic reconstruction from the tiny proxy.
    $dims = Get-EnhancedProxyDimensions $W $H 5
    $proxyW = [int]$dims[0]
    $proxyH = [int]$dims[1]
    $latticeW = $proxyW * 4
    $latticeH = $proxyH * 4

    # 8 luma symbols across full 0..255.
    $yExpr = "floor((val+18.2142857)/36.4285714)*36.4285714"

    # R8/C1a public 7-symbol neutral-centred chroma codebook:
    # signed deviations -48,-24,-10,0,+10,+24,+48 around 128.
    # Midpoint thresholds become absolute 8-bit values:
    # 92,111,123,133,145,164 -> 80,104,118,128,138,152,176.
    $cExpr = "if(lt(val\,92)\,80\,if(lt(val\,111)\,104\,if(lt(val\,123)\,118\,if(lt(val\,133)\,128\,if(lt(val\,145)\,138\,if(lt(val\,164)\,152\,176))))))"

    $base = "crop=$W`:$H`:$X`:$Y," +
            "scale=$latticeW`:$latticeH`:flags=bicubic`:out_range=full," +
            "format=yuv444p," +
            "avgblur=sizeX=8`:sizeY=8," +
            "scale=$proxyW`:$proxyH`:flags=neighbor," +
            "lutyuv=y='$yExpr'`:u='$cExpr'`:v='$cExpr'"

    if ($Mode -eq "Pixelate") {
        # Cosmetic block density tracks Standard strength 5, but every one of
        # these extra blocks is interpolated only from the already-tiny proxy.
        $divisor = Get-PixelateDivisor 5
        $gridW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Floor($W / [double]$divisor)))
        $gridH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Floor($H / [double]$divisor)))
        return $base + ",scale=$gridW`:$gridH`:flags=bilinear,scale=$W`:$H`:flags=neighbor"
    }

    # Cosmetic Enhanced Blur follows C1a's renderer structure: proxy-derived
    # dense representation, one further low-pass resize, then smooth final scale.
    $divisor = Get-BlurLiveDivisor 5
    $gridW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Floor($W / [double]$divisor)))
    $gridH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Floor($H / [double]$divisor)))
    $smoothW = [Math]::Max($proxyW,[Math]::Max(2,[int][Math]::Ceiling($gridW / 2.0)))
    $smoothH = [Math]::Max($proxyH,[Math]::Max(2,[int][Math]::Ceiling($gridH / 2.0)))

    return $base +
           ",scale=$gridW`:$gridH`:flags=bilinear" +
           ",scale=$smoothW`:$smoothH`:flags=bilinear" +
           ",scale=$W`:$H`:flags=bilinear"
}

function Get-RedactionEnhanced($r) {
    if (-not $r) { return $false }
    if ($r -is [hashtable]) {
        if ($r.ContainsKey("Enhanced")) { return [bool]$r["Enhanced"] }
        return $false
    }
    if ($r.PSObject -and $r.PSObject.Properties["Enhanced"]) { return [bool]$r.Enhanced }
    return $false
}

# FFmpeg's boxblur limits the radius independently for the luma and chroma
# planes. With common 4:2:0 video, the chroma plane is half-resolution, so a
# fixed radius such as 12 can fail on short/narrow redaction boxes even though
# the same radius is valid for the luma plane.
#
# Build a visually equivalent blur specification whose radii are automatically
# clamped to values that are legal for the current crop size. $targetRadius
# is normally the output of Get-BlurRadiusTarget above (defaults to the
# original hardcoded 12 so existing callers/tests are unaffected).
function Get-SafeBoxBlurSpec([int]$w, [int]$h, [int]$targetRadius = 12) {
    $minDim = [Math]::Max(2, [Math]::Min($w, $h))

    # Luma radius must be <= min(luma_w,luma_h)/2.
    $lumaMax = [Math]::Max(0, [int][Math]::Floor(($minDim - 1) / 2.0))
    $lumaRadius = [Math]::Min($targetRadius, $lumaMax)

    # For the common yuv420p input format, chroma dimensions are approximately
    # half the luma dimensions, making the legal chroma radius approximately
    # one quarter of the smallest crop dimension. Using this conservative
    # value is also harmless for formats with higher chroma resolution.
    $chromaMax = [Math]::Max(0, [int][Math]::Floor(($minDim - 1) / 4.0))
    $chromaRadius = [Math]::Min($lumaRadius, $chromaMax)

    return "boxblur=luma_radius=$lumaRadius`:luma_power=2`:chroma_radius=$chromaRadius`:chroma_power=2"
}
 
# Builds the -filter_complex string (and the name of the final video label to map)
# for an ordered list of redaction entries. Kept free of any WinForms dependency so
# it can be exercised by a plain script for testing.
#
# $redactionList entries with Shape "Rectangle" (or no Shape at all, for safety)
# use the original rectangle-only drawbox/crop+overlay approach - unchanged from
# earlier versions, and does not need a mask file.
#
# Entries with Shape "Oval" or "Polygon" need a per-redaction mask image (same
# W x H as the entry's bounding box, already rendered to disk by the caller via
# New-ShapeMaskFile - this function is only handed the resulting file *paths*,
# so it stays free of any System.Drawing dependency and can be tested with fake
# paths that don't need to exist). Each such entry consumes one extra ffmpeg
# input; $maskPaths must contain a path for every non-rectangular index.
#   - "Black box": the mask is a real RGBA PNG (transparent background, solid
#     opaque black shape) and is overlaid directly - no need to sample the
#     original frame content.
#   - "Blur"/"Pixelate": the mask is a plain white-shape-on-black PNG. The
#     usual crop+effect patch is generated exactly as for rectangles, then
#     `alphamerge` copies the mask's luma in as that patch's alpha channel
#     before it's overlaid, so only the shape (not its bounding box) actually
#     changes in the output.
function Build-RedactionFilterComplex($redactionList, $maskPaths) {
    if (-not $maskPaths) { $maskPaths = @{} }

    $filterParts = New-Object System.Collections.Generic.List[string]
    $maskInputArgs = New-Object System.Collections.Generic.List[string]
    $cur = "0:v"
    $nextInputIndex = 1

    # Trusted FFmpeg -autorotate resolves source orientation first. Additional
    # UserRotation is then baked into pixels before any redaction geometry is
    # applied, exactly matching the application's canonical working space.
    switch ([int]$script:userRotation) {
        0 { }
        90 {
            $filterParts.Add("[0:v]transpose=clock[ur0]")
            $cur = "ur0"
        }
        180 {
            $filterParts.Add("[0:v]transpose=clock[urA]")
            $filterParts.Add("[urA]transpose=clock[ur0]")
            $cur = "ur0"
        }
        270 {
            $filterParts.Add("[0:v]transpose=cclock[ur0]")
            $cur = "ur0"
        }
        default {
            throw "Build-RedactionFilterComplex: invalid UserRotation '$script:userRotation'."
        }
    }

    for ($i = 0; $i -lt $redactionList.Count; $i++) {
        $r = $redactionList[$i]
        $x = $r.X; $y = $r.Y; $w = $r.W; $h = $r.H
        $startFrame = [int]$r.BufferedStartFrame
        $endFrame = [int]$r.BufferedEndFrame

        if ($startFrame -lt 0 -or $endFrame -lt $startFrame -or
            $script:totalFrames -le 0 -or $endFrame -ge $script:totalFrames) {
            throw "Build-RedactionFilterComplex: invalid buffered frame range."
        }

        $enable = "between(n\,$startFrame\,$endFrame)"
        $nextLabel = "v$i"
        $isRect = (-not $r.Shape) -or ($r.Shape -eq "Rectangle")
        $strength = if ($r.Strength) { [int]$r.Strength } else { 5 }
        $enhanced = Get-RedactionEnhanced $r
        $boxColor = if ($r.Color) { $r.Color } else { [System.Drawing.Color]::Black }
        $colorHex = "0x{0:X2}{1:X2}{2:X2}" -f $boxColor.R, $boxColor.G, $boxColor.B

        if ($isRect) {
            if ($r.Mode -eq "Black box") {
                $filterParts.Add("[$cur]drawbox=x=$x`:y=$y`:w=$w`:h=$h`:color=$colorHex`:t=fill:enable='$enable'[$nextLabel]")
            }
            else {
                $baseLbl = "b$i"; $tmpLbl = "t$i"; $effLbl = "e$i"

                if ($enhanced) {
                    $eff = Get-EnhancedExportEffectSpec $r.Mode $x $y $w $h
                }
                elseif ($r.Mode -eq "Blur") {
                    $blurSpec = Get-SafeBoxBlurSpec $w $h (Get-BlurRadiusTarget $strength)
                    $eff = "crop=$w`:$h`:$x`:$y,$blurSpec"
                }
                else {
                    $pixelDivisor = Get-PixelateDivisor $strength
                    $smallW = [Math]::Max(8, [int]($w / $pixelDivisor))
                    $smallH = [Math]::Max(8, [int]($h / $pixelDivisor))
                    $eff = "crop=$w`:$h`:$x`:$y,scale=$smallW`:$smallH`:flags=neighbor,scale=$w`:$h`:flags=neighbor"
                }

                $filterParts.Add("[$cur]split[$baseLbl][$tmpLbl]")
                $filterParts.Add("[$tmpLbl]$eff" + "[$effLbl]")
                $filterParts.Add("[$baseLbl][$effLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
        }
        else {
            if (-not $maskPaths.ContainsKey($i)) {
                throw "Build-RedactionFilterComplex: missing mask path for non-rectangular redaction index $i"
            }

            $maskInputIdx = $nextInputIndex
            $maskInputArgs.Add((Quote-Arg $maskPaths[$i]))
            $nextInputIndex++

            if ($r.Mode -eq "Black box") {
                $maskFmtLbl = "mf$i"
                $filterParts.Add("[${maskInputIdx}:v]format=rgba[$maskFmtLbl]")
                $filterParts.Add("[$cur][$maskFmtLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
            else {
                $baseLbl = "b$i"; $tmpLbl = "t$i"; $effLbl = "e$i"; $mergedLbl = "m$i"

                if ($enhanced) {
                    $eff = Get-EnhancedExportEffectSpec $r.Mode $x $y $w $h
                }
                elseif ($r.Mode -eq "Blur") {
                    $blurSpec = Get-SafeBoxBlurSpec $w $h (Get-BlurRadiusTarget $strength)
                    $eff = "crop=$w`:$h`:$x`:$y,$blurSpec"
                }
                else {
                    $pixelDivisor = Get-PixelateDivisor $strength
                    $smallW = [Math]::Max(8, [int]($w / $pixelDivisor))
                    $smallH = [Math]::Max(8, [int]($h / $pixelDivisor))
                    $eff = "crop=$w`:$h`:$x`:$y,scale=$smallW`:$smallH`:flags=neighbor,scale=$w`:$h`:flags=neighbor"
                }

                $filterParts.Add("[$cur]split[$baseLbl][$tmpLbl]")
                $filterParts.Add("[$tmpLbl]$eff" + "[$effLbl]")
                $filterParts.Add("[$effLbl][${maskInputIdx}:v]alphamerge[$mergedLbl]")
                $filterParts.Add("[$baseLbl][$mergedLbl]overlay=$x`:$y`:enable='$enable'[$nextLabel]")
            }
        }

        $cur = $nextLabel
    }

    return @{
        FilterComplex = [string]::Join(";", $filterParts)
        FinalLabel = $cur
        MaskInputArgs = $maskInputArgs
    }
}
function Normalize-VideoRect([double]$x, [double]$y, [double]$w, [double]$h) {
    $x = [int][Math]::Floor($x)
    $y = [int][Math]::Floor($y)
    $w = [int][Math]::Ceiling($w)
    $h = [int][Math]::Ceiling($h)
 
    $x = [Math]::Max(0, [Math]::Min($x, $videoWidth - 2))
    $y = [Math]::Max(0, [Math]::Min($y, $videoHeight - 2))
    $w = [Math]::Max(2, [Math]::Min($w, $videoWidth - $x))
    $h = [Math]::Max(2, [Math]::Min($h, $videoHeight - $y))
 
    if ($x % 2 -ne 0) { $x -= 1 }
    if ($y % 2 -ne 0) { $y -= 1 }
    if ($w % 2 -ne 0) {
        if ($x + $w + 1 -le $videoWidth) { $w += 1 } else { $w -= 1 }
    }
    if ($h % 2 -ne 0) {
        if ($y + $h + 1 -le $videoHeight) { $h += 1 } else { $h -= 1 }
    }
    if ($w -lt 2) { $w = 2 }
    if ($h -lt 2) { $h = 2 }
 
    return @{ X = $x; Y = $y; W = $w; H = $h }
}
 
# Given a drag delta (in whatever coordinate space the caller uses) and whether
# Shift-constrain is active, returns a delta with equal magnitude on both axes
# (preserving each axis's original direction) so a dragged Rectangle becomes a
# square and a dragged Oval becomes a circle. Pure math - no controls involved.
function Get-ConstrainedDelta([double]$dx, [double]$dy, [bool]$constrain) {
    if (-not $constrain) { return @{ Dx = $dx; Dy = $dy } }
 
    $side = [Math]::Max([Math]::Abs($dx), [Math]::Abs($dy))
    $sx = if ($dx -lt 0) { -1 } else { 1 }
    $sy = if ($dy -lt 0) { -1 } else { 1 }
    return @{ Dx = $side * $sx; Dy = $side * $sy }
}
 
# Creates an export-only copy of the redaction list. Secure opaque redactions
# are expanded by one pixel on each available side as a small safety margin;
# the on-screen selection and stored user geometry remain unchanged.
function Get-ExportRedactionList($sourceList) {
    $margin = 1
    $list = New-Object System.Collections.ArrayList
    foreach ($r in $sourceList) {
        $x = [int]$r.X; $y = [int]$r.Y; $w = [int]$r.W; $h = [int]$r.H
        if ($r.Mode -eq "Black box") {
            $right = [Math]::Min($videoWidth, $x + $w + $margin)
            $bottomEdge = [Math]::Min($videoHeight, $y + $h + $margin)
            $x = [Math]::Max(0, $x - $margin)
            $y = [Math]::Max(0, $y - $margin)
            $w = $right - $x
            $h = $bottomEdge - $y
        }
        $copy = [PSCustomObject]@{
            Shape = $r.Shape
            X = $x; Y = $y; W = $w; H = $h
            Points = $r.Points
            Mode = $r.Mode
            Strength = $r.Strength
            Enhanced = Get-RedactionEnhanced $r
            Color = $r.Color
            # Logical frame indexes are the sole export timing authority.
            # Display timestamps stay on the UI redaction objects but are not
            # copied into this export-only structure, preventing an accidental
            # return to second/fps-based filter activation.
            StartFrame = [int]$r.StartFrame
            EndFrame = [int]$r.EndFrame
            BufferedStartFrame = [int]$r.BufferedStartFrame
            BufferedEndFrame = [int]$r.BufferedEndFrame
            CommitOrder = if ($r.PSObject.Properties["CommitOrder"]) { [int]$r.CommitOrder } else { -1 }
        }
        [void]$list.Add($copy)
    }
    return ,$list
}

# Given a candidate freeform (Polygon) point and the previous vertex already
# placed, returns a MEDIA-space PointF at the same distance from $from but with
# its angle snapped to the nearest 0/45/90 degree step whenever $constrain is
# true. Keeping this in media space means the draft remains canonical while
# Shift still produces visually correct horizontal/vertical/45-degree segments.
function Get-AngleSnappedPoint([System.Drawing.PointF]$from, [System.Drawing.PointF]$to, [bool]$constrain) {
    if (-not $constrain) { return $to }

    $dx = [double]$to.X - [double]$from.X
    $dy = [double]$to.Y - [double]$from.Y
    $dist = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    if ($dist -lt 0.01) { return $to }

    $angle = [Math]::Atan2($dy, $dx)
    $step = [Math]::PI / 4.0
    $snapped = [Math]::Round($angle / $step) * $step

    $nx = [single]([double]$from.X + ([Math]::Cos($snapped) * $dist))
    $ny = [single]([double]$from.Y + ([Math]::Sin($snapped) * $dist))
    return New-Object System.Drawing.PointF($nx, $ny)
}

# Standard ray-casting point-in-polygon test, used to decide whether a click
# on a closed-but-uncommitted freeform shape should start moving it rather
# than starting a brand new path. Both the test point and polygon vertices are
# canonical MEDIA-space PointF values in v2.0.0 Slice 2.
function Test-PointInPolygon([System.Drawing.PointF]$pt, $polyPoints) {
    $inside = $false
    $n = $polyPoints.Count
    $j = $n - 1
    for ($i = 0; $i -lt $n; $i++) {
        $pi = $polyPoints[$i]; $pj = $polyPoints[$j]
        if ((($pi.Y -gt $pt.Y) -ne ($pj.Y -gt $pt.Y)) -and
            ($pt.X -lt (($pj.X - $pi.X) * ($pt.Y - $pi.Y) / ($pj.Y - $pi.Y) + $pi.X))) {
            $inside = -not $inside
        }
        $j = $i
    }
    return $inside
}

# Bounding box (MEDIA space) of a set of draft freeform points. It is used
# only to clamp whole-shape movement to the canonical media bounds.
function Get-PointsBoundingRect($points) {
    $minX = [double]$points[0].X; $maxX = [double]$points[0].X
    $minY = [double]$points[0].Y; $maxY = [double]$points[0].Y
    foreach ($pt in $points) {
        if ($pt.X -lt $minX) { $minX = [double]$pt.X }
        if ($pt.X -gt $maxX) { $maxX = [double]$pt.X }
        if ($pt.Y -lt $minY) { $minY = [double]$pt.Y }
        if ($pt.Y -gt $maxY) { $maxY = [double]$pt.Y }
    }
    return New-Object System.Drawing.RectangleF(
        [single]$minX, [single]$minY,
        [single]($maxX - $minX), [single]($maxY - $minY))
}

# The legal extent for uncommitted draft vertices/endpoints. Mouse points map
# to media pixel positions 0..(size-1), matching Clamp-MediaPoint.
function Get-DraftMediaBounds {
    if ($videoWidth -le 0 -or $videoHeight -le 0) { return $null }
    return New-Object System.Drawing.RectangleF(
        0.0, 0.0,
        [single][Math]::Max(0.0, ([double]$videoWidth - 1.0)),
        [single][Math]::Max(0.0, ([double]$videoHeight - 1.0)))
}

# Given a shape's original bounding box and a raw (dx,dy) the mouse has
# moved, returns the same delta clipped so the translated bounding box never
# leaves the supplied bounds. In Slice 2 the caller supplies MEDIA bounds.
function Get-ClampedTranslation($origBounds, [double]$dx, [double]$dy, $bounds) {
    $minDx = $bounds.X - $origBounds.X
    $maxDx = ($bounds.X + $bounds.Width) - ($origBounds.X + $origBounds.Width)
    $minDy = $bounds.Y - $origBounds.Y
    $maxDy = ($bounds.Y + $bounds.Height) - ($origBounds.Y + $origBounds.Height)
    $cdx = [Math]::Max($minDx, [Math]::Min($maxDx, $dx))
    $cdy = [Math]::Max($minDy, [Math]::Min($maxDy, $dy))
    return @{ Dx = $cdx; Dy = $cdy }
}
 
# Maps a time (seconds) onto an X pixel position within a track of the given
# width, given the video's total duration. Pure math, no controls involved,
# so it can be unit tested on its own.
function Get-MarkerX([double]$time, [double]$duration, [int]$trackWidth) {
    if ($duration -le 0) { return 0 }
    $frac = $time / $duration
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $frac))
    return [int]($frac * $trackWidth)
}

# VFR-safe navigation helpers. The validated FFprobe frame timeline is the
# timing authority; average FPS is never used to decide which frame is active.
function Get-FramePresentationTime([int]$frameIndex) {
    if ($isImageMode) { return 0.0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Times) { return [double]::NaN }
    if ($frameIndex -lt 0 -or $frameIndex -ge $frameTimeline.Times.Length) { return [double]::NaN }
    return [double]$frameTimeline.Times[$frameIndex]
}

function Get-FramePresentationDuration([int]$frameIndex) {
    if ($isImageMode) { return 0.0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Durations) { return [double]::NaN }
    if ($frameIndex -lt 0 -or $frameIndex -ge $frameTimeline.Durations.Length) { return [double]::NaN }
    return [double]$frameTimeline.Durations[$frameIndex]
}

function Get-FrameIndexAtPresentationTime([double]$time) {
    if ($isImageMode) { return 0 }
    if (-not $frameTimeline -or -not $frameTimeline.Ok -or -not $frameTimeline.Times -or $frameTimeline.Times.Length -le 0) { return -1 }
    if ([double]::IsNaN($time) -or [double]::IsInfinity($time)) { return -1 }

    $times = $frameTimeline.Times
    if ($time -le [double]$times[0]) { return 0 }
    $last = $times.Length - 1
    if ($time -ge [double]$times[$last]) { return $last }

    # Return the frame whose presentation interval contains the requested
    # timeline time: the greatest frame start timestamp <= target time.
    $lo = 0
    $hi = $last
    while ($lo -le $hi) {
        $mid = $lo + [int](($hi - $lo) / 2)
        $midTime = [double]$times[$mid]
        if ($midTime -le $time) {
            $lo = $mid + 1
        }
        else {
            $hi = $mid - 1
        }
    }
    return [Math]::Max(0, [Math]::Min($hi, $last))
}

function Format-FFmpegSeconds([double]$seconds) {
    if ([double]::IsNaN($seconds) -or [double]::IsInfinity($seconds) -or $seconds -lt 0.0) {
        throw 'An invalid media timestamp was supplied to FFmpeg.'
    }
    return $seconds.ToString('0.#########', [System.Globalization.CultureInfo]::InvariantCulture)
}
 
# Redaction membership is frame-index authoritative. Do not infer membership
# from seconds or average FPS: on VFR material those are not interchangeable.
# Both ends are inclusive because Begin/End Redaction describe displayed
# frames, and the automatic safety buffer is also defined in whole frames.
function Test-FrameInRange([int]$frameIndex, [int]$rangeStartFrame, [int]$rangeEndFrame) {
    if ($frameIndex -lt 0 -or $rangeStartFrame -lt 0 -or $rangeEndFrame -lt $rangeStartFrame) { return $false }
    return ($frameIndex -ge $rangeStartFrame -and $frameIndex -le $rangeEndFrame)
}
 
# ----------------------------
# State
# ----------------------------
if (Test-IsPackagedHost) {
    try {
        Initialize-EmbeddedMediaTools
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "The packaged FFmpeg/FFprobe payload could not be prepared. TinyRedactionTool will not continue without its approved media tools.",
            "Media-tool bootstrap failed",
            "OK",
            "Error"
        ) | Out-Null
        Remove-EmbeddedMediaTools
        exit
    }
}

$ffmpeg = Find-FFmpeg
if (-not $ffmpeg) { exit }
$ffprobe = Find-FFprobe
if (-not $ffprobe) { exit }

if (-not (Test-D1MediaToolCapabilities $ffmpeg)) {
    [System.Windows.Forms.MessageBox]::Show(
        "This D1 candidate requires the matching custom FFmpeg build with transpose, avgblur and lutyuv enabled. The media tool beside this script is from an older build profile or is otherwise incompatible.",
        "D1 media-tool capability check failed",
        "OK",
        "Error"
    ) | Out-Null
    exit
}

# Belt-and-braces cleanup for older sessions: Load-PreviewFrame no longer
# touches disk at all (it pipes ffmpeg's output straight into memory), but a
# previous run of this app - or an earlier build, before that change - could
# have crashed between writing one of these temp files and deleting it,
# leaving a frame that may contain whatever the user was about to redact
# sitting in %TEMP% indefinitely. Sweep for and remove any such leftovers
# from prior sessions every time the app starts. Failures here (a file still
# locked by another process, permissions, etc.) are silently skipped rather
# than surfaced - this is opportunistic best-effort hygiene, not something
# that should ever block startup.
try {
    # Older preview files used exactly TinyVideoRedactor_<GUID>.png. Do not
    # delete a broad prefix wildcard that could match unrelated files.
    Get-ChildItem -Path $env:TEMP -Filter "TinyVideoRedactor_*.png" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^TinyVideoRedactor_[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\.png$' } |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
} catch {}
 
$videoPath = $null
# S1b source-deletion state. Destructive execution remains strictly opt-in.
$sourceDeletionIdentity = $null
$sourceDeletionCapability = $null
$deleteOriginalRequested = $false
$isImageMode = $false
$videoWidth = 0
$videoHeight = 0
# v2.2.0 B1 rotation-only slice: source display dimensions remain the output
# of the existing trusted -autorotate preflight. UserRotation is a separate
# per-media quarter-turn applied after source orientation and before any
# redaction geometry is created. videoWidth/videoHeight remain the canonical
# working dimensions used by the existing viewport/geometry stack.
$sourceDisplayWidth = 0
$sourceDisplayHeight = 0
$userRotation = 0
$videoDuration = 0.0
$fps = 0.0
$sourceHasAudio = $false
$frameTimeline = $null
$totalFrames = 0
$currentFrame = 0
$previewSeconds = 0.0
$loadedFrame = -1
 
$dragging = $false

# v2.0.0 Slice 2: all *draft* redaction geometry is now canonical displayed-media
# geometry from the moment the user creates it. Rectangle/Oval use RectangleF;
# Freeform uses PointF vertices. Viewport resizing/panel changes therefore never
# mutate the draft itself - Paint simply projects the same media geometry back
# into the current Fit viewport.
$dragStart = New-Object System.Drawing.PointF(0,0)
$selection = New-Object System.Drawing.RectangleF(0,0,0,0)
$previewImage = $null

# v2.0.0 viewport state. Slice 4 exposes Fit/manual zoom while redaction geometry
# remains canonical media-space. 1.0 means one displayed-media pixel equals
# one viewport pixel (100%).
$zoomMode = "Fit"
$zoomFactor = 1.0
$panOffsetX = 0.0
$panOffsetY = 0.0
$maxZoomFactor = 8.0
$minZoomFactor = 0.01
$zoomStepFactor = 1.25
$zoomToolActive = $false
$script:zoomCursor = $null
$script:zoomCursorHandle = [IntPtr]::Zero

# v2.0.0 Slice 5: left-button drag while the Zoom tool is active pans the
# manual-zoom viewport. A small screen-pixel threshold distinguishes a click
# (zoom in) from a drag (pan), so ordinary left-click zoom behaviour remains
# intact. Pan offsets remain VIEW-space state only; redaction geometry stays
# canonical media-space.
$script:zoomPanCandidate = $false
$script:zoomPanning = $false
$script:zoomPanStartPoint = New-Object System.Drawing.PointF(0,0)
$script:zoomPanStartOffsetX = 0.0
$script:zoomPanStartOffsetY = 0.0
$zoomPanDragThreshold = 4.0

# v2.0.0 Slice 6: holding Space while a drawing tool is selected temporarily
# borrows the same left-drag pan gesture without changing toolMode, radio-button
# state, draft geometry, or Begin/End redaction state. Releasing Space returns
# immediately to the existing drawing tool because the tool was never changed.
$script:spacePanActive = $false

# v2.1 Viewport Usability Slice 1: middle-button drag is an always-available
# viewport pan gesture. v2.2.0 B1-r3 adds right-button DRAG as an equally
# available laptop/trackpad-friendly route while preserving simple right-click
# semantics (Zoom tool = zoom out; Freeform = cancel in-progress path).
# Both routes deliberately reuse the proven zoomPanCandidate / zoomPanning
# state so pan maths, clamping and media-space isolation stay unchanged.
$script:middlePanActive = $false
$script:rightPanActive = $false

# Moving a drawn-but-not-yet-committed shape (Rectangle/Oval/closed Polygon)
# by dragging inside it, rather than starting a brand new one. $moveStart,
# $moveOrigSelection and $moveOrigPolygonPoints are all MEDIA-space snapshots,
# so viewport changes cannot alter what is being moved.
$movingShape = $false
$moveStart = New-Object System.Drawing.PointF(0,0)
$moveOrigSelection = $null
$moveOrigPolygonPoints = $null

# ===== v2.1 Resize Integration: draft resizing is now normal behavior =====
# Rectangle/Square, Oval/Circle and closed-Freeform draft editing have passed
# their isolated Slice tests and are enabled by default in this integration
# candidate. The existing internal flags are deliberately retained as TRUE
# constants so the already-tested helper/wiring paths remain mechanically
# unchanged. Export/timing/security architecture remains outside this feature.
$script:resizeSlice3Enabled = $true
$script:resizeSlice2Enabled = $true
$script:resizeSlice1Enabled = $true
$script:resizingShape = $false
$script:resizeHandle = "None"
$script:resizeShapeKind = "None"
$script:resizeOrigSelection = $null
$script:resizeHandleVisualSize = 8.0
$script:resizeHandleHitSize = 14.0
$script:resizeMinMediaSize = 2.0
# r2: distinguish an intentional Rectangle drag from an ordinary click. Without
# this, MouseDown creates the usual 0.01 x 0.01 seed rectangle and MouseUp can
# leave all eight handles collapsed onto one apparent "lone anchor".
$script:resizeDraftDrawStartView = $null
$script:resizeDraftDrawMoved = $false
$script:resizeDraftDrawThreshold = 3.0

# Slice 3: a closed Freeform polygon exposes one constant-screen-size handle
# at every canonical media-space vertex. Vertex editing is kept separate from
# Rectangle/Oval bounding-box resizing so the earlier known-good paths remain
# mechanically untouched.
$script:editingPolygonVertex = $false
$script:polygonVertexIndex = -1
# ===== End Resize Slice 1/2/3 state =====

# Active canvas tool. Rectangle/Oval use the media-space $selection; Polygon is
# the existing closed Freeform path; Line/Polyline/Text are standalone drawing
# annotations that never enter the security-redaction collection/filter graph.
$toolMode = "Rectangle"
$polygonActive = $false
$polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
$polygonMousePos = $null

$pendingRedaction = $null
$script:pendingAnnotation = $null
$redactions = New-Object System.Collections.ArrayList
# D1b: standalone drawing/annotation objects are deliberately separate from
# security redactions. An annotation-only shape can never enter the redaction
# filter graph merely because it happens to share canonical geometry helpers.
$annotations = New-Object System.Collections.ArrayList
# D1b-r2: security redactions and standalone annotations remain in separate
# collections, but every committed still-image object receives one monotonic
# commit order so normal front-to-back stacking can be reconstructed safely.
$script:objectCommitCounter = 0

function Get-NextObjectCommitOrder {
    $script:objectCommitCounter = [int]$script:objectCommitCounter + 1
    return [int]$script:objectCommitCounter
}

# Blur/Pixelate strength, 1 (lightest) - 10 (strongest). Whatever this is set
# to at the moment a redaction is created gets baked into that redaction's own
# Strength field, so different redactions in the same file can use different
# strengths, and adjusting the slider later never retroactively changes ones
# already added.
$redactionStrength = 5

# C1 Enhanced Blur/Pixelate is explicitly opt-in. Standard remains the default
# and the flag is baked into each committed redaction so changing the checkbox
# later never retroactively changes existing redactions.
$script:redactionEnhanced = $false

# Coloured Box fill color, baked into each new redaction's own Color field
# the same way $redactionStrength is baked into Strength above - changing
# this later never retroactively changes redactions already added, unless
# the user explicitly re-picks a color while that redaction is selected in
# the Redactions list (see Get-ColorEditTarget / Set-ActiveRedactionColor).
$redactionColor = [System.Drawing.Color]::Black

# v2.3.0 D1b: Fill remains the security/effect switch; Outline is a separate
# annotation presentation switch. All drawing widths are canonical media pixels.
# The user-facing name is Outline; renderer fields use normal graphics terminology.
$script:fillEnabled = $true
$script:outlineEnabled = $false
$script:outlineColor = [System.Drawing.Color]::Red
$script:outlineWidth = 3
$script:outlineDashStyle = "Solid"
$script:outlineRectangleCornerStyle = "Square"
$script:outlinePolygonJoinStyle = "Miter"
$script:drawPolylineJoinStyle = "Miter"
$script:drawEndpointStyle = "None"

# D2 standalone Draw-tool draft state. Geometry is canonical media-space and
# never enters the security-redaction collection/filter graph.
$script:lineDrawing = $false
$script:lineStart = $null
$script:lineEnd = $null
$script:polylineActive = $false
$script:polylinePoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
$script:polylineMousePos = $null
$script:polylineGestureAxis = "None"
$script:polylineGestureLastRaw = $null
$script:polylineGestureThresholdView = 8.0

# D3 Text Box draft/style state. Text geometry is canonical media-space and
# font size is stored in media pixels so zoom changes only the preview scale.
$script:textDrawing = $false
$script:textDragStart = $null
$script:textDraftActive = $false
$script:textDraftRect = New-Object System.Drawing.RectangleF(0,0,0,0)
# D5c-r2 floating Text editor is viewport-only UI state. It never participates
# in annotation geometry, timing or export; $txtAnnotationText remains the
# canonical UI-bound text value used by the already-tested annotation model.
$script:floatingTextEditorVisible = $false
$script:floatingTextEditorMode = "None"
$script:floatingTextEditorTargetIndex = -1
$script:floatingTextEditorOriginalText = ""
$script:syncingFloatingTextEditor = $false

# D4a: standalone drawing objects use the same draw -> adjust -> commit rhythm
# as the established redaction drafts. Geometry remains canonical media-space.
$script:lineDraftActive = $false
$script:polylineDraftActive = $false
$script:annotationDraftMoving = $false
$script:annotationDraftMoveKind = "None"
$script:annotationDraftMoveStart = $null
$script:annotationDraftOrigTextRect = $null
$script:annotationDraftOrigLineStart = $null
$script:annotationDraftOrigLineEnd = $null
$script:annotationDraftOrigPolylinePoints = $null

# D4a-r2: Text Box keeps its own resize gesture state. This deliberately does
# not reuse the security-redaction resize flags, so annotation editing cannot
# accidentally alter redaction geometry/state.
$script:textDraftResizing = $false
$script:textDraftResizeHandle = "None"
$script:textDraftResizeOrigRect = $null

# D4b committed-annotation editing state. Selection originates in the
# Annotations list; geometry edits never touch $redactions or security state.
$script:selectedAnnotationIndex = -1
$script:annotationCommittedMoving = $false
$script:annotationCommittedMoveStart = $null
$script:annotationCommittedOrig = $null
$script:annotationCommittedTextResizing = $false
$script:annotationCommittedTextResizeHandle = "None"
$script:annotationCommittedTextResizeOrigRect = $null

# D4d committed-annotation geometry editing. These remain deliberately
# separate from redaction-editing state so drawing geometry can never mutate
# the security-redaction collection by accident.
$script:annotationCommittedResizing = $false
$script:annotationCommittedResizeHandle = "None"
$script:annotationCommittedResizeOrigRect = $null
$script:annotationCommittedVertexEditing = $false
$script:annotationCommittedVertexIndex = -1
# D4e: prevents programmatic control synchronisation from being interpreted as
# a user appearance edit when a committed annotation is selected.
$script:syncingAnnotationAppearance = $false

# D4c committed-redaction editing state. Selection originates in the Redactions
# list and is enabled only for still images. Geometry changes update the existing
# security-redaction object in place; mode, timing, strength, colour, outline
# decoration and commit/layer order are intentionally left untouched.
$script:selectedRedactionIndex = -1
$script:redactionCommittedMoving = $false
$script:redactionCommittedMoveStart = $null
$script:redactionCommittedOrig = $null
$script:redactionCommittedResizing = $false
$script:redactionCommittedResizeHandle = "None"
$script:redactionCommittedResizeOrigRect = $null
$script:redactionCommittedPolygonEditing = $false
$script:redactionCommittedPolygonVertexIndex = -1

$script:textFontFamily = "Segoe UI"
$script:textFontSizePx = 24
$script:textBold = $false
$script:textItalic = $false
$script:textAlignment = "Left"
$script:textColor = [System.Drawing.Color]::Red

function Test-IsStandaloneDrawTool {
    return [bool]($script:toolMode -eq "Line" -or $script:toolMode -eq "Polyline" -or $script:toolMode -eq "Text")
}

# Whether the eyedropper is currently armed, waiting for the user's next
# click on the preview to sample a color from it.
$eyedropperActive = $false

# Shared session-level suppression for the Blur/Pixelate obscuration warning.
# One checkbox controls both visual-obscuration modes.
$script:suppressVisualObscurationWarning = $false
$script:visualObscurationWarningOpen = $false

# Audio is not inspected/redacted. The warning can be suppressed for the
# current session only, matching the visual-obscuration/network warnings.
$script:suppressAudioWarning = $false
$script:audioWarningOpen = $false

# Network-backed media is permitted after an explicit warning. Keep source and
# destination suppression separate because opening unredacted source media and
# exporting a redacted file have materially different disclosure risks.
$script:suppressNetworkSourceWarning = $false
$script:suppressNetworkDestinationWarning = $false
$script:networkLocationWarningOpen = $false
 
$isPlaying = $false
$seekDragging = $false

$BUFFER_FRAMES = 2
 
# ----------------------------
# Form / polished UI
# ----------------------------

# ---------- visual helpers ----------
function New-UIFont([float]$size, [System.Drawing.FontStyle]$style = [System.Drawing.FontStyle]::Regular) {
    # Segoe UI Variable is preferred on Windows 11; fall back cleanly on older systems.
    try {
        return New-Object System.Drawing.Font("Segoe UI Variable Text", $size, $style)
    } catch {
        return New-Object System.Drawing.Font("Segoe UI", $size, $style)
    }
}


# ---------- rounded-button rendering ----------
# WinForms has no border-radius property, so a soft rounded look has to be
# painted by hand. Region-clipping a button to a rounded rect is the simple
# way to do this, but it clips with hard (non-antialiased) pixel edges - it
# looks noticeably jagged next to the smooth curves in the mockup. Instead,
# each rounded control gets its own Paint handler that:
#   1. repaints its FULL bounds in the parent's background color first, which
#      erases whatever the native control chrome (square corners included)
#      already drew before this Paint handler ran;
#   2. fills+strokes a rounded-rect GraphicsPath in the control's own colors
#      with anti-aliasing on;
#   3. redraws the control's own Text centered on top.
# This only works cleanly when the control sits on a solid-color parent
# (true everywhere in this app - no gradients/images behind any button), and
# the parent color is read from $sender.Parent.BackColor at *paint* time so
# it keeps working correctly after a light/dark theme switch.
function Get-RoundedRectPath([System.Drawing.Rectangle]$rect, [int]$radius) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = [Math]::Max(2, $radius * 2)
    if ($d -gt $rect.Width) { $d = $rect.Width }
    if ($d -gt $rect.Height) { $d = $rect.Height }
    $path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
    $path.AddArc(($rect.Right - $d), $rect.Y, $d, $d, 270, 90)
    $path.AddArc(($rect.Right - $d), ($rect.Bottom - $d), $d, $d, 0, 90)
    $path.AddArc($rect.X, ($rect.Bottom - $d), $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

# $radius is captured per-control via GetNewClosure() - without it every
# button's Paint handler would look up a single shared $radius variable
# dynamically when the event fires (the same dynamic-scoping trap that bit
# earlier versions of this app's event handlers), instead of each button
# keeping the radius it was actually given.
function Enable-RoundedPaint($control, [int]$radius = 10) {
    # The Paint handler below draws a rounded shape on top of the control,
    # but that alone doesn't stop Windows from drawing its OWN square-cornered
    # chrome for this control outside that shape - most visibly the dotted
    # focus rectangle / checked-state highlight a Button or a RadioButton
    # with Appearance="Button" draws at its own full rectangular bounds,
    # which happens independently of (and can redraw after) the custom Paint
    # handler here. Setting Control.Region clips literally everything about
    # how this control renders - our own painting AND every bit of native
    # chrome - to the rounded shape, so nothing square can ever show past its
    # corners, regardless of what triggered it.
    $applyRoundedRegion = {
        param($ctrl, $rad)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { return }
        $useRadius = [Math]::Min($rad, [int]([Math]::Min($ctrl.Width, $ctrl.Height) / 2))
        $regionPath = Get-RoundedRectPath (New-Object System.Drawing.Rectangle(0, 0, $ctrl.Width, $ctrl.Height)) $useRadius
        $oldRegion = $ctrl.Region
        $ctrl.Region = New-Object System.Drawing.Region($regionPath)
        $regionPath.Dispose()
        if ($oldRegion) { $oldRegion.Dispose() }
    }.GetNewClosure()
    & $applyRoundedRegion $control $radius
    # Buttons here are all fixed-size, but reapply on Resize too in case that
    # ever changes - a stale Region from before a resize would bring the same
    # hard-corner problem right back on whatever newly-added edge.
    $control.Add_Resize({ & $applyRoundedRegion $control $radius }.GetNewClosure())

    $control.Add_Paint({
        param($sender,$e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $parentColor = if ($sender.Parent) { $sender.Parent.BackColor } else { $sender.BackColor }
        $eraseBrush = New-Object System.Drawing.SolidBrush($parentColor)
        $e.Graphics.FillRectangle($eraseBrush, 0, 0, $sender.Width, $sender.Height)
        $eraseBrush.Dispose()

        $useRadius = [Math]::Min($radius, [int]([Math]::Min($sender.Width, $sender.Height) / 2))
        $inner = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = Get-RoundedRectPath $inner $useRadius

        $fillBrush = New-Object System.Drawing.SolidBrush($sender.BackColor)
        $e.Graphics.FillPath($fillBrush, $path)
        $fillBrush.Dispose()

        $borderColor = $sender.FlatAppearance.BorderColor
        if ($borderColor -ne [System.Drawing.Color]::Empty) {
            $pen = New-Object System.Drawing.Pen($borderColor, 1.3)
            $e.Graphics.DrawPath($pen, $path)
            $pen.Dispose()
        }

        # Icon toolbar/playback buttons carry an .Image instead of .Text (set
        # by New-ToolbarIconButton / New-IconButton) - drawn inset a few px so
        # the rounded background still peeks through as a "selected" halo.
        if ($sender.Image) {
            $margin = 4
            $availW = [Math]::Max(1, $sender.Width - ($margin * 2))
            $availH = [Math]::Max(1, $sender.Height - ($margin * 2))
            $side = [Math]::Min($availW, $availH)
            $imgX = [int](($sender.Width - $side) / 2)
            $imgY = [int](($sender.Height - $side) / 2)
            $imgRect = New-Object System.Drawing.Rectangle($imgX, $imgY, $side, $side)
            $e.Graphics.DrawImage($sender.Image, $imgRect)
        }
        elseif ($sender.Text) {
            $textBrush = New-Object System.Drawing.SolidBrush($sender.ForeColor)
            $fmt = New-Object System.Drawing.StringFormat
            $fmt.Alignment = [System.Drawing.StringAlignment]::Center
            $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
            $textRect = New-Object System.Drawing.RectangleF(0, 0, $sender.Width, $sender.Height)
            $e.Graphics.DrawString($sender.Text, $sender.Font, $textBrush, $textRect, $fmt)
            $textBrush.Dispose()
            $fmt.Dispose()
        }

        $path.Dispose()
    }.GetNewClosure())
}

# Rounded "input field" look for the read-only X/Y/W/H value chips in the
# Redaction Area section. Border/fill colors are read live (via $script:
# variables Apply-Theme keeps current) rather than closure-captured, the
# same pattern the seek bar's Paint handler uses, so the chips keep
# tracking light/dark theme switches correctly.
function Enable-RoundedFieldPaint($panel) {
    $panel.Add_Paint({
        param($sender,$e)
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $parentColor = if ($sender.Parent) { $sender.Parent.BackColor } else { $sender.BackColor }
        $eraseBrush = New-Object System.Drawing.SolidBrush($parentColor)
        $e.Graphics.FillRectangle($eraseBrush, 0, 0, $sender.Width, $sender.Height)
        $eraseBrush.Dispose()

        $inner = New-Object System.Drawing.Rectangle(0, 0, ($sender.Width - 1), ($sender.Height - 1))
        $path = Get-RoundedRectPath $inner 6

        $fillColor = if ($script:fieldFillColor) { $script:fieldFillColor } else { $sender.BackColor }
        $fillBrush = New-Object System.Drawing.SolidBrush($fillColor)
        $e.Graphics.FillPath($fillBrush, $path)
        $fillBrush.Dispose()

        $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
        $pen = New-Object System.Drawing.Pen($borderColor, 1)
        $e.Graphics.DrawPath($pen, $path)
        $pen.Dispose()

        $path.Dispose()
    })
}

function Style-FlatButton($button, [bool]$primary = $false, [int]$radius = 10) {
    $button.FlatStyle = "Flat"
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Font = New-UIFont 9.5 ([System.Drawing.FontStyle]::Regular)
    $button.UseVisualStyleBackColor = $false
    if ($primary) { $button.Tag = "primary" } else { $button.Tag = "button" }
    Enable-RoundedPaint $button $radius
}

# S1c: unlike a generic primary button, Export is only a primary action when
# there is committed content that can actually be written. A disabled blue
# button looked actionable even though WinForms correctly rejected clicks.
function Update-ExportButtonAppearance {
    if (-not $btnExport) { return }
    if ($btnExport.Enabled) {
        $btnExport.BackColor = $script:cAccentCurrent
        $btnExport.ForeColor = [System.Drawing.Color]::White
        $btnExport.FlatAppearance.BorderColor = $script:cAccentCurrent
        $btnExport.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    else {
        $btnExport.BackColor = $script:cButtonCurrent
        $btnExport.ForeColor = $script:cMutedCurrent
        $btnExport.FlatAppearance.BorderColor = $script:cBorderCurrent
        $btnExport.Cursor = [System.Windows.Forms.Cursors]::Default
    }
    $btnExport.Invalidate()
}

function Style-ChoiceButton($control) {
    $control.Appearance = "Button"
    $control.FlatStyle = "Flat"
    $control.FlatAppearance.BorderSize = 1
    $control.TextAlign = "MiddleCenter"
    $control.Cursor = [System.Windows.Forms.Cursors]::Hand
    $control.Font = New-UIFont 9.0
    $control.Tag = "choice"
    Enable-RoundedPaint $control 10
}

function Add-SectionTitle($parent, [string]$text, [int]$x, [int]$y, [int]$w = 300) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object System.Drawing.Point($x,$y)
    $l.Size = New-Object System.Drawing.Size($w,25)
    $l.Font = New-UIFont 11 ([System.Drawing.FontStyle]::Bold)
    $l.Tag = "heading"
    $parent.Controls.Add($l)
    return $l
}

function Add-Rule($parent, [int]$x, [int]$y, [int]$w) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($x,$y)
    $p.Size = New-Object System.Drawing.Size($w,1)
    $p.Tag = "rule"
    $parent.Controls.Add($p)
    return $p
}

function New-MiniField($parent, [string]$caption, [int]$x, [int]$width, [int]$height = 34) {
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, 0)
    $panel.Size = New-Object System.Drawing.Size($width, $height)
    $panel.Tag = "input"
    Enable-RoundedFieldPaint $panel
    $parent.Controls.Add($panel)

    $capLbl = New-Object System.Windows.Forms.Label
    $capLbl.Text = $caption
    $capLbl.Location = New-Object System.Drawing.Point(7,3)
    $capLbl.Size = New-Object System.Drawing.Size(($width-14),12)
    $capLbl.Font = New-UIFont 6.5
    $capLbl.Tag = "muted"
    $capLbl.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($capLbl)

    $valLbl = New-Object System.Windows.Forms.Label
    $valLbl.Text = "--"
    $valLbl.Location = New-Object System.Drawing.Point(7,15)
    $valLbl.Size = New-Object System.Drawing.Size(($width-14),18)
    $valLbl.Font = New-UIFont 9.5 ([System.Drawing.FontStyle]::Bold)
    $valLbl.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($valLbl)

    return $valLbl
}

# ----------------------------------------------------------------------
# TinyRedactionTool v2.0.0 release UI
# ----------------------------------------------------------------------
# Shared compact-layout constants. "UiGap" is the small edge/gutter distance
# used consistently around the toolbar, panel toggle and header action icons.
$script:UiGap = 4
$script:UiIconButtonSize = 34
$script:ToolbarWidth = $script:UiIconButtonSize + (2 * $script:UiGap) # 42 = 4 + 34 + 4
$script:InspectorCollapsedWidth = $script:UiIconButtonSize + (2 * $script:UiGap) # 42
$script:InspectorExpandedWidth = 350
$script:CompactButtonWidth = 130
$script:OpenButtonWidth = 150
$script:ExportButtonWidth = 176
$script:CompactButtonHeight = 30
$script:HeaderHeight = 64

# v2.0.0 preserves the approved compact v1.4.0 UI while adding viewport-only
# zoom/pan. Rectangle, Oval and Freeform draft/committed geometry remains in
# canonical displayed-media coordinates; zoom/pan/window/panel state remains
# view-only state and is not part of export geometry. Existing CFR/VFR timing,
# export/security validation and FFmpeg/FFprobe trust behaviour are preserved.
# ----------------------------------------------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "TinyRedactionTool"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(1540,980)
$form.MinimumSize = New-Object System.Drawing.Size(1320,820)
# D5c-r2: open maximized by default while retaining the normal Windows title bar
# and Restore/Minimize/Close behaviour. This is not borderless/kiosk fullscreen.
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.KeyPreview = $true
$form.Font = New-UIFont 9.0
$form.AutoScaleMode = "Dpi"
$form.BackColor = [System.Drawing.Color]::FromArgb(223,238,245)

# Supplied TRT icon: identical embedded asset for script and compiled host.
$script:TRTIconBase64='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'
$iconStream=[IO.MemoryStream]::new([Convert]::FromBase64String($script:TRTIconBase64))
try{
    $assetIcon=[Drawing.Icon]::new($iconStream)
    try{$script:mainFormIcon=[Drawing.Icon]$assetIcon.Clone()}finally{$assetIcon.Dispose()}
}finally{$iconStream.Dispose()}
$form.Icon=$script:mainFormIcon;$form.ShowIcon=$true
# Shared tooltip component for the icon-only toolbar/playback buttons, which
# have no visible text of their own to explain what they do.
$script:appToolTip = New-Object System.Windows.Forms.ToolTip
$script:appToolTip.AutoPopDelay = 5000
$script:appToolTip.InitialDelay = 400
$script:appToolTip.ReshowDelay = 200

# Header
$top = New-Object System.Windows.Forms.Panel
$top.Dock = "None"
$top.Location = New-Object System.Drawing.Point(0,0)
$top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,$script:HeaderHeight)
$top.Anchor = "Top,Left,Right"
$top.Padding = New-Object System.Windows.Forms.Padding($script:UiGap,0,$script:UiGap,0)
$top.Tag = "header"
$form.Controls.Add($top)

# Embedded header icon: a small original "video frame + play triangle +
# redaction bar" glyph, stored as base64 PNG so the whole app stays a
# single script file with no extra image asset to ship alongside it.
# Decoded once at startup into an Image and shown in a PictureBox, in
# place of the plain Unicode glyph the tile used before.
$script:AppIconBase64 = "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"

function Get-AppIconImage {
    $bytes = [Convert]::FromBase64String($script:AppIconBase64)
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    return [System.Drawing.Image]::FromStream($ms)
}

# Embedded toolbar/playback icon glyphs, stored as base64 PNGs for the
# same single-file-script reason as $script:AppIconBase64 above. v1.4's
# Rectangle/Oval/Freeform/Zoom/Copy and Moon/Sun glyphs are normalized
# transparent RGBA line-art assets with a consistent apparent size/stroke.
# The theme engine tints monochrome glyphs at runtime, so one canonical asset
# works in both Day and Dark modes without maintaining duplicate PNG sets.
$script:IconBase64 = @{
    "play" = "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"
    "pause" = "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"
    "next_frame" = "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"
    "previous_frame" = "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"
    "rotate_ccw" = "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"
    "rotate_cw" = "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"
    "freeform" = "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"
    "oval" = "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"
    "rectangle" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABw0lEQVR42u3bTUoDMQBA4Zfp1J2CgrcQ0QO4cyF4S2/g3ou4EUEENy78QQXbxsVksIgg7aTtmHkfFFdlbF4mk4oBSZIkSZIkSZIkSZKkEoUNv78k8b/FczJnGMTdVD4MeNYH4AmYrStAlV4XwFm6cDXwALfAOfCw6uWoDbYHfKQL+Wpep2lsRosMaN2h/CuwNfAliLQCBGCyzJvrDheu5gY+bHI3sOGHbfgxFmsL4O4og9wBIvA8d1vGwmZ+BLZzjludceDb7dhx+lni0hOBS+AEmC76wF3XHfAIvBS8anz2eQkCGKfZUtoSVM0trb0OEOcGvqQAcRWfZ6jfYHt1W8kABpABDCADGEAGMIAMYAAZwAAygAFkAAPIAAaQAQwgAxhABjCADGAAZVKvKGp7ZCcWOFl7/d/RkeZswKzAydp+pkkfA7SzYge4yv1L9sxRzuU79x1Q0xzfGYLQxwDQnJ0qfeMScs7YLuv9b0YMz9KnZ+oOt99WejAN/aT8lOZc3HhdAQLwDtwAh+7kqYA34O6PlSHbg6Td3+8DBwMf/JgC3APXBX73KX9XFDpe0D9lfN8JM4dBkiRJkiRJkiRJkiSp9QWexYaAl1n83wAAAABJRU5ErkJggg=="
    "pixelate" = "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"
    "blur" = "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"
    "black" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABLklEQVR4nO3bQUrDQBiG4b+tB6g38eDeo1s34jFcdWfURSYUBBExMx8jzwOh7Sb/pG/SrqYKAAAAAAAAAACAXR0GzjoOnreXj6p6Ty+CTkbckYda76KHqrpv72d4ErZ1vlbVU92uYzqn9nqp9QJmOy5frmNXdz1O+o1rVS3t6HIxO9vWee05ZGSAY92++BkCVK3rPPYc0PXk/EyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgTIEyAMAHCBAgbuUFjqaq39jrDXqttnUvPISMDnNu8kTP/YlvnecSQnra7/bGqnmvdczvDT9+2zpf2eYanlt8auV/3NHjeXrr/DwAAAAAAAAAAAADwP3wC3V5LI/al5bMAAAAASUVORK5CYII="
    "eyedropper" = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAACXBIWXMAAAsTAAALEwEAmpwYAAACsElEQVR4nO2bTW4TQRCFSwkcAU+/V2sCAlZYSHCKIJEQJH4kYM0ZAtwDgVhE/FwAwQ2SHZwhBCQ2WSQs4mBUYUbuGHtsx/a4e3qeVBtrPOqvXne5etwj0qhRozqo3W6ft5CEtETyLoCPJH+Q7JL8Q3IPwAdVXbdrpI4C0Cb5LYceGgC+ArgudZJz7g6Aw1HwXhwAWJU6SFXXSR5NAF/MhN/OuRuSIjy95RBtTSC5MQ18EXlhTMt5np4F7yVF59mLPUnRefbiOIpmSecDf5IAETkniU37rlcDvkuiznfzBLyTEJRl2dUqnS9CVddk0QLwnGTHOfegKueDaYTwD74Y1EkSKoI/tA3UQuGzLLs2APRo3vB2f9tASQhS1bUKgP3oALgvIUmrS0J48KYq1nwDjwDhOfh3ftZF0O61IZE43zGnZlgTwnReS+C9a6ZNQrzwM0hC/PBTJKE+8GdIQv3gJ0hCfeHHSEL94Uc0Tae20qnBd4NLAod3ePdmfL//PrMttoTovDujOxN2jJuzJwoU3rumSMJmKtN+Y5wHqrV3PhgBuL0o5xcukisk95N03gTgS/9gk3De5Jy7kp/A8gf8WFKANwF42Tfgz5IKvInkjj9o59xDSQXeOXfB/lf3Bn3carWyWhc8X6r6qG/g25IKvInklj94qwdS92lf5p6q3pQUnNcBT2QA/BKR5VHfJfkkaucBXB5wHrcUIMuyltWLAQ1TXPAmkm/HAFgmeSvvEXb6finihTeR/FnW9RmQLYeSR1ZF7Md4Unupr+3t+Ot+zMNM9v1PtoGSGMXeGxhF8XtmBwwBPC2BtyWwDeCF1RCJWQDeDAEctL63rDW2Iih1EclL9qbFiGkeX3GbRABWS5JwEMzJq3mK5AqA1wB281qwC+CVql5c9NgaNWrUqJFMr7/GqKf+LELoegAAAABJRU5ErkJggg=="
    "info" = "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"
    "zoom" = "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"
    "panel_expand" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAELElEQVR42u2dvW4TQRSFv3WchBSEQIAUIBAdNaLkHehoeIDACyConFSIN+AFoKCCd6AhiYCKFkGLFIkfifzYXgrfUQbLa+/as//nSKMom3g9c87cOzN37u6AIAiCIAiCIAiCUCiinP+/rYhDi9QV+flwFqX4u6/mut1YSEYf+DWFw9QCuA+eAx4BD4BbwKo4nopj4CvwBngJHM0SYRI69vM6sGcfVsle9oxDn9OZFhBZWQXeA3eAE40DmQfhPrACfATumWXE45YwSZUlYAhse+Sv2P9GBZQmDMAd4+zEONw2TpfS3iAC9oGBKSl3Ml/pG4d7SR2smzDwrgM3TMm4YNP9ab0lqqHb6QAXvLo7r3ETOG+zo/8G5KQpZRdYLrjykZF/FzgsQfxF3c4QuAQcABtjdV9O4rpbwV70Y2weXScMsnaaKi6qlj1/WScLiOfxGlUUwJ+qxTXq/fE89e1oyl4uJIAEkACCBJAAggQorL0dCVBeW4dWOhKg2FWqC7G/sOJCw6UH/LotIb8P9IAndv0vsGPtzxy/ybvCMIrqHVrFhuQfN3ffcWjfTaDe6e6xY/c/tRLbNdcJo5x4y9yuJgnQYRQce+6R70gJLcLcAnQb7HpcRsd9uxZ7jffdElVyR02zAIBNRhvjsdfz47HfF7UEuaAZIlwFPk0QIZQ7kgBT4DIRriRYQggRJMCCIizqjiRARhFCuyMJULI7kgAlu6NGCbDJWXpfXumPbv2zBXzmLIttXktolADrBa99LnKWAT6YU4TGrIQjcw1L5J8ZF1v7T4CHwDvgtheudpaS64q5WyHiYZRXeUBxuaEun/OYUTr+pATapLBFv4nh6IhRXmWVQ9pOBLfB07j9gLgCljjpuu+O1oBnIUTQpnzJqKIFRBW1yoHxtQPsNtUFFf2AxvggvDGD/F0rjRuEy3hAw5+GbgFvbRYWe655nHx/Gpqr+bdtIbY/YyHWy2shplCEQhGlBeNC7pJJgBzI76UkXwKU2PMlQAXIlwAluR0JkCHUorQUykvMupwz+RIgoR2RLeq+2L1PArudIAI0NRrqQhtHjHa6XMPjKbGdSqSpNzU9vYfS00ubBXXHRAjldoII0IY3IPruZs0I2LXpaelupw0CuEBbB3jqjX2DKlSuTe8A9Z+OHFalUm17CeuwahXSprwEkACCBJAAggRoJ6qaGVe390hHk8IMdRXAj9nXabXt6l5rAYp8QCN0vd2ri6MQAvTnUTOACRf9gEZoK3Av73Zt8i3jNI0AbiPjN/Cd0XZeTMr33gcSYqNBY6zrSN+AP0x4HXPSAQ4x8IpyooZ1PzPAx8A4fJ3UkXWESX6dKNURJrPWB9eAD+gkjEIP8WFsEFkFHqNjrNIi0zFWOsgtPDId5JZ2ZiL/nxNnOswz35WxIAiCIAiCIAiCUDX8A158x9XvmkSZAAAAAElFTkSuQmCC"
    "panel_collapse" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAEe0lEQVR42u2dzY7cRBSFP7udkETKJCRhNcoE3oAFO8Q2W1YgeILME4zY9cwmUp6ANyCRYM8TsJos2EEQJNJskcI/hIx7zMK3RMVpd9s9XXbZPkcqTU+31V0+p+6tW7eqXCAIgiAIgiAIgiB0iiTw9VNFsW2RMpEfhrOkwee+mjv2xUI9cuD3FRw2FiAFzoDLwD7wEfAO8IY4Xol/gWfAV8DnwD8el42R2t/bwGNTUKV9eWwc+pyutYDEyiXgG+Bd4KX6gdadcA5cBL4F3gdeeMK81tJ9zMxc9j3yL9q1YxAg6aCkxtmpcXjPOJ21qeAxsDAl5U42K7lxeOzx+gqymqhnB9gzJYuKaf1maiYDdAspcK3DujuvsQdctejolaioLqTMgAuVyidG/nvA8yXixO52zoAb1jFe9+6pC1yo4zrboBX9XIlzh4RFbI0m21DNZN0AI0ILKCpWPVgB/FCqGFDrL2Ksb6qQXQJIAEECSABBAkiASOqTSoD+6nJmJZUA3Y5SXQr8gRWXuh39/EMWCfk5MAcO7P2/gSOrX3T5m9CEQJk1fG437txCYe/dqFx7nt9yDeDQvv/USmHvsSUrqLuv0PMBrXnrSoA68t1vORHu8/9s3CgFSCNwO3N77Xy+X8FPgCt0m7sfdSfsk39oJa90uLlZxxPgA+BXhpX6jrYPWOV2Cu//AvieNcs51Ae0E8Anf15Dfr6E/FnghjUJAdq0/CcByJ+0AE3Izz3y9wKQP1kB2ridkORPUoA2bueHwORHLUAW6Gb9UHO+JNRc2G//BNwFTry0QxJQgOjHEue1gCZux+V2vgN2O76/nTFbQJOW70a0J8CnlAu83rLrksANy62Mi8oKtinAOvJ99d8Evqbc/LHoiBR/bWg07mhbAqQrcjvLcNXK5JFtifyCciLlwMvlNGmRffZzo0vGFWrP/ViAm8P9jHJD2mEDFzSIkHBIfcCZfdeRN/haJcIfwF89dsLJ2ATwB1erRHBu6hfgQxuIXeo4DO1jg4YGYrEOxELkgtok4X4E3vasMeSuxQS4OcVk3LxBMu7OVJNxoQRoawmhM6KakKHfOQFNSTZ0R6FE0KQ8mpTvfWVcG0vQshTCLE1sK8LulkSQABuK8NRGrQnnX4sapQB9LE8v1qQtfDyiXKruUgmjR1/L031L0PL0jgSoE6Gw1356YrQC9L1DpuqOLlsFj8wdjX53TAyPoHRjADep46KexRR8fkzPAPV3R06iw41NgEkRzxZHmYIEkACCBJAAggSYRhjqrzYYCqLdoLGJAC5ZNrRHVrq6D1qAhHJDxYzhPrp4EBs08kprcZW+Rrm0b+gP7+7aHZ3WWV+2pJIJ5eLZE+CWvTfzKn1dXWdjuIZ6AvzJkmde1B3gUAAPWZ6VHPoz/bvEwjj8otKQX3Mty6IcHWFyPnfX6AiTdeOD25SnP+g0jM3KMRsc4uN/Vpgl7AMfo2OsmsAdY/Ul5TFWL1hxjJUOcts+Wh3k1jSGlv8PxJkO8ww78hYEQRAEQRAEQRBiw3+mUHW2m+Ug7wAAAABJRU5ErkJggg=="
    "copy" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAADp0lEQVR42u2cwWoUMRzGf5lORbGtij5Iq3jswYsHH8SjF8GDvoNH7z6CIIIg3kREUQ+e9AlELbXipdvZeNiEHcad3SmdSTLZ7wdhaRs6k3zJ/598mxkQQgghhBBCCCGEEEIIIQbHrPn1V2FzFn9jJPdoch6BF4DzbqSZxEa9BX7nGAKMKw+Bu8DFBEORBSrgOfAA+JVLSPJh55FrzBjKS6BwZfQJ3wDbwHfgxJVpwuXYiXBzqLxVRpjam8A515hm7LcJDJLmjLXAzlAXLCM00rrRNZZlqXH5IBsB2jraAkdOHBN4Nvjrbbf0iclNgGbHG7fk2wux9FsiwDNg3434IPuUMqGpbt1y70/Ee5iEvmBKAuAStIkQgopa6FtrAWxjJxrjutkIYFp+Nh32CiZQp0dnKAE2FizdbIc4Owk4Gjdc2LE5ClDRbrRdahnhBrg68KwMarTFEGCZ0eYTa1HbWTaF+RxgH7DIaCuWbA5Hw5iNNj8QX7vfn9SEssCtRht7XX71NfKnbid5z914taThq1YjIcoEuA3ccB0++hAkoy2BHHBWo81EEKXKSYC2TqwbbT4JmyV1+kzC0Yy2FHbCdaPtOnAIXAY+uk9b64ShzLhoRltKVoQ32o5qybmtzlBm3IQECekFeaNts0OdPkNQNKMtNQFOswztc9UUzWgLuQ8QEkACCAkgAYQEkABCAkgAIQEkgJAAEkCsoExwQBT0b0dDux1ddKizFgJYZl/G9H0+x/+/tpMPfzvUyVoAP+p2gFcDdsJuy4x4wuyr0kV11moGlMy+sw0luP/cW1InWwHa4vuQR0SKlo6tH9BdVGfQh8hjPaTnT083p3qM0wrFivxRDjkwigij/pDZEREvQqhnfu2STl5UTlznfwM+MD9+mSR+il4BDpifkPMNP3B/83WvAS9I//DuF+YPaRe5hCAD/ATuuMZtBQgxU+CxW+X403k+tt8HPvH/QyUV8JbZeaLBRn+sHOBnzPuA1/3RCIX+Pt4A7zoImOUqKETS9R3YdiBsy93HoseqpkPH/dj7gCqQ2KuScBXwfqKtgoQESI8ysNh9O52nGWRrfTh3KKezC9GczhQECOV0dmE3xbBbBrzOfiJtNrkLEMPp7JoLgjqdMQRIzelclRvKBAZGb/i3zD5l/iB0lWjxLwX5yvx1CmbsAvhGyOlMJCGFcDrPYoHUnc6sXtI9pulcpNBZQ+aElJmS+evphRBCCCGEEEIIIYQQQgghBPAPlM4RjvwKObMAAAAASUVORK5CYII="
    "moon" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAFbElEQVR42u2cTYgcRRTHf90TF7Nh3TVKFDQedEk0JuCuJHqJGEHQiyBZvKkkEDyIePLiRUkuikLuGxDiweDRqx8gCuJBc1ARBRFFJVmM0QRBk53u9lCvmErZO9sf1TPTPe8PzXzQM939f/U+61WBQqFQKBQKhUKhUCgUCoWiICI5Wv0AbUHsEJ4Bqby2Gr0WDJCevKY5xC8A2+S7RDUg7H3FHqm3AQeA+4H9Qv4uYA04CFyQ81qvFZOklTPAE8B7wGUh1z8OOiZKEWDUW+KPAl97ZPeBdeCKfH6xJaa0VaP+cY/4vhyp8zkDPpHztyh9YcifA055xCeeBlhn+y+wrKanPuzoXQLODiE+80b/aTU94cjfD1wUYtc3IN6O/hT4B9jt+QxFAPL7Q8h3hfOOjv4wNt8lP9mEfHtOAhxyEjRFhXICwL4K5GfA96I9kVJZvaywDfiqoNnxzc/rGnrWNz1vFXC4eRqQAg+r/a9H/lMVyLcJ2B/ATY42KUqWGG7GFM6Sgnbfj/0/7GLoGY/oGinwPLBD3pe5rq1ufiHvNfYvSX6EKRv/5djyrIIGPNtFBxyP4P8z4DlgXsgva7/t+T95GqEoQFwkZmfNKSVkJY9EnPYBjYCqlRteqhD55EVA812MgJo0QdbZHhYSo5ra1EnnGzf4vymwiCk1q+kYgwAAnsRML4boWIhUAOXMD8BjgcizPkQFUHCkppL57qt5HduENQvsVCdc7j/vBrZXjP390X89cIsKoJytXnK0IQQW1ASVw67A/uQ+1YByhO0NRJj9/b1dLEU0pQEhEycrgAcxs2kJOh+wKVkLwO9eOaHOkWKqostdS+qa1ICQZeNESH+ka36gSSecNaBZK56fUQGMCD0R6JI4487MjLXpIRJMXekIOjW5qanYjpmCDOWE3d7QNUx3ROsX6DWhAXZkXsZ0sYW01zar3gG8INfSEvcQoX5Mue63olqQYNaD3SrXilUD8s3Qzw1FQ5mYoNco3+IyVQL4tsGIKAGeBh4VDVNT5BEEZjKmaPdzlU6JDDgvPkEXa+Ro1U7g78CRUF7D1meOALRG5JihGPiyAUecJ4RTjvapJjh1oDep3hNU9LD/vZpjBqfeDzxA+W7oOkJ4F7jRGQRRQG1upRmaAb5r0BnnCeGsCJ6agmj9OrRRmiFfCOvAcYmQXK3cMsRZ25He49pS+ixmZU7rnLxV23swa3urtKbXCVEzqRu9Aty+wf3FQ7LpOUxL/I+0eE8Ke8NnRqgF7gya/XwJs7r+CLCH/A6LWeAOTDffScnkM+A3BnsWRU3Y6aYFkAIPAR+NYRRZYbjXTIA/JVN3WyYXMc1kW73fvyxljx4t3RTKPvzpEWtBnkYUyUf6mO1w+hJAzLQ9ybM3vxu4yrVbz2RjEoYrEHu4PsoOkme6klfYB3h1jFpQZVVm3JWkzoZ41wGfN1yeCDHfcBG4q8GK8VjD0jvlAUeRIZcl/6q8X+lqScM+0IqjBemECMCSf9JLJDtbqDs2QULwC3qd35ElTwjJmEf+qhe1TU3J+lhOBDLqbHnVMZFTNaljhXCUwcasoyzauTZ/amfUrBCWGeyc2JRvcE3dBcz2OVNNvi+EOeAEg51x7WhNA5ga18ecYbCCR3ffykl49mJ21rrC//eM6LPxvhNumWE9x6e8j2lloatxfoiMuecJ4g3gF4bvpDgsqbsEvO0RPzEdddEEa0PklH9vwMxKHRJfsQezXGmr97tEnPkPwDfAp8AHwK9eSSSZpBE36WYpFlPiYl6Esuh9fx44h+nMzsvAk0lU+TYV8yLHzoc8XwVQ4b7zpghd269QKBQKhUKhUCgUCoVCoVAoFAqFwuA/cp9gBTN36BIAAAAASUVORK5CYII="
    "sun" = "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"
    "line_draw" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABNElEQVR42u3WyREDIAzFUEj/PZMWcsl8L08FcJAY2+cAAAAAAAAAAAAAwPvXwx9uf5b/BMj//CdAfuw8AfIz/wmQX7hPgOy1cwVoLl+AsHwBwvIFCMvfHiAuf3OAEvK3Bigjf2OAUvK3BSgnf1OAkvK3BCgrf0OA0vKnBygvf3KAFvKnBmgjf2KAVvKnBWgnf1KAlvKnBGgrf0KA1vK7B2gvv3OAEfK7Bhgjv2OAUfK7BRgnv1OAkfK7BBgrv0OA0fKrBxgvv3KAFfKrBlgjv2KAVfKrBVgnv1KAlfKrBFgrv0KA1fLTAdbLTwYgPxiA/GAA8oMByA8GID8YgPxgAPKDAcgPBiA/GID8YADygwHIDwYgPxzgkp8fQZf8/BK+5OfP0Et+DR4FAAAAAAAAAAAA53wBcJg/dehdUlYAAAAASUVORK5CYII="
    "polyline_draw" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAABmElEQVR42u2aUW6DUAwEWd//zs4NqgbM89qZ+azaCDy7fhD1ugAAAAAAAAAAAAAAAOBVxAhukxXzDOZYNvy/fo6AA8O/JQEBtcP/WgICmkEAAhAAxXsdAYPerxBQn37RgAHJR0B9+m99rYOApuQjoPHJBwEm6UdAc/of23v5ZjVg+I+vMYyTluYNKQlImNc8jdM//hBOx4GcXt0cws2yEdD84BIks3fVTWpAbkt/p4A0k9AmNwYmOZuuR1sEbFlHIwWk2We1pt+1ATJrgrY0IL+42RMSLNaY8xng0ARtEZA3b1aN17OmAXkohTkt/U4rSAclWD3Chnn6u5qgLQKqb/apBLsXuGhOvw42Id3S/6YAl6Tli20cv4J06G/zMv7uKAanX+afZ90ATR6as4AcmlxtENC5Z0UD+gelifJiQfpHNyEWDke/JiA3JvMXXsSgQIBr+lX8e5YCpv//viY3IIckTO5nkl5OPodvcQMYfqMAhs9jKAIAAQiAJgFj3i43N0AMv38FieEDAAAAAAAAAAAAAAAAwP/4ABRpRHmTglTuAAAAAElFTkSuQmCC"
    "text_draw" = "iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAADjUlEQVR42u2cXWhPYRzHP2MxZGJekprXyC7EMG9JXm4oVotEZIgLN4pWK6UkV+5I3i4kIilSysXmwgVzQytDiBUXprxOXjaGi/9Z/Z09tvM7/3OO7X++n3outv//eZ7zfL/P2zm/5/xBCCGEEEIIIYQQQgghhBBCCCGEEEKIVDMc+A78DpA6gNK+0Kh+fciAjcBAQ7uq1Wej5V7A3t+ZXgAFki0aZhjF70xLNQVFw/aQ+baq7+bOAOBtyBHwBSjWCMiNSqAkZN7BwHr14dy44evV942joEEShmect6fPFrQKuG00YbqmoHBU+67xHXAdOKfFOBme+XryUe//I4A2wwh4DRRKThtLHELOyfr8qnEaWi1JbZz1Cdjk+7zKaMBVSRqcod4ePlvAGsf9wXuDAe3AKEkbjB0+8X4CYx3fO2EcBXskbTAafMLd+Mf3FhkNeCBpe2a6Q7ju7mafG02Yq/uA7tnm+/sTcK2b75/PsXyRRSHQ4uuxJ3vIM8U4Aj4ARZLaTaVDsIUh1oye0kZJ7eaaT6inAfPtMhpQJ6m7Mgb44RNqX8C8Jd4+P6gBv4DxkvxvahwileYwenpK+yX53zzyCVRvzL8WBe1Ds8Ah0GZjGQO9HU5eBe2T4rRPmM/AkBDlnDIacE7SZ+K2rT5hzoQsa7HRgK/08qB9EmxxCLMkZFkFQLPRhJ1pN+CWT5DmHBfHg0YD7v7Pxv/vXcBkMmHH7OtoAR7mUGYJMNOYpwx4nMbef4hwB66iTofTKH4/4FUvMaCFFAbtV/YS8TvTmrQZcNknwMuI16QLKGjf7ULZFvM8vMpoQDswOi0G7HYIUB5xHYXAG6MJe9NiQCPhnvtbOWI0oCkN4s92NPxATHVVhFiMK/LdgGMke3r5idGA4/ksfhFdT7M1xlznfqMBH4FB+WrABkeDa2Ouc1KIaShvg/Z1jsZOSKDeO0YD6vNR/FK6vu2S1OtD1lMTiQXtkzwZt9VR38WE6r5E5sRFUArIszftXYGSDtwnnuPCemoi17hEr2K5o4E3E76GdSEW42VxX1T/mMue5009tcBIx6OCWcA0Mu98dXhbwN8RPoooA1YAm8gce5xoLGO+99zqJ5n3zH71lR5fniWmJX0jmmODVwj+0zZBU2scIyKuRbgYGBbyRi2Ku+KpBP9pm6AM9UZqn90FCSGEEEIIIYQQQgghhBBCCCGEEEIIIZLhD5O98y5U1JWPAAAAAElFTkSuQmCC"
}

$script:IconImageCache = @{}
function Get-IconImage([string]$name) {
    if ($script:IconImageCache.ContainsKey($name)) { return $script:IconImageCache[$name] }
    if($name -eq 'copy'){
        $bmp=[Drawing.Bitmap]::new(96,96);$g=[Drawing.Graphics]::FromImage($bmp);$g.SmoothingMode='AntiAlias'
        $pen=[Drawing.Pen]::new([Drawing.Color]::Black,6)
        try{$g.DrawRectangle($pen,35,15,43,52);$g.DrawRectangle($pen,18,31,43,52)}finally{$pen.Dispose();$g.Dispose()}
        $script:IconImageCache[$name]=$bmp;return $bmp
    }
    if($name -eq 'crop'){
        $bmp=[Drawing.Bitmap]::new(96,96);$g=[Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode='AntiAlias';$pen=[Drawing.Pen]::new([Drawing.Color]::Black,6)
        try{
            $g.DrawLines($pen,[Drawing.PointF[]]@([Drawing.PointF]::new(24,9),[Drawing.PointF]::new(24,72),[Drawing.PointF]::new(87,72)))
            $g.DrawLines($pen,[Drawing.PointF[]]@([Drawing.PointF]::new(9,24),[Drawing.PointF]::new(72,24),[Drawing.PointF]::new(72,87)))
        }finally{$pen.Dispose();$g.Dispose()}
        $script:IconImageCache[$name]=$bmp;return $bmp
    }
    $bytes = [Convert]::FromBase64String($script:IconBase64[$name])
    $ms = New-Object System.IO.MemoryStream(,$bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $script:IconImageCache[$name] = $img
    return $img
}

# ----------------------------
# Themeable line-art icons
# ----------------------------
# The Shape/Style toolbar icons (rectangle/oval/freeform/blur/pixelate/black)
# and the eyedropper icon are stored as pure black ink on a fully transparent
# background (see $script:IconBase64 above) rather than the old baked-in grey
# tile. That means the button's own BackColor - which Apply-Theme already
# keeps in sync with the light/dark theme - shows through the transparent
# surround, and the ink itself can be recolored to match whichever theme is
# active. Get-ThemedIconImage does that recoloring: since every source pixel
# is exactly black (0,0,0) at some alpha, a ColorMatrix whose RGB rows are
# all zero and whose translation row is the target color remaps every pixel
# to "target color at the same alpha" in one GPU-side pass, with no per-pixel
# loop needed.
$script:ThemedIconCache = @{}
function Get-ThemedIconImage([string]$name, [System.Drawing.Color]$color) {
    $cacheKey = "$name|$($color.ToArgb())"
    if ($script:ThemedIconCache.ContainsKey($cacheKey)) { return $script:ThemedIconCache[$cacheKey] }

    $src = Get-IconImage $name
    $bmp = New-Object System.Drawing.Bitmap($src.Width, $src.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $r = $color.R / 255.0
    $gc = $color.G / 255.0
    $b = $color.B / 255.0
    $matrixElements = [float[][]]@(
        @(0,0,0,0,0),
        @(0,0,0,0,0),
        @(0,0,0,0,0),
        @(0,0,0,1,0),
        @($r,$gc,$b,0,1)
    )
    $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix(,$matrixElements)
    $attr = New-Object System.Drawing.Imaging.ImageAttributes
    $attr.SetColorMatrix($colorMatrix)
    $destRect = New-Object System.Drawing.Rectangle(0,0,$src.Width,$src.Height)
    $g.DrawImage($src, $destRect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel, $attr)
    $attr.Dispose()
    $g.Dispose()

    $script:ThemedIconCache[$cacheKey] = $bmp
    return $bmp
}

# Every control showing a themed line-art icon registers itself here (name +
# whether it's a checkable tool button) so Update-ThemedIcons can restyle all
# of them in one pass whenever the theme changes or a selection changes.
$script:ThemedIconButtons = New-Object System.Collections.Generic.List[object]
function Register-ThemedIcon($control, [string]$iconName) {
    [void]$script:ThemedIconButtons.Add(@{ Control = $control; IconName = $iconName })
}

# Recolors every registered themed icon: a checked tool/style RadioButton
# gets the accent color (matching its own accent-tinted selected background),
# everything else gets the theme's normal text/icon color.
function Update-ThemedIcons([System.Drawing.Color]$normalColor, [System.Drawing.Color]$accentColor) {
    foreach ($entry in $script:ThemedIconButtons) {
        $ctl = $entry.Control
        $isChecked = ($ctl -is [System.Windows.Forms.RadioButton]) -and $ctl.Checked
        $color = if($entry.IconName -eq 'crop' -and -not $ctl.Enabled){[Drawing.Color]::Gray}elseif ($isChecked) { $accentColor } else { $normalColor }
        $ctl.Image = Get-ThemedIconImage $entry.IconName $color
        $ctl.Invalidate()
    }
}

$logo = New-Object System.Windows.Forms.PictureBox
$logo.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$logo.Image = Get-AppIconImage
$logo.Location = New-Object System.Drawing.Point(10,11)
$logo.Size = New-Object System.Drawing.Size(40,40)
$logo.Tag = "logo"
$top.Controls.Add($logo)

$lblAppTitle = New-Object System.Windows.Forms.Label
$lblAppTitle.Text = "TinyRedactionTool"
$lblAppTitle.Location = New-Object System.Drawing.Point(62,7)
$lblAppTitle.Size = New-Object System.Drawing.Size(260,26)
$lblAppTitle.Font = New-UIFont 14 ([System.Drawing.FontStyle]::Bold)
$lblAppTitle.Tag = "heading"
$top.Controls.Add($lblAppTitle)

$lblAppSub = New-Object System.Windows.Forms.Label
$lblAppSub.Text = "Simple. Private. Secure."
$lblAppSub.Location = New-Object System.Drawing.Point(64,33)
$lblAppSub.Size = New-Object System.Drawing.Size(260,20)
$lblAppSub.Font = New-UIFont 9.2
$lblAppSub.Tag = "muted"
$top.Controls.Add($lblAppSub)

# Everything from here to $btnTheme sits in the header's right-hand cluster:
# theme toggle, then (moving left) the privacy/credit note, then the
# Open/Change file button. Each is positioned from $form.ClientSize.Width at
# construction time and kept flush via Anchor="Top,Right" - the same
# established pattern already proven reliable for $btnTheme itself.
$btnTheme = New-Object System.Windows.Forms.Button
$btnTheme.Text = ""
$btnTheme.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnTheme.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - $script:UiGap - $script:UiIconButtonSize),15)
$btnTheme.Anchor = "Top,Right"
$btnTheme.Tag = "button"
$btnTheme.Image = Get-ThemedIconImage "moon" ([System.Drawing.Color]::FromArgb(32,32,32))
Style-FlatButton $btnTheme $false 8
$top.Controls.Add($btnTheme)
$script:appToolTip.SetToolTip($btnTheme, "Switch to Dark Mode")

# A small circular "i" info button replaces the old
# always-on privacy/credit text: clicking it opens the About dialog (see
# Show-AboutDialog) with the full copyright/license/no-telemetry statement,
# keeping the header itself uncluttered. Sits just left of the theme toggle,
# in the same right-hand cluster.
$btnClearScreen=New-Object System.Windows.Forms.Button
$btnClearScreen.Text='Clear Screen'
$btnClearScreen.Size=New-Object System.Drawing.Size(105,$script:UiIconButtonSize)
$btnClearScreen.Anchor='Top,Right'
Style-FlatButton $btnClearScreen $true
$top.Controls.Add($btnClearScreen)
$appToolTip.SetToolTip($btnClearScreen,'Unload the current image or video without deleting its source file')
$btnClearScreen.Add_Click({
    if($script:CaptureState.Busy -or $script:CaptureState.Recorder -or -not $form.Enabled){return}
    Stop-Playback
    if($script:floatingTextEditorVisible){Close-FloatingTextEditor $false}
    Reset-LoadedSourceAfterDestructiveDeletion 'Ready.'
    Remove-UnusedCaptureFiles
})
$btnInfo = New-Object System.Windows.Forms.Button
$btnInfo.Text = ""
$btnInfo.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnInfo.Location = New-Object System.Drawing.Point(($form.ClientSize.Width - (2 * $script:UiIconButtonSize) - (2 * $script:UiGap)),15)
$btnInfo.Anchor = "Top,Right"
Style-FlatButton $btnInfo $false 999
$top.Controls.Add($btnInfo)
Register-ThemedIcon $btnInfo "info"
$script:appToolTip.SetToolTip($btnInfo, "About TinyRedactionTool")

# "Open Video | Image" - now lives in the header itself, not floating over
# the preview, so it's visible immediately (before any file is loaded) and
# never sits on top of the video. Renamed to "Change Video | Image" once a
# file is loaded - see the file-open handler further down. Sits immediately
# after the app title (fixed position, not right-anchored), so the header
# reads left-to-right as: title -> Open/Change button -> file name/path.
$btnOpen = New-Object System.Windows.Forms.Button
$btnOpen.Text = "Open Video | Image"
$btnOpen.Size = New-Object System.Drawing.Size($script:OpenButtonWidth,$script:CompactButtonHeight)
$btnOpen.Location = New-Object System.Drawing.Point(330,17)
$btnOpen.Font = New-UIFont 8.3
Style-FlatButton $btnOpen $true
$top.Controls.Add($btnOpen)

# File name/path + hint, filling the space between the Open/Change button
# and the right-hand cluster (privacy/credit note + theme toggle). Its width
# has to be recomputed by Update-PolishedLayout on every resize (there's no
# single Anchor setting that means "stretch, but stop short of that other
# anchored control"), so only its fixed X/Y are set here.
$lblFile = New-Object System.Windows.Forms.Label
$lblFile.Text = "No Video | Image Loaded"
$lblFile.AutoEllipsis = $true
$lblFile.Location = New-Object System.Drawing.Point(($btnOpen.Right + 14),11)
$lblFile.Size = New-Object System.Drawing.Size(400,22)
$lblFile.Font = New-UIFont 9.6 ([System.Drawing.FontStyle]::Bold)
$lblFile.Tag = "heading"
$top.Controls.Add($lblFile)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "Open a file to begin."
$lblHint.AutoEllipsis = $true
$lblHint.Location = New-Object System.Drawing.Point(($btnOpen.Right + 14),33)
$lblHint.Size = New-Object System.Drawing.Size(400,20)
$lblHint.Font = New-UIFont 8.4
$lblHint.Tag = "muted"
$top.Controls.Add($lblHint)

# Main layout: a narrow Photoshop-style tool rail, the preview workspace,
# and the inspector. Losing the old 245px wizard rail in favor of a 60px
# icon rail is most of where the extra preview space comes from.
$main = New-Object System.Windows.Forms.TableLayoutPanel
$main.Dock = "None"
$main.Location = New-Object System.Drawing.Point(0,$script:HeaderHeight)
$main.Size = New-Object System.Drawing.Size($form.ClientSize.Width,([Math]::Max(1,$form.ClientSize.Height - $script:HeaderHeight)))
$main.Anchor = "Top,Bottom,Left,Right"
$main.ColumnCount = 3
$main.RowCount = 1
$main.Padding = New-Object System.Windows.Forms.Padding(0)
$main.Margin = New-Object System.Windows.Forms.Padding(0)
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,$script:ToolbarWidth)))
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent,100)))
# v1.4 preview starts with the inspector collapsed; its slim host contains
# only the persistent restore button until the user opens Redaction Area.
[void]$main.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute,$script:InspectorCollapsedWidth)))
$form.Controls.Add($main)

# Header must stay visually above the workspace; geometry keeps the two from overlapping.
$top.BringToFront()

# TOOLBAR --------------------------------------------------------------
# A narrow Photoshop-style icon rail replacing the old wizard steps: Shape
# tools, then Style (redaction mode). These reuse the exact same
# $rbRectangle/$rbOval/$rbFreeform/$rbModeBlack/$rbModeBlur/$rbModePixelate
# RadioButtons the right panel used before (created further down, then
# re-parented here) so all of their existing Set-ToolMode/Get-SelectedMode
# wiring, Apply-Theme coloring, and Update-RedactionButtons enable/disable
# logic carries over unchanged - only their container and skin change.
$toolbar = New-Object System.Windows.Forms.Panel
$toolbar.Dock = "Fill"
# TableLayoutPanel gives child controls a default 3px Margin. In the compact
# 38px toolbar column that silently reduced the usable width below the 34px
# icon-button width and clipped the buttons on their right edge. The toolbar
# itself must occupy the entire column; UiGap provides the intended spacing.
$toolbar.Margin = New-Object System.Windows.Forms.Padding(0)
$toolbar.Padding = New-Object System.Windows.Forms.Padding(0)
$toolbar.Tag = "toolbar"
$main.Controls.Add($toolbar,0,0)

$lblToolsHeading = New-Object System.Windows.Forms.Label
$lblToolsHeading.Text = "Tools"
$lblToolsHeading.TextAlign = "MiddleCenter"
$lblToolsHeading.Location = New-Object System.Drawing.Point(0,4)
$lblToolsHeading.Size = New-Object System.Drawing.Size($script:ToolbarWidth,14)
$lblToolsHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblToolsHeading.Tag = "muted"
$toolbar.Controls.Add($lblToolsHeading)

# Icon-only RadioButton used by both toolbar groups (Shape and Style) -
# same rounded-paint/Enable-RoundedPaint mechanics as every other button in
# this app, just image-only instead of text.
function New-ToolbarIconButton($parent, [string]$iconName, [int]$x, [int]$y, [string]$tooltipText) {
    $b = New-Object System.Windows.Forms.RadioButton
    $b.Appearance = "Button"
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 1
    $b.Text = ""
    # Placeholder until Update-ThemedIcons (called from Apply-Theme, which
    # runs once at startup) recolors it for the active theme - registering
    # below is what makes that happen.
    $b.Image = Get-ThemedIconImage $iconName ([System.Drawing.Color]::Black)
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Location = New-Object System.Drawing.Point($x,$y)
    $b.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
    $b.Tag = "choice"
    Enable-RoundedPaint $b 10
    $parent.Controls.Add($b)
    $script:appToolTip.SetToolTip($b, $tooltipText)
    Register-ThemedIcon $b $iconName
    return $b
}

$script:ImageCrop=$null
$script:CropDraft=$null
$script:CropGesture=$null

function Get-CropBounds {
    if($isImageMode -and $script:ImageCrop){return $script:ImageCrop}
    return [Drawing.RectangleF]::new(0,0,$videoWidth,$videoHeight)
}
function Get-CropPixelRectangle([Drawing.RectangleF]$rect,[Drawing.RectangleF]$bounds) {
    $left=[Math]::Max([int][Math]::Floor($bounds.Left),[int][Math]::Floor($rect.Left))
    $top=[Math]::Max([int][Math]::Floor($bounds.Top),[int][Math]::Floor($rect.Top))
    $right=[Math]::Min([int][Math]::Ceiling($bounds.Right),[int][Math]::Ceiling($rect.Right))
    $bottom=[Math]::Min([int][Math]::Ceiling($bounds.Bottom),[int][Math]::Ceiling($rect.Bottom))
    if($right -le $left -or $bottom -le $top){return $null}
    return [Drawing.Rectangle]::FromLTRB($left,$top,$right,$bottom)
}
function Update-CropControls {
    if(-not $rbCrop){return}
    $rbCrop.Enabled=[bool]($videoPath -and $isImageMode -and -not $script:pendingAnnotation -and -not $pendingRedaction)
    $appToolTip.SetToolTip($rbCrop,$(if($videoPath -and -not $isImageMode){'Video Crop not supported'}else{'Crop Image Tool'}))
    if(-not $rbCrop.Enabled -and $rbCrop.Checked){$rbRectangle.Checked=$true}
    Update-ThemedIcons $script:cTextCurrent $script:cAccentCurrent
    if($isImageMode -and $toolMode -eq 'Crop'){
        $btnAddRedaction.Visible=$true;$btnAddRedaction.Text='Confirm Crop'
        $btnAddRedaction.Enabled=[bool]($script:CropDraft -and $script:CropDraft.Width -ge 1 -and $script:CropDraft.Height -ge 1)
        Set-RedactionButtonColor $btnAddRedaction $(if($btnAddRedaction.Enabled){'green'}else{'grey'})
        $lblToolHint.Text='Crop: drag a rectangle; adjust its eight handles or drag inside. Confirm Crop applies; Esc cancels.'
    }
}
function Start-CropGesture($event) {
    if($event.Button -ne [Windows.Forms.MouseButtons]::Left){return}
    $point=ViewPoint-To-MediaPoint ([Drawing.PointF]::new($event.X,$event.Y)) $false
    if(-not $point){return}
    $bounds=Get-CropBounds
    $kind='New'
    if($script:CropDraft){
        foreach($handle in @(Get-RectangleResizeHandleCenters $script:CropDraft)){
            if([Math]::Abs($handle.X-$event.X) -le 8 -and [Math]::Abs($handle.Y-$event.Y) -le 8){$kind=$handle.Name;break}
        }
        if($kind -eq 'New' -and $script:CropDraft.Contains($point)){$kind='Move'}
    }
    if($kind -eq 'New' -and -not $bounds.Contains($point)){return}
    $script:CropGesture=[pscustomobject]@{Kind=$kind;Start=$point;Rect=$script:CropDraft;Bounds=$bounds}
    if($kind -eq 'New'){$script:CropDraft=[Drawing.RectangleF]::new($point.X,$point.Y,0,0)}
    $picture.Capture=$true;$picture.Invalidate()
}
function Update-CropGesture($event) {
    $gesture=$script:CropGesture
    if(-not $gesture){
        $cursor=[Windows.Forms.Cursors]::Cross
        if($script:CropDraft){
            $view=[Drawing.PointF]::new($event.X,$event.Y)
            $handle=Get-RectangleResizeHandleAtViewPoint $view $script:CropDraft
            if($handle -ne 'None'){$cursor=Get-RectangleResizeCursor $handle}
            elseif((MediaRect-To-ViewRect $script:CropDraft).Contains($view)){$cursor=[Windows.Forms.Cursors]::SizeAll}
        }
        $picture.Cursor=$cursor;return
    }
    $point=ViewPoint-To-MediaPoint ([Drawing.PointF]::new($event.X,$event.Y)) $false
    if(-not $point){return}
    $b=$gesture.Bounds
    $x=[Math]::Max($b.Left,[Math]::Min($b.Right,$point.X));$y=[Math]::Max($b.Top,[Math]::Min($b.Bottom,$point.Y))
    if($gesture.Kind -eq 'Move'){
        $r=$gesture.Rect
        $left=[Math]::Max($b.Left,[Math]::Min($b.Right-$r.Width,$r.X+$x-$gesture.Start.X))
        $top=[Math]::Max($b.Top,[Math]::Min($b.Bottom-$r.Height,$r.Y+$y-$gesture.Start.Y))
        $script:CropDraft=[Drawing.RectangleF]::new($left,$top,$r.Width,$r.Height)
    }else{
        if($gesture.Kind -eq 'New'){$left=$gesture.Start.X;$top=$gesture.Start.Y;$right=$x;$bottom=$y}
        else{
            $r=$gesture.Rect;$left=$r.Left;$top=$r.Top;$right=$r.Right;$bottom=$r.Bottom
            if($gesture.Kind.Contains('W')){$left=$x};if($gesture.Kind.Contains('E')){$right=$x}
            if($gesture.Kind.Contains('N')){$top=$y};if($gesture.Kind.Contains('S')){$bottom=$y}
        }
        $script:CropDraft=[Drawing.RectangleF]::FromLTRB([Math]::Min($left,$right),[Math]::Min($top,$bottom),[Math]::Max($left,$right),[Math]::Max($top,$bottom))
    }
    Update-CropControls;$picture.Invalidate()
}
function Confirm-ImageCrop {
    if(-not $isImageMode -or -not $script:CropDraft){return}
    $rect=Get-CropPixelRectangle $script:CropDraft (Get-CropBounds)
    if(-not $rect){return}
    $script:ImageCrop=[Drawing.RectangleF]$rect
    $script:CropDraft=$null;$script:CropGesture=$null;$picture.Capture=$false
    Reset-ViewportState
    $rbRectangle.Checked=$true
    Update-RedactionButtons;Update-ZoomHud;$picture.Invalidate()
    $status.Text="Image cropped to $($rect.Width) x $($rect.Height). Original unchanged."
}
function Draw-CropGuide($graphics) {
    if(-not $isImageMode -or $toolMode -ne 'Crop' -or -not $script:CropDraft){return}
    $view=MediaRect-To-ViewRect $script:CropDraft
    if(-not $view -or $view.Width -le 0 -or $view.Height -le 0){return}
    $area=MediaRect-To-ViewRect (Get-CropBounds)
    $shade=[Drawing.Region]::new($area);$shade.Exclude($view)
    $brush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(145,0,0,0))
    $pen=[Drawing.Pen]::new([Drawing.Color]::DodgerBlue,1)
    try{
        $graphics.FillRegion($brush,$shade)
        $graphics.DrawRectangle($pen,$view.X,$view.Y,$view.Width,$view.Height)
        foreach($fraction in @((1.0/3),(2.0/3))){
            $x=$view.Left+$view.Width*$fraction;$y=$view.Top+$view.Height*$fraction
            $graphics.DrawLine($pen,[single]$x,[single]$view.Top,[single]$x,[single]$view.Bottom)
            $graphics.DrawLine($pen,[single]$view.Left,[single]$y,[single]$view.Right,[single]$y)
        }
        foreach($handle in @(Get-RectangleResizeHandleCenters $script:CropDraft)){
            $graphics.FillRectangle([Drawing.Brushes]::White,[single]($handle.X-4),[single]($handle.Y-4),8,8)
            $graphics.DrawRectangle($pen,[single]($handle.X-4),[single]($handle.Y-4),8,8)
        }
    }finally{$shade.Dispose();$brush.Dispose();$pen.Dispose()}
}
function Add-ImageCropFilter([string]$filter,[string]$label) {
    if(-not $isImageMode -or -not $script:ImageCrop){return [pscustomobject]@{Filter=$filter;Label=$label;Width=$videoWidth;Height=$videoHeight}}
    $r=Get-CropPixelRectangle $script:ImageCrop ([Drawing.RectangleF]::new(0,0,$videoWidth,$videoHeight))
    if(-not $r){throw 'Invalid confirmed image crop.'}
    $prefix=if($filter){';'}else{''}
    return [pscustomobject]@{Filter=($filter+$prefix+"[$label]crop=$($r.Width):$($r.Height):$($r.X):$($r.Y):exact=1[imagecrop]");Label='imagecrop';Width=$r.Width;Height=$r.Height}
}
function Fit-InspectorContents {
    if(-not $right -or -not $right.Visible -or $script:FittingInspector){return}
    $script:FittingInspector=$true
    try{
        $right.SuspendLayout()
        $right.AutoScrollPosition=[Drawing.Point]::Empty
        $limit=[Math]::Max(240,$right.ClientSize.Width-$right.Padding.Right-[Windows.Forms.SystemInformation]::VerticalScrollBarWidth)
        foreach($ctl in $right.Controls){
            if(-not $script:InspectorWidths.ContainsKey($ctl)){$script:InspectorWidths[$ctl]=@($ctl.Left,$ctl.Width)}
            $ctl.Left=[Math]::Min($script:InspectorWidths[$ctl][0],$limit-20)
            $ctl.Width=[Math]::Max(20,[Math]::Min($script:InspectorWidths[$ctl][1],$limit-$ctl.Left))
        }
        foreach($list in @($lvRedactions,$lvAnnotations)){
            $available=[Math]::Max(220,$list.ClientSize.Width-[Windows.Forms.SystemInformation]::VerticalScrollBarWidth-4)
            $list.Columns[0].Width=26;$list.Columns[1].Width=65
            if($isImageMode){$list.Columns[2].Width=$available-91;$list.Columns[3].Width=0}
            else{$list.Columns[2].Width=80;$list.Columns[3].Width=$available-171}
        }
        $right.AutoScrollMinSize=[Drawing.Size]::Empty
        Position-RightPanelToggle
    }finally{$right.ResumeLayout($true);$script:FittingInspector=$false}
}

$rbRectangle = New-ToolbarIconButton $toolbar "rectangle" $script:UiGap 22 "Rectangle Selection"
$rbRectangle.Checked = $true
$rbOval = New-ToolbarIconButton $toolbar "oval" $script:UiGap 60 "Oval Selection"
$rbFreeform = New-ToolbarIconButton $toolbar "freeform" $script:UiGap 98 "Freeform Selection"
$rbZoom = New-ToolbarIconButton $toolbar "zoom" $script:UiGap 136 "Zoom Tool - left click in, right click out; right-drag pans; mouse wheel zooms around pointer"

$rbCrop = New-ToolbarIconButton $toolbar "crop" $script:UiGap 174 "Crop Image Tool"
$rbCrop.Enabled=$false
Add-Rule $toolbar $script:UiGap 176 ($script:ToolbarWidth - (2 * $script:UiGap)) | Out-Null

$lblStyleHeading = New-Object System.Windows.Forms.Label
$lblStyleHeading.Text = "Style"
$lblStyleHeading.TextAlign = "MiddleCenter"
$lblStyleHeading.Location = New-Object System.Drawing.Point(0,184)
$lblStyleHeading.Size = New-Object System.Drawing.Size($script:ToolbarWidth,14)
$lblStyleHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblStyleHeading.Tag = "muted"
$toolbar.Controls.Add($lblStyleHeading)

# Redaction mode as its own isolated panel so WinForms' "RadioButtons
# auto-group by immediate parent" behavior doesn't lump these in with the
# Rectangle/Oval/Freeform tool buttons sitting directly on $toolbar.
$modeRow = New-Object System.Windows.Forms.Panel
$modeRow.Location = New-Object System.Drawing.Point(0,202)
$modeRow.Size = New-Object System.Drawing.Size($script:ToolbarWidth,110)
$toolbar.Controls.Add($modeRow)

$rbModeBlack = New-ToolbarIconButton $modeRow "black" $script:UiGap 0 "Coloured Box - secure opaque redaction"
$rbModeBlack.Checked = $true   # Secure opaque redaction is the default mode
$rbModeBlur = New-ToolbarIconButton $modeRow "blur" $script:UiGap 38 "Blur - visual obscuration only; use Coloured Box for secure redaction"
$rbModePixelate = New-ToolbarIconButton $modeRow "pixelate" $script:UiGap 76 "Pixelate - visual obscuration only; use Coloured Box for secure redaction"

# G2d managed control: a deployment may prohibit Blur/Pixelate because they are
# visual-obscuration methods rather than guaranteed irreversible redaction. Keep
# the icons visible so the restriction is obvious, but leave Coloured Box usable.
if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) {
    $rbModeBlack.Checked = $true
    $rbModeBlur.Checked = $false
    $rbModePixelate.Checked = $false
    $rbModeBlur.Enabled = $false
    $rbModePixelate.Enabled = $false
    $script:appToolTip.SetToolTip($rbModeBlur, "Blur disabled by managed policy. Use Coloured Box for secure redaction.")
    $script:appToolTip.SetToolTip($rbModePixelate, "Pixelate disabled by managed policy. Use Coloured Box for secure redaction.")

    # G2d-r5: WinForms ToolTip does not display normally for disabled child controls.
    # Keep Blur/Pixelate genuinely disabled, but let their enabled parent panel surface
    # the same control-specific message when the pointer is over either disabled icon.
    $script:managedVisualTooltipTarget = ''
    $modeRow.Add_MouseMove({
        param($sender,$e)
        if (-not ($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration)) { return }

        $target = ''
        $message = ''
        if ($rbModeBlur.Bounds.Contains($e.Location)) {
            $target = 'Blur'
            $message = 'Blur disabled by managed policy. Use Coloured Box for secure redaction.'
        }
        elseif ($rbModePixelate.Bounds.Contains($e.Location)) {
            $target = 'Pixelate'
            $message = 'Pixelate disabled by managed policy. Use Coloured Box for secure redaction.'
        }

        if ($target -ne $script:managedVisualTooltipTarget) {
            $script:appToolTip.Hide($modeRow)
            $script:managedVisualTooltipTarget = $target
            if ($message) {
                $script:appToolTip.Show($message, $modeRow, ($e.X + 14), ($e.Y + 18), 5000)
            }
        }
    })
    $modeRow.Add_MouseLeave({
        $script:appToolTip.Hide($modeRow)
        $script:managedVisualTooltipTarget = ''
    })
}

# D2: standalone drawing tools are isolated in their own RadioButton parent so
# they do not disturb the Style choice group. CheckedChanged handlers below
# explicitly arbitrate them against Rectangle/Oval/Freeform/Zoom.
Add-Rule $toolbar $script:UiGap 318 ($script:ToolbarWidth - (2 * $script:UiGap)) | Out-Null
$lblDrawHeading = New-Object System.Windows.Forms.Label
$lblDrawHeading.Text = "Draw"
$lblDrawHeading.TextAlign = "MiddleCenter"
$lblDrawHeading.Location = New-Object System.Drawing.Point(0,326)
$lblDrawHeading.Size = New-Object System.Drawing.Size($script:ToolbarWidth,14)
$lblDrawHeading.Font = New-UIFont 7.2 ([System.Drawing.FontStyle]::Bold)
$lblDrawHeading.Tag = "muted"
$toolbar.Controls.Add($lblDrawHeading)

$drawRow = New-Object System.Windows.Forms.Panel
$drawRow.Location = New-Object System.Drawing.Point(0,344)
$drawRow.Size = New-Object System.Drawing.Size($script:ToolbarWidth,110)
$toolbar.Controls.Add($drawRow)

$rbText = New-ToolbarIconButton $drawRow "text_draw" $script:UiGap 0 "Text Box Annotation - drag a box, then type in the floating editor"
$rbLine = New-ToolbarIconButton $drawRow "line_draw" $script:UiGap 38 "Line Annotation - drag start to end; Shift constrains angle"
$rbPolyline = New-ToolbarIconButton $drawRow "polyline_draw" $script:UiGap 76 "Polyline Annotation - hold the left mouse button and draw; release to finish"
$rbText.Enabled = $false
$rbLine.Enabled = $false
$rbPolyline.Enabled = $false
foreach($control in $toolbar.Controls){if($control -ne $rbCrop -and $control.Top -ge 176){$control.Top+=38}}

# CENTER -------------------------------------------------------------
$center = New-Object System.Windows.Forms.Panel
$center.Dock = "Fill"
# UiGap is the exact space between the left toolbar and preview. The right
# padding is deliberately zero so, when Redaction Area is collapsed, the
# preview stops exactly UiGap pixels before the persistent restore icon.
$center.Padding = New-Object System.Windows.Forms.Padding($script:UiGap,$script:UiGap,0,2)
$center.Tag = "workspace"
$main.Controls.Add($center,1,0)

# Playback / timeline panel at the bottom of the center column.
$bottom = New-Object System.Windows.Forms.Panel
$bottom.Dock = "Bottom"
$bottom.Height = 156
$bottom.Padding = New-Object System.Windows.Forms.Padding(0)
$bottom.Tag = "workspace"
$center.Controls.Add($bottom)

$lblPos = New-Object System.Windows.Forms.Label
$lblPos.Text = "Preview frame"
$lblPos.Location = New-Object System.Drawing.Point(0,1)
$lblPos.Size = New-Object System.Drawing.Size(110,22)
$lblPos.Font = New-UIFont 8.5
$lblPos.Tag = "muted"
$bottom.Controls.Add($lblPos)

$lblPosValue = New-Object System.Windows.Forms.Label
$lblPosValue.Text = "00:00:00.000"
$lblPosValue.Location = New-Object System.Drawing.Point(112,0)
$lblPosValue.Size = New-Object System.Drawing.Size(110,24)
$lblPosValue.Font = New-UIFont 9.1 ([System.Drawing.FontStyle]::Bold)
$lblPosValue.Tag = "heading"
$bottom.Controls.Add($lblPosValue)

$lblFrameCount = New-Object System.Windows.Forms.Label
$lblFrameCount.Text = "Frame 0 / 0"
$lblFrameCount.TextAlign = "MiddleRight"
$lblFrameCount.Location = New-Object System.Drawing.Point(520,1)
$lblFrameCount.Size = New-Object System.Drawing.Size(170,24)
$lblFrameCount.Anchor = "Top,Right"
$lblFrameCount.Font = New-UIFont 8.5
$lblFrameCount.Tag = "muted"
$bottom.Controls.Add($lblFrameCount)

# Custom slim seek bar, replacing the native TrackBar - WinForms' stock
# TrackBar has a chunky beveled OS-native look that doesn't match the
# mockup's thin track + round accent-colored thumb. It's driven directly off
# $currentFrame/$totalFrames rather than its own Value/Minimum/Maximum
# properties, so there's a single source of truth instead of two numbers
# that could drift out of sync.
$seekBar = New-Object System.Windows.Forms.Panel
$seekBar.Location = New-Object System.Drawing.Point(0,20)
$seekBar.Size = New-Object System.Drawing.Size(690,28)
# No Anchor here - same reasoning as $btnCancelRedaction below: $bottom
# hasn't been through a real WinForms layout pass yet at construction time,
# so an Anchor="Top,Left,Right" set now would capture a wrong baseline width
# and never track $bottom's true live width afterwards (in either windowed
# or maximized state). Update-PolishedLayout sets .Width explicitly instead,
# from $bottom's live ClientSize.Width, every time the form resizes.
$seekBar.Enabled = $false
$seekBar.Cursor = [System.Windows.Forms.Cursors]::Hand
$seekBar.Tag = "seekbar"
$bottom.Controls.Add($seekBar)

# Moves the playhead to whatever frame corresponds to a given X pixel within
# $seekBar - shared by MouseDown (click-to-seek) and MouseMove (drag-to-seek).
function Set-FrameFromSeekX([int]$x) {
    if (-not $videoPath -or $isImageMode -or $totalFrames -le 1) { return }
    $w = $seekBar.ClientSize.Width
    if ($w -le 0 -or $videoDuration -le 0) { return }

    # The seek bar is time-linear, not frame-linear. On VFR material half the
    # duration does not necessarily mean half the frame count.
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $x / [double]$w))
    $targetTime = $frac * $videoDuration
    $newFrame = Get-FrameIndexAtPresentationTime $targetTime
    if ($newFrame -lt 0) { return }

    $mappedTime = Get-FramePresentationTime $newFrame
    if ([double]::IsNaN($mappedTime) -or [double]::IsInfinity($mappedTime)) { return }
    if ($newFrame -eq $currentFrame) { return }

    $script:currentFrame = $newFrame
    $script:previewSeconds = $mappedTime
    $lblPosValue.Text = SecToText $previewSeconds
    $lblFrameCount.Text = "Frame $($currentFrame + 1) / $totalFrames"
    $seekBar.Invalidate()
    $previewTimer.Stop()
    $previewTimer.Start()
}

$seekBar.Add_Paint({
    param($sender,$e)
    $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $w = $sender.ClientSize.Width
    $trackY = 12
    $trackH = 4
    $trackColor = if ($sender.Enabled) { $script:seekTrackColor } else { $script:seekTrackDisabledColor }
    $accentColor = if ($sender.Enabled) { $script:seekAccentColor } else { $script:seekTrackDisabledColor }

    $bgBrush = New-Object System.Drawing.SolidBrush($trackColor)
    $e.Graphics.FillRectangle($bgBrush, 0, $trackY, $w, $trackH)
    $bgBrush.Dispose()

    # Display the playhead on the real presentation timeline. For VFR this is
    # intentionally not currentFrame/totalFrames.
    $frac = if ($videoDuration -gt 0) { $previewSeconds / [double]$videoDuration } else { 0.0 }
    $frac = [Math]::Max(0.0, [Math]::Min(1.0, $frac))
    $filledW = [int]($frac * $w)
    $fillBrush = New-Object System.Drawing.SolidBrush($accentColor)
    if ($filledW -gt 0) { $e.Graphics.FillRectangle($fillBrush, 0, $trackY, $filledW, $trackH) }

    $thumbR = 7
    $cx = $filledW
    $cy = $trackY + [int]($trackH / 2)
    $e.Graphics.FillEllipse($fillBrush, ($cx - $thumbR), ($cy - $thumbR), ($thumbR * 2), ($thumbR * 2))
    $fillBrush.Dispose()
})

$seekBar.Add_MouseDown({
    param($sender,$e)
    if (-not $seekBar.Enabled -or $e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
    Stop-Playback
    $script:seekDragging = $true
    Set-FrameFromSeekX $e.X
})
$seekBar.Add_MouseMove({
    param($sender,$e)
    if ($script:seekDragging) { Set-FrameFromSeekX $e.X }
})
$seekBar.Add_MouseUp({
    param($sender,$e)
    $script:seekDragging = $false
})

$scrubberMarkers = New-Object System.Windows.Forms.Panel
# Sits in its own compact row directly below the seek bar, keeping the red
# redaction-range marks clear of the seek track itself.
$scrubberMarkers.Location = New-Object System.Drawing.Point(10,48)
$scrubberMarkers.Size = New-Object System.Drawing.Size(670,10)
# No Anchor - same Anchor-baseline-timing issue as $seekBar just above.
# It stays 10px inset on each side and Update-PolishedLayout resizes it from
# the live bottom-panel width. Parent + child invalidation there also clears
# the OLD bounds whenever this strip shrinks, preventing stale red range
# pixels from being left behind after panel/window layout changes.
$scrubberMarkers.Tag = "marker"
$bottom.Controls.Add($scrubberMarkers)
$script:appToolTip.SetToolTip($scrubberMarkers, "Red = redactions   |   Violet = annotations")
$scrubberMarkers.BringToFront()

# Icon-only playback/frame-step buttons (Button, not RadioButton - no
# mutual exclusivity needed here, unlike the toolbar's Shape/Style groups).
function New-IconButton([string]$iconName, [int]$w, [int]$h, [int]$radius = 10) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = ""
    $b.Image = Get-IconImage $iconName
    $b.Size = New-Object System.Drawing.Size($w,$h)
    Style-FlatButton $b $false $radius
    return $b
}

# v2.2.0 B1-r2: compact quarter-turn controls now use the user-supplied
# transparent PNG glyphs, embedded in the single-file script just like the
# established toolbar icons. Runtime tinting gives them a consistent Day/Dark
# appearance and lets the disabled state be unmistakably greyed out.
function New-RotateButton([string]$iconName, [string]$tooltipText) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = ""
    $b.Image = Get-IconImage $iconName
    $b.Size = New-Object System.Drawing.Size(38,38)
    $b.Enabled = $false
    Style-FlatButton $b $false 10
    $script:appToolTip.SetToolTip($b, $tooltipText)
    return $b
}

# The custom rounded-button painter draws icons itself, so WinForms' normal
# disabled greying is not visible. B1-r3 keeps Rotate/Previous/Next as clean
# icon-only controls with no visible tile/border; their glyph alone changes
# between normal and deliberately muted disabled colours. Play/Pause keeps its
# accented circular treatment.
function Update-TransportButtonVisuals {
    if (-not $btnRotateCCW -or -not $btnRotateCW -or -not $btnPrevFrame -or
        -not $btnNextFrame -or -not $btnPlayPause) { return }

    $disabledBack = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(55,58,65)
    } else {
        [System.Drawing.Color]::FromArgb(222,227,230)
    }
    $disabledBorder = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(88,93,103)
    } else {
        [System.Drawing.Color]::FromArgb(197,205,210)
    }
    $disabledIcon = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(142,149,159)
    } else {
        [System.Drawing.Color]::FromArgb(148,158,166)
    }

    foreach ($entry in @(
        @{ Button = $btnRotateCCW; Icon = "rotate_ccw" },
        @{ Button = $btnPrevFrame; Icon = "previous_frame" },
        @{ Button = $btnNextFrame; Icon = "next_frame" },
        @{ Button = $btnRotateCW; Icon = "rotate_cw" }
    )) {
        $b = $entry.Button
        # Match the parent transport row so there is no visible square/rounded
        # tile behind these four glyphs. Disabled state remains obvious through
        # the lower-contrast icon itself.
        $b.BackColor = if ($b.Parent) { $b.Parent.BackColor } else { $script:cPanelCurrent }
        # WinForms ButtonBase does not permit Transparent BorderColor.
        # Make these controls genuinely chrome-free by disabling the native
        # flat border, while matching the painter's border colour to the
        # surrounding row so the custom rounded painter also has nothing
        # visibly distinct to draw.
        $b.FlatAppearance.BorderSize = 0
        $b.FlatAppearance.BorderColor = $b.BackColor
        if ($b.Enabled) {
            $b.Image = Get-ThemedIconImage $entry.Icon $script:cTextCurrent
        }
        else {
            $b.Image = Get-ThemedIconImage $entry.Icon $disabledIcon
        }
        $b.Invalidate()
    }

    $playIconName = if ($script:isPlaying) { "pause" } else { "play" }
    if ($btnPlayPause.Enabled) {
        $btnPlayPause.BackColor = $script:cAccentCurrent
        $btnPlayPause.FlatAppearance.BorderColor = $script:cAccentCurrent
        $btnPlayPause.Image = Get-ThemedIconImage $playIconName ([System.Drawing.Color]::White)
    }
    else {
        $btnPlayPause.BackColor = $disabledBack
        $btnPlayPause.FlatAppearance.BorderColor = $disabledBorder
        $btnPlayPause.Image = Get-ThemedIconImage $playIconName $disabledIcon
    }
    $btnPlayPause.Invalidate()
}

# Unified redaction/playback control row: Begin Redaction - Rotate CCW -
# Previous Frame - Play/Pause - Next Frame - Rotate CW - End Redaction, with
# embedded user-supplied transport/rotation artwork and explicit disabled-state
# greying for controls that are unavailable,
# Cancel Redaction right-justified on the same row. Play/Pause is centered
# under the preview;
# Begin/Prev/Next/End cluster symmetrically around it - the X positions
# below are placeholders, recomputed to stay centered on every resize by
# Update-PolishedLayout (WinForms anchoring alone can't express "centered").
$btnStartRedaction = New-Object System.Windows.Forms.Button
$btnStartRedaction.Text = "Begin Redaction"
$btnStartRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnStartRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnStartRedaction.Enabled = $false
$btnStartRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnStartRedaction $true
$bottom.Controls.Add($btnStartRedaction)

$btnAddRedaction = New-Object System.Windows.Forms.Button
$btnAddRedaction.Text = "Create Redaction"
$btnAddRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnAddRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnAddRedaction.Enabled = $false
$btnAddRedaction.Visible = $false
$btnAddRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnAddRedaction $true
$bottom.Controls.Add($btnAddRedaction)

$btnRotateCCW = New-RotateButton "rotate_ccw" "Rotate 90° anticlockwise"
$bottom.Controls.Add($btnRotateCCW)

$btnPrevFrame = New-IconButton "previous_frame" 44 44
$btnPrevFrame.Enabled = $false
$bottom.Controls.Add($btnPrevFrame)
$script:appToolTip.SetToolTip($btnPrevFrame, "Previous Frame")

$btnPlayPause = New-IconButton "play" 52 52 999   # large radius self-clamps to a perfect circle
$btnPlayPause.Enabled = $false
$bottom.Controls.Add($btnPlayPause)
$script:appToolTip.SetToolTip($btnPlayPause, "Play")

$btnNextFrame = New-IconButton "next_frame" 44 44
$btnNextFrame.Enabled = $false
$bottom.Controls.Add($btnNextFrame)
$script:appToolTip.SetToolTip($btnNextFrame, "Next Frame")

$btnRotateCW = New-RotateButton "rotate_cw" "Rotate 90° clockwise"
$bottom.Controls.Add($btnRotateCW)

$btnEndRedaction = New-Object System.Windows.Forms.Button
$btnEndRedaction.Text = "End Redaction"
$btnEndRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
$btnEndRedaction.Location = New-Object System.Drawing.Point(0,69)
$btnEndRedaction.Enabled = $false
$btnEndRedaction.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnEndRedaction
$bottom.Controls.Add($btnEndRedaction)

$btnCancelRedaction = New-Object System.Windows.Forms.Button
$btnCancelRedaction.Text = "Cancel Redaction"
$btnCancelRedaction.Location = New-Object System.Drawing.Point(560,69)
$btnCancelRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
# No Anchor here - Update-PolishedLayout repositions this button by hand on
# every resize (see the comment there for why trusting Anchor's own math
# caused it to overlap End Redaction / Next Frame).
$btnCancelRedaction.Enabled = $false
$btnCancelRedaction.Font = New-UIFont 8.2
Style-FlatButton $btnCancelRedaction
$bottom.Controls.Add($btnCancelRedaction)

# C1 Standard / Enhanced selector.
# Standard remains the default. Enhanced sits immediately before the existing
# Blur/Pixelation strength control and is visible only for those two modes.
# C1 evaluates Enhanced at strength 5 only, so the strength slider remains
# visible but disabled while Enhanced is checked.
$chkEnhanced = New-Object System.Windows.Forms.CheckBox
$chkEnhanced.Text = "Aggressive"
$chkEnhanced.Checked = $false
$chkEnhanced.Location = New-Object System.Drawing.Point(0,70)
$chkEnhanced.Size = New-Object System.Drawing.Size(88,24)
$chkEnhanced.Font = New-UIFont 8.4
$script:appToolTip.SetToolTip($chkEnhanced, "Aggressive - discards more source detail before applying the effect, making reconstruction more difficult. Unchecked uses Default mode.")
$bottom.Controls.Add($chkEnhanced)

$lblStrength = New-Object System.Windows.Forms.Label
$lblStrength.Text = "Blur Strength: 5"
$lblStrength.Location = New-Object System.Drawing.Point(94,62)
$lblStrength.Size = New-Object System.Drawing.Size(170,18)
$lblStrength.Font = New-UIFont 8.0
$lblStrength.Tag = "muted"
$bottom.Controls.Add($lblStrength)

$sliderStrength = New-Object System.Windows.Forms.TrackBar
$sliderStrength.Minimum = 1
$sliderStrength.Maximum = 10
$sliderStrength.Value = $redactionStrength
$sliderStrength.TickStyle = [System.Windows.Forms.TickStyle]::None
$sliderStrength.AutoSize = $false
$sliderStrength.Location = New-Object System.Drawing.Point(94,79)
$sliderStrength.Size = New-Object System.Drawing.Size(170,28)
$script:appToolTip.SetToolTip($sliderStrength, "How strong the Blur/Pixelate effect is")
$bottom.Controls.Add($sliderStrength)
$sliderStrength.BringToFront()

$sliderStrength.Add_ValueChanged({
    $script:redactionStrength = $sliderStrength.Value
    $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
    if ($script:redactionEnhanced) { $lblStrength.Text = "$modeName Strength: 5 (Aggressive)" }
    else { $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)" }
    if ($isImageMode) { $picture.Invalidate() }
})

$chkEnhanced.Add_CheckedChanged({
    $script:redactionEnhanced = [bool]$chkEnhanced.Checked
    if ($script:redactionEnhanced -and $sliderStrength.Value -ne 5) { $sliderStrength.Value = 5 }
    Update-StrengthSliderVisibility
    Update-RedactionButtons
    if ($isImageMode) { $picture.Invalidate() }
})

function Update-StrengthSliderVisibility {
    $show = ($rbModeBlur.Checked -or $rbModePixelate.Checked) -and (-not $isImageMode -or $script:fillEnabled)
    $chkEnhanced.Visible = $show
    $lblStrength.Visible = $show
    $sliderStrength.Visible = $show
    $canEdit = $show -and -not $pendingRedaction
    $chkEnhanced.Enabled = $canEdit
    $sliderStrength.Enabled = $canEdit -and -not $script:redactionEnhanced
    if ($show) {
        $modeName = if ($rbModePixelate.Checked) { "Pixelation" } else { "Blur" }
        if ($script:redactionEnhanced) { $lblStrength.Text = "$modeName Strength: 5 (Aggressive)" }
        else { $lblStrength.Text = "$modeName Strength: $($sliderStrength.Value)" }
    }
    # D5b-r3: the transport cluster reserves more left-side room while these
    # controls are visible. Reflow immediately when the mode/visibility changes
    # rather than waiting for a later window resize.
    if (Get-Command Update-PolishedLayout -ErrorAction SilentlyContinue) { Update-PolishedLayout }
}

# Coloured Box color picker: a clickable swatch showing the current
# redaction color, plus an eyedropper button that samples a color straight
# from the loaded frame. Occupies the exact same row position as the
# Blur/Pixelate strength controls above, and the two are mutually exclusive
# (Update-StrengthSliderVisibility / Update-ColorPickerVisibility) since only
# one style is ever selected at a time.
$lblColor = New-Object System.Windows.Forms.Label
$lblColor.Text = "Box Colour"
$lblColor.Location = New-Object System.Drawing.Point(0,62)
$lblColor.Size = New-Object System.Drawing.Size(170,18)
$lblColor.Font = New-UIFont 8.0
$lblColor.Tag = "muted"
$bottom.Controls.Add($lblColor)

$swatchColor = New-Object System.Windows.Forms.Panel
$swatchColor.Location = New-Object System.Drawing.Point(0,79)
$swatchColor.Size = New-Object System.Drawing.Size(60,30)
$swatchColor.Cursor = [System.Windows.Forms.Cursors]::Hand
$swatchColor.BackColor = $redactionColor
$script:appToolTip.SetToolTip($swatchColor, "Click to choose the redaction box colour")
$bottom.Controls.Add($swatchColor)

# A thin border around the swatch so a black (or, in dark mode, a near-
# background-colored) swatch never visually disappears into its surroundings.
$swatchColor.Add_Paint({
    param($sender,$e)
    $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
    $pen = New-Object System.Drawing.Pen($borderColor, 1)
    $rect = New-Object System.Drawing.Rectangle(0,0,($sender.Width-1),($sender.Height-1))
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})

$btnEyedropper = New-Object System.Windows.Forms.Button
$btnEyedropper.Text = ""
$btnEyedropper.Size = New-Object System.Drawing.Size(30,30)
$btnEyedropper.Location = New-Object System.Drawing.Point(70,79)
Style-FlatButton $btnEyedropper
# This is an icon-only affordance beside the colour swatch, not a separate
# boxed field. Suppress the rounded-button outline so its left border cannot
# appear as a stray vertical separator between the swatch and eyedropper.
$btnEyedropper.FlatAppearance.BorderSize = 0
$bottom.Controls.Add($btnEyedropper)
Register-ThemedIcon $btnEyedropper "eyedropper"
$script:appToolTip.SetToolTip($btnEyedropper, "Pick a colour from the loaded frame")

# Returns the redaction whose color the swatch/eyedropper should affect right
# now: the selected item in the Redactions list, if any and if it's a
# Coloured/Black box - otherwise $null, meaning "the default color used for
# the next new redaction" ($script:redactionColor) applies instead. This is
# how scrubbing to an existing redaction and selecting it in the list lets
# the user recolor that specific box, on any frame it appears on.
function Get-ColorEditTarget {
    if ($lvRedactions.SelectedIndices.Count -eq 0) { return $null }
    $idx = $lvRedactions.SelectedIndices[0]
    if ($idx -lt 0 -or $idx -ge $redactions.Count) { return $null }
    $sel = $redactions[$idx]
    if ($sel.Mode -ne "Black box") { return $null }
    return $sel
}

# Refreshes the swatch to show whichever color is currently "live" - the
# selected existing Coloured box redaction's own color if one is selected,
# otherwise the default color that will be baked into the next new redaction.
function Update-ColorSwatch {
    $target = Get-ColorEditTarget
    $c = if ($target) { Get-RedactionColor $target } else { $script:redactionColor }
    $swatchColor.BackColor = $c
}

# Applies a newly-picked color either to the selected existing redaction (if
# one is selected and it's a Coloured box) or to the default used for new
# redactions, then refreshes anything that shows it.
function Set-ActiveRedactionColor([System.Drawing.Color]$color) {
    $target = Get-ColorEditTarget
    if ($target) {
        $target.Color = $color
        $picture.Invalidate()
    }
    else {
        $script:redactionColor = $color
    }
    Update-ColorSwatch
}

# Shows/hides the color swatch+eyedropper for the currently selected style -
# called from Apply-Theme, which already re-runs on every Shape/Style
# CheckedChanged (see the foreach below) as well as at startup.
function Update-ColorPickerVisibility {
    $show = $rbModeBlack.Checked -and (-not $isImageMode -or $script:fillEnabled)
    $lblColor.Visible = $show
    $swatchColor.Visible = $show
    $btnEyedropper.Visible = $show
    if ($show) { Update-ColorSwatch }
}

$swatchColor.Add_Click({
    $dlg = New-Object System.Windows.Forms.ColorDialog
    $dlg.FullOpen = $true
    $dlg.Color = $swatchColor.BackColor
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        Set-ActiveRedactionColor $dlg.Color
    }
})

$btnEyedropper.Add_Click({
    if (-not $previewImage) { return }
    $script:eyedropperActive = -not $script:eyedropperActive
    if ($script:eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    } else {
        Update-PreviewCursor
    }
    Set-RedactionButtonColor $btnEyedropper $(if ($script:eyedropperActive) { "red" } else { "grey" })
})

$lblPending = New-Object System.Windows.Forms.Label
$lblPending.Text = "No redaction in progress."
$lblPending.TextAlign = "MiddleLeft"
# Compact status row: left-aligned with Box Colour / Ready. so panel
# collapse/restore cannot make the message appear to jump horizontally.
$lblPending.Location = New-Object System.Drawing.Point(0,114)
$lblPending.Size = New-Object System.Drawing.Size(690,16)
$lblPending.Anchor = "Top,Left,Right"
$lblPending.Font = New-UIFont 8.0
$lblPending.Tag = "muted"
$bottom.Controls.Add($lblPending)

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready."
$status.Location = New-Object System.Drawing.Point(0,132)
$status.Size = New-Object System.Drawing.Size(690,16)
$status.Anchor = "Top,Left,Right"
$status.Font = New-UIFont 8.2
$status.Tag = "muted"
$bottom.Controls.Add($status)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(0,150)
$progress.Size = New-Object System.Drawing.Size(690,5)
$progress.Anchor = "Top,Left,Right"
$progress.Style = "Marquee"
$progress.Visible = $false
$bottom.Controls.Add($progress)

# Video preview between file card and timeline
$previewPanel = New-Object System.Windows.Forms.Panel
$previewPanel.Dock = "Fill"
$previewPanel.Padding = New-Object System.Windows.Forms.Padding(0)
$previewPanel.Tag = "workspace"
$center.Controls.Add($previewPanel)
$previewPanel.BringToFront()

$pictureFrame = New-Object System.Windows.Forms.Panel
$pictureFrame.Dock = "Fill"
$pictureFrame.Padding = New-Object System.Windows.Forms.Padding(1)
$pictureFrame.Tag = "previewframe"
$previewPanel.Controls.Add($pictureFrame)

$picture = New-Object System.Windows.Forms.PictureBox
$picture.Dock = "Fill"
$picture.BackColor = [System.Drawing.Color]::FromArgb(22,26,32)
$picture.SizeMode = "Normal"
# PictureBox is normally non-selectable. Slice 4 makes it programmatically
# focusable (without putting it in normal Tab navigation) so WinForms routes
# MouseWheel messages to the preview while the Zoom tool is active.
$picture.TabStop = $false
try {
    $setStyleMethod = [System.Windows.Forms.Control].GetMethod(
        "SetStyle",
        [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic
    )
    if ($setStyleMethod) {
        [void]$setStyleMethod.Invoke($picture, @([System.Windows.Forms.ControlStyles]::Selectable, $true))
    }
} catch {}
$pictureFrame.Controls.Add($picture)

# Slice 4 visible zoom HUD. It is a child of the preview itself so it remains
# pinned inside the viewport regardless of the Redaction Area width. The HUD
# stays hidden until media is actually loaded.
$zoomHud = New-Object System.Windows.Forms.Panel
$zoomHud.Size = New-Object System.Drawing.Size(144,56)
$zoomHud.Visible = $false
$zoomHud.Tag = "zoomhud"
$picture.Controls.Add($zoomHud)

$lblZoomIndicator = New-Object System.Windows.Forms.Label
$lblZoomIndicator.Text = "Fit"
$lblZoomIndicator.TextAlign = "MiddleCenter"
$lblZoomIndicator.Font = New-UIFont 8.0 ([System.Drawing.FontStyle]::Bold)
$lblZoomIndicator.Location = New-Object System.Drawing.Point(4,2)
$lblZoomIndicator.Size = New-Object System.Drawing.Size(136,18)
$lblZoomIndicator.Tag = "zoomindicator"
$zoomHud.Controls.Add($lblZoomIndicator)

$btnZoomOut = New-Object System.Windows.Forms.Button
$btnZoomOut.Text = [char]0x2212
$btnZoomOut.Location = New-Object System.Drawing.Point(4,22)
$btnZoomOut.Size = New-Object System.Drawing.Size(32,28)
$btnZoomOut.Font = New-UIFont 12.0 ([System.Drawing.FontStyle]::Regular)
Style-FlatButton $btnZoomOut $false 7
$zoomHud.Controls.Add($btnZoomOut)
$script:appToolTip.SetToolTip($btnZoomOut, "Zoom out")

$btnZoomFit = New-Object System.Windows.Forms.Button
$btnZoomFit.Text = "Fit"
$btnZoomFit.Location = New-Object System.Drawing.Point(40,22)
$btnZoomFit.Size = New-Object System.Drawing.Size(64,28)
$btnZoomFit.Font = New-UIFont 8.2 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnZoomFit $false 7
$zoomHud.Controls.Add($btnZoomFit)
$script:appToolTip.SetToolTip($btnZoomFit, "Fit media to preview")

$btnZoomIn = New-Object System.Windows.Forms.Button
$btnZoomIn.Text = "+"
$btnZoomIn.Location = New-Object System.Drawing.Point(108,22)
$btnZoomIn.Size = New-Object System.Drawing.Size(32,28)
$btnZoomIn.Font = New-UIFont 12.0 ([System.Drawing.FontStyle]::Regular)
Style-FlatButton $btnZoomIn $false 7
$zoomHud.Controls.Add($btnZoomIn)
$script:appToolTip.SetToolTip($btnZoomIn, "Zoom in")

# Slice 3 r2 requires a full synchronous repaint whenever the preview viewport
# changes size, otherwise stale pixels from the old Fit rectangle can survive.
# Slice 4 attaches that Resize handler later, after its Zoom HUD helper functions
# have been defined, so construction-time resize events cannot call undefined
# PowerShell functions.

# $btnOpen now lives in the header ($top) itself - see its creation right
# after $lblAppSub, further up this file - rather than floating over the
# preview, so it's visible before any file is loaded and stays out of the
# video's own display area.

# RIGHT PANEL --------------------------------------------------------
# A host panel owns the inspector so the entire Redaction Area column can
# collapse to a slim restore strip without destroying/recreating any controls.
$rightHost = New-Object System.Windows.Forms.Panel
$rightHost.Dock = "Fill"
$rightHost.Padding = New-Object System.Windows.Forms.Padding(0)
$rightHost.Tag = "inspectorhost"
$main.Controls.Add($rightHost,2,0)

$right = New-Object System.Windows.Forms.Panel
$right.Dock = "Fill"
$right.Padding = New-Object System.Windows.Forms.Padding(10,8,10,8)
$right.AutoScroll = $true
$right.Tag = "inspector"
$rightHost.Controls.Add($right)

# One persistent panel-toggle button lives in the host rather than having
# separate expand/collapse buttons in different parents. The right edge of
# $rightHost never moves when its column changes width, so pinning one button
# to that edge keeps the control at the exact same screen position whether
# the Redaction Area is open or collapsed.
$btnRightPanelToggle = New-Object System.Windows.Forms.Button
$btnRightPanelToggle.Text = ""
$btnRightPanelToggle.Size = New-Object System.Drawing.Size($script:UiIconButtonSize,$script:UiIconButtonSize)
$btnRightPanelToggle.Tag = "button"
$btnRightPanelToggle.Image = Get-ThemedIconImage "panel_expand" ([System.Drawing.Color]::FromArgb(32,32,32))
Style-FlatButton $btnRightPanelToggle $false 8
$rightHost.Controls.Add($btnRightPanelToggle)
$btnRightPanelToggle.BringToFront()
$script:appToolTip.SetToolTip($btnRightPanelToggle, "Collapse Redaction Area")

# v1.4 UI preview opens with Redaction Area collapsed by default.
$script:rightPanelCollapsed = $true
$right.Visible = $false

function Position-RightPanelToggle {
    if (-not $btnRightPanelToggle -or -not $rightHost) { return }
    $x = [Math]::Max(0, $rightHost.ClientSize.Width - $btnRightPanelToggle.Width - $script:UiGap - $(if($right.Visible -and $right.VerticalScroll.Visible){[Windows.Forms.SystemInformation]::VerticalScrollBarWidth}else{0}))
    $btnRightPanelToggle.Location = New-Object System.Drawing.Point($x,$script:UiGap)
    $btnRightPanelToggle.BringToFront()
}

function Update-RightPanelToggleAppearance {
    $iconColor = if ($script:isDarkMode) {
        [System.Drawing.Color]::FromArgb(240,240,240)
    } else {
        [System.Drawing.Color]::FromArgb(32,32,32)
    }
    if ($script:rightPanelCollapsed) {
        # When collapsed, show the icon that indicates opening/restoring the pane.
        $btnRightPanelToggle.Image = Get-ThemedIconImage "panel_collapse" $iconColor
        $script:appToolTip.SetToolTip($btnRightPanelToggle, "Restore Redaction Area")
    }
    else {
        # When open, show the icon that indicates collapsing/hiding the pane.
        $btnRightPanelToggle.Image = Get-ThemedIconImage "panel_expand" $iconColor
        $script:appToolTip.SetToolTip($btnRightPanelToggle, "Collapse Redaction Area")
    }
    $btnRightPanelToggle.Invalidate()
}

$rightHost.Add_Resize({
    Position-RightPanelToggle
})

function Set-RightPanelCollapsed([bool]$collapsed) {
    $script:rightPanelCollapsed = $collapsed
    $right.Visible = -not $collapsed
    if ($collapsed) {
        $main.ColumnStyles[2].Width = $script:InspectorCollapsedWidth
    }
    else {
        $main.ColumnStyles[2].Width = $script:InspectorExpandedWidth
    }

    # Perform the table-layout change first, then place the persistent toggle
    # against the host's final right edge. The button therefore never jumps
    # sideways when the column collapses/restores.
    $form.PerformLayout()
    Update-PolishedLayout
    Position-RightPanelToggle
    Update-RightPanelToggleAppearance
    if($lblDeleteCapability){Update-InspectorSectionLayout}

    # The timeline controls are manually resized by Update-PolishedLayout.
    # Invalidating the whole bottom region (children included) is important:
    # when a child shrinks, pixels from its OLD bounds otherwise remain on the
    # newly-exposed parent surface until some unrelated repaint occurs. Those
    # stale pixels were the "randomly redrawing" redaction-line artefacts seen
    # in the UI-preview test recording.
    $bottom.Invalidate($true)
    $seekBar.Invalidate()
    $scrubberMarkers.Invalidate()
    if ($script:floatingTextEditorVisible) { Update-FloatingTextEditorPosition }
    $picture.Invalidate()
}

$btnRightPanelToggle.Add_Click({
    Set-RightPanelCollapsed (-not $script:rightPanelCollapsed)
})

# Keep top-level geometry deterministic. WinForms Dock ordering can otherwise
# let a Fill control occupy the header area depending on z-order.
function Update-PolishedLayout {
    $topH = $script:HeaderHeight
    $headerH = $topH

    $top.Location = New-Object System.Drawing.Point(0,0)
    $top.Size = New-Object System.Drawing.Size($form.ClientSize.Width,$topH)

    # Keep the header action icons on the same UiGap edge grid as the
    # Redaction Area collapse/restore button.
    $themeX = [Math]::Max(0, $form.ClientSize.Width - $script:UiGap - $btnTheme.Width)
    $btnTheme.Location = New-Object System.Drawing.Point($themeX,15)
    $infoX = [Math]::Max(0, $themeX - $script:UiGap - $btnInfo.Width)
    $btnInfo.Location = New-Object System.Drawing.Point($infoX,15)

    $clearX = [Math]::Max(0, $infoX - $script:UiGap - $btnClearScreen.Width)
    $btnClearScreen.Location = New-Object System.Drawing.Point($clearX,15)

    # File labels stretch only through the remaining header space.
    $fileInfoW = [Math]::Max(60, $clearX - $lblFile.Left - 10)
    $lblFile.Size = New-Object System.Drawing.Size($fileInfoW,22)
    $lblHint.Size = New-Object System.Drawing.Size($fileInfoW,20)

    $main.Location = New-Object System.Drawing.Point(0,$headerH)
    $main.Size = New-Object System.Drawing.Size(
        $form.ClientSize.Width,
        [Math]::Max(1, $form.ClientSize.Height - $headerH)
    )

    # Center the transport/redaction cluster in the space between the
    # left-side colour/strength utility and the right-side Cancel/Export pair.
    $rowW = $bottom.ClientSize.Width
    if ($rowW -gt 0) {
        $oldSeekWidth = $seekBar.Width
        $oldMarkerWidth = $scrubberMarkers.Width
        $seekBar.Width = $rowW
        $scrubberMarkers.Width = [Math]::Max(0, $rowW - 20)

        if ($oldSeekWidth -ne $seekBar.Width -or $oldMarkerWidth -ne $scrubberMarkers.Width) {
            $bottom.Invalidate($true)
            $seekBar.Invalidate()
            $scrubberMarkers.Invalidate()
        }

        $gap = 10
        $wBeginEnd = $script:CompactButtonWidth
        $wRotate = 38
        $wPrevNext = 44
        $wPlay = 52
        $totalW = ($wBeginEnd * 2) + ($wRotate * 2) + ($wPrevNext * 2) + $wPlay + ($gap * 6)

        # The two compact action buttons live flush-right, Export immediately
        # to the right of Cancel, using the same UiGap edge spacing. Export is
        $cancelW = $script:CompactButtonWidth
        $exportW = $script:ExportButtonWidth
        $actionGap = $script:UiGap
        $copySpace=if($btnCopyImage -and $btnCopyImage.Visible){$script:CompactButtonHeight+$actionGap}else{0};$exportX = [Math]::Max(0, $rowW - $script:UiGap - $exportW-$copySpace)
        $cancelX = [Math]::Max(0, $exportX - $actionGap - $cancelW)

        # wider than the other compact action buttons so its label remains on one line.
        # Reserve enough room at the left for the colour picker or strength
        # slider, then center the transport cluster in the remaining middle.
        $clusterZoneLeft = if (($rbModeBlur.Checked -or $rbModePixelate.Checked) -and (-not $isImageMode -or $script:fillEnabled)) { 280 } else { 180 }
        $clusterZoneRight = [Math]::Max($clusterZoneLeft, $cancelX - $gap)
        $clusterZoneW = [Math]::Max(0, $clusterZoneRight - $clusterZoneLeft)
        $x = $clusterZoneLeft + [Math]::Max(0, [int](($clusterZoneW - $totalW) / 2))

        $rowTop = 58
        $yPlay = $rowTop
        $yPrevNext = $rowTop + [int](($wPlay - $wPrevNext) / 2)
        $yCompact = $rowTop + [int](($wPlay - $script:CompactButtonHeight) / 2)

        $btnStartRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)
        $btnAddRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)
        $x += $wBeginEnd + $gap

        $btnRotateCCW.Location = New-Object System.Drawing.Point($x,($rowTop + [int](($wPlay - $wRotate) / 2)))
        $x += $wRotate + $gap

        $btnPrevFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $btnPlayPause.Location = New-Object System.Drawing.Point($x,$yPlay)
        $x += $wPlay + $gap

        $btnNextFrame.Location = New-Object System.Drawing.Point($x,$yPrevNext)
        $x += $wPrevNext + $gap

        $btnRotateCW.Location = New-Object System.Drawing.Point($x,($rowTop + [int](($wPlay - $wRotate) / 2)))
        $x += $wRotate + $gap

        $btnEndRedaction.Location = New-Object System.Drawing.Point($x,$yCompact)

        $btnCancelRedaction.Location = New-Object System.Drawing.Point($cancelX,$yCompact)
        $btnExport.Location = New-Object System.Drawing.Point($exportX,$yCompact)
        if($btnCopyImage){$btnCopyImage.Location=[Drawing.Point]::new($exportX+$exportW+$actionGap,$yCompact)}
    }
}

$form.Add_SizeChanged({
    Update-PolishedLayout
})

$form.Add_Shown({
    # Start compact: Redaction Area is collapsed by default in v1.4.
    Set-RightPanelCollapsed $true
    Update-PolishedLayout
    $right.AutoScrollPosition = New-Object System.Drawing.Point(0,0)
    $form.ActiveControl = $btnOpen
})

$lblRedactionAreaTitle = Add-SectionTitle $right "Redaction Area" 0 $script:UiGap 280

# The Redaction Area collapse/restore control is hosted by $rightHost above.
# Keeping a single persistent button there prevents it moving when this panel
# is hidden and lets the supplied panel-direction glyphs remain easy to see.

# Redaction Area: a row of 4 small read-only "chip" fields (X/Y/W/H),
# matching the mockup's numeric-field look, shown whenever there's a
# concrete rectangle/bounding-box selection. $lblSelStatus (free text)
# shares the exact same bounds for the cases that aren't a plain rect --
# "no selection yet" and the in-progress freeform hints -- and the two
# are toggled via Update-SelectionFields so only one is visible at a time.
$selFieldsPanel = New-Object System.Windows.Forms.Panel
$selFieldsPanel.Location = New-Object System.Drawing.Point(0,34)
$selFieldsPanel.Size = New-Object System.Drawing.Size(325,34)
$selFieldsPanel.Visible = $false
$right.Controls.Add($selFieldsPanel)

$lblFieldX = New-MiniField $selFieldsPanel "X" 0 78
$lblFieldY = New-MiniField $selFieldsPanel "Y" 82 78
$lblFieldW = New-MiniField $selFieldsPanel "W" 164 78
$lblFieldH = New-MiniField $selFieldsPanel "H" 246 79

$lblSelStatus = New-Object System.Windows.Forms.Label
$lblSelStatus.Text = "Selection: none"
$lblSelStatus.Location = New-Object System.Drawing.Point(0,34)
$lblSelStatus.Size = New-Object System.Drawing.Size(325,34)
$lblSelStatus.Font = New-UIFont 8.2
$lblSelStatus.Tag = "muted"
$right.Controls.Add($lblSelStatus)

# Shows the X/Y/W/H chips for a concrete rect ($vr non-null, any tool
# mode -- Selection-To-VideoRect / the polygon-bounds equivalent both
# return a plain rect with .X/.Y/.W/.H), otherwise falls back to the
# free-text status label (e.g. "Selection: none", freeform-in-progress
# hints) with whatever $statusText the caller supplies.
function Update-SelectionFields($vr, [string]$statusText = "Selection: none") {
    if ($vr) {
        $lblFieldX.Text = "$($vr.X)"
        $lblFieldY.Text = "$($vr.Y)"
        $lblFieldW.Text = "$($vr.W)"
        $lblFieldH.Text = "$($vr.H)"
        $selFieldsPanel.Visible = $true
        $lblSelStatus.Visible = $false
    }
    else {
        $lblFieldX.Text = "--"
        $lblFieldY.Text = "--"
        $lblFieldW.Text = "--"
        $lblFieldH.Text = "--"
        $selFieldsPanel.Visible = $false
        $lblSelStatus.Text = $statusText
        $lblSelStatus.Visible = $true
    }
}

$lblToolHint = New-Object System.Windows.Forms.Label
$lblToolHint.Text = "Freeform: click points, then click the yellow start point to close."
$lblToolHint.Location = New-Object System.Drawing.Point(0,68)
$lblToolHint.Size = New-Object System.Drawing.Size(325,28)
$lblToolHint.Font = New-UIFont 8.2
$lblToolHint.Tag = "muted"
$right.Controls.Add($lblToolHint)

$lblSecurityNote = New-Object System.Windows.Forms.Label
$lblSecurityNote.Location = New-Object System.Drawing.Point(0,96)
$lblSecurityNote.Size = New-Object System.Drawing.Size(325,32)
$lblSecurityNote.Font = New-UIFont 8.2
$lblSecurityNote.Tag = "muted"
$right.Controls.Add($lblSecurityNote)

$lblBufferNote = New-Object System.Windows.Forms.Label
$lblBufferNote.Text = "Every redaction is padded automatically by $BUFFER_FRAMES frames before and after the marked range."
$lblBufferNote.Location = New-Object System.Drawing.Point(0,128)
$lblBufferNote.Size = New-Object System.Drawing.Size(325,48)
$lblBufferNote.Font = New-UIFont 8.2
$lblBufferNote.Tag = "muted"
$right.Controls.Add($lblBufferNote)

function Update-SecurityModeNote {
    if ($isImageMode -and -not $script:fillEnabled) {
        $lblSecurityNote.Text = "Annotation only: the outline is visual markup and does not redact or obscure source pixels."
    }
    elseif ($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) {
        $lblSecurityNote.Text = "Managed policy: Blur and Pixelate are disabled. Use Coloured Box for secure redaction."
    }
    elseif ($rbModeBlack.Checked) {
        $lblSecurityNote.Text = "Secure Redaction: an opaque Coloured Box replaces the selected source pixels."
    }
    else {
        $lblSecurityNote.Text = "Visual Obscuration: Blur/Pixelate are not guaranteed irreversible. Use an opaque Coloured Box for permanent removal."
    }
}

# Blur and Pixelate are useful visual-obscuration tools, but unlike an opaque
# Coloured Box they transform source pixels rather than replacing them. Warn
# when either mode is selected; the suppression checkbox is shared by both
# modes and lasts only for the current application session.
# Compact themed warning/consent dialog used by the Blur/Pixelate, audio,
# and network-location warnings. It deliberately follows stock MessageBox
# proportions much more closely than the earlier oversized custom forms,
# while retaining TinyRedactionTool theming and optional session suppression.
#
# Returns an object with:
#   Accepted   - primary action chosen
#   Suppress   - "Don't show again this session" checked
function Show-CompactWarningDialog(
    [string]$WindowTitle,
    [string]$Heading,
    [string]$Body,
    [string]$PrimaryText = "OK",
    [string]$SecondaryText = "",
    [bool]$ShowSuppression = $true,
    [string]$BoldToken = "",
    [bool]$SuppressionDefaultChecked = $false,
    [bool]$DefaultSecondary = $false
) {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(202,208,216) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }
    $cButton = if ($isDark) { [System.Drawing.Color]::FromArgb(71,75,84) } else { [System.Drawing.Color]::FromArgb(240,248,251) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(100,105,117) } else { [System.Drawing.Color]::FromArgb(190,209,218) }

    # Keep close to a stock WinForms MessageBox footprint. Height is derived
    # from the wrapped message so the longer network warnings grow only when
    # they genuinely need to.
    $dlgW = 450
    $margin = 14
    $iconW = 34
    $textX = $margin + $iconW + 10
    $textW = $dlgW - $textX - $margin

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $WindowTitle
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.Font = New-UIFont 8.7
    $dlg.AutoScaleMode = "Dpi"

    $icon = New-Object System.Windows.Forms.PictureBox
    $icon.Image = [System.Drawing.SystemIcons]::Warning.ToBitmap()
    $icon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $icon.Location = New-Object System.Drawing.Point($margin,16)
    $icon.Size = New-Object System.Drawing.Size($iconW,$iconW)
    $dlg.Controls.Add($icon)

    # PowerShell variable names are case-insensitive. Do not call this control
    # $heading because the function parameter is $Heading; doing so coerces the
    # Label into the typed string parameter and makes .Text assignments fail.
    $headingLabel = New-Object System.Windows.Forms.Label
    $headingLabel.Text = $Heading
    $headingLabel.Font = New-UIFont 9.0 ([System.Drawing.FontStyle]::Bold)
    $headingLabel.ForeColor = $cText
    $headingLabel.BackColor = [System.Drawing.Color]::Transparent
    $headingLabel.Location = New-Object System.Drawing.Point($textX,14)
    $headingLabel.Size = New-Object System.Drawing.Size($textW,20)
    $dlg.Controls.Add($headingLabel)

    $boldMessageFont = $null
    if ([string]::IsNullOrEmpty($BoldToken)) {
        $message = New-Object System.Windows.Forms.Label
        $message.Text = $Body
        $message.Font = New-UIFont 8.4
        $message.ForeColor = $cMuted
        $message.BackColor = [System.Drawing.Color]::Transparent
        $message.AutoSize = $true
        $message.MaximumSize = New-Object System.Drawing.Size($textW,0)

        # Let WinForms measure its own wrapped text, then freeze the size. This is
        # more reliable than hand-counting lines across DPI/font combinations.
        $pref = $message.GetPreferredSize((New-Object System.Drawing.Size($textW,0)))
        $message.AutoSize = $false
        $message.Location = New-Object System.Drawing.Point($textX,38)
        $message.Size = New-Object System.Drawing.Size($textW,([Math]::Max(36,$pref.Height + 2)))
    }
    else {
        # A Label cannot mix font weights. Use a borderless read-only RichTextBox
        # only for dialogs that explicitly request an inline bold token.
        $message = New-Object System.Windows.Forms.RichTextBox
        $message.Text = $Body
        $message.Font = New-UIFont 8.4
        $message.ForeColor = $cMuted
        $message.BackColor = $cBg
        $message.BorderStyle = [System.Windows.Forms.BorderStyle]::None
        $message.ReadOnly = $true
        $message.DetectUrls = $false
        $message.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::None
        $message.TabStop = $false
        $message.ShortcutsEnabled = $false

        $measureFlags = [System.Windows.Forms.TextFormatFlags]::WordBreak -bor [System.Windows.Forms.TextFormatFlags]::TextBoxControl
        $measured = [System.Windows.Forms.TextRenderer]::MeasureText(
            $Body,
            $message.Font,
            (New-Object System.Drawing.Size($textW,10000)),
            $measureFlags
        )
        $message.Location = New-Object System.Drawing.Point($textX,38)
        $message.Size = New-Object System.Drawing.Size($textW,([Math]::Max(36,$measured.Height + 6)))

        $tokenIndex = $Body.IndexOf($BoldToken, [System.StringComparison]::Ordinal)
        if ($tokenIndex -ge 0) {
            $boldMessageFont = New-Object System.Drawing.Font(
                $message.Font,
                [System.Drawing.FontStyle]::Bold
            )
            $message.Select($tokenIndex, $BoldToken.Length)
            $message.SelectionFont = $boldMessageFont
            $message.Select(0,0)
        }
    }

    $dlg.Controls.Add($message)

    $y = $message.Bottom + 6

    $dontShow = $null
    if ($ShowSuppression) {
        $dontShow = New-Object System.Windows.Forms.CheckBox
        $dontShow.Text = "Don't show again this session"
        $dontShow.Checked = $SuppressionDefaultChecked
        $dontShow.Font = New-UIFont 8.2
        $dontShow.ForeColor = $cText
        $dontShow.BackColor = $cBg
        $dontShow.Location = New-Object System.Drawing.Point($textX,$y)
        $dontShow.Size = New-Object System.Drawing.Size(235,22)
        $dlg.Controls.Add($dontShow)
        $y = $dontShow.Bottom + 8
    }
    else {
        $y += 4
    }

    $buttonH = 28
    $primaryW = if ($PrimaryText.Length -gt 8) { 88 } else { 74 }
    $secondaryW = if ($SecondaryText.Length -gt 8) { 88 } else { 74 }
    $buttonGap = 8

    $primary = New-Object System.Windows.Forms.Button
    $primary.Text = $PrimaryText
    $primary.Size = New-Object System.Drawing.Size($primaryW,$buttonH)
    if ($DefaultSecondary -and -not [string]::IsNullOrWhiteSpace($SecondaryText)) {
        # Destructive confirmations put the destructive action on the left and
        # the safe/default action on the right, matching the visible focus.
        $primary.Location = New-Object System.Drawing.Point(($dlgW - $margin - $secondaryW - $buttonGap - $primaryW),$y)
    }
    else {
        $primary.Location = New-Object System.Drawing.Point(($dlgW - $margin - $primaryW),$y)
    }
    $primary.DialogResult = [System.Windows.Forms.DialogResult]::OK
    if ($DefaultSecondary -and -not [string]::IsNullOrWhiteSpace($SecondaryText)) {
        Style-FlatButton $primary $false 7
        $primary.BackColor = $cButton
        $primary.ForeColor = $cText
        $primary.FlatAppearance.BorderSize = 1
        $primary.FlatAppearance.BorderColor = $cBorder
    }
    else {
        Style-FlatButton $primary $true 7
        $primary.BackColor = $cAccent
        $primary.ForeColor = [System.Drawing.Color]::White
        $primary.FlatAppearance.BorderColor = $cAccent
    }
    $dlg.Controls.Add($primary)

    $secondary = $null
    if (-not [string]::IsNullOrWhiteSpace($SecondaryText)) {
        $secondary = New-Object System.Windows.Forms.Button
        $secondary.Text = $SecondaryText
        $secondary.Size = New-Object System.Drawing.Size($secondaryW,$buttonH)
        if ($DefaultSecondary) {
            $secondary.Location = New-Object System.Drawing.Point(($dlgW - $margin - $secondaryW),$y)
            Style-FlatButton $secondary $true 7
            $secondary.BackColor = $cAccent
            $secondary.ForeColor = [System.Drawing.Color]::White
            $secondary.FlatAppearance.BorderColor = $cAccent
        }
        else {
            $secondary.Location = New-Object System.Drawing.Point(($primary.Left - $buttonGap - $secondaryW),$y)
            Style-FlatButton $secondary $false 7
            # Explicitly theme the secondary button so Enable-RoundedPaint draws
            # the complete rounded outline instead of exposing fragments of the
            # native WinForms flat-button border.
            $secondary.BackColor = $cButton
            $secondary.ForeColor = $cText
            $secondary.FlatAppearance.BorderSize = 1
            $secondary.FlatAppearance.BorderColor = $cBorder
        }
        $secondary.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $dlg.Controls.Add($secondary)
        $dlg.CancelButton = $secondary
    }
    else {
        $dlg.CancelButton = $primary
    }

    if ($DefaultSecondary -and $secondary) {
        $dlg.AcceptButton = $secondary
        $dlg.Add_Shown({ $secondary.Select() }.GetNewClosure())
    }
    else {
        $dlg.AcceptButton = $primary
    }
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgW,($primary.Bottom + 12))

    $result = $dlg.ShowDialog($form)
    $accepted = ($result -eq [System.Windows.Forms.DialogResult]::OK)
    $suppress = ($dontShow -and $dontShow.Checked)

    if ($icon.Image) { $icon.Image.Dispose() }
    $dlg.Dispose()
    if ($boldMessageFont) { $boldMessageFont.Dispose() }

    return [pscustomobject]@{
        Accepted = $accepted
        Suppress = $suppress
    }
}


# S1c: information/success companion to Show-CompactWarningDialog. The export
# and destructive-deletion success path now uses one coherent themed dialog
# family instead of alternating between stock MessageBox and custom forms.
function Show-CompactInformationDialog(
    [string]$WindowTitle,
    [string]$Heading,
    [string]$Body,
    [string]$ButtonText = "OK"
) {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(202,208,216) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }

    $dlgW = 450
    $margin = 14
    $iconW = 34
    $textX = $margin + $iconW + 10
    $textW = $dlgW - $textX - $margin

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = $WindowTitle
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.Font = New-UIFont 8.7
    $dlg.AutoScaleMode = "Dpi"

    $icon = New-Object System.Windows.Forms.PictureBox
    $icon.Image = [System.Drawing.SystemIcons]::Information.ToBitmap()
    $icon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $icon.Location = New-Object System.Drawing.Point($margin,16)
    $icon.Size = New-Object System.Drawing.Size($iconW,$iconW)
    $dlg.Controls.Add($icon)

    $headingLabel = New-Object System.Windows.Forms.Label
    $headingLabel.Text = $Heading
    $headingLabel.Font = New-UIFont 9.0 ([System.Drawing.FontStyle]::Bold)
    $headingLabel.ForeColor = $cText
    $headingLabel.BackColor = [System.Drawing.Color]::Transparent
    $headingLabel.Location = New-Object System.Drawing.Point($textX,14)
    $headingLabel.Size = New-Object System.Drawing.Size($textW,20)
    $dlg.Controls.Add($headingLabel)

    $message = New-Object System.Windows.Forms.Label
    $message.Text = $Body
    $message.Font = New-UIFont 8.4
    $message.ForeColor = $cMuted
    $message.BackColor = [System.Drawing.Color]::Transparent
    $message.AutoSize = $true
    $message.MaximumSize = New-Object System.Drawing.Size($textW,0)
    $pref = $message.GetPreferredSize((New-Object System.Drawing.Size($textW,0)))
    $message.AutoSize = $false
    $message.Location = New-Object System.Drawing.Point($textX,38)
    $message.Size = New-Object System.Drawing.Size($textW,([Math]::Max(36,$pref.Height + 2)))
    $dlg.Controls.Add($message)

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $ButtonText
    $button.Size = New-Object System.Drawing.Size(74,28)
    $button.Location = New-Object System.Drawing.Point(($dlgW - $margin - 74),($message.Bottom + 12))
    $button.DialogResult = [System.Windows.Forms.DialogResult]::OK
    Style-FlatButton $button $true 7
    $button.BackColor = $cAccent
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatAppearance.BorderColor = $cAccent
    $dlg.Controls.Add($button)
    $dlg.AcceptButton = $button
    $dlg.CancelButton = $button
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgW,($button.Bottom + 12))
    $dlg.Add_Shown({ $button.Select() }.GetNewClosure())

    [void]$dlg.ShowDialog($form)

    if ($icon.Image) { $icon.Image.Dispose() }
    $dlg.Dispose()
}

function Show-DeleteOriginalConfirmation($capability) {
    $body = "The export was completed successfully. Do you want to overwrite and delete the original file? This cannot be undone."
    if ($capability -and $capability.Class -eq 'BestEffortOverwrite') {
        $body += "`r`n`r`nThis storage may retain inaccessible internal copies even after the file is overwritten and deleted."
    }
    $result = Show-CompactWarningDialog `
        'Delete original file?' `
        'Delete original file?' `
        $body `
        'Proceed' `
        'No' `
        $false `
        '' `
        $false `
        $true
    return [bool]$result.Accepted
}

function Show-DeleteOriginalCountdown {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(202,208,216) } else { [System.Drawing.Color]::FromArgb(78,91,110) }
    $cButton = if ($isDark) { [System.Drawing.Color]::FromArgb(71,75,84) } else { [System.Drawing.Color]::FromArgb(240,248,251) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(100,105,117) } else { [System.Drawing.Color]::FromArgb(190,209,218) }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = 'Deletion countdown'
    $dlg.StartPosition = 'CenterParent'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.ClientSize = New-Object System.Drawing.Size(390,190)
    $dlg.AutoScaleMode = 'Dpi'

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Deletion will begin in'
    $label.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
    $label.ForeColor = $cText
    $label.TextAlign = 'MiddleCenter'
    $label.Location = New-Object System.Drawing.Point(20,18)
    $label.Size = New-Object System.Drawing.Size(350,28)
    $dlg.Controls.Add($label)

    $countLabel = New-Object System.Windows.Forms.Label
    $countLabel.Text = '5'
    $countLabel.Font = New-UIFont 28 ([System.Drawing.FontStyle]::Bold)
    $countLabel.ForeColor = $cText
    $countLabel.TextAlign = 'MiddleCenter'
    $countLabel.Location = New-Object System.Drawing.Point(20,48)
    $countLabel.Size = New-Object System.Drawing.Size(350,66)
    $dlg.Controls.Add($countLabel)

    $note = New-Object System.Windows.Forms.Label
    $note.Text = 'You can still cancel. No source data has been changed.'
    $note.Font = New-UIFont 8.2
    $note.ForeColor = $cMuted
    $note.TextAlign = 'MiddleCenter'
    $note.Location = New-Object System.Drawing.Point(20,112)
    $note.Size = New-Object System.Drawing.Size(350,26)
    $dlg.Controls.Add($note)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = 'Cancel'
    $cancel.Size = New-Object System.Drawing.Size(82,28)
    $cancel.Location = New-Object System.Drawing.Point(154,148)
    $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    Style-FlatButton $cancel $false 7
    $cancel.BackColor = $cButton
    $cancel.ForeColor = $cText
    $cancel.FlatAppearance.BorderColor = $cBorder
    $dlg.Controls.Add($cancel)
    $dlg.CancelButton = $cancel

    # Keep countdown state on the Form itself rather than in an event-local
    # PowerShell variable. Event-handler scopes can otherwise make the captured
    # integer appear to reset on each Timer tick (5 -> 4 -> 4 -> 4...).
    $dlg.Tag = 5
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $next = ([int]$dlg.Tag) - 1
        $dlg.Tag = $next
        if ($next -le 0) {
            $timer.Stop()
            $dlg.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $dlg.Close()
        }
        else {
            $countLabel.Text = [string]$next
        }
    }.GetNewClosure())
    $dlg.Add_Shown({ $cancel.Select(); $timer.Start() }.GetNewClosure())

    $result = $dlg.ShowDialog($form)
    $timer.Stop()
    $timer.Dispose()
    $dlg.Dispose()
    return ($result -eq [System.Windows.Forms.DialogResult]::OK)
}

function Show-DeleteOriginalProgressDialog {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(202,208,216) } else { [System.Drawing.Color]::FromArgb(78,91,110) }

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = 'Deleting original'
    $dlg.StartPosition = 'CenterParent'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ControlBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.ClientSize = New-Object System.Drawing.Size(430,164)
    $dlg.AutoScaleMode = 'Dpi'

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Preparing deletion...'
    $label.Font = New-UIFont 9.2 ([System.Drawing.FontStyle]::Bold)
    $label.ForeColor = $cText
    $label.TextAlign = 'MiddleCenter'
    $label.Location = New-Object System.Drawing.Point(20,18)
    $label.Size = New-Object System.Drawing.Size(390,30)
    $dlg.Controls.Add($label)

    $bar = New-Object System.Windows.Forms.ProgressBar
    $bar.Minimum = 0
    $bar.Maximum = 100
    $bar.Value = 0
    $bar.Style = 'Continuous'
    $bar.Location = New-Object System.Drawing.Point(30,60)
    $bar.Size = New-Object System.Drawing.Size(370,24)
    $dlg.Controls.Add($bar)

    $detail = New-Object System.Windows.Forms.Label
    $detail.Text = 'This step cannot be cancelled once overwriting has started.'
    $detail.Font = New-UIFont 8.2
    $detail.ForeColor = $cMuted
    $detail.TextAlign = 'MiddleCenter'
    $detail.Location = New-Object System.Drawing.Point(20,96)
    $detail.Size = New-Object System.Drawing.Size(390,40)
    $dlg.Controls.Add($detail)

    $state = [pscustomobject]@{
        Form = $dlg
        Label = $label
        Progress = $bar
        AllowClose = $false
    }
    $dlg.Add_FormClosing({
        param($sender,$e)
        if (-not $state.AllowClose) { $e.Cancel = $true }
    }.GetNewClosure())

    return $state
}

function Reset-LoadedSourceAfterDestructiveDeletion([string]$readyStatus) {
    Stop-Playback

    if ($previewImage) {
        try { $previewImage.Dispose() } catch {}
        $script:previewImage = $null
    }

    $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $null
    $script:isImageMode = $false
    $script:sourceDisplayWidth = 0
    $script:sourceDisplayHeight = 0
    $script:videoWidth = 0
    $script:videoHeight = 0
    $script:videoDuration = 0.0
    $script:fps = 0.0
    $script:totalFrames = 0
    $script:currentFrame = 0
    $script:previewSeconds = 0.0
    $script:loadedFrame = -1
    $script:frameTimeline = $null
    $script:sourceHasAudio = $false
    $script:userRotation = 0
    $chkAudio.Checked = $false

    $lblFile.Text = 'No Video | Image Loaded'
    $lblPosValue.Text = '00:00:00.000'
    $lblFrameCount.Text = 'Frame 0 / 0'
    $seekBar.Enabled = $false
    $seekBar.Invalidate()
    $btnPrevFrame.Enabled = $false
    $btnNextFrame.Enabled = $false
    $btnPlayPause.Enabled = $false
    $script:appToolTip.SetToolTip($btnPlayPause, 'Play')
    $btnOpen.Text = 'Open Video | Image'

    Reset-ViewportState
    Reset-RedactionState
    Reset-SourceDeletionState
    Apply-ModeLabels
    Update-TransportButtonVisuals
    Update-RedactionButtons
    Update-PreviewCursor
    if ($picture) { $picture.Invalidate() }
    $status.Text = if ([string]::IsNullOrWhiteSpace($readyStatus)) { 'Ready.' } else { $readyStatus }
}

function Invoke-S1bDeleteOriginalFlow {
    while ($true) {
        $check = Revalidate-SourceDeletionRequest
        if (-not $check.Ok) {
            $chkDeleteOriginal.Checked = $false
            $script:deleteOriginalRequested = $false
            $script:sourceDeletionCapability = $check.Capability
            Update-SourceDeletionUi
            [System.Windows.Forms.MessageBox]::Show(
                "Deletion could not begin. The original file was not changed.`r`n`r`n$($check.Error)",
                'Original file unchanged', 'OK', 'Information') | Out-Null
            return
        }

        if (-not (Show-DeleteOriginalConfirmation $check.Capability)) {
            $chkDeleteOriginal.Checked = $false
            $script:deleteOriginalRequested = $false
            return
        }

        if (-not (Show-DeleteOriginalCountdown)) {
            # Cancel remains fully non-destructive and returns to confirmation.
            continue
        }

        # Last non-destructive gate, immediately before the helper opens the
        # exact source for overwrite/delete and re-checks the handle identity.
        $finalCheck = Revalidate-SourceDeletionRequest
        if (-not $finalCheck.Ok) {
            $chkDeleteOriginal.Checked = $false
            $script:deleteOriginalRequested = $false
            $script:sourceDeletionCapability = $finalCheck.Capability
            Update-SourceDeletionUi
            [System.Windows.Forms.MessageBox]::Show(
                "Deletion could not begin. The original file was not changed.`r`n`r`n$($finalCheck.Error)",
                'Original file unchanged', 'OK', 'Information') | Out-Null
            return
        }

        $sourcePathForDeletion = [string]$videoPath
        $identity = $finalCheck.Capability.Inspection
        if (-not $identity -or -not $identity.Ok) {
            $chkDeleteOriginal.Checked = $false
            $script:deleteOriginalRequested = $false
            [System.Windows.Forms.MessageBox]::Show(
                'Deletion could not begin. The original file was not changed.',
                'Original file unchanged', 'OK', 'Information') | Out-Null
            return
        }

        $progressUi = Show-DeleteOriginalProgressDialog
        $progressUi.Form.Show($form)
        $progressUi.Form.BringToFront()
        [System.Windows.Forms.Application]::DoEvents()

        $progressScript = {
            param([long]$done,[long]$total,[string]$phase)
            try {
                $pct = if ($total -gt 0) {
                    [int][Math]::Max(0,[Math]::Min(100,[Math]::Round(([double]$done / [double]$total) * 100.0)))
                } else { 100 }
                $progressUi.Label.Text = if ([string]::IsNullOrWhiteSpace($phase)) { 'Deleting original...' } else { $phase }
                if ($progressUi.Progress.Value -ne $pct) { $progressUi.Progress.Value = $pct }
                [System.Windows.Forms.Application]::DoEvents()
            } catch {}
        }.GetNewClosure()
        $progressCallback = [System.Action[System.Int64,System.Int64,System.String]]$progressScript

        $execution = $null
        try {
            $form.Enabled = $false
            $execution = [SourceDeletionDestructiveV1]::Execute(
                $sourcePathForDeletion,
                [uint64]$identity.VolumeSerialNumber,
                [string]$identity.FileIdHex,
                [long]$identity.FileLength,
                $progressCallback)
        }
        catch {
            $execution = [pscustomobject]@{
                Started = $false
                OverwriteVerified = $false
                DeleteAttempted = $false
                Deleted = $false
                Error = $_.Exception.Message
            }
        }
        finally {
            $form.Enabled = $true
            if ($progressUi -and $progressUi.Form) {
                $progressUi.AllowClose = $true
                try { $progressUi.Form.Close() } catch {}
                try { $progressUi.Form.Dispose() } catch {}
            }
        }

        $chkDeleteOriginal.Checked = $false
        $script:deleteOriginalRequested = $false

        if (-not $execution -or -not $execution.Started) {
            # No destructive byte was written and delete was not attempted.
            $message = 'Deletion could not begin. The original file was not changed.'
            if ($execution -and -not [string]::IsNullOrWhiteSpace([string]$execution.Error)) {
                $message += "`r`n`r`n$($execution.Error)"
            }
            $script:sourceDeletionCapability = Get-SourceDeletionCapability $sourcePathForDeletion
            Update-SourceDeletionUi
            [System.Windows.Forms.MessageBox]::Show(
                $message, 'Original file unchanged', 'OK', 'Information') | Out-Null
            return
        }

        if (-not $execution.OverwriteVerified) {
            $message = 'Deletion could not complete. The original file may have been partially overwritten and may be unusable.'
            if (-not [string]::IsNullOrWhiteSpace([string]$execution.Error)) {
                $message += "`r`n`r`n$($execution.Error)"
            }
            [System.Windows.Forms.MessageBox]::Show(
                $message, 'Deletion incomplete', 'OK', 'Error') | Out-Null
            Reset-LoadedSourceAfterDestructiveDeletion 'Source deletion did not complete.'
            return
        }

        if (-not $execution.Deleted) {
            $message = 'The original file contents were overwritten and verified, but Windows could not remove the file.'
            if (-not [string]::IsNullOrWhiteSpace([string]$execution.Error)) {
                $message += "`r`n`r`n$($execution.Error)"
            }
            [System.Windows.Forms.MessageBox]::Show(
                $message, 'Original file not removed', 'OK', 'Warning') | Out-Null
            Reset-LoadedSourceAfterDestructiveDeletion 'Original contents were overwritten, but the file was not removed.'
            return
        }

        $successMessage = if ($finalCheck.Capability.Class -eq 'BestEffortOverwrite') {
            "The original file was overwritten, verified through Windows, and deleted.`r`n`r`nThis storage may retain inaccessible internal copies."
        } else {
            'The original file was overwritten, verified, and deleted.'
        }
        Show-CompactInformationDialog `
            'Original file deleted' `
            'Original file deleted' `
            $successMessage
        Reset-LoadedSourceAfterDestructiveDeletion 'Original file deleted. Ready.'
        return
    }
}

function Show-VisualObscurationWarning {
    if ($script:suppressVisualObscurationWarning -or $script:visualObscurationWarningOpen) { return }

    $script:visualObscurationWarningOpen = $true
    try {
        $visualObscurationBody = @'
Blur and Pixelate obscure content, but don't completely destroy it.

In testing, AI-based reconstruction attempts and a prolonged third-party tool attack failed to recover hidden information.
However, this does not guarantee that sensitive material can never be retrieved.

An "Aggressive" option is available. It first reduces the selected area to a low-detail representation before applying Blur or Pixelate.
This discards more source information and makes reconstruction more difficult, but may produce a coarser visual result.

For maximum obscuration, use Black Box or Coloured Box.
'@

        $result = Show-CompactWarningDialog `
            "Visual obscuration warning" `
            "Blur and Pixelate are unsecure redaction methods." `
            $visualObscurationBody `
            "OK" `
            "" `
            $true `
            "Aggressive" `
            $true

        if ($result.Suppress) {
            $script:suppressVisualObscurationWarning = $true
        }
    }
    finally {
        $script:visualObscurationWarningOpen = $false
    }
}


# G2a-G2d managed policies may strengthen the existing network warnings into a hard
# block. This dialog deliberately contains no source/destination path or filename.
function Show-ManagedNetworkLocationBlock([ValidateSet("Source","Destination")][string]$kind) {
    if ($kind -eq "Source") {
        $messageText = "The configured managed policy does not allow media to be opened from UNC or mapped-network locations. Choose a file on local storage."
    }
    else {
        $messageText = "The configured managed policy does not allow exports to UNC or mapped-network locations. Choose a local save location."
    }

    [System.Windows.Forms.MessageBox]::Show(
        $messageText,
        "Managed policy restriction",
        "OK",
        "Warning"
    ) | Out-Null
}

# Network-backed paths are allowed, but require informed consent rather than a
# hard block unless a validated managed policy explicitly strengthens that
# source/destination decision. The two warning classes have independent session
# suppression so accepting a network source does not also suppress export warnings.
function Show-NetworkLocationWarning([ValidateSet("Source","Destination")][string]$kind) {
    if ($kind -eq "Source") {
        if ($script:suppressNetworkSourceWarning) { return $true }
        $titleText = "Network/cloud source warning"
        $headingText = "Opening media from a network location"
        $messageText = "This file is on a network or cloud-synced location — opening it means its unredacted content will be transmitted over the network to this computer. If it must not leave a specific machine, copy it to a local folder first."
    }
    else {
        if ($script:suppressNetworkDestinationWarning) { return $true }
        $titleText = "Network/cloud save warning"
        $headingText = "Saving media to a network location"
        $messageText = "This save location is on a network or cloud-synced drive — the exported file will be transmitted over the network (and potentially to the cloud) once written here. Choose a local folder if this file must not leave this computer."
    }

    if ($script:networkLocationWarningOpen) { return $false }
    $script:networkLocationWarningOpen = $true

    try {
        $result = Show-CompactWarningDialog `
            $titleText `
            $headingText `
            $messageText `
            "Continue" `
            "Cancel" `
            $true

        if ($result.Accepted -and $result.Suppress) {
            if ($kind -eq "Source") {
                $script:suppressNetworkSourceWarning = $true
            }
            else {
                $script:suppressNetworkDestinationWarning = $true
            }
        }

        return $result.Accepted
    }
    finally {
        $script:networkLocationWarningOpen = $false
    }
}

# Shape (Rectangle/Oval/Freeform) and Style (Black box/Blur/Pixelate) are
# chosen from the vertical icon toolbar on the far left now - see
# New-ToolbarIconButton and the $rbRectangle/.../$rbModePixelate creation
# there. Only the pure mode-lookup helper lives here, since it's referenced
# from this file's redaction-building code regardless of where the
# controls it reads live.
function Get-SelectedMode {
    # G2d defence in depth: even if a disabled style control is manipulated
    # programmatically, managed policy cannot create a new Blur/Pixelate redaction.
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) { return "Black box" }
    if ($rbModeBlack.Checked) { return "Black box" }
    if ($rbModePixelate.Checked) { return "Pixelate" }
    return "Blur"
}

function Get-SelectedEnhanced {
    $mode = Get-SelectedMode
    return [bool]($script:redactionEnhanced -and ($mode -eq "Blur" -or $mode -eq "Pixelate"))
}

function Test-HasEnhancedRedactions {
    foreach ($r in $redactions) { if (Get-RedactionEnhanced $r) { return $true } }
    return $false
}

# Redactions created before the Coloured Box picker existed (or any created
# via a code path that didn't set one) won't have a Color field - fall back
# to black, matching the original hardcoded "black box" behavior exactly.
function Get-RedactionColor($r) {
    if ($r.Color) { return $r.Color }
    return [System.Drawing.Color]::Black
}

# Formats a color as ffmpeg's "0xRRGGBB" literal, used by drawbox's color=
# option in Build-RedactionFilterComplex.
function Get-FFmpegColorHex([System.Drawing.Color]$c) {
    return "0x{0:X2}{1:X2}{2:X2}" -f $c.R, $c.G, $c.B
}

$ruleAppearance = Add-Rule $right 0 184 325
$lblAppearanceTitle = Add-SectionTitle $right "Appearance" 0 198 330

# D1b: Fill and Outline are independent on still-image Rectangle/Oval/Freeform
# shapes. Fill-off + Outline-on is annotation-only and is never presented as a
# security redaction. Video keeps the proven v2.2 redaction-only behaviour.
$chkFill = New-Object System.Windows.Forms.CheckBox
$chkFill.Text = "Fill"
$chkFill.Checked = $script:fillEnabled
$chkFill.Location = New-Object System.Drawing.Point(0,228)
$chkFill.Size = New-Object System.Drawing.Size(68,24)
$chkFill.Font = New-UIFont 8.5
$right.Controls.Add($chkFill)
$script:appToolTip.SetToolTip($chkFill, "Apply the selected redaction/effect inside the shape")

$chkOutline = New-Object System.Windows.Forms.CheckBox
$chkOutline.Text = "Outline"
$chkOutline.Checked = $script:outlineEnabled
$chkOutline.Location = New-Object System.Drawing.Point(76,228)
$chkOutline.Size = New-Object System.Drawing.Size(82,24)
$chkOutline.Font = New-UIFont 8.5
$right.Controls.Add($chkOutline)
$script:appToolTip.SetToolTip($chkOutline, "Draw an annotation outline on top")

$lblOutlineWidth = New-Object System.Windows.Forms.Label
$lblOutlineWidth.Text = "Width"
$lblOutlineWidth.Location = New-Object System.Drawing.Point(164,232)
$lblOutlineWidth.Size = New-Object System.Drawing.Size(42,20)
$lblOutlineWidth.Font = New-UIFont 8.0
$lblOutlineWidth.Tag = "muted"
$right.Controls.Add($lblOutlineWidth)

$numOutlineWidth = New-Object System.Windows.Forms.NumericUpDown
$numOutlineWidth.Minimum = 1
$numOutlineWidth.Maximum = 20
$numOutlineWidth.DecimalPlaces = 0
$numOutlineWidth.Value = [decimal]$script:outlineWidth
$numOutlineWidth.Location = New-Object System.Drawing.Point(208,228)
$numOutlineWidth.Size = New-Object System.Drawing.Size(52,24)
$numOutlineWidth.Font = New-UIFont 8.5
$numOutlineWidth.Tag = "input"
$right.Controls.Add($numOutlineWidth)
$script:appToolTip.SetToolTip($numOutlineWidth, "Outline width in media pixels")

$swatchOutlineColor = New-Object System.Windows.Forms.Panel
$swatchOutlineColor.Location = New-Object System.Drawing.Point(272,228)
$swatchOutlineColor.Size = New-Object System.Drawing.Size(32,24)
$swatchOutlineColor.Cursor = [System.Windows.Forms.Cursors]::Hand
$swatchOutlineColor.BackColor = $script:outlineColor
$right.Controls.Add($swatchOutlineColor)
$script:appToolTip.SetToolTip($swatchOutlineColor, "Annotation / outline colour")
$swatchOutlineColor.Add_Paint({
    param($sender,$e)
    $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
    $pen = New-Object System.Drawing.Pen($borderColor, 1)
    $rect = New-Object System.Drawing.Rectangle(0,0,($sender.Width-1),($sender.Height-1))
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})

$lblOutlineDash = New-Object System.Windows.Forms.Label
$lblOutlineDash.Text = "Line style"
$lblOutlineDash.Location = New-Object System.Drawing.Point(0,258)
$lblOutlineDash.Size = New-Object System.Drawing.Size(150,18)
$lblOutlineDash.Font = New-UIFont 8.0
$lblOutlineDash.Tag = "muted"
$right.Controls.Add($lblOutlineDash)

$cmbOutlineDash = New-Object System.Windows.Forms.ComboBox
$cmbOutlineDash.DropDownStyle = "DropDownList"
$cmbOutlineDash.Items.AddRange(@("Solid","Dash","Dot","Dash-Dot","Dash-Dot-Dot"))
$cmbOutlineDash.SelectedIndex = 0
$cmbOutlineDash.Location = New-Object System.Drawing.Point(0,276)
$cmbOutlineDash.Size = New-Object System.Drawing.Size(150,26)
$cmbOutlineDash.Font = New-UIFont 8.3
$cmbOutlineDash.Tag = "input"
$right.Controls.Add($cmbOutlineDash)

$lblOutlineJoin = New-Object System.Windows.Forms.Label
$lblOutlineJoin.Text = "Corners"
$lblOutlineJoin.Location = New-Object System.Drawing.Point(174,258)
$lblOutlineJoin.Size = New-Object System.Drawing.Size(150,18)
$lblOutlineJoin.Font = New-UIFont 8.0
$lblOutlineJoin.Tag = "muted"
$right.Controls.Add($lblOutlineJoin)

$cmbOutlineJoin = New-Object System.Windows.Forms.ComboBox
$cmbOutlineJoin.DropDownStyle = "DropDownList"
$cmbOutlineJoin.Location = New-Object System.Drawing.Point(174,276)
$cmbOutlineJoin.Size = New-Object System.Drawing.Size(150,26)
$cmbOutlineJoin.Font = New-UIFont 8.3
$cmbOutlineJoin.Tag = "input"
$right.Controls.Add($cmbOutlineJoin)

$lblAppearanceStatus = New-Object System.Windows.Forms.Label
$lblAppearanceStatus.Location = New-Object System.Drawing.Point(0,307)
$lblAppearanceStatus.Size = New-Object System.Drawing.Size(325,40)
$lblAppearanceStatus.Font = New-UIFont 8.2
$lblAppearanceStatus.Tag = "muted"
$right.Controls.Add($lblAppearanceStatus)

$lblDrawEnds = New-Object System.Windows.Forms.Label
$lblDrawEnds.Text = "Ends"
$lblDrawEnds.Location = New-Object System.Drawing.Point(0,307)
$lblDrawEnds.Size = New-Object System.Drawing.Size(150,18)
$lblDrawEnds.Font = New-UIFont 8.0
$lblDrawEnds.Tag = "muted"
$lblDrawEnds.Visible = $false
$right.Controls.Add($lblDrawEnds)

$cmbDrawEnds = New-Object System.Windows.Forms.ComboBox
$cmbDrawEnds.DropDownStyle = "DropDownList"
$cmbDrawEnds.Items.AddRange(@("None","Arrow at end","Arrow at start","Arrows both ends"))
$cmbDrawEnds.SelectedIndex = 0
$cmbDrawEnds.Location = New-Object System.Drawing.Point(0,325)
$cmbDrawEnds.Size = New-Object System.Drawing.Size(130,26)
$cmbDrawEnds.Font = New-UIFont 8.3
$cmbDrawEnds.Tag = "input"
$cmbDrawEnds.Visible = $false
$right.Controls.Add($cmbDrawEnds)

# D4a explicit pre-commit confirmation for Line/Polyline. Keeping these in
# Appearance (rather than Redaction Area) preserves the visual separation
# between security redactions and annotation-only drawing objects.
$btnAddDraw = New-Object System.Windows.Forms.Button
$btnAddDraw.Text = "Create Annotation"
$btnAddDraw.Location = New-Object System.Drawing.Point(141,325)
$btnAddDraw.Size = New-Object System.Drawing.Size(131,26)
$btnAddDraw.Visible = $false
Style-FlatButton $btnAddDraw $true
$right.Controls.Add($btnAddDraw)

$btnCancelDraw = New-Object System.Windows.Forms.Button
$btnCancelDraw.Text = "Cancel"
$btnCancelDraw.Location = New-Object System.Drawing.Point(280,325)
$btnCancelDraw.Size = New-Object System.Drawing.Size(45,26)
$btnCancelDraw.Font = New-UIFont 7.4
$btnCancelDraw.Visible = $false
Style-FlatButton $btnCancelDraw
$right.Controls.Add($btnCancelDraw)

# D3 Text Box editor. It is context-sensitive and appears only while Text is
# selected; line/shape appearance controls remain untouched for their tools.
$textAppearancePanel = New-Object System.Windows.Forms.Panel
$textAppearancePanel.Location = New-Object System.Drawing.Point(0,446)
$textAppearancePanel.Size = New-Object System.Drawing.Size(325,200)
$textAppearancePanel.Visible = $false
$textAppearancePanel.Tag = "panel"
$right.Controls.Add($textAppearancePanel)

$lblTextContent = New-Object System.Windows.Forms.Label
$lblTextContent.Text = "Text"
$lblTextContent.Location = New-Object System.Drawing.Point(0,0)
$lblTextContent.Size = New-Object System.Drawing.Size(50,18)
$lblTextContent.Font = New-UIFont 8.0
$lblTextContent.Tag = "muted"
$textAppearancePanel.Controls.Add($lblTextContent)

$txtAnnotationText = New-Object System.Windows.Forms.TextBox
$txtAnnotationText.Multiline = $true
$txtAnnotationText.AcceptsReturn = $true
$txtAnnotationText.ScrollBars = "Vertical"
$txtAnnotationText.Location = New-Object System.Drawing.Point(0,18)
$txtAnnotationText.Size = New-Object System.Drawing.Size(325,54)
$txtAnnotationText.Font = New-UIFont 8.5
$txtAnnotationText.Tag = "input"
$textAppearancePanel.Controls.Add($txtAnnotationText)

$lblTextFont = New-Object System.Windows.Forms.Label
$lblTextFont.Text = "Font"
$lblTextFont.Location = New-Object System.Drawing.Point(0,78)
$lblTextFont.Size = New-Object System.Drawing.Size(150,18)
$lblTextFont.Font = New-UIFont 8.0
$lblTextFont.Tag = "muted"
$textAppearancePanel.Controls.Add($lblTextFont)

$lblTextSize = New-Object System.Windows.Forms.Label
$lblTextSize.Text = "Size (px)"
$lblTextSize.Location = New-Object System.Drawing.Point(218,78)
$lblTextSize.Size = New-Object System.Drawing.Size(70,18)
$lblTextSize.Font = New-UIFont 8.0
$lblTextSize.Tag = "muted"
$textAppearancePanel.Controls.Add($lblTextSize)

$cmbTextFont = New-Object System.Windows.Forms.ComboBox
$cmbTextFont.DropDownStyle = "DropDownList"
$cmbTextFont.Location = New-Object System.Drawing.Point(0,96)
$cmbTextFont.Size = New-Object System.Drawing.Size(208,26)
$cmbTextFont.Font = New-UIFont 8.3
$cmbTextFont.Tag = "input"
$textAppearancePanel.Controls.Add($cmbTextFont)

try {
    $installedFonts = New-Object System.Drawing.Text.InstalledFontCollection
    $fontNames = @($installedFonts.Families | ForEach-Object { $_.Name } | Sort-Object -Unique)
    foreach ($fontName in $fontNames) { [void]$cmbTextFont.Items.Add($fontName) }
    $installedFonts.Dispose()
}
catch {
    [void]$cmbTextFont.Items.Add("Segoe UI")
}
if ($cmbTextFont.Items.Count -eq 0) { [void]$cmbTextFont.Items.Add("Segoe UI") }
$fontIdx = $cmbTextFont.Items.IndexOf($script:textFontFamily)
if ($fontIdx -lt 0) { $fontIdx = 0; $script:textFontFamily = [string]$cmbTextFont.Items[0] }
$cmbTextFont.SelectedIndex = $fontIdx

$numTextSize = New-Object System.Windows.Forms.NumericUpDown
$numTextSize.Minimum = 6
$numTextSize.Maximum = 200
$numTextSize.DecimalPlaces = 0
$numTextSize.Value = [decimal]$script:textFontSizePx
$numTextSize.Location = New-Object System.Drawing.Point(218,96)
$numTextSize.Size = New-Object System.Drawing.Size(62,24)
$numTextSize.Font = New-UIFont 8.5
$numTextSize.Tag = "input"
$textAppearancePanel.Controls.Add($numTextSize)

$swatchTextColor = New-Object System.Windows.Forms.Panel
$swatchTextColor.Location = New-Object System.Drawing.Point(290,96)
$swatchTextColor.Size = New-Object System.Drawing.Size(32,24)
$swatchTextColor.Cursor = [System.Windows.Forms.Cursors]::Hand
$swatchTextColor.BackColor = $script:textColor
$textAppearancePanel.Controls.Add($swatchTextColor)
$script:appToolTip.SetToolTip($swatchTextColor, "Text colour")
$swatchTextColor.Add_Paint({
    param($sender,$e)
    $borderColor = if ($script:fieldBorderColor) { $script:fieldBorderColor } else { [System.Drawing.Color]::Gray }
    $pen = New-Object System.Drawing.Pen($borderColor, 1)
    $rect = New-Object System.Drawing.Rectangle(0,0,($sender.Width-1),($sender.Height-1))
    $e.Graphics.DrawRectangle($pen, $rect)
    $pen.Dispose()
})

$chkTextBold = New-Object System.Windows.Forms.CheckBox
$chkTextBold.Appearance = "Button"
$chkTextBold.FlatStyle = "Flat"
$chkTextBold.Text = "B"
$chkTextBold.TextAlign = "MiddleCenter"
$chkTextBold.Location = New-Object System.Drawing.Point(0,130)
$chkTextBold.Size = New-Object System.Drawing.Size(34,28)
$chkTextBold.Font = New-UIFont 9.0 ([System.Drawing.FontStyle]::Bold)
$chkTextBold.Tag = "choice"
Enable-RoundedPaint $chkTextBold 8
$textAppearancePanel.Controls.Add($chkTextBold)

$chkTextItalic = New-Object System.Windows.Forms.CheckBox
$chkTextItalic.Appearance = "Button"
$chkTextItalic.FlatStyle = "Flat"
$chkTextItalic.Text = "I"
$chkTextItalic.TextAlign = "MiddleCenter"
$chkTextItalic.Location = New-Object System.Drawing.Point(40,130)
$chkTextItalic.Size = New-Object System.Drawing.Size(34,28)
$chkTextItalic.Font = New-UIFont 9.0 ([System.Drawing.FontStyle]::Italic)
$chkTextItalic.Tag = "choice"
Enable-RoundedPaint $chkTextItalic 8
$textAppearancePanel.Controls.Add($chkTextItalic)

$cmbTextAlign = New-Object System.Windows.Forms.ComboBox
$cmbTextAlign.DropDownStyle = "DropDownList"
$cmbTextAlign.Items.AddRange(@("Left","Centre","Right"))
$cmbTextAlign.SelectedIndex = 0
$cmbTextAlign.Location = New-Object System.Drawing.Point(84,130)
$cmbTextAlign.Size = New-Object System.Drawing.Size(55,28)
$cmbTextAlign.Font = New-UIFont 8.3
$cmbTextAlign.Tag = "input"
$textAppearancePanel.Controls.Add($cmbTextAlign)

$btnAddText = New-Object System.Windows.Forms.Button
$btnAddText.Text = "Create Annotation"
$btnAddText.Location = New-Object System.Drawing.Point(145,130)
$btnAddText.Size = New-Object System.Drawing.Size(131,28)
Style-FlatButton $btnAddText $true
$textAppearancePanel.Controls.Add($btnAddText)

$btnCancelText = New-Object System.Windows.Forms.Button
$btnCancelText.Text = "Cancel"
$btnCancelText.Location = New-Object System.Drawing.Point(282,130)
$btnCancelText.Size = New-Object System.Drawing.Size(43,28)
$btnCancelText.Font = New-UIFont 7.4
Style-FlatButton $btnCancelText
$textAppearancePanel.Controls.Add($btnCancelText)

$lblTextStatus = New-Object System.Windows.Forms.Label
$lblTextStatus.Text = "Drag a text box on the preview first."
$lblTextStatus.Location = New-Object System.Drawing.Point(0,162)
$lblTextStatus.Size = New-Object System.Drawing.Size(325,36)
$lblTextStatus.Font = New-UIFont 8.2
$lblTextStatus.Tag = "muted"
$textAppearancePanel.Controls.Add($lblTextStatus)

# D5c-r2: compact floating Text editor hosted by the preview itself. Styling
# remains in the existing Appearance panel; this control is deliberately only
# a convenient, live multiline text-entry surface next to the annotation.
$floatingTextEditor = New-Object System.Windows.Forms.Panel
$floatingTextEditor.Size = New-Object System.Drawing.Size(548,124)
$floatingTextEditor.Visible = $false
$floatingTextEditor.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$floatingTextEditor.Tag = "floatingtexteditor"
$picture.Controls.Add($floatingTextEditor)

$lblFloatingTextEditor = New-Object System.Windows.Forms.Label
$lblFloatingTextEditor.Text = "Tips: Enter for multi-line text. Ctrl+Enter or click outside to close. Create Annotation to commit."
$lblFloatingTextEditor.Location = New-Object System.Drawing.Point(2,103)
$lblFloatingTextEditor.Size = New-Object System.Drawing.Size(540,18)
$lblFloatingTextEditor.Font = New-UIFont 7.8
$lblFloatingTextEditor.Tag = "muted"
$floatingTextEditor.Controls.Add($lblFloatingTextEditor)

$txtFloatingAnnotationText = New-Object System.Windows.Forms.TextBox
$txtFloatingAnnotationText.Multiline = $true
$txtFloatingAnnotationText.AcceptsReturn = $true
$txtFloatingAnnotationText.ScrollBars = "Vertical"
$txtFloatingAnnotationText.Location = New-Object System.Drawing.Point(2,45)
$txtFloatingAnnotationText.Size = New-Object System.Drawing.Size(540,58)
$txtFloatingAnnotationText.Font = New-UIFont 9.0
$txtFloatingAnnotationText.Tag = "input"
$floatingTextEditor.Controls.Add($txtFloatingAnnotationText)

# D5c-r2: viewport-only controls mirror the accepted Appearance controls.
$floatingTextTools = New-Object System.Windows.Forms.Panel
$floatingTextTools.SetBounds(2,18,510,26)
$floatingTextEditor.Controls.Add($floatingTextTools)
$floatingDrawTools = New-Object System.Windows.Forms.Panel
$floatingDrawTools.SetBounds(38,18,474,26)
$floatingTextEditor.Controls.Add($floatingDrawTools)
$floatingAnnotationColor = New-Object System.Windows.Forms.Button
$floatingAnnotationColor.SetBounds(4,20,24,22)
$floatingTextEditor.Controls.Add($floatingAnnotationColor)
$floatingAnnotationColor.Add_Click({
    $script:floatingAnnotationColorDialog = $true
    try {
        $target = if ($txtFloatingAnnotationText.Visible) { $swatchTextColor } else { $swatchOutlineColor }
        # Raise the established swatch Click handler; it owns color validation.
        $clickMethod = [System.Windows.Forms.Control].GetMethod('OnClick',[System.Reflection.BindingFlags]'Instance,NonPublic')
        $clickMethod.Invoke($target,@([System.EventArgs]::Empty)) | Out-Null
        $floatingAnnotationColor.BackColor = $target.BackColor
    } finally { $script:floatingAnnotationColorDialog = $false }
})
$floatingClose = New-Object System.Windows.Forms.Button
$floatingClose.Text = '×'
$floatingClose.SetBounds(523,0,22,19)
$floatingClose.FlatStyle = 'Flat'
$floatingClose.FlatAppearance.BorderSize = 0
$floatingClose.Add_Click({ Close-FloatingTextEditor $false })
$floatingTextEditor.Controls.Add($floatingClose)
$floatingTitle = New-Object System.Windows.Forms.Label
$floatingTitle.Text = 'Text'
$floatingTitle.SetBounds(262,0,110,18)
$floatingTextEditor.Controls.Add($floatingTitle)

function New-FloatingCombo($hostPanel,$backing,$x,$width) {
    $mirror = New-Object System.Windows.Forms.ComboBox
    $mirror.DropDownStyle = 'DropDownList'
    $mirror.SetBounds($x,2,$width,24)
    foreach ($item in $backing.Items) { [void]$mirror.Items.Add($item) }
    $mirror.SelectedIndex = $backing.SelectedIndex
    $hostPanel.Controls.Add($mirror)
    $mirror.Add_SelectedIndexChanged({
        if (-not $script:syncingFloatingToolbar) { $backing.SelectedIndex = $mirror.SelectedIndex }
    }.GetNewClosure())
    $backing.Add_SelectedIndexChanged({
        $script:syncingFloatingToolbar = $true
        try {
            if ($mirror.Items.Count -ne $backing.Items.Count -or (($mirror.Items -join '|') -ne ($backing.Items -join '|'))) {
                $mirror.Items.Clear()
                foreach ($item in $backing.Items) { [void]$mirror.Items.Add($item) }
            }
            $mirror.SelectedIndex = $backing.SelectedIndex
        } finally { $script:syncingFloatingToolbar = $false }
    }.GetNewClosure())
    return $mirror
}
function New-FloatingNumber($hostPanel,$backing,$x,$width) {
    $mirror = New-Object System.Windows.Forms.NumericUpDown
    $mirror.Minimum = $backing.Minimum; $mirror.Maximum = $backing.Maximum
    $mirror.DecimalPlaces = $backing.DecimalPlaces; $mirror.Increment = $backing.Increment
    $mirror.Value = $backing.Value
    $mirror.SetBounds($x,2,$width,24)
    $hostPanel.Controls.Add($mirror)
    $mirror.Add_ValueChanged({ if (-not $script:syncingFloatingToolbar) { $backing.Value = $mirror.Value } }.GetNewClosure())
    $backing.Add_ValueChanged({
        $script:syncingFloatingToolbar = $true
        try { $mirror.Value = $backing.Value } finally { $script:syncingFloatingToolbar = $false }
    }.GetNewClosure())
    return $mirror
}
$floatingFont = New-FloatingCombo $floatingTextTools $cmbTextFont 36 205
$floatingSize = New-FloatingNumber $floatingTextTools $numTextSize 246 62
foreach ($spec in @(@($chkTextBold,'B',316),@($chkTextItalic,'I',345))) {
    $backing=$spec[0]
    $mirror=New-Object System.Windows.Forms.CheckBox
    $mirror.Appearance='Button'; $mirror.Text=$spec[1]; $mirror.TextAlign='MiddleCenter'
    $mirror.Font=$backing.Font
    $mirror.SetBounds($spec[2],2,26,24)
    $floatingTextTools.Controls.Add($mirror)
    $mirror.Add_CheckedChanged({ if (-not $script:syncingFloatingToolbar) { $backing.Checked=$mirror.Checked } }.GetNewClosure())
    $backing.Add_CheckedChanged({
        $script:syncingFloatingToolbar=$true
        try { $mirror.Checked=$backing.Checked } finally { $script:syncingFloatingToolbar=$false }
    }.GetNewClosure())
}
$script:floatingAlignButtons=@()
foreach ($spec in @(@('≡',0,385),@('≡',1,414),@('≡',2,443))) {
    $alignment=[int]$spec[1]
    $button=New-Object System.Windows.Forms.CheckBox
    $button.Appearance='Button'; $button.Text=$spec[0]
    $button.TextAlign=@('MiddleLeft','MiddleCenter','MiddleRight')[$alignment]
    $button.SetBounds($spec[2],2,26,24)
    $floatingTextTools.Controls.Add($button)
    $script:floatingAlignButtons += $button
    $button.Add_Click({ $cmbTextAlign.SelectedIndex=$alignment }.GetNewClosure())
}
$cmbTextAlign.Add_SelectedIndexChanged({
    for($i=0;$i -lt 3;$i++) { $script:floatingAlignButtons[$i].Checked=($i -eq $cmbTextAlign.SelectedIndex) }
})
$floatingWidth = New-FloatingNumber $floatingDrawTools $numOutlineWidth 0 58
$floatingDash = New-FloatingCombo $floatingDrawTools $cmbOutlineDash 66 113
$floatingEnds = New-FloatingCombo $floatingDrawTools $cmbDrawEnds 187 145
$floatingJoin = New-FloatingCombo $floatingDrawTools $cmbOutlineJoin 340 125
$script:appToolTip.SetToolTip($floatingWidth,'Line width')
$script:appToolTip.SetToolTip($floatingDash,'Line dash')
$script:appToolTip.SetToolTip($floatingEnds,'Arrow endpoints')
$script:appToolTip.SetToolTip($floatingJoin,'Polyline join')

function Set-FloatingAnnotationToolbar([string]$kind) {
    $isText = $kind -eq 'Text'
    $floatingTitle.Text=$kind
    $txtFloatingAnnotationText.Visible=$isText
    $floatingTextTools.Visible=$isText; $floatingDrawTools.Visible=-not $isText
    $floatingJoin.Visible=$kind -eq 'Polyline'
    $floatingAnnotationColor.BackColor=if($isText) { $swatchTextColor.BackColor } else { $swatchOutlineColor.BackColor }
    $floatingTextEditor.Height=if($isText) {124} else {68}
    $lblFloatingTextEditor.Top=if($isText) {103} else {46}
    $lblFloatingTextEditor.Text=if($isText) {'Tips: Enter for multi-line text. Ctrl+Enter or click outside to close. Create Annotation to commit.'} else {'Click outside to close. Double-click to reopen. Create Annotation to commit.'}
    for($i=0;$i -lt 3;$i++) { $script:floatingAlignButtons[$i].Checked=($i -eq $cmbTextAlign.SelectedIndex) }
}

# Observe mouse clicks throughout the application's message loop. Never swallow
# the click: Create/Begin/End retain their original event and timing semantics.
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;
public sealed class TRTAnnotationOutsideClickFilter : IMessageFilter {
    [StructLayout(LayoutKind.Sequential)] private struct RECT { public int L,T,R,B; }
    [StructLayout(LayoutKind.Sequential)] private struct COMBOBOXINFO {
        public int Size; public RECT Item, Button; public int State;
        public IntPtr Combo, Edit, List;
    }
    [DllImport("user32.dll")] private static extern bool GetComboBoxInfo(IntPtr handle, ref COMBOBOXINFO info);
    private bool IsEditorPopup(Control parent, IntPtr handle) {
        foreach (Control child in parent.Controls) {
            ComboBox combo = child as ComboBox;
            if (combo != null && combo.IsHandleCreated) {
                COMBOBOXINFO info = new COMBOBOXINFO();
                info.Size = Marshal.SizeOf(typeof(COMBOBOXINFO));
                if (GetComboBoxInfo(combo.Handle, ref info) && info.List == handle) return true;
            }
            if (IsEditorPopup(child, handle)) return true;
        }
        return false;
    }
    public event EventHandler OutsideClick;
    public Control Editor;
    public bool PreFilterMessage(ref Message m) {
        if (Editor == null || !Editor.Visible) return false;
        if (m.Msg == 0x201 || m.Msg == 0x204 || m.Msg == 0x207 ||
            m.Msg == 0x20B || m.Msg == 0xA1 || m.Msg == 0xA4 || m.Msg == 0xA7) {
            Control c = Control.FromChildHandle(m.HWnd);
            if (c != Editor && (c == null || !Editor.Contains(c)) && !IsEditorPopup(Editor, m.HWnd)) {
                if (OutsideClick != null) OutsideClick(this, EventArgs.Empty);
            }
        }
        return false;
    }
}
'@
$script:floatingOutsideFilter=New-Object TRTAnnotationOutsideClickFilter
$script:floatingOutsideFilter.Editor=$floatingTextEditor
$script:floatingOutsideFilter.Add_OutsideClick({
    if ($script:floatingAnnotationColorDialog) { return }
    $script:suppressFloatingOutsidePreviewClick = $picture.RectangleToScreen($picture.ClientRectangle).Contains([System.Windows.Forms.Cursor]::Position)
    Close-FloatingTextEditor $false
})
[System.Windows.Forms.Application]::AddMessageFilter($script:floatingOutsideFilter)
$form.Add_Deactivate({
    if ($script:floatingTextEditorVisible -and -not $script:floatingAnnotationColorDialog) { Close-FloatingTextEditor $false }
})
$form.Add_FormClosed({ [System.Windows.Forms.Application]::RemoveMessageFilter($script:floatingOutsideFilter) })

function Register-FloatingAnnotationKeys($control) {
    if ($control -ne $txtFloatingAnnotationText) {
        $control.Add_KeyDown({
            param($sender,$e)
            if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
                Close-FloatingTextEditor $false
                $e.Handled=$true; $e.SuppressKeyPress=$true
            }
        })
    }
    foreach($child in $control.Controls) { Register-FloatingAnnotationKeys $child }
}
Register-FloatingAnnotationKeys $floatingTextEditor


function Get-FloatingTextEditorMediaRect {
    if (-not $script:floatingTextEditorVisible) { return $null }
    if ($script:floatingTextEditorMode -eq "Draft") {
        if ($toolMode -eq "Text" -and $script:textDraftActive) { return $script:textDraftRect }
        if ($toolMode -eq "Line" -and $script:lineDraftActive) {
            return Get-AnnotationMediaBounds (New-LineDrawingAnnotation $script:lineStart $script:lineEnd $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawEndpointStyle -1)
        }
        if ($toolMode -eq "Polyline" -and $script:polylineDraftActive) {
            return Get-AnnotationMediaBounds (New-PolylineDrawingAnnotation $script:polylinePoints $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawPolylineJoinStyle $script:drawEndpointStyle -1)
        }
        return $null
    }
    if ($script:floatingTextEditorMode -eq "Committed") {
        $idx = [int]$script:floatingTextEditorTargetIndex
        if ($idx -ge 0 -and $idx -lt $annotations.Count) {
            $a = $annotations[$idx]
            if ($a -and $a.Kind -in @("Text","Line","Polyline")) { return Get-AnnotationMediaBounds $a }
        }
    }
    return $null
}

function Update-FloatingTextEditorPosition {
    if (-not $floatingTextEditor -or -not $script:floatingTextEditorVisible -or -not $floatingTextEditor.Visible) { return }
    $mediaRect = Get-FloatingTextEditorMediaRect
    if (-not $mediaRect) { $floatingTextEditor.Visible = $false; $script:floatingTextEditorVisible = $false; return }
    $viewRect = MediaRect-To-ViewRect $mediaRect
    if (-not $viewRect) { return }

    $margin = 8
    $w = [int]$floatingTextEditor.Width
    $h = [int]$floatingTextEditor.Height
    $x = [int][Math]::Round([double]$viewRect.X + (([double]$viewRect.Width - $w) / 2.0))
    $yBelow = [int][Math]::Round([double]$viewRect.Bottom + $margin)
    $yAbove = [int][Math]::Round([double]$viewRect.Top - $h - $margin)
    $y = if (($yBelow + $h) -le ($picture.ClientSize.Height - $margin)) { $yBelow } else { $yAbove }
    $x = [Math]::Max($margin,[Math]::Min($x,[Math]::Max($margin,$picture.ClientSize.Width - $w - $margin)))
    $y = [Math]::Max($margin,[Math]::Min($y,[Math]::Max($margin,$picture.ClientSize.Height - $h - $margin)))
    $newLocation = New-Object System.Drawing.Point($x,$y)
    if ($floatingTextEditor.Location -ne $newLocation) { $floatingTextEditor.Location = $newLocation }
}

function Set-FloatingTextEditorText([string]$value) {
    if (-not $txtFloatingAnnotationText) { return }
    $script:syncingFloatingTextEditor = $true
    try { $txtFloatingAnnotationText.Text = if ($null -eq $value) { "" } else { [string]$value } }
    finally { $script:syncingFloatingTextEditor = $false }
}

function Show-FloatingTextEditor([string]$mode = "Draft") {
    if (-not $floatingTextEditor -or -not $txtFloatingAnnotationText) { return $false }
    $value = ""
    $targetIndex = -1
    if ($mode -eq "Committed") {
        $a = Get-SelectedAppearanceAnnotation
        if (-not $a -or $a.Kind -notin @("Text","Line","Polyline")) { return $false }
        $targetIndex = [int]$script:selectedAnnotationIndex
        $value = [string]$a.Text
    }
    else {
        if (-not (($toolMode -eq "Text" -and $script:textDraftActive) -or ($toolMode -eq "Line" -and $script:lineDraftActive) -or ($toolMode -eq "Polyline" -and $script:polylineDraftActive))) { return $false }
        $mode = "Draft"
        $value = [string]$txtAnnotationText.Text
    }

    $kind = if ($mode -eq "Committed") { [string]$a.Kind } else { [string]$toolMode }
    Set-FloatingAnnotationToolbar $kind
    $script:floatingTextEditorMode = $mode
    $script:floatingTextEditorTargetIndex = $targetIndex
    $script:floatingTextEditorOriginalText = $value
    $script:floatingTextEditorVisible = $true
    Set-FloatingTextEditorText $value
    $floatingTextEditor.Visible = $true
    Update-FloatingTextEditorPosition
    $floatingTextEditor.BringToFront()
    if ($kind -eq "Text") { $txtFloatingAnnotationText.Focus() } else { $floatingAnnotationColor.Focus() }
    $txtFloatingAnnotationText.SelectionStart = $txtFloatingAnnotationText.TextLength
    $txtFloatingAnnotationText.SelectionLength = 0
    return $true
}

function Close-FloatingTextEditor([bool]$cancel = $false) {
    if (-not $floatingTextEditor) { return }
    $mode = [string]$script:floatingTextEditorMode
    $idx = [int]$script:floatingTextEditorTargetIndex
    $original = [string]$script:floatingTextEditorOriginalText

    if ($mode -eq "Committed" -and $idx -ge 0 -and $idx -lt $annotations.Count) {
        $a = $annotations[$idx]
        if ($a -and $a.Kind -eq "Text") {
            if ($cancel) { $a.Text = $original }
            # Empty committed input is never stored. On a normal close, restore
            # the editor UI to the annotation's last valid live value; Escape
            # instead restores the value that existed when editing began.
            if ($script:selectedAnnotationIndex -eq $idx -and ($cancel -or [string]::IsNullOrWhiteSpace($txtFloatingAnnotationText.Text))) {
                $oldSync = $script:syncingAnnotationAppearance
                $script:syncingAnnotationAppearance = $true
                try { $txtAnnotationText.Text = [string]$a.Text } finally { $script:syncingAnnotationAppearance = $oldSync }
            }
        }
    }

    $floatingTextEditor.Visible = $false
    $script:floatingTextEditorVisible = $false
    $script:floatingTextEditorMode = "None"
    $script:floatingTextEditorTargetIndex = -1
    $script:floatingTextEditorOriginalText = ""
    if ($picture) { $picture.Invalidate() }
}

function Get-SelectedDrawEndpointStyle {
    switch ([string]$cmbDrawEnds.SelectedItem) {
        "Arrow at end"       { return "ArrowEnd" }
        "Arrow at start"     { return "ArrowStart" }
        "Arrows both ends"   { return "ArrowBoth" }
        default                { return "None" }
    }
}

function Get-SelectedOutlineDashStyle {
    switch ([string]$cmbOutlineDash.SelectedItem) {
        "Dash"         { return "Dash" }
        "Dot"          { return "Dot" }
        "Dash-Dot"     { return "DashDot" }
        "Dash-Dot-Dot" { return "DashDotDot" }
        default          { return "Solid" }
    }
}

function Get-SelectedAppearanceAnnotation {
    if (-not $annotations) { return $null }
    $idx = [int]$script:selectedAnnotationIndex
    if ($idx -lt 0 -or $idx -ge $annotations.Count) { return $null }
    return $annotations[$idx]
}

function Set-OutlineJoinChoices {
    if (-not $cmbOutlineJoin) { return }
    $a = Get-SelectedAppearanceAnnotation
    $context = if ($a) {
        if ($a.Kind -eq "ShapeOutline") { [string]$a.Shape } else { [string]$a.Kind }
    } else { [string]$toolMode }

    $oldSync = $script:syncingAnnotationAppearance
    $script:syncingAnnotationAppearance = $true
    try {
        $cmbOutlineJoin.Items.Clear()
        if ($context -eq "Polygon" -or $context -eq "Polyline") {
            $lblOutlineJoin.Text = "Joins"
            $cmbOutlineJoin.Items.AddRange(@("Miter","Round"))
            $want = if ($a) { [string]$a.JoinStyle } elseif ($context -eq "Polyline") { $script:drawPolylineJoinStyle } else { $script:outlinePolygonJoinStyle }
            $idx = $cmbOutlineJoin.Items.IndexOf($want)
            $cmbOutlineJoin.SelectedIndex = if ($idx -ge 0) { $idx } else { 0 }
        }
        elseif ($context -eq "Oval" -or $context -eq "Line") {
            $lblOutlineJoin.Text = if ($context -eq "Line") { "Joins" } else { "Corners / joins" }
            [void]$cmbOutlineJoin.Items.Add("Not applicable")
            $cmbOutlineJoin.SelectedIndex = 0
        }
        else {
            $lblOutlineJoin.Text = "Corners"
            $cmbOutlineJoin.Items.AddRange(@("Square","Round"))
            $want = if ($a) { [string]$a.JoinStyle } else { $script:outlineRectangleCornerStyle }
            $idx = $cmbOutlineJoin.Items.IndexOf($want)
            $cmbOutlineJoin.SelectedIndex = if ($idx -ge 0) { $idx } else { 0 }
        }
    }
    finally { $script:syncingAnnotationAppearance = $oldSync }
}

function Get-CurrentOutlineJoinStyle {
    if ($toolMode -eq "Polygon") { return $script:outlinePolygonJoinStyle }
    if ($toolMode -eq "Polyline") { return $script:drawPolylineJoinStyle }
    if ($toolMode -eq "Oval") { return "Round" }
    return $script:outlineRectangleCornerStyle
}

function Sync-DraftAppearanceDefaultsToControls {
    $oldSync = $script:syncingAnnotationAppearance
    $script:syncingAnnotationAppearance = $true
    try {
        $numOutlineWidth.Value = [decimal][Math]::Max([double]$numOutlineWidth.Minimum,[Math]::Min([double]$numOutlineWidth.Maximum,[double]$script:outlineWidth))
        $swatchOutlineColor.BackColor = $script:outlineColor
        $swatchOutlineColor.Invalidate()
        $dashDisplay = switch ([string]$script:outlineDashStyle) {
            "DashDot" { "Dash-Dot" }
            "DashDotDot" { "Dash-Dot-Dot" }
            default { [string]$script:outlineDashStyle }
        }
        $dashIdx = $cmbOutlineDash.Items.IndexOf($dashDisplay)
        $cmbOutlineDash.SelectedIndex = if ($dashIdx -ge 0) { $dashIdx } else { 0 }
        $endDisplay = switch ([string]$script:drawEndpointStyle) {
            "ArrowEnd" { "Arrow at end" }
            "ArrowStart" { "Arrow at start" }
            "ArrowBoth" { "Arrows both ends" }
            default { "None" }
        }
        $endIdx = $cmbDrawEnds.Items.IndexOf($endDisplay)
        $cmbDrawEnds.SelectedIndex = if ($endIdx -ge 0) { $endIdx } else { 0 }

        $fontIdx = $cmbTextFont.Items.IndexOf([string]$script:textFontFamily)
        if ($fontIdx -ge 0) { $cmbTextFont.SelectedIndex = $fontIdx }
        $numTextSize.Value = [decimal][Math]::Max([double]$numTextSize.Minimum,[Math]::Min([double]$numTextSize.Maximum,[double]$script:textFontSizePx))
        $chkTextBold.Checked = [bool]$script:textBold
        $chkTextItalic.Checked = [bool]$script:textItalic
        $alignIdx = $cmbTextAlign.Items.IndexOf([string]$script:textAlignment)
        $cmbTextAlign.SelectedIndex = if ($alignIdx -ge 0) { $alignIdx } else { 0 }
        $swatchTextColor.BackColor = $script:textColor
        $swatchTextColor.Invalidate()
        Set-OutlineJoinChoices
    }
    finally { $script:syncingAnnotationAppearance = $oldSync }
}

function Sync-SelectedAnnotationAppearanceToControls {
    $a = Get-SelectedAppearanceAnnotation
    if (-not $a) { return }

    $oldSync = $script:syncingAnnotationAppearance
    $script:syncingAnnotationAppearance = $true
    try {
        if ($a.Kind -eq "Text") {
            $txtAnnotationText.Text = [string]$a.Text
            $fontIdx = $cmbTextFont.Items.IndexOf([string]$a.FontFamily)
            if ($fontIdx -ge 0) { $cmbTextFont.SelectedIndex = $fontIdx }
            $size = [decimal][Math]::Max([double]$numTextSize.Minimum,[Math]::Min([double]$numTextSize.Maximum,[double]$a.FontSizePx))
            $numTextSize.Value = $size
            $chkTextBold.Checked = [bool]$a.Bold
            $chkTextItalic.Checked = [bool]$a.Italic
            $alignIdx = $cmbTextAlign.Items.IndexOf([string]$a.Alignment)
            $cmbTextAlign.SelectedIndex = if ($alignIdx -ge 0) { $alignIdx } else { 0 }
            $swatchTextColor.BackColor = $a.TextColor
            $swatchTextColor.Invalidate()
        }
        else {
            $width = [decimal][Math]::Max([double]$numOutlineWidth.Minimum,[Math]::Min([double]$numOutlineWidth.Maximum,[double]$a.StrokeWidth))
            $numOutlineWidth.Value = $width
            $swatchOutlineColor.BackColor = $a.StrokeColor
            $swatchOutlineColor.Invalidate()
            $dashDisplay = switch ([string]$a.DashStyle) {
                "DashDot" { "Dash-Dot" }
                "DashDotDot" { "Dash-Dot-Dot" }
                default { [string]$a.DashStyle }
            }
            $dashIdx = $cmbOutlineDash.Items.IndexOf($dashDisplay)
            $cmbOutlineDash.SelectedIndex = if ($dashIdx -ge 0) { $dashIdx } else { 0 }
            Set-OutlineJoinChoices
            if ($a.Kind -eq "Line" -or $a.Kind -eq "Polyline") {
                $endDisplay = switch ([string]$a.EndpointStyle) {
                    "ArrowEnd" { "Arrow at end" }
                    "ArrowStart" { "Arrow at start" }
                    "ArrowBoth" { "Arrows both ends" }
                    default { "None" }
                }
                $endIdx = $cmbDrawEnds.Items.IndexOf($endDisplay)
                $cmbDrawEnds.SelectedIndex = if ($endIdx -ge 0) { $endIdx } else { 0 }
            }
        }
    }
    finally { $script:syncingAnnotationAppearance = $oldSync }
}

function Update-AppearanceStatus {
    if (-not $videoPath) {
        $lblAppearanceStatus.Text = "Appearance options for redactions and annotations."
        return
    }
    $selectedA = Get-SelectedAppearanceAnnotation
    if ($selectedA) {
        switch ([string]$selectedA.Kind) {
            "Text" { $lblAppearanceStatus.Text = "Text annotation selected — edit content/style here; drag or resize it on the preview."; return }
            "Line" { $lblAppearanceStatus.Text = "Line annotation selected — edit its appearance here or geometry on the preview."; return }
            "Polyline" { $lblAppearanceStatus.Text = "Polyline selected — edit appearance here or move its vertices on the preview."; return }
            default { $lblAppearanceStatus.Text = "Outline annotation selected — edit its appearance here or geometry on the preview."; return }
        }
    }
    if ($toolMode -eq "Text") {
        $lblAppearanceStatus.Text = if (-not $isImageMode -and $script:pendingAnnotation) {
            "Annotation range in progress — move through the video, then use End Annotation."
        } elseif (-not $isImageMode -and $script:textDraftActive) {
            "Text ready — adjust it as needed, then use Begin Annotation below the preview."
        } elseif ($isImageMode) {
            "Text Box annotation — drag a box, type in the floating editor, then close the editor and choose Create Annotation."
        } else {
            "Text Box annotation — drag a box and type in the floating editor; Begin Annotation sets its first frame."
        }
        return
    }
    if ($toolMode -eq "Line") {
        $lblAppearanceStatus.Text = if (-not $isImageMode -and $script:pendingAnnotation) {
            "Annotation range in progress — move through the video, then use End Annotation."
        } elseif ($script:lineDraftActive) {
            if ($isImageMode) { "Line ready — drag the line to reposition it, then choose Create Annotation." }
            else { "Line ready — reposition it if needed, then use Begin Annotation below the preview." }
        } else {
            "Line annotation — drag from start to end. Hold Shift to constrain to 45° increments."
        }
        return
    }
    if ($toolMode -eq "Polyline") {
        $lblAppearanceStatus.Text = if (-not $isImageMode -and $script:pendingAnnotation) {
            "Annotation range in progress — move through the video, then use End Annotation."
        } elseif ($script:polylineDraftActive) {
            if ($isImageMode) { "Polyline ready — drag the path to reposition it, then choose Create Annotation." }
            else { "Polyline ready — reposition it if needed, then use Begin Annotation below the preview." }
        } else {
            "Polyline annotation — hold the left mouse button and draw; release to prepare it for positioning."
        }
        return
    }
    if (-not $chkFill.Checked -and -not $chkOutline.Checked) {
        $lblAppearanceStatus.Text = "Choose Fill, Outline, or both before creating the shape."
    }
    elseif (-not $chkFill.Checked -and $chkOutline.Checked) {
        $lblAppearanceStatus.Text = "Annotation only — this does not redact or obscure media."
    }
    elseif ($chkFill.Checked -and $chkOutline.Checked) {
        $lblAppearanceStatus.Text = "Redaction/effect with a separate annotation outline."
    }
    else {
        $lblAppearanceStatus.Text = "Fill uses the selected redaction/effect."
    }
}

function Update-OutlineControlsAvailability {
    if($script:ExportBusy){return}
    $supported = [bool]($videoPath -and -not $pendingRedaction -and -not $script:pendingAnnotation)
    $selectedA = Get-SelectedAppearanceAnnotation
    $editingCommitted = [bool]($null -ne $selectedA)
    $selectedKind = if ($selectedA) { [string]$selectedA.Kind } else { "" }
    $textContext = [bool](($editingCommitted -and $selectedKind -eq "Text") -or (-not $editingCommitted -and $toolMode -eq "Text"))
    $drawTool = [bool]((-not $editingCommitted) -and (Test-IsStandaloneDrawTool))
    $nonTextAnnotationEdit = [bool]($editingCommitted -and $selectedKind -ne "Text")
    $drawContext = [bool]($drawTool -or $nonTextAnnotationEdit)

    # Text has its own compact editor. A selected committed Text annotation
    # temporarily owns Appearance regardless of which toolbar tool remains active.
    foreach ($ctl in @($chkFill,$chkOutline,$lblOutlineWidth,$numOutlineWidth,$swatchOutlineColor)) {
        if ($ctl) { $ctl.Visible = -not $textContext }
    }
    foreach ($ctl in @($lblOutlineDash,$cmbOutlineDash,$lblOutlineJoin,$cmbOutlineJoin,$lblAppearanceStatus)) {
        if ($ctl) { $ctl.Visible = [bool](-not $textContext) }
    }
    if ($textAppearancePanel) { $textAppearancePanel.Visible = $textContext }

    if ($textContext) {
        $txtAnnotationText.Enabled = [bool]($supported -and ($editingCommitted -or $script:textDraftActive))
        $cmbTextFont.Enabled = $supported
        $numTextSize.Enabled = $supported
        $swatchTextColor.Enabled = $supported
        $chkTextBold.Enabled = $supported
        $chkTextItalic.Enabled = $supported
        $cmbTextAlign.Enabled = $supported
        if ($editingCommitted) {
            $btnAddText.Visible = $true
            $btnAddText.Text = "Create Annotation"
            $btnAddText.Enabled = $supported
            $btnCancelText.Visible = $false
            $lblTextStatus.Text = "Changes apply to the selected Text annotation. Drag or resize it on the preview as needed."
        }
        else {
            $btnAddText.Text = "Create Annotation"
            $btnAddText.Visible = $true
            $btnAddText.Enabled = [bool]($supported -and $script:textDraftActive -and -not [string]::IsNullOrWhiteSpace($txtAnnotationText.Text))
            $btnCancelText.Visible = [bool]$isImageMode
            $btnCancelText.Enabled = [bool]($isImageMode -and $supported -and ($script:textDraftActive -or $script:textDrawing))
            $lblTextStatus.Text = if ($script:textDraftActive) {
                if ($isImageMode) { "Drag the box to reposition it. Enter adds a line; Ctrl+Enter closes; Create Annotation commits." }
                elseif ($script:pendingAnnotation) { "Range started. Move to the final frame, then use End Annotation." }
                else { "Drag the box to reposition it. Begin Annotation sets the first frame." }
            } elseif ($script:textDrawing) {
                "Drag to size the text box."
            } else {
                "Drag a text box on the preview first."
            }
        }
        foreach ($ctl in @($lblDrawEnds,$cmbDrawEnds,$btnAddDraw,$btnCancelDraw)) { if ($ctl) { $ctl.Visible = $false } }
        Update-AppearanceStatus
        return
    }

    # Standalone Draw tools and selected committed non-Text annotations are
    # annotation-only. Hide Fill/Outline switches so security semantics cannot
    # be confused with visual appearance editing.
    $chkFill.Visible = -not $drawContext
    $chkOutline.Visible = -not $drawContext
    if ($drawContext) {
        $lblOutlineWidth.Left = 0
        $numOutlineWidth.Left = 44
        $swatchOutlineColor.Left = 108
    }
    else {
        $lblOutlineWidth.Left = 164
        $numOutlineWidth.Left = 208
        $swatchOutlineColor.Left = 272
    }

    $chkFill.Enabled = $supported -and $isImageMode -and -not $drawContext
    $chkOutline.Enabled = $supported -and $isImageMode -and -not $drawContext
    $styleEnabled = [bool]($supported -and ($drawContext -or ($isImageMode -and $chkOutline.Checked)))
    $lblOutlineWidth.Enabled = $styleEnabled
    $numOutlineWidth.Enabled = $styleEnabled
    $swatchOutlineColor.Enabled = $styleEnabled
    $lblOutlineDash.Enabled = $styleEnabled
    $cmbOutlineDash.Enabled = $styleEnabled

    $contextKind = if ($selectedA) {
        if ($selectedA.Kind -eq "ShapeOutline") { [string]$selectedA.Shape } else { [string]$selectedA.Kind }
    } else { [string]$toolMode }
    $joinApplies = [bool]($styleEnabled -and ($contextKind -eq "Rectangle" -or $contextKind -eq "Polygon" -or $contextKind -eq "Polyline"))
    $lblOutlineJoin.Enabled = $joinApplies
    $cmbOutlineJoin.Enabled = $joinApplies

    $endsApply = [bool]($styleEnabled -and ($contextKind -eq "Line" -or $contextKind -eq "Polyline"))
    $lblDrawEnds.Visible = [bool]$endsApply
    $cmbDrawEnds.Visible = [bool]$endsApply
    $lblDrawEnds.Enabled = $endsApply
    $cmbDrawEnds.Enabled = $endsApply

    if ($btnAddDraw) {
        $btnAddDraw.Visible = [bool]($drawTool -or ($selectedA -and $selectedA.Kind -in @("Line","Polyline")))
        $btnAddDraw.Text = "Create Annotation"
        $btnAddDraw.Enabled = [bool]($supported -and (($selectedA -and $selectedA.Kind -in @("Line","Polyline")) -or ($toolMode -eq "Line" -and $script:lineDraftActive) -or ($toolMode -eq "Polyline" -and $script:polylineDraftActive)))
    }
    if ($btnCancelDraw) {
        $btnCancelDraw.Visible = [bool]($drawTool -and $isImageMode)
        $btnCancelDraw.Enabled = [bool]($isImageMode -and $supported -and (($toolMode -eq "Line" -and ($script:lineDrawing -or $script:lineDraftActive)) -or ($toolMode -eq "Polyline" -and ($script:polylineActive -or $script:polylineDraftActive))))
    }

    $oldSync = $script:syncingAnnotationAppearance
    $script:syncingAnnotationAppearance = $true
    try { Set-OutlineJoinChoices } finally { $script:syncingAnnotationAppearance = $oldSync }
    Update-AppearanceStatus
}

$chkFill.Add_CheckedChanged({
    $script:fillEnabled = [bool]$chkFill.Checked
    Update-SecurityModeNote
    Update-AppearanceStatus
    Update-StrengthSliderVisibility
    Update-ColorPickerVisibility
    Update-OutlineControlsAvailability
    Update-RedactionButtons
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$chkOutline.Add_CheckedChanged({
    $script:outlineEnabled = [bool]$chkOutline.Checked
    Update-OutlineControlsAvailability
    Update-RedactionButtons
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$numOutlineWidth.Add_ValueChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -ne "Text") { $a.StrokeWidth = [double]$numOutlineWidth.Value }
    else { $script:outlineWidth = [int]$numOutlineWidth.Value }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$cmbOutlineDash.Add_SelectedIndexChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $dash = Get-SelectedOutlineDashStyle
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -ne "Text") { $a.DashStyle = $dash }
    else { $script:outlineDashStyle = $dash }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$cmbOutlineJoin.Add_SelectedIndexChanged({
    if ($script:syncingAnnotationAppearance -or $cmbOutlineJoin.SelectedIndex -lt 0) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -ne "Text") {
        if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and ($a.Shape -eq "Rectangle" -or $a.Shape -eq "Polygon"))) {
            $a.JoinStyle = [string]$cmbOutlineJoin.SelectedItem
        }
    }
    elseif ($toolMode -eq "Polygon") {
        $script:outlinePolygonJoinStyle = [string]$cmbOutlineJoin.SelectedItem
    }
    elseif ($toolMode -eq "Polyline") {
        $script:drawPolylineJoinStyle = [string]$cmbOutlineJoin.SelectedItem
    }
    elseif ($toolMode -eq "Rectangle") {
        $script:outlineRectangleCornerStyle = [string]$cmbOutlineJoin.SelectedItem
    }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$cmbDrawEnds.Add_SelectedIndexChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $ends = Get-SelectedDrawEndpointStyle
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and ($a.Kind -eq "Line" -or $a.Kind -eq "Polyline")) { $a.EndpointStyle = $ends }
    else { $script:drawEndpointStyle = $ends }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})

$swatchOutlineColor.Add_Click({
    if (-not $swatchOutlineColor.Enabled) { return }
    $a = Get-SelectedAppearanceAnnotation
    $dlg = New-Object System.Windows.Forms.ColorDialog
    try {
        $dlg.FullOpen = $true
        $dlg.Color = if ($a -and $a.Kind -ne "Text") { $a.StrokeColor } else { $script:outlineColor }
        if ($dlg.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
            if ($a -and $a.Kind -ne "Text") { $a.StrokeColor = $dlg.Color }
            else { $script:outlineColor = $dlg.Color }
            $swatchOutlineColor.BackColor = $dlg.Color
            $swatchOutlineColor.Invalidate()
            if ($isImageMode -and $picture) { $picture.Invalidate() }
        }
    }
    finally { $dlg.Dispose() }
})

$cmbTextFont.Add_SelectedIndexChanged({
    if ($script:syncingAnnotationAppearance -or $cmbTextFont.SelectedIndex -lt 0) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") { $a.FontFamily = [string]$cmbTextFont.SelectedItem }
    else { $script:textFontFamily = [string]$cmbTextFont.SelectedItem }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})
$numTextSize.Add_ValueChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") { $a.FontSizePx = [double]$numTextSize.Value }
    else {
        $script:textFontSizePx = [int]$numTextSize.Value
        if ($script:textDraftActive -and $lblTextStatus) { $lblTextStatus.Text = "Font size changed. Drag the Text Box handles if more room is needed." }
    }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})
$chkTextBold.Add_CheckedChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") { $a.Bold = [bool]$chkTextBold.Checked }
    else { $script:textBold = [bool]$chkTextBold.Checked }
    Apply-Theme
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})
$chkTextItalic.Add_CheckedChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") { $a.Italic = [bool]$chkTextItalic.Checked }
    else { $script:textItalic = [bool]$chkTextItalic.Checked }
    Apply-Theme
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})
$cmbTextAlign.Add_SelectedIndexChanged({
    if ($script:syncingAnnotationAppearance -or $cmbTextAlign.SelectedIndex -lt 0) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") { $a.Alignment = [string]$cmbTextAlign.SelectedItem }
    else { $script:textAlignment = [string]$cmbTextAlign.SelectedItem }
    if ($isImageMode -and $picture) { $picture.Invalidate() }
})
$swatchTextColor.Add_Click({
    if (-not $swatchTextColor.Enabled) { return }
    $a = Get-SelectedAppearanceAnnotation
    $dlg = New-Object System.Windows.Forms.ColorDialog
    try {
        $dlg.FullOpen = $true
        $dlg.Color = if ($a -and $a.Kind -eq "Text") { $a.TextColor } else { $script:textColor }
        if ($dlg.ShowDialog($form) -eq [System.Windows.Forms.DialogResult]::OK) {
            if ($a -and $a.Kind -eq "Text") {
                $a.TextColor = $dlg.Color
                $a.StrokeColor = $dlg.Color
            }
            else { $script:textColor = $dlg.Color }
            $swatchTextColor.BackColor = $dlg.Color
            $swatchTextColor.Invalidate()
            if ($isImageMode -and $picture) { $picture.Invalidate() }
        }
    }
    finally { $dlg.Dispose() }
})
$txtAnnotationText.Add_TextChanged({
    if ($script:syncingAnnotationAppearance) { return }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") {
        if (-not [string]::IsNullOrWhiteSpace($txtAnnotationText.Text)) {
            $a.Text = $txtAnnotationText.Text
            $lblTextStatus.Text = "Changes apply immediately. Use Done when finished."
        }
        else {
            $lblTextStatus.Text = "Text cannot be empty; the committed annotation keeps its previous text until valid text is entered."
        }
    }
    else {
        Update-OutlineControlsAvailability
        Update-RedactionButtons
    }
    if ($script:floatingTextEditorVisible -and -not $script:syncingFloatingTextEditor) {
        Set-FloatingTextEditorText $txtAnnotationText.Text
    }
    if ($picture) { $picture.Invalidate() }
})
$txtAnnotationText.Add_KeyDown({
    param($sender,$e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        Close-FloatingTextEditor $false
        $e.Handled = $true; $e.SuppressKeyPress = $true
    }
})

$txtFloatingAnnotationText.Add_TextChanged({
    if ($script:syncingFloatingTextEditor) { return }
    $script:syncingFloatingTextEditor = $true
    try { $txtAnnotationText.Text = $txtFloatingAnnotationText.Text }
    finally { $script:syncingFloatingTextEditor = $false }
    if ($picture) { $picture.Invalidate() }
})

$txtFloatingAnnotationText.Add_KeyDown({
    param($sender,$e)
    if ($e.Control -and $e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        Close-FloatingTextEditor $false
        $e.Handled = $true; $e.SuppressKeyPress = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        if ($script:floatingTextEditorMode -eq "Committed") {
            Close-FloatingTextEditor $true
            Sync-SelectedAnnotationAppearanceToControls
        } else {
            Close-FloatingTextEditor $false
            Reset-DrawingState
            Update-SelectionFields $null
            Update-RedactionButtons
        }
        $e.Handled = $true; $e.SuppressKeyPress = $true
    }
})

function Confirm-TextAnnotation {
    Close-FloatingTextEditor $false
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -eq "Text") {
        if ([string]::IsNullOrWhiteSpace($txtAnnotationText.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Text cannot be empty.","Text annotation","OK","Information") | Out-Null
            $oldSync=$script:syncingAnnotationAppearance; $script:syncingAnnotationAppearance=$true
            try { $txtAnnotationText.Text=[string]$a.Text } finally { $script:syncingAnnotationAppearance=$oldSync }
            return
        }
        if ($lvAnnotations.SelectedItems.Count -gt 0) { $lvAnnotations.SelectedItems[0].Selected = $false }
        $script:selectedAnnotationIndex = -1
        Update-InspectorSectionLayout
        $picture.Invalidate()
        return
    }
    if (-not $isImageMode) {
        Update-RedactionButtons
        if ($btnStartRedaction.Enabled) { $btnStartRedaction.PerformClick() }
        return
    }
    [void](Commit-TextDraft)
}
$btnAddText.Add_Click({Confirm-TextAnnotation})
$btnCancelText.Add_Click({
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    Update-InspectorSectionLayout
    $picture.Invalidate()
})
function Confirm-DrawingAnnotation {
    if (-not $videoPath) { return }
    Close-FloatingTextEditor $false
    $selectedDraw = Get-SelectedAppearanceAnnotation
    if ($selectedDraw -and $selectedDraw.Kind -in @("Line","Polyline")) {
        if ($lvAnnotations.SelectedItems.Count -gt 0) { $lvAnnotations.SelectedItems[0].Selected = $false }
        $script:selectedAnnotationIndex = -1
        Update-InspectorSectionLayout
        $picture.Invalidate()
        return
    }
    if (-not $isImageMode) {
        Update-RedactionButtons
        if ($btnStartRedaction.Enabled) { $btnStartRedaction.PerformClick() }
        return
    }
    if ($toolMode -eq "Line" -and $script:lineDraftActive -and $script:lineStart -and $script:lineEnd) {
        if (Add-LineDrawingAnnotation $script:lineStart $script:lineEnd) {
            Reset-DrawingState
            Update-SelectionFields $null
            Update-RedactionButtons
            Update-InspectorSectionLayout
            $picture.Invalidate()
        }
        return
    }
    if ($toolMode -eq "Polyline" -and $script:polylineDraftActive) {
        if (Complete-PolylineDrawing) {
            Update-InspectorSectionLayout
            $picture.Invalidate()
        }
    }
}
$btnAddDraw.Add_Click({Confirm-DrawingAnnotation})
$btnCancelDraw.Add_Click({
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    Update-InspectorSectionLayout
    $picture.Invalidate()
})

Set-OutlineJoinChoices
Update-OutlineControlsAvailability

$ruleRedactions = Add-Rule $right 0 352 325
$lblRedactionsTitle = Add-SectionTitle $right "Redactions" 0 366 330

$lvRedactions = New-Object System.Windows.Forms.ListView
$lvRedactions.View = "Details"
$lvRedactions.FullRowSelect = $true
$lvRedactions.GridLines = $false
$lvRedactions.MultiSelect = $false
$lvRedactions.Location = New-Object System.Drawing.Point(0,398)
$lvRedactions.Size = New-Object System.Drawing.Size(325,120)
$lvRedactions.BorderStyle = "FixedSingle"
$lvRedactions.Font = New-UIFont 8.2
$lvRedactions.Tag = "list"
[void]$lvRedactions.Columns.Add("#", 30)
[void]$lvRedactions.Columns.Add("Shape", 66)
[void]$lvRedactions.Columns.Add("Mode", 92)
[void]$lvRedactions.Columns.Add("Marked range", 125)
[void]$lvRedactions.Columns.Add("Export range (buffered)", 0)
[void]$lvRedactions.Columns.Add("Rect (bounding box)", 0)
$right.Controls.Add($lvRedactions)

# Selecting a redaction here still targets the colour swatch/eyedropper. In
# D4c, a still-image selection also becomes an editable committed redaction.
$lvRedactions.Add_SelectedIndexChanged({
    if ($lvRedactions.SelectedIndices.Count -gt 0) {
        $idx = [int]$lvRedactions.SelectedIndices[0]
        if ($idx -ge 0 -and $idx -lt $redactions.Count) {
            Reset-DrawingState
            if ($lvAnnotations -and $lvAnnotations.SelectedItems.Count -gt 0) { $lvAnnotations.SelectedItems[0].Selected = $false }
            $script:selectedAnnotationIndex = -1
            $script:selectedRedactionIndex = $idx
            $r = $redactions[$idx]
            $lblPending.Text = if ($r.Shape -eq "Polygon") {
                "Redaction selected — drag inside it to move, or drag a vertex handle to reshape it."
            } else {
                "Redaction selected — drag inside it to move, or use the handles to resize it."
            }
        }
    }
    else {
        $script:selectedRedactionIndex = -1
    }
    Update-ColorSwatch
    Update-InspectorSectionLayout
    $picture.Invalidate()
})

$btnRemoveRedaction = New-Object System.Windows.Forms.Button
$btnRemoveRedaction.Text = "Remove Selected"
$btnRemoveRedaction.Location = New-Object System.Drawing.Point(0,526)
$btnRemoveRedaction.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
Style-FlatButton $btnRemoveRedaction
$right.Controls.Add($btnRemoveRedaction)

$btnClearRedactions = New-Object System.Windows.Forms.Button
$btnClearRedactions.Text = "Clear All"
$btnClearRedactions.Location = New-Object System.Drawing.Point(140,526)
$btnClearRedactions.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
Style-FlatButton $btnClearRedactions
$right.Controls.Add($btnClearRedactions)

$ruleAnnotations = Add-Rule $right 0 570 325
$lblAnnotationsTitle = Add-SectionTitle $right "Annotations" 0 584 330

$lvAnnotations = New-Object System.Windows.Forms.ListView
$lvAnnotations.View = "Details"
$lvAnnotations.FullRowSelect = $true
$lvAnnotations.GridLines = $false
$lvAnnotations.MultiSelect = $false
$lvAnnotations.Location = New-Object System.Drawing.Point(0,616)
$lvAnnotations.Size = New-Object System.Drawing.Size(325,92)
$lvAnnotations.BorderStyle = "FixedSingle"
$lvAnnotations.Font = New-UIFont 8.2
$lvAnnotations.Tag = "list"
[void]$lvAnnotations.Columns.Add("#", 30)
[void]$lvAnnotations.Columns.Add("Shape", 80)
[void]$lvAnnotations.Columns.Add("Type", 185)
[void]$lvAnnotations.Columns.Add("Range", 0)
$right.Controls.Add($lvAnnotations)

$lvAnnotations.Add_SelectedIndexChanged({
    if ($lvAnnotations.SelectedIndices.Count -gt 0) {
        $idx = [int]$lvAnnotations.SelectedIndices[0]
        if ($idx -ge 0 -and $idx -lt $annotations.Count) {
            if (-not $isImageMode) { Stop-Playback }
            # Selecting a committed annotation dismisses only uncommitted drawing
            # state. It never changes the selected toolbar tool or any redaction.
            Reset-DrawingState
            if ($lvRedactions -and $lvRedactions.SelectedItems.Count -gt 0) { $lvRedactions.SelectedItems[0].Selected = $false }
            $script:selectedRedactionIndex = -1
            $script:selectedAnnotationIndex = $idx
            Sync-SelectedAnnotationAppearanceToControls
            Update-InspectorSectionLayout
            Update-AppearanceStatus
                }
    }
    else {
        $script:selectedAnnotationIndex = -1
        Sync-DraftAppearanceDefaultsToControls
        Update-InspectorSectionLayout
        }
    $picture.Invalidate()
})

$lvAnnotations.Add_DoubleClick({
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -in @("Text","Line","Polyline")) { [void](Show-FloatingTextEditor "Committed") }
})

$btnRemoveAnnotation = New-Object System.Windows.Forms.Button
$btnRemoveAnnotation.Text = "Remove Selected"
$btnRemoveAnnotation.Location = New-Object System.Drawing.Point(0,716)
$btnRemoveAnnotation.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
Style-FlatButton $btnRemoveAnnotation
$right.Controls.Add($btnRemoveAnnotation)

$btnClearAnnotations = New-Object System.Windows.Forms.Button
$btnClearAnnotations.Text = "Clear All"
$btnClearAnnotations.Location = New-Object System.Drawing.Point(140,716)
$btnClearAnnotations.Size = New-Object System.Drawing.Size($script:CompactButtonWidth,$script:CompactButtonHeight)
Style-FlatButton $btnClearAnnotations
$right.Controls.Add($btnClearAnnotations)

$ruleOutput = Add-Rule $right 0 760 325
$lblOutputTitle = Add-SectionTitle $right "Output" 0 774 330

# Format and Quality sit side by side to save vertical space. Format's item
# list and selection swap between video and image extensions in
# Apply-ModeLabels (mirroring how $cmbQuality/$chkAudio are shown/hidden
# there already).
$lblFormat = New-Object System.Windows.Forms.Label
$lblFormat.Text = "Format"
$lblFormat.Location = New-Object System.Drawing.Point(0,810)
$lblFormat.Size = New-Object System.Drawing.Size(150,22)
$lblFormat.Font = New-UIFont 8.5
$lblFormat.Tag = "muted"
$right.Controls.Add($lblFormat)

$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Quality"
$lblQuality.Location = New-Object System.Drawing.Point(175,810)
$lblQuality.Size = New-Object System.Drawing.Size(150,22)
$lblQuality.Font = New-UIFont 8.5
$lblQuality.Tag = "muted"
$right.Controls.Add($lblQuality)

$VIDEO_FORMATS = @("MP4","MOV","M4V","AVI","MKV","WEBM")
$IMAGE_FORMATS = @("PNG","JPG","GIF","WEBP")

$cmbFormat = New-Object System.Windows.Forms.ComboBox
$cmbFormat.DropDownStyle = "DropDownList"
$cmbFormat.Items.AddRange($VIDEO_FORMATS)
$cmbFormat.SelectedIndex = 0
$cmbFormat.Location = New-Object System.Drawing.Point(0,830)
$cmbFormat.Size = New-Object System.Drawing.Size(150,30)
$cmbFormat.Font = New-UIFont 9.1
$cmbFormat.Tag = "input"
$right.Controls.Add($cmbFormat)

$cmbQuality = New-Object System.Windows.Forms.ComboBox
$cmbQuality.DropDownStyle = "DropDownList"
$cmbQuality.Items.AddRange(@("High quality","Normal quality","Smaller file size"))
$cmbQuality.SelectedIndex = 1
$cmbQuality.Location = New-Object System.Drawing.Point(175,830)
$cmbQuality.Size = New-Object System.Drawing.Size(150,30)
$cmbQuality.Font = New-UIFont 9.1
$cmbQuality.Tag = "input"
$right.Controls.Add($cmbQuality)

$chkAudio = New-Object System.Windows.Forms.CheckBox
$chkAudio.Text = "Keep original audio"
$chkAudio.Checked = $false
$chkAudio.Location = New-Object System.Drawing.Point(0,868)
$chkAudio.Size = New-Object System.Drawing.Size(220,26)
$chkAudio.Font = New-UIFont 8.8
$right.Controls.Add($chkAudio)
$chkAudio.Add_CheckedChanged({
    if (-not $chkAudio.Checked) { return }
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableAudioRetention) {
        $chkAudio.Checked = $false
        return
    }
    if ($script:suppressAudioWarning) { return }
    if ($script:audioWarningOpen) { return }

    $script:audioWarningOpen = $true
    try {
        $result = Show-CompactWarningDialog `
            "Audio is not redacted" `
            "Audio will remain in the exported file" `
            "TinyRedactionTool does not inspect or redact audio. Include the primary audio track anyway?" `
            "Yes" `
            "No" `
            $true

        if (-not $result.Accepted) {
            $chkAudio.Checked = $false
        }
        elseif ($result.Suppress) {
            $script:suppressAudioWarning = $true
        }
    }
    finally {
        $script:audioWarningOpen = $false
    }
})

# G2c managed control: an organisation may require exported video to omit the
# source audio track because TinyRedactionTool does not inspect or redact audio.
# Keep the control visible so the restriction is explicit rather than hidden.
if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableAudioRetention) {
    $chkAudio.Checked = $false
    $chkAudio.Enabled = $false
    $chkAudio.Text = "Keep original audio (disabled by policy)"
    $chkAudio.Size = New-Object System.Drawing.Size(325,26)
    $script:appToolTip.SetToolTip(
        $chkAudio,
        "Disabled by managed policy. Exported video will not retain source audio."
    )
}


$chkDeleteOriginal = New-Object System.Windows.Forms.CheckBox
$chkDeleteOriginal.Text = 'Delete original after successful export'
$chkDeleteOriginal.Checked = $false
$chkDeleteOriginal.Enabled = $false
$chkDeleteOriginal.Location = New-Object System.Drawing.Point(0,900)
$chkDeleteOriginal.Size = New-Object System.Drawing.Size(300,24)
$chkDeleteOriginal.Font = New-UIFont 8.8
$right.Controls.Add($chkDeleteOriginal)
$chkDeleteOriginal.Add_CheckedChanged({
    $script:deleteOriginalRequested = [bool]$chkDeleteOriginal.Checked
})

$btnDeleteInfo = New-Object System.Windows.Forms.Button
$btnDeleteInfo.Text = '?'
$btnDeleteInfo.Location = New-Object System.Drawing.Point(0,924)
$btnDeleteInfo.Size = New-Object System.Drawing.Size(24,24)
$btnDeleteInfo.Font = New-UIFont 10.0 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnDeleteInfo $false 12
$btnDeleteInfo.Enabled = $false
$script:appToolTip.SetToolTip($btnDeleteInfo, 'More information about original-file deletion')
$right.Controls.Add($btnDeleteInfo)
$btnDeleteInfo.Add_Click({
    $message = if ($sourceDeletionCapability) { [string]$sourceDeletionCapability.Reason } else { 'Open a source file first.' }
    $heading = if ($sourceDeletionCapability) { [string]$sourceDeletionCapability.StatusText } else { 'Deletion availability' }
    Show-CompactInformationDialog $heading $heading $message
})

$lblDeleteCapability = New-Object System.Windows.Forms.Label
$lblDeleteCapability.Text = 'Open a source to check deletion availability.'
$lblDeleteCapability.Location = New-Object System.Drawing.Point(32,924)
$lblDeleteCapability.Size = New-Object System.Drawing.Size(292,38)
$lblDeleteCapability.Font = New-UIFont 8.2
$lblDeleteCapability.Tag = 'muted'
$right.Controls.Add($lblDeleteCapability)

$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = "Export Video"
$btnExport.Location = New-Object System.Drawing.Point(0,69)
$btnExport.Size = New-Object System.Drawing.Size($script:ExportButtonWidth,$script:CompactButtonHeight)
$btnExport.Enabled = $false
$btnExport.Font = New-UIFont 7.8 ([System.Drawing.FontStyle]::Bold)
Style-FlatButton $btnExport $true
# Export now sits beside Cancel in the compact transport/action row instead
# of consuming a full-width row in Redaction Area.
$bottom.Controls.Add($btnExport)
$btnCopyImage=New-Object Windows.Forms.Button
$btnCopyImage.Size=[Drawing.Size]::new($script:CompactButtonHeight,$script:CompactButtonHeight)
$btnCopyImage.Visible=$false;$btnCopyImage.Enabled=$false
Style-FlatButton $btnCopyImage $true
$btnCopyImage.AccessibleName='Copy redacted image'
$btnCopyImage.Image=Get-ThemedIconImage 'copy' ([Drawing.Color]::White)
$script:appToolTip.SetToolTip($btnCopyImage,'Copy redacted image')
$bottom.Controls.Add($btnCopyImage)
$btnCopyImage.Add_Click({if($isImageMode -and -not $script:ExportBusy){$script:CopyRequested=$true;$btnExport.PerformClick()}})
$btnCopyImage.Add_EnabledChanged({if(Get-Command Update-CopyButton -ErrorAction SilentlyContinue){Update-CopyButton}})

# D2 keeps the accepted inspector grouping. D5b-r2 deliberately keeps video
# annotation timing out of the inspector: Text/Line/Polyline reuse the existing
# bottom Begin/End/Cancel temporal controls instead.
function Update-InspectorSectionLayout {
    if(-not $lvAnnotations -or -not $lblDeleteCapability){return}
    if(-not $script:InspectorWidths){$script:InspectorWidths=@{}}
    if(-not $script:AnnotationBackingPanel){
        # Keep style values/events alive for floating editors without an
        # Appearance section or hidden-button commit dependency.
        $script:AnnotationBackingPanel=New-Object Windows.Forms.Panel
        $script:AnnotationBackingPanel.Visible=$false
        $form.Controls.Add($script:AnnotationBackingPanel)
        foreach($ctl in @($ruleAppearance,$lblAppearanceTitle,$chkFill,$chkOutline,$lblOutlineWidth,$numOutlineWidth,$swatchOutlineColor,$lblOutlineDash,$cmbOutlineDash,$lblOutlineJoin,$cmbOutlineJoin,$lblDrawEnds,$cmbDrawEnds,$btnAddDraw,$btnCancelDraw,$lblAppearanceStatus,$textAppearancePanel,$lblOutputTitle)){
            $script:AnnotationBackingPanel.Controls.Add($ctl)
        }
    }
    $ruleRedactions.Top=184;$lblRedactionsTitle.Top=198
    $lvRedactions.Top=230;$lvRedactions.Height=140
    $btnRemoveRedaction.Top=378;$btnClearRedactions.Top=378
    $ruleAnnotations.Top=420;$lblAnnotationsTitle.Top=434
    $lvAnnotations.Top=466;$lvAnnotations.Height=140
    $btnRemoveAnnotation.Top=614;$btnClearAnnotations.Top=614
    foreach($ctl in @($ruleAnnotations,$lblAnnotationsTitle,$lvAnnotations,$btnRemoveAnnotation,$btnClearAnnotations)){$ctl.Visible=$true}
    # Retain export format and original-file controls, below the three sections.
    $ruleOutput.Top=656
    $lblFormat.Top=668;$lblQuality.Top=668
    $cmbFormat.Top=690;$cmbQuality.Top=690
    $chkAudio.Top=730
    $chkDeleteOriginal.Top=if($isImageMode){730}else{760}
    $lblDeleteCapability.Top=if($isImageMode){758}else{788}
    $btnDeleteInfo.Top=$lblDeleteCapability.Top-2
    Fit-InspectorContents
    Update-OutlineControlsAvailability
}


# Apply the requested section grouping before the form is first shown.
Update-InspectorSectionLayout

# ---------- theme engine ----------
$script:isDarkMode = $false

# Fixed status colors for the shared Begin/End temporal buttons. These signal
# state (ready-to-begin / in-progress) rather than the neutral UI palette,
# so they stay constant across the light/dark theme toggle.
$script:colorGreenBg     = [System.Drawing.Color]::FromArgb(34,197,94)
$script:colorGreenBorder = [System.Drawing.Color]::FromArgb(22,163,74)
$script:colorRedBg       = [System.Drawing.Color]::FromArgb(239,68,68)
$script:colorRedBorder   = [System.Drawing.Color]::FromArgb(220,38,38)

# Populated by Apply-Theme with the current theme's neutral button/text/
# border colors, so Update-RedactionButtons (and anything else that needs
# the "inactive/grey" look) can match the active theme without duplicating
# the light/dark color logic.
$script:cButtonCurrent = [System.Drawing.Color]::FromArgb(240,248,251)
$script:cTextCurrent   = [System.Drawing.Color]::FromArgb(18,27,42)
$script:cMutedCurrent  = [System.Drawing.Color]::FromArgb(82,101,115)
$script:cBorderCurrent = [System.Drawing.Color]::FromArgb(190,209,218)
$script:cAccentCurrent = [System.Drawing.Color]::FromArgb(18,113,255)

function Apply-Theme {
    Update-InspectorSectionLayout
    if ($script:isDarkMode) {
        # v2.2 D2 Dark Mode: raise the common application/workspace/panel
        # base to #3C3F47. Nearby cards, inputs, buttons and borders are
        # lifted with it so the theme stays coherent rather than simply
        # replacing one background colour in isolation.
        $cBg       = [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cWorkspace= [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cPanel    = [System.Drawing.Color]::FromArgb(60,63,71)  # #3C3F47
        $cCard     = [System.Drawing.Color]::FromArgb(68,72,81)  # #444851
        $cInput    = [System.Drawing.Color]::FromArgb(73,77,86)  # #494D56
        $cText     = [System.Drawing.Color]::FromArgb(241,245,249)
        $cMuted    = [System.Drawing.Color]::FromArgb(192,199,208)
        $cBorder   = [System.Drawing.Color]::FromArgb(100,105,117)
        $cAccent   = [System.Drawing.Color]::FromArgb(38,132,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(35,77,122)
        $cButton   = [System.Drawing.Color]::FromArgb(71,75,84)  # #474B54
        $cPreview  = [System.Drawing.Color]::FromArgb(26,28,32)
        $cIconNormal = [System.Drawing.Color]::FromArgb(240,240,240) # #F0F0F0
        $btnTheme.Text = ""
        $btnTheme.Image = Get-ThemedIconImage "sun" $cIconNormal
        $script:appToolTip.SetToolTip($btnTheme, "Switch to Light Mode")
    }
    else {
        # v1.4 Day Mode: a deliberate cool off-white instead of pure white.
        $cBg       = [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5
        $cWorkspace= [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5 - unified with the main Day background
        $cPanel    = [System.Drawing.Color]::FromArgb(223,238,245) # #DFEEF5
        $cCard     = [System.Drawing.Color]::FromArgb(240,247,250)
        $cInput    = [System.Drawing.Color]::FromArgb(248,252,254)
        $cText     = [System.Drawing.Color]::FromArgb(18,27,42)
        $cMuted    = [System.Drawing.Color]::FromArgb(82,101,115)
        $cBorder   = [System.Drawing.Color]::FromArgb(190,209,218)
        $cAccent   = [System.Drawing.Color]::FromArgb(18,113,255)
        $cAccent2  = [System.Drawing.Color]::FromArgb(205,230,244)
        $cButton   = [System.Drawing.Color]::FromArgb(240,248,251)
        $cPreview  = [System.Drawing.Color]::FromArgb(22,26,32)
        $cIconNormal = [System.Drawing.Color]::FromArgb(32,32,32) # #202020
        $btnTheme.Text = ""
        $btnTheme.Image = Get-ThemedIconImage "moon" $cIconNormal
        $script:appToolTip.SetToolTip($btnTheme, "Switch to Dark Mode")
    }

    $form.BackColor = $cBg
    $top.BackColor = $cPanel
    $toolbar.BackColor = $cPanel
    $modeRow.BackColor = $cPanel
    $drawRow.BackColor = $cPanel
    $center.BackColor = $cWorkspace
    $rightHost.BackColor = $cPanel
    $right.BackColor = $cPanel
    $bottom.BackColor = $cWorkspace
    $chkEnhanced.BackColor = $cWorkspace
    $chkEnhanced.ForeColor = $cText
    $chkFill.BackColor = $cPanel
    $chkFill.ForeColor = $cText
    $chkOutline.BackColor = $cPanel
    $chkOutline.ForeColor = $cText
    $lblOutlineDash.BackColor = $cPanel
    $lblOutlineDash.ForeColor = $cMuted
    $lblOutlineJoin.BackColor = $cPanel
    $lblOutlineJoin.ForeColor = $cMuted
    $lblAppearanceStatus.BackColor = $cPanel
    $lblAppearanceStatus.ForeColor = $cMuted
    $lblDrawEnds.BackColor = $cPanel
    $lblDrawEnds.ForeColor = $cMuted
    $previewPanel.BackColor = $cWorkspace
    $pictureFrame.BackColor = $cBorder
    $picture.BackColor = $cPreview
    $scrubberMarkers.BackColor = $cWorkspace
    $seekBar.BackColor = $cWorkspace
    $script:seekTrackColor = $cBorder
    $script:seekTrackDisabledColor = $cBorder
    $script:seekAccentColor = $cAccent
    $seekBar.Invalidate()

    foreach ($ctl in @($form,$top,$toolbar,$center,$rightHost,$right,$bottom,$previewPanel)) {
        foreach ($child in $ctl.Controls) {
            if ($child.Tag -eq "heading") {
                $child.ForeColor = $cText
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "muted") {
                $child.ForeColor = $cMuted
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "accenttext") {
                $child.ForeColor = $cAccent
                if ($child -is [System.Windows.Forms.Label]) { $child.BackColor = [System.Drawing.Color]::Transparent }
            }
            elseif ($child.Tag -eq "rule") {
                $child.BackColor = $cBorder
            }
        }
    }

    # The embedded icon PNG already bakes in its own dark rounded-tile
    # background; $logo.BackColor only shows through its transparent
    # corner cutouts, so it should match the header bar behind it rather
    # than carry its own theme-driven tile color.
    $logo.BackColor = $cPanel

    foreach ($b in @($btnTheme,$btnRightPanelToggle,$btnRotateCCW,$btnPrevFrame,$btnNextFrame,$btnRotateCW,$btnEndRedaction,$btnCancelRedaction,$btnRemoveRedaction,$btnClearRedactions,$btnRemoveAnnotation,$btnClearAnnotations,$btnZoomOut,$btnZoomFit,$btnZoomIn)) {
        $b.BackColor = $cButton
        $b.ForeColor = $cText
        $b.FlatAppearance.BorderColor = $cBorder
    }

    foreach ($b in @($btnOpen,$btnPlayPause,$btnStartRedaction,$btnAddRedaction,$btnClearScreen)) {
        $b.BackColor = $cAccent
        $b.ForeColor = [System.Drawing.Color]::White
        $b.FlatAppearance.BorderColor = $cAccent
    }

    foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbZoom,$rbCrop,$rbModeBlack,$rbModeBlur,$rbModePixelate,$rbText,$rbLine,$rbPolyline)) {
        if ($r.Checked) {
            $r.BackColor = if ($script:isDarkMode) { [System.Drawing.Color]::FromArgb(42,67,96) } else { $cAccent2 }
            $r.ForeColor = $cAccent
            $r.FlatAppearance.BorderColor = $cAccent
        } else {
            $r.BackColor = $cButton
            $r.ForeColor = $cText
            $r.FlatAppearance.BorderColor = $cBorder
        }
    }
    $zoomHud.BackColor = $cPanel
    $lblZoomIndicator.BackColor = [System.Drawing.Color]::Transparent
    $lblZoomIndicator.ForeColor = $cText
    Update-StrengthSliderVisibility
    Update-ThemedIcons $cIconNormal $cAccent
    Update-RightPanelToggleAppearance

    # Redaction Area X/Y/W/H chip fields. Fill/border colors are read live
    # by Enable-RoundedFieldPaint's Paint handler (see that function), so
    # setting the $script: vars here and invalidating is enough to repaint
    # them correctly on a theme switch.
    $script:fieldFillColor = $cInput
    $script:fieldBorderColor = $cBorder
    foreach ($fld in @($lblFieldX,$lblFieldY,$lblFieldW,$lblFieldH)) {
        $fldPanel = $fld.Parent
        $fldPanel.BackColor = $cPanel
        $fldPanel.Controls[0].ForeColor = $cMuted
        $fldPanel.Controls[1].ForeColor = $cText
        $fldPanel.Invalidate()
    }

    # Update-ColorPickerVisibility (and the swatch's own border) reads
    # $script:fieldBorderColor, so this runs after it's set just above.
    Update-ColorPickerVisibility
    $swatchColor.Invalidate()
    $numOutlineWidth.BackColor = $cInput
    $numOutlineWidth.ForeColor = $cText
    $cmbOutlineDash.BackColor = $cInput
    $cmbOutlineDash.ForeColor = $cText
    $cmbOutlineJoin.BackColor = $cInput
    $cmbOutlineJoin.ForeColor = $cText
    $swatchOutlineColor.BackColor = $script:outlineColor
    $swatchOutlineColor.Invalidate()

    # D3 Text Box context editor lives inside its own child panel, so theme it
    # explicitly rather than relying on the top-level control traversal above.
    $textAppearancePanel.BackColor = $cPanel
    foreach ($lbl in @($lblTextContent,$lblTextFont,$lblTextSize,$lblTextStatus)) {
        $lbl.BackColor = [System.Drawing.Color]::Transparent
        $lbl.ForeColor = $cMuted
    }
    foreach ($c in @($txtAnnotationText,$cmbTextFont,$numTextSize,$cmbTextAlign)) {
        $c.BackColor = $cInput
        $c.ForeColor = $cText
    }
    # D5c-r2 floating Text editor uses the same Day/Dark palette as Appearance.
    if ($floatingTextEditor) {
        $floatingTextEditor.BackColor = $cPanel
        $lblFloatingTextEditor.BackColor = [System.Drawing.Color]::Transparent
        $lblFloatingTextEditor.ForeColor = $cMuted
        $txtFloatingAnnotationText.BackColor = $cInput
        $txtFloatingAnnotationText.ForeColor = $cText
    }
    $swatchTextColor.BackColor = $script:textColor
    $swatchTextColor.Invalidate()
    foreach ($b in @($btnAddText,$btnCancelText)) {
        $b.BackColor = if ($b -eq $btnAddText) { $cAccent } else { $cButton }
        $b.ForeColor = if ($b -eq $btnAddText) { [System.Drawing.Color]::White } else { $cText }
        $b.FlatAppearance.BorderColor = if ($b -eq $btnAddText) { $cAccent } else { $cBorder }
    }
    foreach ($b in @($btnAddDraw,$btnCancelDraw)) {
        $b.BackColor = if ($b -eq $btnAddDraw) { $cAccent } else { $cButton }
        $b.ForeColor = if ($b -eq $btnAddDraw) { [System.Drawing.Color]::White } else { $cText }
        $b.FlatAppearance.BorderColor = if ($b -eq $btnAddDraw) { $cAccent } else { $cBorder }
    }
    foreach ($b in @($chkTextBold,$chkTextItalic)) {
        if ($b.Checked) {
            $b.BackColor = if ($script:isDarkMode) { [System.Drawing.Color]::FromArgb(42,67,96) } else { $cAccent2 }
            $b.ForeColor = $cAccent
            $b.FlatAppearance.BorderColor = $cAccent
        }
        else {
            $b.BackColor = $cButton
            $b.ForeColor = $cText
            $b.FlatAppearance.BorderColor = $cBorder
        }
        $b.Invalidate()
    }

    foreach ($c in @($cmbQuality,$cmbFormat)) {
        $c.BackColor = $cInput
        $c.ForeColor = $cText
    }

    # Keep the eyedropper icon on the same base colour as its surrounding
    # panel and without a visible button border. Its glyph itself is still
    # tinted by Update-ThemedIcons for the active Day/Dark theme.
    $btnEyedropper.BackColor = $cPanel
    $btnEyedropper.ForeColor = $cText
    $btnEyedropper.FlatAppearance.BorderSize = 0
        $btnEyedropper.Invalidate()

    $chkAudio.BackColor = $cPanel
    $chkAudio.ForeColor = $cText

    # S1c-r2: the secure-deletion Output controls were introduced after the
    # original theme pass and therefore kept their default WinForms colours.
    # Theme them explicitly so Dark Mode does not render black text on #3C3F47.
    $chkDeleteOriginal.BackColor = $cPanel
    $chkDeleteOriginal.ForeColor = $cText
    $btnDeleteInfo.BackColor = $cButton
    $btnDeleteInfo.ForeColor = $cText
    $btnDeleteInfo.FlatAppearance.BorderColor = $cBorder
    $lblDeleteCapability.BackColor = [System.Drawing.Color]::Transparent
    $lblDeleteCapability.ForeColor = $cMuted

    Update-SecurityModeNote
    Update-AppearanceStatus

    $lvRedactions.BackColor = $cInput
    $lvRedactions.ForeColor = $cText
    $lvAnnotations.BackColor = $cInput
    $lvAnnotations.ForeColor = $cText
    $cmbDrawEnds.BackColor = $cInput
    $cmbDrawEnds.ForeColor = $cText

    $status.ForeColor = $cMuted
    $lblSelStatus.ForeColor = $cMuted
    $lblPending.ForeColor = $cMuted
    $lblBufferNote.ForeColor = $cMuted
    $lblHint.ForeColor = $cMuted
    $lblFile.ForeColor = $cText
    $lblPos.ForeColor = $cMuted
    $lblPosValue.ForeColor = $cText
    $lblFrameCount.ForeColor = $cMuted
    $lblFormat.ForeColor = $cMuted
    $lblQuality.ForeColor = $cMuted
    $lblToolHint.ForeColor = $cMuted
    $lblOutlineWidth.ForeColor = $cMuted

    $script:cButtonCurrent = $cButton
    $script:cTextCurrent = $cText
    $script:cMutedCurrent = $cMuted
    $script:cBorderCurrent = $cBorder
    $script:cAccentCurrent = $cAccent
    Update-ExportButtonAppearance
    if(Get-Command Update-CopyButton -ErrorAction SilentlyContinue){Update-CopyButton}
    Update-TransportButtonVisuals

    $picture.Invalidate()
    $scrubberMarkers.Invalidate()
    if($redactionEditor){
        $redactionEditor.BackColor=$floatingTextEditor.BackColor;$redactionEditor.ForeColor=$floatingTextEditor.ForeColor
        foreach($ctl in @($redactionEditorTitle,$redactionEditorHint)){$ctl.BackColor=$redactionEditor.BackColor;$ctl.ForeColor=$redactionEditor.ForeColor}
    }
}

$btnTheme.Add_Click({
    $script:isDarkMode = -not $script:isDarkMode
    Apply-Theme
    # Apply-Theme itself must not call Update-RedactionButtons (it's invoked
    # once, near the top of the script, before Update-RedactionButtons is
    # defined) -- so re-apply the green/red/grey redaction-button state here,
    # once both functions are known to exist.
    Update-RedactionButtons
})

# ----------------------------
# About dialog
# ----------------------------
# Adds a centered, word-wrapped label to $panel at the current $script:aboutY
# cursor, using the Label control's own preferred-size calculation plus a
# small DPI-safe allowance, then advances the cursor past it.
function Add-CenteredAboutLabel($panel, [string]$text, $font, [System.Drawing.Color]$color, [int]$width, [int]$topPad = 0, [int]$bottomPad = 10) {
    $script:aboutY += $topPad

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Font = $font
    $lbl.ForeColor = $color
    $lbl.BackColor = [System.Drawing.Color]::Transparent
    $lbl.TextAlign = "TopCenter"

    # UI: use the Label control's own layout engine to calculate the wrapped
    # height, then add a small DPI-safe allowance. TextRenderer alone can
    # under-measure the final wrapped line on some Windows DPI/font setups.
    $lbl.AutoSize = $true
    $lbl.MaximumSize = New-Object System.Drawing.Size($width, 0)
    $lbl.MinimumSize = New-Object System.Drawing.Size($width, 0)
    $preferred = $lbl.GetPreferredSize((New-Object System.Drawing.Size($width, 0)))
    $lbl.AutoSize = $false
    $lbl.Location = New-Object System.Drawing.Point(0, $script:aboutY)
    $lbl.Size = New-Object System.Drawing.Size($width, ($preferred.Height + 10))

    $panel.Controls.Add($lbl)
    $script:aboutY += $lbl.Height + $bottomPad
    return $lbl
}

# Builds and shows the About/info dialog: app name, copyright, the no-
# telemetry/no-network statement, license text, and a selectable GitHub URL.
# v2.0 deliberately does not launch the URL. A copy icon places it on the
# clipboard and shows a brief inline status message instead.
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace TRT250 {
    public sealed class CaptureHotkeys : NativeWindow, IDisposable {
        [DllImport("user32.dll", SetLastError=true)] private static extern bool RegisterHotKey(IntPtr window, int id, uint modifiers, uint key);
        [DllImport("user32.dll")] private static extern bool UnregisterHotKey(IntPtr window, int id);
        public event EventHandler ImageRequested;
        public event EventHandler VideoRequested;
        public bool ImageRegistered { get; private set; }
        public bool VideoRegistered { get; private set; }
        public CaptureHotkeys() {
            CreateParams p = new CreateParams();
            p.Caption = "TinyRedactionTool capture hotkeys";
            p.Parent = new IntPtr(-3);
            CreateHandle(p);
        }
        public void Register() {
            ImageRegistered = RegisterHotKey(Handle, 1, 0x4002, 0x2C);
            VideoRegistered = RegisterHotKey(Handle, 2, 0x4006, 0x2C);
        }
        protected override void WndProc(ref Message message) {
            if (message.Msg == 0x312) {
                if (message.WParam.ToInt32() == 1 && ImageRequested != null) ImageRequested(this, EventArgs.Empty);
                if (message.WParam.ToInt32() == 2 && VideoRequested != null) VideoRequested(this, EventArgs.Empty);
            }
            base.WndProc(ref message);
        }
        public void Dispose() {
            if (Handle != IntPtr.Zero) {
                if (ImageRegistered) UnregisterHotKey(Handle, 1);
                if (VideoRegistered) UnregisterHotKey(Handle, 2);
                DestroyHandle();
            }
            ImageRegistered = false; VideoRegistered = false;
        }
    }

    public sealed class DpiScope : IDisposable {
        [DllImport("user32.dll")] private static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
        private IntPtr previous;
        public DpiScope() { try { previous = SetThreadDpiAwarenessContext(new IntPtr(-4)); } catch (EntryPointNotFoundException) {} }
        public void Dispose() { if (previous != IntPtr.Zero) SetThreadDpiAwarenessContext(previous); }
    }

    public sealed class RegionSelector : Form {
        private readonly Bitmap desktop;
        private Point anchor;
        private Rectangle selection;
        private bool dragging;
        public Rectangle SelectedRegion { get; private set; }
        public RegionSelector(Bitmap background, Rectangle virtualBounds) {
            desktop = background;
            AutoScaleMode = AutoScaleMode.None;
            FormBorderStyle = FormBorderStyle.None; StartPosition = FormStartPosition.Manual;
            Bounds = virtualBounds; TopMost = true; ShowInTaskbar = false;
            DoubleBuffered = true; KeyPreview = true; Cursor = Cursors.Cross;
        }
        public static Rectangle NormalizeSelection(Point first, Point last) {
            return Rectangle.FromLTRB(Math.Min(first.X,last.X),Math.Min(first.Y,last.Y),Math.Max(first.X,last.X),Math.Max(first.Y,last.Y));
        }
        protected override void OnShown(EventArgs e) { base.OnShown(e); Activate(); Focus(); }
        protected override void OnMouseDown(MouseEventArgs e) {
            base.OnMouseDown(e);
            if (e.Button == MouseButtons.Right) { DialogResult = DialogResult.Cancel; return; }
            if (e.Button != MouseButtons.Left) return;
            anchor = e.Location; selection = Rectangle.Empty; dragging = true; Capture = true; Invalidate();
        }
        protected override void OnMouseMove(MouseEventArgs e) {
            base.OnMouseMove(e);
            if (dragging) {
                Point end = new Point(Math.Max(0,Math.Min(ClientSize.Width,e.X)),Math.Max(0,Math.Min(ClientSize.Height,e.Y)));
                selection = NormalizeSelection(anchor,end); Invalidate();
            }
        }
        protected override void OnMouseUp(MouseEventArgs e) {
            base.OnMouseUp(e);
            if (!dragging || e.Button != MouseButtons.Left) return;
            selection = NormalizeSelection(anchor,new Point(Math.Max(0,Math.Min(ClientSize.Width,e.X)),Math.Max(0,Math.Min(ClientSize.Height,e.Y))));
            dragging = false; Capture = false;
            if (selection.Width < 2 || selection.Height < 2) { DialogResult = DialogResult.Cancel; return; }
            SelectedRegion = new Rectangle(Bounds.Left+selection.Left,Bounds.Top+selection.Top,selection.Width,selection.Height);
            DialogResult = DialogResult.OK;
        }
        protected override void OnKeyDown(KeyEventArgs e) {
            if (e.KeyCode == Keys.Escape) { DialogResult = DialogResult.Cancel; e.Handled = true; }
            base.OnKeyDown(e);
        }
        protected override void OnPaint(PaintEventArgs e) {
            e.Graphics.DrawImageUnscaled(desktop,0,0);
            using (Brush shade = new SolidBrush(Color.FromArgb(110,0,0,0))) e.Graphics.FillRectangle(shade,ClientRectangle);
            if (selection.Width > 0 && selection.Height > 0) {
                e.Graphics.DrawImage(desktop,selection,selection,GraphicsUnit.Pixel);
                using (Pen pen = new Pen(Color.DodgerBlue,2)) e.Graphics.DrawRectangle(pen,selection);
            }
            Rectangle hint = new Rectangle(20,20,360,30);
            using (Brush shade = new SolidBrush(Color.FromArgb(255,220,65))) e.Graphics.FillRectangle(shade,hint);
            TextRenderer.DrawText(e.Graphics,"Drag to select a region. Esc / right-click cancels.",SystemFonts.MessageBoxFont,hint,Color.Black,TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
            base.OnPaint(e);
        }
    }

    public static class ScreenCapture {
        [DllImport("user32.dll", EntryPoint="IsWindowEnabled")] public static extern bool IsWindowEnabled(IntPtr window);
        public static Bitmap Grab(Rectangle region) {
            if (region.Width < 2 || region.Height < 2) throw new ArgumentException("Capture region is too small.");
            using (DpiScope dpi = new DpiScope()) {
                Bitmap bitmap = new Bitmap(region.Width,region.Height,PixelFormat.Format24bppRgb);
                try {
                    using (Graphics graphics = Graphics.FromImage(bitmap)) graphics.CopyFromScreen(region.Left,region.Top,0,0,region.Size,CopyPixelOperation.SourceCopy);
                    return bitmap;
                } catch { bitmap.Dispose(); throw; }
            }
        }
        public static Rectangle SelectRegion() {
            using (DpiScope dpi = new DpiScope()) {
                Rectangle desktop = SystemInformation.VirtualScreen;
                using (Bitmap bitmap = Grab(desktop))
                using (RegionSelector selector = new RegionSelector(bitmap,desktop)) {
                    return selector.ShowDialog() == DialogResult.OK ? selector.SelectedRegion : Rectangle.Empty;
                }
            }
        }
        public static Rectangle VideoRegion(Rectangle region) {
            // H.264 4:2:0 needs even dimensions. Crop inward by at most one pixel;
            // never capture pixels outside the user's selection.
            return new Rectangle(region.Left,region.Top,region.Width & ~1,region.Height & ~1);
        }
    }

    public sealed class RegionVideoRecorder : IDisposable {
        private Thread worker;
        private readonly ManualResetEvent stop = new ManualResetEvent(false);
        private volatile bool stopping;
        private Process process;
        private volatile int frames;
        private string error = "";
        private bool disposed;
        public bool IsRecording { get { return worker != null && worker.IsAlive; } }
        public int FrameCount { get { return frames; } }
        public string Error { get { return error; } }
        public void Start(string ffmpeg, string output, Rectangle region, int fps) { Start(ffmpeg,output,region,fps,null); }
        public void Start(string ffmpeg, string output, Rectangle region, int fps, Func<Bitmap> frameProvider) {
            if (worker != null || disposed) throw new InvalidOperationException("Recorder cannot be reused.");
            if (fps < 1 || fps > 30 || region.Width < 2 || region.Height < 2 || (region.Width & 1) != 0 || (region.Height & 1) != 0) throw new ArgumentException("Invalid recording dimensions or frame rate.");
            if (!Path.IsPathRooted(ffmpeg) || !Path.IsPathRooted(output) || ffmpeg.IndexOf('"') >= 0 || output.IndexOf('"') >= 0) throw new ArgumentException("Recording paths must be absolute.");
            worker = new Thread(delegate() { Record(ffmpeg,output,region,fps,frameProvider); });
            worker.IsBackground = true; worker.Name = "TRT region recording"; worker.Start();
        }
        private void Record(string ffmpeg, string output, Rectangle region, int fps, Func<Bitmap> provider) {
            Task<string> errors = null;
            byte[] latest = null;
            Stopwatch clock = new Stopwatch();
            try {
                ProcessStartInfo info = new ProcessStartInfo();
                info.FileName = ffmpeg;
                info.Arguments = "-hide_banner -loglevel error -y -f image2pipe -framerate " + fps + " -c:v png -i pipe:0 -an -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p -threads 1 -map_metadata -1 -movflags +faststart \"" + output + "\"";
                info.UseShellExecute = false; info.CreateNoWindow = true;
                info.RedirectStandardInput = true; info.RedirectStandardError = true;
                process = Process.Start(info); errors = process.StandardError.ReadToEndAsync();
                clock.Start();
                do {
                    using (Bitmap image = provider == null ? ScreenCapture.Grab(region) : provider())
                    using (MemoryStream bytes = new MemoryStream()) {
                        if (image.Width != region.Width || image.Height != region.Height) throw new InvalidOperationException("Frame dimensions changed during recording.");
                        image.Save(bytes,ImageFormat.Png); latest = bytes.ToArray();
                    }
                    int target = Math.Max(1,(int)Math.Floor(clock.Elapsed.TotalSeconds * fps)+1);
                    // Repeat the latest frame for missed sample slots, retaining a
                    // monotonic wall-clock duration without a capture-frame backlog.
                    if (target - frames > fps * 10) throw new InvalidOperationException("Screen recording could not keep up with the selected region.");
                    while (frames < target) WriteFrame(latest);
                    int delay = Math.Max(1,(int)(frames * 1000.0 / fps - clock.Elapsed.TotalMilliseconds));
                    stop.WaitOne(delay);
                } while (!stopping);
            } catch (Exception ex) { error = ex.Message; }
            finally {
                clock.Stop();
                if (process != null) {
                    try { process.StandardInput.Close(); } catch {}
                    try {
                        if (!process.WaitForExit(20000)) { process.Kill(); error = "The recording encoder did not finish."; process.WaitForExit(2000); }
                        else if (process.ExitCode != 0 && error.Length == 0) error = "The recording encoder failed.";
                        if (errors != null) {
                            string detail = errors.GetAwaiter().GetResult();
                            if (error.Length > 0 && detail.Length > 0) error += " " + detail.Substring(0,Math.Min(500,detail.Length));
                        }
                    } catch (Exception ex) { if (error.Length == 0) error = ex.Message; }
                    process.Dispose(); process = null;
                }
            }
        }
        private void WriteFrame(byte[] png) {
            process.StandardInput.BaseStream.Write(png,0,png.Length);
            process.StandardInput.BaseStream.Flush(); frames++;
        }
        public void RequestStop() { stopping = true; stop.Set(); }
        public void Dispose() {
            if (disposed) return;
            RequestStop();
            if (worker != null && worker.IsAlive && !worker.Join(22000)) {
                try { if (process != null) process.Kill(); } catch {}
                worker.Join(2000);
            }
            if (worker == null || !worker.IsAlive) stop.Dispose();
            disposed = true;
        }
    }
    public sealed class RecordingStopWindow : Form {
        [System.Runtime.InteropServices.DllImport("user32.dll", SetLastError=true)]
        private static extern bool SetWindowDisplayAffinity(IntPtr window, uint affinity);
        private readonly System.Windows.Forms.Timer blink = new System.Windows.Forms.Timer();
        private readonly Button stopButton = new Button();
        private bool red = true;
        public event EventHandler StopRequested;
        public bool CaptureExcluded { get; private set; }
        public RecordingStopWindow(Rectangle region) {
            FormBorderStyle=FormBorderStyle.None; ShowInTaskbar=false; TopMost=true;
            AutoScaleMode=AutoScaleMode.None; BackColor=Color.FromArgb(255,220,65);
            ClientSize=new Size(190,38); StartPosition=FormStartPosition.Manual;
            Rectangle screen=Screen.FromRectangle(region).Bounds;
            Location=new Point(screen.Left+(screen.Width-Width)/2,screen.Top+10);
            stopButton.Text="Stop Recording"; stopButton.FlatStyle=FlatStyle.Flat;
            stopButton.FlatAppearance.BorderSize=0; stopButton.BackColor=BackColor;
            stopButton.Font=new Font("Segoe UI",10,FontStyle.Bold);
            stopButton.SetBounds(31,0,159,38); Controls.Add(stopButton);
            stopButton.Click+=delegate { var handler=StopRequested; if(handler!=null)handler(this,EventArgs.Empty); };
            blink.Interval=500; blink.Tick+=delegate { red=!red; Invalidate(); }; blink.Start();
        }
        protected override bool ShowWithoutActivation { get { return true; } }
        protected override CreateParams CreateParams { get { var p=base.CreateParams;p.ExStyle|=0x08000080;return p; } }
        protected override void OnHandleCreated(EventArgs e) {
            base.OnHandleCreated(e); CaptureExcluded=SetWindowDisplayAffinity(Handle,0x11);
        }
        protected override void OnPaint(PaintEventArgs e) {
            base.OnPaint(e); e.Graphics.SmoothingMode=System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using(var brush=new SolidBrush(red?Color.Red:BackColor))e.Graphics.FillEllipse(brush,10,12,14,14);
        }
        public void Finishing() { blink.Stop();red=false;stopButton.Text="Finishing...";stopButton.Enabled=false;Invalidate(); }
        protected override void Dispose(bool disposing) { if(disposing){blink.Dispose();stopButton.Font.Dispose();}base.Dispose(disposing); }
    }
    public sealed class RecordingBorder : Form {
        [DllImport("user32.dll",SetLastError=true)] private static extern bool SetWindowDisplayAffinity(IntPtr window,uint affinity);
        private readonly System.Windows.Forms.Timer blink=new System.Windows.Forms.Timer();
        private bool red=true;
        public bool CaptureExcluded {get;private set;}
        public RecordingBorder(Rectangle region) {
            AutoScaleMode=AutoScaleMode.None;FormBorderStyle=FormBorderStyle.None;
            StartPosition=FormStartPosition.Manual;Bounds=region;TopMost=true;ShowInTaskbar=false;
            BackColor=Color.Magenta;TransparencyKey=Color.Magenta;
            blink.Interval=500;blink.Tick+=delegate{red=!red;Invalidate();};blink.Start();
        }
        protected override bool ShowWithoutActivation {get{return true;}}
        protected override CreateParams CreateParams {get{var p=base.CreateParams;p.ExStyle|=0x080000A0;return p;}}
        protected override void OnHandleCreated(EventArgs e){base.OnHandleCreated(e);CaptureExcluded=SetWindowDisplayAffinity(Handle,0x11);}
        protected override void OnPaint(PaintEventArgs e){base.OnPaint(e);if(red)using(var pen=new Pen(Color.Red,3))e.Graphics.DrawRectangle(pen,1,1,Math.Max(1,ClientSize.Width-3),Math.Max(1,ClientSize.Height-3));}
        protected override void Dispose(bool disposing){if(disposing)blink.Dispose();base.Dispose(disposing);}
    }
    public static class CaptureCleanup {
        public static void OverwriteAndDelete(string path,string root) {
            string full=Path.GetFullPath(path), prefix=Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar)+Path.DirectorySeparatorChar;
            if(!full.StartsWith(prefix,StringComparison.OrdinalIgnoreCase)||Path.GetDirectoryName(full)!=prefix.TrimEnd(Path.DirectorySeparatorChar))throw new IOException("Capture cleanup path rejected.");
            if(!File.Exists(full))return;
            if((File.GetAttributes(full)&FileAttributes.ReparsePoint)!=0||(File.GetAttributes(root)&FileAttributes.ReparsePoint)!=0)throw new IOException("Capture cleanup rejects redirected files.");
            using(var file=new FileStream(full,FileMode.Open,FileAccess.ReadWrite,FileShare.None,65536,FileOptions.WriteThrough)){
                long length=file.Length;byte[] zero=new byte[65536];
                while(file.Position<length)file.Write(zero,0,(int)Math.Min(zero.Length,length-file.Position));
                file.Flush(true);file.Position=0;byte[] check=new byte[65536];int count;
                while((count=file.Read(check,0,check.Length))>0)for(int i=0;i<count;i++)if(check[i]!=0)throw new IOException("Capture overwrite verification failed.");
            }
            File.Delete(full);
        }
    }
}

'@

# v2.5.0: tray preferences and native capture are session-local UI/input state.
$script:TraySettings = [pscustomobject]@{ Mode='Exit'; Syncing=$false; AllowQuit=$false; Restoring=$false; NormalState=[System.Windows.Forms.FormWindowState]::Maximized }
$script:CaptureState = [pscustomobject]@{ Busy=$false; Recorder=$null; Output=''; Root=''; Files=(New-Object System.Collections.Generic.List[string]); Hotkeys=$null; Tray=$null; Menu=$null; StopItem=$null; Poll=$null; StopWindow=$null; Border=$null; Quitting=$false; QuitPending=$false }

function Add-CaptureAboutControls($panel,[int]$width,[System.Drawing.Color]$textColor) {
    $settings=$script:TraySettings
    $row=New-Object System.Windows.Forms.Panel
    $row.SetBounds(0,$script:aboutY,$width,26)
    $panel.Controls.Add($row)
    $half=[int]($width/2)
    $minimize=New-Object System.Windows.Forms.CheckBox
    $minimize.Text='Minimize to tray';$minimize.AutoSize=$true;$minimize.Font=New-UIFont 8.5;$minimize.ForeColor=$textColor
    $row.Controls.Add($minimize)
    $exit=New-Object System.Windows.Forms.CheckBox
    $exit.Text='Exit to tray';$exit.AutoSize=$true;$exit.Font=New-UIFont 8.5;$exit.ForeColor=$textColor
    $row.Controls.Add($exit)
    $minimize.Checked=$settings.Mode -eq 'Minimize';$exit.Checked=$settings.Mode -eq 'Exit'
    $minimize.Left=[int](($half-$minimize.PreferredSize.Width)/2)
    $exit.Left=$half+[int](($half-$exit.PreferredSize.Width)/2)
    $minimize.Add_CheckedChanged({
        if($settings.Syncing){return};$settings.Syncing=$true
        try {if($minimize.Checked){$settings.Mode='Minimize';$exit.Checked=$false}else{$settings.Mode='Exit';$exit.Checked=$true}}
        finally {$settings.Syncing=$false}
    }.GetNewClosure())
    $exit.Add_CheckedChanged({
        if($settings.Syncing){return};$settings.Syncing=$true
        try {if($exit.Checked){$settings.Mode='Exit';$minimize.Checked=$false}else{$settings.Mode='Minimize';$minimize.Checked=$true}}
        finally {$settings.Syncing=$false}
    }.GetNewClosure())
    $script:aboutY += 26
    foreach($spec in @(@('CTRL-Print Screen for image capture',0),@('CTRL-SHIFT-Print Screen for video capture',$half))) {
        $label=New-Object System.Windows.Forms.Label
        $label.Text=$spec[0];$label.Font=New-UIFont 8.0;$label.ForeColor=$textColor;$label.TextAlign='MiddleCenter'
        $label.SetBounds($spec[1],$script:aboutY,$half,24)
        $panel.Controls.Add($label)
    }
    $script:aboutY += 30
}

function Restore-TRTFromTray {
    $settings=$script:TraySettings
    $settings.Restoring=$true
    try {
        $form.Show()
        if($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {$form.WindowState=$settings.NormalState}
        $form.BringToFront();$form.Activate()
    } finally {$settings.Restoring=$false}
}

function Hide-TRTToTray {
    if(-not $script:CaptureState.Tray -or -not $script:CaptureState.Tray.Visible) {return}
    Stop-Playback
    if($script:floatingTextEditorVisible) {Close-FloatingTextEditor $false}
    $form.Hide()
}

function Remove-UnusedCaptureFiles {
    $state=$script:CaptureState
    if(-not $state.Root){return}
    foreach($path in @($state.Files.ToArray())) {
        if($path -eq $videoPath -or ($state.Recorder -and $path -eq $state.Output)){continue}
        try {
            [TRT250.CaptureCleanup]::OverwriteAndDelete($path,$state.Root)
            [void]$state.Files.Remove($path)
        } catch {
            [System.Windows.Forms.MessageBox]::Show(('Capture cleanup failed. File retained for retry: '+$path+"`r`n"+$_.Exception.GetBaseException().Message),'Capture cleanup','OK','Warning')|Out-Null
        }
    }
    if(-not $state.Files.Count){
        if($script:CaptureLease){$script:CaptureLease.Dispose();$script:CaptureLease=$null}
        $leasePath=Join-Path $state.Root '.session.lock'
        if(Test-Path -LiteralPath $leasePath){Remove-Item -LiteralPath $leasePath -Force -ErrorAction Stop}
        [IO.Directory]::Delete($state.Root,$false);$state.Root=''
    }
}
function New-CaptureFile([string]$extension) {
    $state=$script:CaptureState
    if(-not $state.Root) {
        $temp=Get-CaptureTempBase
        if(Get-NetworkPathReason $temp) {throw 'Screen capture requires a local temporary folder.'}
        $state.Root=Join-Path $temp ('TinyRedactionTool-Capture-'+[guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($state.Root) | Out-Null
        $script:CaptureLease=[IO.File]::Open((Join-Path $state.Root '.session.lock'),[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
    }
    $path=Join-Path $state.Root ('capture-'+[guid]::NewGuid().ToString('N')+$extension)
    $state.Files.Add($path)
    return $path
}

function Complete-RegionRecording {
    $state=$script:CaptureState
    if(-not $state.Recorder -or $state.Recorder.IsRecording) {return}
    $state.Poll.Stop()
    if($state.Border){$state.Border.Dispose();$state.Border=$null};if($state.StopWindow){$state.StopWindow.Dispose();$state.StopWindow=$null}
    $errorText=[string]$state.Recorder.Error
    $frames=[int]$state.Recorder.FrameCount
    $state.Recorder.Dispose();$state.Recorder=$null
    $state.StopItem.Visible=$false;$state.Tray.Text='TinyRedactionTool v2.5.0'
    $form.Enabled=$true
    $path=[string]$state.Output;$state.Output=''
    if($state.Quitting){return}
    Restore-TRTFromTray
    if($errorText -or $frames -le 0 -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Remove-UnusedCaptureFiles
        [System.Windows.Forms.MessageBox]::Show(('The region recording could not be completed. '+$errorText),'Screen recording','OK','Error') | Out-Null
        return
    }
    Open-TRTMediaPath $path
}

function Stop-RegionRecording {
    if($script:CaptureState.Recorder) {
        if($script:CaptureState.StopWindow){$script:CaptureState.StopWindow.Finishing()}
        $script:CaptureState.Recorder.RequestStop()
        $script:CaptureState.Tray.Text='TinyRedactionTool: finishing recording'
    }
}

function Invoke-RegionCapture([bool]$video=$false) {
    $state=$script:CaptureState
    if($state.Recorder) {if($video){Stop-RegionRecording};return}
    if($script:ExportBusy -or $state.Busy -or -not $form.Enabled -or -not [TRT250.ScreenCapture]::IsWindowEnabled($form.Handle) -or $state.Quitting){return}
    foreach($owned in $form.OwnedForms) {if($owned.Visible -and $owned.Modal){return}}
    $state.Busy=$true
    $wasVisible=$form.Visible
    try {
        Stop-Playback
        if($script:floatingTextEditorVisible){Close-FloatingTextEditor $false}
        $form.Hide()
        [System.Windows.Forms.Application]::DoEvents()
        [Threading.Thread]::Sleep(120)
        $region=[TRT250.ScreenCapture]::SelectRegion()
        if($region.Width -lt 2 -or $region.Height -lt 2){if($wasVisible){Restore-TRTFromTray};return}
        [System.Windows.Forms.Application]::DoEvents()
        [Threading.Thread]::Sleep(80)
        if($video) {
            $region=[TRT250.ScreenCapture]::VideoRegion($region)
            $state.Output=New-CaptureFile '.mp4'
            $state.Border=New-Object TRT250.RecordingBorder($region)
            $state.Border.Show()
            if(-not $state.Border.CaptureExcluded){throw 'Windows could not exclude the recording border from capture.'}
            $state.StopWindow=New-Object TRT250.RecordingStopWindow($region)
            $state.StopWindow.Add_StopRequested({Stop-RegionRecording})
            $state.StopWindow.Show()
            if(-not $state.StopWindow.CaptureExcluded){throw 'Windows could not exclude the recording control from capture.'}
            $state.Recorder=New-Object TRT250.RegionVideoRecorder
            $state.Recorder.Start([IO.Path]::GetFullPath($ffmpeg),$state.Output,$region,15)
            $state.StopItem.Visible=$true
            $state.Tray.Text='TinyRedactionTool: recording region'
            $form.Enabled=$false
            $state.Poll.Start()
            $state.Tray.ShowBalloonTip(3000,'Recording selected region','Click Stop Recording or press Ctrl+Shift+Print Screen to finish. Screen only; no audio.',[System.Windows.Forms.ToolTipIcon]::Info)
        } else {
            $path=New-CaptureFile '.png'
            $bitmap=[TRT250.ScreenCapture]::Grab($region)
            try {$bitmap.Save($path,[System.Drawing.Imaging.ImageFormat]::Png)}finally{$bitmap.Dispose()}
            Restore-TRTFromTray
            Open-TRTMediaPath $path
        }
    } catch {
        if($state.Border){$state.Border.Dispose();$state.Border=$null};if($state.StopWindow){$state.StopWindow.Dispose();$state.StopWindow=$null}
        if($state.Recorder){$state.Recorder.Dispose();$state.Recorder=$null}
        $form.Enabled=$true
        Restore-TRTFromTray
        $state.Output=''
        Remove-UnusedCaptureFiles
        [System.Windows.Forms.MessageBox]::Show($_.Exception.GetBaseException().Message,'Screen capture','OK','Error') | Out-Null
    } finally {$state.Busy=$false;if($state.QuitPending){Quit-TRTFromTray}}
}

function Quit-TRTFromTray {
    if($script:MediaWorker -and $script:MediaWorker.Kind -eq "Load"){$script:QuitAfterExport=$true;Cancel-VideoLoading;Hide-TRTToTray;return}
    if($script:ExportBusy){$script:QuitAfterExport=$true;Hide-TRTToTray;return}
    $state=$script:CaptureState
    if($state.Busy){$state.QuitPending=$true;return}
    $state.QuitPending=$false
    $state.Quitting=$true
    $script:TraySettings.AllowQuit=$true
    if($state.Recorder) {
        $state.Recorder.Dispose()
        Complete-RegionRecording
    }
    $form.Enabled=$true
    $form.Close()
}

function Initialize-TRTTrayCapture {
    $state=$script:CaptureState
    $state.Menu=New-Object System.Windows.Forms.ContextMenuStrip
    $state.StopItem=New-Object System.Windows.Forms.ToolStripMenuItem('Stop recording')
    $state.StopItem.Visible=$false;$state.StopItem.Add_Click({Stop-RegionRecording})
    [void]$state.Menu.Items.Add($state.StopItem)
    $quit=New-Object System.Windows.Forms.ToolStripMenuItem('Quit')
    $quit.Add_Click({Quit-TRTFromTray});[void]$state.Menu.Items.Add($quit)
    $state.Tray=New-Object System.Windows.Forms.NotifyIcon
    $state.Tray.Icon=$form.Icon
    $state.Tray.Text='TinyRedactionTool v2.5.0';$state.Tray.ContextMenuStrip=$state.Menu
    $state.Tray.Add_MouseClick({param($sender,$e) if($e.Button -eq [System.Windows.Forms.MouseButtons]::Left){Restore-TRTFromTray}})
    $state.Tray.Visible=$true
    $state.Poll=New-Object System.Windows.Forms.Timer
    $state.Poll.Interval=200;$state.Poll.Add_Tick({Complete-RegionRecording})
    $form.Add_Resize({
        $settings=$script:TraySettings
        if($settings.Restoring){return}
        if($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
            if($settings.Mode -eq 'Minimize'){Hide-TRTToTray}
        } else {$settings.NormalState=$form.WindowState}
    })
    $form.Add_FormClosing({
        param($sender,$e)
        if($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and -not $script:TraySettings.AllowQuit -and $script:TraySettings.Mode -eq 'Exit') {
            $e.Cancel=$true;[void]$form.BeginInvoke([System.Action]{if(-not $form.IsDisposed -and -not $script:TraySettings.AllowQuit){Hide-TRTToTray}})
        }
    })
    $form.Add_Shown({
        if($script:CaptureState.Hotkeys){return}
        try {
            $script:CaptureState.Hotkeys=New-Object TRT250.CaptureHotkeys
            $script:CaptureState.Hotkeys.Add_ImageRequested({Invoke-RegionCapture $false})
            $script:CaptureState.Hotkeys.Add_VideoRequested({Invoke-RegionCapture $true})
            $script:CaptureState.Hotkeys.Register()
            $missing=New-Object System.Collections.Generic.List[string]
            if(-not $script:CaptureState.Hotkeys.ImageRegistered){$missing.Add('Ctrl+Print Screen')}
            if(-not $script:CaptureState.Hotkeys.VideoRegistered){$missing.Add('Ctrl+Shift+Print Screen')}
            if($missing.Count) {[System.Windows.Forms.MessageBox]::Show(('Capture shortcut unavailable: '+($missing -join ', ')+'. Another application may already use it.'),'Capture shortcuts','OK','Information') | Out-Null}
        } catch {[System.Windows.Forms.MessageBox]::Show('Windows could not register the capture shortcuts. Tray controls remain available.','Capture shortcuts','OK','Information') | Out-Null}
    })
    $form.Add_FormClosed({
        $state=$script:CaptureState;$state.Quitting=$true
        if($state.Poll){$state.Poll.Stop();$state.Poll.Dispose()}
        if($state.Hotkeys){$state.Hotkeys.Dispose()}
        if($state.Border){$state.Border.Dispose();$state.Border=$null};if($state.StopWindow){$state.StopWindow.Dispose();$state.StopWindow=$null}
        if($state.Recorder){$state.Recorder.Dispose();$state.Recorder=$null}
        if($state.Tray){$state.Tray.Visible=$false;$state.Tray.Dispose()}
        if($state.Menu){$state.Menu.Dispose()}
        # Session-owned captures are separate from user-supplied originals.
        # Release preview state before overwriting these generated files.
        $script:videoPath=$null
        Remove-UnusedCaptureFiles
    })
}


function Show-AboutDialog {
    $isDark = $script:isDarkMode
    $cBg     = if ($isDark) { [System.Drawing.Color]::FromArgb(60,63,71) } else { [System.Drawing.Color]::FromArgb(223,238,245) }
    $cText   = if ($isDark) { [System.Drawing.Color]::FromArgb(241,245,249) } else { [System.Drawing.Color]::FromArgb(18,27,42) }
    $cMuted  = if ($isDark) { [System.Drawing.Color]::FromArgb(192,199,208) } else { [System.Drawing.Color]::FromArgb(99,112,132) }
    $cAccent = if ($isDark) { [System.Drawing.Color]::FromArgb(70,150,255) } else { [System.Drawing.Color]::FromArgb(18,113,255) }
    $cBorder = if ($isDark) { [System.Drawing.Color]::FromArgb(100,105,117) } else { [System.Drawing.Color]::FromArgb(218,224,232) }

    $dlgWidth = 560
    $contentWidth = $dlgWidth - 40

    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = "About TinyRedactionTool"
    $dlg.StartPosition = "CenterParent"
    $dlg.FormBorderStyle = "FixedDialog"
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.BackColor = $cBg
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, 300)
    $dlg.Font = New-UIFont 9.0
    $dlg.AutoScaleMode = "Dpi"

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(20,14)
    $panel.Size = New-Object System.Drawing.Size($contentWidth, 1)
    $panel.AutoSize = $false
    $dlg.Controls.Add($panel)

    $script:aboutY = 0
    $aboutEmphasis = if ($isDark) { $cText } else { [System.Drawing.Color]::Black }

    Add-CenteredAboutLabel $panel "TinyRedactionTool v2.5.0" (New-UIFont 15.5 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 6 | Out-Null
    Add-CaptureAboutControls $panel $contentWidth $cText
    Add-CenteredAboutLabel $panel "Copyright (C) 2026 David McCabe" (New-UIFont 9.5 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 0 5 | Out-Null
    Add-CenteredAboutLabel $panel "Local media processing. No telemetry or media uploads." (New-UIFont 8.5 ([System.Drawing.FontStyle]::Bold)) $aboutEmphasis $contentWidth 0 0 | Out-Null
    Add-CenteredAboutLabel $panel "Licensed under GPL-2.0-or-later. Source available on GitHub." (New-UIFont 8.5) $cMuted $contentWidth -4 0 | Out-Null

    if ($script:ManagedPolicy) {
        Add-CenteredAboutLabel $panel ("Managed policy: {0} ({1})" -f $script:ManagedPolicy.PolicyId, $script:ManagedPolicy.PolicyVersion) (New-UIFont 8.3 ([System.Drawing.FontStyle]::Bold)) $cText $contentWidth 2 0 | Out-Null
        $managedControls = New-Object System.Collections.Generic.List[string]
        if ($script:ManagedPolicy.BlockNetworkSource) { [void]$managedControls.Add("block network source") }
        if ($script:ManagedPolicy.BlockNetworkDestination) { [void]$managedControls.Add("block network destination") }
        if ($script:ManagedPolicy.DisableSourceDeletion) { [void]$managedControls.Add("disable source deletion") }
        if ($script:ManagedPolicy.DisableAudioRetention) { [void]$managedControls.Add("disable audio retention") }
        if ($script:ManagedPolicy.DisableVisualObscuration) { [void]$managedControls.Add("disable visual obscuration") }
        $managedControlText = if ($managedControls.Count -gt 0) { [string]::Join("; ", $managedControls) } else { "none (public behaviour remains active)" }
        Add-CenteredAboutLabel $panel ("Managed controls: " + $managedControlText) (New-UIFont 8.1) $cMuted $contentWidth -4 0 | Out-Null
        Add-CenteredAboutLabel $panel "v2.5.0 adds tray controls and native region capture; accepted G2d restrictions remain unchanged." (New-UIFont 8.1) $cMuted $contentWidth -4 2 | Out-Null
    }

    $repoUrl = "https://github.com/mccabedd/tinyredactiontool/"

    # Keep the URL and copy affordance as one compact centred group instead
    # of pinning the icon to the far-right edge of the dialog.
    $urlBox = New-Object System.Windows.Forms.TextBox
    $urlBox.Text = $repoUrl
    $urlBox.ReadOnly = $true
    $urlBox.TabStop = $false
    $urlBox.SelectionStart = 0
    $urlBox.SelectionLength = 0
    $urlBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $urlBox.BackColor = $cBg
    $urlBox.ForeColor = $cText
    $urlBox.Font = New-UIFont 9.0

    $urlTextSize = [System.Windows.Forms.TextRenderer]::MeasureText($repoUrl, $urlBox.Font)
    $urlBoxWidth = $urlTextSize.Width + 2
    $copyGap = 6
    $copySize = 24
    $urlGroupWidth = $urlBoxWidth + $copyGap + $copySize

    $urlRow = New-Object System.Windows.Forms.Panel
    $urlRow.Location = New-Object System.Drawing.Point(
        [int](($contentWidth - $urlGroupWidth) / 2),
        ([Math]::Max(0, $script:aboutY - 4))
    )
    $urlRow.Size = New-Object System.Drawing.Size($urlGroupWidth, 28)
    $urlRow.BackColor = [System.Drawing.Color]::Transparent
    $panel.Controls.Add($urlRow)

    $urlBox.Location = New-Object System.Drawing.Point(0,5)
    $urlBox.Size = New-Object System.Drawing.Size($urlBoxWidth,20)
    $urlRow.Controls.Add($urlBox)

    # Use an icon-only PictureBox rather than a tiny styled Button. This keeps
    # the copy glyph visually clean and lets SizeMode=Zoom scale the RGBA icon
    # properly without WinForms button-image clipping/chrome.
    $btnCopyUrl = New-Object System.Windows.Forms.PictureBox
    $btnCopyUrl.Size = New-Object System.Drawing.Size($copySize,$copySize)
    $btnCopyUrl.Location = New-Object System.Drawing.Point(($urlBoxWidth + $copyGap),2)
    $btnCopyUrl.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $btnCopyUrl.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnCopyUrl.BackColor = [System.Drawing.Color]::Transparent
    $copyIconColor = if ($isDark) { [System.Drawing.Color]::FromArgb(240,240,240) } else { [System.Drawing.Color]::FromArgb(32,32,32) }
    $btnCopyUrl.Image = Get-ThemedIconImage "copy" $copyIconColor
    $urlRow.Controls.Add($btnCopyUrl)

    $copyStatus = New-Object System.Windows.Forms.Label
    $copyStatus.Text = ""
    $copyStatus.TextAlign = "TopCenter"
    $copyStatus.Font = New-UIFont 8.2
    $copyStatus.ForeColor = $cMuted
    $copyStatus.BackColor = [System.Drawing.Color]::Transparent
    $copyStatus.Location = New-Object System.Drawing.Point(0, ($script:aboutY + 24))
    $copyStatus.Size = New-Object System.Drawing.Size($contentWidth, 16)
    $panel.Controls.Add($copyStatus)

    $copyNoticeTimer = New-Object System.Windows.Forms.Timer
    $copyNoticeTimer.Interval = 1500
    $copyNoticeTimer.Add_Tick({
        $copyNoticeTimer.Stop()
        $copyStatus.Text = ""
    }.GetNewClosure())

    $btnCopyUrl.Add_Click({
        $copied = $false
        for ($attempt = 0; $attempt -lt 3 -and -not $copied; $attempt++) {
            try {
                [System.Windows.Forms.Clipboard]::SetText($repoUrl)
                $copied = $true
            }
            catch {
                Start-Sleep -Milliseconds 60
            }
        }

        $copyNoticeTimer.Stop()
        if ($copied) {
            $copyStatus.Text = "URL has been copied to Clipboard"
            $copyStatus.ForeColor = $cMuted
        }
        else {
            $copyStatus.Text = "Could not copy URL to Clipboard"
            $copyStatus.ForeColor = [System.Drawing.Color]::FromArgb(200,70,70)
        }
        $copyNoticeTimer.Start()
    }.GetNewClosure())

    # Use a dialog-local ToolTip for the PictureBox copy affordance.
    # The shared application ToolTip is not reliable on this nested control
    # inside a modal dialog on some WinForms/PowerShell 5.1 setups.
    $aboutToolTip = New-Object System.Windows.Forms.ToolTip
    $aboutToolTip.ShowAlways = $true
    $aboutToolTip.InitialDelay = 350
    $aboutToolTip.ReshowDelay = 100
    $aboutToolTip.AutoPopDelay = 3000

    $btnCopyUrl.Add_MouseEnter({
        $aboutToolTip.Show(
            "Copy GitHub URL",
            $btnCopyUrl,
            0,
            ($btnCopyUrl.Height + 2),
            3000
        )
    }.GetNewClosure())

    $btnCopyUrl.Add_MouseLeave({
        $aboutToolTip.Hide($btnCopyUrl)
    }.GetNewClosure())

    $script:aboutY += 40

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Size = New-Object System.Drawing.Size(90,30)
    $btnClose.Location = New-Object System.Drawing.Point((($contentWidth - 90) / 2), $script:aboutY)
    $btnClose.DialogResult = [System.Windows.Forms.DialogResult]::OK
    Style-FlatButton $btnClose $true
    $btnClose.BackColor = $cAccent
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.FlatAppearance.BorderColor = $cAccent
    $panel.Controls.Add($btnClose)
    $script:aboutY += $btnClose.Height + 6

    $panel.Size = New-Object System.Drawing.Size($contentWidth, $script:aboutY)
    $dlg.ClientSize = New-Object System.Drawing.Size($dlgWidth, ($script:aboutY + 24))
    $dlg.AcceptButton = $btnClose
    $dlg.Add_Shown({
        $urlBox.SelectionStart = 0
        $urlBox.SelectionLength = 0
        $btnClose.Select()
    }.GetNewClosure())

    $dlg.ShowDialog($form) | Out-Null
    if ($copyNoticeTimer) {
        $copyNoticeTimer.Stop()
        $copyNoticeTimer.Dispose()
    }
    if ($aboutToolTip) {
        $aboutToolTip.Dispose()
    }
    $dlg.Dispose()
}

$btnInfo.Add_Click({ Show-AboutDialog })

$rbModeBlur.Add_CheckedChanged({
    if ($rbModeBlur.Checked -and $script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) {
        $rbModeBlur.Checked = $false
        $rbModeBlack.Checked = $true
        return
    }
    if ($rbModeBlur.Checked) { Show-VisualObscurationWarning }
})
$rbModePixelate.Add_CheckedChanged({
    if ($rbModePixelate.Checked -and $script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) {
        $rbModePixelate.Checked = $false
        $rbModeBlack.Checked = $true
        return
    }
    if ($rbModePixelate.Checked) { Show-VisualObscurationWarning }
})

foreach ($r in @($rbRectangle,$rbOval,$rbFreeform,$rbZoom,$rbCrop,$rbModeBlack,$rbModeBlur,$rbModePixelate,$rbLine,$rbPolyline)) {
    $r.Add_CheckedChanged({
        Apply-Theme
        # Apply-Theme paints the generic accent/neutral palette first.
        # Immediately restore the semantic Begin/End state colours so
        # switching Shape/Zoom/Style cannot turn a valid green/red action blue.
        Update-RedactionButtons
    })
}

Apply-Theme

# ----------------------------
# Geometry mapping
# ----------------------------
# v2.0.0 viewport transform. Slice 4 now exposes manual zoom through the same
# renderer/projection layer established in Slice 3. Navigation, playback, media
# timing and export remain on their proven paths.
function Get-FitZoomFactor {
    if (-not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) { return 1.0 }

    if($isImageMode -and $script:ImageCrop){$videoWidth=$script:ImageCrop.Width;$videoHeight=$script:ImageCrop.Height}
    $viewportWidth = [double]$picture.ClientSize.Width
    $viewportHeight = [double]$picture.ClientSize.Height
    if ($viewportWidth -le 0.0 -or $viewportHeight -le 0.0) { return 1.0 }

    return [double][Math]::Min(
        $viewportWidth / [double]$videoWidth,
        $viewportHeight / [double]$videoHeight
    )
}

function Get-ViewportTransform {
    if (-not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }

    $sourceCanvasWidth=$videoWidth;$sourceCanvasHeight=$videoHeight
    if($isImageMode -and $script:ImageCrop){$videoWidth=$script:ImageCrop.Width;$videoHeight=$script:ImageCrop.Height}
    $viewportWidth = [double]$picture.ClientSize.Width
    $viewportHeight = [double]$picture.ClientSize.Height
    if ($viewportWidth -le 0.0 -or $viewportHeight -le 0.0) { return $null }

    $fitScale = Get-FitZoomFactor
    if ($zoomMode -eq "Fit") {
        # Preserve the exact integer Fit geometry previously produced by
        # PictureBox SizeMode=Zoom. Slice 3 draws the bitmap itself through
        # this transform, so there is still no intentional visible change.
        $displayWidth = [double][int]([double]$videoWidth * [double]$fitScale)
        $displayHeight = [double][int]([double]$videoHeight * [double]$fitScale)
        if ($displayWidth -le 0.0 -or $displayHeight -le 0.0) { return $null }

        $originX = [double][int](($viewportWidth - $displayWidth) / 2.0)
        $originY = [double][int](($viewportHeight - $displayHeight) / 2.0)

        # The legacy PictureBox mapping rounds width/height independently to
        # whole screen pixels. Keep both effective axes here so Slice 2's
        # overlay projection matches that renderer exactly, even where those
        # two rounded ratios differ by a tiny fraction.
        $scaleX = $displayWidth / [double]$videoWidth
        $scaleY = $displayHeight / [double]$videoHeight
        $scale = [Math]::Min($scaleX, $scaleY)
    }
    else {
        $scale = [double]$zoomFactor
        if ([double]::IsNaN($scale) -or [double]::IsInfinity($scale) -or $scale -le 0.0) {
            $scale = [double]$fitScale
        }
        $scale = [Math]::Min([double]$maxZoomFactor, $scale)
        if ($scale -le 0.0 -or [double]::IsNaN($scale) -or [double]::IsInfinity($scale)) { return $null }

        $scaleX = $scale
        $scaleY = $scale
        $displayWidth = [double]$videoWidth * $scale
        $displayHeight = [double]$videoHeight * $scale
        $originX = (($viewportWidth - $displayWidth) / 2.0) + [double]$panOffsetX
        $originY = (($viewportHeight - $displayHeight) / 2.0) + [double]$panOffsetY
    }

    if ($scale -le 0.0 -or [double]::IsNaN($scale) -or [double]::IsInfinity($scale)) { return $null }

    if($isImageMode -and $script:ImageCrop){$originX-=$script:ImageCrop.X*$scaleX;$originY-=$script:ImageCrop.Y*$scaleY;$displayWidth=$sourceCanvasWidth*$scaleX;$displayHeight=$sourceCanvasHeight*$scaleY}
    return [pscustomobject]@{
        Scale = $scale
        ScaleX = [double]$scaleX
        ScaleY = [double]$scaleY
        FitScale = [double]$fitScale
        OriginX = $originX
        OriginY = $originY
        DisplayWidth = $displayWidth
        DisplayHeight = $displayHeight
        MediaWidth = [double]$sourceCanvasWidth
        MediaHeight = [double]$sourceCanvasHeight
        ViewportWidth = $viewportWidth
        ViewportHeight = $viewportHeight
    }
}

function MediaPoint-To-ViewPoint([System.Drawing.PointF]$point) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]($transform.OriginX + ([double]$point.X * $transform.ScaleX))
    $viewY = [single]($transform.OriginY + ([double]$point.Y * $transform.ScaleY))
    return New-Object System.Drawing.PointF($viewX,$viewY)
}

function ViewPoint-To-MediaPoint([System.Drawing.PointF]$point, [bool]$clamp = $false) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $mediaX = ([double]$point.X - $transform.OriginX) / $transform.ScaleX
    $mediaY = ([double]$point.Y - $transform.OriginY) / $transform.ScaleY

    if ($clamp) {
        $mediaX = [Math]::Max(0.0, [Math]::Min($mediaX, $transform.MediaWidth - 1.0))
        $mediaY = [Math]::Max(0.0, [Math]::Min($mediaY, $transform.MediaHeight - 1.0))
    }

    if($clamp -and $isImageMode -and $script:ImageCrop){$mediaX=[Math]::Max($script:ImageCrop.Left,[Math]::Min($script:ImageCrop.Right-1,$mediaX));$mediaY=[Math]::Max($script:ImageCrop.Top,[Math]::Min($script:ImageCrop.Bottom-1,$mediaY))}
    return New-Object System.Drawing.PointF([single]$mediaX, [single]$mediaY)
}

function MediaRect-To-ViewRect([System.Drawing.RectangleF]$rect) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]($transform.OriginX + ([double]$rect.X * $transform.ScaleX))
    $viewY = [single]($transform.OriginY + ([double]$rect.Y * $transform.ScaleY))
    $viewW = [single]([double]$rect.Width * $transform.ScaleX)
    $viewH = [single]([double]$rect.Height * $transform.ScaleY)
    return New-Object System.Drawing.RectangleF($viewX,$viewY,$viewW,$viewH)
}

function MediaPoints-To-ViewPoints($points) {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $output = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    foreach ($point in $points) {
        $viewX = [single]($transform.OriginX + ([double]$point.X * $transform.ScaleX))
        $viewY = [single]($transform.OriginY + ([double]$point.Y * $transform.ScaleY))
        $output.Add((New-Object System.Drawing.PointF($viewX,$viewY)))
    }
    return $output.ToArray()
}

function Get-MediaViewRect {
    $transform = Get-ViewportTransform
    if (-not $transform) { return $null }

    $viewX = [single]$transform.OriginX
    $viewY = [single]$transform.OriginY
    $viewW = [single]$transform.DisplayWidth
    $viewH = [single]$transform.DisplayHeight
    return New-Object System.Drawing.RectangleF($viewX,$viewY,$viewW,$viewH)
}

function Clamp-MediaPoint([System.Drawing.PointF]$point) {
    if ($videoWidth -le 0 -or $videoHeight -le 0) { return $point }

    $x = [Math]::Max(0.0, [Math]::Min([double]$point.X, [double]$videoWidth - 1.0))
    $y = [Math]::Max(0.0, [Math]::Min([double]$point.Y, [double]$videoHeight - 1.0))
    return New-Object System.Drawing.PointF([single]$x, [single]$y)
}


# ===== Resize Slice 1 helpers: Rectangle/Square only =====
# Handles are VIEW-space UI affordances with constant screen-pixel size. The
# rectangle itself remains canonical MEDIA-space geometry at all times.
function Get-RectangleResizeHandleCenters([System.Drawing.RectangleF]$rect) {
    $dr = MediaRect-To-ViewRect $rect
    if (-not $dr) { return @() }

    $left = [double]$dr.X
    $top = [double]$dr.Y
    $right = [double]$dr.X + [double]$dr.Width
    $bottom = [double]$dr.Y + [double]$dr.Height
    $midX = ($left + $right) / 2.0
    $midY = ($top + $bottom) / 2.0

    return @(
        [pscustomobject]@{ Name = "NW"; X = $left;  Y = $top },
        [pscustomobject]@{ Name = "N";  X = $midX;  Y = $top },
        [pscustomobject]@{ Name = "NE"; X = $right; Y = $top },
        [pscustomobject]@{ Name = "E";  X = $right; Y = $midY },
        [pscustomobject]@{ Name = "SE"; X = $right; Y = $bottom },
        [pscustomobject]@{ Name = "S";  X = $midX;  Y = $bottom },
        [pscustomobject]@{ Name = "SW"; X = $left;  Y = $bottom },
        [pscustomobject]@{ Name = "W";  X = $left;  Y = $midY }
    )
}

function Get-RectangleResizeHandleAtViewPoint([System.Drawing.PointF]$viewPoint, [System.Drawing.RectangleF]$rect) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestName = "None"
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-RectangleResizeHandleCenters $rect)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestName = [string]$h.Name
            }
        }
    }
    return $bestName
}

function Get-RectangleResizeCursor([string]$handle) {
    switch ($handle) {
        "N"  { return [System.Windows.Forms.Cursors]::SizeNS }
        "S"  { return [System.Windows.Forms.Cursors]::SizeNS }
        "E"  { return [System.Windows.Forms.Cursors]::SizeWE }
        "W"  { return [System.Windows.Forms.Cursors]::SizeWE }
        "NW" { return [System.Windows.Forms.Cursors]::SizeNWSE }
        "SE" { return [System.Windows.Forms.Cursors]::SizeNWSE }
        "NE" { return [System.Windows.Forms.Cursors]::SizeNESW }
        "SW" { return [System.Windows.Forms.Cursors]::SizeNESW }
        default { return [System.Windows.Forms.Cursors]::Default }
    }
}

function Get-RectangleResizeResult(
    [System.Drawing.RectangleF]$orig,
    [string]$handle,
    [System.Drawing.PointF]$pointer,
    [bool]$constrainSquare,
    [System.Drawing.RectangleF]$bounds
) {
    $minSize = [double]$script:resizeMinMediaSize
    $bL = [double]$bounds.X
    $bT = [double]$bounds.Y
    $bR = [double]$bounds.X + [double]$bounds.Width
    $bB = [double]$bounds.Y + [double]$bounds.Height

    $oL = [double]$orig.X
    $oT = [double]$orig.Y
    $oR = [double]$orig.X + [double]$orig.Width
    $oB = [double]$orig.Y + [double]$orig.Height
    $cx = ($oL + $oR) / 2.0
    $cy = ($oT + $oB) / 2.0

    $px = [Math]::Max($bL, [Math]::Min([double]$pointer.X, $bR))
    $py = [Math]::Max($bT, [Math]::Min([double]$pointer.Y, $bB))

    $l = $oL; $t = $oT; $r = $oR; $b = $oB

    if ($constrainSquare -and (@("NW","NE","SE","SW") -contains $handle)) {
        switch ($handle) {
            "NW" { $ax=$oR; $ay=$oB; $dx=-1.0; $dy=-1.0; $maxX=$ax-$bL; $maxY=$ay-$bT }
            "NE" { $ax=$oL; $ay=$oB; $dx= 1.0; $dy=-1.0; $maxX=$bR-$ax; $maxY=$ay-$bT }
            "SE" { $ax=$oL; $ay=$oT; $dx= 1.0; $dy= 1.0; $maxX=$bR-$ax; $maxY=$bB-$ay }
            "SW" { $ax=$oR; $ay=$oT; $dx=-1.0; $dy= 1.0; $maxX=$ax-$bL; $maxY=$bB-$ay }
        }
        $desired = [Math]::Max([Math]::Abs($px-$ax), [Math]::Abs($py-$ay))
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxX,$maxY))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        if ($dx -lt 0) { $l=$ax-$side; $r=$ax } else { $l=$ax; $r=$ax+$side }
        if ($dy -lt 0) { $t=$ay-$side; $b=$ay } else { $t=$ay; $b=$ay+$side }
    }
    elseif ($constrainSquare -and (@("N","S") -contains $handle)) {
        $anchorY = if ($handle -eq "N") { $oB } else { $oT }
        $desired = [Math]::Abs($py - $anchorY)
        $maxVertical = if ($handle -eq "N") { $anchorY-$bT } else { $bB-$anchorY }
        $maxHorizontal = 2.0 * [Math]::Min($cx-$bL, $bR-$cx)
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxVertical,$maxHorizontal))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        $l=$cx-($side/2.0); $r=$cx+($side/2.0)
        if ($handle -eq "N") { $t=$anchorY-$side; $b=$anchorY } else { $t=$anchorY; $b=$anchorY+$side }
    }
    elseif ($constrainSquare -and (@("E","W") -contains $handle)) {
        $anchorX = if ($handle -eq "W") { $oR } else { $oL }
        $desired = [Math]::Abs($px - $anchorX)
        $maxHorizontal = if ($handle -eq "W") { $anchorX-$bL } else { $bR-$anchorX }
        $maxVertical = 2.0 * [Math]::Min($cy-$bT, $bB-$cy)
        $maxSide = [Math]::Max(0.01, [Math]::Min($maxHorizontal,$maxVertical))
        $side = [Math]::Min($maxSide, [Math]::Max([Math]::Min($minSize,$maxSide), $desired))
        $t=$cy-($side/2.0); $b=$cy+($side/2.0)
        if ($handle -eq "W") { $l=$anchorX-$side; $r=$anchorX } else { $l=$anchorX; $r=$anchorX+$side }
    }
    else {
        switch ($handle) {
            "NW" { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)); $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "N"  { $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "NE" { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)); $t=[Math]::Max($bT,[Math]::Min($py,$oB-$minSize)) }
            "E"  { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)) }
            "SE" { $r=[Math]::Min($bR,[Math]::Max($px,$oL+$minSize)); $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "S"  { $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "SW" { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)); $b=[Math]::Min($bB,[Math]::Max($py,$oT+$minSize)) }
            "W"  { $l=[Math]::Max($bL,[Math]::Min($px,$oR-$minSize)) }
            default { return $orig }
        }
    }

    return New-Object System.Drawing.RectangleF(
        [single]$l,[single]$t,
        [single][Math]::Max(0.01,$r-$l),
        [single][Math]::Max(0.01,$b-$t))
}

function Test-RectangleDraftDragThreshold([System.Drawing.PointF]$startView, [System.Drawing.PointF]$currentView) {
    $dx = [double]$currentView.X - [double]$startView.X
    $dy = [double]$currentView.Y - [double]$startView.Y
    return ([Math]::Sqrt(($dx * $dx) + ($dy * $dy)) -ge [double]$script:resizeDraftDrawThreshold)
}

function Draw-RectangleResizeHandles($gfx, [System.Drawing.RectangleF]$rect) {
    if (-not $script:resizeSlice1Enabled -or -not $gfx) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-RectangleResizeHandleCenters $rect)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}


# ===== Resize Slice 2 helpers: Oval/Circle only =====
# Oval geometry remains the same canonical MEDIA-space RectangleF bounding box
# already used by v2.0.0. Only four VIEW-space handles are exposed: the north,
# east, south and west cardinal points of the ellipse.
function Get-OvalResizeHandleCenters([System.Drawing.RectangleF]$rect) {
    $dr = MediaRect-To-ViewRect $rect
    if (-not $dr) { return @() }

    $left = [double]$dr.X
    $top = [double]$dr.Y
    $right = [double]$dr.X + [double]$dr.Width
    $bottom = [double]$dr.Y + [double]$dr.Height
    $midX = ($left + $right) / 2.0
    $midY = ($top + $bottom) / 2.0

    return @(
        [pscustomobject]@{ Name = "N"; X = $midX;  Y = $top },
        [pscustomobject]@{ Name = "E"; X = $right; Y = $midY },
        [pscustomobject]@{ Name = "S"; X = $midX;  Y = $bottom },
        [pscustomobject]@{ Name = "W"; X = $left;  Y = $midY }
    )
}

function Get-OvalResizeHandleAtViewPoint([System.Drawing.PointF]$viewPoint, [System.Drawing.RectangleF]$rect) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestName = "None"
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-OvalResizeHandleCenters $rect)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestName = [string]$h.Name
            }
        }
    }
    return $bestName
}

function Get-OvalResizeCursor([string]$handle) {
    switch ($handle) {
        "N" { return [System.Windows.Forms.Cursors]::SizeNS }
        "S" { return [System.Windows.Forms.Cursors]::SizeNS }
        "E" { return [System.Windows.Forms.Cursors]::SizeWE }
        "W" { return [System.Windows.Forms.Cursors]::SizeWE }
        default { return [System.Windows.Forms.Cursors]::Default }
    }
}

function Get-OvalResizeResult(
    [System.Drawing.RectangleF]$orig,
    [string]$handle,
    [System.Drawing.PointF]$pointer,
    [bool]$constrainCircle,
    [System.Drawing.RectangleF]$bounds
) {
    # Cardinal-point ellipse resizing is mathematically the same bounding-box
    # edge operation already proven by Slice 1. Shift simply requests the
    # existing 1:1 side-handle constraint, producing a circle.
    if (@("N","E","S","W") -notcontains $handle) { return $orig }
    return Get-RectangleResizeResult $orig $handle $pointer $constrainCircle $bounds
}

function Draw-OvalResizeHandles($gfx, [System.Drawing.RectangleF]$rect) {
    if (-not $script:resizeSlice2Enabled -or -not $gfx) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-OvalResizeHandleCenters $rect)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}
# ===== End Resize Slice 2 helpers =====

# ===== Resize Slice 3 helpers: Freeform vertex editing only =====
# A closed Freeform polygon already stores every vertex as a canonical
# MEDIA-space PointF. These helpers only project the points for screen-space
# handles/hit-testing and return a cloned point list when one vertex moves.
function Get-FreeformVertexHandleCenters($points) {
    if (-not $points -or $points.Count -le 0) { return @() }
    $viewPoints = MediaPoints-To-ViewPoints $points
    if (-not $viewPoints) { return @() }

    $result = @()
    for ($i = 0; $i -lt $viewPoints.Count; $i++) {
        $vp = $viewPoints[$i]
        $result += [pscustomobject]@{ Index = [int]$i; X = [double]$vp.X; Y = [double]$vp.Y }
    }
    return $result
}

function Get-FreeformVertexHandleAtViewPoint([System.Drawing.PointF]$viewPoint, $points) {
    $half = [double]$script:resizeHandleHitSize / 2.0
    $bestIndex = -1
    $bestDist = [double]::PositiveInfinity

    foreach ($h in (Get-FreeformVertexHandleCenters $points)) {
        $dx = [double]$viewPoint.X - [double]$h.X
        $dy = [double]$viewPoint.Y - [double]$h.Y
        if ([Math]::Abs($dx) -le $half -and [Math]::Abs($dy) -le $half) {
            $d2 = ($dx * $dx) + ($dy * $dy)
            if ($d2 -lt $bestDist) {
                $bestDist = $d2
                $bestIndex = [int]$h.Index
            }
        }
    }
    return $bestIndex
}

function Get-FreeformVertexCursor {
    # Cross distinguishes precise single-vertex editing from SizeAll, which
    # continues to mean "move the whole closed Freeform shape".
    return [System.Windows.Forms.Cursors]::Cross
}

function Get-FreeformVertexEditResult(
    $points,
    [int]$vertexIndex,
    [System.Drawing.PointF]$pointer,
    [System.Drawing.RectangleF]$bounds
) {
    if (-not $points -or $vertexIndex -lt 0 -or $vertexIndex -ge $points.Count) { return ,$points }

    $bL = [double]$bounds.X
    $bT = [double]$bounds.Y
    $bR = [double]$bounds.X + [double]$bounds.Width
    $bB = [double]$bounds.Y + [double]$bounds.Height
    $x = [Math]::Max($bL, [Math]::Min([double]$pointer.X, $bR))
    $y = [Math]::Max($bT, [Math]::Min([double]$pointer.Y, $bB))

    $result = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    for ($i = 0; $i -lt $points.Count; $i++) {
        if ($i -eq $vertexIndex) {
            [void]$result.Add((New-Object System.Drawing.PointF([single]$x,[single]$y)))
        }
        else {
            $p = $points[$i]
            [void]$result.Add((New-Object System.Drawing.PointF([single]$p.X,[single]$p.Y)))
        }
    }
    return ,$result
}

function Draw-FreeformVertexHandles($gfx, $points) {
    if (-not $script:resizeSlice3Enabled -or -not $gfx -or -not $points -or $points.Count -lt 3) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    try {
        foreach ($h in (Get-FreeformVertexHandleCenters $points)) {
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
    }
}

# Resize Slice 3 r2: when a CLOSED, uncommitted Freeform is clicked outside,
# that first click is a dismissal gesture only. Clear the existing draft and
# consume the click; the next click may then start a new Freeform normally.
function Clear-ClosedFreeformDraftForOutsideClick {
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    Update-PreviewCursor
}
# ===== End Resize Slice 3 helpers =====

# ===== End Resize Slice 1 helpers =====

function Reset-ViewportState {
    $script:zoomMode = "Fit"
    $script:zoomFactor = 1.0
    $script:panOffsetX = 0.0
    $script:panOffsetY = 0.0
    Update-ZoomHud
}

function Position-ZoomHud {
    if (-not $zoomHud -or -not $picture -or $zoomHud.IsDisposed -or $picture.IsDisposed) { return }
    $x = [Math]::Max($script:UiGap, $picture.ClientSize.Width - $zoomHud.Width - ($script:UiGap * 2))
    $y = [Math]::Max($script:UiGap, $picture.ClientSize.Height - $zoomHud.Height - ($script:UiGap * 2))
    $zoomHud.Location = New-Object System.Drawing.Point($x,$y)
    $zoomHud.BringToFront()
}

function Update-ZoomHud {
    if (-not $zoomHud -or -not $lblZoomIndicator) { return }

    $hasMedia = [bool]($videoPath -and $previewImage -and $videoWidth -gt 0 -and $videoHeight -gt 0)
    $zoomHud.Visible = $hasMedia
    if (-not $hasMedia) { return }

    $scale = if ($zoomMode -eq "Fit") { Get-FitZoomFactor } else { [double]$zoomFactor }
    if ([double]::IsNaN($scale) -or [double]::IsInfinity($scale) -or $scale -le 0.0) { $scale = 1.0 }
    $pct = [int][Math]::Round($scale * 100.0)
    if ($pct -lt 1) { $pct = 1 }
    $lblZoomIndicator.Text = if ($zoomMode -eq "Fit") { "Fit ($pct%)" } else { "$pct%" }

    $btnZoomIn.Enabled = ($scale -lt ([double]$maxZoomFactor - 0.000001))
    $btnZoomOut.Enabled = ($scale -gt ([double]$minZoomFactor + 0.000001))
    $btnZoomFit.Enabled = ($zoomMode -ne "Fit")
    Position-ZoomHud
}

function Clamp-ViewportPan([double]$minimumMaxX = 0.0, [double]$minimumMaxY = 0.0) {
    # Pan is purely VIEW state. Bound each axis at the natural edge limit:
    # when media is larger than the viewport it cannot be dragged past an edge
    # into avoidable blank space; when media is smaller it may move within the
    # available letterbox but cannot be dragged partly out of the viewport.
    if ($zoomMode -ne "Manual" -or -not $picture -or $videoWidth -le 0 -or $videoHeight -le 0) {
        if ($zoomMode -eq "Fit") {
            $script:panOffsetX = 0.0
            $script:panOffsetY = 0.0
        }
        return
    }

    $vw = [double]$picture.ClientSize.Width
    $vh = [double]$picture.ClientSize.Height
    $scale = [double]$zoomFactor
    if ($vw -le 0.0 -or $vh -le 0.0 -or $scale -le 0.0) { return }

    if($isImageMode -and $script:ImageCrop){$videoWidth=$script:ImageCrop.Width;$videoHeight=$script:ImageCrop.Height}
    $displayWidth = [double]$videoWidth * $scale
    $displayHeight = [double]$videoHeight * $scale
    $maxPanX = [Math]::Max([Math]::Abs($displayWidth - $vw) / 2.0, [Math]::Abs($minimumMaxX))
    $maxPanY = [Math]::Max([Math]::Abs($displayHeight - $vh) / 2.0, [Math]::Abs($minimumMaxY))

    $script:panOffsetX = [Math]::Max(-$maxPanX, [Math]::Min($maxPanX, [double]$panOffsetX))
    $script:panOffsetY = [Math]::Max(-$maxPanY, [Math]::Min($maxPanY, [double]$panOffsetY))
}

function Reset-ZoomPanGesture {
    $script:zoomPanCandidate = $false
    $script:zoomPanning = $false
    $script:middlePanActive = $false
    $script:rightPanActive = $false
    $script:zoomPanStartPoint = New-Object System.Drawing.PointF(0,0)
    $script:zoomPanStartOffsetX = 0.0
    $script:zoomPanStartOffsetY = 0.0
    if ($picture -and -not $picture.IsDisposed -and $picture.Capture) {
        $picture.Capture = $false
    }
}

function Test-CursorOverPreview {
    if (-not $picture -or $picture.IsDisposed -or -not $picture.Visible) { return $false }
    try {
        $clientPoint = $picture.PointToClient([System.Windows.Forms.Cursor]::Position)
        return $picture.ClientRectangle.Contains($clientPoint)
    }
    catch {
        return $false
    }
}

function Stop-SpacePanMode {
    if (-not $script:spacePanActive) { return }
    $script:spacePanActive = $false
    Reset-ZoomPanGesture
    Update-PreviewCursor
}

function Stop-MiddlePanMode {
    if (-not $script:middlePanActive) { return }

    $wasPanning = [bool]$script:zoomPanning
    $startOffsetX = [double]$script:zoomPanStartOffsetX
    $startOffsetY = [double]$script:zoomPanStartOffsetY
    Reset-ZoomPanGesture

    if ($wasPanning) {
        Clamp-ViewportPan ([Math]::Abs($startOffsetX)) ([Math]::Abs($startOffsetY))
        $picture.Refresh()
    }

    # Eyedropper owns the normal crosshair while armed. Restore it explicitly
    # because Update-PreviewCursor intentionally does not override eyedropper.
    if ($eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    }
    else {
        Update-PreviewCursor
    }
}

function Stop-RightPanMode {
    if (-not $script:rightPanActive) { return $false }

    $wasPanning = [bool]$script:zoomPanning
    $startOffsetX = [double]$script:zoomPanStartOffsetX
    $startOffsetY = [double]$script:zoomPanStartOffsetY
    Reset-ZoomPanGesture

    if ($wasPanning) {
        Clamp-ViewportPan ([Math]::Abs($startOffsetX)) ([Math]::Abs($startOffsetY))
        $picture.Refresh()
    }

    if ($eyedropperActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    }
    else {
        Update-PreviewCursor
    }

    return $wasPanning
}

function Set-ZoomFit {
    if (-not $previewImage) { return }
    Reset-ZoomPanGesture
    $script:zoomMode = "Fit"
    $script:zoomFactor = 1.0
    $script:panOffsetX = 0.0
    $script:panOffsetY = 0.0
    Update-ZoomHud
    $picture.Refresh()
}

function Set-ZoomAroundViewPoint([double]$targetScale, [System.Drawing.PointF]$viewPoint) {
    if (-not $previewImage -or $videoWidth -le 0 -or $videoHeight -le 0) { return }

    $before = Get-ViewportTransform
    if (-not $before) { return }

    # Capture the canonical media point under the requested screen point BEFORE
    # changing scale. The new pan offset is then solved so this same media point
    # lands back on the exact same screen point after zooming.
    $mediaX = ([double]$viewPoint.X - [double]$before.OriginX) / [double]$before.ScaleX
    $mediaY = ([double]$viewPoint.Y - [double]$before.OriginY) / [double]$before.ScaleY

    $targetScale = [Math]::Max([double]$minZoomFactor, [Math]::Min([double]$maxZoomFactor, $targetScale))
    if ([double]::IsNaN($targetScale) -or [double]::IsInfinity($targetScale) -or $targetScale -le 0.0) { return }

    $vw = [double]$picture.ClientSize.Width
    $vh = [double]$picture.ClientSize.Height
    if ($vw -le 0.0 -or $vh -le 0.0) { return }

    $baseOriginX = ($vw - ([double]$videoWidth * $targetScale)) / 2.0
    $baseOriginY = ($vh - ([double]$videoHeight * $targetScale)) / 2.0

    if($isImageMode -and $script:ImageCrop){$baseOriginX=($vw-$script:ImageCrop.Width*$targetScale)/2.0-$script:ImageCrop.X*$targetScale;$baseOriginY=($vh-$script:ImageCrop.Height*$targetScale)/2.0-$script:ImageCrop.Y*$targetScale}
    $script:zoomMode = "Manual"
    $script:zoomFactor = $targetScale
    $script:panOffsetX = [double]$viewPoint.X - $baseOriginX - ($mediaX * $targetScale)
    $script:panOffsetY = [double]$viewPoint.Y - $baseOriginY - ($mediaY * $targetScale)

    Update-ZoomHud
    $picture.Refresh()
}

function Step-ZoomAtViewPoint([int]$direction, [System.Drawing.PointF]$viewPoint) {
    if (-not $previewImage -or $direction -eq 0) { return }
    $currentScale = if ($zoomMode -eq "Fit") { Get-FitZoomFactor } else { [double]$zoomFactor }
    if ($currentScale -le 0.0) { $currentScale = 1.0 }
    if ($direction -gt 0 -and $currentScale -ge [double]$maxZoomFactor) { return }
    if ($direction -lt 0 -and $currentScale -le [double]$minZoomFactor) { return }

    $factor = [double]$zoomStepFactor
    $target = if ($direction -gt 0) { $currentScale * $factor } else { $currentScale / $factor }
    Set-ZoomAroundViewPoint $target $viewPoint
}

function Get-ViewportCenterPoint {
    return New-Object System.Drawing.PointF(
        [single]([double]$picture.ClientSize.Width / 2.0),
        [single]([double]$picture.ClientSize.Height / 2.0))
}

function Initialize-ZoomCursor {
    if ($script:zoomCursor) { return }
    try {
        # White outer glyph + slightly smaller black glyph gives the cursor a
        # two-tone edge that remains legible over both bright and dark media.
        $bmp = New-Object System.Drawing.Bitmap(32,32,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $outer = Get-ThemedIconImage "zoom" ([System.Drawing.Color]::White)
        $inner = Get-ThemedIconImage "zoom" ([System.Drawing.Color]::Black)
        $g.DrawImage($outer, (New-Object System.Drawing.Rectangle(0,0,32,32)))
        $g.DrawImage($inner, (New-Object System.Drawing.Rectangle(1,1,30,30)))
        $hIcon = $bmp.GetHicon()
        try {
            $hCursor = [ZoomCursorNativeV1]::CreateCursorFromIcon($hIcon, 11, 11)
            if ($hCursor -ne [IntPtr]::Zero) {
                $script:zoomCursorHandle = $hCursor
                $script:zoomCursor = [System.Windows.Forms.Cursor]::new($hCursor)
            }
        }
        finally {
            [ZoomCursorNativeV1]::DestroyIconHandle($hIcon)
        }
        $g.Dispose()
        $bmp.Dispose()
    }
    catch {
        $script:zoomCursor = $null
        $script:zoomCursorHandle = [IntPtr]::Zero
    }
}

function Update-PreviewCursor {
    if (-not $picture) { return }
    if ($script:middlePanActive -or $script:rightPanActive) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }
    if ($eyedropperActive) { return }
    if ($script:spacePanActive) {
        # Space is a temporary viewport override only; the underlying drawing
        # tool remains selected and resumes the instant Space is released.
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    elseif ($script:zoomToolActive) {
        if ($script:zoomPanCandidate -or $script:zoomPanning) {
            # WinForms has no standard closed-grab cursor; Hand is the closest
            # familiar visual language while a pan gesture is in progress.
            $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        }
        else {
            Initialize-ZoomCursor
            $picture.Cursor = if ($script:zoomCursor) { $script:zoomCursor } else { [System.Windows.Forms.Cursors]::Cross }
        }
    }
    elseif (Test-IsStandaloneDrawTool) {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Cross
    }
    else {
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
    }
}

# Attach only AFTER the Slice 4 helper functions exist. The PictureBox can resize
# several times while the form is still being built; wiring this earlier would
# let construction-time Resize events call helpers PowerShell has not defined yet.
# Refresh() deliberately preserves the Slice 3 r2 full-repaint fix.
$picture.Add_Resize({
    Position-ZoomHud
    Update-ZoomHud
    if ($picture -and -not $picture.IsDisposed) { $picture.Refresh() }
})
Position-ZoomHud
Update-ZoomHud

# Compatibility wrapper for older call sites. The displayed media rectangle
# now comes from the same viewport transform that draws the preview itself.
function Get-DisplayedImageRect {
    if (-not $previewImage) { return $null }
    $viewRect = Get-MediaViewRect
    if (-not $viewRect) { return $null }

    return New-Object System.Drawing.Rectangle([int]$viewRect.X,[int]$viewRect.Y,[int]$viewRect.Width,[int]$viewRect.Height)
}
 
function Clamp-PointToImage([System.Drawing.Point]$pt) {
    $r = Get-DisplayedImageRect
    if (-not $r) { return $pt }
 
    $x = [Math]::Max($r.Left, [Math]::Min($pt.X, $r.Right - 1))
    $y = [Math]::Max($r.Top, [Math]::Min($pt.Y, $r.Bottom - 1))
    return New-Object System.Drawing.Point($x,$y)
}
 
# Draft Rectangle/Oval geometry is already canonical MEDIA space.
# Commit-time normalization is the only conversion left here.
function Selection-To-VideoRect {
    if (-not $selection -or $selection.Width -lt 0.01 -or $selection.Height -lt 0.01) { return $null }
    return Normalize-VideoRect ([double]$selection.X) ([double]$selection.Y) ([double]$selection.Width) ([double]$selection.Height)
}
 
# Legacy-named view helpers now delegate to the v2 viewport transform. Keeping
# these wrappers avoids disturbing the proven committed-redaction model while
# making preview, committed overlays and draft overlays share one projection.
# System.Drawing.Graphics.DrawRectangle has Rectangle/int and float-coordinate
# overloads, but no RectangleF overload. Manual zoom intentionally projects
# media rectangles to RectangleF so sub-pixel viewport positions are preserved.
# Route rectangle outlines through this helper so Fit mode keeps the original
# Rectangle overload while manual zoom uses the float-coordinate overload.
function Draw-ViewportRectangleOutline($gfx, $pen, $rect) {
    if ($null -eq $rect) { return }

    if ($rect -is [System.Drawing.RectangleF]) {
        $gfx.DrawRectangle($pen,
            [single]$rect.X,
            [single]$rect.Y,
            [single]$rect.Width,
            [single]$rect.Height)
    }
    else {
        $gfx.DrawRectangle($pen, $rect)
    }
}

# v2.3.0 D1b: one annotation renderer owns decorative outline geometry for
# preview and export. Geometry/stroke widths are media-pixel values; preview
# supplies the viewport transform while export uses identity coordinates.
# Security redaction rendering never calls this renderer.
function Get-AnnotationDashStyle([string]$name) {
    switch ($name) {
        "Dash"       { return [System.Drawing.Drawing2D.DashStyle]::Dash }
        "Dot"        { return [System.Drawing.Drawing2D.DashStyle]::Dot }
        "DashDot"    { return [System.Drawing.Drawing2D.DashStyle]::DashDot }
        "DashDotDot" { return [System.Drawing.Drawing2D.DashStyle]::DashDotDot }
        default       { return [System.Drawing.Drawing2D.DashStyle]::Solid }
    }
}

function Get-AnnotationLineJoin([string]$name) {
    if ($name -eq "Round") { return [System.Drawing.Drawing2D.LineJoin]::Round }
    return [System.Drawing.Drawing2D.LineJoin]::Miter
}

function New-ShapeOutlineAnnotation($shape, [System.Drawing.Color]$color, [double]$width, [string]$dashStyle = "Solid", [string]$joinStyle = "Square", [int]$ownerIndex = -1, [int]$commitOrder = -1) {
    if (-not $shape) { return $null }
    $shapeName = [string]$shape.Shape
    if ($shapeName -notin @("Rectangle","Oval","Polygon")) { return $null }
    if ($width -lt 1.0) { $width = 1.0 }
    return [PSCustomObject]@{
        Kind = "ShapeOutline"
        Shape = $shapeName
        X = [double]$shape.X
        Y = [double]$shape.Y
        W = [double]$shape.W
        H = [double]$shape.H
        Points = $shape.Points
        StrokeColor = $color
        StrokeWidth = [double]$width
        DashStyle = $dashStyle
        JoinStyle = $joinStyle
        OwnerIndex = [int]$ownerIndex
        CommitOrder = [int]$commitOrder
    }
}

function New-LineDrawingAnnotation(
    [System.Drawing.PointF]$startPoint,
    [System.Drawing.PointF]$endPoint,
    [System.Drawing.Color]$color,
    [double]$width,
    [string]$dashStyle,
    [string]$endpointStyle,
    [int]$commitOrder = -1
) {
    if ($width -lt 1.0) { $width = 1.0 }
    return [PSCustomObject]@{
        Kind = "Line"
        Shape = "Line"
        X1 = [double]$startPoint.X; Y1 = [double]$startPoint.Y
        X2 = [double]$endPoint.X; Y2 = [double]$endPoint.Y
        StrokeColor = $color
        StrokeWidth = [double]$width
        DashStyle = $dashStyle
        JoinStyle = "Miter"
        EndpointStyle = $endpointStyle
        CommitOrder = [int]$commitOrder
    }
}

function New-PolylineDrawingAnnotation(
    $points,
    [System.Drawing.Color]$color,
    [double]$width,
    [string]$dashStyle,
    [string]$joinStyle,
    [string]$endpointStyle,
    [int]$commitOrder = -1
) {
    if (-not $points -or $points.Count -lt 2) { return $null }
    if ($width -lt 1.0) { $width = 1.0 }
    $copy = @()
    foreach ($pt in $points) {
        $copy += [PSCustomObject]@{ X = [double]$pt.X; Y = [double]$pt.Y }
    }
    return [PSCustomObject]@{
        Kind = "Polyline"
        Shape = "Polyline"
        Points = $copy
        StrokeColor = $color
        StrokeWidth = [double]$width
        DashStyle = $dashStyle
        JoinStyle = $joinStyle
        EndpointStyle = $endpointStyle
        CommitOrder = [int]$commitOrder
    }
}

function New-TextDrawingAnnotation(
    [System.Drawing.RectangleF]$rect,
    [string]$content,
    [System.Drawing.Color]$color,
    [string]$fontFamily,
    [double]$fontSizePx,
    [bool]$bold,
    [bool]$italic,
    [string]$alignment,
    [int]$commitOrder = -1
) {
    if ([string]::IsNullOrWhiteSpace($content)) { return $null }
    if ($rect.Width -lt 1.0 -or $rect.Height -lt 1.0) { return $null }
    if ($fontSizePx -lt 1.0) { $fontSizePx = 1.0 }
    return [PSCustomObject]@{
        Kind = "Text"
        Shape = "Text"
        X = [double]$rect.X; Y = [double]$rect.Y
        W = [double]$rect.Width; H = [double]$rect.Height
        Text = $content
        TextColor = $color
        FontFamily = $fontFamily
        FontSizePx = [double]$fontSizePx
        Bold = [bool]$bold
        Italic = [bool]$italic
        Alignment = $alignment
        # Compatibility fields keep the shared renderer's common setup simple.
        StrokeColor = $color
        StrokeWidth = 1.0
        DashStyle = "Solid"
        JoinStyle = "Miter"
        CommitOrder = [int]$commitOrder
    }
}

# Shared timing helper. Still-image annotations use frame 0 only; video D5b-r2
# commits explicit exact Begin/End frames through the shared temporal workflow.
# No annotation range ever receives the redaction safety buffer.
function Set-AnnotationWholeMediaTiming($annotation) {
    if (-not $annotation) { return }
    $startFrame = 0
    $endFrame = if ($isImageMode) { 0 } else { [Math]::Max(0, ([int]$script:totalFrames - 1)) }
    foreach ($pair in @(@('StartFrame',$startFrame),@('EndFrame',$endFrame))) {
        $name=[string]$pair[0]; $value=[int]$pair[1]
        if ($annotation.PSObject.Properties[$name]) { $annotation.$name = $value }
        else { $annotation | Add-Member -NotePropertyName $name -NotePropertyValue $value }
    }
}

function Set-AnnotationFrameTiming($annotation, [int]$startFrame, [int]$endFrame) {
    if (-not $annotation) { return }
    if ($startFrame -lt 0) { $startFrame = 0 }
    $maxFrame = if ($isImageMode) { 0 } else { [Math]::Max(0, ([int]$script:totalFrames - 1)) }
    if ($endFrame -gt $maxFrame) { $endFrame = $maxFrame }
    if ($endFrame -lt $startFrame) { $endFrame = $startFrame }
    foreach ($pair in @(@('StartFrame',$startFrame),@('EndFrame',$endFrame))) {
        $name=[string]$pair[0]; $value=[int]$pair[1]
        if ($annotation.PSObject.Properties[$name]) { $annotation.$name = $value }
        else { $annotation | Add-Member -NotePropertyName $name -NotePropertyValue $value }
    }
}

function Get-AnnotationFrameRange($annotation) {
    if (-not $annotation) { return @{ Start = 0; End = -1 } }
    if ($isImageMode) { return @{ Start = 0; End = 0 } }
    $maxFrame = [Math]::Max(0, ([int]$script:totalFrames - 1))
    $start = if ($annotation.PSObject.Properties['StartFrame']) { [int]$annotation.StartFrame } else { 0 }
    $end = if ($annotation.PSObject.Properties['EndFrame']) { [int]$annotation.EndFrame } else { $maxFrame }
    $start = [Math]::Max(0,[Math]::Min($start,$maxFrame))
    $end = [Math]::Max($start,[Math]::Min($end,$maxFrame))
    return @{ Start = $start; End = $end }
}


# D5b-r2: new video annotations use the same temporal workflow as redactions.
# The draft remains editable until Begin Annotation is pressed; after Begin,
# geometry/style are frozen while the user navigates to the final logical frame.
function Get-CurrentVideoAnnotationDraft {
    if (-not $videoPath -or $isImageMode -or -not (Test-IsStandaloneDrawTool)) { return $null }

    if ($toolMode -eq "Text") {
        return Get-CurrentTextDraftAnnotation
    }
    if ($toolMode -eq "Line" -and $script:lineDraftActive -and $script:lineStart -and $script:lineEnd) {
        return New-LineDrawingAnnotation $script:lineStart $script:lineEnd $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawEndpointStyle -1
    }
    if ($toolMode -eq "Polyline" -and $script:polylineDraftActive -and $script:polylinePoints -and $script:polylinePoints.Count -ge 2) {
        return New-PolylineDrawingAnnotation $script:polylinePoints $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawPolylineJoinStyle $script:drawEndpointStyle -1
    }
    return $null
}

function Test-VideoAnnotationDraftReady {
    return [bool](Get-CurrentVideoAnnotationDraft)
}

function Test-VideoAnnotationDraftPresent {
    if (-not $videoPath -or $isImageMode -or -not (Test-IsStandaloneDrawTool)) { return $false }
    switch ($toolMode) {
        "Text" { return [bool]($script:textDrawing -or $script:textDraftActive) }
        "Line" { return [bool]($script:lineDrawing -or $script:lineDraftActive) }
        "Polyline" { return [bool]($script:polylineActive -or $script:polylineDraftActive -or ($script:polylinePoints -and $script:polylinePoints.Count -gt 0)) }
    }
    return $false
}

function Begin-VideoAnnotationRange {
    if (-not $videoPath -or $isImageMode -or $script:pendingAnnotation) { return $false }
    Stop-Playback
    if ($script:floatingTextEditorVisible) { Close-FloatingTextEditor $false }

    $a = Get-CurrentVideoAnnotationDraft
    if (-not $a) {
        Show-CompactInformationDialog "Annotation timing" "Nothing ready to begin" "Create and position a Text Box, Line, or Polyline first, then choose Begin Annotation."
        return $false
    }

    $script:pendingAnnotation = [PSCustomObject]@{
        Annotation = $a
        StartFrame = [int]$currentFrame
        Tool = [string]$toolMode
    }
    $lblPending.Text = "Annotation started at frame $($currentFrame + 1). Move to the final frame, then click End Annotation."
    Update-RedactionButtons
    Update-AppearanceStatus
    Update-OutlineControlsAvailability
    $picture.Invalidate()
    return $true
}

function Cancel-VideoAnnotationRange {
    if (-not $script:pendingAnnotation) { return $false }
    Stop-Playback
    $startFrame = [int]$script:pendingAnnotation.StartFrame
    $script:pendingAnnotation = $null
    $lblPending.Text = "Annotation range cancelled. Draft restored; adjust it or choose Begin Annotation again."
    Update-RedactionButtons
    Update-AppearanceStatus
    Update-OutlineControlsAvailability
    $picture.Invalidate()
    return $true
}

function End-VideoAnnotationRange {
    if (-not $script:pendingAnnotation) { return $false }
    Stop-Playback

    $startFrame = [int]$script:pendingAnnotation.StartFrame
    if ([int]$currentFrame -lt $startFrame) {
        Show-CompactInformationDialog "Annotation timing" "End frame is before Begin" "Move to frame $($startFrame + 1) or later, then choose End Annotation."
        return $false
    }

    $a = $script:pendingAnnotation.Annotation
    if (-not $a) {
        $script:pendingAnnotation = $null
        Update-RedactionButtons
        return $false
    }

    $a.CommitOrder = Get-NextObjectCommitOrder
    Set-AnnotationFrameTiming $a $startFrame ([int]$currentFrame)
    [void]$script:annotations.Add($a)
    $kindText = if ($a.Kind -eq "Text") { "Text annotation" } elseif ($a.Kind -eq "Line") { "Line annotation" } else { "Polyline annotation" }
    $endFrame = [int]$currentFrame

    $script:pendingAnnotation = $null
    Reset-DrawingState
    Refresh-AnnotationList
    Update-SelectionFields $null
    $lblPending.Text = "$kindText #$($annotations.Count) added: frames $($startFrame + 1)-$($endFrame + 1)."
    Update-RedactionButtons
    Update-InspectorSectionLayout
    $picture.Invalidate()
    return $true
}

function Test-AnnotationFrameActive($annotation, [int]$frameIndex) {
    $range = Get-AnnotationFrameRange $annotation
    return (Test-FrameInRange $frameIndex ([int]$range.Start) ([int]$range.End))
}

function Test-RedactionHasOutline($r) {
    if (-not $r) { return $false }
    $prop = $r.PSObject.Properties["OutlineEnabled"]
    return [bool]($prop -and $r.OutlineEnabled)
}

function Get-RedactionShapeOutline($r, [int]$ownerIndex = -1) {
    if (-not (Test-RedactionHasOutline $r)) { return $null }
    $color = if ($r.PSObject.Properties["OutlineColor"] -and $r.OutlineColor) {
        $r.OutlineColor
    } else {
        [System.Drawing.Color]::Red
    }
    $width = if ($r.PSObject.Properties["OutlineWidth"] -and [double]$r.OutlineWidth -ge 1.0) {
        [double]$r.OutlineWidth
    } else {
        3.0
    }
    $dashStyle = if ($r.PSObject.Properties["OutlineDashStyle"] -and $r.OutlineDashStyle) {
        [string]$r.OutlineDashStyle
    } else {
        "Solid"
    }
    $joinStyle = if ($r.PSObject.Properties["OutlineJoinStyle"] -and $r.OutlineJoinStyle) {
        [string]$r.OutlineJoinStyle
    }
    elseif ($r.PSObject.Properties["OutlineCornerStyle"] -and $r.OutlineCornerStyle) {
        [string]$r.OutlineCornerStyle
    }
    elseif ($r.Shape -eq "Polygon") { "Miter" }
    else { "Square" }
    $commitOrder = if ($r.PSObject.Properties["CommitOrder"]) { [int]$r.CommitOrder } else { -1 }
    $annotation = New-ShapeOutlineAnnotation $r $color $width $dashStyle $joinStyle $ownerIndex $commitOrder
    if ($annotation) {
        $startFrame = if ($r.PSObject.Properties["BufferedStartFrame"]) { [int]$r.BufferedStartFrame } else { 0 }
        $endFrame = if ($r.PSObject.Properties["BufferedEndFrame"]) { [int]$r.BufferedEndFrame } else { $startFrame }
        Set-AnnotationFrameTiming $annotation $startFrame $endFrame
    }
    return $annotation
}

function Get-ImageAnnotationObjects {
    $items = New-Object System.Collections.ArrayList
    # Attached outlines are decorations owned by their redactions.
    for ($i = 0; $i -lt $redactions.Count; $i++) {
        $a = Get-RedactionShapeOutline $redactions[$i] $i
        if ($a) { [void]$items.Add($a) }
    }
    # Standalone annotations are never part of the security-redaction list.
    foreach ($a in $annotations) {
        if ($a) { [void]$items.Add($a) }
    }

    # D1b-r2: the two collections stay structurally separate for security, but
    # visual stacking follows actual commit order. This lets a later redaction
    # cover an earlier annotation while a later annotation can still sit above
    # an earlier redaction. Security processing itself remains redactions-first.
    if ($items.Count -gt 1) {
        $sorted = @($items | Sort-Object @{ Expression = {
            if ($_.PSObject.Properties["CommitOrder"] -and [int]$_.CommitOrder -ge 0) { [int]$_.CommitOrder }
            else { [int]::MaxValue }
        } })
        return ,$sorted
    }
    return ,$items
}

# Builds a transformed path for one committed redaction. It is used only as a
# decorative-annotation occlusion mask: later committed redactions visually cover
# earlier annotation pixels without altering the security render graph.
function New-RedactionGeometryPath(
    $r,
    [double]$scaleX,
    [double]$scaleY,
    [double]$originX,
    [double]$originY
) {
    if (-not $r) { return $null }
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    try {
        if ($r.Shape -eq "Polygon") {
            $pts = @()
            foreach ($p in $r.Points) {
                $px = [single]($originX + ([double]$p.X * $scaleX))
                $py = [single]($originY + ([double]$p.Y * $scaleY))
                $pts += New-Object System.Drawing.PointF($px,$py)
            }
            if ($pts.Count -ge 3) { $path.AddPolygon([System.Drawing.PointF[]]$pts) }
        }
        else {
            $rx = [single]($originX + ([double]$r.X * $scaleX))
            $ry = [single]($originY + ([double]$r.Y * $scaleY))
            $rw = [single]([double]$r.W * $scaleX)
            $rh = [single]([double]$r.H * $scaleY)
            $rect = New-Object System.Drawing.RectangleF($rx,$ry,$rw,$rh)
            if ($rect.Width -gt 0.0 -and $rect.Height -gt 0.0) {
                if ($r.Shape -eq "Oval") { $path.AddEllipse($rect) }
                else { $path.AddRectangle($rect) }
            }
        }
        return $path
    }
    catch {
        $path.Dispose()
        throw
    }
}

function Get-AnnotationArrowGeometry(
    [System.Drawing.PointF]$from,
    [System.Drawing.PointF]$tip,
    [double]$scaledMediaStrokeWidth,
    [double]$geometryScale
) {
    $dx = [double]$tip.X - [double]$from.X
    $dy = [double]$tip.Y - [double]$from.Y
    $len = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    if ($len -lt 0.001) { return $null }

    $ux = $dx / $len; $uy = $dy / $len

    # Arrowhead dimensions are media-space geometry, just like Width. Scale the
    # fixed minimum together with the viewport so zoom cannot change exported size.
    $arrowLen = [Math]::Max((6.0 * $geometryScale), ($scaledMediaStrokeWidth * 4.0))
    $arrowWidth = [Math]::Max((5.0 * $geometryScale), ($scaledMediaStrokeWidth * 3.0))

    $baseX = [double]$tip.X - ($ux * $arrowLen)
    $baseY = [double]$tip.Y - ($uy * $arrowLen)
    $px = -$uy; $py = $ux
    $half = $arrowWidth / 2.0

    # Do not draw the full-width shaft all the way to the arrow tip. If a thick
    # shaft reaches the tip, its rectangular silhouette protrudes through the
    # narrowing triangle and visually flattens the point. Stop the shaft well
    # inside the arrowhead instead. The small overlap prevents anti-aliased gaps.
    $shaftInset = [Math]::Min(($arrowLen * 0.75), ($len * 0.85))
    $shaftJoin = New-Object System.Drawing.PointF(
        [single]([double]$tip.X - ($ux * $shaftInset)),
        [single]([double]$tip.Y - ($uy * $shaftInset)))

    $pts = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF([single]$tip.X,[single]$tip.Y)),
        (New-Object System.Drawing.PointF([single]($baseX + $px*$half),[single]($baseY + $py*$half))),
        (New-Object System.Drawing.PointF([single]($baseX - $px*$half),[single]($baseY - $py*$half)))
    )

    return [PSCustomObject]@{
        Points = $pts
        ShaftJoin = $shaftJoin
    }
}

function Draw-AnnotationArrowHead($gfx, $arrowGeometry, $brush) {
    if (-not $gfx -or -not $arrowGeometry -or -not $brush) { return }
    if (-not $arrowGeometry.Points -or $arrowGeometry.Points.Count -lt 3) { return }
    $gfx.FillPolygon($brush, [System.Drawing.PointF[]]$arrowGeometry.Points)
}

function Test-AnnotationShaftHasForwardLength(
    [System.Drawing.PointF]$originalStart,
    [System.Drawing.PointF]$originalEnd,
    [System.Drawing.PointF]$shaftStart,
    [System.Drawing.PointF]$shaftEnd
) {
    $odx = [double]$originalEnd.X - [double]$originalStart.X
    $ody = [double]$originalEnd.Y - [double]$originalStart.Y
    $sdx = [double]$shaftEnd.X - [double]$shaftStart.X
    $sdy = [double]$shaftEnd.Y - [double]$shaftStart.Y
    return (($odx * $sdx) + ($ody * $sdy)) -gt 0.01
}

function Draw-AnnotationPolylineShaft(
    $gfx,
    $pen,
    [System.Drawing.PointF[]]$points,
    [string]$joinStyle
) {
    if (-not $gfx -or -not $pen -or -not $points -or $points.Count -lt 2) { return }

    if ($pen.DashStyle -eq [System.Drawing.Drawing2D.DashStyle]::Solid) {
        $gfx.DrawLines($pen, $points)
        return
    }

    # GDI+ can produce partial miter wedges when a built-in dash boundary lands
    # directly on a Polyline vertex. Draw dashed segments independently instead,
    # then weld each internal corner with a very short solid path using the
    # requested Miter/Round join. This affects drawing annotations only.
    for ($i = 0; $i -lt ($points.Count - 1); $i++) {
        $gfx.DrawLine($pen, $points[$i], $points[$i + 1])
    }

    if ($points.Count -lt 3) { return }

    $joinPen = New-Object System.Drawing.Pen($pen.Color, $pen.Width)
    try {
        $joinPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Solid
        $joinPen.LineJoin = Get-AnnotationLineJoin $joinStyle
        $joinPen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Center
        $joinPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Flat
        $joinPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Flat

        for ($i = 1; $i -lt ($points.Count - 1); $i++) {
            $prev = $points[$i - 1]
            $cur = $points[$i]
            $next = $points[$i + 1]

            $v1x = [double]$prev.X - [double]$cur.X
            $v1y = [double]$prev.Y - [double]$cur.Y
            $v2x = [double]$next.X - [double]$cur.X
            $v2y = [double]$next.Y - [double]$cur.Y
            $len1 = [Math]::Sqrt(($v1x * $v1x) + ($v1y * $v1y))
            $len2 = [Math]::Sqrt(($v2x * $v2x) + ($v2y * $v2y))
            if ($len1 -lt 0.001 -or $len2 -lt 0.001) { continue }

            $bridge = [Math]::Max(1.0, ([double]$pen.Width * 0.60))
            $bridge = [Math]::Min($bridge, ($len1 * 0.45))
            $bridge = [Math]::Min($bridge, ($len2 * 0.45))
            if ($bridge -lt 0.01) { continue }

            $before = New-Object System.Drawing.PointF(
                [single]([double]$cur.X + (($v1x / $len1) * $bridge)),
                [single]([double]$cur.Y + (($v1y / $len1) * $bridge)))
            $after = New-Object System.Drawing.PointF(
                [single]([double]$cur.X + (($v2x / $len2) * $bridge)),
                [single]([double]$cur.Y + (($v2y / $len2) * $bridge)))
            $joinPoints = [System.Drawing.PointF[]]@($before, $cur, $after)
            $gfx.DrawLines($joinPen, $joinPoints)
        }
    }
    finally { $joinPen.Dispose() }
}

function Draw-AnnotationObject(
    $gfx,
    $annotation,
    [double]$scaleX,
    [double]$scaleY,
    [double]$originX,
    [double]$originY,
    $occlusionRedactions = $null
) {
    if (-not $gfx -or -not $annotation) { return }
    if ($scaleX -le 0.0 -or $scaleY -le 0.0) { return }

    $strokeScale = ([Math]::Abs($scaleX) + [Math]::Abs($scaleY)) / 2.0
    $scaledMediaStrokeWidth = ([double]$annotation.StrokeWidth * $strokeScale)
    $strokeWidth = [Math]::Max(1.0, $scaledMediaStrokeWidth)
    $pen = New-Object System.Drawing.Pen($annotation.StrokeColor, [single]$strokeWidth)
    $savedState = $gfx.Save()
    try {
        $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $pen.DashStyle = Get-AnnotationDashStyle $annotation.DashStyle
        $pen.LineJoin = Get-AnnotationLineJoin $annotation.JoinStyle
        $pen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Center
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Flat
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Flat

        # D1b-r2 keeps the security pipeline redactions-first while restoring
        # intuitive layer behaviour. Any security redaction committed *after*
        # this annotation/outline visually occludes it. Earlier redactions do
        # not: a later annotation may legitimately be drawn on top because it
        # adds pixels only and can never reveal the original source underneath.
        if ($occlusionRedactions) {
            $annotationOrder = if ($annotation.PSObject.Properties["CommitOrder"]) { [int]$annotation.CommitOrder } else { -1 }
            if ($annotationOrder -ge 0) {
                foreach ($occ in $occlusionRedactions) {
                    if (-not $occ) { continue }
                    $occOrder = if ($occ.PSObject.Properties["CommitOrder"]) { [int]$occ.CommitOrder } else { -1 }
                    if ($occOrder -le $annotationOrder) { continue }
                    $occPath = New-RedactionGeometryPath $occ $scaleX $scaleY $originX $originY
                    if ($occPath) {
                        try { $gfx.SetClip($occPath, [System.Drawing.Drawing2D.CombineMode]::Exclude) }
                        finally { $occPath.Dispose() }
                    }
                }
            }
            elseif ($annotation.PSObject.Properties["OwnerIndex"] -and [int]$annotation.OwnerIndex -ge 0) {
                # Compatibility fallback for an object lacking CommitOrder.
                for ($j = ([int]$annotation.OwnerIndex + 1); $j -lt $occlusionRedactions.Count; $j++) {
                    $occPath = New-RedactionGeometryPath $occlusionRedactions[$j] $scaleX $scaleY $originX $originY
                    if ($occPath) {
                        try { $gfx.SetClip($occPath, [System.Drawing.Drawing2D.CombineMode]::Exclude) }
                        finally { $occPath.Dispose() }
                    }
                }
            }
        }

        if ($annotation.Kind -eq "Text") {
            $x = [single]($originX + ([double]$annotation.X * $scaleX))
            $y = [single]($originY + ([double]$annotation.Y * $scaleY))
            $w = [single]([double]$annotation.W * $scaleX)
            $h = [single]([double]$annotation.H * $scaleY)
            if ($w -gt 0.0 -and $h -gt 0.0 -and -not [string]::IsNullOrWhiteSpace([string]$annotation.Text)) {
                $fontSize = [Math]::Max(1.0, ([double]$annotation.FontSizePx * $strokeScale))
                $fontStyle = [System.Drawing.FontStyle]::Regular
                if ([bool]$annotation.Bold) { $fontStyle = $fontStyle -bor [System.Drawing.FontStyle]::Bold }
                if ([bool]$annotation.Italic) { $fontStyle = $fontStyle -bor [System.Drawing.FontStyle]::Italic }
                $font = $null
                try {
                    try {
                        $font = New-Object System.Drawing.Font([string]$annotation.FontFamily, [single]$fontSize, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
                    }
                    catch {
                        $font = New-Object System.Drawing.Font("Segoe UI", [single]$fontSize, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
                    }
                    $brush = New-Object System.Drawing.SolidBrush($annotation.TextColor)
                    $fmt = New-Object System.Drawing.StringFormat
                    try {
                        $fmt.LineAlignment = [System.Drawing.StringAlignment]::Near
                        $fmt.Alignment = switch ([string]$annotation.Alignment) {
                            "Centre" { [System.Drawing.StringAlignment]::Center }
                            "Right"  { [System.Drawing.StringAlignment]::Far }
                            default  { [System.Drawing.StringAlignment]::Near }
                        }
                        $fmt.Trimming = [System.Drawing.StringTrimming]::EllipsisWord
                        $textRect = New-Object System.Drawing.RectangleF($x,$y,$w,$h)
                        $textState = $gfx.Save()
                        try {
                            $gfx.SetClip($textRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
                            $gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
                            $gfx.DrawString([string]$annotation.Text, $font, $brush, $textRect, $fmt)
                        }
                        finally { $gfx.Restore($textState) }
                    }
                    finally {
                        $fmt.Dispose()
                        $brush.Dispose()
                    }
                }
                finally {
                    if ($font) { $font.Dispose() }
                }
            }
        }
        elseif ($annotation.Kind -eq "Line") {
            $p1 = New-Object System.Drawing.PointF(
                [single]($originX + ([double]$annotation.X1 * $scaleX)),
                [single]($originY + ([double]$annotation.Y1 * $scaleY)))
            $p2 = New-Object System.Drawing.PointF(
                [single]($originX + ([double]$annotation.X2 * $scaleX)),
                [single]($originY + ([double]$annotation.Y2 * $scaleY)))

            $startArrow = $null
            $endArrow = $null
            $shaftP1 = $p1
            $shaftP2 = $p2

            if ($annotation.EndpointStyle -eq "ArrowStart" -or $annotation.EndpointStyle -eq "ArrowBoth") {
                $startArrow = Get-AnnotationArrowGeometry $p2 $p1 $scaledMediaStrokeWidth $strokeScale
                if ($startArrow) { $shaftP1 = $startArrow.ShaftJoin }
            }
            if ($annotation.EndpointStyle -eq "ArrowEnd" -or $annotation.EndpointStyle -eq "ArrowBoth") {
                $endArrow = Get-AnnotationArrowGeometry $p1 $p2 $scaledMediaStrokeWidth $strokeScale
                if ($endArrow) { $shaftP2 = $endArrow.ShaftJoin }
            }

            if (Test-AnnotationShaftHasForwardLength $p1 $p2 $shaftP1 $shaftP2) {
                $gfx.DrawLine($pen, $shaftP1, $shaftP2)
            }

            $capBrush = New-Object System.Drawing.SolidBrush($annotation.StrokeColor)
            try {
                if ($startArrow) { Draw-AnnotationArrowHead $gfx $startArrow $capBrush }
                if ($endArrow) { Draw-AnnotationArrowHead $gfx $endArrow $capBrush }
            }
            finally { $capBrush.Dispose() }
        }
        elseif ($annotation.Kind -eq "Polyline") {
            $pts = @()
            foreach ($p in $annotation.Points) {
                $pts += New-Object System.Drawing.PointF(
                    [single]($originX + ([double]$p.X * $scaleX)),
                    [single]($originY + ([double]$p.Y * $scaleY)))
            }
            if ($pts.Count -ge 2) {
                $startArrow = $null
                $endArrow = $null
                $shaftPts = [System.Drawing.PointF[]]($pts.Clone())

                if ($annotation.EndpointStyle -eq "ArrowStart" -or $annotation.EndpointStyle -eq "ArrowBoth") {
                    $startArrow = Get-AnnotationArrowGeometry $pts[1] $pts[0] $scaledMediaStrokeWidth $strokeScale
                    if ($startArrow) { $shaftPts[0] = $startArrow.ShaftJoin }
                }
                if ($annotation.EndpointStyle -eq "ArrowEnd" -or $annotation.EndpointStyle -eq "ArrowBoth") {
                    $endArrow = Get-AnnotationArrowGeometry $pts[$pts.Count-2] $pts[$pts.Count-1] $scaledMediaStrokeWidth $strokeScale
                    if ($endArrow) { $shaftPts[$shaftPts.Count-1] = $endArrow.ShaftJoin }
                }

                $drawShaft = $true
                if ($shaftPts.Count -eq 2) {
                    $drawShaft = Test-AnnotationShaftHasForwardLength $pts[0] $pts[1] $shaftPts[0] $shaftPts[1]
                }
                if ($drawShaft) {
                    Draw-AnnotationPolylineShaft $gfx $pen $shaftPts ([string]$annotation.JoinStyle)
                }

                $capBrush = New-Object System.Drawing.SolidBrush($annotation.StrokeColor)
                try {
                    if ($startArrow) { Draw-AnnotationArrowHead $gfx $startArrow $capBrush }
                    if ($endArrow) { Draw-AnnotationArrowHead $gfx $endArrow $capBrush }
                }
                finally { $capBrush.Dispose() }
            }
        }
        elseif ($annotation.Shape -eq "Oval") {
            $x = [single]($originX + ([double]$annotation.X * $scaleX))
            $y = [single]($originY + ([double]$annotation.Y * $scaleY))
            $w = [single]([double]$annotation.W * $scaleX)
            $h = [single]([double]$annotation.H * $scaleY)
            if ($w -gt 0.0 -and $h -gt 0.0) { $gfx.DrawEllipse($pen, $x, $y, $w, $h) }
        }
        elseif ($annotation.Shape -eq "Polygon") {
            $pts = @()
            foreach ($p in $annotation.Points) {
                $pts += New-Object System.Drawing.PointF(
                    [single]($originX + ([double]$p.X * $scaleX)),
                    [single]($originY + ([double]$p.Y * $scaleY)))
            }
            if ($pts.Count -ge 3) {
                $shapePath = New-Object System.Drawing.Drawing2D.GraphicsPath
                try {
                    $shapePath.AddPolygon([System.Drawing.PointF[]]$pts)
                    $gfx.DrawPath($pen, $shapePath)
                }
                finally { $shapePath.Dispose() }
            }
        }
        else {
            $x = [single]($originX + ([double]$annotation.X * $scaleX))
            $y = [single]($originY + ([double]$annotation.Y * $scaleY))
            $w = [single]([double]$annotation.W * $scaleX)
            $h = [single]([double]$annotation.H * $scaleY)
            if ($w -gt 0.0 -and $h -gt 0.0) {
                # A GraphicsPath makes the selected Rectangle corner join
                # explicit, so Square/Miter versus Round is shared identically
                # by preview and export rather than relying on DrawRectangle's
                # platform-specific primitive implementation details.
                $shapePath = New-Object System.Drawing.Drawing2D.GraphicsPath
                try {
                    $shapePath.AddRectangle((New-Object System.Drawing.RectangleF($x,$y,$w,$h)))
                    $gfx.DrawPath($pen, $shapePath)
                }
                finally { $shapePath.Dispose() }
            }
        }
    }
    finally {
        $gfx.Restore($savedState)
        $pen.Dispose()
    }
}

function Draw-AnnotationsToView($gfx) {
    if (-not $videoPath) { return }
    $items = Get-ImageAnnotationObjects
    if ($items.Count -eq 0) { return }
    $transform = Get-ViewportTransform
    if (-not $transform) { return }
    $mediaViewRect = Get-MediaViewRect
    if (-not $mediaViewRect) { return }

    $activeOcclusionRedactions = New-Object System.Collections.ArrayList
    foreach ($r in $redactions) {
        if ($isImageMode -or (Test-FrameInRange $currentFrame $r.BufferedStartFrame $r.BufferedEndFrame)) {
            [void]$activeOcclusionRedactions.Add($r)
        }
    }

    $saved = $gfx.Save()
    try {
        $gfx.SetClip($mediaViewRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        foreach ($a in $items) {
            if (-not (Test-AnnotationFrameActive $a $currentFrame)) { continue }
            Draw-AnnotationObject $gfx $a $transform.ScaleX $transform.ScaleY $transform.OriginX $transform.OriginY $activeOcclusionRedactions
        }
    }
    finally {
        $gfx.Restore($saved)
    }
}

function Draw-DraftShapeOutlineToView($gfx, $shapeData) {
    if (-not $isImageMode -or -not $script:outlineEnabled -or -not $shapeData) { return }
    $annotation = New-ShapeOutlineAnnotation $shapeData $script:outlineColor $script:outlineWidth $script:outlineDashStyle (Get-CurrentOutlineJoinStyle)
    if (-not $annotation) { return }
    $transform = Get-ViewportTransform
    if (-not $transform) { return }
    $mediaViewRect = Get-MediaViewRect
    if (-not $mediaViewRect) { return }

    $saved = $gfx.Save()
    try {
        $gfx.SetClip($mediaViewRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        Draw-AnnotationObject $gfx $annotation $transform.ScaleX $transform.ScaleY $transform.OriginX $transform.OriginY
    }
    finally {
        $gfx.Restore($saved)
    }
}

function New-ImageAnnotationOverlayFile($annotationObjects, $occlusionRedactions, [string]$outPath) {
    if ($videoWidth -le 0 -or $videoHeight -le 0) {
        throw "Cannot render an annotation overlay without valid media dimensions."
    }
    $bmp = New-Object System.Drawing.Bitmap(
        [int]$videoWidth,
        [int]$videoHeight,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.Clear([System.Drawing.Color]::Transparent)
        foreach ($a in $annotationObjects) {
            Draw-AnnotationObject $g $a 1.0 1.0 0.0 0.0 $occlusionRedactions
        }
        if (Test-Path -LiteralPath $outPath) {
            Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue
        }
        $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $g.Dispose()
        $bmp.Dispose()
    }
}

function Get-CurrentTextDraftAnnotation {
    if (-not $script:textDraftActive) { return $null }
    if ([string]::IsNullOrWhiteSpace($txtAnnotationText.Text)) { return $null }
    return New-TextDrawingAnnotation `
        $script:textDraftRect `
        $txtAnnotationText.Text `
        $script:textColor `
        $script:textFontFamily `
        $script:textFontSizePx `
        $script:textBold `
        $script:textItalic `
        $script:textAlignment `
        -1
}

function Commit-TextDraft {
    if (-not $videoPath -or -not $isImageMode -or $toolMode -ne "Text" -or -not $script:textDraftActive) { return $false }
    $a = Get-CurrentTextDraftAnnotation
    if (-not $a) {
        [System.Windows.Forms.MessageBox]::Show(
            "Type some text before adding the annotation.",
            "No text",
            "OK",
            "Information"
        ) | Out-Null
        return $false
    }
    $a.CommitOrder = Get-NextObjectCommitOrder
    Set-AnnotationWholeMediaTiming $a
    [void]$script:annotations.Add($a)
    Refresh-AnnotationList
    $lblPending.Text = "Text annotation #$($annotations.Count) added."
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    Update-InspectorSectionLayout
    return $true
}

function Add-LineDrawingAnnotation([System.Drawing.PointF]$startPoint, [System.Drawing.PointF]$endPoint) {
    if (-not $isImageMode) { return $false }
    $dx = [double]$endPoint.X - [double]$startPoint.X
    $dy = [double]$endPoint.Y - [double]$startPoint.Y
    if ([Math]::Sqrt(($dx*$dx)+($dy*$dy)) -lt 1.0) { return $false }
    $a = New-LineDrawingAnnotation $startPoint $endPoint $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawEndpointStyle (Get-NextObjectCommitOrder)
    Set-AnnotationWholeMediaTiming $a
    [void]$script:annotations.Add($a)
    Refresh-AnnotationList
    $lblPending.Text = "Line annotation #$($annotations.Count) added."
    return $true
}

function Get-PolylineGestureThresholdMedia {
    $transform = Get-ViewportTransform
    if (-not $transform) { return 8.0 }
    $scale = [Math]::Min([double]$transform.ScaleX, [double]$transform.ScaleY)
    if ($scale -le 0.0) { return 8.0 }
    return [Math]::Max(0.5, ([double]$script:polylineGestureThresholdView / $scale))
}

function Get-DominantGestureAxis([System.Drawing.PointF]$from, [System.Drawing.PointF]$to) {
    $dx = [Math]::Abs([double]$to.X - [double]$from.X)
    $dy = [Math]::Abs([double]$to.Y - [double]$from.Y)
    if ($dx -ge $dy) { return "H" }
    return "V"
}

function Get-ProjectedPolylineGesturePoint([System.Drawing.PointF]$anchorPoint, [System.Drawing.PointF]$rawPoint, [string]$axis) {
    if ($axis -eq "H") {
        return Clamp-MediaPoint (New-Object System.Drawing.PointF([single]$rawPoint.X,[single]$anchorPoint.Y))
    }
    if ($axis -eq "V") {
        return Clamp-MediaPoint (New-Object System.Drawing.PointF([single]$anchorPoint.X,[single]$rawPoint.Y))
    }
    return Clamp-MediaPoint $rawPoint
}

function Add-PolylineGesturePointIfDistinct([System.Drawing.PointF]$point) {
    if (-not $script:polylinePoints -or $script:polylinePoints.Count -eq 0) {
        [void]$script:polylinePoints.Add($point)
        return
    }
    $last = $script:polylinePoints[$script:polylinePoints.Count - 1]
    $dx = [double]$point.X - [double]$last.X
    $dy = [double]$point.Y - [double]$last.Y
    if ([Math]::Sqrt(($dx*$dx)+($dy*$dy)) -ge 0.5) {
        [void]$script:polylinePoints.Add($point)
    }
}

function Update-PolylineGesture([System.Drawing.PointF]$rawPoint) {
    if (-not $script:polylineActive -or -not $script:polylinePoints -or $script:polylinePoints.Count -eq 0) { return }
    $rawPoint = Clamp-MediaPoint $rawPoint
    $anchorPoint = $script:polylinePoints[$script:polylinePoints.Count - 1]
    $threshold = [double](Get-PolylineGestureThresholdMedia)

    if (-not $script:polylineGestureLastRaw) {
        $script:polylineGestureLastRaw = $rawPoint
    }

    if ($script:polylineGestureAxis -eq "None") {
        $dx0 = [double]$rawPoint.X - [double]$anchorPoint.X
        $dy0 = [double]$rawPoint.Y - [double]$anchorPoint.Y
        if ([Math]::Sqrt(($dx0*$dx0)+($dy0*$dy0)) -lt $threshold) {
            $script:polylineMousePos = $rawPoint
            return
        }
        $script:polylineGestureAxis = Get-DominantGestureAxis $anchorPoint $rawPoint
        $script:polylineGestureLastRaw = $rawPoint
    }

    $script:polylineMousePos = Get-ProjectedPolylineGesturePoint $anchorPoint $rawPoint $script:polylineGestureAxis

    $sampleDx = [double]$rawPoint.X - [double]$script:polylineGestureLastRaw.X
    $sampleDy = [double]$rawPoint.Y - [double]$script:polylineGestureLastRaw.Y
    $sampleDistance = [Math]::Sqrt(($sampleDx*$sampleDx)+($sampleDy*$sampleDy))
    if ($sampleDistance -lt $threshold) { return }

    $candidateAxis = Get-DominantGestureAxis $script:polylineGestureLastRaw $rawPoint
    if ($candidateAxis -ne $script:polylineGestureAxis) {
        $corner = $script:polylineMousePos
        Add-PolylineGesturePointIfDistinct $corner
        $anchorPoint = $script:polylinePoints[$script:polylinePoints.Count - 1]
        $script:polylineGestureAxis = $candidateAxis
        $script:polylineMousePos = Get-ProjectedPolylineGesturePoint $anchorPoint $rawPoint $script:polylineGestureAxis
    }
    $script:polylineGestureLastRaw = $rawPoint
}

function Finish-PolylineGesture([System.Drawing.PointF]$rawPoint) {
    if (-not $script:polylineActive) { return $false }
    if ($rawPoint) { Update-PolylineGesture $rawPoint }
    if ($script:polylineMousePos) { Add-PolylineGesturePointIfDistinct $script:polylineMousePos }
    if ($script:polylinePoints.Count -lt 2) {
        Reset-DrawingState
        Update-SelectionFields $null
        Update-RedactionButtons
        return $false
    }
    $script:polylineActive = $false
    $script:polylineDraftActive = $true
    $script:polylineMousePos = $null
    $script:polylineGestureAxis = "None"
    $script:polylineGestureLastRaw = $null
    Update-SelectionFields $null "Polyline ready. Create Annotation locks it in."
    [void](Show-FloatingTextEditor "Draft")
    Update-RedactionButtons
    return $true
}

function Complete-PolylineDrawing {
    if (-not $isImageMode) { return $false }
    if (-not $script:polylineDraftActive -or -not $script:polylinePoints -or $script:polylinePoints.Count -lt 2) { return $false }
    $a = New-PolylineDrawingAnnotation $script:polylinePoints $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawPolylineJoinStyle $script:drawEndpointStyle (Get-NextObjectCommitOrder)
    if (-not $a) { return $false }
    Set-AnnotationWholeMediaTiming $a
    [void]$script:annotations.Add($a)
    Refresh-AnnotationList
    $lblPending.Text = "Polyline annotation #$($annotations.Count) added."
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
    return $true
}

# D4a draft hit-testing/movement helpers. Hit-testing is intentionally VIEW
# space so a thin line remains practical to grab at every zoom level; movement
# itself is canonical MEDIA-space and clamped to the displayed media bounds.
function Get-ViewPointToSegmentDistance([System.Drawing.PointF]$point, [System.Drawing.PointF]$a, [System.Drawing.PointF]$b) {
    $vx = [double]$b.X - [double]$a.X
    $vy = [double]$b.Y - [double]$a.Y
    $wx = [double]$point.X - [double]$a.X
    $wy = [double]$point.Y - [double]$a.Y
    $len2 = ($vx * $vx) + ($vy * $vy)
    if ($len2 -le 0.0001) {
        return [Math]::Sqrt(($wx * $wx) + ($wy * $wy))
    }
    $t = (($wx * $vx) + ($wy * $vy)) / $len2
    $t = [Math]::Max(0.0, [Math]::Min(1.0, $t))
    $px = [double]$a.X + ($t * $vx)
    $py = [double]$a.Y + ($t * $vy)
    $dx = [double]$point.X - $px
    $dy = [double]$point.Y - $py
    return [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
}

function Get-StandaloneDraftHitToleranceView {
    $transform = Get-ViewportTransform
    $scaledHalfWidth = 0.0
    if ($transform) {
        $scaledHalfWidth = ([double]$script:outlineWidth * [double]$transform.ScaleX) / 2.0
    }
    return [Math]::Max(7.0, ($scaledHalfWidth + 5.0))
}

function Test-LineDraftHit([System.Drawing.PointF]$viewPoint) {
    if (-not $script:lineDraftActive -or -not $script:lineStart -or -not $script:lineEnd) { return $false }
    $a = MediaPoint-To-ViewPoint $script:lineStart
    $b = MediaPoint-To-ViewPoint $script:lineEnd
    if (-not $a -or -not $b) { return $false }
    return [bool]((Get-ViewPointToSegmentDistance $viewPoint $a $b) -le (Get-StandaloneDraftHitToleranceView))
}

function Test-PolylineDraftHit([System.Drawing.PointF]$viewPoint) {
    if (-not $script:polylineDraftActive -or -not $script:polylinePoints -or $script:polylinePoints.Count -lt 2) { return $false }
    $tol = Get-StandaloneDraftHitToleranceView
    for ($i = 1; $i -lt $script:polylinePoints.Count; $i++) {
        $a = MediaPoint-To-ViewPoint $script:polylinePoints[$i - 1]
        $b = MediaPoint-To-ViewPoint $script:polylinePoints[$i]
        if ($a -and $b -and (Get-ViewPointToSegmentDistance $viewPoint $a $b) -le $tol) { return $true }
    }
    return $false
}

function Begin-AnnotationDraftMove([string]$kind, [System.Drawing.PointF]$mediaPoint) {
    $script:annotationDraftMoving = $true
    $script:annotationDraftMoveKind = $kind
    $script:annotationDraftMoveStart = $mediaPoint
    $script:annotationDraftOrigTextRect = $null
    $script:annotationDraftOrigLineStart = $null
    $script:annotationDraftOrigLineEnd = $null
    $script:annotationDraftOrigPolylinePoints = $null

    if ($kind -eq "Text") {
        $script:annotationDraftOrigTextRect = New-Object System.Drawing.RectangleF(
            [single]$script:textDraftRect.X,[single]$script:textDraftRect.Y,[single]$script:textDraftRect.Width,[single]$script:textDraftRect.Height)
    }
    elseif ($kind -eq "Line") {
        $script:annotationDraftOrigLineStart = New-Object System.Drawing.PointF([single]$script:lineStart.X,[single]$script:lineStart.Y)
        $script:annotationDraftOrigLineEnd = New-Object System.Drawing.PointF([single]$script:lineEnd.X,[single]$script:lineEnd.Y)
    }
    elseif ($kind -eq "Polyline") {
        $script:annotationDraftOrigPolylinePoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        foreach ($pt in $script:polylinePoints) {
            [void]$script:annotationDraftOrigPolylinePoints.Add((New-Object System.Drawing.PointF([single]$pt.X,[single]$pt.Y)))
        }
    }
    $picture.Capture = $true
    $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
}

function Update-AnnotationDraftMove([System.Drawing.PointF]$mediaPoint) {
    if (-not $script:annotationDraftMoving -or -not $script:annotationDraftMoveStart -or -not $mediaPoint) { return }
    $mediaBounds = Get-DraftMediaBounds
    if (-not $mediaBounds) { return }
    $dx = [double]$mediaPoint.X - [double]$script:annotationDraftMoveStart.X
    $dy = [double]$mediaPoint.Y - [double]$script:annotationDraftMoveStart.Y

    if ($script:annotationDraftMoveKind -eq "Text" -and $script:annotationDraftOrigTextRect) {
        $d = Get-ClampedTranslation $script:annotationDraftOrigTextRect $dx $dy $mediaBounds
        $script:textDraftRect = New-Object System.Drawing.RectangleF(
            [single]([double]$script:annotationDraftOrigTextRect.X + [double]$d.Dx),
            [single]([double]$script:annotationDraftOrigTextRect.Y + [double]$d.Dy),
            [single]$script:annotationDraftOrigTextRect.Width,[single]$script:annotationDraftOrigTextRect.Height)
    }
    elseif ($script:annotationDraftMoveKind -eq "Line" -and $script:annotationDraftOrigLineStart -and $script:annotationDraftOrigLineEnd) {
        $minX = [Math]::Min([double]$script:annotationDraftOrigLineStart.X,[double]$script:annotationDraftOrigLineEnd.X)
        $minY = [Math]::Min([double]$script:annotationDraftOrigLineStart.Y,[double]$script:annotationDraftOrigLineEnd.Y)
        $maxX = [Math]::Max([double]$script:annotationDraftOrigLineStart.X,[double]$script:annotationDraftOrigLineEnd.X)
        $maxY = [Math]::Max([double]$script:annotationDraftOrigLineStart.Y,[double]$script:annotationDraftOrigLineEnd.Y)
        $origBounds = New-Object System.Drawing.RectangleF([single]$minX,[single]$minY,[single][Math]::Max(0.01,($maxX-$minX)),[single][Math]::Max(0.01,($maxY-$minY)))
        $d = Get-ClampedTranslation $origBounds $dx $dy $mediaBounds
        $script:lineStart = New-Object System.Drawing.PointF([single]([double]$script:annotationDraftOrigLineStart.X + [double]$d.Dx),[single]([double]$script:annotationDraftOrigLineStart.Y + [double]$d.Dy))
        $script:lineEnd = New-Object System.Drawing.PointF([single]([double]$script:annotationDraftOrigLineEnd.X + [double]$d.Dx),[single]([double]$script:annotationDraftOrigLineEnd.Y + [double]$d.Dy))
    }
    elseif ($script:annotationDraftMoveKind -eq "Polyline" -and $script:annotationDraftOrigPolylinePoints) {
        $origBounds = Get-PointsBoundingRect $script:annotationDraftOrigPolylinePoints
        $d = Get-ClampedTranslation $origBounds $dx $dy $mediaBounds
        $newPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        foreach ($pt in $script:annotationDraftOrigPolylinePoints) {
            [void]$newPoints.Add((New-Object System.Drawing.PointF([single]([double]$pt.X + [double]$d.Dx),[single]([double]$pt.Y + [double]$d.Dy))))
        }
        $script:polylinePoints = $newPoints
    }
}

function Stop-AnnotationDraftMove {
    $script:annotationDraftMoving = $false
    $script:annotationDraftMoveKind = "None"
    $script:annotationDraftMoveStart = $null
    $script:annotationDraftOrigTextRect = $null
    $script:annotationDraftOrigLineStart = $null
    $script:annotationDraftOrigLineEnd = $null
    $script:annotationDraftOrigPolylinePoints = $null
    if ($picture) { $picture.Capture = $false }
}

# D4b committed-annotation helpers. These operate only on $annotations.
function Get-SelectedCommittedAnnotation {
    $idx = [int]$script:selectedAnnotationIndex
    if ($idx -lt 0 -or $idx -ge $annotations.Count) { return $null }
    return $annotations[$idx]
}

function Get-AnnotationMediaBounds($a) {
    if (-not $a) { return $null }
    if ($a.Kind -eq "Line") {
        $minX = [Math]::Min([double]$a.X1,[double]$a.X2)
        $minY = [Math]::Min([double]$a.Y1,[double]$a.Y2)
        $maxX = [Math]::Max([double]$a.X1,[double]$a.X2)
        $maxY = [Math]::Max([double]$a.Y1,[double]$a.Y2)
        return New-Object System.Drawing.RectangleF([single]$minX,[single]$minY,[single][Math]::Max(0.01,($maxX-$minX)),[single][Math]::Max(0.01,($maxY-$minY)))
    }
    if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon")) {
        if (-not $a.Points -or $a.Points.Count -lt 1) { return $null }
        return Get-PointsBoundingRect $a.Points
    }
    if ($a.PSObject.Properties["X"] -and $a.PSObject.Properties["Y"] -and
        $a.PSObject.Properties["W"] -and $a.PSObject.Properties["H"]) {
        return New-Object System.Drawing.RectangleF([single]$a.X,[single]$a.Y,[single]$a.W,[single]$a.H)
    }
    return $null
}

function Get-AnnotationHitToleranceView($a) {
    $transform = Get-ViewportTransform
    $scaledHalf = 0.0
    if ($transform -and $a -and $a.PSObject.Properties["StrokeWidth"]) {
        $scaledHalf = ([double]$a.StrokeWidth * [double]$transform.ScaleX) / 2.0
    }
    return [Math]::Max(7.0, ($scaledHalf + 5.0))
}

function Test-CommittedAnnotationHit($a, [System.Drawing.PointF]$viewPoint) {
    if (-not $a) { return $false }
    $mediaPoint = ViewPoint-To-MediaPoint $viewPoint $false
    if (-not $mediaPoint) { return $false }

    if ($a.Kind -eq "Text") {
        $r = Get-AnnotationMediaBounds $a
        return [bool]($r -and $r.Contains($mediaPoint))
    }
    if ($a.Kind -eq "Line") {
        $p1 = MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.X1,[single]$a.Y1))
        $p2 = MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.X2,[single]$a.Y2))
        if (-not $p1 -or -not $p2) { return $false }
        return [bool]((Get-ViewPointToSegmentDistance $viewPoint $p1 $p2) -le (Get-AnnotationHitToleranceView $a))
    }
    if ($a.Kind -eq "Polyline") {
        $tol = Get-AnnotationHitToleranceView $a
        for ($i=1; $i -lt $a.Points.Count; $i++) {
            $p1 = MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.Points[$i-1].X,[single]$a.Points[$i-1].Y))
            $p2 = MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.Points[$i].X,[single]$a.Points[$i].Y))
            if ($p1 -and $p2 -and (Get-ViewPointToSegmentDistance $viewPoint $p1 $p2) -le $tol) { return $true }
        }
        return $false
    }
    if ($a.Kind -eq "ShapeOutline") {
        if ($a.Shape -eq "Polygon") { return [bool](Test-PointInPolygon $mediaPoint $a.Points) }
        $r = Get-AnnotationMediaBounds $a
        if (-not $r) { return $false }
        if ($a.Shape -eq "Oval") {
            if ($r.Width -le 0.0 -or $r.Height -le 0.0) { return $false }
            $cx=[double]$r.X+([double]$r.Width/2.0); $cy=[double]$r.Y+([double]$r.Height/2.0)
            $nx=([double]$mediaPoint.X-$cx)/([double]$r.Width/2.0)
            $ny=([double]$mediaPoint.Y-$cy)/([double]$r.Height/2.0)
            return [bool]((($nx*$nx)+($ny*$ny)) -le 1.0)
        }
        return [bool]($r.Contains($mediaPoint))
    }
    return $false
}

function Copy-AnnotationGeometrySnapshot($a) {
    if (-not $a) { return $null }
    if ($a.Kind -eq "Line") {
        return [PSCustomObject]@{ Kind="Line"; X1=[double]$a.X1; Y1=[double]$a.Y1; X2=[double]$a.X2; Y2=[double]$a.Y2 }
    }
    if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon")) {
        $pts=@(); foreach ($p in $a.Points) { $pts += [PSCustomObject]@{X=[double]$p.X;Y=[double]$p.Y} }
        return [PSCustomObject]@{ Kind=[string]$a.Kind; Shape=[string]$a.Shape; Points=$pts }
    }
    $r = Get-AnnotationMediaBounds $a
    if ($r) { return [PSCustomObject]@{ Kind=[string]$a.Kind; Shape=[string]$a.Shape; X=[double]$r.X;Y=[double]$r.Y;W=[double]$r.Width;H=[double]$r.Height } }
    return $null
}

function Begin-CommittedAnnotationMove($a, [System.Drawing.PointF]$mediaPoint) {
    $snap = Copy-AnnotationGeometrySnapshot $a
    if (-not $snap -or -not $mediaPoint) { return $false }
    $script:annotationCommittedMoving = $true
    $script:annotationCommittedMoveStart = $mediaPoint
    $script:annotationCommittedOrig = $snap
    $picture.Capture = $true
    $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
    return $true
}

function Update-CommittedAnnotationMove([System.Drawing.PointF]$mediaPoint) {
    if (-not $script:annotationCommittedMoving -or -not $mediaPoint -or -not $script:annotationCommittedMoveStart -or -not $script:annotationCommittedOrig) { return }
    $a = Get-SelectedCommittedAnnotation
    if (-not $a) { return }
    $bounds = Get-DraftMediaBounds
    if (-not $bounds) { return }
    $dx=[double]$mediaPoint.X-[double]$script:annotationCommittedMoveStart.X
    $dy=[double]$mediaPoint.Y-[double]$script:annotationCommittedMoveStart.Y
    $orig=$script:annotationCommittedOrig

    if ($orig.Kind -eq "Line") {
        $minX=[Math]::Min($orig.X1,$orig.X2); $minY=[Math]::Min($orig.Y1,$orig.Y2)
        $maxX=[Math]::Max($orig.X1,$orig.X2); $maxY=[Math]::Max($orig.Y1,$orig.Y2)
        $ob=New-Object System.Drawing.RectangleF([single]$minX,[single]$minY,[single][Math]::Max(0.01,($maxX-$minX)),[single][Math]::Max(0.01,($maxY-$minY)))
        $d=Get-ClampedTranslation $ob $dx $dy $bounds
        $a.X1=[double]$orig.X1+[double]$d.Dx; $a.Y1=[double]$orig.Y1+[double]$d.Dy
        $a.X2=[double]$orig.X2+[double]$d.Dx; $a.Y2=[double]$orig.Y2+[double]$d.Dy
    }
    elseif ($orig.Points) {
        $ob=Get-PointsBoundingRect $orig.Points
        $d=Get-ClampedTranslation $ob $dx $dy $bounds
        $pts=@(); foreach ($pt in $orig.Points) { $pts += [PSCustomObject]@{X=[double]$pt.X+[double]$d.Dx;Y=[double]$pt.Y+[double]$d.Dy} }
        $a.Points=$pts
    }
    else {
        $ob=New-Object System.Drawing.RectangleF([single]$orig.X,[single]$orig.Y,[single]$orig.W,[single]$orig.H)
        $d=Get-ClampedTranslation $ob $dx $dy $bounds
        $a.X=[double]$orig.X+[double]$d.Dx; $a.Y=[double]$orig.Y+[double]$d.Dy
    }
}

function Stop-CommittedAnnotationMove {
    $script:annotationCommittedMoving=$false
    $script:annotationCommittedMoveStart=$null
    $script:annotationCommittedOrig=$null
    if ($picture) { $picture.Capture=$false }
}

# D4d: committed Line/Polyline/Freeform annotation handles reuse the proven
# constant-screen-size vertex hit zones but accept two-point Line geometry too.
function Get-CommittedAnnotationEditablePoints($a) {
    if (-not $a) { return @() }
    if ($a.Kind -eq "Line") {
        return @(
            (New-Object System.Drawing.PointF([single]$a.X1,[single]$a.Y1)),
            (New-Object System.Drawing.PointF([single]$a.X2,[single]$a.Y2))
        )
    }
    if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon")) {
        $pts = @()
        foreach ($p in $a.Points) { $pts += New-Object System.Drawing.PointF([single]$p.X,[single]$p.Y) }
        return ,$pts
    }
    return @()
}

function Get-CommittedAnnotationVertexHandleAtViewPoint($a, [System.Drawing.PointF]$viewPoint) {
    $pts = Get-CommittedAnnotationEditablePoints $a
    if (-not $pts -or $pts.Count -lt 1) { return -1 }
    return Get-FreeformVertexHandleAtViewPoint $viewPoint $pts
}

function Test-AnnotationVertexIsArrowEndpoint($a, [int]$vertexIndex) {
    if (-not $a -or $vertexIndex -lt 0) { return $false }
    $style = [string]$a.EndpointStyle
    if ([string]::IsNullOrWhiteSpace($style) -or $style -eq "None") { return $false }

    if ($a.Kind -eq "Line") {
        if ($vertexIndex -eq 0) { return [bool]($style -eq "ArrowStart" -or $style -eq "ArrowBoth") }
        if ($vertexIndex -eq 1) { return [bool]($style -eq "ArrowEnd" -or $style -eq "ArrowBoth") }
        return $false
    }

    if ($a.Kind -eq "Polyline" -and $a.Points) {
        if ($vertexIndex -eq 0) { return [bool]($style -eq "ArrowStart" -or $style -eq "ArrowBoth") }
        if ($vertexIndex -eq ($a.Points.Count - 1)) { return [bool]($style -eq "ArrowEnd" -or $style -eq "ArrowBoth") }
    }
    return $false
}

function Draw-CommittedAnnotationVertexHandles($gfx, $a) {
    if (-not $gfx -or -not $a) { return }
    $pts = Get-CommittedAnnotationEditablePoints $a
    if (-not $pts -or $pts.Count -lt 1) { return }
    $size = [double]$script:resizeHandleVisualSize
    $half = $size / 2.0
    $fill = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
    $arrowPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 1.4)
    try {
        foreach ($h in (Get-FreeformVertexHandleCenters $pts)) {
            if (Test-AnnotationVertexIsArrowEndpoint $a ([int]$h.Index)) {
                # A filled square centred on an arrow tip makes the arrow look
                # blunt even though the underlying D2-r3 arrow geometry is still
                # pointed. Use a hollow selection ring for arrow endpoints so the
                # tip remains visible while the same endpoint hit target stays active.
                $ringSize = [Math]::Max(10.0, ($size + 2.0))
                $ringHalf = $ringSize / 2.0
                $gfx.DrawEllipse($arrowPen,
                    [single]([double]$h.X - $ringHalf),
                    [single]([double]$h.Y - $ringHalf),
                    [single]$ringSize,
                    [single]$ringSize)
                continue
            }
            $x = [single]([double]$h.X - $half)
            $y = [single]([double]$h.Y - $half)
            $gfx.FillRectangle($fill, $x, $y, [single]$size, [single]$size)
            $gfx.DrawRectangle($pen, $x, $y, [single]$size, [single]$size)
        }
    }
    finally {
        $fill.Dispose()
        $pen.Dispose()
        $arrowPen.Dispose()
    }
}

function Update-CommittedAnnotationVertex($a, [int]$vertexIndex, [System.Drawing.PointF]$rawPoint, [System.Drawing.RectangleF]$mediaBounds) {
    if (-not $a -or -not $rawPoint -or -not $mediaBounds -or $vertexIndex -lt 0) { return }
    $point = Clamp-MediaPoint $rawPoint

    if ($a.Kind -eq "Line") {
        if ($vertexIndex -gt 1) { return }
        $other = if ($vertexIndex -eq 0) {
            New-Object System.Drawing.PointF([single]$a.X2,[single]$a.Y2)
        } else {
            New-Object System.Drawing.PointF([single]$a.X1,[single]$a.Y1)
        }
        $constrain = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
        if ($constrain) { $point = Clamp-MediaPoint (Get-AngleSnappedPoint $other $point $true) }
        if ($vertexIndex -eq 0) { $a.X1=[double]$point.X; $a.Y1=[double]$point.Y }
        else { $a.X2=[double]$point.X; $a.Y2=[double]$point.Y }
        return
    }

    if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon")) {
        if (-not $a.Points -or $vertexIndex -ge $a.Points.Count) { return }
        $a.Points = Get-FreeformVertexEditResult $a.Points $vertexIndex $point $mediaBounds
    }
}

function Draw-SelectedCommittedAnnotationGuide($gfx) {
    $a=Get-SelectedCommittedAnnotation
    if (-not $a -or -not $gfx) { return }

    $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::Gold,1)
    $pen.DashStyle=[System.Drawing.Drawing2D.DashStyle]::Dash
    try {
        if ($a.Kind -eq "Line") {
            $p1=MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.X1,[single]$a.Y1))
            $p2=MediaPoint-To-ViewPoint (New-Object System.Drawing.PointF([single]$a.X2,[single]$a.Y2))
            if ($p1 -and $p2) { $gfx.DrawLine($pen,$p1,$p2) }
            Draw-CommittedAnnotationVertexHandles $gfx $a
            return
        }

        if ($a.Kind -eq "Polyline" -or ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon")) {
            $pts=MediaPoints-To-ViewPoints $a.Points
            if ($pts -and $pts.Count -ge 2) {
                if ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Polygon" -and $pts.Count -ge 3) {
                    $gfx.DrawPolygon($pen,[System.Drawing.PointF[]]$pts)
                } else {
                    $gfx.DrawLines($pen,[System.Drawing.PointF[]]$pts)
                }
            }
            Draw-CommittedAnnotationVertexHandles $gfx $a
            return
        }

        $bounds=Get-AnnotationMediaBounds $a
        if (-not $bounds) { return }
        $vr=MediaRect-To-ViewRect $bounds
        if (-not $vr) { return }

        if ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Oval") {
            $gfx.DrawEllipse($pen,$vr)
            Draw-OvalResizeHandles $gfx $bounds
            return
        }
        if ($a.Kind -eq "ShapeOutline" -and $a.Shape -eq "Rectangle") {
            $gfx.DrawRectangle($pen,$vr.X,$vr.Y,$vr.Width,$vr.Height)
            Draw-RectangleResizeHandles $gfx $bounds
            return
        }

        $pad=3.0
        $guide=New-Object System.Drawing.RectangleF([single]([double]$vr.X-$pad),[single]([double]$vr.Y-$pad),[single]([double]$vr.Width+($pad*2.0)),[single]([double]$vr.Height+($pad*2.0)))
        $gfx.DrawRectangle($pen,$guide.X,$guide.Y,$guide.Width,$guide.Height)
        if ($a.Kind -eq "Text") { Draw-RectangleResizeHandles $gfx $bounds }
    }
    finally { $pen.Dispose() }
}

# D4c committed-redaction helpers. These mutate only geometry fields on the
# already-committed still-image redaction object. Security mode/strength/timing,
# colour, attached outline styling and CommitOrder are never rewritten here.
function Get-SelectedCommittedRedaction {
    $idx = [int]$script:selectedRedactionIndex
    if ($idx -lt 0 -or $idx -ge $redactions.Count) { return $null }
    if(-not $isImageMode -and -not (Test-FrameInRange $currentFrame $redactions[$idx].BufferedStartFrame $redactions[$idx].BufferedEndFrame)){return $null}
    return $redactions[$idx]
}

function Get-RedactionMediaBounds($r) {
    if (-not $r) { return $null }
    if ($r.Shape -eq "Polygon") {
        if (-not $r.Points -or $r.Points.Count -lt 3) { return $null }
        return Get-PointsBoundingRect $r.Points
    }
    return New-Object System.Drawing.RectangleF([single]$r.X,[single]$r.Y,[single]$r.W,[single]$r.H)
}

function Test-CommittedRedactionHit($r, [System.Drawing.PointF]$mediaPoint) {
    if (-not $r -or -not $mediaPoint) { return $false }
    if ($r.Shape -eq "Polygon") { return [bool](Test-PointInPolygon $mediaPoint $r.Points) }
    $rect = Get-RedactionMediaBounds $r
    if (-not $rect) { return $false }
    if ($r.Shape -eq "Oval") {
        if ($rect.Width -le 0.0 -or $rect.Height -le 0.0) { return $false }
        $cx=[double]$rect.X+([double]$rect.Width/2.0); $cy=[double]$rect.Y+([double]$rect.Height/2.0)
        $nx=([double]$mediaPoint.X-$cx)/([double]$rect.Width/2.0)
        $ny=([double]$mediaPoint.Y-$cy)/([double]$rect.Height/2.0)
        return [bool]((($nx*$nx)+($ny*$ny)) -le 1.0)
    }
    return [bool]($rect.Contains($mediaPoint))
}

function Copy-RedactionGeometrySnapshot($r) {
    if (-not $r) { return $null }
    if ($r.Shape -eq "Polygon") {
        $pts=@(); foreach ($p in $r.Points) { $pts += [PSCustomObject]@{ X=[double]$p.X; Y=[double]$p.Y } }
        return [PSCustomObject]@{ Shape="Polygon"; X=[double]$r.X; Y=[double]$r.Y; W=[double]$r.W; H=[double]$r.H; Points=$pts }
    }
    return [PSCustomObject]@{ Shape=[string]$r.Shape; X=[double]$r.X; Y=[double]$r.Y; W=[double]$r.W; H=[double]$r.H }
}

function Update-CommittedPolygonBounds($r) {
    if (-not $r -or $r.Shape -ne "Polygon" -or -not $r.Points -or $r.Points.Count -lt 3) { return }
    $b = Get-PointsBoundingRect $r.Points
    $r.X=[double]$b.X; $r.Y=[double]$b.Y
    $r.W=[double][Math]::Max(2.0,[double]$b.Width)
    $r.H=[double][Math]::Max(2.0,[double]$b.Height)
}

function Normalize-CommittedRedactionGeometry($r) {
    if (-not $r) { return }
    if ($r.Shape -eq "Polygon") {
        $pts=@()
        foreach ($p in $r.Points) {
            $x=[int][Math]::Round([Math]::Max(0.0,[Math]::Min([double]$p.X,[double]$videoWidth-1.0)))
            $y=[int][Math]::Round([Math]::Max(0.0,[Math]::Min([double]$p.Y,[double]$videoHeight-1.0)))
            $pts += [PSCustomObject]@{ X=$x; Y=$y }
        }
        $r.Points=$pts
        $minX=($pts|ForEach-Object{$_.X}|Measure-Object -Minimum).Minimum
        $maxX=($pts|ForEach-Object{$_.X}|Measure-Object -Maximum).Maximum
        $minY=($pts|ForEach-Object{$_.Y}|Measure-Object -Minimum).Minimum
        $maxY=($pts|ForEach-Object{$_.Y}|Measure-Object -Maximum).Maximum
        $bbox=Normalize-VideoRect $minX $minY ([Math]::Max(2,$maxX-$minX)) ([Math]::Max(2,$maxY-$minY))
        $r.X=$bbox.X; $r.Y=$bbox.Y; $r.W=$bbox.W; $r.H=$bbox.H
        return
    }
    $nr=Normalize-VideoRect ([double]$r.X) ([double]$r.Y) ([double]$r.W) ([double]$r.H)
    $r.X=$nr.X; $r.Y=$nr.Y; $r.W=$nr.W; $r.H=$nr.H
}

function Begin-CommittedRedactionMove($r, [System.Drawing.PointF]$mediaPoint) {
    $snap=Copy-RedactionGeometrySnapshot $r
    if (-not $snap -or -not $mediaPoint) { return $false }
    $script:redactionCommittedMoving=$true
    $script:redactionCommittedMoveStart=$mediaPoint
    $script:redactionCommittedOrig=$snap
    $picture.Capture=$true
    $picture.Cursor=[System.Windows.Forms.Cursors]::SizeAll
    return $true
}

function Update-CommittedRedactionMove([System.Drawing.PointF]$mediaPoint) {
    if (-not $script:redactionCommittedMoving -or -not $mediaPoint -or -not $script:redactionCommittedMoveStart -or -not $script:redactionCommittedOrig) { return }
    $r=Get-SelectedCommittedRedaction
    $bounds=Get-DraftMediaBounds
    if (-not $r -or -not $bounds) { return }
    $dx=[double]$mediaPoint.X-[double]$script:redactionCommittedMoveStart.X
    $dy=[double]$mediaPoint.Y-[double]$script:redactionCommittedMoveStart.Y
    $orig=$script:redactionCommittedOrig
    $origBounds=New-Object System.Drawing.RectangleF([single]$orig.X,[single]$orig.Y,[single]$orig.W,[single]$orig.H)
    if ($orig.Shape -eq "Polygon") { $origBounds=Get-PointsBoundingRect $orig.Points }
    $d=Get-ClampedTranslation $origBounds $dx $dy $bounds
    if ($orig.Shape -eq "Polygon") {
        $pts=@(); foreach ($p in $orig.Points) { $pts += [PSCustomObject]@{ X=[double]$p.X+[double]$d.Dx; Y=[double]$p.Y+[double]$d.Dy } }
        $r.Points=$pts
        Update-CommittedPolygonBounds $r
    } else {
        $r.X=[double]$orig.X+[double]$d.Dx
        $r.Y=[double]$orig.Y+[double]$d.Dy
    }
}

function Stop-CommittedRedactionMove {
    $r=Get-SelectedCommittedRedaction
    if ($r) { Normalize-CommittedRedactionGeometry $r }
    $script:redactionCommittedMoving=$false
    $script:redactionCommittedMoveStart=$null
    $script:redactionCommittedOrig=$null
    if ($picture) { $picture.Capture=$false }
}

function Draw-SelectedCommittedRedactionGuide($gfx) {
    $r=Get-SelectedCommittedRedaction
    if (-not $r -or -not $gfx) { return }
    if ($r.Shape -eq "Polygon") {
        $dpts=VideoPoints-To-DisplayPoints $r.Points
        if ($dpts -and $dpts.Count -ge 3) {
            $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::Gold,1)
            $pen.DashStyle=[System.Drawing.Drawing2D.DashStyle]::Dash
            try { $gfx.DrawPolygon($pen,$dpts) } finally { $pen.Dispose() }
            Draw-FreeformVertexHandles $gfx $r.Points
        }
        return
    }
    $rect=Get-RedactionMediaBounds $r
    $vr=MediaRect-To-ViewRect $rect
    if ($vr) {
        $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::Gold,1)
        $pen.DashStyle=[System.Drawing.Drawing2D.DashStyle]::Dash
        try {
            if ($r.Shape -eq "Oval") { $gfx.DrawEllipse($pen,$vr) }
            else { $gfx.DrawRectangle($pen,$vr.X,$vr.Y,$vr.Width,$vr.Height) }
        } finally { $pen.Dispose() }
    }
    if ($r.Shape -eq "Oval") { Draw-OvalResizeHandles $gfx $rect }
    else { Draw-RectangleResizeHandles $gfx $rect }
}

function VideoRect-To-Display($vx, $vy, $vw, $vh) {
    if ($zoomMode -ne "Fit") {
        $transform = Get-ViewportTransform
        if (-not $transform) { return $null }
        return New-Object System.Drawing.RectangleF(
            [single]([double]$transform.OriginX + ([double]$vx * [double]$transform.ScaleX)),
            [single]([double]$transform.OriginY + ([double]$vy * [double]$transform.ScaleY)),
            [single]([double]$vw * [double]$transform.ScaleX),
            [single]([double]$vh * [double]$transform.ScaleY))
    }

    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }
 
    # Preserve r18's exact arithmetic order in Fit mode.
    $x = [int]($imgRect.X + ($vx * $imgRect.Width / $videoWidth))
    $y = [int]($imgRect.Y + ($vy * $imgRect.Height / $videoHeight))
    $w = [int]($vw * $imgRect.Width / $videoWidth)
    $h = [int]($vh * $imgRect.Height / $videoHeight)
 
    return New-Object System.Drawing.Rectangle($x,$y,$w,$h)
}
 
function VideoPoints-To-DisplayPoints($pts) {
    if ($zoomMode -ne "Fit") {
        $transform = Get-ViewportTransform
        if (-not $transform) { return $null }
        $outF = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        foreach ($p in $pts) {
            $dx = [single]([double]$transform.OriginX + ([double]$p.X * [double]$transform.ScaleX))
            $dy = [single]([double]$transform.OriginY + ([double]$p.Y * [double]$transform.ScaleY))
            $outF.Add((New-Object System.Drawing.PointF($dx,$dy)))
        }
        return $outF.ToArray()
    }

    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect -or $videoWidth -le 0 -or $videoHeight -le 0) { return $null }
 
    $out = New-Object System.Collections.Generic.List[System.Drawing.Point]
    foreach ($p in $pts) {
        $dx = [int]($imgRect.X + ($p.X * $imgRect.Width / $videoWidth))
        $dy = [int]($imgRect.Y + ($p.Y * $imgRect.Height / $videoHeight))
        $out.Add((New-Object System.Drawing.Point($dx,$dy)))
    }
    return $out.ToArray()
}
 
function DisplayPoint-To-VideoPoint([System.Drawing.Point]$pt) {
    if ($zoomMode -ne "Fit") {
        $mp = ViewPoint-To-MediaPoint (New-Object System.Drawing.PointF([single]$pt.X,[single]$pt.Y)) $true
        if (-not $mp) { return $null }
        return @{ X = [int][Math]::Round($mp.X); Y = [int][Math]::Round($mp.Y) }
    }

    $imgRect = Get-DisplayedImageRect
    if (-not $imgRect) { return $null }
 
    $vx = ($pt.X - $imgRect.X) * $videoWidth / $imgRect.Width
    $vy = ($pt.Y - $imgRect.Y) * $videoHeight / $imgRect.Height
    $vx = [Math]::Max(0, [Math]::Min($vx, $videoWidth - 1))
    $vy = [Math]::Max(0, [Math]::Min($vy, $videoHeight - 1))
    return @{ X = [int][Math]::Round($vx); Y = [int][Math]::Round($vy) }
}
 
# Converts a completed freeform draft that is ALREADY in canonical MEDIA space
# into the existing committed Polygon descriptor. Vertices are rounded/clamped
# only at this boundary so resizing the viewport can never alter draft geometry.
function Polygon-To-VideoShape($mediaPoints) {
    if ($mediaPoints.Count -lt 3) { return $null }

    $vpts = @()
    foreach ($p in $mediaPoints) {
        $cx = [Math]::Max(0.0, [Math]::Min([double]$p.X, [double]$videoWidth - 1.0))
        $cy = [Math]::Max(0.0, [Math]::Min([double]$p.Y, [double]$videoHeight - 1.0))
        $vpts += ,@{ X = [int][Math]::Round($cx); Y = [int][Math]::Round($cy) }
    }

    $minX = ($vpts | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum
    $maxX = ($vpts | ForEach-Object { $_.X } | Measure-Object -Maximum).Maximum
    $minY = ($vpts | ForEach-Object { $_.Y } | Measure-Object -Minimum).Minimum
    $maxY = ($vpts | ForEach-Object { $_.Y } | Measure-Object -Maximum).Maximum

    $bbox = Normalize-VideoRect $minX $minY ([Math]::Max(2, $maxX - $minX)) ([Math]::Max(2, $maxY - $minY))
    return @{ Shape = "Polygon"; X = $bbox.X; Y = $bbox.Y; W = $bbox.W; H = $bbox.H; Points = $vpts }
}
 
# Returns the shape descriptor for whatever is currently drawn-but-not-yet-
# committed (a finished drag for Rectangle/Oval, or a closed click-path for
# Polygon), or $null if there's nothing ready to become a redaction yet.
function Get-CurrentShapeVideoData {
    # D3 Draw tools (Text/Line/Polyline) commit directly into the annotation
    # collection and are never candidates for the redaction Begin/Create workflow.
    if (Test-IsStandaloneDrawTool) { return $null }
    if ($toolMode -eq "Polygon") {
        if ($polygonActive -or $polygonPoints.Count -lt 3) { return $null }
        return Polygon-To-VideoShape $polygonPoints
    }
    else {
        $vr = Selection-To-VideoRect
        if (-not $vr) { return $null }
        return @{ Shape = $toolMode; X = $vr.X; Y = $vr.Y; W = $vr.W; H = $vr.H }
    }
}
 
# Draws one redaction's shape (committed, pending, or a preview) onto the
# PictureBox in video-space -> converted to display coordinates here, so the
# same function serves the Paint handler for both committed (green) and
# pending (orange) redactions.
function Draw-RedactionShape($gfx, $r, [System.Drawing.Color]$borderColor, [System.Drawing.Color]$fillColor, [bool]$drawGuideBorder = $true) {
    $pen = New-Object System.Drawing.Pen($borderColor, 2)
    $brush = New-Object System.Drawing.SolidBrush($fillColor)
 
    if ($r.Shape -eq "Oval") {
        $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
        if ($dr) {
            $gfx.FillEllipse($brush, $dr)
            if ($drawGuideBorder) { $gfx.DrawEllipse($pen, $dr) }
        }
    }
    elseif ($r.Shape -eq "Polygon") {
        $dpts = VideoPoints-To-DisplayPoints $r.Points
        if ($dpts -and $dpts.Count -ge 3) {
            $gfx.FillPolygon($brush, $dpts)
            if ($drawGuideBorder) { $gfx.DrawPolygon($pen, $dpts) }
        }
    }
    else {
        $dr = VideoRect-To-Display $r.X $r.Y $r.W $r.H
        if ($dr) {
            $gfx.FillRectangle($brush, $dr)
            if ($drawGuideBorder) { Draw-ViewportRectangleOutline $gfx $pen $dr }
        }
    }
 
    $brush.Dispose()
    $pen.Dispose()
}
 
# Renders the per-redaction mask PNG used by Build-RedactionFilterComplex for
# non-rectangular shapes. Sized exactly to the redaction's bounding box (W x H)
# so it lines up pixel-for-pixel once ffmpeg overlays/alphamerges it back at
# (X,Y). "Black box" masks carry real alpha (transparent background, opaque
# black shape) and get overlaid directly; Blur/Pixelate masks are a plain
# white-shape-on-black image whose luma becomes the processed patch's alpha
# via `alphamerge`.
function New-ShapeMaskFile($r, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap([int]$r.W, [int]$r.H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
 
    $isBlackBox = ($r.Mode -eq "Black box")
    # SECURITY: opaque redaction masks must have binary coverage. AntiAlias
    # creates partially transparent edge pixels that blend source + replacement.
    # Blur/Pixelate keep their smoother mask edge because they are explicitly
    # visual-obscuration modes, not guaranteed irreversible redaction.
    $g.SmoothingMode = if ($isBlackBox) { [System.Drawing.Drawing2D.SmoothingMode]::None } else { [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias }
    if ($isBlackBox) {
        # Older redactions created before the Coloured Box picker existed
        # won't have a Color field - fall back to plain black, matching the
        # original hardcoded "black box" behavior exactly.
        $boxColor = if ($r.Color) { $r.Color } else { [System.Drawing.Color]::Black }
        $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
        $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $boxColor.R, $boxColor.G, $boxColor.B))
    }
    else {
        $g.Clear([System.Drawing.Color]::Black)
        $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    }
 
    if ($r.Shape -eq "Oval") {
        $g.FillEllipse($shapeBrush, 0, 0, $r.W, $r.H)
    }
    elseif ($r.Shape -eq "Polygon") {
        $pts = @()
        foreach ($p in $r.Points) {
            $pts += New-Object System.Drawing.Point(($p.X - $r.X), ($p.Y - $r.Y))
        }
        if ($pts.Count -ge 3) {
            $g.FillPolygon($shapeBrush, $pts)
            if ($isBlackBox) {
                # Export geometry has a 1 px larger bounding box. A 2 px hard
                # stroke therefore dilates a freeform boundary by ~1 px without
                # being clipped except at the actual media edge.
                $edgePen = New-Object System.Drawing.Pen($shapeBrush.Color, 2)
                $edgePen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
                $g.DrawPolygon($edgePen, $pts)
                $edgePen.Dispose()
            }
        }
    }
 
    $shapeBrush.Dispose()
    $g.Dispose()
 
    if (Test-Path $outPath) { Remove-Item $outPath -Force -ErrorAction SilentlyContinue }
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}
 
# D5b visual-layer restoration mask. This is not a security mask and never
# changes source-redaction coverage; it merely clips an annotation so a later
# active redaction can visually sit above it while the already-redacted pixels
# are restored from the security-pass branch.
function New-AnnotationOcclusionMaskFile($r, [string]$outPath) {
    $bmp = New-Object System.Drawing.Bitmap([int]$r.W, [int]$r.H)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $isOpaque = ($r.Mode -eq 'Black box')
    $g.SmoothingMode = if ($isOpaque) { [System.Drawing.Drawing2D.SmoothingMode]::None } else { [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias }
    $g.Clear([System.Drawing.Color]::Black)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    try {
        if ($r.Shape -eq 'Oval') {
            $g.FillEllipse($brush,0,0,[int]$r.W,[int]$r.H)
        }
        elseif ($r.Shape -eq 'Polygon') {
            $pts=@()
            foreach ($p in $r.Points) { $pts += New-Object System.Drawing.Point(([int]$p.X-[int]$r.X),([int]$p.Y-[int]$r.Y)) }
            if ($pts.Count -ge 3) {
                $g.FillPolygon($brush,$pts)
                if ($isOpaque) {
                    $edgePen=New-Object System.Drawing.Pen([System.Drawing.Color]::White,2)
                    try { $edgePen.LineJoin=[System.Drawing.Drawing2D.LineJoin]::Round; $g.DrawPolygon($edgePen,$pts) }
                    finally { $edgePen.Dispose() }
                }
            }
        }
        else {
            $g.FillRectangle($brush,0,0,[int]$r.W,[int]$r.H)
        }
    }
    finally { $brush.Dispose(); $g.Dispose() }
    if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force -ErrorAction SilentlyContinue }
    try { $bmp.Save($outPath,[System.Drawing.Imaging.ImageFormat]::Png) }
    finally { $bmp.Dispose() }
}

# ----------------------------
# UI state helpers
# ----------------------------
# Paints a Begin/End/Create-Redaction button as either its theme-neutral
# "grey" (inactive) look, or a fixed "green" (ready to begin) / "red"
# (in progress, ready to end) status color. Called from Update-RedactionButtons
# any time enable state changes, and from the theme-toggle handler so the
# grey state stays in sync with the active theme.
function Set-RedactionButtonColor([System.Windows.Forms.Button]$btn, [string]$state) {
    switch ($state) {
        "green" {
            $btn.BackColor = $script:colorGreenBg
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $script:colorGreenBorder
        }
        "red" {
            $btn.BackColor = $script:colorRedBg
            $btn.ForeColor = [System.Drawing.Color]::White
            $btn.FlatAppearance.BorderColor = $script:colorRedBorder
        }
        default {
            $btn.BackColor = $script:cButtonCurrent
            $btn.ForeColor = $script:cTextCurrent
            $btn.FlatAppearance.BorderColor = $script:cBorderCurrent
        }
    }
}

# v2.2.0 B1 quarter-turn state helpers. Source orientation and user rotation are
# deliberately separate: sourceDisplayWidth/Height already include trusted
# FFmpeg autorotation; UserRotation is the additional user-selected turn.
function Set-WorkingDimensionsForUserRotation {
    if ($sourceDisplayWidth -le 0 -or $sourceDisplayHeight -le 0) {
        $script:videoWidth = 0
        $script:videoHeight = 0
        return
    }

    if (($userRotation % 180) -ne 0) {
        $script:videoWidth = [int]$sourceDisplayHeight
        $script:videoHeight = [int]$sourceDisplayWidth
    }
    else {
        $script:videoWidth = [int]$sourceDisplayWidth
        $script:videoHeight = [int]$sourceDisplayHeight
    }
}

# Rotation is a pre-redaction media setup operation. Any state that would need
# geometry transformation locks the controls rather than attempting to rotate
# existing rectangles, ovals, freeform vertices or timeline ranges.
function Test-HasRotationLockoutState {
    if($isImageMode -and $script:ImageCrop){return $true}
    if ($redactions -and $redactions.Count -gt 0) { return $true }
    if ($annotations -and $annotations.Count -gt 0) { return $true }
    if ($pendingRedaction -or $script:pendingAnnotation) { return $true }
    if ($dragging -or $movingShape -or $script:resizingShape -or $script:editingPolygonVertex) { return $true }
    if ($selection -and ($selection.Width -gt 0.0 -or $selection.Height -gt 0.0)) { return $true }
    if ($polygonActive -or ($polygonPoints -and $polygonPoints.Count -gt 0)) { return $true }
    if ($script:lineDrawing -or $script:lineStart -or $script:lineEnd) { return $true }
    if ($script:polylineActive -or ($script:polylinePoints -and $script:polylinePoints.Count -gt 0)) { return $true }
    if ($script:textDrawing -or $script:textDraftActive) { return $true }
    return $false
}

function Update-RotationButtons {
    if($script:ExportBusy){return}
    if (-not $btnRotateCCW -or -not $btnRotateCW) { return }
    $canRotate = [bool]($videoPath -and -not (Test-HasRotationLockoutState))
    $btnRotateCCW.Enabled = $canRotate
    $btnRotateCW.Enabled = $canRotate
    Update-TransportButtonVisuals
}

function Update-RedactionButtons {
    if($script:ExportBusy){return}
    $hasVideo = [bool]$videoPath
    $hasSelection = [bool](Get-CurrentShapeVideoData)
    $drawTool = [bool](Test-IsStandaloneDrawTool)
    $annotationContext = [bool](-not $isImageMode -and ($drawTool -or $script:pendingAnnotation))
    $managedBlocksVisualObscuration = [bool]($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration)

    if (-not $isImageMode) {
        $btnStartRedaction.Text = if ($annotationContext) { "Begin Annotation" } else { "Begin Redaction" }
        $btnEndRedaction.Text = if ($annotationContext) { "End Annotation" } else { "End Redaction" }
        $btnCancelRedaction.Text = if ($annotationContext) { "Cancel Annotation" } else { "Cancel Redaction" }
    }

    if ($isImageMode) {
        # Standalone Draw tools use their own explicit annotation commit controls
        # inside Appearance, so the redaction Create button stays hidden.
        $btnAddRedaction.Visible = $true
        $hasAppearance = [bool]($script:fillEnabled -or $script:outlineEnabled)
        $btnAddRedaction.Text = if ($drawTool -or -not $script:fillEnabled) { "Create Annotation" } else { "Create Redaction" }
        $draftReady = if ($toolMode -eq "Text") { $script:textDraftActive -and -not [string]::IsNullOrWhiteSpace($txtAnnotationText.Text) } elseif ($toolMode -eq "Line") { $script:lineDraftActive } elseif ($toolMode -eq "Polyline") { $script:polylineDraftActive } else { $false }
        $btnAddRedaction.Enabled = ($hasVideo -and (($drawTool -and $draftReady) -or (-not $drawTool -and $hasSelection -and $hasAppearance)))
        Set-RedactionButtonColor $btnAddRedaction $(if ($btnAddRedaction.Enabled) { "green" } else { "grey" })
        $rbRectangle.Enabled = $true
        $rbOval.Enabled = $true
        $rbFreeform.Enabled = $true
        $rbText.Enabled = $true
        $rbLine.Enabled = $true
        $rbPolyline.Enabled = $true
        $styleEnabled = [bool]($script:fillEnabled -and -not $drawTool)
        $rbModeBlack.Enabled = $styleEnabled
        $rbModeBlur.Enabled = [bool]($styleEnabled -and -not $managedBlocksVisualObscuration)
        $rbModePixelate.Enabled = [bool]($styleEnabled -and -not $managedBlocksVisualObscuration)
    }
    elseif ($script:pendingAnnotation) {
        $btnAddRedaction.Visible = $false
        $btnStartRedaction.Enabled = $false
        Set-RedactionButtonColor $btnStartRedaction "grey"
        $btnEndRedaction.Enabled = $true
        Set-RedactionButtonColor $btnEndRedaction "red"
        $btnCancelRedaction.Enabled = $true
        $rbModeBlack.Enabled = $false; $rbModeBlur.Enabled = $false; $rbModePixelate.Enabled = $false
        $rbRectangle.Enabled = $false; $rbOval.Enabled = $false; $rbFreeform.Enabled = $false
        $rbText.Enabled = $false; $rbLine.Enabled = $false; $rbPolyline.Enabled = $false
        if ($lvRedactions) { $lvRedactions.Enabled = $false }
        if ($lvAnnotations) { $lvAnnotations.Enabled = $false }
    }
    elseif ($drawTool) {
        $btnAddRedaction.Visible = $false
        $draftReady = [bool](Test-VideoAnnotationDraftReady)
        $draftPresent = [bool](Test-VideoAnnotationDraftPresent)
        $btnStartRedaction.Enabled = ($hasVideo -and $draftReady)
        Set-RedactionButtonColor $btnStartRedaction $(if ($btnStartRedaction.Enabled) { "green" } else { "grey" })
        $btnEndRedaction.Enabled = $false
        Set-RedactionButtonColor $btnEndRedaction "grey"
        $btnCancelRedaction.Enabled = $draftPresent
        $rbModeBlack.Enabled = $false; $rbModeBlur.Enabled = $false; $rbModePixelate.Enabled = $false
        $rbRectangle.Enabled = $true; $rbOval.Enabled = $true; $rbFreeform.Enabled = $true
        $rbText.Enabled = $true; $rbLine.Enabled = $true; $rbPolyline.Enabled = $true
        if ($lvRedactions) { $lvRedactions.Enabled = $true }
        if ($lvAnnotations) { $lvAnnotations.Enabled = $true }
    }
    elseif ($pendingRedaction) {
        $btnAddRedaction.Visible = $false
        $btnStartRedaction.Enabled = $false
        Set-RedactionButtonColor $btnStartRedaction "grey"
        $btnEndRedaction.Enabled = $true
        Set-RedactionButtonColor $btnEndRedaction "red"
        $btnCancelRedaction.Enabled = $true
        $rbModeBlack.Enabled = $false; $rbModeBlur.Enabled = $false; $rbModePixelate.Enabled = $false
        $rbRectangle.Enabled = $false
        $rbOval.Enabled = $false
        $rbFreeform.Enabled = $false
        $rbText.Enabled = $false
        $rbLine.Enabled = $false
        $rbPolyline.Enabled = $false
        if ($lvRedactions) { $lvRedactions.Enabled = $true }
        if ($lvAnnotations) { $lvAnnotations.Enabled = $true }
    }
    else {
        $btnAddRedaction.Visible = $false
        $btnStartRedaction.Enabled = ($hasVideo -and $hasSelection)
        Set-RedactionButtonColor $btnStartRedaction $(if ($btnStartRedaction.Enabled) { "green" } else { "grey" })
        $btnEndRedaction.Enabled = $false
        Set-RedactionButtonColor $btnEndRedaction "grey"
        $btnCancelRedaction.Enabled = $false
        $rbModeBlack.Enabled = $true
        $rbModeBlur.Enabled = -not $managedBlocksVisualObscuration
        $rbModePixelate.Enabled = -not $managedBlocksVisualObscuration
        $rbRectangle.Enabled = $true
        $rbOval.Enabled = $true
        $rbFreeform.Enabled = $true
        $rbText.Enabled = $true
        $rbLine.Enabled = $true
        $rbPolyline.Enabled = $true
        if ($lvRedactions) { $lvRedactions.Enabled = $true }
        if ($lvAnnotations) { $lvAnnotations.Enabled = $true }
    }

    $hasStandaloneAnnotations = [bool]($annotations -and $annotations.Count -gt 0)
    $btnExport.Enabled = ($hasVideo -and -not $script:pendingAnnotation -and ($redactions.Count -gt 0 -or $hasStandaloneAnnotations -or ($isImageMode -and $script:ImageCrop)))
    if ($isImageMode) {
        $btnExport.Text = if($isImageMode -and $script:ImageCrop -and $redactions.Count -eq 0 -and -not $hasStandaloneAnnotations){"Export Cropped Image"} elseif ($redactions.Count -gt 0) { "Export Redacted Image" } elseif ($hasStandaloneAnnotations) { "Export Annotated Image" } else { "Export Image" }
    }
    else {
        $btnExport.Text = if($isImageMode -and $script:ImageCrop -and $redactions.Count -eq 0 -and -not $hasStandaloneAnnotations){"Export Cropped Image"} elseif ($redactions.Count -gt 0) { "Export Redacted Video" } elseif ($hasStandaloneAnnotations) { "Export Annotated Video" } else { "Export Video" }
    }
    Update-ExportButtonAppearance
    $script:appToolTip.SetToolTip($btnExport, "")
    if(Get-Command Update-CopyButton -ErrorAction SilentlyContinue){Update-CopyButton}
    $btnEyedropper.Enabled = $hasVideo -and -not $drawTool -and -not $script:pendingAnnotation
    Update-StrengthSliderVisibility
    Update-OutlineControlsAvailability
    Update-RotationButtons
    Update-SourceDeletionUi
    Update-CropControls
}
 
function Refresh-RedactionList {
    $keepSelectedRedactionIndex = [int]$script:selectedRedactionIndex
    $lvRedactions.Items.Clear()
    for ($i = 0; $i -lt $redactions.Count; $i++) {
        $r = $redactions[$i]
        $item = New-Object System.Windows.Forms.ListViewItem(($i+1).ToString())
        [void]$item.SubItems.Add($r.Shape)
        $modeText = if (Get-RedactionEnhanced $r) { "$($r.Mode) A" } else { $r.Mode }
        if (Test-RedactionHasOutline $r) { $modeText += " + Outline" }
        [void]$item.SubItems.Add($modeText)
        [void]$item.SubItems.Add("$(SecToText $r.MarkStart) - $(SecToText $r.MarkEnd)")
        [void]$item.SubItems.Add("$(SecToText $r.BufferedStart) - $(SecToText $r.BufferedEnd)")
        [void]$item.SubItems.Add("x=$($r.X), y=$($r.Y), w=$($r.W), h=$($r.H)")
        [void]$lvRedactions.Items.Add($item)
    }
    if ($keepSelectedRedactionIndex -ge 0 -and $keepSelectedRedactionIndex -lt $lvRedactions.Items.Count) {
        $script:selectedRedactionIndex = $keepSelectedRedactionIndex
        $lvRedactions.Items[$keepSelectedRedactionIndex].Selected = $true
    }
    elseif ($keepSelectedRedactionIndex -ge $redactions.Count) {
        $script:selectedRedactionIndex = -1
    }
    $scrubberMarkers.Invalidate()
    # A committed redaction's shape can be showing on the current preview
    # frame; any time the list changes (added, removed, cleared) that overlay
    # may need to appear or disappear, so repaint the preview too.
    $picture.Invalidate()
    # Selection can end up cleared (e.g. after Remove/Clear All) without a
    # SelectedIndexChanged event always firing predictably - refresh the
    # swatch explicitly so it never keeps showing a just-deleted redaction's
    # color as if it were still the active edit target.
    Update-ColorSwatch
}
 
function Refresh-AnnotationList {
    if (-not $lvAnnotations) { return }
    $lvAnnotations.Items.Clear()
    for ($i = 0; $i -lt $annotations.Count; $i++) {
        $a = $annotations[$i]
        $item = New-Object System.Windows.Forms.ListViewItem(($i+1).ToString())
        $shapeText = if ($a.Shape -eq "Polygon") { "Freeform" } elseif ($a.Kind -eq "Text") { "Text Box" } else { [string]$a.Shape }
        $typeText = if ($a.Kind -eq "Text") { "Text annotation" } elseif ($a.Kind -eq "Line" -or $a.Kind -eq "Polyline") { "Drawing annotation" } else { "Outline only (not a redaction)" }
        $rangeText = ""
        if (-not $isImageMode -and $a.Kind -in @("Text","Line","Polyline")) {
            $typeText = if ($a.Kind -eq "Text") { "Text" } else { "Drawing" }
            $ar = Get-AnnotationFrameRange $a
            $rangeText = "$([int]$ar.Start + 1)-$([int]$ar.End + 1)"
        }
        [void]$item.SubItems.Add($shapeText)
        [void]$item.SubItems.Add($typeText)
        [void]$item.SubItems.Add($rangeText)
        [void]$lvAnnotations.Items.Add($item)
    }
    if ($script:selectedAnnotationIndex -ge 0 -and $script:selectedAnnotationIndex -lt $lvAnnotations.Items.Count) {
        $lvAnnotations.Items[$script:selectedAnnotationIndex].Selected = $true
    }
    elseif ($script:selectedAnnotationIndex -ge $annotations.Count) {
        $script:selectedAnnotationIndex = -1
    }
    $scrubberMarkers.Invalidate()
    $picture.Invalidate()
}

function Stop-Playback {
    if ($isPlaying) {
        $script:isPlaying = $false
        $playTimer.Stop()
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
    }
}
 
# Clears whatever is currently being drawn (an in-progress drag, or an
# in-progress/just-closed freeform click-path) without touching any already
# committed or pending redaction. Called whenever the tool changes, a
# redaction is started/ended/cancelled, or a new file is loaded.
function Reset-DrawingState {
    if ($script:floatingTextEditorVisible) { Close-FloatingTextEditor $false }
    $script:dragging = $false
    $script:dragStart = New-Object System.Drawing.PointF(0,0)
    $script:selection = New-Object System.Drawing.RectangleF(0,0,0,0)
    $script:polygonActive = $false
    $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $script:polygonMousePos = $null
    $script:movingShape = $false
    $script:moveStart = New-Object System.Drawing.PointF(0,0)
    $script:moveOrigSelection = $null
    $script:moveOrigPolygonPoints = $null
    $script:resizingShape = $false
    $script:resizeHandle = "None"
    $script:resizeShapeKind = "None"
    $script:resizeOrigSelection = $null
    $script:resizeDraftDrawStartView = $null
    $script:resizeDraftDrawMoved = $false
    $script:editingPolygonVertex = $false
    $script:polygonVertexIndex = -1
    $script:lineDrawing = $false
    $script:lineDraftActive = $false
    $script:lineStart = $null
    $script:lineEnd = $null
    $script:polylineActive = $false
    $script:polylineDraftActive = $false
    $script:polylinePoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
    $script:polylineMousePos = $null
    $script:polylineGestureAxis = "None"
    $script:polylineGestureLastRaw = $null
    $script:textDrawing = $false
    $script:textDragStart = $null
    $script:textDraftActive = $false
    $script:textDraftRect = New-Object System.Drawing.RectangleF(0,0,0,0)
    $script:annotationDraftMoving = $false
    $script:annotationDraftMoveKind = "None"
    $script:annotationDraftMoveStart = $null
    $script:annotationDraftOrigTextRect = $null
    $script:annotationDraftOrigLineStart = $null
    $script:annotationDraftOrigLineEnd = $null
    $script:annotationDraftOrigPolylinePoints = $null
    $script:textDraftResizing = $false
    $script:textDraftResizeHandle = "None"
    $script:textDraftResizeOrigRect = $null
    $script:annotationCommittedMoving = $false
    $script:annotationCommittedMoveStart = $null
    $script:annotationCommittedOrig = $null
    $script:annotationCommittedTextResizing = $false
    $script:annotationCommittedTextResizeHandle = "None"
    $script:annotationCommittedTextResizeOrigRect = $null
    $script:annotationCommittedResizing = $false
    $script:annotationCommittedResizeHandle = "None"
    $script:annotationCommittedResizeOrigRect = $null
    $script:annotationCommittedVertexEditing = $false
    $script:annotationCommittedVertexIndex = -1
    $script:redactionCommittedMoving = $false
    $script:redactionCommittedMoveStart = $null
    $script:redactionCommittedOrig = $null
    $script:redactionCommittedResizing = $false
    $script:redactionCommittedResizeHandle = "None"
    $script:redactionCommittedResizeOrigRect = $null
    $script:redactionCommittedPolygonEditing = $false
    $script:redactionCommittedPolygonVertexIndex = -1
    if ($txtAnnotationText) { $txtAnnotationText.Text = "" }
    if ($picture) { $picture.Capture = $false; $picture.Invalidate() }
    if ($textAppearancePanel) { Update-OutlineControlsAvailability }
}
 
function Reset-RedactionState {
    $script:redactions = New-Object System.Collections.ArrayList
    $script:annotations = New-Object System.Collections.ArrayList
    $script:selectedAnnotationIndex = -1
    $script:selectedRedactionIndex = -1
    $script:objectCommitCounter = 0
    $script:pendingRedaction = $null
    $script:pendingAnnotation = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = "No temporal operation in progress."
    Refresh-RedactionList
    Refresh-AnnotationList
}
 
# Swaps the handful of UI bits that read differently depending on whether a
# video or a still image is currently loaded: the shared Begin/End/Cancel
# temporal workflow doesn't make sense for a single image, so
# that becomes one "Add Redaction" button, and video-only controls (audio,
# quality) are hidden. "Open video/file..." itself never changes - it always
# accepts either kind of file.
function Apply-ModeLabels {
    if ($isImageMode) {
        $lblHint.Text = "Load an image, create redactions or annotations, then export. Draw tools are annotation-only."
        $lblPos.Text = "Preview:"
        $btnExport.Text = "Export Redacted Image"
        $lblBufferNote.Text = "Redactions and annotations apply to the whole image - there's no timeline (and so no before/after buffer) for a still image."
        $btnStartRedaction.Visible = $false
        $btnEndRedaction.Visible = $false
        $btnCancelRedaction.Visible = $false
        $lblPending.Visible = $false
        $btnAddRedaction.Visible = $true
        $chkAudio.Visible = $false
        $lblQuality.Visible = $false
        $cmbQuality.Visible = $false
        $lvRedactions.Columns[2].Width = 150
        $lvRedactions.Columns[3].Width = 0
        $lvRedactions.Columns[4].Width = 0
        $lvAnnotations.Columns[2].Width = 185
        $lvAnnotations.Columns[3].Width = 0

        # Output format list swaps to the image container set. Default: PNG.
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange($IMAGE_FORMATS)
        $cmbFormat.SelectedIndex = 0
    }
    else {
        $lblHint.Text = "Load a video, create timed redactions or Text/Line/Polyline annotations, then export."
        $lblPos.Text = "Preview frame:"
        $btnExport.Text = "Export Redacted Video"
        $lblBufferNote.Text = "Redactions are padded by $BUFFER_FRAMES frames before/after. Annotation Begin/End ranges are exact logical frames with no buffer."
        $btnStartRedaction.Visible = $true
        $btnEndRedaction.Visible = $true
        $btnCancelRedaction.Visible = $true
        $lblPending.Visible = $true
        $btnAddRedaction.Visible = $false
        $chkAudio.Visible = $true
        $lblQuality.Visible = $true
        $cmbQuality.Visible = $true
        $lvRedactions.Columns[2].Width = 92
        $lvRedactions.Columns[3].Width = 145
        $lvRedactions.Columns[4].Width = 0
        $lvAnnotations.Columns[2].Width = 100
        $lvAnnotations.Columns[3].Width = 105

        # Output format list swaps to the video container set. Default: MP4.
        $cmbFormat.Items.Clear()
        $cmbFormat.Items.AddRange($VIDEO_FORMATS)
        $cmbFormat.SelectedIndex = 0
    }
    Update-InspectorSectionLayout
    Update-SecurityModeNote
    Update-StrengthSliderVisibility
    Update-ColorPickerVisibility
    Update-OutlineControlsAvailability
    Update-SourceDeletionUi
    if (Get-Command Update-ToolHintText -ErrorAction SilentlyContinue) { Update-ToolHintText }
}
 
# ----------------------------
# Preview extraction
# ----------------------------
function Load-PreviewFrame {
    if (-not $videoPath) { return }
    if ($previewImage -and $loadedFrame -eq $currentFrame) { return }

    $status.Text = if ($isImageMode) { "Loading image..." } else { "Loading preview frame..." }
    $form.Refresh()

    # Extracted frames used to be written to a temp PNG in %TEMP% and then
    # deleted once loaded - if the app or Windows crashed in the narrow
    # window between those two steps, that PNG (a full frame of whatever is
    # on screen, including anything the user is about to redact) could be
    # left behind on disk indefinitely. Piping ffmpeg's output straight into
    # this process's own memory instead removes that window entirely: the
    # frame is never written to a file at all, so there is nothing on disk
    # to leak even if PowerShell, ffmpeg, or Windows itself dies mid-extract.
    #
    # Runs FFmpeg to extract exactly the logical frame identified by the trusted
    # frame map. The selector compares the decoded frame PTS to FFprobe's exact
    # best_effort_timestamp; it never asks FFmpeg for "whatever frame is near"
    # a floating-point time. -copyts keeps source PTS intact across the coarse
    # seek. If the exact mapped PTS is not decoded, extraction returns no frame
    # and TinyRedactionTool fails closed rather than showing a neighbour.
    $tryExtractFrame = {
        param([int]$targetFrame)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffmpeg
        if ($isImageMode) {
            # A still image has no timeline to seek within - just decode it (via
            # ffmpeg rather than System.Drawing so formats like .webp, which GDI+
            # doesn't understand, work the same as everything else here).
            $psi.Arguments = "-hide_banner -nostdin -loglevel error -autorotate -i " + (Quote-Arg $videoPath) + " -map 0:v:0 -frames:v 1 -f image2pipe -vcodec png pipe:1"
        }
        else {
            if (-not $frameTimeline -or -not $frameTimeline.Ok -or
                -not $frameTimeline.Timestamps -or -not $frameTimeline.Times -or
                $targetFrame -lt 0 -or $targetFrame -ge $frameTimeline.Timestamps.Length -or
                $targetFrame -ge $frameTimeline.Times.Length) {
                return @{ Ok = $false; Err = "The exact frame timing map is unavailable for this preview frame."; Bytes = @() }
            }

            $targetPts = [int64]$frameTimeline.Timestamps[$targetFrame]
            $targetSeconds = [double]$frameTimeline.Times[$targetFrame]
            $coarse = [Math]::Max(0.0, $targetSeconds - 2.0)
            $coarseText = Format-FFmpegSeconds $coarse
            $ptsText = $targetPts.ToString([System.Globalization.CultureInfo]::InvariantCulture)
            $selectExpr = "select='eq(pts\,$ptsText)'"

            # SECURITY: -copyts is essential here. Input -ss is only a decode
            # accelerator; frame identity is decided solely by exact source PTS.
            $psi.Arguments = "-hide_banner -nostdin -loglevel error -copyts -ss $coarseText -autorotate -i " + (Quote-Arg $videoPath) + " -map 0:v:0 -vf " + (Quote-Arg $selectExpr) + " -frames:v 1 -f image2pipe -vcodec png pipe:1"
        }
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)

        # Read stdout (the PNG bytes) and stderr concurrently - reading them
        # one after another can deadlock if ffmpeg fills one pipe's OS buffer
        # while waiting for the other end to be drained.
        $stdoutMs = New-Object System.IO.MemoryStream
        $copyTask = $proc.StandardOutput.BaseStream.CopyToAsync($stdoutMs)
        $stderrText = $proc.StandardError.ReadToEnd()
        $copyTask.GetAwaiter().GetResult()
        $proc.WaitForExit()

        $bytes = $stdoutMs.ToArray()
        $stdoutMs.Dispose()

        return @{ Ok = ($proc.ExitCode -eq 0 -and $bytes.Length -gt 0); Err = $stderrText; Bytes = $bytes }
    }.GetNewClosure()

    $result = & $tryExtractFrame $currentFrame

    if (-not $result.Ok) {
        $status.Text = "Couldn't extract preview frame."
        [System.Windows.Forms.MessageBox]::Show(
            "FFmpeg couldn't extract the exact mapped preview frame.`r`n`r`n$(Get-SafeFFmpegError $result.Err $videoPath)",
            "Preview error",
            "OK",
            "Error"
        ) | Out-Null
        return
    }

    if ($previewImage) {
        $previewImage.Dispose()
        $script:previewImage = $null
    }
 
    $ms = New-Object System.IO.MemoryStream(,$result.Bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    $rotatedPreview = New-Object System.Drawing.Bitmap($img)
    $img.Dispose()
    $ms.Dispose()

    # Existing source -autorotate has already happened inside FFmpeg. Apply only
    # the additional per-session quarter-turn here, in memory, so frame identity
    # and the trusted PTS extraction path remain completely unchanged.
    switch ([int]$userRotation) {
        90  { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        180 { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        270 { $rotatedPreview.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
    }

    if ($rotatedPreview.Width -ne $videoWidth -or $rotatedPreview.Height -ne $videoHeight) {
        $rotatedPreview.Dispose()
        $status.Text = "Preview orientation mismatch."
        [System.Windows.Forms.MessageBox]::Show(
            "The rotated preview dimensions did not match the canonical working dimensions. No redaction geometry was changed.",
            "Rotation preview error",
            "OK",
            "Error"
        ) | Out-Null
        return
    }
    $script:previewImage = $rotatedPreview
 
    # Slice 3 keeps the bitmap out of PictureBox.Image. The PictureBox is now
    # only the viewport/canvas; its Paint handler draws $previewImage through
    # Get-ViewportTransform before drawing overlays. Slice 4 keeps the current
    # viewport state across frame changes and refreshes only the visible HUD.
    Update-ZoomHud
    Update-PreviewCursor
    $picture.Refresh()
    $script:loadedFrame = $currentFrame
    $picture.Invalidate()
 
    $status.Text = if ($userRotation -eq 0) { "Preview loaded." } else { "$videoWidth x $videoHeight   |   User rotation: $userRotation°" }
}
 
function Set-PlaybackIntervalForFrame([int]$frameIndex) {
    if ($isImageMode -or -not $frameTimeline) { return }
    $frameDuration = Get-FramePresentationDuration $frameIndex
    if ([double]::IsNaN($frameDuration) -or [double]::IsInfinity($frameDuration) -or $frameDuration -le 0.0) { return }
    $intervalMs = [Math]::Round($frameDuration * 1000.0)
    if ($intervalMs -lt 1) { $intervalMs = 1 }
    if ($intervalMs -gt [int]::MaxValue) { $intervalMs = [int]::MaxValue }
    $playTimer.Interval = [int]$intervalMs
}

function Step-Frame([int]$delta) {
    if (-not $videoPath -or $isImageMode -or $totalFrames -le 0) { return }
 
    $newFrame = [Math]::Max(0, [Math]::Min($currentFrame + $delta, $totalFrames - 1))
    if ($newFrame -eq $currentFrame) { return }

    $mappedTime = Get-FramePresentationTime $newFrame
    if ([double]::IsNaN($mappedTime) -or [double]::IsInfinity($mappedTime)) {
        Stop-Playback
        $status.Text = "Frame timing is unavailable; playback stopped."
        return
    }
 
    $script:currentFrame = $newFrame
    $script:previewSeconds = $mappedTime
    $seekBar.Invalidate()
    $lblPosValue.Text = SecToText $previewSeconds
    $lblFrameCount.Text = "Frame $($currentFrame + 1) / $totalFrames"

    # If playback is active, the next tick should wait for this frame's actual
    # presentation duration rather than a synthetic 1/fps interval.
    Set-PlaybackIntervalForFrame $currentFrame
    $previewTimer.Stop()
    Load-PreviewFrame
}
 
# S1b starts with deletion unavailable until a source is accepted.
Reset-SourceDeletionState

# ----------------------------
# Events
# ----------------------------
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
public sealed class TRTMediaOperation {
    readonly object gate=new object(); readonly List<Process> children=new List<Process>();
    public volatile bool Cancelled; public double Microseconds;
    public Process Start(ProcessStartInfo info) { lock(gate) { if(Cancelled) throw new OperationCanceledException(); var p=Process.Start(info); children.Add(p); return p; } }
    public void Cancel() { lock(gate) { Cancelled=true; foreach(var p in children) try { if(!p.HasExited) p.Kill(); } catch{} } }
    public void Dispose() { lock(gate) { foreach(var p in children) { try {if(!p.HasExited)p.Kill();}catch{} p.Dispose(); } children.Clear(); } }
}
'@
function Start-MediaWorker($kind,$arguments,$complete,$context) {
    if($script:MediaWorker){throw 'A media operation is already running.'}
    $owner=New-Object TRTMediaOperation
    $defs=New-Object Text.StringBuilder
    foreach($name in @('Quote-Arg','Get-SafeFFmpegError','Get-FrameTimingMap','Get-OutputInspection','Test-ExportSecurity','Get-VideoInfo')){
        $body=(Get-Command $name -CommandType Function).Definition
        # Instrument private worker copies only. All accepted checks stay intact.
        $body=$body.Replace('[System.Diagnostics.Process]::Start($psi)','$script:OperationOwner.Start($psi)').Replace('$copyTask.GetAwaiter().GetResult()','[void]$copyTask.GetAwaiter().GetResult()').Replace('[System.Windows.Forms.Application]::DoEvents()','')
        if($name -eq 'Get-VideoInfo'){$body=$body.Replace('$bytes = $ms.ToArray()','$bytes = $ms.ToArray(); $info.FirstFrameBytes=$bytes')}
        [void]$defs.AppendLine(('function '+$name+' {'+"`n"+$body+"`n"+'}'))
    }
    $work=@'
param($owner,$kind,$a)
$ErrorActionPreference='Stop';$script:OperationOwner=$owner
if($kind -eq 'Load'){ Get-VideoInfo $a.Mpeg $a.Probe $a.Path $a.Image; return }
$p=$owner.Start($a.Psi)
$errorTask=$p.StandardError.ReadToEndAsync()
while($null -ne ($line=$p.StandardOutput.ReadLine())){
    if($line -match '^out_time_us=(-?\d+)'){$owner.Microseconds=[double]$Matches[1]}
}
$p.WaitForExit();$mediaError=$errorTask.GetAwaiter().GetResult()
if($p.ExitCode -ne 0 -or -not [IO.File]::Exists($a.Path)){
    @{ExitCode=$p.ExitCode;Error=$mediaError;Validation=@{Ok=$false;Error='Encoding failed.'}};return
}
$validation=Test-ExportSecurity $a.Mpeg $a.Probe $a.Path $a.Image $a.Audio $a.Width $a.Height $a.Duration $a.Timeline
@{ExitCode=$p.ExitCode;Error=$mediaError;Validation=$validation}
'@
    $worker=[PowerShell]::Create()
    try{
        [void]$worker.AddScript($defs.ToString()).AddStatement().AddScript($work).AddArgument($owner).AddArgument($kind).AddArgument($arguments)
        $task=$worker.BeginInvoke()
        $timer=New-Object Windows.Forms.Timer;$timer.Interval=75
        $script:MediaWorker=@{Worker=$worker;Task=$task;Owner=$owner;Timer=$timer;Kind=$kind;Complete=$complete;Context=$context;Arguments=$arguments}
        $timer.Add_Tick({
            $op=$script:MediaWorker;if(-not $op){return}
            if(-not $op.Task.IsCompleted){
                if($op.Kind -eq 'Export' -and $op.Arguments.Duration -gt 0){
                    $pct=[Math]::Max(0,[Math]::Min(99,[int]($op.Owner.Microseconds/($op.Arguments.Duration*10000.0))))
                    $progress.Value=$pct;$status.Text="Exporting / validating... $pct%"
                }
                return
            }
            $op.Timer.Stop();$op.Timer.Dispose();$script:MediaWorker=$null
            $result=$null;$failure=$null
            try{
                $items=$op.Worker.EndInvoke($op.Task)
                if($op.Worker.Streams.Error.Count -or $items.Count -ne 1){throw 'The media worker did not complete safely.'}
                $result=$items[0].PSObject.BaseObject
            }catch{$failure=$_.Exception.GetBaseException().Message}
            finally{$op.Worker.Dispose();$op.Owner.Dispose()}
            & $op.Complete $result $failure $op.Owner.Cancelled $op.Context
        })
        $timer.Start()
    }catch{$worker.Dispose();$owner.Dispose();throw}
}
function Close-VideoLoadingNotice {
    if($script:LoadingNotice){$script:LoadingNotice.Dispose();$script:LoadingNotice=$null}
}
function Cancel-VideoLoading {
    if($script:MediaWorker -and $script:MediaWorker.Kind -eq 'Load'){
        $script:MediaWorker.Owner.Cancel()
        $script:LoadingCancel.Enabled=$false;$script:LoadingTitle.Text='Cancelling video loading...'
    }
}
function Show-ClipboardConfirmation {
    $dialog=New-Object Windows.Forms.Form
    $dialog.Text='Clipboard';$dialog.StartPosition='CenterParent';$dialog.FormBorderStyle='FixedDialog'
    $dialog.MaximizeBox=$false;$dialog.MinimizeBox=$false;$dialog.ShowInTaskbar=$false
    $dialog.BackColor=$form.BackColor;$dialog.ForeColor=$script:cTextCurrent
    $dialog.AutoScaleMode='Dpi';$dialog.ClientSize=[Drawing.Size]::new(360,116)
    $label=New-Object Windows.Forms.Label;$label.Text='Image Copied to Clipboard'
    $label.Font=New-UIFont 10.0 'Bold';$label.ForeColor=$script:cTextCurrent
    $label.BackColor=[Drawing.Color]::Transparent;$label.TextAlign='MiddleCenter';$label.SetBounds(14,15,332,34)
    $ok=New-Object Windows.Forms.Button;$ok.Text='OK';$ok.SetBounds(246,70,100,30)
    Style-FlatButton $ok $true
    $ok.BackColor=$script:cAccentCurrent;$ok.ForeColor=[Drawing.Color]::White
    $ok.FlatAppearance.BorderColor=$script:cAccentCurrent;$ok.DialogResult='OK'
    $dialog.Controls.AddRange([Windows.Forms.Control[]]@($label,$ok))
    $dialog.AcceptButton=$ok;$dialog.CancelButton=$ok
    try{[void]$dialog.ShowDialog($form)}finally{$dialog.Dispose()}
}
function Show-VideoLoadingNotice {
    $notice=New-Object Windows.Forms.Form
    $notice.Text='Loading Video';$notice.FormBorderStyle='FixedDialog';$notice.ControlBox=$false
    $notice.ShowInTaskbar=$false;$notice.StartPosition='CenterParent';$notice.ClientSize=[Drawing.Size]::new(520,164)
    $notice.BackColor=$form.BackColor;$notice.ForeColor=$script:cTextCurrent
    $title=New-Object Windows.Forms.Label;$title.Text='Loading Video... Please Wait';$title.Font=New-UIFont 12.0 'Bold';$title.SetBounds(18,15,485,30)
    $detail=New-Object Windows.Forms.Label;$detail.Text='This may take a while depending on video size and/or if opening from a network location';$detail.Font=New-UIFont 9.0;$detail.SetBounds(18,50,485,42)
    $bar=New-Object Windows.Forms.ProgressBar;$bar.Style='Marquee';$bar.SetBounds(18,101,370,20)
    $cancel=New-Object Windows.Forms.Button;$cancel.Text='Cancel';$cancel.SetBounds(401,98,100,30);Style-FlatButton $cancel $true
    # Use the same palette and rounded painter as TRT's ordinary buttons.
    $cancel.BackColor=$script:cAccentCurrent;$cancel.ForeColor=[Drawing.Color]::White
    $cancel.FlatAppearance.BorderColor=$script:cAccentCurrent
    $title.ForeColor=$script:cTextCurrent;$detail.ForeColor=$script:cMutedCurrent
    $title.BackColor=[Drawing.Color]::Transparent;$detail.BackColor=[Drawing.Color]::Transparent
    $cancel.Add_Click({Cancel-VideoLoading})
    $notice.Controls.AddRange([Windows.Forms.Control[]]@($title,$detail,$bar,$cancel))
    $script:LoadingNotice=$notice;$script:LoadingCancel=$cancel;$script:LoadingTitle=$title
    $notice.Show($form)
}
function Update-CopyButton {
    if(-not $btnCopyImage){return}
    $btnCopyImage.Visible=[bool]($videoPath -and $isImageMode)
    $btnCopyImage.Enabled=[bool]($btnCopyImage.Visible -and $btnExport.Enabled -and -not $script:ExportBusy)
    $ink=if($btnCopyImage.Enabled){[Drawing.Color]::White}else{[Drawing.Color]::Gray}
    $btnCopyImage.Image=Get-ThemedIconImage 'copy' $ink
    $btnCopyImage.BackColor=$btnExport.BackColor;$btnCopyImage.ForeColor=$btnExport.ForeColor
    $btnCopyImage.FlatAppearance.BorderColor=$btnExport.FlatAppearance.BorderColor
    $btnCopyImage.Cursor=$btnExport.Cursor;$btnCopyImage.Invalidate()
}

function Open-TRTMediaPath([string]$selectedPath) {
    if($script:MediaWorker -or $script:ExportBusy){return}
    $networkReason=Get-NetworkPathReason $selectedPath
    if($networkReason){
        if($script:ManagedPolicy -and $script:ManagedPolicy.BlockNetworkSource){Show-ManagedNetworkLocationBlock 'Source';return}
        if(-not (Show-NetworkLocationWarning 'Source')){return}
    }
    $ext=[IO.Path]::GetExtension($selectedPath).ToLowerInvariant()
    $newImageMode=$ext -in @('.jpg','.jpeg','.jpe','.png','.apng','.gif','.webp','.bmp','.tif','.tiff','.tga','.dds','.exr','.hdr','.dpx','.jp2','.j2k','.j2c','.jpc','.jls','.psd','.pcx','.qoi','.avif','.heic','.heif')
    if($newImageMode){
        # Still-image preflight remains the accepted synchronous short path.
                $body=(Get-Command Get-VideoInfo -CommandType Function).Definition
        $body=$body.Replace('$bytes = $ms.ToArray()','$bytes = $ms.ToArray(); $info.FirstFrameBytes=$bytes').Replace('$copyTask.GetAwaiter().GetResult()','[void]$copyTask.GetAwaiter().GetResult()')
        $info=& ([scriptblock]::Create($body)) $ffmpeg $ffprobe $selectedPath $true
        Complete-MediaLoad $info $null $false @{Path=$selectedPath;Image=$true};return
    }
    Stop-Playback;Set-ExportWindowBusy $true;$script:CaptureState.Busy=$true
    try{
        Show-VideoLoadingNotice
        Start-MediaWorker 'Load' @{Mpeg=$ffmpeg;Probe=$ffprobe;Path=$selectedPath;Image=$false} ${function:Complete-MediaLoad} @{Path=$selectedPath;Image=$false}
    }catch{
        Close-VideoLoadingNotice;Set-ExportWindowBusy $false;$script:CaptureState.Busy=$false
        Remove-UnusedCaptureFiles;throw
    }
}
function Complete-MediaLoad($info,$failure,$cancelled,$context) {
    $selectedPath=$context.Path;$newImageMode=$context.Image
    Close-VideoLoadingNotice
    if(-not $newImageMode){Set-ExportWindowBusy $false;$script:CaptureState.Busy=$false}
    try{
        if($cancelled){$status.Text='Video loading cancelled.';return}
        if($failure -or -not $info.IsSafe){
            $status.Text='File not opened.'
            $message=if($failure){$failure}else{$info.Error}
            [Windows.Forms.MessageBox]::Show($message,'Media safety check failed','OK','Error')|Out-Null;return
        }
    $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $selectedPath
    $script:isImageMode = $newImageMode
    # B1 reset boundary: every newly accepted media source starts with no
    # additional user rotation. The existing preflight dimensions already
    # represent source autorotation and are kept separately from UserRotation.
    $script:sourceDisplayWidth = [int]$info.Width
    $script:sourceDisplayHeight = [int]$info.Height
    $script:userRotation = 0
    Set-WorkingDimensionsForUserRotation
    $script:redactionEnhanced = $false
    $chkEnhanced.Checked = $false
    Update-StrengthSliderVisibility
    $script:sourceHasAudio = [bool]$info.HasAudio
    $script:frameTimeline = $info.FrameTimeline
    # Audio is an explicit per-source opt-in. Changing/opening media always
    # returns the control to its secure default rather than carrying consent
    # from a previously opened file.
    $chkAudio.Checked = $false
    $lblFile.Text = $script:videoPath

    if ($videoWidth -le 0 -or $videoHeight -le 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "I couldn't read that file's display dimensions safely.",
            "File error",
            "OK",
            "Error"
        ) | Out-Null
        $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $null
        Reset-SourceDeletionState
        return
    }

    if ($isImageMode) {
        $script:videoDuration = 0.0
        $script:fps = 1.0
        $script:totalFrames = 1
        $script:currentFrame = 0
        $script:previewSeconds = 0.0
        $script:loadedFrame = -1
        $seekBar.Enabled = $false
        $seekBar.Invalidate()

        $btnPrevFrame.Enabled = $false
        $btnNextFrame.Enabled = $false
        $btnPlayPause.Enabled = $false
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
        $lblPosValue.Text = "n/a"
        $lblFrameCount.Text = "Image"
        $status.Text = "$videoWidth x $videoHeight   |   Still image"
    }
    else {
        $script:fps = $info.Fps  # informational average only; never a navigation authority
        $script:totalFrames = [int]$info.FrameCount
        if (-not $frameTimeline -or -not $frameTimeline.Ok -or
            -not $frameTimeline.Times -or -not $frameTimeline.Durations -or
            $frameTimeline.Times.Length -ne $totalFrames -or
            $frameTimeline.Durations.Length -ne $totalFrames) {
            [System.Windows.Forms.MessageBox]::Show(
                "The video's validated frame timeline is unavailable or inconsistent.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $null
            Reset-SourceDeletionState
            return
        }
        $script:videoDuration = [double]$frameTimeline.Duration
        if ($videoDuration -le 0 -or $totalFrames -le 0) {
            [System.Windows.Forms.MessageBox]::Show(
                "The video's frame timing could not be established safely.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $null
            Reset-SourceDeletionState
            return
        }

        $script:currentFrame = 0
        $script:previewSeconds = Get-FramePresentationTime 0
        if ([double]::IsNaN($previewSeconds) -or [double]::IsInfinity($previewSeconds)) {
            [System.Windows.Forms.MessageBox]::Show(
                "The first frame does not have a usable presentation timestamp.",
                "Video error",
                "OK",
                "Error"
            ) | Out-Null
            $script:ImageCrop=$null;$script:CropDraft=$null;$script:CropGesture=$null
    $script:videoPath = $null
            Reset-SourceDeletionState
            return
        }
        Set-PlaybackIntervalForFrame 0
        $script:loadedFrame = -1
        $seekBar.Enabled = $true
        $seekBar.Invalidate()

        $btnPrevFrame.Enabled = $true
        $btnNextFrame.Enabled = $true
        $btnPlayPause.Enabled = $true
        $script:appToolTip.SetToolTip($btnPlayPause, "Play")
        Update-TransportButtonVisuals
        $lblPosValue.Text = SecToText $previewSeconds
        $lblFrameCount.Text = "Frame 1 / $totalFrames"
        $timingStatus = if ($info.IsVfr) { "VFR timing verified" } else { "CFR timing verified" }
        $status.Text = "$videoWidth x $videoHeight   |   Duration: $(SecToText $videoDuration)   |   $([Math]::Round($fps,3)) avg fps   |   $timingStatus"
    }

    # A successfully accepted new source is the zoom reset boundary. Slice 1
    # keeps the existing PictureBox rendering path unchanged, but establishes
    # the v2 viewport state ready for later zoom interaction slices.
    Reset-ViewportState

    # Every newly opened source returns presentation controls to the secure
    # default: Fill on, Outline off. Styling choices such as colour/width may
    # persist for convenience, but annotation-only state never carries across files.
    $script:fillEnabled = $true
    $script:outlineEnabled = $false
    $chkFill.Checked = $true
    $chkOutline.Checked = $false

    Initialize-SourceDeletionStateForSource
    Apply-ModeLabels
    Reset-RedactionState
    Update-RedactionButtons
    Update-TransportButtonVisuals
    $btnOpen.Text = "Change Video | Image"

    $stream=[IO.MemoryStream]::new([byte[]]$info.FirstFrameBytes)
    try{
        $decoded=[Drawing.Image]::FromStream($stream)
        try{$nextPreview=[Drawing.Bitmap]::new($decoded)}finally{$decoded.Dispose()}
    }finally{$stream.Dispose()}
    if($previewImage){$previewImage.Dispose()};$script:previewImage=$nextPreview
    $script:loadedFrame=0;Update-ZoomHud;Update-PreviewCursor;$picture.Invalidate()

    }finally{
        Remove-UnusedCaptureFiles;Update-RedactionButtons;Update-CopyButton;Update-PolishedLayout
        if($script:QuitAfterExport -or $script:CaptureState.QuitPending){$script:QuitAfterExport=$false;Quit-TRTFromTray}
    }
}

$btnOpen.Add_Click({
    Stop-Playback

    $openFilter = "Video or image|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d;*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|Video files|*.mp4;*.mov;*.m4v;*.avi;*.mkv;*.webm;*.wmv;*.asf;*.mpg;*.mpeg;*.mpe;*.vob;*.ts;*.mts;*.m2ts;*.m2t;*.flv;*.3gp;*.3g2;*.f4v;*.ogv;*.rm;*.rmvb;*.mxf;*.wtv;*.dv;*.mjpeg;*.mjpg;*.mlv;*.r3d|Image files|*.jpg;*.jpeg;*.jpe;*.png;*.apng;*.gif;*.webp;*.bmp;*.tif;*.tiff;*.tga;*.dds;*.exr;*.hdr;*.dpx;*.jp2;*.j2k;*.j2c;*.jpc;*.jls;*.psd;*.pcx;*.qoi;*.avif;*.heic;*.heif|All files|*.*"
    try {
        $selectedPath = [SecureFileDialogNativeV2]::ShowOpen($form.Handle, $openFilter, "Choose a video or image")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(("Windows could not open the secure file-selection dialog.`r`n`r`n" + $_.Exception.Message), "File dialog error", "OK", "Error") | Out-Null
        return
    }
    if ([string]::IsNullOrWhiteSpace($selectedPath)) { return }

    Open-TRTMediaPath $selectedPath
})
 
$previewTimer = New-Object System.Windows.Forms.Timer
$previewTimer.Interval = 350
$previewTimer.Add_Tick({
    $previewTimer.Stop()
    if ($videoPath) { Load-PreviewFrame }
})
 
# "Play" steps forward one frame at a time through the same ffmpeg-per-frame
# extraction used everywhere else in this app. That extraction involves
# spawning a process per frame, so this will not play at true source frame
# rate on most machines - it's a best-effort scrub, not a smooth video
# player. Real smooth playback would need a live decoded-frame pipe read on
# a background thread with cross-thread UI updates, which is a materially
# riskier design to get right in a script like this.
$playTimer = New-Object System.Windows.Forms.Timer
$playTimer.Interval = 40
$playTimer.Add_Tick({
    if (-not $videoPath -or $currentFrame -ge $totalFrames - 1) {
        Stop-Playback
        return
    }
    Step-Frame 1
})
 
$btnPlayPause.Add_Click({
    if (-not $videoPath) { return }
    if ($isPlaying) {
        Stop-Playback
    }
    else {
        if ($currentFrame -ge $totalFrames - 1) {
            $script:currentFrame = 0
            $script:previewSeconds = Get-FramePresentationTime 0
            $lblPosValue.Text = SecToText $previewSeconds
            $lblFrameCount.Text = "Frame 1 / $totalFrames"
            $seekBar.Invalidate()
        }
        Set-PlaybackIntervalForFrame $currentFrame
        $script:isPlaying = $true
        $script:appToolTip.SetToolTip($btnPlayPause, "Pause")
        Update-TransportButtonVisuals
        $playTimer.Start()
    }
})

function Invoke-UserQuarterTurn([int]$deltaDegrees) {
    if (-not $videoPath) { return }
    if ($deltaDegrees -ne 90 -and $deltaDegrees -ne -90) { return }

    # The buttons should already be disabled in this state, but re-check in the
    # handler as a stale-UI safety belt. Never discard or transform redactions.
    if (Test-HasRotationLockoutState) {
        Update-RotationButtons
        [System.Windows.Forms.MessageBox]::Show(
            "Rotation can only be changed before redactions are added. Clear/reset the current redaction work first.",
            "Rotation locked",
            "OK",
            "Information"
        ) | Out-Null
        return
    }

    Stop-Playback

    $nextRotation = (([int]$userRotation + $deltaDegrees) % 360 + 360) % 360

    # Rotate the already decoded in-memory preview by exactly the requested
    # quarter turn for immediate UI response. Subsequent frame loads apply the
    # complete UserRotation afresh to newly decoded source-autorotated pixels.
    if ($previewImage) {
        if ($deltaDegrees -eq 90) {
            $previewImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone)
        }
        else {
            $previewImage.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone)
        }
    }

    $script:userRotation = [int]$nextRotation
    Set-WorkingDimensionsForUserRotation

    if ($previewImage -and ($previewImage.Width -ne $videoWidth -or $previewImage.Height -ne $videoHeight)) {
        # This should be impossible for a quarter-turn. Fail closed by throwing
        # away the cache and re-decoding the current logical frame.
        $previewImage.Dispose()
        $script:previewImage = $null
        $script:loadedFrame = -1
    }

    Reset-ViewportState
    Update-ZoomHud
    Update-RotationButtons
    $picture.Invalidate()

    $status.Text = "$videoWidth x $videoHeight   |   User rotation: $userRotation°"
    if (-not $previewImage) { Load-PreviewFrame }
}

$btnRotateCCW.Add_Click({ Invoke-UserQuarterTurn -90 })
$btnPrevFrame.Add_Click({ Stop-Playback; Step-Frame -1 })
$btnNextFrame.Add_Click({ Stop-Playback; Step-Frame 1 })
$btnRotateCW.Add_Click({ Invoke-UserQuarterTurn 90 })
 
$form.Add_KeyDown({
    param($sender,$e)
    if($script:ExportBusy){return}
    if($isImageMode -and $toolMode -eq 'Crop' -and $e.KeyCode -eq [Windows.Forms.Keys]::Escape){$rbRectangle.Checked=$true;$e.Handled=$true;$e.SuppressKeyPress=$true;return}
    if ($script:floatingTextEditorVisible -and $floatingTextEditor -and $floatingTextEditor.ContainsFocus) { return }
    if (-not $videoPath) { return }

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space) {
        # Once the temporary override is active, swallow keyboard auto-repeat
        # even if the drag has moved the pointer outside the preview. Otherwise
        # a repeated Space could accidentally activate whichever button still
        # owns keyboard focus while the user is panning.
        if ($script:spacePanActive) {
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }

        # Optional power-user pan: only borrow Space when a drawing tool is
        # active and the pointer is actually over the preview. Do not steal an
        # already-running Rectangle/Oval drag or shape-move gesture. Suppressing
        # the key press also prevents Space from accidentally activating a
        # focused toolbar/button control while it is serving as the pan modifier.
        if (-not $script:zoomToolActive -and -not $eyedropperActive -and $previewImage -and
            -not $dragging -and -not $movingShape -and -not $script:annotationDraftMoving -and -not $script:lineDrawing -and -not $script:textDrawing -and
            -not $script:annotationCommittedMoving -and -not $script:annotationCommittedTextResizing -and -not $script:annotationCommittedResizing -and -not $script:annotationCommittedVertexEditing -and
            -not $script:redactionCommittedMoving -and -not $script:redactionCommittedResizing -and -not $script:redactionCommittedPolygonEditing -and
            (Test-CursorOverPreview)) {
            Reset-ZoomPanGesture
            $script:spacePanActive = $true
            Update-PreviewCursor
            $e.Handled = $true
            $e.SuppressKeyPress = $true
            return
        }
    }

    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Left) {
        Stop-Playback
        Step-Frame -1
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Right) {
        Stop-Playback
        Step-Frame 1
        $e.Handled = $true
    }
    elseif ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        if ($script:pendingAnnotation) {
            [void](Cancel-VideoAnnotationRange)
            $e.Handled = $true
        }
        elseif (($toolMode -eq "Polygon" -and ($polygonActive -or $polygonPoints.Count -gt 0)) -or
            ($toolMode -eq "Polyline" -and ($script:polylineActive -or $script:polylineDraftActive -or $script:polylinePoints.Count -gt 0)) -or
            ($toolMode -eq "Line" -and ($script:lineDrawing -or $script:lineDraftActive)) -or
            ($toolMode -eq "Text" -and ($script:textDrawing -or $script:textDraftActive))) {
            Reset-DrawingState
            Update-SelectionFields $null
            Update-RedactionButtons
            $e.Handled = $true
        }
    }
})

$form.Add_KeyUp({
    param($sender,$e)
    if($script:ExportBusy){return}
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Space -and $script:spacePanActive) {
        Stop-SpacePanMode
        $e.Handled = $true
        $e.SuppressKeyPress = $true
    }
})

# If the application loses focus while Space is down, Windows may never deliver
# the matching KeyUp to this form. Clear the temporary override so the preview
# cannot get stuck in hand/pan mode when the user Alt-Tabs away and returns.
$form.Add_Deactivate({
    Stop-SpacePanMode
    Stop-MiddlePanMode
    [void](Stop-RightPanMode)
})
 
$rbCrop.Add_CheckedChanged({
    if($rbCrop.Checked){
        $rbText.Checked=$false;$rbLine.Checked=$false;$rbPolyline.Checked=$false
        Reset-ZoomPanGesture;$script:zoomToolActive=$false
        if($script:floatingTextEditorVisible){Close-FloatingTextEditor $false}
        Set-ToolMode 'Crop';Update-CropControls;$picture.Invalidate()
    }else{$script:CropDraft=$null;$script:CropGesture=$null;$picture.Capture=$false;$picture.Invalidate()}
})
$toolbar.Add_MouseMove({param($sender,$e)
    if(-not $rbCrop.Enabled -and $rbCrop.Bounds.Contains($e.Location)){$appToolTip.Show($(if($videoPath -and -not $isImageMode){'Video Crop not supported'}else{'Crop Image Tool'}),$toolbar,$e.X+15,$e.Y+15,2000)}
})

function Update-ToolHintText {
    if (-not $lblToolHint) { return }
    switch ($script:toolMode) {
        "Text"     { $lblToolHint.Text = if ($isImageMode) { "Text Box: drag a box, type in the floating editor, then reposition/resize and add." } else { "Text Box: drag a box, type in the floating editor, then use Begin Annotation." } }
        "Line"     { $lblToolHint.Text = if ($isImageMode) { "Line: drag start to end, reposition if needed, then choose Create Annotation." } else { "Line: drag start to end, reposition if needed, then use Begin Annotation." } }
        "Polyline" { $lblToolHint.Text = if ($isImageMode) { "Polyline: hold and draw, reposition the result if needed, then choose Create Annotation." } else { "Polyline: hold and draw, reposition the result if needed, then use Begin Annotation." } }
        "Polygon"  { $lblToolHint.Text = "Freeform: click points, then click the yellow start point to close." }
        "Oval"     { $lblToolHint.Text = "Oval: drag to select. Hold Shift for a circle." }
        default      { $lblToolHint.Text = "Rectangle: drag to select. Hold Shift for a square." }
    }
}

function Set-ToolMode([string]$mode) {
    if ($script:toolMode -eq $mode) {
        Set-OutlineJoinChoices
        Update-OutlineControlsAvailability
        Update-ToolHintText
        Update-InspectorSectionLayout
        return
    }
    $script:toolMode = $mode
    if ($lvAnnotations -and $lvAnnotations.SelectedItems.Count -gt 0) { $lvAnnotations.SelectedItems[0].Selected = $false }
    if ($lvRedactions -and $lvRedactions.SelectedItems.Count -gt 0) { $lvRedactions.SelectedItems[0].Selected = $false }
    $script:selectedAnnotationIndex = -1
    $script:selectedRedactionIndex = -1
    Reset-DrawingState
    Update-SelectionFields $null
    Sync-DraftAppearanceDefaultsToControls
    Set-OutlineJoinChoices
    Update-OutlineControlsAvailability
    Update-ToolHintText
    Update-InspectorSectionLayout
    Update-RedactionButtons
}
$rbRectangle.Add_CheckedChanged({
    if ($rbRectangle.Checked) {
        $rbText.Checked = $false; $rbLine.Checked = $false; $rbPolyline.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Rectangle"
        Update-PreviewCursor
    }
})
$rbOval.Add_CheckedChanged({
    if ($rbOval.Checked) {
        $rbText.Checked = $false; $rbLine.Checked = $false; $rbPolyline.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Oval"
        Update-PreviewCursor
    }
})
$rbFreeform.Add_CheckedChanged({
    if ($rbFreeform.Checked) {
        $rbText.Checked = $false; $rbLine.Checked = $false; $rbPolyline.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Polygon"
        Update-PreviewCursor
    }
})
$rbText.Add_CheckedChanged({
    if ($rbText.Checked) {
        $rbCrop.Checked=$false;$rbRectangle.Checked = $false; $rbOval.Checked = $false; $rbFreeform.Checked = $false; $rbZoom.Checked = $false
        $rbLine.Checked = $false; $rbPolyline.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Text"
        Update-PreviewCursor
    }
})
$rbLine.Add_CheckedChanged({
    if ($rbLine.Checked) {
        $rbCrop.Checked=$false;$rbRectangle.Checked = $false; $rbOval.Checked = $false; $rbFreeform.Checked = $false; $rbZoom.Checked = $false
        $rbText.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Line"
        Update-PreviewCursor
    }
})
$rbPolyline.Add_CheckedChanged({
    if ($rbPolyline.Checked) {
        $rbCrop.Checked=$false;$rbRectangle.Checked = $false; $rbOval.Checked = $false; $rbFreeform.Checked = $false; $rbZoom.Checked = $false
        $rbText.Checked = $false
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Set-ToolMode "Polyline"
        Update-PreviewCursor
    }
})
$rbZoom.Add_CheckedChanged({
    if ($rbZoom.Checked) {
        $rbText.Checked = $false; $rbLine.Checked = $false; $rbPolyline.Checked = $false
        # Zoom is a VIEW tool, not a new redaction shape. Preserve the last
        # drawing tool and any draft geometry while Zoom is temporarily active.
        $script:zoomToolActive = $true
        Update-PreviewCursor
    }
    elseif ($script:zoomToolActive) {
        Reset-ZoomPanGesture
        $script:zoomToolActive = $false
        Update-PreviewCursor
    }
})

$btnZoomFit.Add_Click({ Set-ZoomFit })
$btnZoomIn.Add_Click({ Step-ZoomAtViewPoint 1 (Get-ViewportCenterPoint) })
$btnZoomOut.Add_Click({ Step-ZoomAtViewPoint -1 (Get-ViewportCenterPoint) })

$picture.Add_MouseEnter({
    # v2.1: wheel zoom is always available while the pointer is over the loaded
    # preview, regardless of which drawing/view tool is selected. MouseWheel is
    # delivered to the focused WinForms control, so focus the preview on entry.
    # Form.KeyPreview keeps the existing keyboard shortcuts available.
    if ($previewImage) {
        [void]$picture.Focus()
    }

    if ($script:zoomToolActive -or $script:spacePanActive -or $script:middlePanActive -or $script:rightPanActive) {
        Update-PreviewCursor
    }
})
 
$picture.Add_MouseDown({
    param($sender,$e)
    if($isImageMode -and $script:ImageCrop -and $toolMode -ne 'Crop' -and -not (MediaRect-To-ViewRect $script:ImageCrop).Contains([Drawing.PointF]::new($e.X,$e.Y))){return}
    if($isImageMode -and $toolMode -eq 'Crop'){Start-CropGesture $e;;return}
    if (-not $previewImage) { return }
    if ($script:suppressFloatingOutsidePreviewClick) { $script:suppressFloatingOutsidePreviewClick = $false; return }
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $script:floatingTextEditorVisible) {
        Close-FloatingTextEditor $false
    }

    # v2.1 always-on middle-button pan takes priority over drawing/edit gestures
    # without changing the selected tool. The pointer only needs to be over the
    # displayed media when the gesture begins; capture then allows the drag to
    # continue naturally beyond the original hit area.
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Middle) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        Reset-ZoomPanGesture
        $script:middlePanActive = $true
        $script:zoomPanCandidate = $true
        $script:zoomPanning = $false
        $script:zoomPanStartPoint = $viewPt
        $script:zoomPanStartOffsetX = [double]$panOffsetX
        $script:zoomPanStartOffsetY = [double]$panOffsetY
        $picture.Capture = $true
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }

    # B1-r3: right-button DRAG pans from any tool, making panning practical on
    # laptops/trackpads that have no clickable middle button. A plain right-click
    # is deliberately deferred to MouseUp so existing click semantics survive:
    # Zoom tool -> zoom out; Freeform -> cancel the in-progress path.
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right -and
        -not $dragging -and -not $movingShape -and -not $script:resizingShape -and
        -not $script:editingPolygonVertex -and -not $script:lineDrawing -and -not $script:textDrawing -and
        -not $script:textDraftResizing -and -not $script:annotationCommittedMoving -and -not $script:annotationCommittedTextResizing -and -not $script:annotationCommittedResizing -and -not $script:annotationCommittedVertexEditing -and
        -not $script:redactionCommittedMoving -and -not $script:redactionCommittedResizing -and -not $script:redactionCommittedPolygonEditing) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        Reset-ZoomPanGesture
        $script:rightPanActive = $true
        $script:zoomPanCandidate = $true
        $script:zoomPanning = $false
        $script:zoomPanStartPoint = $viewPt
        $script:zoomPanStartOffsetX = [double]$panOffsetX
        $script:zoomPanStartOffsetY = [double]$panOffsetY
        $picture.Capture = $true
        $picture.Cursor = [System.Windows.Forms.Cursors]::Hand
        return
    }

    # Eyedropper takes priority over normal left/right drawing input while armed. In Slice 3
    # it uses the same inverse viewport transform as draft geometry.
    if ($eyedropperActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            $imgRect = Get-MediaViewRect
            $viewPtF = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            $pt = New-Object System.Drawing.Point($e.X,$e.Y)
            if ($imgRect -and $imgRect.Contains($viewPtF) -and $previewImage) {
                $vp = DisplayPoint-To-VideoPoint $pt
                if ($vp) {
                    $sampled = $previewImage.GetPixel($vp.X, $vp.Y)
                    Set-ActiveRedactionColor $sampled
                }
            }
        }
        $script:eyedropperActive = $false
        Update-PreviewCursor
        Set-RedactionButtonColor $btnEyedropper "grey"
        return
    }

    if ($script:zoomToolActive -or $script:spacePanActive) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $mediaRect = Get-MediaViewRect
        if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
            # Do NOT zoom on MouseDown. A left press may become a pan gesture;
            # MouseUp performs click-to-zoom only for the real Zoom tool. When
            # Space is the temporary override, a no-drag click is intentionally
            # a no-op so the underlying drawing tool is never invoked by accident.
            $script:zoomPanCandidate = $true
            $script:zoomPanning = $false
            $script:zoomPanStartPoint = $viewPt
            $script:zoomPanStartOffsetX = [double]$panOffsetX
            $script:zoomPanStartOffsetY = [double]$panOffsetY
            $picture.Capture = $true
            Update-PreviewCursor
        }
        return
    }

    if ($pendingRedaction -or $script:pendingAnnotation) { return }

    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }

    Stop-Playback

    # From this point on, mouse input is converted to canonical MEDIA space
    # immediately. No draft shape stores PictureBox/view coordinates anymore.
    $viewRect = Get-MediaViewRect
    if (-not $viewRect) { return }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)

    # D4c: committed still-image redaction editing is list-selected and takes
    # priority over starting a new draft. Handle/vertex hit zones are checked
    # before media containment because edge handles intentionally straddle it.
    if ($script:selectedRedactionIndex -ge 0) {
        $selectedRedaction = Get-SelectedCommittedRedaction
        if ($selectedRedaction) {
            if ($selectedRedaction.Shape -eq "Polygon") {
                $redactionVertex = Get-FreeformVertexHandleAtViewPoint $viewPt $selectedRedaction.Points
                if ($redactionVertex -ge 0) {
                    $script:redactionCommittedPolygonEditing=$true
                    $script:redactionCommittedPolygonVertexIndex=[int]$redactionVertex
                    $picture.Capture=$true
                    $picture.Cursor=Get-FreeformVertexCursor
                    $lblPending.Text="Redaction vertex editing — release to keep the new shape."
                    $picture.Invalidate()
                    return
                }
            }
            else {
                $selectedRedactionRect=Get-RedactionMediaBounds $selectedRedaction
                $redactionHandle = if ($selectedRedaction.Shape -eq "Oval") {
                    Get-OvalResizeHandleAtViewPoint $viewPt $selectedRedactionRect
                } else {
                    Get-RectangleResizeHandleAtViewPoint $viewPt $selectedRedactionRect
                }
                if ($redactionHandle -ne "None") {
                    $script:redactionCommittedResizing=$true
                    $script:redactionCommittedResizeHandle=[string]$redactionHandle
                    $script:redactionCommittedResizeOrigRect=$selectedRedactionRect
                    $picture.Capture=$true
                    $picture.Cursor=if ($selectedRedaction.Shape -eq "Oval") { Get-OvalResizeCursor $redactionHandle } else { Get-RectangleResizeCursor $redactionHandle }
                    $lblPending.Text="Redaction resizing — release to keep the new geometry."
                    $picture.Invalidate()
                    return
                }
            }
            if ($viewRect.Contains($viewPt)) {
                $selectedRedactionMediaPoint=ViewPoint-To-MediaPoint $viewPt $true
                if ($selectedRedactionMediaPoint -and (Test-CommittedRedactionHit $selectedRedaction $selectedRedactionMediaPoint)) {
                    if (Begin-CommittedRedactionMove $selectedRedaction $selectedRedactionMediaPoint) {
                        $lblPending.Text="Redaction moving — release to keep the new position."
                        $picture.Invalidate()
                        return
                    }
                }
            }
        }
        # D4c-r2: clicking away from a selected committed redaction is a
        # dismissal-only gesture. Consume this click so Freeform (and every
        # other active tool) cannot also start a new draft from the same input.
        # The next click returns the canvas to normal active-tool behaviour.
        $script:selectedRedactionIndex=-1
        if ($lvRedactions.SelectedItems.Count -gt 0) { $lvRedactions.SelectedItems[0].Selected=$false }
        $picture.Invalidate()
        return
    }

    # D4b: committed annotation editing is list-selected and takes priority over
    # starting a new draft. Text handles are tested before media containment so
    # edge handles remain practical, matching the pre-commit Text behaviour.
    if ($script:selectedAnnotationIndex -ge 0) {
        if (-not $isImageMode) { Stop-Playback }
        $selectedAnnotation = Get-SelectedCommittedAnnotation

        # D4d: precise point/vertex handles take precedence over whole-object movement.
        if ($selectedAnnotation -and ($selectedAnnotation.Kind -eq "Line" -or $selectedAnnotation.Kind -eq "Polyline" -or ($selectedAnnotation.Kind -eq "ShapeOutline" -and $selectedAnnotation.Shape -eq "Polygon"))) {
            $annotationVertex = Get-CommittedAnnotationVertexHandleAtViewPoint $selectedAnnotation $viewPt
            if ($annotationVertex -ge 0) {
                $script:annotationCommittedVertexEditing = $true
                $script:annotationCommittedVertexIndex = [int]$annotationVertex
                $picture.Capture = $true
                $picture.Cursor = Get-FreeformVertexCursor
                $lblAppearanceStatus.Text = if ($selectedAnnotation.Kind -eq "Line") { "Line endpoint editing — release to keep the new geometry." } else { "Annotation vertex editing — release to keep the new geometry." }
                $picture.Invalidate()
                return
            }
        }

        # Outline-only Rectangle/Oval annotations now expose the same proven
        # media-space resize handles as their corresponding redaction shapes.
        if ($selectedAnnotation -and $selectedAnnotation.Kind -eq "ShapeOutline" -and $selectedAnnotation.Shape -ne "Polygon") {
            $selectedOutlineRect = Get-AnnotationMediaBounds $selectedAnnotation
            $annotationResizeHandle = if ($selectedAnnotation.Shape -eq "Oval") {
                Get-OvalResizeHandleAtViewPoint $viewPt $selectedOutlineRect
            } else {
                Get-RectangleResizeHandleAtViewPoint $viewPt $selectedOutlineRect
            }
            if ($annotationResizeHandle -ne "None") {
                $script:annotationCommittedResizing = $true
                $script:annotationCommittedResizeHandle = [string]$annotationResizeHandle
                $script:annotationCommittedResizeOrigRect = $selectedOutlineRect
                $picture.Capture = $true
                $picture.Cursor = if ($selectedAnnotation.Shape -eq "Oval") { Get-OvalResizeCursor $annotationResizeHandle } else { Get-RectangleResizeCursor $annotationResizeHandle }
                $lblAppearanceStatus.Text = "Annotation resizing — release to keep the new geometry."
                $picture.Invalidate()
                return
            }
        }

        if ($selectedAnnotation -and $selectedAnnotation.Kind -eq "Text") {
            $selectedTextRect = Get-AnnotationMediaBounds $selectedAnnotation
            $committedTextHandle = Get-RectangleResizeHandleAtViewPoint $viewPt $selectedTextRect
            if ($committedTextHandle -ne "None") {
                $script:annotationCommittedTextResizing = $true
                $script:annotationCommittedTextResizeHandle = [string]$committedTextHandle
                $script:annotationCommittedTextResizeOrigRect = $selectedTextRect
                $picture.Capture = $true
                $picture.Cursor = Get-RectangleResizeCursor $committedTextHandle
                $lblAppearanceStatus.Text = "Text annotation resizing."
                $picture.Invalidate()
                return
            }
        }
        if ($viewRect.Contains($viewPt)) {
            $selectedMediaPoint = ViewPoint-To-MediaPoint $viewPt $true
            if ($selectedMediaPoint -and (Test-CommittedAnnotationHit $selectedAnnotation $viewPt)) {
                if (Begin-CommittedAnnotationMove $selectedAnnotation $selectedMediaPoint) {
                    $lblAppearanceStatus.Text = "Annotation moving — release to keep the new position."
                    $picture.Invalidate()
                    return
                }
            }
        }
        # D4c-r2: match committed-redaction dismissal semantics. The first
        # outside click only clears committed annotation selection; the next
        # click may begin whatever drawing tool is currently active.
        $script:selectedAnnotationIndex = -1
        if ($lvAnnotations.SelectedItems.Count -gt 0) { $lvAnnotations.SelectedItems[0].Selected = $false }
        Sync-DraftAppearanceDefaultsToControls
        Update-InspectorSectionLayout
        $picture.Invalidate()
        return
    }

    # D4a-r2: Text Box resize handles use the already-proven Rectangle handle
    # geometry/hit zones, but keep completely separate gesture state from
    # security redactions. Handle testing happens before media containment so
    # a handle centred on an image edge remains practical to grab.
    if ($toolMode -eq "Text" -and $script:textDraftActive -and -not $script:textDrawing) {
        $textResizeHandle = Get-RectangleResizeHandleAtViewPoint $viewPt $script:textDraftRect
        if ($textResizeHandle -ne "None") {
            $script:textDraftResizing = $true
            $script:textDraftResizeHandle = [string]$textResizeHandle
            $script:textDraftResizeOrigRect = New-Object System.Drawing.RectangleF(
                [single]$script:textDraftRect.X,[single]$script:textDraftRect.Y,
                [single]$script:textDraftRect.Width,[single]$script:textDraftRect.Height)
            $picture.Capture = $true
            $picture.Cursor = Get-RectangleResizeCursor $textResizeHandle
            Update-SelectionFields $null "Text Box resizing. Release to keep the new size, then add the text."
            $picture.Invalidate()
            return
        }
    }

    # Resize Slice 1/2: handle hit-testing deliberately happens before the
    # normal media-rectangle containment check. Handles centred on a media edge
    # are partly outside the image by design and must remain easy to grab.
    $resizeHandleCandidate = [bool](
        ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
    if ($resizeHandleCandidate -and
        $selection.Width -gt 0.01 -and $selection.Height -gt 0.01 -and -not $dragging) {
        $hitHandle = if ($toolMode -eq "Oval") {
            Get-OvalResizeHandleAtViewPoint $viewPt $selection
        } else {
            Get-RectangleResizeHandleAtViewPoint $viewPt $selection
        }
        if ($hitHandle -ne "None") {
            $script:resizingShape = $true
            $script:resizeHandle = $hitHandle
            $script:resizeShapeKind = [string]$toolMode
            $script:resizeOrigSelection = New-Object System.Drawing.RectangleF(
                [single]$selection.X,[single]$selection.Y,[single]$selection.Width,[single]$selection.Height)
            $picture.Capture = $true
            $picture.Cursor = if ($toolMode -eq "Oval") {
                Get-OvalResizeCursor $hitHandle
            } else {
                Get-RectangleResizeCursor $hitHandle
            }
            $picture.Invalidate()
            return
        }
    }

    # Resize Slice 3: closed Freeform vertex handles take precedence over the
    # polygon interior move gesture. Hit-testing is VIEW-space so the handle
    # remains a comfortable fixed screen size at every zoom level.
    if ($script:resizeSlice3Enabled -and $toolMode -eq "Polygon" -and
        -not $polygonActive -and $polygonPoints.Count -ge 3) {
        $vertexIndex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
        if ($vertexIndex -ge 0) {
            $script:editingPolygonVertex = $true
            $script:polygonVertexIndex = [int]$vertexIndex
            $picture.Capture = $true
            $picture.Cursor = Get-FreeformVertexCursor
            $picture.Invalidate()
            return
        }
    }

    # Resize Slice 3 r2: a first click outside a closed Freeform is a
    # dismissal-only gesture. This also applies to preview letterbox space.
    # Vertex handles were already given priority above, so an edge handle that
    # straddles the media boundary is still editable rather than dismissed.
    if ($script:resizeSlice3Enabled -and $toolMode -eq "Polygon" -and
        -not $polygonActive -and $polygonPoints.Count -ge 3 -and
        -not $viewRect.Contains($viewPt)) {
        Clear-ClosedFreeformDraftForOutsideClick
        return
    }

    if (-not $viewRect.Contains($viewPt)) { return }

    $mediaPt = ViewPoint-To-MediaPoint $viewPt $true
    if (-not $mediaPt) { return }

    if ($toolMode -eq "Text") {
        Stop-Playback
        if ($script:textDraftActive) {
            if ($script:textDraftRect.Contains($mediaPt)) {
                Begin-AnnotationDraftMove "Text" $mediaPt
                Update-SelectionFields $null "Text Box moving. Release to keep the new position, then add the text."
                $picture.Invalidate()
            } else {
                $lblTextStatus.Text = "Text Box ready. Double-click it to reopen the floating editor, or use Create Annotation / Begin Annotation."
                if ($picture.CanFocus) { $picture.Focus() }
            }
            return
        }
        $script:textDrawing = $true
        $script:textDragStart = $mediaPt
        $script:textDraftRect = New-Object System.Drawing.RectangleF([single]$mediaPt.X,[single]$mediaPt.Y,[single]0.01,[single]0.01)
        $picture.Capture = $true
        $lblTextStatus.Text = "Drag to size the text box."
        Update-RotationButtons
        $picture.Invalidate()
        return
    }

    if ($toolMode -eq "Line") {
        Stop-Playback
        if ($script:lineDraftActive) {
            if (Test-LineDraftHit $viewPt) {
                Begin-AnnotationDraftMove "Line" $mediaPt
                Update-SelectionFields $null "Line moving. Release to keep the new position, then choose Create Annotation."
                $picture.Invalidate()
            } else {
                Update-SelectionFields $null "Line ready. Drag the existing line to reposition it, or choose Create Annotation / Cancel."
            }
            return
        }
        $script:lineDrawing = $true
        $script:lineStart = $mediaPt
        $script:lineEnd = $mediaPt
        $picture.Capture = $true
        Update-SelectionFields $null "Line: drag to the end point; hold Shift to constrain angle."
        Update-RotationButtons
        $picture.Invalidate()
        return
    }

    if ($toolMode -eq "Polyline") {
        Stop-Playback
        if ($script:polylineDraftActive) {
            if (Test-PolylineDraftHit $viewPt) {
                Begin-AnnotationDraftMove "Polyline" $mediaPt
                Update-SelectionFields $null "Polyline moving. Release to keep the new position, then choose Create Annotation."
                $picture.Invalidate()
            } else {
                Update-SelectionFields $null "Polyline ready. Drag the existing path to reposition it, or choose Create Annotation / Cancel."
            }
            return
        }
        $script:polylineActive = $true
        $script:polylinePoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        [void]$script:polylinePoints.Add($mediaPt)
        $script:polylineMousePos = $mediaPt
        $script:polylineGestureAxis = "None"
        $script:polylineGestureLastRaw = $mediaPt
        $picture.Capture = $true
        Update-SelectionFields $null "Polyline: keep the left mouse button held and draw; release to finish."
        Update-RotationButtons
        $picture.Invalidate()
        return
    }

    if ($toolMode -eq "Polygon") {
        if (-not $polygonActive -and $polygonPoints.Count -ge 3) {
            if (Test-PointInPolygon $mediaPt $polygonPoints) {
                # Clicked inside the closed-but-uncommitted path: move the whole
                # canonical media-space shape instead of starting a new one.
                $script:movingShape = $true
                $picture.Capture = $true
                $script:moveStart = $mediaPt
                $script:moveOrigPolygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
                foreach ($pt in $polygonPoints) {
                    [void]$script:moveOrigPolygonPoints.Add((New-Object System.Drawing.PointF([single]$pt.X,[single]$pt.Y)))
                }
                $picture.Invalidate()
                return
            }

            if ($script:resizeSlice3Enabled) {
                # r2 behavior: the first outside click clears the closed draft
                # and is consumed. Do NOT reuse this same click as point #1 of
                # the next polygon; a second click starts the next Freeform.
                Clear-ClosedFreeformDraftForOutsideClick
                return
            }
        }
        if (-not $polygonActive) {
            $script:polygonActive = $true
            $script:polygonPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
            $script:polygonPoints.Add($mediaPt)
            $script:polygonMousePos = $mediaPt
            Update-SelectionFields $null "Selection: freeform started (1 point). Click to add points; click the yellow start point to close (need at least 3)."
        }
        else {
            # Shift snapping also happens in MEDIA space. Because the viewport
            # scale is uniform, media-space 45-degree snapping is visually 45
            # degrees on screen too.
            $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
            $mediaPt = Clamp-MediaPoint (Get-AngleSnappedPoint $lastPolyPt $mediaPt $constrainAngle)

            # Closing remains a screen-pixel interaction: the yellow start
            # marker is 8 px across, so preserve the familiar 10 px close
            # tolerance even though the stored vertices are media-space.
            $candidateView = MediaPoint-To-ViewPoint $mediaPt
            $startView = MediaPoint-To-ViewPoint $polygonPoints[0]
            $distToStart = [double]::PositiveInfinity
            if ($candidateView -and $startView) {
                $dxs = [double]$candidateView.X - [double]$startView.X
                $dys = [double]$candidateView.Y - [double]$startView.Y
                $distToStart = [Math]::Sqrt(($dxs * $dxs) + ($dys * $dys))
            }

            if ($polygonPoints.Count -ge 3 -and $distToStart -le 10.0) {
                $script:polygonActive = $false
                Update-SelectionFields $null "Selection: freeform closed ($($polygonPoints.Count) points)."
            }
            else {
                $script:polygonPoints.Add($mediaPt)
                Update-SelectionFields $null "Selection: freeform, $($polygonPoints.Count) points (click the yellow start point to close)."
            }
        }
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }

    if ($selection.Width -gt 0.01 -and $selection.Height -gt 0.01 -and $selection.Contains($mediaPt)) {
        # Clicked inside the existing uncommitted Rectangle/Oval selection:
        # move the canonical media-space shape instead of creating another.
        # Oval deliberately keeps the existing bounding-box hit behaviour.
        $script:movingShape = $true
        $picture.Capture = $true
        $script:moveStart = $mediaPt
        $script:moveOrigSelection = New-Object System.Drawing.RectangleF(
            [single]$selection.X,[single]$selection.Y,[single]$selection.Width,[single]$selection.Height)
        $picture.Invalidate()
        return
    }

    # Rectangle / Oval: the very first point is canonical MEDIA space. The
    # resize branch also tracks a small screen-pixel threshold so click-only
    # gestures cannot leave coincident handles behind.
    if (($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) {
        $script:resizeDraftDrawStartView = $viewPt
        $script:resizeDraftDrawMoved = $false
    }
    $script:dragging = $true
    $picture.Capture = $true
    $script:dragStart = $mediaPt
    $script:selection = New-Object System.Drawing.RectangleF(
        [single]$dragStart.X,[single]$dragStart.Y,[single]0.01,[single]0.01)
    Update-RotationButtons
    $picture.Invalidate()
})

# D5c-r2: double-clicking the current Text draft or a selected committed Text
# annotation reopens the floating editor without changing geometry/timing.
$picture.Add_MouseDoubleClick({
    param($sender,$e)
    if (-not $previewImage -or $e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
    if ($toolMode -eq "Text" -and $script:textDraftActive) {
        $mediaPt = ViewPoint-To-MediaPoint $viewPt $false
        if ($mediaPt -and $script:textDraftRect.Contains($mediaPt)) {
            [void](Show-FloatingTextEditor "Draft")
            return
        }
    }
    if (($toolMode -eq "Line" -and (Test-LineDraftHit $viewPt)) -or ($toolMode -eq "Polyline" -and (Test-PolylineDraftHit $viewPt))) {
        [void](Show-FloatingTextEditor "Draft")
        return
    }
    $mediaPt=ViewPoint-To-MediaPoint $viewPt $false
    if($mediaPt -and -not $pendingRedaction -and -not $script:pendingAnnotation){
        for($idx=$redactions.Count-1;$idx -ge 0;$idx--){
            $r=$redactions[$idx]
            if(-not $isImageMode -and -not (Test-FrameInRange $currentFrame $r.BufferedStartFrame $r.BufferedEndFrame)){continue}
            if(Test-CommittedRedactionHit $r $mediaPt){Show-RedactionEditor $idx;return}
        }
    }
    $a = Get-SelectedAppearanceAnnotation
    if ($a -and $a.Kind -in @("Text","Line","Polyline") -and (Test-CommittedAnnotationHit $a $viewPt)) {
        [void](Show-FloatingTextEditor "Committed")
        return
    }
    # Reopen a visible committed annotation directly from the canvas, even
    # when it was not already selected in the Annotations list.
    for ($idx = $annotations.Count - 1; $idx -ge 0; $idx--) {
        $candidate = $annotations[$idx]
        if ($candidate.Kind -notin @("Text","Line","Polyline")) { continue }
        if (-not $isImageMode -and -not (Test-AnnotationFrameActive $candidate $currentFrame)) { continue }
        if (Test-CommittedAnnotationHit $candidate $viewPt) {
            Reset-DrawingState
            if ($idx -lt $lvAnnotations.Items.Count) { $lvAnnotations.Items[$idx].Selected = $true }
            $script:selectedAnnotationIndex = $idx
            Sync-SelectedAnnotationAppearanceToControls
            Update-InspectorSectionLayout
            [void](Show-FloatingTextEditor "Committed")
            return
        }
    }
})

$picture.Add_MouseMove({
    param($sender,$e)
    if($isImageMode -and $toolMode -eq 'Crop'){Update-CropGesture $e;;return}

    if ($script:zoomToolActive -or $script:spacePanActive -or $script:middlePanActive -or $script:rightPanActive) {
        if ($script:zoomPanCandidate) {
            $dxView = [double]$e.X - [double]$script:zoomPanStartPoint.X
            $dyView = [double]$e.Y - [double]$script:zoomPanStartPoint.Y

            if (-not $script:zoomPanning) {
                $distance = [Math]::Sqrt(($dxView * $dxView) + ($dyView * $dyView))
                if ($distance -ge [double]$zoomPanDragThreshold) {
                    $script:zoomPanning = $true
                }
            }

            if ($script:zoomPanning -and $zoomMode -eq "Manual") {
                $script:panOffsetX = [double]$script:zoomPanStartOffsetX + $dxView
                $script:panOffsetY = [double]$script:zoomPanStartOffsetY + $dyView
                Clamp-ViewportPan ([Math]::Abs([double]$script:zoomPanStartOffsetX)) ([Math]::Abs([double]$script:zoomPanStartOffsetY))
                $picture.Refresh()
            }
            Update-PreviewCursor
            return
        }

        Update-PreviewCursor
        return
    }

    if ($script:pendingAnnotation) {
        Update-PreviewCursor
        return
    }

    if ($script:redactionCommittedPolygonEditing) {
        $r=Get-SelectedCommittedRedaction
        $viewPt=New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt=ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds=Get-DraftMediaBounds
        if ($r -and $r.Shape -eq "Polygon" -and $rawPt -and $mediaBounds -and $script:redactionCommittedPolygonVertexIndex -ge 0) {
            $r.Points=Get-FreeformVertexEditResult $r.Points $script:redactionCommittedPolygonVertexIndex $rawPt $mediaBounds
            Update-CommittedPolygonBounds $r
            $picture.Cursor=Get-FreeformVertexCursor
            $picture.Invalidate()
        }
        return
    }

    if ($script:redactionCommittedResizing) {
        $r=Get-SelectedCommittedRedaction
        $viewPt=New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt=ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds=Get-DraftMediaBounds
        if ($r -and $rawPt -and $mediaBounds -and $script:redactionCommittedResizeOrigRect) {
            $constrain=[bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $rr=if ($r.Shape -eq "Oval") {
                Get-OvalResizeResult $script:redactionCommittedResizeOrigRect $script:redactionCommittedResizeHandle $rawPt $constrain $mediaBounds
            } else {
                Get-RectangleResizeResult $script:redactionCommittedResizeOrigRect $script:redactionCommittedResizeHandle $rawPt $constrain $mediaBounds
            }
            $r.X=[double]$rr.X; $r.Y=[double]$rr.Y; $r.W=[double]$rr.Width; $r.H=[double]$rr.Height
            $picture.Cursor=if ($r.Shape -eq "Oval") { Get-OvalResizeCursor $script:redactionCommittedResizeHandle } else { Get-RectangleResizeCursor $script:redactionCommittedResizeHandle }
            $picture.Invalidate()
        }
        return
    }

    if ($script:redactionCommittedMoving) {
        $viewPt=New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt=ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt) {
            Update-CommittedRedactionMove $rawPt
            $picture.Cursor=[System.Windows.Forms.Cursors]::SizeAll
            $picture.Invalidate()
        }
        return
    }

    if ($script:annotationCommittedVertexEditing) {
        $a = Get-SelectedCommittedAnnotation
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if ($a -and $rawPt -and $mediaBounds -and $script:annotationCommittedVertexIndex -ge 0) {
            Update-CommittedAnnotationVertex $a $script:annotationCommittedVertexIndex $rawPt $mediaBounds
            $picture.Cursor = Get-FreeformVertexCursor
            $lblAppearanceStatus.Text = if ($a.Kind -eq "Line") { "Line endpoint editing." } else { "Annotation vertex editing." }
            $picture.Invalidate()
        }
        return
    }

    if ($script:annotationCommittedResizing) {
        $a = Get-SelectedCommittedAnnotation
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if ($a -and $a.Kind -eq "ShapeOutline" -and $rawPt -and $mediaBounds -and $script:annotationCommittedResizeOrigRect) {
            $constrain = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $r = if ($a.Shape -eq "Oval") {
                Get-OvalResizeResult $script:annotationCommittedResizeOrigRect $script:annotationCommittedResizeHandle $rawPt $constrain $mediaBounds
            } else {
                Get-RectangleResizeResult $script:annotationCommittedResizeOrigRect $script:annotationCommittedResizeHandle $rawPt $constrain $mediaBounds
            }
            $a.X=[double]$r.X; $a.Y=[double]$r.Y; $a.W=[double]$r.Width; $a.H=[double]$r.Height
            $picture.Cursor = if ($a.Shape -eq "Oval") { Get-OvalResizeCursor $script:annotationCommittedResizeHandle } else { Get-RectangleResizeCursor $script:annotationCommittedResizeHandle }
            $lblAppearanceStatus.Text = "Annotation resizing."
            $picture.Invalidate()
        }
        return
    }

    if ($script:annotationCommittedTextResizing) {
        $a = Get-SelectedCommittedAnnotation
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if ($a -and $a.Kind -eq "Text" -and $rawPt -and $mediaBounds -and $script:annotationCommittedTextResizeOrigRect) {
            $r = Get-RectangleResizeResult $script:annotationCommittedTextResizeOrigRect $script:annotationCommittedTextResizeHandle $rawPt $false $mediaBounds
            $a.X=[double]$r.X; $a.Y=[double]$r.Y; $a.W=[double]$r.Width; $a.H=[double]$r.Height
            $picture.Cursor = Get-RectangleResizeCursor $script:annotationCommittedTextResizeHandle
            $lblAppearanceStatus.Text = "Text annotation resizing."
            $picture.Invalidate()
        }
        return
    }

    if ($script:annotationCommittedMoving) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt) {
            Update-CommittedAnnotationMove $rawPt
            $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
            $picture.Invalidate()
        }
        return
    }

    if ($script:textDraftResizing -and $toolMode -eq "Text") {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if ($rawPt -and $mediaBounds -and $script:textDraftResizeOrigRect) {
            # Text boxes are freely resizable; Shift is intentionally not used
            # for a square constraint because text layout has no 1:1 semantic.
            $script:textDraftRect = Get-RectangleResizeResult `
                $script:textDraftResizeOrigRect `
                $script:textDraftResizeHandle `
                $rawPt `
                $false `
                $mediaBounds
            $picture.Cursor = Get-RectangleResizeCursor $script:textDraftResizeHandle
            Update-SelectionFields $null "Text Box resizing."
            $picture.Invalidate()
        }
        return
    }

    if ($script:annotationDraftMoving) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt) {
            Update-AnnotationDraftMove $rawPt
            $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
            $picture.Invalidate()
        }
        return
    }

    if ($script:textDrawing -and $toolMode -eq "Text" -and $script:textDragStart) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt) {
            $x = [Math]::Min([double]$script:textDragStart.X, [double]$rawPt.X)
            $y = [Math]::Min([double]$script:textDragStart.Y, [double]$rawPt.Y)
            $w = [Math]::Max(0.01, [Math]::Abs([double]$rawPt.X - [double]$script:textDragStart.X))
            $h = [Math]::Max(0.01, [Math]::Abs([double]$rawPt.Y - [double]$script:textDragStart.Y))
            $script:textDraftRect = New-Object System.Drawing.RectangleF([single]$x,[single]$y,[single]$w,[single]$h)
            $picture.Invalidate()
        }
        return
    }

    if ($script:lineDrawing -and $toolMode -eq "Line") {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt -and $script:lineStart) {
            $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $script:lineEnd = Clamp-MediaPoint (Get-AngleSnappedPoint $script:lineStart $rawPt $constrainAngle)
            $picture.Invalidate()
        }
        return
    }

    if ($script:polylineActive -and $toolMode -eq "Polyline") {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt -and $script:polylinePoints.Count -gt 0) {
            Update-PolylineGesture $rawPt
            $picture.Invalidate()
        }
        return
    }

    if ($script:resizingShape) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if (-not $rawPt -or -not $mediaBounds -or -not $script:resizeOrigSelection) { return }

        $constrainOneToOne = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
        if ($script:resizeShapeKind -eq "Oval") {
            $script:selection = Get-OvalResizeResult $script:resizeOrigSelection $script:resizeHandle $rawPt $constrainOneToOne $mediaBounds
            $picture.Cursor = Get-OvalResizeCursor $script:resizeHandle
        }
        else {
            $script:selection = Get-RectangleResizeResult $script:resizeOrigSelection $script:resizeHandle $rawPt $constrainOneToOne $mediaBounds
            $picture.Cursor = Get-RectangleResizeCursor $script:resizeHandle
        }
        Update-SelectionFields (Selection-To-VideoRect) "Selection resizing."
        $picture.Invalidate()
        return
    }

    if ($script:editingPolygonVertex) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $mediaBounds = Get-DraftMediaBounds
        if (-not $rawPt -or -not $mediaBounds -or $script:polygonVertexIndex -lt 0) { return }

        $script:polygonPoints = Get-FreeformVertexEditResult $polygonPoints $script:polygonVertexIndex $rawPt $mediaBounds
        $picture.Cursor = Get-FreeformVertexCursor
        Update-SelectionFields $null "Selection: freeform vertex editing."
        $picture.Invalidate()
        return
    }

    if ($movingShape) {
        $mediaBounds = Get-DraftMediaBounds
        if (-not $mediaBounds) { return }

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if (-not $rawPt) { return }

        $dx = [double]$rawPt.X - [double]$moveStart.X
        $dy = [double]$rawPt.Y - [double]$moveStart.Y

        if ($toolMode -eq "Polygon") {
            $origBounds = Get-PointsBoundingRect $moveOrigPolygonPoints
            $clampedD = Get-ClampedTranslation $origBounds $dx $dy $mediaBounds
            $newPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
            foreach ($origPt in $moveOrigPolygonPoints) {
                [void]$newPoints.Add((New-Object System.Drawing.PointF(
                    [single]([double]$origPt.X + [double]$clampedD.Dx),
                    [single]([double]$origPt.Y + [double]$clampedD.Dy))))
            }
            $script:polygonPoints = $newPoints
        }
        else {
            $clampedD = Get-ClampedTranslation $moveOrigSelection $dx $dy $mediaBounds
            $script:selection = New-Object System.Drawing.RectangleF(
                [single]([double]$moveOrigSelection.X + [double]$clampedD.Dx),
                [single]([double]$moveOrigSelection.Y + [double]$clampedD.Dy),
                [single]$moveOrigSelection.Width,
                [single]$moveOrigSelection.Height)
        }
        $picture.Invalidate()
        return
    }

    if (-not $dragging -and -not $pendingRedaction) {
        $hoverViewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        if ($script:selectedRedactionIndex -ge 0) {
            $selectedHoverRedaction=Get-SelectedCommittedRedaction
            if ($selectedHoverRedaction) {
                if ($selectedHoverRedaction.Shape -eq "Polygon") {
                    $selectedRedactionVertex=Get-FreeformVertexHandleAtViewPoint $hoverViewPt $selectedHoverRedaction.Points
                    if ($selectedRedactionVertex -ge 0) {
                        $picture.Cursor=Get-FreeformVertexCursor
                        return
                    }
                }
                else {
                    $selectedHoverRedactionRect=Get-RedactionMediaBounds $selectedHoverRedaction
                    $selectedRedactionHandle=if ($selectedHoverRedaction.Shape -eq "Oval") {
                        Get-OvalResizeHandleAtViewPoint $hoverViewPt $selectedHoverRedactionRect
                    } else {
                        Get-RectangleResizeHandleAtViewPoint $hoverViewPt $selectedHoverRedactionRect
                    }
                    if ($selectedRedactionHandle -ne "None") {
                        $picture.Cursor=if ($selectedHoverRedaction.Shape -eq "Oval") { Get-OvalResizeCursor $selectedRedactionHandle } else { Get-RectangleResizeCursor $selectedRedactionHandle }
                        return
                    }
                }
                $selectedHoverRedactionMedia=ViewPoint-To-MediaPoint $hoverViewPt $false
                if ($selectedHoverRedactionMedia -and (Test-CommittedRedactionHit $selectedHoverRedaction $selectedHoverRedactionMedia)) {
                    $picture.Cursor=[System.Windows.Forms.Cursors]::SizeAll
                    return
                }
            }
        }
        if ($script:selectedAnnotationIndex -ge 0) {
            $selectedHoverAnnotation = Get-SelectedCommittedAnnotation
            if ($selectedHoverAnnotation -and ($selectedHoverAnnotation.Kind -eq "Line" -or $selectedHoverAnnotation.Kind -eq "Polyline" -or ($selectedHoverAnnotation.Kind -eq "ShapeOutline" -and $selectedHoverAnnotation.Shape -eq "Polygon"))) {
                $selectedHoverVertex = Get-CommittedAnnotationVertexHandleAtViewPoint $selectedHoverAnnotation $hoverViewPt
                if ($selectedHoverVertex -ge 0) {
                    $picture.Cursor = Get-FreeformVertexCursor
                    return
                }
            }
            if ($selectedHoverAnnotation -and $selectedHoverAnnotation.Kind -eq "ShapeOutline" -and $selectedHoverAnnotation.Shape -ne "Polygon") {
                $selectedHoverRect = Get-AnnotationMediaBounds $selectedHoverAnnotation
                $selectedHoverHandle = if ($selectedHoverAnnotation.Shape -eq "Oval") {
                    Get-OvalResizeHandleAtViewPoint $hoverViewPt $selectedHoverRect
                } else {
                    Get-RectangleResizeHandleAtViewPoint $hoverViewPt $selectedHoverRect
                }
                if ($selectedHoverHandle -ne "None") {
                    $picture.Cursor = if ($selectedHoverAnnotation.Shape -eq "Oval") { Get-OvalResizeCursor $selectedHoverHandle } else { Get-RectangleResizeCursor $selectedHoverHandle }
                    return
                }
            }
            if ($selectedHoverAnnotation -and $selectedHoverAnnotation.Kind -eq "Text") {
                $selectedHoverRect = Get-AnnotationMediaBounds $selectedHoverAnnotation
                $selectedHoverHandle = Get-RectangleResizeHandleAtViewPoint $hoverViewPt $selectedHoverRect
                if ($selectedHoverHandle -ne "None") {
                    $picture.Cursor = Get-RectangleResizeCursor $selectedHoverHandle
                    return
                }
            }
            if ($selectedHoverAnnotation -and (Test-CommittedAnnotationHit $selectedHoverAnnotation $hoverViewPt)) {
                $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
                return
            }
        }
        if ($toolMode -eq "Text" -and $script:textDraftActive) {
            $hoverTextHandle = Get-RectangleResizeHandleAtViewPoint $hoverViewPt $script:textDraftRect
            if ($hoverTextHandle -ne "None") {
                $picture.Cursor = Get-RectangleResizeCursor $hoverTextHandle
                return
            }
            $hoverMediaPt = ViewPoint-To-MediaPoint $hoverViewPt $false
            $picture.Cursor = if ($hoverMediaPt -and $script:textDraftRect.Contains($hoverMediaPt)) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
            return
        }
        if ($toolMode -eq "Line" -and $script:lineDraftActive) {
            $picture.Cursor = if (Test-LineDraftHit $hoverViewPt) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
            return
        }
        if ($toolMode -eq "Polyline" -and $script:polylineDraftActive) {
            $picture.Cursor = if (Test-PolylineDraftHit $hoverViewPt) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
            return
        }
    }

    if ($toolMode -eq "Polygon") {
        if ($polygonActive) {
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            $rawPt = ViewPoint-To-MediaPoint $viewPt $true
            if (-not $rawPt) { return }

            if ($polygonPoints.Count -gt 0) {
                $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
                $lastPolyPt = $polygonPoints[$polygonPoints.Count - 1]
                $rawPt = Clamp-MediaPoint (Get-AngleSnappedPoint $lastPolyPt $rawPt $constrainAngle)
            }
            $script:polygonMousePos = $rawPt
            $picture.Invalidate()
        }
        elseif (-not $pendingRedaction -and $polygonPoints.Count -ge 3) {
            # Slice 3 vertex handles take precedence over whole-polygon hover.
            # Because their hit area may straddle the media edge, test them
            # before enforcing media-rectangle containment.
            $viewRect = Get-MediaViewRect
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
            if ($script:resizeSlice3Enabled) {
                $hoverVertex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
                if ($hoverVertex -ge 0) {
                    $picture.Cursor = Get-FreeformVertexCursor
                    return
                }
            }
            # Idle interior hit-testing remains media-space. Outside the
            # displayed media, keep the normal cursor rather than clamping.
            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and (Test-PointInPolygon $hoverPt $polygonPoints)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        return
    }

    if (-not $dragging) {
        if (-not $pendingRedaction -and $selection.Width -gt 0.01 -and $selection.Height -gt 0.01) {
            $viewRect = Get-MediaViewRect
            $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)

            # Resize handles take precedence over whole-shape movement. Their
            # hover zone may extend a few pixels outside the displayed media.
            $resizeHoverCandidate = [bool](
                ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
                ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
            if ($resizeHoverCandidate) {
                $hoverHandle = if ($toolMode -eq "Oval") {
                    Get-OvalResizeHandleAtViewPoint $viewPt $selection
                } else {
                    Get-RectangleResizeHandleAtViewPoint $viewPt $selection
                }
                if ($hoverHandle -ne "None") {
                    $picture.Cursor = if ($toolMode -eq "Oval") {
                        Get-OvalResizeCursor $hoverHandle
                    } else {
                        Get-RectangleResizeCursor $hoverHandle
                    }
                    return
                }
            }

            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and $selection.Contains($hoverPt)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        return
    }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
    if ((($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
         ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) -and
        -not $script:resizeDraftDrawMoved -and $script:resizeDraftDrawStartView) {
        if (Test-RectangleDraftDragThreshold $script:resizeDraftDrawStartView $viewPt) {
            $script:resizeDraftDrawMoved = $true
        }
    }
    $p = ViewPoint-To-MediaPoint $viewPt $true
    if (-not $p) { return }

    # Shift constrains Rectangle to a square / Oval to a circle. This now
    # happens in MEDIA pixels, which is also the correct canonical geometry.
    $constrain = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
    $delta = Get-ConstrainedDelta ([double]$p.X - [double]$dragStart.X) ([double]$p.Y - [double]$dragStart.Y) $constrain

    $x = [Math]::Min([double]$dragStart.X, ([double]$dragStart.X + [double]$delta.Dx))
    $y = [Math]::Min([double]$dragStart.Y, ([double]$dragStart.Y + [double]$delta.Dy))
    $w = [Math]::Max(0.01, [Math]::Abs([double]$delta.Dx))
    $h = [Math]::Max(0.01, [Math]::Abs([double]$delta.Dy))

    $script:selection = New-Object System.Drawing.RectangleF(
        [single]$x,[single]$y,[single]$w,[single]$h)
    $picture.Invalidate()
})

$picture.Add_MouseWheel({
    param($sender,$e)

    # v2.1 always-on pointer-centred wheel zoom. Do not change scale in the
    # middle of an active geometry drag/edit or pan gesture; between gestures,
    # wheel zoom remains available with Rectangle/Oval/Freeform/Zoom selected.
    if (-not $previewImage -or $e.Delta -eq 0 -or $script:zoomPanCandidate -or
        $dragging -or $movingShape -or $script:resizingShape -or $script:editingPolygonVertex -or
        $script:lineDrawing -or $script:textDrawing -or $script:textDraftResizing -or
        $script:annotationCommittedMoving -or $script:annotationCommittedTextResizing -or $script:annotationCommittedResizing -or $script:annotationCommittedVertexEditing -or
        $script:redactionCommittedMoving -or $script:redactionCommittedResizing -or $script:redactionCommittedPolygonEditing) { return }

    $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
    $mediaRect = Get-MediaViewRect
    if (-not $mediaRect -or -not $mediaRect.Contains($viewPt)) { return }

    Step-ZoomAtViewPoint $(if ($e.Delta -gt 0) { 1 } else { -1 }) $viewPt
})

$picture.Add_MouseUp({
    param($sender,$e)
    if($isImageMode -and $toolMode -eq 'Crop'){Update-CropGesture $e;$script:CropGesture=$null;$picture.Capture=$false;return}

    if ($script:rightPanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $clickPoint = New-Object System.Drawing.PointF(
                [single]$script:zoomPanStartPoint.X,
                [single]$script:zoomPanStartPoint.Y)
            $wasPanning = [bool](Stop-RightPanMode)

            if (-not $wasPanning) {
                if ($eyedropperActive) {
                    # Preserve the old behaviour where a non-left click simply
                    # dismisses an armed eyedropper without sampling a pixel.
                    $script:eyedropperActive = $false
                    Update-PreviewCursor
                    Set-RedactionButtonColor $btnEyedropper "grey"
                }
                elseif ($script:zoomToolActive) {
                    Step-ZoomAtViewPoint -1 $clickPoint
                }
                elseif (-not $script:pendingAnnotation -and (($toolMode -eq "Polygon" -and ($polygonActive -or $polygonPoints.Count -gt 0)) -or
                        ($toolMode -eq "Polyline" -and ($script:polylineActive -or $script:polylineDraftActive -or $script:polylinePoints.Count -gt 0)) -or
                        ($toolMode -eq "Line" -and ($script:lineDrawing -or $script:lineDraftActive)) -or
                        ($toolMode -eq "Text" -and ($script:textDrawing -or $script:textDraftActive)))) {
                    # Preserve simple right-click as a cancel gesture for an uncommitted draft.
                    Stop-Playback
                    Reset-DrawingState
                    Update-SelectionFields $null
                    Update-RedactionButtons
                }
            }
        }
        return
    }

    if ($script:middlePanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Middle) {
            Stop-MiddlePanMode
        }
        return
    }

    if ($script:pendingAnnotation -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { return }

    if ($script:redactionCommittedPolygonEditing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $r=Get-SelectedCommittedRedaction
        if ($r) { Normalize-CommittedRedactionGeometry $r }
        $script:redactionCommittedPolygonEditing=$false
        $script:redactionCommittedPolygonVertexIndex=-1
        $picture.Capture=$false
        $lblPending.Text="Redaction shape updated."
        Refresh-RedactionList
        $picture.Cursor=[System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:redactionCommittedResizing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $r=Get-SelectedCommittedRedaction
        if ($r) { Normalize-CommittedRedactionGeometry $r }
        $script:redactionCommittedResizing=$false
        $script:redactionCommittedResizeHandle="None"
        $script:redactionCommittedResizeOrigRect=$null
        $picture.Capture=$false
        $lblPending.Text="Redaction size updated."
        Refresh-RedactionList
        $picture.Cursor=[System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:redactionCommittedMoving -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Stop-CommittedRedactionMove
        $lblPending.Text="Redaction position updated."
        Refresh-RedactionList
        $picture.Cursor=[System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:annotationCommittedVertexEditing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:annotationCommittedVertexEditing = $false
        $script:annotationCommittedVertexIndex = -1
        $picture.Capture = $false
        $lblAppearanceStatus.Text = "Annotation geometry updated."
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:annotationCommittedResizing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:annotationCommittedResizing = $false
        $script:annotationCommittedResizeHandle = "None"
        $script:annotationCommittedResizeOrigRect = $null
        $picture.Capture = $false
        $lblAppearanceStatus.Text = "Annotation size updated."
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:annotationCommittedTextResizing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:annotationCommittedTextResizing = $false
        $picture.Capture = $false
        $script:annotationCommittedTextResizeOrigRect = $null
        $script:annotationCommittedTextResizeHandle = "None"
        $lblAppearanceStatus.Text = "Text annotation resized — drag inside it to reposition if needed."
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:annotationCommittedMoving -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        Stop-CommittedAnnotationMove
        $lblAppearanceStatus.Text = "Annotation position updated."
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }

    if ($script:textDraftResizing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:textDraftResizing = $false
        $picture.Capture = $false
        $script:textDraftResizeOrigRect = $null
        Update-SelectionFields $null "Text Box resized. Type/edit the text, then choose Create Annotation."
        Update-RedactionButtons

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $hoverTextHandle = Get-RectangleResizeHandleAtViewPoint $viewPt $script:textDraftRect
        if ($hoverTextHandle -ne "None") {
            $picture.Cursor = Get-RectangleResizeCursor $hoverTextHandle
        } else {
            $hoverMediaPt = ViewPoint-To-MediaPoint $viewPt $false
            $picture.Cursor = if ($hoverMediaPt -and $script:textDraftRect.Contains($hoverMediaPt)) { [System.Windows.Forms.Cursors]::SizeAll } else { [System.Windows.Forms.Cursors]::Default }
        }
        $script:textDraftResizeHandle = "None"
        $picture.Invalidate()
        return
    }

    if ($script:annotationDraftMoving -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $kind = [string]$script:annotationDraftMoveKind
        Stop-AnnotationDraftMove
        $picture.Cursor = [System.Windows.Forms.Cursors]::SizeAll
        if ($kind -eq "Text") {
            Update-SelectionFields $null "Text Box position adjusted. Type/edit the text, then choose Create Annotation."
        } elseif ($kind -eq "Line") {
            Update-SelectionFields $null "Line position adjusted. Choose Create Annotation when ready."
        } elseif ($kind -eq "Polyline") {
            Update-SelectionFields $null "Polyline position adjusted. Choose Create Annotation when ready."
        }
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }

    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $toolMode -eq "Text" -and $script:textDrawing) {
        $picture.Capture = $false
        $script:textDrawing = $false
        if ($script:textDraftRect.Width -ge 2.0 -and $script:textDraftRect.Height -ge 2.0) {
            $script:textDraftActive = $true
            $lblTextStatus.Text = "Type in the floating editor; the annotation updates live. Ctrl+Enter closes; Create Annotation commits."
            $txtAnnotationText.Enabled = $true
            Update-RedactionButtons
            [void](Show-FloatingTextEditor "Draft")
        }
        else {
            $script:textDraftActive = $false
            $script:textDraftRect = New-Object System.Drawing.RectangleF(0,0,0,0)
        }
        Update-OutlineControlsAvailability
        Update-RotationButtons
        $picture.Invalidate()
        return
    }

    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $toolMode -eq "Polyline" -and $script:polylineActive) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        $picture.Capture = $false
        [void](Finish-PolylineGesture $rawPt)
        $picture.Invalidate()
        return
    }

    if ($script:zoomToolActive -or $script:spacePanActive) {
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left -and $script:zoomPanCandidate) {
            $wasPanning = [bool]$script:zoomPanning
            $clickPoint = New-Object System.Drawing.PointF(
                [single]$script:zoomPanStartPoint.X,
                [single]$script:zoomPanStartPoint.Y)

            $script:zoomPanCandidate = $false
            $script:zoomPanning = $false
            $picture.Capture = $false
            Update-PreviewCursor

            if (-not $wasPanning -and $script:zoomToolActive) {
                Step-ZoomAtViewPoint 1 $clickPoint
            }
            elseif ($wasPanning) {
                Clamp-ViewportPan ([Math]::Abs([double]$script:zoomPanStartOffsetX)) ([Math]::Abs([double]$script:zoomPanStartOffsetY))
                $picture.Refresh()
            }
        }
        return
    }

    if ($toolMode -eq "Line" -and $script:lineDrawing -and $e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $rawPt = ViewPoint-To-MediaPoint $viewPt $true
        if ($rawPt -and $script:lineStart) {
            $constrainAngle = [bool]([System.Windows.Forms.Control]::ModifierKeys -band [System.Windows.Forms.Keys]::Shift)
            $script:lineEnd = Clamp-MediaPoint (Get-AngleSnappedPoint $script:lineStart $rawPt $constrainAngle)
        }
        $picture.Capture = $false
        $script:lineDrawing = $false
        $dx = if ($script:lineStart -and $script:lineEnd) { [double]$script:lineEnd.X - [double]$script:lineStart.X } else { 0.0 }
        $dy = if ($script:lineStart -and $script:lineEnd) { [double]$script:lineEnd.Y - [double]$script:lineStart.Y } else { 0.0 }
        if ($script:lineStart -and $script:lineEnd -and [Math]::Sqrt(($dx*$dx)+($dy*$dy)) -ge 1.0) {
            $script:lineDraftActive = $true
            Update-SelectionFields $null "Line ready. Create Annotation locks it in."
            [void](Show-FloatingTextEditor "Draft")
        } else {
            Reset-DrawingState
            Update-SelectionFields $null
        }
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }

    if ($script:editingPolygonVertex) {
        $script:editingPolygonVertex = $false
        $picture.Capture = $false
        $script:polygonVertexIndex = -1
        Update-SelectionFields $null "Selection: freeform vertex moved."
        Update-RedactionButtons

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $hoverVertex = Get-FreeformVertexHandleAtViewPoint $viewPt $polygonPoints
        if ($hoverVertex -ge 0) {
            $picture.Cursor = Get-FreeformVertexCursor
        }
        else {
            $viewRect = Get-MediaViewRect
            if ($viewRect -and $viewRect.Contains($viewPt)) {
                $hoverPt = ViewPoint-To-MediaPoint $viewPt $true
                $picture.Cursor = if ($hoverPt -and (Test-PointInPolygon $hoverPt $polygonPoints)) {
                    [System.Windows.Forms.Cursors]::SizeAll
                } else {
                    [System.Windows.Forms.Cursors]::Default
                }
            }
            else {
                $picture.Cursor = [System.Windows.Forms.Cursors]::Default
            }
        }
        $picture.Invalidate()
        return
    }

    if ($script:resizingShape) {
        $resizeKind = [string]$script:resizeShapeKind
        $script:resizingShape = $false
        $picture.Capture = $false
        $script:resizeOrigSelection = $null
        Update-SelectionFields (Selection-To-VideoRect) "Selection resized."
        Update-RedactionButtons

        $viewPt = New-Object System.Drawing.PointF([single]$e.X,[single]$e.Y)
        $hoverHandle = if ($resizeKind -eq "Oval") {
            Get-OvalResizeHandleAtViewPoint $viewPt $selection
        } else {
            Get-RectangleResizeHandleAtViewPoint $viewPt $selection
        }
        if ($hoverHandle -ne "None") {
            $picture.Cursor = if ($resizeKind -eq "Oval") {
                Get-OvalResizeCursor $hoverHandle
            } else {
                Get-RectangleResizeCursor $hoverHandle
            }
        } else {
            $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        }
        $script:resizeHandle = "None"
        $script:resizeShapeKind = "None"
        $picture.Invalidate()
        return
    }

    if ($movingShape) {
        $script:movingShape = $false
        $picture.Capture = $false
        $script:moveOrigSelection = $null
        $script:moveOrigPolygonPoints = $null
        Update-SelectionFields (Get-CurrentShapeVideoData) "Selection moved."
        Update-RedactionButtons
        $picture.Invalidate()
        return
    }
    if ($toolMode -eq "Polygon") { return }
    if (-not $dragging) { return }

    $resizeTrackedShape = [bool](
        ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval"))
    $clickOnlyResizeShape = [bool]($resizeTrackedShape -and -not $script:resizeDraftDrawMoved)

    $script:dragging = $false
    $picture.Capture = $false

    if ($resizeTrackedShape) {
        $script:resizeDraftDrawStartView = $null
        $script:resizeDraftDrawMoved = $false
    }

    if ($clickOnlyResizeShape) {
        # A click is not a redaction. Remove the seed geometry entirely so
        # coincident resize handles cannot appear as one stray anchor point.
        $script:selection = New-Object System.Drawing.RectangleF(0,0,0,0)
        Update-SelectionFields $null
        Update-RedactionButtons
        $picture.Cursor = [System.Windows.Forms.Cursors]::Default
        $picture.Invalidate()
        return
    }
 
    $vr = Selection-To-VideoRect
    Update-SelectionFields $vr
    Update-RedactionButtons
    $picture.Invalidate()
})
 
# Crops the given video/image-pixel-space rectangle out of $previewImage and
# returns a small Bitmap with the actual Blur or Pixelate effect applied to
# it - the same two-step scale-down/scale-up technique Build-RedactionFilterComplex
# uses for the real ffmpeg export (nearest-neighbor for Pixelate; here, Blur
# uses a bicubic resample instead of ffmpeg's boxblur, since GDI+ has no
# built-in blur filter - it's a close enough visual approximation for a live
# preview, not a claim of pixel-identical output). Returns $null for "Black
# box" (the caller just fills solid black directly - no source pixels needed)
# or if there's no loaded image to sample from.
function Get-LiveEffectPatch([string]$mode, [int]$sx, [int]$sy, [int]$sw, [int]$sh, [int]$strength = 5, [bool]$enhanced = $false) {
    if (-not $previewImage -or $sw -le 0 -or $sh -le 0) { return $null }
    if ($mode -ne "Blur" -and $mode -ne "Pixelate") { return $null }

    $sx = [Math]::Max(0, [Math]::Min($sx, $previewImage.Width - 1))
    $sy = [Math]::Max(0, [Math]::Min($sy, $previewImage.Height - 1))
    $sw = [Math]::Max(1, [Math]::Min($sw, $previewImage.Width - $sx))
    $sh = [Math]::Max(1, [Math]::Min($sh, $previewImage.Height - $sy))
    $srcRect = New-Object System.Drawing.Rectangle($sx,$sy,$sw,$sh)

    if ($enhanced) {
        $proxy = New-EnhancedStructuralProxy $previewImage $srcRect
        try { return New-EnhancedReconstructedPatch $proxy $sw $sh $mode }
        finally { $proxy.Dispose() }
    }

    # STANDARD PATH BELOW REMAINS THE B1-r4/v2.1 BEHAVIOUR.
    $divisor = if ($mode -eq "Blur") { Get-BlurLiveDivisor $strength } else { Get-PixelateDivisor $strength }
    $interp = if ($mode -eq "Blur") {
        [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    } else {
        [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    }
    # D1b preview/export parity fix:
    # Standard/Default Pixelate export has always enforced a minimum 8x8
    # reduced grid. Mirror that here so the on-screen Pixelate block layout
    # does not visibly change merely because the user exports the image.
    # Blur keeps its existing preview behaviour unchanged.
    if ($mode -eq "Pixelate") {
        $smallW = [Math]::Max(8, [int]($sw / $divisor))
        $smallH = [Math]::Max(8, [int]($sh / $divisor))
    }
    else {
        $smallW = [Math]::Max(1, [int]($sw / $divisor))
        $smallH = [Math]::Max(1, [int]($sh / $divisor))
    }

    # GDI+'s Graphics.DrawImage defaults to WrapMode.Tile for its internal
    # sampling. With interpolation (bicubic here) that means pixels near the
    # edge of the destination rectangle get blended against pixels wrapped in
    # from the OPPOSITE edge of the source, rather than clamped/extended from
    # the nearest source edge. The blend band this produces is a fixed number
    # of SOURCE pixels wide, but gets mapped to a growing number of
    # DESTINATION pixels as the upscale factor increases (i.e. as the strength
    # slider - via Get-BlurLiveDivisor - shrinks $tiny more before blowing it
    # back up) - visually that band looks like an unblurred/"clean" edge
    # eating inward, i.e. the blurred area appears to shrink as strength goes
    # up. Passing an ImageAttributes with WrapMode.TileFlipXY makes GDI+
    # mirror-extend at the edges instead of wrapping around, which removes
    # that artifact regardless of how far the image is scaled.
    $wrapAttr = New-Object System.Drawing.Imaging.ImageAttributes
    $wrapAttr.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

    $tiny = New-Object System.Drawing.Bitmap($smallW, $smallH)
    $tg = [System.Drawing.Graphics]::FromImage($tiny)
    $tg.InterpolationMode = $interp
    if ($mode -eq "Pixelate") {
        # D1b: GDI+ NearestNeighbor needs half-pixel-centre sampling to keep
        # block selection aligned with the centre-sampled FFmpeg neighbour path.
        $tg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    }
    $tg.DrawImage($previewImage, (New-Object System.Drawing.Rectangle(0,0,$smallW,$smallH)), $srcRect.X, $srcRect.Y, $srcRect.Width, $srcRect.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $tg.Dispose()

    $patch = New-Object System.Drawing.Bitmap($sw, $sh)
    $g = [System.Drawing.Graphics]::FromImage($patch)
    $g.InterpolationMode = $interp
    if ($mode -eq "Pixelate") {
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    }
    $g.DrawImage($tiny, (New-Object System.Drawing.Rectangle(0,0,$sw,$sh)), 0, 0, $smallW, $smallH, [System.Drawing.GraphicsUnit]::Pixel, $wrapAttr)
    $g.Dispose()
    $tiny.Dispose()
    $wrapAttr.Dispose()

    return $patch
}

# D1b: project an already-rendered live-effect patch into the viewport.
# Default Pixelate must remain nearest-neighbour at this final display stage;
# otherwise the PictureBox paint path can visually shift/blend block edges
# even when the media-space patch itself is correct.
function Draw-LiveEffectPatchToView($gfx, $patch, $dr, [string]$mode) {
    if ($mode -ne "Pixelate") {
        $gfx.DrawImage($patch, $dr)
        return
    }

    $savedState = $gfx.Save()
    try {
        $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $gfx.DrawImage($patch, $dr)
    }
    finally {
        $gfx.Restore($savedState)
    }
}

# Image-mode counterpart to Draw-RedactionShape: instead of a translucent
# color tint standing in for the redaction, this composites the REAL effect
# (the actual blurred/pixelated/blacked pixels, sampled from $previewImage)
# onto the preview, clipped to the exact shape. Only used in image mode -
# there's a single static frame to sample from, so this stays cheap; video
# mode keeps the lighter tint overlay, since re-sampling/re-blurring a fresh
# source frame on every drag or frame step would be far more expensive there.
function Draw-RedactionShapeLiveEffect($gfx, $r, [System.Drawing.Color]$borderColor, [bool]$drawGuideBorder = $true) {
    $pen = New-Object System.Drawing.Pen($borderColor, 2)

    # Resize Slice 1 r2 / Slice 2: an uncommitted Rectangle or Oval may still
    # contain fractional MEDIA coordinates after move/resize. Its handles are
    # projected from that RectangleF directly. Keep the draft effect/border on
    # exactly the same VIEW rectangle instead of projecting the commit-normalized
    # integer box, which could visibly separate handles from the border after zoom/pan.
    $draftDisplayRect = $null
    if ($r -is [hashtable] -and $r.ContainsKey("DraftDisplayRect")) {
        $draftDisplayRect = $r["DraftDisplayRect"]
    }
    elseif ($r.PSObject -and $r.PSObject.Properties["DraftDisplayRect"]) {
        $draftDisplayRect = $r.DraftDisplayRect
    }

    if ($r.Mode -eq "Black box") {
        $brush = New-Object System.Drawing.SolidBrush((Get-RedactionColor $r))
        if ($r.Shape -eq "Oval") {
            $dr = if ($draftDisplayRect) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
            if ($dr) { $gfx.FillEllipse($brush, $dr); if ($drawGuideBorder) { $gfx.DrawEllipse($pen, $dr) } }
        }
        elseif ($r.Shape -eq "Polygon") {
            $dpts = VideoPoints-To-DisplayPoints $r.Points
            if ($dpts -and $dpts.Count -ge 3) { $gfx.FillPolygon($brush, $dpts); if ($drawGuideBorder) { $gfx.DrawPolygon($pen, $dpts) } }
        }
        else {
            $dr = if ($draftDisplayRect) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
            if ($dr) { $gfx.FillRectangle($brush, $dr); if ($drawGuideBorder) { Draw-ViewportRectangleOutline $gfx $pen $dr } }
        }
        $brush.Dispose()
        $pen.Dispose()
        return
    }

    $dr = if ($draftDisplayRect -and ($r.Shape -eq "Rectangle" -or $r.Shape -eq "Oval")) { $draftDisplayRect } else { VideoRect-To-Display $r.X $r.Y $r.W $r.H }
    if (-not $dr) { $pen.Dispose(); return }
    $liveStrength = if ($r.Strength) { [int]$r.Strength } else { 5 }
    $liveEnhanced = Get-RedactionEnhanced $r
    $patch = Get-LiveEffectPatch $r.Mode $r.X $r.Y $r.W $r.H $liveStrength $liveEnhanced
    if (-not $patch) { $pen.Dispose(); return }

    if ($r.Shape -eq "Oval") {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddEllipse($dr)
        $savedClip = $gfx.Clip.Clone()
        $gfx.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
        Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
        $gfx.Clip = $savedClip
        if ($drawGuideBorder) { $gfx.DrawEllipse($pen, $dr) }
        $path.Dispose()
    }
    elseif ($r.Shape -eq "Polygon") {
        $dpts = VideoPoints-To-DisplayPoints $r.Points
        if ($dpts -and $dpts.Count -ge 3) {
            $path = New-Object System.Drawing.Drawing2D.GraphicsPath
            $path.AddPolygon($dpts)
            $savedClip = $gfx.Clip.Clone()
            $gfx.SetClip($path, [System.Drawing.Drawing2D.CombineMode]::Intersect)
            Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
            $gfx.Clip = $savedClip
            if ($drawGuideBorder) { $gfx.DrawPolygon($pen, $dpts) }
        }
    }
    else {
        Draw-LiveEffectPatchToView $gfx $patch $dr $r.Mode
        if ($drawGuideBorder) { Draw-ViewportRectangleOutline $gfx $pen $dr }
    }

    $patch.Dispose()
    $pen.Dispose()
}

$picture.Add_Paint({
    param($sender,$e)
    $cropClipState=$null
    if($isImageMode -and $script:ImageCrop){$cropClipState=$e.Graphics.Save();$e.Graphics.SetClip((MediaRect-To-ViewRect $script:ImageCrop))}
    if ($script:floatingTextEditorVisible) { Update-FloatingTextEditorPosition }

    # Slice 3: the PictureBox no longer renders its Image property. Draw the
    # current decoded/autorotated frame explicitly through the viewport
    # transform first, then layer committed/pending/draft redactions on top.
    # Fit geometry intentionally preserves r18's integer SizeMode=Zoom result.
    if ($previewImage) {
        $mediaViewRect = Get-MediaViewRect
        if ($mediaViewRect -and $mediaViewRect.Width -gt 0.0 -and $mediaViewRect.Height -gt 0.0) {
            if ($zoomMode -eq "Fit") {
                $destRect = New-Object System.Drawing.Rectangle([int]$mediaViewRect.X,[int]$mediaViewRect.Y,[int]$mediaViewRect.Width,[int]$mediaViewRect.Height)
                $e.Graphics.DrawImage(
                    $previewImage,
                    $destRect,
                    0,
                    0,
                    $previewImage.Width,
                    $previewImage.Height,
                    [System.Drawing.GraphicsUnit]::Pixel
                )
            }
            else {
                $destRectF = New-Object System.Drawing.RectangleF([single]$mediaViewRect.X,[single]$mediaViewRect.Y,[single]$mediaViewRect.Width,[single]$mediaViewRect.Height)
                $e.Graphics.DrawImage($previewImage, $destRectF)
            }
        }
    }

    # Already-committed redactions: show each one's shape whenever the
    # current frame falls within its exact buffered frame range, so scrubbing
    # back over an earlier redaction shows you what's covered where. Frame
    # membership never depends on seconds or average FPS. Still-image entries
    # use frame 0 for every range field, so no special-case is needed here.
    # In image mode this shows the real applied effect rather than a
    # translucent tint, since there's just one static frame to composite against.
    foreach ($r in $redactions) {
        if (Test-FrameInRange $currentFrame $r.BufferedStartFrame $r.BufferedEndFrame) {
            if ($isImageMode) {
                $drawGuide = -not (Test-RedactionHasOutline $r)
                Draw-RedactionShapeLiveEffect $e.Graphics $r ([System.Drawing.Color]::Lime) $drawGuide
            }
            elseif ($r.Mode -eq "Black box") {
                # Show the redaction's own assigned color while scrubbing,
                # rather than the generic green marker used for Blur/Pixelate,
                # so it's obvious at a glance which box is which color.
                $boxColor = Get-RedactionColor $r
                $fillTint = [System.Drawing.Color]::FromArgb(90, $boxColor.R, $boxColor.G, $boxColor.B)
                Draw-RedactionShape $e.Graphics $r $boxColor $fillTint (-not (Test-RedactionHasOutline $r))
            }
            else {
                Draw-RedactionShape $e.Graphics $r ([System.Drawing.Color]::Lime) ([System.Drawing.Color]::FromArgb(60,0,255,0)) (-not (Test-RedactionHasOutline $r))
            }
        }
    }

    # Decorative annotations are always painted after every committed security
    # redaction/effect. They therefore cannot reveal or replace source pixels.
    Draw-AnnotationsToView $e.Graphics
    Draw-SelectedCommittedRedactionGuide $e.Graphics
    Draw-SelectedCommittedAnnotationGuide $e.Graphics
 
    if ($toolMode -eq "Text" -and ($script:textDrawing -or $script:textDraftActive)) {
        $transform = Get-ViewportTransform
        $mediaRect = Get-MediaViewRect
        if ($transform -and $mediaRect -and $script:textDraftRect.Width -gt 0.0 -and $script:textDraftRect.Height -gt 0.0) {
            $draftView = MediaRect-To-ViewRect $script:textDraftRect
            if ($draftView) {
                $draftPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 1)
                $draftPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                try { $e.Graphics.DrawRectangle($draftPen, $draftView.X, $draftView.Y, $draftView.Width, $draftView.Height) }
                finally { $draftPen.Dispose() }
                if ($script:textDraftActive -and -not $script:textDrawing) {
                    Draw-RectangleResizeHandles $e.Graphics $script:textDraftRect
                }
            }
            $draftText = Get-CurrentTextDraftAnnotation
            if ($draftText) {
                $saved = $e.Graphics.Save()
                try {
                    $e.Graphics.SetClip($mediaRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
                    Draw-AnnotationObject $e.Graphics $draftText $transform.ScaleX $transform.ScaleY $transform.OriginX $transform.OriginY
                }
                finally { $e.Graphics.Restore($saved) }
            }
        }
    }
    elseif ($toolMode -eq "Line" -and ($script:lineDrawing -or $script:lineDraftActive) -and $script:lineStart -and $script:lineEnd) {
        $draftLine = New-LineDrawingAnnotation $script:lineStart $script:lineEnd $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawEndpointStyle -1
        $transform = Get-ViewportTransform
        $mediaRect = Get-MediaViewRect
        if ($transform -and $mediaRect) {
            $saved = $e.Graphics.Save()
            try {
                $e.Graphics.SetClip($mediaRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
                Draw-AnnotationObject $e.Graphics $draftLine $transform.ScaleX $transform.ScaleY $transform.OriginX $transform.OriginY
            }
            finally { $e.Graphics.Restore($saved) }
        }
    }
    elseif ($toolMode -eq "Polyline" -and ($script:polylineActive -or $script:polylineDraftActive) -and $script:polylinePoints.Count -gt 0) {
        $draftPoints = New-Object System.Collections.Generic.List[System.Drawing.PointF]
        foreach ($pt in $script:polylinePoints) { [void]$draftPoints.Add($pt) }
        if ($script:polylineMousePos -and $draftPoints.Count -gt 0) { [void]$draftPoints.Add($script:polylineMousePos) }
        if ($draftPoints.Count -ge 2) {
            $draftPolyline = New-PolylineDrawingAnnotation $draftPoints $script:outlineColor $script:outlineWidth $script:outlineDashStyle $script:drawPolylineJoinStyle $script:drawEndpointStyle -1
            $transform = Get-ViewportTransform
            $mediaRect = Get-MediaViewRect
            if ($transform -and $mediaRect) {
                $saved = $e.Graphics.Save()
                try {
                    $e.Graphics.SetClip($mediaRect, [System.Drawing.Drawing2D.CombineMode]::Intersect)
                    Draw-AnnotationObject $e.Graphics $draftPolyline $transform.ScaleX $transform.ScaleY $transform.OriginX $transform.OriginY
                }
                finally { $e.Graphics.Restore($saved) }
            }
        }
        # Constant-screen-space vertex markers keep the click path readable at any zoom.
        $dpts = MediaPoints-To-ViewPoints $script:polylinePoints
        if ($dpts) {
            $markerBrush = New-Object System.Drawing.SolidBrush($script:outlineColor)
            try {
                for ($i = 0; $i -lt $dpts.Count; $i++) {
                    $isArrowStart = [bool]($i -eq 0 -and ($script:drawEndpointStyle -eq "ArrowStart" -or $script:drawEndpointStyle -eq "ArrowBoth"))
                    $isArrowEnd = [bool]($i -eq ($dpts.Count - 1) -and ($script:drawEndpointStyle -eq "ArrowEnd" -or $script:drawEndpointStyle -eq "ArrowBoth"))
                    if ($isArrowStart -or $isArrowEnd) { continue }
                    $vp = $dpts[$i]
                    $e.Graphics.FillEllipse($markerBrush,($vp.X-3),($vp.Y-3),6,6)
                }
            }
            finally { $markerBrush.Dispose() }
        }
    }

    if ($pendingRedaction) {
        # The timeline only moves forward from here: a pending redaction has
        # a start but no end yet, so it should show on its start frame and
        # every frame after, until End Redaction gives it an end. It should
        # NOT show on frames before the start.
        if ($currentFrame -ge $pendingRedaction.StartFrame) {
            Draw-RedactionShape $e.Graphics $pendingRedaction ([System.Drawing.Color]::Orange) ([System.Drawing.Color]::FromArgb(60,255,165,0))
        }
    }
    elseif ($toolMode -eq "Polygon") {
        if ($polygonPoints.Count -gt 0) {
            # Draft freeform vertices live in MEDIA space; project them into
            # the current viewport for drawing only. Pen/marker sizes remain
            # screen-pixel constants.
            $dpts = MediaPoints-To-ViewPoints $polygonPoints
            if ($dpts -and $dpts.Count -gt 0) {
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)

                for ($i = 0; $i -lt $dpts.Count - 1; $i++) {
                    $e.Graphics.DrawLine($pen, $dpts[$i], $dpts[$i+1])
                }

                if ($polygonActive -and $polygonMousePos) {
                    $mouseView = MediaPoint-To-ViewPoint $polygonMousePos
                    if ($mouseView) {
                        $dashPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 1)
                        $dashPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
                        $e.Graphics.DrawLine($dashPen, $dpts[$dpts.Count - 1], $mouseView)
                        $dashPen.Dispose()
                    }
                }
                elseif (-not $polygonActive -and $polygonPoints.Count -ge 3) {
                    # Closed but not yet committed via Begin/Create Redaction.
                    if ($isImageMode) {
                        $shapeData = Polygon-To-VideoShape $polygonPoints
                        if ($shapeData) {
                            if ($script:fillEnabled) {
                                $shapeData.Mode = Get-SelectedMode
                                $shapeData.Strength = $redactionStrength
                                $shapeData.Enhanced = Get-SelectedEnhanced
                                $shapeData.Color = $redactionColor
                                Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red) (-not $script:outlineEnabled)
                            }
                            if ($script:outlineEnabled) {
                                Draw-DraftShapeOutlineToView $e.Graphics $shapeData
                            }
                        }
                    }
                    elseif ($dpts.Count -ge 3) {
                        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
                        $e.Graphics.FillPolygon($brush, $dpts)
                        $e.Graphics.DrawPolygon($pen, $dpts)
                        $brush.Dispose()
                    }
                }

                # Marker on the start point. Geometry moves with the media,
                # while the marker itself remains a constant 8 screen pixels.
                $startPt = $dpts[0]
                $markerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Yellow)
                $e.Graphics.FillEllipse($markerBrush, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
                $e.Graphics.DrawEllipse($pen, ($startPt.X - 4), ($startPt.Y - 4), 8, 8)
                $markerBrush.Dispose()
                $pen.Dispose()

                # Slice 3: once the path is closed, every Freeform corner is
                # an editable vertex. Handles are pure VIEW-space decoration;
                # the underlying PointF list remains canonical media geometry.
                if ($script:resizeSlice3Enabled -and -not $polygonActive -and $polygonPoints.Count -ge 3) {
                    Draw-FreeformVertexHandles $e.Graphics $polygonPoints
                }
            }
        }
    }
    elseif ($selection.Width -gt 0.0 -and $selection.Height -gt 0.0) {
        $displaySelection = MediaRect-To-ViewRect $selection
        if ($displaySelection) {
            if ($isImageMode) {
                $vr = Selection-To-VideoRect
                if ($vr) {
                    $shapeData = @{
                        Shape = if ($toolMode -eq "Oval") { "Oval" } else { "Rectangle" }
                        X = $vr.X; Y = $vr.Y; W = $vr.W; H = $vr.H
                        Mode = Get-SelectedMode
                        Strength = $redactionStrength
                        Enhanced = Get-SelectedEnhanced
                        Color = $redactionColor
                    }
                    if (($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") -or
                        ($script:resizeSlice2Enabled -and $toolMode -eq "Oval")) {
                        # VIEW-only draft geometry: keeps border/effect and the
                        # resize handles on one identical projected RectangleF.
                        $shapeData.DraftDisplayRect = $displaySelection
                    }
                    if ($script:fillEnabled) {
                        Draw-RedactionShapeLiveEffect $e.Graphics $shapeData ([System.Drawing.Color]::Red) (-not $script:outlineEnabled)
                    }
                    if ($script:outlineEnabled) {
                        Draw-DraftShapeOutlineToView $e.Graphics $shapeData
                    }
                }
            }
            else {
                $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 2)
                $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(55,255,0,0))
                if ($toolMode -eq "Oval") {
                    $e.Graphics.FillEllipse($brush, $displaySelection)
                    $e.Graphics.DrawEllipse($pen, $displaySelection)
                }
                else {
                    $e.Graphics.FillRectangle($brush, $displaySelection)
                    Draw-ViewportRectangleOutline $e.Graphics $pen $displaySelection
                }
                $brush.Dispose()
                $pen.Dispose()
            }

            # Resize Slice 1/2: handles are constant screen-pixel UI only.
            # Rectangle keeps its eight handles; Oval exposes only N/E/S/W.
            if (-not $dragging) {
                if ($script:resizeSlice1Enabled -and $toolMode -eq "Rectangle") {
                    Draw-RectangleResizeHandles $e.Graphics $selection
                }
                elseif ($script:resizeSlice2Enabled -and $toolMode -eq "Oval") {
                    Draw-OvalResizeHandles $e.Graphics $selection
                }
            }
        }
    }
    if($cropClipState){$e.Graphics.Restore($cropClipState)}
    Draw-CropGuide $e.Graphics
})
 
$scrubberMarkers.Add_Paint({
    param($sender,$e)

    # Always clear this control explicitly before drawing the current model.
    # The marker strip is repainted from the current redaction + annotation
    # collections, preventing stale pixels after resize/remove/clear operations.
    $e.Graphics.Clear($sender.BackColor)

    if ($videoDuration -le 0 -or ($redactions.Count -eq 0 -and $annotations.Count -eq 0)) { return }

    $w = $sender.ClientSize.Width
    if ($w -le 1) { return }

    # D5b-r3 uses two slim lanes inside the compact marker strip so overlapping
    # redaction and annotation ranges stay independently visible without making
    # the playback panel taller. Red remains security redaction; violet is annotation.
    $redY = 3
    $annotationY = [Math]::Max(7, $sender.ClientSize.Height - 2)

    $redPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
    $redPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $redPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $redBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Red)

    foreach ($r in $redactions) {
        $x1 = Get-MarkerX $r.BufferedStart $videoDuration $w
        $x2 = Get-MarkerX $r.BufferedEnd $videoDuration $w
        $e.Graphics.DrawLine($redPen, $x1, $redY, $x2, $redY)
        $e.Graphics.FillEllipse($redBrush, ($x1 - 3), ($redY - 3), 6, 6)
        $e.Graphics.FillEllipse($redBrush, ($x2 - 3), ($redY - 3), 6, 6)
    }

    $annotationColor = [System.Drawing.Color]::FromArgb(168,85,247) # violet #A855F7
    $annotationPen = New-Object System.Drawing.Pen($annotationColor, 2)
    $annotationPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $annotationPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $annotationBrush = New-Object System.Drawing.SolidBrush($annotationColor)

    foreach ($a in $annotations) {
        if ($a.Kind -notin @("Text","Line","Polyline")) { continue }
        $ar = Get-AnnotationFrameRange $a
        if ([int]$ar.End -lt [int]$ar.Start) { continue }
        $startTime = Get-FramePresentationTime ([int]$ar.Start)
        $endTime = Get-FramePresentationTime ([int]$ar.End)
        if ([double]::IsNaN($startTime) -or [double]::IsInfinity($startTime) -or
            [double]::IsNaN($endTime) -or [double]::IsInfinity($endTime)) { continue }
        $x1 = Get-MarkerX $startTime $videoDuration $w
        $x2 = Get-MarkerX $endTime $videoDuration $w
        $e.Graphics.DrawLine($annotationPen, $x1, $annotationY, $x2, $annotationY)
        $e.Graphics.FillEllipse($annotationBrush, ($x1 - 2), ($annotationY - 2), 4, 4)
        $e.Graphics.FillEllipse($annotationBrush, ($x2 - 2), ($annotationY - 2), 4, 4)
    }

    $redPen.Dispose()
    $redBrush.Dispose()
    $annotationPen.Dispose()
    $annotationBrush.Dispose()
})

$btnStartRedaction.Add_Click({
    if (-not $videoPath) { return }
    if (-not $isImageMode -and (Test-IsStandaloneDrawTool)) {
        [void](Begin-VideoAnnotationRange)
        return
    }
    Stop-Playback
 
    $shapeData = Get-CurrentShapeVideoData
    if (-not $shapeData) {
        [System.Windows.Forms.MessageBox]::Show(
            "Draw a shape over the area to redact first.",
            "Nothing selected",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
 
    $script:pendingRedaction = @{
        Shape = $shapeData.Shape
        X = $shapeData.X; Y = $shapeData.Y; W = $shapeData.W; H = $shapeData.H
        Points = $shapeData.Points
        Mode = Get-SelectedMode
        Strength = $redactionStrength
        Enhanced = Get-SelectedEnhanced
        Color = $redactionColor
        StartTime = Get-FramePresentationTime $currentFrame
        StartFrame = $currentFrame
    }

    if ([double]::IsNaN([double]$pendingRedaction.StartTime) -or
        [double]::IsInfinity([double]$pendingRedaction.StartTime)) {
        $script:pendingRedaction = $null
        [System.Windows.Forms.MessageBox]::Show(
            "The selected start frame does not have a usable presentation timestamp.",
            "Frame timing error",
            "OK",
            "Error"
        ) | Out-Null
        Update-RedactionButtons
        return
    }
 
    $lblPending.Text = "Pending: started at frame $($currentFrame + 1) ($(SecToText $pendingRedaction.StartTime)). Move to the end frame, then click End Redaction."
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnCancelRedaction.Add_Click({
    if ($script:pendingAnnotation) {
        [void](Cancel-VideoAnnotationRange)
        return
    }
    if (-not $isImageMode -and (Test-IsStandaloneDrawTool) -and (Test-VideoAnnotationDraftPresent)) {
        Stop-Playback
        Reset-DrawingState
        Update-SelectionFields $null
        $lblPending.Text = "Annotation draft cancelled."
        Update-RedactionButtons
        Update-AppearanceStatus
        $picture.Invalidate()
        return
    }
    Stop-Playback
    $script:pendingRedaction = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = "No redaction in progress."
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnEndRedaction.Add_Click({
    if ($script:pendingAnnotation) {
        [void](End-VideoAnnotationRange)
        return
    }
    if (-not $pendingRedaction) { return }
    Stop-Playback
 
    if ($currentFrame -lt $pendingRedaction.StartFrame) {
        [System.Windows.Forms.MessageBox]::Show(
            "The end frame must be at or after the start frame ($(SecToText $pendingRedaction.StartTime)).",
            "Invalid range",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }
 
    # The marked range and the safety buffer are defined in exact logical
    # frames. Average FPS is deliberately not involved. This makes the range
    # semantics identical for CFR and VFR and prevents rounding from dropping
    # the first/last intended frame.
    $endFrame = [int]$currentFrame
    $bufferedStartFrame = [int][Math]::Max(0, ([int]$pendingRedaction.StartFrame - $BUFFER_FRAMES))
    $bufferedEndFrame = [int][Math]::Min(($totalFrames - 1), ($endFrame + $BUFFER_FRAMES))

    # Keep seconds only as derived UI/current-export compatibility values.
    # The frame indexes above are canonical and will drive the n-based export
    # activation in the next implementation slice.
    $markStartTime = Get-FramePresentationTime ([int]$pendingRedaction.StartFrame)
    $markEndTime = Get-FramePresentationTime $endFrame
    $bufferedStartTime = Get-FramePresentationTime $bufferedStartFrame
    $bufferedEndTime = Get-FramePresentationTime $bufferedEndFrame
    $rangeTimes = @($markStartTime, $markEndTime, $bufferedStartTime, $bufferedEndTime)
    foreach ($rangeTime in $rangeTimes) {
        if ([double]::IsNaN([double]$rangeTime) -or [double]::IsInfinity([double]$rangeTime)) {
            [System.Windows.Forms.MessageBox]::Show(
                "The selected redaction range does not have a complete validated frame-timing map.",
                "Frame timing error",
                "OK",
                "Error"
            ) | Out-Null
            return
        }
    }
 
    $entry = [PSCustomObject]@{
        Shape = $pendingRedaction.Shape
        X = $pendingRedaction.X; Y = $pendingRedaction.Y; W = $pendingRedaction.W; H = $pendingRedaction.H
        Points = $pendingRedaction.Points
        Mode = $pendingRedaction.Mode
        Strength = $pendingRedaction.Strength
        Enhanced = [bool]$pendingRedaction.Enhanced
        Color = $pendingRedaction.Color
        StartFrame = [int]$pendingRedaction.StartFrame
        EndFrame = $endFrame
        BufferedStartFrame = $bufferedStartFrame
        BufferedEndFrame = $bufferedEndFrame
        MarkStart = [double]$markStartTime
        MarkEnd = [double]$markEndTime
        BufferedStart = [double]$bufferedStartTime
        BufferedEnd = [double]$bufferedEndTime
    }
    [void]$script:redactions.Add($entry)
    Refresh-RedactionList
 
    $script:pendingRedaction = $null
    Reset-DrawingState
    Update-SelectionFields $null
    $lblPending.Text = if (Get-RedactionEnhanced $entry) {
        "Aggressive redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    } else {
        "Redaction #$($redactions.Count) added. Draw a new shape for the next redaction, or export."
    }
    Update-RedactionButtons
    $picture.Invalidate()
})
 
$btnAddRedaction.Add_Click({
    if($isImageMode -and $toolMode -eq 'Crop'){Confirm-ImageCrop;return}
    if (-not $videoPath -or -not $isImageMode) { return }
    if (Test-IsStandaloneDrawTool) {
        Close-FloatingTextEditor $false
        if ($toolMode -eq "Text") { Confirm-TextAnnotation } else { Confirm-DrawingAnnotation }
        return
    }
 
    $shapeData = Get-CurrentShapeVideoData
    if (-not $shapeData) {
        [System.Windows.Forms.MessageBox]::Show(
            "Draw a shape first.",
            "Nothing selected",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    if (-not $script:fillEnabled -and -not $script:outlineEnabled) {
        [System.Windows.Forms.MessageBox]::Show(
            "Choose Fill, Outline, or both before creating the shape.",
            "Nothing to create",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    if (-not $script:fillEnabled) {
        # Annotation-only objects are deliberately stored outside $redactions.
        # They never enter Build-RedactionFilterComplex or security-mask logic.
        $commitOrder = Get-NextObjectCommitOrder
        $annotation = New-ShapeOutlineAnnotation `
            $shapeData `
            $script:outlineColor `
            $script:outlineWidth `
            $script:outlineDashStyle `
            (Get-CurrentOutlineJoinStyle) `
            -1 `
            $commitOrder
        if (-not $annotation) { return }
        [void]$script:annotations.Add($annotation)
        Refresh-AnnotationList
        $lblPending.Text = "Annotation #$($annotations.Count) added. This object does not redact or obscure media."
    }
    else {
        $commitOrder = Get-NextObjectCommitOrder
        $entry = [PSCustomObject]@{
            Shape = $shapeData.Shape
            X = $shapeData.X; Y = $shapeData.Y; W = $shapeData.W; H = $shapeData.H
            Points = $shapeData.Points
            Mode = Get-SelectedMode
            Strength = $redactionStrength
            Enhanced = Get-SelectedEnhanced
            Color = $redactionColor
            OutlineEnabled = [bool]$script:outlineEnabled
            OutlineColor = $script:outlineColor
            OutlineWidth = [int]$script:outlineWidth
            OutlineDashStyle = $script:outlineDashStyle
            OutlineJoinStyle = Get-CurrentOutlineJoinStyle
            CommitOrder = [int]$commitOrder
            StartFrame = 0; EndFrame = 0
            BufferedStartFrame = 0; BufferedEndFrame = 0
            MarkStart = 0.0; MarkEnd = 0.0
            BufferedStart = 0.0; BufferedEnd = 0.0
        }
        [void]$script:redactions.Add($entry)
        Refresh-RedactionList

        if (Get-RedactionEnhanced $entry) {
            $lblPending.Text = "Aggressive redaction #$($redactions.Count) added. Draw a new shape for the next object, or export."
        }
        else {
            $lblPending.Text = "Redaction #$($redactions.Count) added. Draw a new shape for the next object, or export."
        }
    }
 
    $script:selectedRedactionIndex = -1
    if ($lvRedactions.SelectedItems.Count -gt 0) { $lvRedactions.SelectedItems[0].Selected = $false }
    Reset-DrawingState
    Update-SelectionFields $null
    Update-RedactionButtons
})
 
$btnRemoveRedaction.Add_Click({
    if ($lvRedactions.SelectedIndices.Count -eq 0) { return }
    $idx = $lvRedactions.SelectedIndices[0]
    $script:redactions.RemoveAt($idx)
    $script:selectedRedactionIndex = -1
    Reset-DrawingState
    Refresh-RedactionList
    Update-RedactionButtons
})
 
$btnClearRedactions.Add_Click({
    if ($redactions.Count -eq 0) { return }
    $script:redactions.Clear()
    $script:selectedRedactionIndex = -1
    Reset-DrawingState
    Refresh-RedactionList
    Update-RedactionButtons
})
 
$btnRemoveAnnotation.Add_Click({
    if ($script:floatingTextEditorVisible) { Close-FloatingTextEditor $false }
    if ($lvAnnotations.SelectedIndices.Count -eq 0) { return }
    $idx = $lvAnnotations.SelectedIndices[0]
    if ($idx -lt 0 -or $idx -ge $annotations.Count) { return }
    $script:annotations.RemoveAt($idx)
    $script:selectedAnnotationIndex = -1
    Refresh-AnnotationList
    Sync-DraftAppearanceDefaultsToControls
    Update-InspectorSectionLayout
    Update-RedactionButtons
})

$btnClearAnnotations.Add_Click({
    if ($script:floatingTextEditorVisible) { Close-FloatingTextEditor $false }
    if ($annotations.Count -eq 0) { return }
    $script:annotations.Clear()
    $script:selectedAnnotationIndex = -1
    Refresh-AnnotationList
    Sync-DraftAppearanceDefaultsToControls
    Update-InspectorSectionLayout
    Update-RedactionButtons
})
 
function Complete-AsyncExport($result,$failure,$cancelled,$context) {
    foreach($key in $context.Keys){Set-Variable -Name $key -Value $context[$key] -Scope Local}
    $err=if($result){$result.Error}else{$failure}
    try{
        if ($failure -or -not $result -or $result.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $partial)) {
            if(-not $copyOperation){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue}
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Export failed."
            [System.Windows.Forms.MessageBox]::Show(
                "FFmpeg failed to create a complete export. No destination file was replaced.`r`n`r`n$(Get-SafeFFmpegError $err $videoPath)",
                "Export failed",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        $status.Text = "Validating export..."
        $form.Refresh()
        $expectAudio = (-not $isImageMode -and $chkAudio.Checked -and $sourceHasAudio)
        $validation = $result.Validation
        if (-not $validation.Ok) {
            if(-not $copyOperation){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue}
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Export validation failed."
            [System.Windows.Forms.MessageBox]::Show(
                "The exported file failed post-export validation and was not finalized.`r`n`r`n$($validation.Error)",
                "Export validation failed",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        if($copyOperation){
            $stream=[IO.File]::OpenRead($partial)
            try{
                $image=[Drawing.Image]::FromStream($stream)
                try{$clipboardBitmap=[Drawing.Bitmap]::new($image)}finally{$image.Dispose()}
            }finally{$stream.Dispose()}
            try{[Windows.Forms.Clipboard]::SetImage($clipboardBitmap)}finally{$clipboardBitmap.Dispose()}
            $status.Text='Redacted image copied to clipboard.'
            Show-ClipboardConfirmation
        }else{
        # Commit only after validation. Existing destination files remain
        # untouched until this point; File.Replace is atomic on supported
        # same-volume Windows filesystems.
        try {
            if (Test-Path -LiteralPath $out -PathType Leaf) {
                [System.IO.File]::Replace($partial, $out, [System.Management.Automation.Language.NullString]::Value)
            }
            else {
                [System.IO.File]::Move($partial, $out)
            }
        }
        catch {
            if(-not $copyOperation){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue}
            $progress.Visible = $false
            Update-RedactionButtons
            $status.Text = "Could not finalize export."
            [System.Windows.Forms.MessageBox]::Show(
                "The temporary export passed validation, but Windows could not atomically finalize it. Any existing destination file was left untouched.",
                "Could not finalize export",
                "OK",
                "Error"
            ) | Out-Null
            return
        }

        $progress.Visible = $false
        Update-RedactionButtons
        $status.Text = "Done: $out"
        if($form.Visible){
            Show-CompactInformationDialog "Export complete" "Export complete" ("Finished and validated.`r`n`r`n" + $out)
        }else{
            $script:CaptureState.Tray.ShowBalloonTip(3000,'Export complete','The redacted output has finished and passed validation.',[Windows.Forms.ToolTipIcon]::Info)
        }


        }
        if ($deleteRequestedForExport -and -not $copyOperation) {
            Invoke-S1bDeleteOriginalFlow
        }
    }
    catch {
        # Fail closed for unexpected mask/filter/process/finalization exceptions.
        # The selected destination is never touched before validation/commit.
        if ($partial -and (Test-Path -LiteralPath $partial)) {
            if(-not $copyOperation){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue}
        }
        $status.Text = "Export failed."
        [System.Windows.Forms.MessageBox]::Show(
            "The export stopped because an unexpected error occurred. No unvalidated destination file was finalized.",
            "Export failed",
            "OK",
            "Error"
        ) | Out-Null
    }
    finally {



        if (-not $copyOperation -and (Test-Path -LiteralPath $partial)) { if(-not $copyOperation){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue} }
        try { Remove-UnusedCaptureFiles } finally { Set-ExportWindowBusy $false; if($script:QuitAfterExport){$script:QuitAfterExport=$false;Quit-TRTFromTray} }
        $progress.Visible = $false
        Update-RedactionButtons
    }

}
$btnExport.Add_Click({
    if (-not $videoPath) { return }
    $copyOperation=[bool]$script:CopyRequested;$script:CopyRequested=$false;$handedOff=$false
    Stop-Playback

    $hasStandaloneAnnotations = [bool]($annotations.Count -gt 0)
    if ($redactions.Count -eq 0 -and -not $hasStandaloneAnnotations -and -not ($isImageMode -and $script:ImageCrop)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Create at least one redaction or annotation before exporting.",
            "Nothing to export",
            "OK",
            "Warning"
        ) | Out-Null
        return
    }

    # G2d defence in depth: managed policy forbids Blur/Pixelate redactions. Normal
    # UI cannot create them while the control is active, but reject unexpected state
    # before even opening the save dialog rather than silently converting it.
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableVisualObscuration) {
        foreach ($managedRedaction in $redactions) {
            if ($managedRedaction.Mode -eq "Blur" -or $managedRedaction.Mode -eq "Pixelate") {
                [System.Windows.Forms.MessageBox]::Show(
                    "The configured managed policy does not allow Blur or Pixelate redactions. Remove the visual-obscuration redaction and use Coloured Box instead.",
                    "Managed policy restriction",
                    "OK",
                    "Warning"
                ) | Out-Null
                return
            }
        }
    }

    $selectedFormat = if($copyOperation){"PNG"}else{[string]$cmbFormat.SelectedItem}
    if (-not $selectedFormat) { $selectedFormat = if ($isImageMode) { "PNG" } else { "MP4" } }
    $outExt = "." + $selectedFormat.ToLowerInvariant()
    $outputPrefix = if($isImageMode -and $script:ImageCrop -and $redactions.Count -eq 0 -and -not $hasStandaloneAnnotations){"CROPPED_"} elseif ($redactions.Count -eq 0 -and $hasStandaloneAnnotations) { "ANNOTATED_" } else { "REDACTED_" }
    $neutralName = $outputPrefix + (Get-Date -Format "yyyyMMdd_HHmmss") + $outExt
    $saveFilter = if ($isImageMode) { "$selectedFormat image|*$outExt|All files|*.*" } else { "$selectedFormat video|*$outExt|All files|*.*" }
    $saveTitle = if($isImageMode -and $script:ImageCrop -and $redactions.Count -eq 0 -and -not $hasStandaloneAnnotations){"Save cropped image"} elseif ($redactions.Count -eq 0 -and $hasStandaloneAnnotations) { if ($isImageMode) { "Save annotated image" } else { "Save annotated video" } } elseif ($isImageMode) { "Save redacted image" } else { "Save redacted video" }

    try {
        $out = if($copyOperation){New-CaptureFile '.png'}else{[SecureFileDialogNativeV2]::ShowSave($form.Handle, $saveFilter, $saveTitle, $neutralName, $selectedFormat.ToLowerInvariant())}
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(("Windows could not open the secure save dialog.`r`n`r`n" + $_.Exception.Message), "File dialog error", "OK", "Error") | Out-Null
        return
    }
    if ([string]::IsNullOrWhiteSpace($out)) { return }

    # Keep the filename/container extension consistent with the selected export
    # format even if the user typed a different extension in the native dialog.
    if (-not [System.IO.Path]::GetExtension($out).Equals($outExt, [System.StringComparison]::OrdinalIgnoreCase)) {
        $out = [System.IO.Path]::ChangeExtension($out, $outExt)
    }


    # G2c defence in depth: even if UI state is changed unexpectedly, a managed
    # disableAudioRetention policy cannot cause unredacted source audio to be exported.
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableAudioRetention) {
        $chkAudio.Checked = $false
    }

    # G2b defence in depth: even if UI state is changed unexpectedly, a managed
    # disableSourceDeletion policy cannot reach the destructive deletion path.
    if ($script:ManagedPolicy -and $script:ManagedPolicy.DisableSourceDeletion) {
        $chkDeleteOriginal.Checked = $false
        $script:deleteOriginalRequested = $false
    }
    $deleteRequestedForExport = [bool](-not $copyOperation -and $chkDeleteOriginal.Checked -and $chkDeleteOriginal.Enabled)
    if ($deleteRequestedForExport -and (Test-DeletionOutputCollision $videoPath $out $sourceDeletionIdentity)) {
        [System.Windows.Forms.MessageBox]::Show(
            'The export destination must be different from the original file when automatic deletion is selected. Choose another destination.',
            'Choose a different destination', 'OK', 'Warning') | Out-Null
        return
    }

    $networkReason = Get-NetworkPathReason $out
    if ($networkReason) {
        if ($script:ManagedPolicy -and $script:ManagedPolicy.BlockNetworkDestination) {
            # Managed G2a-G2d block occurs before partial-file creation or encoding.
            # No selected output path is logged or persisted by this decision.
            Show-ManagedNetworkLocationBlock "Destination"
            return
        }

        # Without a managed block, preserve the accepted public warning flow and
        # the same-directory partial/validation workflow.
        if (-not (Show-NetworkLocationWarning "Destination")) { return }
    }

    # Never encode directly over the user's chosen destination. The temporary
    # redacted output lives beside it (same volume), is validated there, then
    # is atomically moved/replaced only after validation succeeds.
    $outDir = [System.IO.Path]::GetDirectoryName($out)
    $outStem = [System.IO.Path]::GetFileNameWithoutExtension($out)
    $partial = if($copyOperation){New-CaptureFile '.png'}else{Join-Path $outDir ($outStem + ".partial." + [guid]::NewGuid().ToString("N") + $outExt)}

    $exportRedactions = Get-ExportRedactionList $redactions

    # Oval/Polygon redactions each need a pre-rendered geometry-only mask.
    $maskPaths = @{}
    $maskTempFiles = New-Object System.Collections.Generic.List[string]
    $annotationTempFiles = New-Object System.Collections.Generic.List[string]
    $annotationRestoreMaskTempFiles = New-Object System.Collections.Generic.List[string]
    Set-ExportWindowBusy $true
    try {
        for ($i = 0; $i -lt $exportRedactions.Count; $i++) {
            $r = $exportRedactions[$i]
            if ($r.Shape -and $r.Shape -ne "Rectangle") {
                $maskFile = New-CaptureFile '.png'
                New-ShapeMaskFile $r $maskFile
                $maskPaths[$i] = $maskFile
                [void]$maskTempFiles.Add($maskFile)
            }
        }

        $built = Build-RedactionFilterComplex $exportRedactions $maskPaths
        $filterComplex = $built.FilterComplex
        $finalLabel = $built.FinalLabel
        $maskInputArgsStr = if ($built.MaskInputArgs.Count -gt 0) { " -i " + ([string]::Join(" -i ", $built.MaskInputArgs)) } else { "" }
        $annotationInputArgsStr = ""

        # The shared GDI+ renderer remains the sole annotation visual source.
        # Stills use one combined overlay. D5b video uses one full-media RGBA
        # overlay per annotation so exact logical-frame activation and commit-order
        # redaction occlusion can be expressed without changing the security pass.
        $annotationObjects = Get-ImageAnnotationObjects
        if ($annotationObjects.Count -gt 0) {
            if ($isImageMode) {
                $annotationFile = New-CaptureFile '.png'
                New-ImageAnnotationOverlayFile $annotationObjects $redactions $annotationFile
                [void]$annotationTempFiles.Add($annotationFile)

                $annotationInputIndex = 1 + [int]$built.MaskInputArgs.Count
                $annotationInputArgsStr = " -i " + (Quote-Arg $annotationFile)
                $annotationFmtLabel = "annfmt0"
                $annotationOutLabel = "annout0"
                $annotationPrefix = if ([string]::IsNullOrWhiteSpace($filterComplex)) { "" } else { ";" }
                $filterComplex += $annotationPrefix + "[${annotationInputIndex}:v]format=rgba[$annotationFmtLabel];[$finalLabel][$annotationFmtLabel]overlay=0:0[$annotationOutLabel]"
                $finalLabel = $annotationOutLabel
            }
            else {
                $annInputStart = 1 + [int]$built.MaskInputArgs.Count
                $annInputIndexes = New-Object System.Collections.ArrayList
                for ($ai=0; $ai -lt $annotationObjects.Count; $ai++) {
                    $a = $annotationObjects[$ai]
                    $annotationFile = New-CaptureFile '.png'
                    New-ImageAnnotationOverlayFile @($a) @() $annotationFile
                    [void]$annotationTempFiles.Add($annotationFile)
                    $annotationInputArgsStr += " -i " + (Quote-Arg $annotationFile)
                    [void]$annInputIndexes.Add($annInputStart + $ai)
                }

                # Identify every case where an annotation must visually sit below
                # a redaction committed later. Security redactions have already
                # been applied to $finalLabel; the restore operation copies those
                # already-redacted pixels, never original source pixels.
                $restorePairs = New-Object System.Collections.ArrayList
                for ($ai=0; $ai -lt $annotationObjects.Count; $ai++) {
                    $a=$annotationObjects[$ai]
                    $aOrder=if ($a.PSObject.Properties['CommitOrder']) { [int]$a.CommitOrder } else { -1 }
                    $ar=Get-AnnotationFrameRange $a
                    for ($ri=0; $ri -lt $exportRedactions.Count; $ri++) {
                        $r=$exportRedactions[$ri]
                        $rOrder=if ($r.PSObject.Properties['CommitOrder']) { [int]$r.CommitOrder } else { -1 }
                        if ($aOrder -lt 0 -or $rOrder -le $aOrder) { continue }
                        $rs=[Math]::Max([int]$ar.Start,[int]$r.BufferedStartFrame)
                        $re=[Math]::Min([int]$ar.End,[int]$r.BufferedEndFrame)
                        if ($re -ge $rs) {
                            [void]$restorePairs.Add([PSCustomObject]@{ AnnotationIndex=$ai; RedactionIndex=$ri; StartFrame=$rs; EndFrame=$re })
                        }
                    }
                }

                # Non-rectangular restoration needs a geometry-only luma mask.
                # One mask input per redaction is split if several earlier
                # annotations need restoration under the same redaction.
                $restoreMaskInputIndex = @{}
                $restoreMaskUses = @{}
                foreach ($pair in $restorePairs) {
                    $ri=[int]$pair.RedactionIndex; $r=$exportRedactions[$ri]
                    if ($r.Shape -eq 'Rectangle' -or -not $r.Shape) { continue }
                    if (-not $restoreMaskUses.ContainsKey($ri)) { $restoreMaskUses[$ri]=0 }
                    $restoreMaskUses[$ri]=[int]$restoreMaskUses[$ri]+1
                }
                $nextAuxIndex = $annInputStart + $annotationObjects.Count
                foreach ($ri in @($restoreMaskUses.Keys | Sort-Object)) {
                    $r=$exportRedactions[[int]$ri]
                    $restoreMaskFile=New-CaptureFile '.png'
                    New-AnnotationOcclusionMaskFile $r $restoreMaskFile
                    [void]$annotationRestoreMaskTempFiles.Add($restoreMaskFile)
                    $annotationInputArgsStr += " -i " + (Quote-Arg $restoreMaskFile)
                    $restoreMaskInputIndex[[int]$ri]=$nextAuxIndex
                    $nextAuxIndex++
                }

                $annParts=New-Object System.Collections.Generic.List[string]
                $restoreCopies=New-Object System.Collections.ArrayList
                if ($restorePairs.Count -gt 0) {
                    $labels=@('[annsecbase]')
                    for ($k=0;$k -lt $restorePairs.Count;$k++) { $labels += "[annsec$k]" }
                    $annParts.Add("[$finalLabel]split=$($restorePairs.Count+1)" + ([string]::Join('', $labels)))
                    for ($k=0;$k -lt $restorePairs.Count;$k++) { [void]$restoreCopies.Add("annsec$k") }
                    $curAnn='annsecbase'
                } else { $curAnn=$finalLabel }

                $restoreMaskLabelQueues=@{}
                foreach ($ri in @($restoreMaskUses.Keys | Sort-Object)) {
                    $count=[int]$restoreMaskUses[$ri]
                    $idx=[int]$restoreMaskInputIndex[$ri]
                    $queue=New-Object System.Collections.Queue
                    if ($count -eq 1) {
                        $label="arm${ri}_0"
                        $annParts.Add("[${idx}:v]format=gray[$label]")
                        $queue.Enqueue($label)
                    } else {
                        $labels=@()
                        for ($m=0;$m -lt $count;$m++) { $labels += "[arm${ri}_$m]"; $queue.Enqueue("arm${ri}_$m") }
                        $annParts.Add("[${idx}:v]format=gray,split=$count" + ([string]::Join('', $labels)))
                    }
                    $restoreMaskLabelQueues[[int]$ri]=$queue
                }

                $restoreCopyIndex=0
                for ($ai=0;$ai -lt $annotationObjects.Count;$ai++) {
                    $a=$annotationObjects[$ai]; $ar=Get-AnnotationFrameRange $a
                    $annIdx=[int]$annInputIndexes[$ai]
                    $fmt="vaf$ai"; $outLbl="vao$ai"
                    $annParts.Add("[${annIdx}:v]format=rgba[$fmt]")
                    $annEnable="between(n\,$([int]$ar.Start)\,$([int]$ar.End))"
                    $annParts.Add("[$curAnn][$fmt]overlay=0:0:enable='$annEnable'[$outLbl]")
                    $curAnn=$outLbl

                    foreach ($pair in @($restorePairs | Where-Object { [int]$_.AnnotationIndex -eq $ai })) {
                        $ri=[int]$pair.RedactionIndex; $r=$exportRedactions[$ri]
                        $sec=[string]$restoreCopies[$restoreCopyIndex]; $restoreCopyIndex++
                        $crop="arc${ai}_${ri}_${restoreCopyIndex}"
                        $next="arv${ai}_${ri}_${restoreCopyIndex}"
                        $annParts.Add("[$sec]crop=$($r.W):$($r.H):$($r.X):$($r.Y)[$crop]")
                        $restoreEnable="between(n\,$([int]$pair.StartFrame)\,$([int]$pair.EndFrame))"
                        if ($r.Shape -and $r.Shape -ne 'Rectangle') {
                            $maskLabel=[string]$restoreMaskLabelQueues[$ri].Dequeue()
                            $patch="arp${ai}_${ri}_${restoreCopyIndex}"
                            $annParts.Add("[$crop][$maskLabel]alphamerge[$patch]")
                            $annParts.Add("[$curAnn][$patch]overlay=$($r.X):$($r.Y):enable='$restoreEnable'[$next]")
                        } else {
                            $annParts.Add("[$curAnn][$crop]overlay=$($r.X):$($r.Y):enable='$restoreEnable'[$next]")
                        }
                        $curAnn=$next
                    }
                }

                $annotationPrefix = if ([string]::IsNullOrWhiteSpace($filterComplex)) { '' } else { ';' }
                $filterComplex += $annotationPrefix + ([string]::Join(';',$annParts))
                $finalLabel=$curAnn
            }
        }
        $cropExport=Add-ImageCropFilter $filterComplex $finalLabel
        $filterComplex=$cropExport.Filter;$finalLabel=$cropExport.Label
        $auxInputArgsStr = $maskInputArgsStr + $annotationInputArgsStr

        $progress.Minimum = 0
        $progress.Maximum = 100
        if ($isImageMode) {
            $progress.Style = "Marquee"
        }
        else {
            $progress.Style = "Continuous"
            $progress.Value = 0
        }
        $progress.Visible = $true
        $btnExport.Enabled = $false
        Update-ExportButtonAppearance
        if ($redactions.Count -eq 0 -and $annotations.Count -gt 0) {
            $status.Text = "Exporting $($annotations.Count) annotation(s)..."
        }
        elseif ($annotations.Count -gt 0) {
            $status.Text = "Exporting $($redactions.Count) redaction(s) and $($annotations.Count) annotation(s)..."
        }
        else {
            $status.Text = "Exporting $($redactions.Count) redaction(s)..."
        }
        $form.Refresh()

        $metadataArgs = " -map_metadata -1 -map_metadata:s -1 -map_chapters -1"

        if ($isImageMode) {
            if ($selectedFormat -eq "GIF") {
                $paletteStage = "[$finalLabel]split[gpal1][gpal2];[gpal1]palettegen=stats_mode=single[gpal];[gpal2][gpal]paletteuse=dither=bayer[gout]"
                $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $auxInputArgsStr +
                        " -filter_complex " + (Quote-Arg "$filterComplex;$paletteStage") +
                        " -map " + (Quote-Arg "[gout]") + $metadataArgs +
                        " -frames:v 1 -c:v gif " +
                        (Quote-Arg $partial)
            }
            else {
                # Do not rely on FFmpeg's container/default encoder selection.
                # Every supported still-image output names its encoder explicitly,
                # just as video exports already do.
                $qualityArg = switch ($selectedFormat) {
                    "PNG"  { "-c:v png" }
                    "JPG"  { "-c:v mjpeg -q:v 3" }
                    "WEBP" { "-c:v libwebp -q:v 90" }
                    default { throw "Unsupported image output format." }
                }
                $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $auxInputArgsStr +
                        " -filter_complex " + (Quote-Arg $filterComplex) +
                        " -map " + (Quote-Arg "[$finalLabel]") + $metadataArgs +
                        " -frames:v 1 -update 1 $qualityArg " +
                        (Quote-Arg $partial)
            }
        }
        else {
            $isWebm = ($selectedFormat -eq "WEBM")

            if ($isWebm) {
                $crf = switch ($cmbQuality.SelectedIndex) {
                    0 { 24 }
                    1 { 31 }
                    default { 38 }
                }
                $vcodecArgs = "-c:v libvpx-vp9 -b:v 0 -crf $crf -pix_fmt yuv420p"
                $audioCodecArg = if ($chkAudio.Checked) { "-c:a libopus -b:a 128k" } else { "-an" }
            }
            else {
                $crf = switch ($cmbQuality.SelectedIndex) {
                    0 { 18 }
                    1 { 22 }
                    default { 26 }
                }
                $vcodecArgs = "-c:v libx264 -preset medium -crf $crf -pix_fmt yuv420p"
                $audioCodecArg = if ($chkAudio.Checked) { "-c:a aac -b:a 192k" } else { "-an" }
            }

            # Audio is unsanitised. If the user explicitly enables it, include
            # only the primary audio stream instead of silently carrying every
            # commentary/secondary track in the source.
            $audioMapArg = if ($chkAudio.Checked) { " -map 0:a:0?" } else { "" }
            # Preserve the filtergraph's presentation timestamps explicitly.
            # FFmpeg's default auto fps mode is not acceptable here because a
            # muxer may otherwise select CFR and duplicate/drop source frames.
            $videoTimingArgs = "-fps_mode:v:0 passthrough -enc_time_base:v:0 filter"
            $args = "-hide_banner -nostdin -y -autorotate -i " + (Quote-Arg $videoPath) + $auxInputArgsStr +
                    " -filter_complex " + (Quote-Arg $filterComplex) +
                    " -map " + (Quote-Arg "[$finalLabel]") + $audioMapArg + $metadataArgs +
                    " $vcodecArgs $videoTimingArgs $audioCodecArg " +
                    (Quote-Arg $partial)
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $ffmpeg
        $psi.Arguments = "-progress pipe:1 -nostats " + $args
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $context=@{partial=$partial;out=$out;copyOperation=$copyOperation;deleteRequestedForExport=$deleteRequestedForExport;cropExport=$cropExport}
        $parameters=@{Psi=$psi;Mpeg=$ffmpeg;Probe=$ffprobe;Path=$partial;Image=$isImageMode;Audio=(-not $isImageMode -and $chkAudio.Checked -and $sourceHasAudio);Width=$cropExport.Width;Height=$cropExport.Height;Duration=$videoDuration;Timeline=$frameTimeline}
        Start-MediaWorker 'Export' $parameters ${function:Complete-AsyncExport} $context
        $handedOff=$true
    }catch{
        if(-not $copyOperation -and $partial -and (Test-Path -LiteralPath $partial)){Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue}
        [Windows.Forms.MessageBox]::Show('The export could not be started. No destination was finalized.','Export failed','OK','Error')|Out-Null
    }finally{
        if(-not $handedOff){Remove-UnusedCaptureFiles;Set-ExportWindowBusy $false;$progress.Visible=$false;Update-RedactionButtons}
    }
})
 
$form.Add_SizeChanged({if($right.Visible -and $lblDeleteCapability){Update-InspectorSectionLayout}})
Initialize-TRTTrayCapture
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class TRTSessionWindows {
    private delegate bool Callback(IntPtr h,IntPtr p);
    [DllImport("user32.dll")]private static extern bool EnumWindows(Callback c,IntPtr p);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)]private static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
    [DllImport("user32.dll")]private static extern uint GetWindowThreadProcessId(IntPtr h,out uint id);
    public static bool HasOtherTRTWindow(int own){bool found=false;EnumWindows(delegate(IntPtr h,IntPtr p){var text=new StringBuilder(256);GetWindowText(h,text,256);uint id;GetWindowThreadProcessId(h,out id);if(id!=(uint)own && text.ToString()=="TinyRedactionTool"){found=true;return false;}return true;},IntPtr.Zero);return found;}
}
'@
function Set-ExportWindowBusy([bool]$busy) {
    if($busy){
        if($script:ExportBusy){return}
        $script:ExportBusy=$true
        $script:ExportControlStates=@()
        $queue=New-Object 'Collections.Generic.Queue[Windows.Forms.Control]'
        foreach($control in $form.Controls){$queue.Enqueue($control)}
        while($queue.Count){
            $control=$queue.Dequeue()
            # Leave panels/window activation enabled. Lock only input controls.
            if($control -is [Windows.Forms.ButtonBase] -or $control -is [Windows.Forms.TextBoxBase] -or
               $control -is [Windows.Forms.ComboBox] -or $control -is [Windows.Forms.UpDownBase] -or
               $control -is [Windows.Forms.TrackBar] -or $control -is [Windows.Forms.ListView] -or
               $control -is [Windows.Forms.PictureBox]){
                $script:ExportControlStates+=,[pscustomobject]@{Control=$control;Enabled=$control.Enabled}
                $control.Enabled=$false
            }else{foreach($child in $control.Controls){$queue.Enqueue($child)}}
        }
        $form.Enabled=$true
    }else{
        foreach($entry in $script:ExportControlStates){if(-not $entry.Control.IsDisposed){$entry.Control.Enabled=$entry.Enabled}}
        $script:ExportControlStates=@();$script:ExportBusy=$false;$form.Enabled=$true
        Update-SourceDeletionUi;Update-OutlineControlsAvailability
    }
}
function Invoke-ResponsiveExportValidation($mpeg,$probe,$path,$imageMode,$expectAudio,$width,$height,$duration,$timeline) {
    # Execute the original validator and its original helpers on a worker;
    # only the main UI thread pumps messages. Trusted tool locks remain held.
    $definitions=New-Object Text.StringBuilder
    foreach($name in @('Quote-Arg','Get-SafeFFmpegError','Get-FrameTimingMap','Get-OutputInspection','Test-ExportSecurity')){
        $definition=(Get-Command $name -CommandType Function).Definition
        [void]$definitions.AppendLine(('function '+$name+' {'+"`n"+$definition+"`n"+'}'))
    }
    $worker=[PowerShell]::Create()
    try{
        [void]$worker.AddScript('$ErrorActionPreference="Stop"'+"`n"+$definitions.ToString()).AddStatement().AddCommand('Test-ExportSecurity')
        foreach($arg in @($mpeg,$probe,$path,$imageMode,$expectAudio,$width,$height,$duration,$timeline)){[void]$worker.AddArgument($arg)}
        $task=$worker.BeginInvoke()
        while(-not $task.IsCompleted){[Windows.Forms.Application]::DoEvents();[Threading.Thread]::Sleep(30)}
        $result=$worker.EndInvoke($task)
        if($worker.Streams.Error.Count -or $result.Count -ne 1){return @{Ok=$false;Error='The export validation worker did not complete safely.'}}
        return $result[0].PSObject.BaseObject
    }catch{return @{Ok=$false;Error='The export validation worker failed; no output was finalized.'}}
    finally{$worker.Dispose()}
}
function Get-CaptureTempBase {return [IO.Path]::GetFullPath([IO.Path]::GetTempPath())}
function Recover-AbandonedCaptureFiles {
    $temp=Get-CaptureTempBase
    $legacyLive=[TRTSessionWindows]::HasOtherTRTWindow($PID)
    foreach($dir in @(Get-ChildItem -LiteralPath $temp -Directory -Filter 'TinyRedactionTool-Capture-*' -ErrorAction SilentlyContinue)){
        if($dir.Name -notmatch '^TinyRedactionTool-Capture-[a-f0-9]{32}$' -or ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)){continue}
        $leasePath=Join-Path $dir.FullName '.session.lock';$lease=$null
        if(-not (Test-Path -LiteralPath $leasePath) -and $legacyLive){continue}
        try{
            if(Test-Path -LiteralPath $leasePath){$lease=[IO.File]::Open($leasePath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)}
        }catch{continue} # Another live instance/session owns this folder.
        try{
            foreach($file in @(Get-ChildItem -LiteralPath $dir.FullName -File)){
                if($file.Name -match '^capture-[a-f0-9]{32}\.(png|mp4)$'){
                    [TRT250.CaptureCleanup]::OverwriteAndDelete($file.FullName,$dir.FullName)
                }
            }
            if($lease){$lease.Dispose();$lease=$null}
            if(Test-Path -LiteralPath $leasePath){Remove-Item -LiteralPath $leasePath -Force -ErrorAction Stop}
            # Nonrecursive: unknown files/subfolders are never deleted.
            [IO.Directory]::Delete($dir.FullName,$false)
        }catch{
            [System.Windows.Forms.MessageBox]::Show(('TRT temporary capture cleanup could not finish: '+$dir.FullName+"`r`n"+$_.Exception.GetBaseException().Message),'Capture cleanup','OK','Warning')|Out-Null
        }finally{if($lease){$lease.Dispose()}}
    }
    if(-not $legacyLive){
        # Old test launchers had no ownership marker. Only known three-file
        # test directories with cryptographically pinned binaries qualify.
        foreach($dir in @(Get-ChildItem -LiteralPath $temp -Directory -Filter 'TinyRedactionTool-C*-Test-*' -ErrorAction SilentlyContinue)){
            if($dir.Name -notmatch '^TinyRedactionTool-C[1-5]-Test-[a-f0-9]{32}$' -or ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)){continue}
            try{
                $files=@(Get-ChildItem -LiteralPath $dir.FullName -Force)
                if($files.Count -ne 3 -or @($files|Where-Object{($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $_.PSIsContainer}).Count){continue}
                $code=@($files|Where-Object Name -match '^TinyRedactionTool-v2\.5\.0-C[1-5]-TEST\.ps1$')
                if($code.Count -ne 1 -or -not [IO.File]::ReadAllText($code[0].FullName).StartsWith('# TinyRedactionTool ')){continue}
                $mpeg=Join-Path $dir.FullName 'ffmpeg.exe';$probe=Join-Path $dir.FullName 'ffprobe.exe'
                if((Get-FileHash $mpeg).Hash -ne $script:ExpectedFFmpegSha256 -or (Get-FileHash $probe).Hash -ne $script:ExpectedFFprobeSha256){continue}
                foreach($file in $files){Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop}
                [IO.Directory]::Delete($dir.FullName,$false)
            }catch{[Windows.Forms.MessageBox]::Show(('Old TRT test tools could not be removed: '+$dir.FullName),'Temporary cleanup','OK','Warning')|Out-Null}
        }
        $embeddedBase=Join-Path $temp 'TinyRedactionTool'
        if((Test-Path -LiteralPath $embeddedBase) -and -not ((Get-Item -LiteralPath $embeddedBase).Attributes -band [IO.FileAttributes]::ReparsePoint)){
            foreach($dir in @(Get-ChildItem -LiteralPath $embeddedBase -Directory -Filter 'run-*')){
                if($dir.Name -notmatch '^run-[a-f0-9]{32}$' -or ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $dir.FullName -eq $script:EmbeddedMediaRuntimeDir){continue}
                try{
                    $files=@(Get-ChildItem -LiteralPath $dir.FullName -Force)
                    if(@($files|Where-Object{$_.Name -notin @('ffmpeg.exe','ffprobe.exe') -or $_.PSIsContainer -or ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)}).Count){continue}
                    foreach($file in $files){Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop}
                    [IO.Directory]::Delete($dir.FullName,$false)
                }catch{[Windows.Forms.MessageBox]::Show(('Abandoned TRT media tools could not be removed: '+$dir.FullName),'Temporary cleanup','OK','Warning')|Out-Null}
            }
        }
    }
}
function Show-RedactionEditor([int]$index) {
    if($index -lt 0 -or $index -ge $redactions.Count -or $pendingRedaction -or $script:pendingAnnotation){return}
    Stop-Playback;Close-FloatingTextEditor $false;Reset-DrawingState
    if($lvAnnotations.SelectedItems.Count){$lvAnnotations.SelectedItems[0].Selected=$false}
    $script:selectedAnnotationIndex=-1
    $lvRedactions.Items[$index].Selected=$true;$script:selectedRedactionIndex=$index
    $r=$redactions[$index];$script:RedactionEditorSync=$true
    try{
        $redactionEditorTitle.Text=if($r.Shape -eq 'Polygon'){'Freeform redaction'}else{$r.Shape+' redaction'}
        $redactionEditorColor.BackColor=$r.Color;$redactionEditorColor.Visible=$r.Mode -eq 'Black box'
        $redactionEditorStrength.Visible=$r.Mode -ne 'Black box'
        $redactionEditorStrength.Enabled=-not (Get-RedactionEnhanced $r)
        $redactionEditorStrength.Value=[Math]::Max(1,[Math]::Min(10,[int]$r.Strength))
        $redactionEditor.Location=New-Object Drawing.Point(12,12)
        $redactionEditor.BackColor=$floatingTextEditor.BackColor;$redactionEditor.ForeColor=$floatingTextEditor.ForeColor
        foreach($ctl in @($redactionEditorTitle,$redactionEditorHint)){$ctl.BackColor=$redactionEditor.BackColor;$ctl.ForeColor=$redactionEditor.ForeColor}
        $redactionEditor.Visible=$true;$redactionEditor.BringToFront()
    }finally{$script:RedactionEditorSync=$false}
    $lblPending.Text='Redaction editing: drag inside to move; drag handles to resize or reshape. Click outside to confirm.'
    $picture.Invalidate()
}
function Close-RedactionEditor {
    if($redactionEditor){$redactionEditor.Visible=$false}
}

$redactionEditor=New-Object Windows.Forms.Panel
$redactionEditor.Size=New-Object Drawing.Size(405,65);$redactionEditor.Visible=$false
$redactionEditor.BorderStyle='FixedSingle';$redactionEditor.BackColor=[Drawing.Color]::FromArgb(255,244,170);$redactionEditor.ForeColor=[Drawing.Color]::Black
$picture.Controls.Add($redactionEditor)
$redactionEditorTitle=New-Object Windows.Forms.Label;$redactionEditorTitle.SetBounds(8,7,175,22);$redactionEditor.Controls.Add($redactionEditorTitle)
$redactionEditorColor=New-Object Windows.Forms.Button;$redactionEditorColor.SetBounds(190,5,40,24);$redactionEditor.Controls.Add($redactionEditorColor)
$script:appToolTip.SetToolTip($redactionEditorColor,'Redaction colour')
$redactionEditorColor.Add_Click({
    $r=Get-SelectedCommittedRedaction;if(-not $r -or $r.Mode -ne 'Black box'){return}
    $script:RedactionColorDialog=$true;$dlg=New-Object Windows.Forms.ColorDialog;$dlg.Color=$r.Color
    try{if($dlg.ShowDialog($form) -eq 'OK'){$r.Color=$dlg.Color;$redactionEditorColor.BackColor=$dlg.Color;Update-ColorSwatch;$picture.Invalidate()}}finally{$dlg.Dispose();$script:RedactionColorDialog=$false}
})
$redactionEditorStrength=New-Object Windows.Forms.NumericUpDown;$redactionEditorStrength.Minimum=1;$redactionEditorStrength.Maximum=10;$redactionEditorStrength.SetBounds(190,5,55,24);$redactionEditor.Controls.Add($redactionEditorStrength)
$script:appToolTip.SetToolTip($redactionEditorStrength,'Redaction strength')
$redactionEditorStrength.Add_ValueChanged({if(-not $script:RedactionEditorSync){$r=Get-SelectedCommittedRedaction;if($r -and $r.Mode -ne 'Black box'){$r.Strength=[int]$redactionEditorStrength.Value;$picture.Invalidate()}}})
$redactionEditorDone=New-Object Windows.Forms.Button;$redactionEditorDone.Text='Done';$redactionEditorDone.SetBounds(330,4,65,26);$redactionEditor.Controls.Add($redactionEditorDone)
$redactionEditorDone.Add_Click({Close-RedactionEditor})
$redactionEditorHint=New-Object Windows.Forms.Label;$redactionEditorHint.Text='Drag handles to adjust. Double-click to reopen. Click outside to close.';$redactionEditorHint.SetBounds(8,36,390,22);$redactionEditor.Controls.Add($redactionEditorHint)
$script:RedactionOutsideFilter=New-Object TRTAnnotationOutsideClickFilter;$script:RedactionOutsideFilter.Editor=$redactionEditor
$script:RedactionOutsideFilter.Add_OutsideClick({if(-not $script:RedactionColorDialog){Close-RedactionEditor}})
[Windows.Forms.Application]::AddMessageFilter($script:RedactionOutsideFilter)
$form.Add_Deactivate({if(-not $script:RedactionColorDialog){Close-RedactionEditor}})
$form.Add_FormClosing({param($sender,$e) if($script:ExportBusy){$e.Cancel=$true;Hide-TRTToTray}})
$script:InstancePoll=New-Object Windows.Forms.Timer;$script:InstancePoll.Interval=150
$script:InstancePoll.Add_Tick({if($script:InstanceSignal.WaitOne(0)){Restore-TRTFromTray}})
$script:InstancePoll.Start()
$form.Add_FormClosed({
    $script:InstancePoll.Stop();$script:InstancePoll.Dispose()
    [Windows.Forms.Application]::RemoveMessageFilter($script:RedactionOutsideFilter)
    $script:InstanceSignal.Dispose();if($script:InstanceOwned){$script:InstanceMutex.ReleaseMutex();$script:InstanceOwned=$false};$script:InstanceMutex.Dispose()
})
Recover-AbandonedCaptureFiles

$form.Add_FormClosed({
    $playTimer.Stop()
    $previewTimer.Stop()
    if ($previewImage) { $previewImage.Dispose() }
    if ($script:zoomCursor) {
        try { $script:zoomCursor.Dispose() } catch {}
        $script:zoomCursor = $null
    }
    if ($script:zoomCursorHandle -ne [IntPtr]::Zero) {
        try { [ZoomCursorNativeV1]::DestroyCursorHandle($script:zoomCursorHandle) } catch {}
        $script:zoomCursorHandle = [IntPtr]::Zero
    }
    Remove-EmbeddedMediaTools
})
 
Update-RedactionButtons
 
[System.Windows.Forms.Application]::Run($form)